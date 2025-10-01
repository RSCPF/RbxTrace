--[[
    RbxTrace - FRAMEWORK INTEGRATION EXAMPLE
    
    This example shows how to integrate RbxTrace
    into an existing game framework or architecture.
]] local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RbxTrace = require(ReplicatedStorage.Packages.RbxTrace)

--[[
    EXAMPLE GAME FRAMEWORK WITH INTEGRATED LOGGING
]]
local GameFramework = {}
GameFramework.Controllers = {}
GameFramework.Services = {}
GameFramework.IsInitialized = false

-- Integrate RbxTrace into the framework
GameFramework.Logger = RbxTrace

--[[
    FRAMEWORK INITIALIZATION WITH LOGGING
]]
function GameFramework:Initialize()
  if self.IsInitialized then
    return
  end

  -- Configure and initialize RbxTrace
  local config = RbxTrace.GetConfig()
  config.WEBHOOKS.DISCORD_WEBHOOK_URL = "your-webhook-url-here"
  config.DEV_AUTHENTICATION.GROUP_ID = 123456789
  RbxTrace.Initialize()

  -- Log framework startup
  self.Logger.Info("Framework", "GameFramework initialization started")

  -- Initialize controllers and services
  self:InitializeControllers()
  self:InitializeServices()

  self.IsInitialized = true
  self.Logger.Info("Framework", "GameFramework initialization completed")
end

function GameFramework:InitializeControllers()
  self.Logger.Debug("Framework", "Loading controllers...")

  -- Example controller loading with logging
  for _, controllerScript in pairs(script.Controllers:GetChildren()) do
    if controllerScript:IsA("ModuleScript") then
      local success, controller = pcall(require, controllerScript)
      if success then
        self.Controllers[controllerScript.Name] = controller
        self.Logger.Info("Framework", string.format("Loaded controller: %s", controllerScript.Name))

        -- Initialize controller if it has an Init method
        if controller.Init then
          controller:Init(self)
        end
      else
        self.Logger.Error("Framework", string.format("Failed to load controller: %s", controllerScript.Name), {
          error = controller,
          scriptName = controllerScript.Name
        })
      end
    end
  end
end

function GameFramework:InitializeServices()
  self.Logger.Debug("Framework", "Loading services...")
  -- Similar pattern for services
end

--[[
    FRAMEWORK LOGGING CONVENIENCES
]]
function GameFramework:Log(level, system, message, metadata)
  return self.Logger[level](system, message, metadata)
end

function GameFramework:LogControllerAction(controllerName, action, data)
  return self.Logger.Info("Controller:" .. controllerName, action, data or {})
end

function GameFramework:LogServiceEvent(serviceName, event, data)
  return self.Logger.Info("Service:" .. serviceName, event, data or {})
end

--[[
    EXAMPLE CONTROLLER WITH INTEGRATED LOGGING
]]
local WeaponController = {}

function WeaponController:Init(framework)
  self.Framework = framework
  self.Logger = framework.Logger

  self.Logger.Debug("WeaponController", "Weapon controller initialized")
end

function WeaponController:FireWeapon(weaponData)
  -- Log weapon firing with detailed metadata
  self.Logger.Info("Weapons", "Weapon fired", {
    weaponType = weaponData.Type,
    ammo = weaponData.Ammo,
    accuracy = weaponData.Accuracy,
    damage = weaponData.Damage,
    fireMode = weaponData.FireMode
  })

  -- Performance tracking
  local startTime = tick()
  self:ProcessWeaponFire(weaponData)
  local duration = tick() - startTime

  self.Logger.LogPerformance("WeaponFire", duration, {
    weaponType = weaponData.Type,
    complexity = "standard"
  })
end

function WeaponController:ProcessWeaponFire(weaponData)
  -- Weapon firing logic here
  task.wait(0.01) -- Simulate processing time
end

function WeaponController:OnWeaponJam(weaponData)
  -- Log weapon malfunction as error
  self.Logger.Error("Weapons", "Weapon malfunction detected", {
    weaponId = weaponData.Id,
    weaponType = weaponData.Type,
    condition = weaponData.Condition,
    roundsFired = weaponData.RoundsFired,
    malfunctionType = "jam"
  })
end

--[[
    EXAMPLE SERVICE WITH INTEGRATED LOGGING
]]
local PlayerDataService = {}

function PlayerDataService:Init(framework)
  self.Framework = framework
  self.Logger = framework.Logger

  self.Logger.Debug("PlayerDataService", "Player data service initialized")
end

function PlayerDataService:LoadPlayerData(player)
  self.Logger.Info("PlayerData", "Loading player data", {
    playerId = player.UserId,
    playerName = player.Name
  })

  local startTime = tick()
  local success, data = pcall(function()
    -- Simulate data loading
    task.wait(0.1)
    return {
      level = 25,
      experience = 15000,
      coins = 5000,
      items = {"sword", "shield", "potion"}
    }
  end)

  local duration = tick() - startTime

  if success then
    self.Logger.Info("PlayerData", "Player data loaded successfully", {
      playerId = player.UserId,
      loadTime = duration,
      dataSize = #game:GetService("HttpService"):JSONEncode(data)
    })

    self.Logger.LogPerformance("PlayerDataLoad", duration, {
      playerId = player.UserId,
      success = true
    })

    return data
  else
    self.Logger.Error("PlayerData", "Failed to load player data", {
      playerId = player.UserId,
      error = data,
      loadTime = duration,
      retryable = true
    })

    return nil
  end
end

function PlayerDataService:SavePlayerData(player, data)
  self.Logger.Debug("PlayerData", "Saving player data", {
    playerId = player.UserId
  })

  local success, result = pcall(function()
    -- Simulate data saving
    task.wait(0.05)
    return true
  end)

  if success then
    self.Logger.Info("PlayerData", "Player data saved", {
      playerId = player.UserId,
      dataSize = #game:GetService("HttpService"):JSONEncode(data)
    })
  else
    self.Logger.Error("PlayerData", "Failed to save player data", {
      playerId = player.UserId,
      error = result,
      critical = true
    })
  end
end

--[[
    AUTOMATIC ERROR HANDLING WRAPPER
]]
function GameFramework:WrapWithLogging(func, systemName, operationName)
  return function(...)
    local startTime = tick()
    local success, result = pcall(func, ...)
    local duration = tick() - startTime

    if success then
      if duration > 0.1 then -- Log slow operations
        self.Logger.Warn(systemName, string.format("Slow operation: %s", operationName), {
          duration = duration,
          operation = operationName
        })
      else
        self.Logger.Debug(systemName, string.format("Operation completed: %s", operationName), {
          duration = duration
        })
      end
      return result
    else
      self.Logger.Error(systemName, string.format("Operation failed: %s", operationName), {
        error = result,
        duration = duration,
        operation = operationName
      })
      error(result) -- Re-throw the error
    end
  end
end

--[[
    USAGE EXAMPLE
]]
local function ExampleUsage()
  -- Initialize framework with logging
  GameFramework:Initialize()

  -- Add controllers to framework
  GameFramework.Controllers.WeaponController = WeaponController
  GameFramework.Services.PlayerDataService = PlayerDataService

  -- Initialize them
  WeaponController:Init(GameFramework)
  PlayerDataService:Init(GameFramework)

  -- Use the integrated logging
  GameFramework:LogControllerAction("WeaponController", "ControllerReady", {
    weaponTypes = {"rifle", "pistol", "shotgun"}
  })

  -- Example weapon firing
  WeaponController:FireWeapon({
    Type = "AssaultRifle",
    Ammo = 30,
    Accuracy = 0.85,
    Damage = 75,
    FireMode = "Auto"
  })

  -- Example data operations
  local mockPlayer = {
    UserId = 123456,
    Name = "TestPlayer"
  }
  local playerData = PlayerDataService:LoadPlayerData(mockPlayer)
  if playerData then
    PlayerDataService:SavePlayerData(mockPlayer, playerData)
  end

  -- Use error handling wrapper
  local safeCalculation = GameFramework:WrapWithLogging(function(a, b)
    return a / b -- This could fail if b is 0
  end, "Math", "Division")

  -- This will be logged as successful
  local result1 = safeCalculation(10, 2)

  -- This will be logged as an error
  local success, result2 = pcall(function()
    return safeCalculation(10, 0)
  end)
end

-- Run the example
ExampleUsage()

return GameFramework
