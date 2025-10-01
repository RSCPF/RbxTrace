# RbxTrace

A comprehensive, production-ready logging system for Roblox games with advanced features like real-time GUI monitoring, DataStore persistence, webhook alerts, and intelligent filtering.

[![CI/CD](https://github.com/RSCPF/RbxTrace/actions/workflows/ci.yml/badge.svg)](https://github.com/RSCPF/RbxTrace/actions/workflows/ci.yml)
[![Release](https://github.com/RSCPF/RbxTrace/actions/workflows/release.yml/badge.svg)](https://github.com/RSCPF/RbxTrace/actions/workflows/release.yml)
[![Wally](https://img.shields.io/badge/Wally-rscpf%2Frbxtrace-blue)](https://wally.run/package/rscpf/rbxtrace)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/RSCPF/RbxTrace)](https://github.com/RSCPF/RbxTrace/releases/latest)

## 🌟 Features

### Core Features

- **6 Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
- **Multiple Storage Backends**: Memory, DataStore, Webhooks
- **Client-Server Communication**: Secure Red remote integration
- **Developer GUI**: Real-time log viewer with filtering and search
- **Automatic Timestamps**: Precise timing with customizable formats
- **Script Detection**: Automatic caller identification with line numbers
- **Performance Optimized**: Async processing and smart batching

### Advanced Features

- **Group Rank Authentication**: Dev GUI only accessible to authorized users
- **Rate Limiting**: Prevents log spam and network overload
- **Export Functionality**: Export logs to Pastebin, JSON, CSV, or text
- **Webhook Integration**: Discord alerts for critical errors
- **Memory Management**: Automatic log rotation and cleanup
- **Search & Filtering**: Powerful filtering by level, title, script, etc.
- **Performance Monitoring**: Built-in performance tracking utilities

## 📦 Installation

### Using Wally (Recommended)

Add to your `wally.toml`:

```toml
[dependencies]
RbxTrace = "rscpf/rbxtrace@^0.0.1"
```

Then run:

```bash
wally install
```

### Manual Installation

1. Download the latest release
2. Place this repository in your `ReplicatedStorage.Packages`
3. Require it in your code: `local RbxTrace = require(game.ReplicatedStorage.Packages.RbxTrace)`

## 🚀 Quick Start

### 1. Basic Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxTrace = require(ReplicatedStorage.Packages.RbxTrace)

-- Initialize the logger (call this once at startup)
RbxTrace.Initialize()
```

### 2. Configuration

Before initializing, configure the logger by editing the config:

```lua
local config = RbxTrace.GetConfig()

-- Set your Discord webhook URL for error alerts
config.WEBHOOKS.DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/your-webhook-here"

-- Configure developer authentication for GUI access
config.DEV_AUTHENTICATION.GROUP_ID = 123456789  -- Your Roblox group ID
config.DEV_AUTHENTICATION.MIN_RANK = 100        -- Minimum rank for dev access

-- Adjust log level thresholds
config.STORAGE_THRESHOLDS.WEBHOOKS = config.LOG_LEVELS.ERROR  -- Only ERROR+ to Discord
config.STORAGE_THRESHOLDS.DATASTORE = config.LOG_LEVELS.INFO  -- INFO+ to DataStore

-- Then initialize
RbxTrace.Initialize()
```

### 3. Basic Logging

```lua
-- Basic logging methods
RbxTrace.Info("SystemName", "Something happened")
RbxTrace.Warn("SystemName", "Warning message")
RbxTrace.Error("SystemName", "Error occurred", {errorCode = 404, context = "user_action"})
RbxTrace.Debug("SystemName", "Debug information", {variable = "value"})

-- Global convenience functions (available after initialization)
LogInfo("SystemName", "Information message")
LogWarn("SystemName", "Warning message")
LogError("SystemName", "Error message")
```

### 4. Advanced Features

```lua
-- Log player actions with rich metadata
RbxTrace.LogPlayerAction(player, "WeaponFired", {
    weaponType = "AssaultRifle",
    accuracy = 0.85,
    ammo = 30
})

-- Log system events
RbxTrace.LogSystemEvent("Combat", "DamageDealt", {
    damage = 75,
    weapon = "Rifle",
    headshot = true
})

-- Performance monitoring
RbxTrace.LogPerformance("ChunkGeneration", duration, {
    chunkSize = "64x64",
    objectsGenerated = 150
})

-- Automatic performance monitoring
RbxTrace.StartPerformanceMonitoring(60) -- Every 60 seconds
```

## 📱 Developer GUI

### Accessing the GUI

- **Keybind**: F9 (configurable)
- **Chat Command**: `/logs` (configurable)
- **Programmatic**: `RbxTrace.GetGUI():ToggleGUI()`

> **Note**: GUI is only accessible to users with the configured group rank or those in the fallback UserIds list.

### GUI Features

- **Real-time Log Streaming**: See logs as they happen
- **Advanced Filtering**: Filter by level, title, script name, server/client
- **Search**: Full-text search across all log messages
- **Export**: Export filtered logs to Pastebin, JSON, CSV, or text format
- **Performance Stats**: View memory usage and log counts
- **Auto-scroll**: Optionally follow new logs automatically

## 🔧 Configuration

All configuration is done through the config object before initialization:

```lua
local config = RbxTrace.GetConfig()

-- Log level thresholds (what gets stored where)
config.STORAGE_THRESHOLDS = {
    MEMORY = config.LOG_LEVELS.TRACE,      -- All logs in memory
    CONSOLE = config.LOG_LEVELS.TRACE,     -- All logs to console
    DATASTORE = config.LOG_LEVELS.INFO,    -- INFO+ to DataStore
    WEBHOOKS = config.LOG_LEVELS.ERROR,    -- ERROR+ to webhooks
    CLIENT_TO_SERVER = config.LOG_LEVELS.WARN  -- WARN+ from client to server
}

-- Webhook configuration
config.WEBHOOKS = {
    DISCORD_WEBHOOK_URL = "your-webhook-url",
    RATE_LIMIT_SECONDS = 5,        -- Min time between sends
    BATCH_SIZE = 10,               -- Max logs per batch
    INCLUDE_STACK_TRACE = true,    -- Include traces for errors
    INCLUDE_RECENT_CONTEXT = true  -- Include recent logs before errors
}

-- Developer authentication
config.DEV_AUTHENTICATION = {
    GROUP_ID = 0,          -- Your group ID
    MIN_RANK = 100,        -- Minimum rank for dev features
    FALLBACK_USERIDS = {}  -- Backup dev UserIds
}

-- GUI settings
config.GUI = {
    TOGGLE_KEYBIND = Enum.KeyCode.F9,  -- GUI toggle key
    CHAT_COMMAND = "/logs",             -- Chat command
    MAX_DISPLAYED_LOGS = 1000,          -- Max logs in GUI
    EXPORT_SERVICES = {
        PASTEBIN_API_KEY = "",          -- Your Pastebin API key
    }
}
```

## 💡 Usage Examples

### Error Handling

```lua
local success, result = pcall(function()
    -- Risky operation
    return someComplexCalculation()
end)

if not success then
    RbxTrace.Error("DataProcessing", "Calculation failed", {
        errorMessage = result,
        inputData = data,
        recoverable = true
    })
end
```

### Performance Monitoring

```lua
-- Time expensive operations
local startTime = tick()
-- ... expensive operation ...
local duration = tick() - startTime

RbxTrace.LogPerformance("DatabaseQuery", duration, {
    query = "SELECT * FROM players",
    resultCount = 1500
})
```

### Player Behavior Tracking

```lua
-- Track player actions
RbxTrace.LogPlayerAction(player, "ItemPurchased", {
    itemName = "Golden Sword",
    price = 1000,
    currency = "Coins",
    shopCategory = "Weapons"
})

-- Monitor for exploits
if player.Character.Humanoid.WalkSpeed > 50 then
    RbxTrace.Warn("AntiCheat", "Suspicious speed detected", {
        playerId = player.UserId,
        speed = player.Character.Humanoid.WalkSpeed,
        expectedSpeed = 16
    })
end
```

## 📊 Log Levels

| Level | Value | Usage                    | Storage                      |
| ----- | ----- | ------------------------ | ---------------------------- |
| TRACE | 1     | Very detailed debugging  | Memory only                  |
| DEBUG | 2     | Development debugging    | Memory + Console             |
| INFO  | 3     | General information      | Memory + Console + DataStore |
| WARN  | 4     | Warnings and issues      | All storages                 |
| ERROR | 5     | Errors and exceptions    | All storages + Webhooks      |
| FATAL | 6     | Critical system failures | All storages + Webhooks      |

## 🏗️ Architecture

RbxTrace consists of several key components:

- **Logger**: Core logging engine with async processing
- **StorageManager**: Handles Memory, DataStore, and Webhook storage
- **LogRemote**: Secure client-server communication via Red
- **LoggerGUI**: Developer interface with real-time monitoring
- **LogEntry**: Structured log data with rich metadata

## 🔒 Security

- **Rate Limiting**: Prevents log spam and DoS attacks
- **Input Validation**: All data validated before processing
- **Authentication**: GUI restricted to authorized users only
- **Network Security**: Client-server communication secured
- **Size Limits**: Automatic truncation prevents memory issues

## 📈 Performance

- **Asynchronous Processing**: Non-blocking log operations
- **Smart Batching**: Efficient batch operations for storage
- **Memory Management**: Automatic cleanup and rotation
- **Configurable Limits**: Tune performance for your needs
- **Lazy Loading**: GUI components loaded on demand

## 🤝 Integration

### With Existing Frameworks

```lua
-- Easy integration with any framework
local MyFramework = {}
MyFramework.Logger = RbxTrace

function MyFramework:LogEvent(event, data)
    RbxTrace.Info("Framework", event, data)
end
```

### With External Services

```lua
-- Export logs for external analytics
local logs = RbxTrace.GetLogger():GetLogs({
    level = "INFO",
    startTime = tick() - 3600 -- Last hour
})

local exportData = RbxTrace.GetLogger().StorageManager:ExportLogs("JSON", {
    level = "ERROR"
})
-- Send to external service
```

## 📚 API Reference

### Core Methods

- `RbxTrace.Initialize()` - Initialize the logging system
- `RbxTrace.Trace(title, message, metadata?)` - Log trace message
- `RbxTrace.Debug(title, message, metadata?)` - Log debug message
- `RbxTrace.Info(title, message, metadata?)` - Log info message
- `RbxTrace.Warn(title, message, metadata?)` - Log warning message
- `RbxTrace.Error(title, message, metadata?)` - Log error message
- `RbxTrace.Fatal(title, message, metadata?)` - Log fatal message

### Specialized Methods

- `RbxTrace.LogPlayerAction(player, action, details)` - Log player actions
- `RbxTrace.LogSystemEvent(system, event, data)` - Log system events
- `RbxTrace.LogPerformance(operation, duration, metadata)` - Log performance
- `RbxTrace.StartPerformanceMonitoring(interval?)` - Auto performance monitoring

### Utility Methods

- `RbxTrace.GetLogger()` - Get logger instance
- `RbxTrace.GetConfig()` - Get configuration object
- `RbxTrace.GetGUI()` - Get GUI controller
- `RbxTrace.GetSystemStats()` - Get system statistics

## 🔧 Troubleshooting

### Common Issues

**GUI not appearing:**

- Verify you're in the configured group with sufficient rank
- Check `DEV_AUTHENTICATION` settings in config
- Try chat command if keybind not working

**Webhooks not working:**

- Verify webhook URL is correct
- Check Discord webhook permissions
- Monitor rate limiting settings

**Performance issues:**

- Reduce log levels for high-frequency operations
- Increase cleanup intervals
- Consider raising storage thresholds

**DataStore errors:**

- Check DataStore permissions in game settings
- Monitor API request limits
- Verify DataStore service availability

### Debug Mode

Enable debug mode for troubleshooting:

```lua
local config = RbxTrace.GetConfig()
config.DEBUG.ENABLE_DEBUG_MODE = true
config.DEBUG.LOG_LOGGER_ERRORS = true
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Check this README and inline code documentation
- **Discord**: Contact agentracct privately for Support

---

**RbxTrace** - Production-ready logging for Roblox games.

Built with ❤️ by RSCPF for the Roblox development community.
