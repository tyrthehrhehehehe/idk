local ScriptURL = "YOUR_RAW_SCRIPT_URL_HERE"

local queueteleport = queue_on_teleport 
    or (syn and syn.queue_on_teleport) 
    or (fluxus and fluxus.queue_on_teleport)

local TeleportCheck = false
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started and not TeleportCheck and queueteleport then
        TeleportCheck = true
        queueteleport('loadstring(game:HttpGet("' .. ScriptURL .. '"))()')
    end
end)

-- [[ CATTSTAR HUB ]]
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local states = {
    autoCollect = false,
    collectRadius = 50,
    autoRoll = false,
    autoRebirth = false,
    rebirthDelay = 15,
    autoEquipBest = false,
    autoBuyZone = false,
    autoClaimIndex = false,
    autousePortions = false,
    autoCollectRecipe = false,
    walkSpeedValue = 32,
    antiAFK = false
}

-- [[ REMOTE UTILITIES ]]
local localPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local basePath = {"Packages", "_Index", "leifstout_networker@0.3.1", "networker", "_remotes",}

local function navigatePath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local remotesFolder = navigatePath(ReplicatedStorage, basePath)

local function getRemote(name, remoteType)
    if not remotesFolder then return nil end
    local folder = remotesFolder:FindFirstChild(name)
    if not folder then return nil end
    return folder:FindFirstChild(remoteType)
end

local rollRE      = getRemote("RollService", "RemoteEvent")
local rebirthRF   = getRemote("RebirthService", "RemoteFunction")
local codeRF      = getRemote("CodeService", "RemoteFunction")
local indexRF     = getRemote("IndexService", "RemoteFunction")
local inventoryRF = getRemote("InventoryService", "RemoteFunction")
local zonesRF     = getRemote("ZonesService", "RemoteFunction")
local BoostRF     = getRemote("BoostService", "RemoteFunction")

local function getGameplayFolder()
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name:lower():find("gameplay") then
            return child
        end
    end
    return nil
end

local function getClosestMob()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local gameplayFolder = getGameplayFolder()
    if not gameplayFolder then return nil end
    
    local enemies = gameplayFolder:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    local closest = nil
    local shortestDistance = math.huge
    
    for _, enemy in pairs(enemies:GetChildren()) do
        local root = enemy:FindFirstChild("RootPart")
        if root then
            local distance = (root.Position - character.HumanoidRootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closest = root
            end
        end
    end
    return closest
end

local Window = WindUI:CreateWindow({
    Title = "Cattstar Hub",
    Icon = "snowflake",
    Author = "",
    Folder = "CattstarHubConfig"
})

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

MainTab:Section({ Title = "Farming" })

MainTab:Toggle({
    Title = "Auto Collect",
    Desc = "Collects nearby loot objects",
    Value = states.autoCollect,
    Callback = function(state)
        states.autoCollect = state
        task.spawn(function()
            while states.autoCollect do
                local player = game:GetService("Players").LocalPlayer
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local lootFolder = workspace:FindFirstChild("Loot")
                
                if hrp and lootFolder then
                    for _, lootObject in ipairs(lootFolder:GetChildren()) do
                        if not states.autoCollect then break end
                        
                        local touchPart = nil
                        for _, child in ipairs(lootObject:GetChildren()) do
                            if (child:IsA("MeshPart") or child:IsA("BasePart")) and child:FindFirstChild("TouchInterest") then
                                touchPart = child
                                break
                            end
                        end
                        
                        if touchPart then
                            local distance = (hrp.Position - touchPart.Position).Magnitude
                            if distance <= states.collectRadius then
                                pcall(function()
                                    firetouchinterest(hrp, touchPart, 0)
                                    task.wait()
                                    firetouchinterest(hrp, touchPart, 1)
                                end)
                                task.wait(0.05)
                            end
                        end
                    end
                end
                task.wait(0.2)
            end
        end)
    end
})

MainTab:Slider({
    Title = "Collect Radius",
    Step = 1,
    Value = { Min = 10, Max = 200, Default = states.collectRadius },
    Callback = function(value) states.collectRadius = value end
})

MainTab:Toggle({
    Title = "Auto Mobs",
    Desc = "Tweens to the nearest mob automatically",
    Value = false,
    Callback = function(state)
        getgenv().AutoMob = state
        
        if state then
            task.spawn(function()
                while getgenv().AutoMob do
                    local target = getClosestMob()
                    local character = localPlayer.Character
                    
                    if target and character and character:FindFirstChild("HumanoidRootPart") then
                        local hrp = character.HumanoidRootPart
                        local tweenService = game:GetService("TweenService")
                        local distance = (target.Position - hrp.Position).Magnitude
                        local tweenInfo = TweenInfo.new(distance / 100, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                        local tween = tweenService:Create(hrp, tweenInfo, {CFrame = target.CFrame})
                        tween:Play()
                        tween.Completed:Wait()
                    end
                    task.wait(0.5) 
                end
            end)
        end
    end
})

MainTab:Toggle({
    Title = "Auto Roll",
    Desc = "Spams requestRoll event",
    Value = states.autoRoll,
    Callback = function(state)
        states.autoRoll = state
        task.spawn(function()
            while states.autoRoll do
                if rollRE then rollRE:FireServer("requestRoll") end
                task.wait(0.1)
            end
        end)
    end
})

MainTab:Section({ Title = "Progression" })

MainTab:Toggle({
    Title = "Auto Rebirth",
    Value = states.autoRebirth,
    Callback = function(state)
        states.autoRebirth = state
        task.spawn(function()
            while states.autoRebirth do
                if rebirthRF then rebirthRF:InvokeServer("requestRebirth") end
                task.wait(states.rebirthDelay)
            end
        end)
    end
})

MainTab:Slider({
    Title = "Rebirth Delay",
    Step = 1,
    Value = { Min = 5, Max = 60, Default = states.rebirthDelay },
    Callback = function(value) states.rebirthDelay = value end
})

MainTab:Toggle({
    Title = "Auto Equip Best",
    Value = states.autoEquipBest,
    Callback = function(state)
        states.autoEquipBest = state
        task.spawn(function()
            while states.autoEquipBest do
                if inventoryRF then inventoryRF:InvokeServer("requestEquipBest") end
                task.wait(5)
            end
        end)
    end
})

MainTab:Toggle({
    Title = "Auto Buy Zone",
    Value = states.autoBuyZone,
    Callback = function(state)
        states.autoBuyZone = state
        task.spawn(function()
            while states.autoBuyZone do
                if zonesRF then zonesRF:InvokeServer("requestPurchaseZone") end
                task.wait(2)
            end
        end)
    end
})

MainTab:Toggle({
    Title = "Auto Claim Index",
    Value = states.autoClaimIndex,
    Callback = function(state)
        states.autoClaimIndex = state
        task.spawn(function()
            while states.autoClaimIndex do
                for _, category in ipairs({"basic", "big", "huge", "shiny", "inverted"}) do
                    if indexRF then indexRF:InvokeServer("requestClaimReward", category) end
                    task.wait(0.2)
                end
                task.wait(10)
            end
        end)
    end
})

MainTab:Toggle({
    Title = "Auto use all portions",
    Value = states.autousePortions,
    Callback = function(state)
        states.autousePortions = state
        task.spawn(function()
            while states.autousePortions do
                for _, category in ipairs({"luck", "rollSpeed", "currency"}) do
                    if BoostRF then BoostRF:InvokeServer("requestUseBoost", category) end
                    task.wait(0.2)
                end
                task.wait(10)
            end
        end)
    end
})

MainTab:Toggle({
    Title = "Auto Collect Recipe",
    Desc = "Teleports to recipes and interacts",
    Value = states.autoCollectRecipe,
    Callback = function(state)
        states.autoCollectRecipe = state
        task.spawn(function()
            while states.autoCollectRecipe do
                local zones = workspace:FindFirstChild("Zones")
                local hrp = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local VIM = game:GetService("VirtualInputManager")
                if zones and hrp then
                    local originalCFrame = hrp.CFrame
                    for _, zone in pairs(zones:GetChildren()) do
                        if not states.autoCollectRecipe then break end
                        for _, recipeObj in pairs(zone:GetChildren()) do
                            if recipeObj.Name:match("^Recipe") then
                                local attachment = recipeObj:FindFirstChild("RecipePromptAttachment")
                                local prompt = attachment and attachment:FindFirstChild("RecipePrompt")
                                if prompt then
                                    local teleportPart = recipeObj:FindFirstChild("MeshPart") or recipeObj:FindFirstChild("Part") or recipeObj
                                    if teleportPart and teleportPart:IsA("BasePart") then
                                        pcall(function()
                                            prompt.MaxActivationDistance = 99999
                                            prompt.HoldDuration = 0
                                            hrp.CFrame = teleportPart.CFrame + Vector3.new(0, 3, 0)
                                            task.wait(0.2)
                                            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                            task.wait(0.05)
                                            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                            task.wait(0.2)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    hrp.CFrame = originalCFrame
                end
                task.wait(30)
            end
        end)
    end
})

local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings-2" })

MiscTab:Section({ Title = "Player Settings" })

MiscTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = states.walkSpeedValue },
    Callback = function(value) states.walkSpeedValue = value end
})

local AntiAfkService = { Active = false, Connection = nil }

local function removeAutoRejoin()
    pcall(function()
        local paths = {
            ReplicatedStorage.Packages._Index["leifstout_networker@0.3.1"].networker._remotes:FindFirstChild("AutoRejoinService"),
            ReplicatedStorage:FindFirstChild("Source") and ReplicatedStorage.Source.Features:FindFirstChild("AutoRejoin"),
            ReplicatedStorage:FindFirstChild("AutoRejoin"),
            ReplicatedStorage:FindFirstChild("AutoRejoinService")
        }
        for _, obj in pairs(paths) do if obj then obj:Destroy() end end
    end)
end

MiscTab:Toggle({
    Title = "Anti AFK",
    Desc = "Prevents disconnection & blocks AutoRejoin",
    Value = false,
    Callback = function(state)
        if state then
            removeAutoRejoin()
            AntiAfkService.Active = true
            AntiAfkService.Connection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                if AntiAfkService.Active then
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end
            end)
        else
            AntiAfkService.Active = false
            if AntiAfkService.Connection then AntiAfkService.Connection:Disconnect() end
        end
    end
})

MiscTab:Button({
    Title = "Redeem All Codes",
    Icon = "ticket",
    Callback = function()
        if not codeRF then return end
        for _, code in ipairs({"2muchluck", "test", "gullible"}) do
            pcall(function() codeRF:InvokeServer("redeem", code) end)
            task.wait(0.5)
        end
        WindUI:Notify({ Title = "Codes", Content = "Redemption complete", Duration = 3 })
    end
})

task.spawn(function()
    while task.wait() do
        pcall(function()
            local char = game:GetService("Players").LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = states.walkSpeedValue
            end
        end)
    end
end)
