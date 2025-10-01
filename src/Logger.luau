--[[
    RBXTRACE SYSTEM - CORE LOGGER
    
    The heart of the logging system. Handles all log processing,
    formatting, routing, and storage coordination.
]] local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local LoggerConfig = require(script.Parent.LoggerConfig)
local StorageManager = require(script.Parent.StorageManager)
local LogEntry = require(script.Parent.LogEntry)

local Logger = {}
Logger.__index = Logger

-- // SINGLETON PATTERN
local LoggerInstance = nil

-- // INTERNAL STATE
local IsServer = RunService:IsServer()
local LocalPlayer = IsServer and nil or Players.LocalPlayer

local LogQueue = {}
local ProcessingCoroutine = nil
local LastWebhookTime = 0
local WebhookBatch = {}

-- // UTILITY FUNCTIONS
local function GetTimestamp()
  local now = DateTime.now()
  local formatted = now:FormatLocalTime(LoggerConfig.FORMATTING.TIMESTAMP_FORMAT, "en-us")
  return formatted
end

local function GetCallerInfo()
  if not LoggerConfig.FORMATTING.INCLUDE_SCRIPT_NAME then
    return nil, nil
  end

  local success, result = pcall(function()
    local info = debug.getinfo(4, "Sl")
    if info then
      local scriptName = info.source:match("([^%.]+)%.") or "Unknown"
      local lineNumber = LoggerConfig.FORMATTING.INCLUDE_LINE_NUMBER and info.currentline or nil
      return scriptName, lineNumber
    end
  end)

  if success then
    return result
  else
    return "Unknown", nil
  end
end

local function IsUserDeveloper(userId)
  -- Check fallback UserIds first
  for _, devId in ipairs(LoggerConfig.DEV_AUTHENTICATION.FALLBACK_USERIDS) do
    if userId == devId then
      return true
    end
  end

  -- Check group rank
  if LoggerConfig.DEV_AUTHENTICATION.GROUP_ID > 0 then
    local success, result = pcall(function()
      return GroupService:GetRankInGroup(userId, LoggerConfig.DEV_AUTHENTICATION.GROUP_ID)
    end)

    if success and result >= LoggerConfig.DEV_AUTHENTICATION.MIN_RANK then
      return true
    end
  end

  return false
end

local function FormatLogMessage(level, title, message, timestamp, scriptName, lineNumber)
  local colorCode = LoggerConfig.FORMATTING.COLOR_CODES[level] or ""
  local resetCode = LoggerConfig.FORMATTING.COLOR_CODES.RESET

  local parts = {}
  table.insert(parts, colorCode)
  table.insert(parts, timestamp)

  if title then
    table.insert(parts, string.format("[%s]", title))
  end

  if scriptName then
    local scriptInfo = lineNumber and string.format("[%s:%d]", scriptName, lineNumber) or
                         string.format("[%s]", scriptName)
    table.insert(parts, scriptInfo)
  end

  table.insert(parts, string.format("[%s]", level))
  table.insert(parts, message)
  table.insert(parts, resetCode)

  return table.concat(parts, " ")
end

local function ShouldLogToStorage(level, storageType)
  local levelValue = LoggerConfig.LOG_LEVELS[level]
  local threshold = LoggerConfig.STORAGE_THRESHOLDS[storageType]
  return levelValue >= threshold
end

-- // CORE LOGGER CLASS
function Logger.new()
  if LoggerInstance then
    return LoggerInstance
  end

  local self = setmetatable({}, Logger)

  self.StorageManager = StorageManager.new()
  self.IsRunning = false
  self.LogCount = 0
  self.StartTime = tick()

  -- Initialize storage backends
  self.StorageManager:Initialize()

  LoggerInstance = self
  return self
end

function Logger:Start()
  if self.IsRunning then
    return
  end

  self.IsRunning = true

  -- Start processing coroutine
  ProcessingCoroutine = coroutine.create(function()
    self:ProcessLogQueue()
  end)

  -- Start the processing loop
  RunService.Heartbeat:Connect(function()
    if ProcessingCoroutine and coroutine.status(ProcessingCoroutine) ~= "dead" then
      coroutine.resume(ProcessingCoroutine)
    end
  end)

  self:Info("Logger", "RbxTrace Logging System started successfully")
end

function Logger:Stop()
  if not self.IsRunning then
    return
  end

  self.IsRunning = false

  -- Flush any remaining logs
  self:FlushLogs()

  self:Info("Logger", "RbxTrace Logging System stopped")
end

-- // MAIN LOGGING METHODS
function Logger:Log(level, title, message, metadata)
  if not self.IsRunning then
    return
  end

  -- Validate inputs
  if not LoggerConfig.LOG_LEVELS[level] then
    level = "INFO"
  end

  if type(message) ~= "string" then
    message = tostring(message)
  end

  -- Truncate long messages
  if #message > LoggerConfig.FORMATTING.MAX_MESSAGE_LENGTH then
    message = string.sub(message, 1, LoggerConfig.FORMATTING.MAX_MESSAGE_LENGTH) .. "..."
  end

  -- Get caller information
  local scriptName, lineNumber = GetCallerInfo()
  local timestamp = GetTimestamp()

  -- Create log entry
  local logEntry = LogEntry.new({
    level = level,
    title = title,
    message = message,
    timestamp = timestamp,
    scriptName = scriptName,
    lineNumber = lineNumber,
    metadata = metadata or {},
    server = IsServer,
    userId = not IsServer and LocalPlayer.UserId or nil,
    placeId = game.PlaceId,
    jobId = game.JobId
  })

  -- Add to processing queue
  table.insert(LogQueue, logEntry)
  self.LogCount = self.LogCount + 1

  -- Console output (immediate)
  if ShouldLogToStorage(level, "CONSOLE") then
    local formatted = FormatLogMessage(level, title, message, timestamp, scriptName, lineNumber)
    print(formatted)
  end
end

-- // CONVENIENCE METHODS
function Logger:Trace(title, message, metadata)
  -- Only process trace logs if debug mode is enabled
  if LoggerConfig.DEBUG_MODE then
    self:Log("TRACE", title, message, metadata)
  end
  -- If debug mode is disabled, the call is ignored but no error is thrown
end

function Logger:Debug(title, message, metadata)
  -- Only process debug logs if debug mode is enabled
  if LoggerConfig.DEBUG_MODE then
    self:Log("DEBUG", title, message, metadata)
  end
  -- If debug mode is disabled, the call is ignored but no error is thrown
end

function Logger:Info(title, message, metadata)
  self:Log("INFO", title, message, metadata)
end

function Logger:Warn(title, message, metadata)
  self:Log("WARN", title, message, metadata)
end

function Logger:Error(title, message, metadata)
  self:Log("ERROR", title, message, metadata)
end

function Logger:Fatal(title, message, metadata)
  self:Log("FATAL", title, message, metadata)
end

-- // LOG PROCESSING
function Logger:ProcessLogQueue()
  while self.IsRunning do
    local logsProcessed = 0

    -- Process logs in batches to avoid frame drops
    while #LogQueue > 0 and logsProcessed < LoggerConfig.PERFORMANCE.MAX_LOGS_PER_FRAME do
      local logEntry = table.remove(LogQueue, 1)
      self:ProcessLogEntry(logEntry)
      logsProcessed = logsProcessed + 1
    end

    -- Yield to prevent infinite loop
    coroutine.yield()
  end
end

function Logger:ProcessLogEntry(logEntry)
  -- Memory storage (always process for dev GUI)
  if ShouldLogToStorage(logEntry.level, "MEMORY") then
    self.StorageManager:StoreInMemory(logEntry)
  end

  -- DataStore storage
  if ShouldLogToStorage(logEntry.level, "DATASTORE") and IsServer then
    self.StorageManager:StoreInDataStore(logEntry)
  end

  -- Webhook processing
  if ShouldLogToStorage(logEntry.level, "WEBHOOKS") then
    self:QueueForWebhook(logEntry)
  end

  -- Client-to-server transmission
  if not IsServer and ShouldLogToStorage(logEntry.level, "CLIENT_TO_SERVER") then
    self:SendToServer(logEntry)
  end
end

function Logger:QueueForWebhook(logEntry)
  table.insert(WebhookBatch, logEntry)

  local currentTime = tick()
  local timeSinceLastWebhook = currentTime - LastWebhookTime

  -- Send webhook if batch is full or enough time has passed
  if #WebhookBatch >= LoggerConfig.WEBHOOKS.BATCH_SIZE or timeSinceLastWebhook >=
    LoggerConfig.WEBHOOKS.RATE_LIMIT_SECONDS then
    self:SendWebhook()
  end
end

function Logger:SendWebhook()
  if #WebhookBatch == 0 then
    return
  end

  -- This will be implemented in the next part with the StorageManager
  self.StorageManager:SendWebhook(WebhookBatch)

  WebhookBatch = {} -- Clear batch
  LastWebhookTime = tick()
end

function Logger:SendToServer(logEntry)
  -- This will be implemented with the Red remote system
  local success, err = pcall(function()
    -- We'll implement this in the next step
  end)

  if not success and LoggerConfig.DEBUG.LOG_LOGGER_ERRORS then
    warn("Failed to send log to server:", err)
  end
end

function Logger:FlushLogs()
  -- Process any remaining logs in queue
  while #LogQueue > 0 do
    local logEntry = table.remove(LogQueue, 1)
    self:ProcessLogEntry(logEntry)
  end

  -- Send any remaining webhooks
  if #WebhookBatch > 0 then
    self:SendWebhook()
  end

  -- Flush storage backends
  self.StorageManager:Flush()
end

-- // DEVELOPER UTILITIES
function Logger:GetLogs(filters)
  return self.StorageManager:GetMemoryLogs(filters)
end

function Logger:ClearLogs()
  if IsServer or (LocalPlayer and IsUserDeveloper(LocalPlayer.UserId)) then
    self.StorageManager:ClearMemoryLogs()
    self:Info("Logger", "Log history cleared by developer")
  end
end

function Logger:GetStats()
  return {
    totalLogs = self.LogCount,
    uptime = tick() - self.StartTime,
    queueSize = #LogQueue,
    memoryLogs = self.StorageManager:GetMemoryLogCount(),
    isRunning = self.IsRunning
  }
end

function Logger:SetLogLevel(storageType, level)
  if IsServer or (LocalPlayer and IsUserDeveloper(LocalPlayer.UserId)) then
    LoggerConfig.STORAGE_THRESHOLDS[storageType] = LoggerConfig.LOG_LEVELS[level]
    self:Info("Logger", string.format("Log level for %s set to %s", storageType, level))
  end
end

-- // STATIC ACCESS METHODS
function Logger.GetInstance()
  if not LoggerInstance then
    LoggerInstance = Logger.new()
    LoggerInstance:Start()
  end
  return LoggerInstance
end

-- Global convenience functions
_G.LogTrace = function(title, message, metadata)
  Logger.GetInstance():Trace(title, message, metadata)
end
_G.LogDebug = function(title, message, metadata)
  Logger.GetInstance():Debug(title, message, metadata)
end
_G.LogInfo = function(title, message, metadata)
  Logger.GetInstance():Info(title, message, metadata)
end
_G.LogWarn = function(title, message, metadata)
  Logger.GetInstance():Warn(title, message, metadata)
end
_G.LogError = function(title, message, metadata)
  Logger.GetInstance():Error(title, message, metadata)
end
_G.LogFatal = function(title, message, metadata)
  Logger.GetInstance():Fatal(title, message, metadata)
end

return Logger
