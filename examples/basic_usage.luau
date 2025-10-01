--[[
    RbxTrace - BASIC USAGE EXAMPLE
    
    This example shows how to set up and use RbxTrace
    in a simple Roblox game or framework.
]] local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Require RbxTrace from Wally packages
local RbxTrace = require(ReplicatedStorage.Packages.RbxTrace)

--[[
    STEP 1: CONFIGURATION
    Configure the logger before initialization
]]
local function ConfigureLogger()
  local config = RbxTrace.GetConfig()

  -- Set your Discord webhook for error alerts
  config.WEBHOOKS.DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/your-webhook-here"

  -- Configure developer access (replace with your group ID and rank)
  config.DEV_AUTHENTICATION.GROUP_ID = 123456789 -- Your group ID
  config.DEV_AUTHENTICATION.MIN_RANK = 100 -- Minimum rank for dev access

  -- You can also add fallback UserIds for developers
  config.DEV_AUTHENTICATION.FALLBACK_USERIDS = {
    -- 123456789,  -- Your UserID
    -- 987654321,  -- Another dev's UserID
  }

  -- Adjust what gets logged where
  config.STORAGE_THRESHOLDS.WEBHOOKS = config.LOG_LEVELS.ERROR -- Only errors to Discord
  config.STORAGE_THRESHOLDS.DATASTORE = config.LOG_LEVELS.INFO -- Info+ to DataStore

  -- Configure GUI settings
  config.GUI.TOGGLE_KEYBIND = Enum.KeyCode.F9 -- Press F9 to open dev GUI
  config.GUI.CHAT_COMMAND = "/logs" -- Type /logs to open dev GUI
end

--[[
    STEP 2: INITIALIZATION
    Initialize the logger system
]]
local function InitializeLogger()
  ConfigureLogger()
  RbxTrace.Initialize()

  -- The logger is now ready to use!
  RbxTrace.Info("Example", "RbxTrace initialized successfully!")
end

--[[
    STEP 3: BASIC LOGGING EXAMPLES
]]
local function BasicLoggingExamples()
  -- Different log levels
  RbxTrace.Trace("Example", "This is trace level - very detailed debugging")
  RbxTrace.Debug("Example", "This is debug level - development info")
  RbxTrace.Info("Example", "This is info level - general information")
  RbxTrace.Warn("Example", "This is warn level - something might be wrong")
  RbxTrace.Error("Example", "This is error level - something went wrong")
  -- RbxTrace.Fatal("Example", "This is fatal level - critical system failure")

  -- Logging with metadata
  RbxTrace.Info("Example", "Player data loaded", {
    playerId = 123456,
    loadTime = 0.5,
    dataSize = "2KB",
    success = true
  })

  -- Using global convenience functions (available after initialization)
  LogInfo("Example", "Global function works too!")
  LogDebug("Example", "Debug message via global function")
end

--[[
    STEP 4: PLAYER MANAGEMENT WITH LOGGING
]]
local function SetupPlayerLogging()
  Players.PlayerAdded:Connect(function(player)
    -- Log player join
    RbxTrace.LogPlayerAction(player, "PlayerJoined", {
      accountAge = player.AccountAge,
      userId = player.UserId,
      displayName = player.DisplayName,
      joinTime = tick()
    })

    -- Log when character spawns
    player.CharacterAdded:Connect(function(character)
      RbxTrace.Info("Players", string.format("Character spawned for %s", player.Name), {
        playerId = player.UserId,
        spawnTime = tick()
      })
    end)
  end)

  Players.PlayerRemoving:Connect(function(player)
    -- Log player leave
    RbxTrace.LogPlayerAction(player, "PlayerLeft", {
      sessionDuration = tick() - (player:GetAttribute("JoinTime") or tick()),
      userId = player.UserId
    })
  end)
end

--[[
    STEP 5: ERROR HANDLING WITH LOGGING
]]
local function ErrorHandlingExample()
  -- Wrap risky operations with error logging
  local function SafeOperation()
    local success, result = pcall(function()
      -- Some operation that might fail
      local data = workspace:FindFirstChild("SomeImportantPart")
      if not data then
        error("Important part not found!")
      end
      return data
    end)

    if not success then
      RbxTrace.Error("SafeOperation", "Operation failed", {
        errorMessage = result,
        context = "startup_sequence",
        recoverable = true
      })
      return nil
    end

    return result
  end

  -- Try the operation
  local result = SafeOperation()
  if result then
    RbxTrace.Info("SafeOperation", "Operation completed successfully")
  end
end

--[[
    STEP 6: PERFORMANCE MONITORING
]]
local function PerformanceMonitoringExample()
  -- Manual performance logging
  local function ExpensiveOperation()
    local startTime = tick()

    -- Simulate expensive work
    local total = 0
    for i = 1, 100000 do
      total = total + math.random()
    end

    local duration = tick() - startTime
    RbxTrace.LogPerformance("ExpensiveOperation", duration, {
      operationType = "calculation",
      iterations = 100000,
      result = total
    })

    return total
  end

  -- Run the expensive operation
  ExpensiveOperation()

  -- Start automatic performance monitoring (every 30 seconds)
  RbxTrace.StartPerformanceMonitoring(30)
end

--[[
    STEP 7: SYSTEM EVENT LOGGING
]]
local function SystemEventExample()
  -- Log system events
  RbxTrace.LogSystemEvent("GameState", "RoundStarted", {
    roundNumber = 1,
    maxPlayers = 20,
    currentPlayers = #Players:GetPlayers(),
    gameMode = "Classic"
  })

  -- Log when game state changes
  task.wait(5)
  RbxTrace.LogSystemEvent("GameState", "RoundEnded", {
    roundNumber = 1,
    duration = 300, -- 5 minutes
    winner = "TeamA",
    finalScore = "10-8"
  })
end

--[[
    STEP 8: ACCESSING THE DEVELOPER GUI
]]
local function DeveloperGUIInstructions()
  RbxTrace.Info("Example", "Developer GUI Instructions:")
  RbxTrace.Info("Example", "1. Press F9 to open/close the developer GUI")
  RbxTrace.Info("Example", "2. Type '/logs' in chat to open the GUI")
  RbxTrace.Info("Example", "3. Use the GUI to filter, search, and export logs")
  RbxTrace.Info("Example", "4. GUI is only available to configured developers")
end

--[[
    MAIN EXECUTION
]]
local function Main()
  -- Initialize the logger
  InitializeLogger()

  -- Run examples
  BasicLoggingExamples()
  SetupPlayerLogging()
  ErrorHandlingExample()
  PerformanceMonitoringExample()
  SystemEventExample()
  DeveloperGUIInstructions()

  -- Log completion
  RbxTrace.Info("Example", "All examples completed! RbxTrace is ready to use.")

  -- Show stats
  task.wait(1)
  local stats = RbxTrace.GetSystemStats()
  RbxTrace.Info("Example", "System Stats", {
    totalLogs = stats.totalLogs,
    uptime = stats.uptime,
    memoryLogs = stats.memoryLogs,
    isRunning = stats.isRunning
  })
end

-- Run the example
Main()

--[[
    NEXT STEPS:
    
    1. Replace the webhook URL and group settings with your actual values
    2. Integrate logging into your existing game systems
    3. Use the developer GUI to monitor logs in real-time
    4. Set up DataStore permissions for log persistence
    5. Configure webhook alerts for critical errors
    
    For more examples, check the other files in this examples folder!
]]
