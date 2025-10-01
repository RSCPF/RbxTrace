--[[
    LOG REMOTE SYSTEM
    
    Handles client-to-server log transmission using Red networking.
    Provides secure, efficient log transfer with rate limiting and validation.
]] local RunService = game:GetService("RunService")
-- Get Red from the package dependencies
local Packages = script.Parent.Parent.Parent
local Red = require(Packages.Red)

local LoggerConfig = require(script.Parent.LoggerConfig)

local LogRemote = {}

local IsServer = RunService:IsServer()
local LogTransmissionRemote = nil
local ClientLogBuffer = {}
local LastTransmission = 0

-- // INITIALIZATION
function LogRemote.Initialize()
  if IsServer then
    LogRemote.InitializeServer()
  else
    LogRemote.InitializeClient()
  end
end

-- // SERVER-SIDE SETUP
function LogRemote.InitializeServer()
  -- Create Red remote for log transmission
  LogTransmissionRemote = Red.Server("LogTransmission", Red.Reliable)

  -- Handle incoming client logs
  LogTransmissionRemote:On(function(player, logBatch)
    LogRemote.ProcessClientLogs(player, logBatch)
  end)

  print("LogRemote: Server initialized")
end

function LogRemote.ProcessClientLogs(player, logBatch)
  -- Validate player
  if not player or not player.Parent then
    return
  end

  -- Validate log batch
  if type(logBatch) ~= "table" or #logBatch == 0 then
    warn("LogRemote: Invalid log batch from player", player.Name)
    return
  end

  -- Rate limiting per player
  local currentTime = tick()
  if not LogRemote.PlayerLastTransmission then
    LogRemote.PlayerLastTransmission = {}
  end

  local lastTime = LogRemote.PlayerLastTransmission[player.UserId] or 0
  if currentTime - lastTime < 1 then -- 1 second rate limit per player
    warn("LogRemote: Rate limit exceeded by player", player.Name)
    return
  end
  LogRemote.PlayerLastTransmission[player.UserId] = currentTime

  -- Validate each log entry
  local validLogs = {}
  for _, logData in ipairs(logBatch) do
    if LogRemote.ValidateLogData(logData) then
      -- Add server-side metadata
      logData.receivedAt = currentTime
      logData.fromClient = true
      logData.playerName = player.Name
      logData.playerUserId = player.UserId

      table.insert(validLogs, logData)
    end
  end

  -- Process valid logs through the main logger
  if #validLogs > 0 then
    LogRemote.ProcessValidatedLogs(validLogs)
  end
end

function LogRemote.ValidateLogData(logData)
  -- Basic structure validation
  if type(logData) ~= "table" then
    return false
  end

  -- Required fields
  local requiredFields = {"level", "message", "timestamp"}
  for _, field in ipairs(requiredFields) do
    if not logData[field] then
      return false
    end
  end

  -- Validate log level
  if not LoggerConfig.LOG_LEVELS[logData.level] then
    return false
  end

  -- Validate message length
  if type(logData.message) ~= "string" or #logData.message > 2000 then
    return false
  end

  -- Validate timestamp
  if type(logData.timestamp) ~= "string" then
    return false
  end

  return true
end

function LogRemote.ProcessValidatedLogs(validLogs)
  local Logger = require(script.Parent.Logger)
  local LogEntry = require(script.Parent.LogEntry)

  for _, logData in ipairs(validLogs) do
    -- Create LogEntry from client data
    local logEntry = LogEntry.new({
      level = logData.level,
      title = logData.title,
      message = string.format("[CLIENT:%s] %s", logData.playerName, logData.message),
      timestamp = logData.timestamp,
      scriptName = logData.scriptName,
      lineNumber = logData.lineNumber,
      metadata = logData.metadata or {},
      server = true, -- This is processed on server
      userId = logData.playerUserId,
      placeId = game.PlaceId,
      jobId = game.JobId
    })

    -- Add client-specific metadata
    logEntry.metadata.fromClient = true
    logEntry.metadata.clientTimestamp = logData.timestamp
    logEntry.metadata.receivedAt = logData.receivedAt

    -- Process through storage manager
    local logger = Logger.GetInstance()
    logger.StorageManager:StoreInMemory(logEntry)

    -- Store in DataStore if level is high enough
    if LoggerConfig.LOG_LEVELS[logData.level] >= LoggerConfig.STORAGE_THRESHOLDS.DATASTORE then
      logger.StorageManager:StoreInDataStore(logEntry)
    end

    -- Send to webhooks if level is high enough
    if LoggerConfig.LOG_LEVELS[logData.level] >= LoggerConfig.STORAGE_THRESHOLDS.WEBHOOKS then
      logger.StorageManager:SendWebhook({logEntry})
    end
  end
end

-- // CLIENT-SIDE SETUP
function LogRemote.InitializeClient()
  -- Create Red remote reference
  LogTransmissionRemote = Red.Client("LogTransmission", Red.Reliable)

  -- Start transmission loop
  task.spawn(function()
    LogRemote.StartTransmissionLoop()
  end)

  print("LogRemote: Client initialized")
end

function LogRemote.StartTransmissionLoop()
  while true do
    task.wait(5) -- Send logs every 5 seconds

    if #ClientLogBuffer > 0 then
      LogRemote.TransmitBufferedLogs()
    end
  end
end

function LogRemote.TransmitBufferedLogs()
  if not LogTransmissionRemote then
    return
  end

  local currentTime = tick()

  -- Rate limiting
  if currentTime - LastTransmission < 1 then
    return
  end

  -- Prepare batch
  local batch = {}
  local maxBatch = 20 -- Limit batch size to prevent network spam

  for i = 1, math.min(#ClientLogBuffer, maxBatch) do
    table.insert(batch, table.remove(ClientLogBuffer, 1))
  end

  if #batch == 0 then
    return
  end

  -- Send to server
  local success, err = pcall(function()
    LogTransmissionRemote:Fire(batch)
  end)

  if success then
    LastTransmission = currentTime
  else
    warn("LogRemote: Failed to transmit logs:", err)
    -- Put logs back in buffer for retry
    for i = #batch, 1, -1 do
      table.insert(ClientLogBuffer, 1, batch[i])
    end
  end
end

-- // CLIENT LOG QUEUING
function LogRemote.QueueClientLog(logEntry)
  if IsServer then
    return -- Only queue on client
  end

  -- Check if log level meets transmission threshold
  if LoggerConfig.LOG_LEVELS[logEntry.level] < LoggerConfig.STORAGE_THRESHOLDS.CLIENT_TO_SERVER then
    return
  end

  -- Convert LogEntry to transmittable data
  local logData = {
    level = logEntry.level,
    title = logEntry.title,
    message = logEntry.message,
    timestamp = logEntry.timestamp,
    scriptName = logEntry.scriptName,
    lineNumber = logEntry.lineNumber,
    metadata = logEntry.metadata or {}
  }

  -- Add to buffer
  table.insert(ClientLogBuffer, logData)

  -- Limit buffer size to prevent memory issues
  if #ClientLogBuffer > 100 then
    table.remove(ClientLogBuffer, 1) -- Remove oldest log
  end

  -- Immediate transmission for critical logs
  if logEntry.level == "ERROR" or logEntry.level == "FATAL" then
    task.spawn(function()
      task.wait(0.1) -- Small delay to allow batching of multiple errors
      LogRemote.TransmitBufferedLogs()
    end)
  end
end

-- // UTILITY FUNCTIONS
function LogRemote.GetBufferStatus()
  return {
    bufferedLogs = #ClientLogBuffer,
    lastTransmission = LastTransmission,
    isConnected = LogTransmissionRemote ~= nil
  }
end

function LogRemote.FlushBuffer()
  if not IsServer then
    LogRemote.TransmitBufferedLogs()
  end
end

function LogRemote.ClearBuffer()
  if not IsServer then
    ClientLogBuffer = {}
  end
end

-- // SERVER STATISTICS
LogRemote.PlayerLastTransmission = {}
LogRemote.ServerStats = {
  totalLogsReceived = 0,
  totalPlayersLogged = 0,
  lastLogReceived = 0
}

function LogRemote.GetServerStats()
  if IsServer then
    return {
      totalLogsReceived = LogRemote.ServerStats.totalLogsReceived,
      totalPlayersLogged = LogRemote.ServerStats.totalPlayersLogged,
      lastLogReceived = LogRemote.ServerStats.lastLogReceived,
      connectedPlayers = #game.Players:GetPlayers()
    }
  end
  return nil
end

-- // SECURITY FEATURES
function LogRemote.ValidatePlayer(player)
  -- Additional security checks can be added here
  if not player or not player.Parent then
    return false
  end

  -- Check if player is in game
  if not game.Players:FindFirstChild(player.Name) then
    return false
  end

  return true
end

-- Player cleanup when they leave
if IsServer then
  game.Players.PlayerRemoving:Connect(function(player)
    if LogRemote.PlayerLastTransmission then
      LogRemote.PlayerLastTransmission[player.UserId] = nil
    end
  end)
end

return LogRemote
