--[[
    RBXTRACE SYSTEM - MAIN INITIALIZATION
    
    This is the main entry point for the logging system.
    Import this module to initialize the entire logging system.
]] local RunService = game:GetService("RunService")

-- Get Red from packages
local Packages = script.Parent.Parent
local Red = require(Packages.Red)

local Logger = require(script.Logger)
local LogRemote = require(script.LogRemote)
local LoggerGUI = require(script.LoggerGUI)
local LoggerConfig = require(script.LoggerConfig)

local RbxTrace = {}

local IsInitialized = false
local IsServer = RunService:IsServer()

-- // INITIALIZATION
function RbxTrace.Initialize()
  if IsInitialized then
    warn("RbxTrace: Already initialized!")
    return RbxTrace
  end

  print("RbxTrace: Initializing RbxTrace Logging System...")

  -- Initialize core logger
  local logger = Logger.GetInstance()

  -- Initialize remote system
  LogRemote.Initialize()

  -- Initialize GUI (client only, dev only)
  if not IsServer then
    LoggerGUI.Initialize()
  end

  -- Hook into client log transmission
  if not IsServer then
    -- Connect client logs to remote transmission
    local originalLog = logger.Log
    logger.Log = function(self, level, title, message, metadata)
      -- Call original log method
      local result = originalLog(self, level, title, message, metadata)

      -- Queue for server transmission if needed
      if LoggerConfig.LOG_LEVELS[level] >= LoggerConfig.STORAGE_THRESHOLDS.CLIENT_TO_SERVER then
        local logEntry = self.StorageManager.MemoryLogs[#self.StorageManager.MemoryLogs]
        if logEntry then
          LogRemote.QueueClientLog(logEntry)
        end
      end

      return result
    end
  end

  IsInitialized = true

  -- Log successful initialization
  logger:Info("RbxTrace", "RbxTrace Logging System initialized successfully")
  logger:Info("RbxTrace",
    string.format("Running on %s | Place: %d | JobId: %s", IsServer and "Server" or "Client", game.PlaceId,
      game.JobId or "Unknown"))

  return RbxTrace
end

-- // QUICK ACCESS METHODS
function RbxTrace.GetLogger()
  if not IsInitialized then
    RbxTrace.Initialize()
  end
  return Logger.GetInstance()
end

function RbxTrace.GetConfig()
  return LoggerConfig
end

function RbxTrace.GetRemote()
  return LogRemote
end

function RbxTrace.GetGUI()
  return LoggerGUI
end

-- // CONVENIENCE LOGGING METHODS
function RbxTrace.Trace(title, message, metadata)
  RbxTrace.GetLogger():Trace(title, message, metadata)
end

function RbxTrace.Debug(title, message, metadata)
  RbxTrace.GetLogger():Debug(title, message, metadata)
end

function RbxTrace.Info(title, message, metadata)
  RbxTrace.GetLogger():Info(title, message, metadata)
end

function RbxTrace.Warn(title, message, metadata)
  RbxTrace.GetLogger():Warn(title, message, metadata)
end

function RbxTrace.Error(title, message, metadata)
  RbxTrace.GetLogger():Error(title, message, metadata)
end

function RbxTrace.Fatal(title, message, metadata)
  RbxTrace.GetLogger():Fatal(title, message, metadata)
end

-- // SPECIALIZED LOGGING METHODS
function RbxTrace.LogPlayerAction(player, action, details)
  local metadata = {
    playerId = player.UserId,
    playerName = player.Name,
    actionType = "player_action",
    details = details or {}
  }

  RbxTrace.Info("PlayerActions", string.format("Player %s performed action: %s", player.Name, action), metadata)
end

function RbxTrace.LogSystemEvent(system, event, data)
  local metadata = {
    systemName = system,
    eventType = "system_event",
    eventData = data or {}
  }

  RbxTrace.Info("SystemEvents", string.format("System %s triggered event: %s", system, event), metadata)
end

function RbxTrace.LogPerformance(operation, duration, metadata)
  local perfMetadata = {
    operationType = "performance",
    duration = duration,
    operation = operation
  }

  -- Merge with provided metadata
  if metadata then
    for key, value in pairs(metadata) do
      perfMetadata[key] = value
    end
  end

  local level = duration > 1 and "WARN" or "DEBUG"
  RbxTrace.GetLogger():Log(level, "Performance",
    string.format("Operation '%s' took %.2fms", operation, duration * 1000), perfMetadata)
end

function RbxTrace.LogNetworkEvent(eventType, size, playerId)
  local metadata = {
    networkEvent = true,
    eventType = eventType,
    dataSize = size,
    playerId = playerId
  }

  RbxTrace.Debug("Network", string.format("%s event - Size: %d bytes", eventType, size), metadata)
end

-- // ERROR HANDLING AND CRASH REPORTING
function RbxTrace.LogError(errorMessage, stackTrace, context)
  local metadata = {
    errorType = "runtime_error",
    stackTrace = stackTrace,
    context = context or {},
    timestamp = tick()
  }

  RbxTrace.Error("Runtime", errorMessage, metadata)
end

function RbxTrace.SetupGlobalErrorHandling()
  -- This would set up global error catching
  -- Implementation depends on your specific needs
  if IsServer then
    -- Server error handling
    game:GetService("ScriptContext").Error:Connect(function(message, stackTrace, script)
      RbxTrace.LogError(message, stackTrace, {
        scriptName = script and script.Name or "Unknown",
        serverError = true
      })
    end)
  end
end

-- // STATISTICS AND MONITORING
function RbxTrace.GetSystemStats()
  local logger = RbxTrace.GetLogger()
  local stats = logger:GetStats()

  if not IsServer then
    local remoteStats = LogRemote.GetBufferStatus()
    stats.clientBuffer = remoteStats
  else
    local serverStats = LogRemote.GetServerStats()
    stats.serverRemote = serverStats
  end

  return stats
end

function RbxTrace.LogMemoryUsage()
  local memory = collectgarbage("count")
  RbxTrace.Debug("System", string.format("Memory usage: %.2f KB", memory), {
    memoryKB = memory,
    monitoringType = "memory"
  })
end

function RbxTrace.StartPerformanceMonitoring(interval)
  interval = interval or 60 -- Default 60 seconds

  task.spawn(function()
    while true do
      task.wait(interval)
      RbxTrace.LogMemoryUsage()

      -- Log FPS on client
      if not IsServer then
        local fps = 1 / RunService.Heartbeat:Wait()
        RbxTrace.Debug("Performance", string.format("FPS: %.1f", fps), {
          fps = fps,
          monitoringType = "performance"
        })
      end
    end
  end)
end

-- // SHUTDOWN AND CLEANUP
function RbxTrace.Shutdown()
  if not IsInitialized then
    return
  end

  RbxTrace.Info("RbxTrace", "Shutting down RbxTrace Logging System...")

  local logger = RbxTrace.GetLogger()
  logger:Stop()

  if not IsServer then
    LogRemote.FlushBuffer()
  end

  IsInitialized = false
end

-- Auto-cleanup on server shutdown
if IsServer then
  game:BindToClose(function()
    RbxTrace.Shutdown()
    task.wait(2) -- Give time for final log processing
  end)
end

return RbxTrace
