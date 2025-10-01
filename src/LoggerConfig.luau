--[[
    RBXTRACE SYSTEM CONFIGURATION
    
    Customize all logging behavior by editing the values below.
    No need to dig through the code - everything you need is right here!
]] local LoggerConfig = {}

-- // LOG LEVEL THRESHOLDS (TRACE=1, DEBUG=2, INFO=3, WARN=4, ERROR=5, FATAL=6)
LoggerConfig.LOG_LEVELS = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
  FATAL = 6
}

-- // STORAGE ROUTING - Set minimum log level for each storage type
LoggerConfig.STORAGE_THRESHOLDS = {
  MEMORY = LoggerConfig.LOG_LEVELS.TRACE, -- All logs in memory for dev GUI
  CONSOLE = LoggerConfig.LOG_LEVELS.TRACE, -- All logs to console output
  DATASTORE = LoggerConfig.LOG_LEVELS.INFO, -- INFO+ to DataStore (persistent)
  WEBHOOKS = LoggerConfig.LOG_LEVELS.ERROR, -- ERROR+ to webhooks (alerts)
  CLIENT_TO_SERVER = LoggerConfig.LOG_LEVELS.WARN -- WARN+ sent from client to server
}

-- // DEVELOPER AUTHENTICATION
LoggerConfig.DEV_AUTHENTICATION = {
  GROUP_ID = 0, -- Your group ID here
  MIN_RANK = 100, -- Minimum rank to access dev features
  FALLBACK_USERIDS = { -- Backup dev UserIds if group check fails
    -- Add your UserIds here: 123456789, 987654321
  }
}

-- // WEBHOOK CONFIGURATION
LoggerConfig.WEBHOOKS = {
  DISCORD_WEBHOOK_URL = "", -- Your Discord webhook URL
  BACKUP_WEBHOOK_URL = "", -- Backup webhook URL
  RATE_LIMIT_SECONDS = 5, -- Minimum seconds between webhook sends
  BATCH_SIZE = 10, -- Max logs per webhook batch
  INCLUDE_STACK_TRACE = true,
  INCLUDE_RECENT_CONTEXT = true, -- Include last 5 logs before errors
  CONTEXT_LINES = 5
}

-- // DATASTORE CONFIGURATION
LoggerConfig.DATASTORE = {
  STORE_NAME = "GameLogs_v1",
  MAX_LOGS_PER_PLAYER = 1000, -- Rotate old logs when exceeded
  SAVE_INTERVAL_SECONDS = 30, -- Auto-save interval
  INCLUDE_DEVICE_INFO = true,
  INCLUDE_PERFORMANCE_METRICS = true
}

-- // MEMORY STORAGE CONFIGURATION
LoggerConfig.MEMORY = {
  MAX_LOGS = 5000, -- Maximum logs kept in memory before rotation
  CLEANUP_INTERVAL_SECONDS = 60,
  PRESERVE_IMPORTANT_LOGS = true -- Keep ERROR+ logs even during cleanup
}

-- // LOG FORMATTING
LoggerConfig.FORMATTING = {
  TIMESTAMP_FORMAT = "[%H:%M:%S.%f]", -- 24-hour format with milliseconds
  INCLUDE_SCRIPT_NAME = true, -- Auto-detect calling script
  INCLUDE_LINE_NUMBER = true, -- Show line number where log was called
  MAX_MESSAGE_LENGTH = 2000, -- Truncate long messages
  COLOR_CODES = { -- Console color codes for different log levels
    TRACE = "\27[90m", -- Gray
    DEBUG = "\27[36m", -- Cyan  
    INFO = "\27[32m", -- Green
    WARN = "\27[33m", -- Yellow
    ERROR = "\27[31m", -- Red
    FATAL = "\27[35m", -- Magenta
    RESET = "\27[0m" -- Reset color
  }
}

-- // GUI CONFIGURATION
LoggerConfig.GUI = {
  TOGGLE_KEYBIND = Enum.KeyCode.F9, -- Key to open/close dev GUI
  CHAT_COMMAND = "/logs", -- Chat command to open GUI
  MAX_DISPLAYED_LOGS = 1000, -- Max logs shown in GUI before pagination
  AUTO_SCROLL = true, -- Auto-scroll to new logs
  EXPORT_SERVICES = { -- Services for log export
    PASTEBIN_API_KEY = "", -- Your Pastebin API key
    HASTEBIN_URL = "https://haste.zneix.eu" -- Alternative paste service
  },
  REFRESH_RATE_MS = 100, -- GUI refresh rate in milliseconds
  SEARCH_DEBOUNCE_MS = 300 -- Debounce search input
}

-- // PERFORMANCE SETTINGS
LoggerConfig.PERFORMANCE = {
  ASYNC_PROCESSING = true, -- Process logs asynchronously
  THREAD_POOL_SIZE = 3, -- Number of worker threads
  MAX_LOGS_PER_FRAME = 50, -- Max logs processed per heartbeat
  ENABLE_PROFILING = false, -- Profile logger performance (dev only)
  GARBAGE_COLLECTION_INTERVAL = 300 -- Force GC every N seconds
}

-- // DEBUG SETTINGS
LoggerConfig.DEBUG = {
  ENABLE_DEBUG_MODE = false, -- Enable extra debug output from logger itself
  LOG_LOGGER_ERRORS = true, -- Log errors that occur in the logger
  VALIDATE_LOG_INTEGRITY = false, -- Extra validation (performance cost)
  SIMULATE_NETWORK_ISSUES = false -- Simulate webhook/datastore failures (testing)
}

return LoggerConfig
