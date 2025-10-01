--[[
    LOG ENTRY CLASS
    
    Represents a single log entry with all its metadata.
    Used throughout the logging system for consistent data structure.
]] local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LogEntry = {}
LogEntry.__index = LogEntry

function LogEntry.new(data)
  local self = setmetatable({}, LogEntry)

  -- Core log data
  self.id = HttpService:GenerateGUID(false)
  self.level = data.level
  self.title = data.title
  self.message = data.message
  self.timestamp = data.timestamp
  self.rawTimestamp = tick()

  -- Script information
  self.scriptName = data.scriptName
  self.lineNumber = data.lineNumber

  -- Context information
  self.server = data.server
  self.userId = data.userId
  self.placeId = data.placeId
  self.jobId = data.jobId

  -- Additional metadata
  self.metadata = data.metadata or {}

  -- Automatically add device info for client logs
  if not self.server and data.userId then
    self:AddDeviceInfo()
  end

  return self
end

function LogEntry:AddDeviceInfo()
  local UserInputService = game:GetService("UserInputService")

  self.metadata.deviceInfo = {
    platform = Enum.Platform.Windows, -- This would need to be detected properly
    touchEnabled = UserInputService.TouchEnabled,
    keyboardEnabled = UserInputService.KeyboardEnabled,
    mouseEnabled = UserInputService.MouseEnabled,
    gamepadEnabled = UserInputService.GamepadEnabled,
    accelerometerEnabled = UserInputService.AccelerometerEnabled,
    gyroscopeEnabled = UserInputService.GyroscopeEnabled
  }
end

function LogEntry:AddStackTrace()
  local stackTrace = {}
  local level = 2

  while true do
    local info = debug.getinfo(level, "Sln")
    if not info then
      break
    end

    table.insert(stackTrace, {
      source = info.source,
      name = info.name or "anonymous",
      line = info.currentline,
      what = info.what
    })

    level = level + 1
    if level > 20 then -- Prevent infinite loops
      break
    end
  end

  self.metadata.stackTrace = stackTrace
end

function LogEntry:AddPerformanceMetrics()
  self.metadata.performance = {
    memory = collectgarbage("count"),
    fps = 1 / RunService.Heartbeat:Wait(), -- Approximate FPS
    ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
  }
end

function LogEntry:ToJSON()
  return HttpService:JSONEncode({
    id = self.id,
    level = self.level,
    title = self.title,
    message = self.message,
    timestamp = self.timestamp,
    rawTimestamp = self.rawTimestamp,
    scriptName = self.scriptName,
    lineNumber = self.lineNumber,
    server = self.server,
    userId = self.userId,
    placeId = self.placeId,
    jobId = self.jobId,
    metadata = self.metadata
  })
end

function LogEntry:ToString()
  local parts = {}

  table.insert(parts, self.timestamp)

  if self.title then
    table.insert(parts, string.format("[%s]", self.title))
  end

  if self.scriptName then
    local scriptInfo = self.lineNumber and string.format("[%s:%d]", self.scriptName, self.lineNumber) or
                         string.format("[%s]", self.scriptName)
    table.insert(parts, scriptInfo)
  end

  table.insert(parts, string.format("[%s]", self.level))
  table.insert(parts, self.message)

  return table.concat(parts, " ")
end

function LogEntry:GetDisplayText()
  -- Formatted text for GUI display
  return self:ToString()
end

function LogEntry:GetWebhookPayload()
  -- Format specifically for Discord webhooks
  local embed = {
    title = string.format("%s Log", self.level),
    description = self.message,
    color = self:GetLevelColor(),
    timestamp = DateTime.fromUnixTimestamp(self.rawTimestamp):ToIsoDate(),
    fields = {}
  }

  if self.title then
    table.insert(embed.fields, {
      name = "System",
      value = self.title,
      inline = true
    })
  end

  if self.scriptName then
    local scriptInfo = self.lineNumber and string.format("%s:%d", self.scriptName, self.lineNumber) or self.scriptName
    table.insert(embed.fields, {
      name = "Source",
      value = scriptInfo,
      inline = true
    })
  end

  table.insert(embed.fields, {
    name = "Context",
    value = string.format("Server: %s | Place: %d | Job: %s", tostring(self.server), self.placeId,
      self.jobId or "Unknown"),
    inline = false
  })

  if self.userId then
    table.insert(embed.fields, {
      name = "User",
      value = tostring(self.userId),
      inline = true
    })
  end

  return {
    embeds = {embed}
  }
end

function LogEntry:GetLevelColor()
  local colors = {
    TRACE = 9807270, -- Gray
    DEBUG = 3447003, -- Blue
    INFO = 3066993, -- Green
    WARN = 15844367, -- Yellow
    ERROR = 15158332, -- Red
    FATAL = 10181046 -- Purple
  }
  return colors[self.level] or colors.INFO
end

function LogEntry:MatchesFilter(filter)
  if not filter then
    return true
  end

  -- Level filter
  if filter.level and self.level ~= filter.level then
    return false
  end

  -- Title filter (supports partial matching)
  if filter.title then
    if not self.title or not string.find(self.title:lower(), filter.title:lower()) then
      return false
    end
  end

  -- Message filter (supports partial matching)
  if filter.message then
    if not string.find(self.message:lower(), filter.message:lower()) then
      return false
    end
  end

  -- Script filter
  if filter.scriptName then
    if not self.scriptName or not string.find(self.scriptName:lower(), filter.scriptName:lower()) then
      return false
    end
  end

  -- Time range filter
  if filter.startTime and self.rawTimestamp < filter.startTime then
    return false
  end

  if filter.endTime and self.rawTimestamp > filter.endTime then
    return false
  end

  -- Server/client filter
  if filter.server ~= nil and self.server ~= filter.server then
    return false
  end

  return true
end

return LogEntry
