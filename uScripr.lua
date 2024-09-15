local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local player = game.Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "X-Ware",
    SubTitle = player.DisplayName .. " | " .. player.Name,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Self = Window:AddTab({ Title = "Self", Icon = "user" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "compass" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ESP Functionality
local function createESP(object, color)
    local highlight = Instance.new("Highlight", object)
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Adornee = object

    local billboard = Instance.new("BillboardGui", object)
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Text = "" -- Ensure default text is an empty string

    return highlight, billboard, label
end

local function updateDistanceText(object, billboard, label, isPlayer)
    local playerPos = player.Character.HumanoidRootPart.Position
    local targetPos = isPlayer and object.HumanoidRootPart.Position or object.Handle.Position
    local distance = (playerPos - targetPos).Magnitude

    -- Update text with distance and name, and add "(Spider)" if applicable
    local name = isPlayer and object.Name or object.Name
    if isPlayer and object:FindFirstChild("isSpiderCharacter") and object.isSpiderCharacter.Value == true then
        name = name .. " (Spider)" -- Add the Spider tag
    end
    label.Text = name .. " [" .. math.floor(distance) .. " studs]"
end

local activeESPItems = {}
local activeESPPlayers = {}

local function espItems(active)
    if active then
        for _, item in pairs(workspace.Items:GetChildren()) do
            if item:FindFirstChild("Handle") then
                local randomColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
                local highlight, billboard, label = createESP(item.Handle, randomColor)
                activeESPItems[item] = {highlight, billboard}

                game:GetService("RunService").RenderStepped:Connect(function()
                    if item:FindFirstChild("Handle") then
                        updateDistanceText(item, billboard, label, false)
                    end
                end)
            end
        end
    else
        for item, espData in pairs(activeESPItems) do
            espData[1]:Destroy() -- highlight
            espData[2]:Destroy() -- billboard
        end
        activeESPItems = {}
    end
end

local function espPlayers(active)
    if active then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local isSpider = false
                local color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)) -- Default random color

                -- Check if the player has a "isSpiderCharacter" BoolValue
                if player.Character:FindFirstChild("IsSpiderCharacter") and player.Character.IsSpiderCharacter.Value == true then
                    color = Color3.fromRGB(255, 0, 0) -- Red color for Spider character
                    isSpider = true
                end

                local highlight, billboard, label = createESP(player.Character.HumanoidRootPart, color)
                label.Text = player.DisplayName -- Ensuring display name is a valid string
                activeESPPlayers[player] = {highlight, billboard}

                game:GetService("RunService").RenderStepped:Connect(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        updateDistanceText(player.Character, billboard, label, true)
                    end
                end)
            end
        end
    else
        for player, espData in pairs(activeESPPlayers) do
            espData[1]:Destroy() -- highlight
            espData[2]:Destroy() -- billboard
        end
        activeESPPlayers = {}
    end
end

Tabs.Visuals:AddToggle("ESPItems", {Title = "ESP Items", Default = false}):OnChanged(function(active)
    espItems(active)
end)

Tabs.Visuals:AddToggle("ESPPlayers", {Title = "ESP Players", Default = false}):OnChanged(function(active)
    espPlayers(active)
end)

local loopConnection = nil

local WebPlaceToggle = Tabs.Self:AddToggle("WebPlaceToggle", {
    Title = "Auto Place Web",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Start the loop when toggle is turned on
            loopConnection = game:GetService("RunService").Heartbeat:Connect(function()
                local args = {
                    [1] = "AttemptPlaceWeb"
                }
                game:GetService("ReplicatedStorage").modules.up.Network.RemoteFunction:InvokeServer(unpack(args))
                task.wait(1) -- Wait for 1 second before next iteration
            end)
        else
            -- Stop the loop when toggle is turned off
            if loopConnection then
                loopConnection:Disconnect()
                loopConnection = nil
            end
        end
    end
})

-- Self Tab Functionality
Tabs.Self:AddSlider("Walkspeed", {
    Title = "Walkspeed", 
    Min = 1, 
    Max = 70, 
    Default = 16, 
    Rounding = 0
}):OnChanged(function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)

Tabs.Self:AddSlider("JumpPower", {
    Title = "Jump Power", 
    Min = 5, 
    Max = 800, 
    Default = 50, 
    Rounding = 0
}):OnChanged(function(value)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
end)

Tabs.Self:AddSlider("FieldOfView", {
    Title = "Field of View", 
    Min = 20, 
    Max = 120, 
    Default = 70, 
    Rounding = 0
}):OnChanged(function(value)
    game.Workspace.CurrentCamera.FieldOfView = value
end)

-- Movement Tab Functionality
local selectedPlayer = nil

local function refreshPlayerList(dropdown)
    local players = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        table.insert(players, p.Name)
    end
    dropdown:SetValues(players)
end

local playerDropdown = Tabs.Movement:AddDropdown("SelectPlayer", {Title = "Select Player", Values = {}})
refreshPlayerList(playerDropdown)

playerDropdown:OnChanged(function(value)
    selectedPlayer = value
end)

Tabs.Movement:AddButton({Title = "Teleport to Selected Player", Callback = function()
    if selectedPlayer then
        local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end})

Tabs.Movement:AddButton({Title = "Refresh Player List", Callback = function()
    refreshPlayerList(playerDropdown)
end})

-- Item Teleport Functionality
local function teleportToItem(item)
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = item.Handle.CFrame
end

local itemSection = Tabs.Movement:AddSection("Items")

for _, item in pairs(workspace.Items:GetChildren()) do
    itemSection:AddButton({Title = "Teleport to " .. item.Name, Callback = function()
        teleportToItem(item)
    end})
end

-- Save Manager and Interface Setup
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("X-WareScriptHub")
SaveManager:SetFolder("X-WareScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "X-Ware",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
