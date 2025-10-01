--[[
    STORAGE MANAGER
    
    Handles all storage backends: Memory, DataStore, and Webhooks.
    Manages data persistence, retrieval, and cleanup operations.
]] local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LoggerConfig = require(script.Parent.LoggerConfig)

local StorageManager = {}
StorageManager.__index = StorageManager

local IsServer = RunService:IsServer()

function StorageManager.new()
  local self = setmetatable({}, StorageManager)

  -- Memory storage
  self.MemoryLogs = {}
  self.LogsByLevel = {}
  self.LogsByTitle = {}

  -- DataStore
  self.LogDataStore = nil
  self.PendingDataStoreSaves = {}
  self.LastDataStoreSave = 0

  -- Webhooks
  self.WebhookQueue = {}
  self.LastWebhookSend = 0

  -- Initialize level and title indices
  for level, _ in pairs(LoggerConfig.LOG_LEVELS) do
    self.LogsByLevel[level] = {}
  end

  return self
end

function StorageManager:Initialize()
  -- Initialize DataStore (server only)
  if IsServer then
    self:InitializeDataStore()
  end

  -- Start cleanup coroutine
  coroutine.wrap(function()
    self:StartCleanupLoop()
  end)()

  -- Start DataStore save loop (server only)
  if IsServer then
    coroutine.wrap(function()
      self:StartDataStoreSaveLoop()
    end)()
  end
end

-- // MEMORY STORAGE
function StorageManager:StoreInMemory(logEntry)
  -- Add to main log array
  table.insert(self.MemoryLogs, logEntry)

  -- Add to level index
  table.insert(self.LogsByLevel[logEntry.level], logEntry)

  -- Add to title index
  if logEntry.title then
    if not self.LogsByTitle[logEntry.title] then
      self.LogsByTitle[logEntry.title] = {}
    end
    table.insert(self.LogsByTitle[logEntry.title], logEntry)
  end

  -- Check if we need to rotate logs
  if #self.MemoryLogs > LoggerConfig.MEMORY.MAX_LOGS then
    self:RotateMemoryLogs()
  end
end

function StorageManager:RotateMemoryLogs()
  local logsToRemove = #self.MemoryLogs - LoggerConfig.MEMORY.MAX_LOGS + 100 -- Remove extra buffer

  for i = 1, logsToRemove do
    local removedLog = table.remove(self.MemoryLogs, 1)

    -- Remove from indices if preserving important logs is disabled
    -- or if it's not an important log
    local isImportant = LoggerConfig.MEMORY.PRESERVE_IMPORTANT_LOGS and
                          (removedLog.level == "ERROR" or removedLog.level == "FATAL")

    if not isImportant then
      -- Remove from level index
      local levelLogs = self.LogsByLevel[removedLog.level]
      for j, log in ipairs(levelLogs) do
        if log.id == removedLog.id then
          table.remove(levelLogs, j)
          break
        end
      end

      -- Remove from title index
      if removedLog.title and self.LogsByTitle[removedLog.title] then
        local titleLogs = self.LogsByTitle[removedLog.title]
        for j, log in ipairs(titleLogs) do
          if log.id == removedLog.id then
            table.remove(titleLogs, j)
            break
          end
        end
      end
    else
      -- Keep important logs, just not in main array
      -- They'll still be in the indices for retrieval
    end
  end
end

function StorageManager:GetMemoryLogs(filters)
  local logs = self.MemoryLogs

  if filters then
    -- Use indices for efficient filtering
    if filters.level and self.LogsByLevel[filters.level] then
      logs = self.LogsByLevel[filters.level]
    elseif filters.title and self.LogsByTitle[filters.title] then
      logs = self.LogsByTitle[filters.title]
    end

    -- Apply additional filters
    local filteredLogs = {}
    for _, log in ipairs(logs) do
      if log:MatchesFilter(filters) then
        table.insert(filteredLogs, log)
      end
    end
    return filteredLogs
  end

  -- Return copy to prevent external modification
  local logsCopy = {}
  for _, log in ipairs(logs) do
    table.insert(logsCopy, log)
  end
  return logsCopy
end

function StorageManager:GetMemoryLogCount()
  return #self.MemoryLogs
end

function StorageManager:ClearMemoryLogs()
  self.MemoryLogs = {}

  -- Clear indices
  for level, _ in pairs(LoggerConfig.LOG_LEVELS) do
    self.LogsByLevel[level] = {}
  end

  for title, _ in pairs(self.LogsByTitle) do
    self.LogsByTitle[title] = {}
  end
end

-- // DATASTORE STORAGE (Server Only)
function StorageManager:InitializeDataStore()
  local success, result = pcall(function()
    return DataStoreService:GetDataStore(LoggerConfig.DATASTORE.STORE_NAME)
  end)

  if success then
    self.LogDataStore = result
  else
    warn("Failed to initialize log DataStore:", result)
  end
end

function StorageManager:StoreInDataStore(logEntry)
  if not IsServer or not self.LogDataStore then
    return
  end

  -- Add to pending saves queue
  local key = self:GetDataStoreKey(logEntry)
  if not self.PendingDataStoreSaves[key] then
    self.PendingDataStoreSaves[key] = {}
  end

  table.insert(self.PendingDataStoreSaves[key], logEntry)
end

function StorageManager:GetDataStoreKey(logEntry)
  if logEntry.userId then
    return string.format("player_%d", logEntry.userId)
  else
    return string.format("server_%s", logEntry.jobId or "unknown")
  end
end

function StorageManager:StartDataStoreSaveLoop()
  while true do
    task.wait(LoggerConfig.DATASTORE.SAVE_INTERVAL_SECONDS)
    self:SavePendingDataStoreLogs()
  end
end

function StorageManager:SavePendingDataStoreLogs()
  if not self.LogDataStore or not next(self.PendingDataStoreSaves) then
    return
  end

  for key, logs in pairs(self.PendingDataStoreSaves) do
    coroutine.wrap(function()
      self:SaveLogsForKey(key, logs)
    end)()
  end

  -- Clear pending saves
  self.PendingDataStoreSaves = {}
end

function StorageManager:SaveLogsForKey(key, newLogs)
  local success, result = pcall(function()
    -- Get existing logs
    local existingData = self.LogDataStore:GetAsync(key) or {
      logs = {}
    }
    local existingLogs = existingData.logs

    -- Add new logs
    for _, log in ipairs(newLogs) do
      table.insert(existingLogs, {
        id = log.id,
        level = log.level,
        title = log.title,
        message = log.message,
        timestamp = log.timestamp,
        rawTimestamp = log.rawTimestamp,
        scriptName = log.scriptName,
        lineNumber = log.lineNumber,
        metadata = log.metadata
      })
    end

    -- Rotate if too many logs
    if #existingLogs > LoggerConfig.DATASTORE.MAX_LOGS_PER_PLAYER then
      local logsToRemove = #existingLogs - LoggerConfig.DATASTORE.MAX_LOGS_PER_PLAYER
      for i = 1, logsToRemove do
        table.remove(existingLogs, 1)
      end
    end

    -- Save back to DataStore
    local dataToSave = {
      logs = existingLogs,
      lastUpdated = tick(),
      version = 1
    }

    return self.LogDataStore:SetAsync(key, dataToSave)
  end)

  if not success then
    warn("Failed to save logs to DataStore for key", key, ":", result)
    -- Could implement retry logic here
  end
end

-- // WEBHOOK SYSTEM
function StorageManager:SendWebhook(logBatch)
  if #logBatch == 0 then
    return
  end

  -- Rate limiting check
  local currentTime = tick()
  if currentTime - self.LastWebhookSend < LoggerConfig.WEBHOOKS.RATE_LIMIT_SECONDS then
    -- Queue for later
    for _, log in ipairs(logBatch) do
      table.insert(self.WebhookQueue, log)
    end
    return
  end

  self.LastWebhookSend = currentTime

  -- Send webhook asynchronously
  coroutine.wrap(function()
    self:ProcessWebhookBatch(logBatch)
  end)()
end

function StorageManager:ProcessWebhookBatch(logBatch)
  local webhookUrl = LoggerConfig.WEBHOOKS.DISCORD_WEBHOOK_URL
  if not webhookUrl or webhookUrl == "" then
    return
  end

  -- Create webhook payload
  local payload = self:CreateWebhookPayload(logBatch)

  -- Send to primary webhook
  local success = self:SendWebhookRequest(webhookUrl, payload)

  -- Try backup webhook if primary failed
  if not success and LoggerConfig.WEBHOOKS.BACKUP_WEBHOOK_URL ~= "" then
    self:SendWebhookRequest(LoggerConfig.WEBHOOKS.BACKUP_WEBHOOK_URL, payload)
  end
end

function StorageManager:CreateWebhookPayload(logBatch)
  local embeds = {}

  for _, logEntry in ipairs(logBatch) do
    local embed = logEntry:GetWebhookPayload().embeds[1]

    -- Add context logs for errors if enabled
    if (logEntry.level == "ERROR" or logEntry.level == "FATAL") and LoggerConfig.WEBHOOKS.INCLUDE_RECENT_CONTEXT then
      self:AddContextToEmbed(embed, logEntry)
    end

    table.insert(embeds, embed)

    -- Discord has a limit of 10 embeds per message
    if #embeds >= 10 then
      break
    end
  end

  return {
    username = "SCP-THRESHER Logger",
    avatar_url = "https://cdn.discordapp.com/attachments/your-avatar-url.png", -- Add your avatar URL
    embeds = embeds
  }
end

function StorageManager:AddContextToEmbed(embed, errorLog)
  -- Get recent logs before this error
  local contextLogs = {}
  local errorIndex = 0

  -- Find the error log in memory
  for i, log in ipairs(self.MemoryLogs) do
    if log.id == errorLog.id then
      errorIndex = i
      break
    end
  end

  if errorIndex > 0 then
    local startIndex = math.max(1, errorIndex - LoggerConfig.WEBHOOKS.CONTEXT_LINES)
    for i = startIndex, errorIndex - 1 do
      local log = self.MemoryLogs[i]
      table.insert(contextLogs, string.format("`%s` %s", log.level, log.message))
    end
  end

  if #contextLogs > 0 then
    table.insert(embed.fields, {
      name = "Recent Context",
      value = table.concat(contextLogs, "\n"),
      inline = false
    })
  end
end

function StorageManager:SendWebhookRequest(url, payload)
  local success, result = pcall(function()
    return HttpService:PostAsync(url, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
  end)

  if not success then
    warn("Webhook send failed:", result)
    return false
  end

  return true
end

-- // CLEANUP AND MAINTENANCE
function StorageManager:StartCleanupLoop()
  while true do
    task.wait(LoggerConfig.MEMORY.CLEANUP_INTERVAL_SECONDS)
    self:PerformCleanup()
  end
end

function StorageManager:PerformCleanup()
  -- Memory cleanup is handled in RotateMemoryLogs

  -- Process queued webhooks
  if #self.WebhookQueue > 0 then
    local batchSize = math.min(LoggerConfig.WEBHOOKS.BATCH_SIZE, #self.WebhookQueue)
    local batch = {}

    for i = 1, batchSize do
      table.insert(batch, table.remove(self.WebhookQueue, 1))
    end

    self:SendWebhook(batch)
  end

  -- Force garbage collection if enabled
  if LoggerConfig.PERFORMANCE.GARBAGE_COLLECTION_INTERVAL > 0 then
    if tick() % LoggerConfig.PERFORMANCE.GARBAGE_COLLECTION_INTERVAL < 1 then
      collectgarbage("collect")
    end
  end
end

function StorageManager:Flush()
  -- Save any pending DataStore logs immediately
  if IsServer then
    self:SavePendingDataStoreLogs()
  end

  -- Send any queued webhooks
  if #self.WebhookQueue > 0 then
    self:ProcessWebhookBatch(self.WebhookQueue)
    self.WebhookQueue = {}
  end
end

-- // EXPORT FUNCTIONALITY
function StorageManager:ExportLogs(format, filters)
  local logs = self:GetMemoryLogs(filters)

  if format == "JSON" then
    return self:ExportAsJSON(logs)
  elseif format == "CSV" then
    return self:ExportAsCSV(logs)
  elseif format == "TXT" then
    return self:ExportAsText(logs)
  else
    return self:ExportAsText(logs) -- Default to text
  end
end

function StorageManager:ExportAsJSON(logs)
  local exportData = {
    exportTime = DateTime.now():ToIsoDate(),
    totalLogs = #logs,
    logs = {}
  }

  for _, log in ipairs(logs) do
    table.insert(exportData.logs, {
      id = log.id,
      level = log.level,
      title = log.title,
      message = log.message,
      timestamp = log.timestamp,
      scriptName = log.scriptName,
      lineNumber = log.lineNumber,
      server = log.server,
      userId = log.userId,
      metadata = log.metadata
    })
  end

  return HttpService:JSONEncode(exportData)
end

function StorageManager:ExportAsCSV(logs)
  local lines = {"Timestamp,Level,Title,ScriptName,LineNumber,Message,Server,UserID"}

  for _, log in ipairs(logs) do
    local csvLine = string.format('"%s","%s","%s","%s","%s","%s","%s","%s"', log.timestamp or "", log.level or "",
      log.title or "", log.scriptName or "", log.lineNumber or "", (log.message or ""):gsub('"', '""'), -- Escape quotes
      tostring(log.server), tostring(log.userId or ""))
    table.insert(lines, csvLine)
  end

  return table.concat(lines, "\n")
end

function StorageManager:ExportAsText(logs)
  local lines = {"=== SCP-THRESHER LOG EXPORT ===", "Export Time: " .. DateTime.now():ToIsoDate(),
                 "Total Logs: " .. #logs, "================================", ""}

  for _, log in ipairs(logs) do
    table.insert(lines, log:ToString())
  end

  return table.concat(lines, "\n")
end

return StorageManager
