--[[ 
ADMIN PANEL V2
]]

--// LOAD RAYFIELD UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// SAFE CHARACTER FUNCTIONS
local function GetCharacterSafe(player)
    player = player or LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

local function GetRootSafe(char)
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
end

--// GLOBAL STATE
getgenv().Settings = {
    Fly = false,
    FlySpeed = 50,
    NoClip = false,
    ESP = false,
    ESPNames = true,
    ESPDistance = true,
    ESPArrows = true,
    ESPMaxDistance = 1000,
}

--// UTILITY FUNCTIONS
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function WorldToScreen(position)
    local point, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), onScreen
end

--// FLY SYSTEM
local BV, BodyGyro

local function EnableFly()
    local root = GetRoot()
    if not root then return end
    
    if not BV then
        BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(1, 1, 1) * 1e6
        BV.Velocity = Vector3.zero
        BV.Parent = root
    end
    
    if not BodyGyro then
        BodyGyro = Instance.new("BodyGyro")
        BodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 1e6
        BodyGyro.CFrame = root.CFrame
        BodyGyro.Parent = root
    end
    
    local humanoid = GetHumanoid()
    if humanoid then humanoid.PlatformStand = true end
end

local function DisableFly()
    if BV then BV:Destroy(); BV = nil end
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    local humanoid = GetHumanoid()
    if humanoid then humanoid.PlatformStand = false end
end

local function ToggleFly()
    Settings.Fly = not Settings.Fly
    if not Settings.Fly then DisableFly() end
    Rayfield:Notify({
        Title = "Fly",
        Content = Settings.Fly and "Enabled" or "Disabled",
        Duration = 1,
        Image = 4483362458,
    })
end

local function HandleFly()
    if not Settings.Fly then return end
    local root = GetRoot()
    if not root then return end
    EnableFly()
    
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
    
    if BV then
        BV.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.FlySpeed or Vector3.zero
    end
    if BodyGyro then
        BodyGyro.CFrame = CFrame.new(root.Position, root.Position + Camera.CFrame.LookVector)
    end
end

--// NO CLIP SYSTEM
local NoclipConnection

local function EnableNoClip()
    if NoclipConnection then return end
    NoclipConnection = RunService.Stepped:Connect(function()
        if Settings.NoClip then
            local char = GetCharacter()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end)
end

local function DisableNoClip()
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    local char = GetCharacter()
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

--// ESP SYSTEM 
local ESPData = {}

local function CreateArrowDrawing()
    local arrow = {}
    
    arrow.Line1 = Drawing.new("Line")
    arrow.Line1.Thickness = 2
    arrow.Line1.Color = Color3.fromRGB(255, 255, 0)
    arrow.Line1.Visible = false
    
    arrow.Line2 = Drawing.new("Line")
    arrow.Line2.Thickness = 2
    arrow.Line2.Color = Color3.fromRGB(255, 255, 0)
    arrow.Line2.Visible = false
    
    arrow.Line3 = Drawing.new("Line")
    arrow.Line3.Thickness = 2
    arrow.Line3.Color = Color3.fromRGB(255, 255, 0)
    arrow.Line3.Visible = false
    
    arrow.Text = Drawing.new("Text")
    arrow.Text.Size = 13
    arrow.Text.Center = true
    arrow.Text.Outline = true
    arrow.Text.Color = Color3.fromRGB(255, 255, 255)
    arrow.Text.Visible = false
    
    return arrow
end

local function UpdateArrow(arrow, targetWorldPos, playerName, distance)
    local screenSize = Camera.ViewportSize
    local center = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    local cameraPos = Camera.CFrame.Position
    local direction3D = (targetWorldPos - cameraPos).Unit
    
    local cameraLook = Camera.CFrame.LookVector
    local cameraRight = Camera.CFrame.RightVector
    local cameraUp = Camera.CFrame.UpVector
    
    local dotForward = direction3D:Dot(cameraLook)
    local dotRight = direction3D:Dot(cameraRight)
    local dotUp = direction3D:Dot(cameraUp)
    
    local screenDirection = Vector2.new(dotRight, -dotUp)
    
    if screenDirection.Magnitude > 0.01 then
        screenDirection = screenDirection.Unit
    else
        screenDirection = Vector2.new(0, -1)
    end
    
    local circleRadius = 300
    local arrowPos = center + (screenDirection * circleRadius)
    local angle = math.atan2(screenDirection.Y, screenDirection.X)
    local arrowSize = 15
    
    local tipX = math.cos(angle) * arrowSize
    local tipY = math.sin(angle) * arrowSize
    
    local perpX = math.cos(angle + math.pi/2) * (arrowSize * 0.6)
    local perpY = math.sin(angle + math.pi/2) * (arrowSize * 0.6)
    
    local point1 = arrowPos + Vector2.new(tipX, tipY)
    local point2 = arrowPos + Vector2.new(-perpX, -perpY)
    local point3 = arrowPos + Vector2.new(perpX, perpY)
    
    arrow.Line1.From = point1
    arrow.Line1.To = point2
    arrow.Line1.Visible = true
    
    arrow.Line2.From = point2
    arrow.Line2.To = point3
    arrow.Line2.Visible = true
    
    arrow.Line3.From = point3
    arrow.Line3.To = point1
    arrow.Line3.Visible = true
    
    local textOffset = screenDirection * 25
    arrow.Text.Position = arrowPos + textOffset
    arrow.Text.Text = string.format("%s [%.0f]", playerName, distance)
    arrow.Text.Visible = true
end

local function HideArrow(arrow)
    if arrow then
        arrow.Line1.Visible = false
        arrow.Line2.Visible = false
        arrow.Line3.Visible = false
        arrow.Text.Visible = false
    end
end

local function HideAllDrawings(d)
    if not d then return end
    if d.Name then d.Name.Visible = false end
    if d.Dist then d.Dist.Visible = false end
    HideArrow(d.Arrow)
end

local function RemoveAllDrawings(d)
    if not d then return end
    if d.Name then pcall(function() d.Name:Remove() end) end
    if d.Dist then pcall(function() d.Dist:Remove() end) end
    if d.Arrow then
        pcall(function() d.Arrow.Line1:Remove() end)
        pcall(function() d.Arrow.Line2:Remove() end)
        pcall(function() d.Arrow.Line3:Remove() end)
        pcall(function() d.Arrow.Text:Remove() end)
    end
end

local function UpdateESP(player)
    if player == LocalPlayer then return end
    
    if not player or not player.Parent then
        CleanupESP(player)
        return
    end
    
    if not ESPData[player] then
        ESPData[player] = {
            Arrow = CreateArrowDrawing()
        }
    end
    local d = ESPData[player]
    
    if not Settings.ESP then
        HideAllDrawings(d)
        return
    end
    
    local char = player.Character
    if not char then
        HideAllDrawings(d)
        return
    end
    
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not root or not humanoid or not head then
        HideAllDrawings(d)
        return
    end
    
    if humanoid.Health <= 0 then
        HideAllDrawings(d)
        return
    end
    
    local myRoot = GetRoot()
    if not myRoot then return end
    
    local distance
    local success = pcall(function()
        distance = (myRoot.Position - root.Position).Magnitude
    end)
    
    if not success or not distance then
        HideAllDrawings(d)
        return
    end
    
    local tooFar = distance > Settings.ESPMaxDistance
    
    local headPos, onScreen
    success = pcall(function()
        headPos, onScreen = WorldToScreen(head.Position)
    end)
    
    if not success or not headPos then
        HideAllDrawings(d)
        return
    end
    
    local shouldShow = not tooFar and onScreen
    local shouldShowArrow = Settings.ESPArrows and not tooFar and not onScreen
    
    -- NAME
    if Settings.ESPNames then
        if not d.Name then
            d.Name = Drawing.new("Text")
            d.Name.Size = 13
            d.Name.Center = true
            d.Name.Outline = true
            d.Name.Color = Color3.fromRGB(255, 255, 255)
        end
        
        if shouldShow then
            d.Name.Position = Vector2.new(headPos.X, headPos.Y - 35)
            d.Name.Text = player.Name
            d.Name.Visible = true
        else
            d.Name.Visible = false
        end
    elseif d.Name then
        d.Name.Visible = false
    end
    
    -- DISTANCE
    if Settings.ESPDistance then
        if not d.Dist then
            d.Dist = Drawing.new("Text")
            d.Dist.Size = 12
            d.Dist.Center = true
            d.Dist.Outline = true
            d.Dist.Color = Color3.fromRGB(200, 200, 200)
        end
        
        if shouldShow then
            d.Dist.Position = Vector2.new(headPos.X, headPos.Y + 15)
            d.Dist.Text = string.format("[%.0f]", distance)
            d.Dist.Visible = true
        else
            d.Dist.Visible = false
        end
    elseif d.Dist then
        d.Dist.Visible = false
    end
    
    -- OFF-SCREEN ARROWS
    if Settings.ESPArrows then
        if shouldShowArrow then
            pcall(function()
                UpdateArrow(d.Arrow, root.Position, player.Name, distance)
            end)
        else
            HideArrow(d.Arrow)
        end
    else
        HideArrow(d.Arrow)
    end
end

local function CleanupESP(player)
    if ESPData[player] then
        RemoveAllDrawings(ESPData[player])
        ESPData[player] = nil
    end
end

local function ESPRenderLoop()
    for player, data in pairs(ESPData) do
        if not player or not player.Parent then
            RemoveAllDrawings(data)
            ESPData[player] = nil
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateESP(player)
        end
    end
    
    local currentPlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        currentPlayers[player] = true
    end
    
    for player, data in pairs(ESPData) do
        if not currentPlayers[player] then
            RemoveAllDrawings(data)
            ESPData[player] = nil
        end
    end
end

--// UI CREATION
local Window = Rayfield:CreateWindow({
    Name = "Admin Panel V1.4 | by Plexynex Dev",
    LoadingTitle = "Admin Panel V2",
    LoadingSubtitle = "by PlexyDev",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

--// INFO TAB
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("script Info")

InfoTab:CreateParagraph({
    Title = "Admin Panel",
    Content = "Developed by Plexynex\nVersion: 1.4"
})

InfoTab:CreateSection("⚠️ Device Support")

InfoTab:CreateParagraph({
    Title = "Compatibility",
    Content = "Desktop: Full support\nMobile: Limited support (beberapa kontrol mungkin tidak berfungsi normal)\nScript ini dioptimalkan untuk penggunaan Desktop."
})

InfoTab:CreateParagraph({
    Title = "⚠️ DISCLAIMER",
    Content = "Script ini dirancang untuk ADMIN PANEL atau SERVER PRIBADI.\nTIDAK disarankan untuk exploitasi di server publik.\nDeveloper (Plexynex) tidak bertanggung jawab atas penyalahgunaan.\n\nGunakan dengan BIJAK dan sesuai aturan server.\nJika digunakan di server luar, harap BERHATI-HATI karena dapat mengakibatkan BAN atau konsekuensi lainnya."
})

InfoTab:CreateSection("Social Media")

local function copyLink(link, name)
    if setclipboard then
        setclipboard(link)
        Rayfield:Notify({
            Title = "Copied",
            Content = name .. " link copied to clipboard",
            Duration = 2
        })
    else
        Rayfield:Notify({
            Title = "Error",
            Content = "Clipboard tidak didukung executor",
            Duration = 3
        })
    end
end

InfoTab:CreateButton({
    Name = "💻 GitHub",
    Callback = function()
        copyLink("https://github.com/plexynex", "GitHub")
    end
})

InfoTab:CreateButton({
    Name = "💬 Discord",
    Callback = function()
        copyLink("https://discord.gg/AuzQzquvru", "Discord")
    end
})

--// MAIN TAB
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateSection("Movement")

MainTab:CreateToggle({
    Name = "Fly | Shortcut [F]",
    CurrentValue = false,
    Callback = function(v) Settings.Fly = v; if not v then DisableFly() end end,
})

MainTab:CreateParagraph({
    Title = "Fly Function",
    Content = "Fasilitas navigasi udara untuk Administrator melakukan inspeksi terrain, inspeksi pemain yang melakukan exploitasi, verifikasi tata letak map, dan pengawasan area lintas udara secara komprehensif. Dirancang untuk keperluan administratif dan quality assurance server."
})

MainTab:CreateSection("Other")

MainTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Callback = function(v) Settings.NoClip = v; if v then EnableNoClip() else DisableNoClip() end end,
})

MainTab:CreateParagraph({
    Title = "No Clip Function",
    Content = "No Clip adalah fitur yang menghilangkan deteksi collision pada karakter Administrator, memungkinkan pergerakan menembus seluruh objek solid seperti dinding, terrain, dan prop. Fitur ini esensial untuk melakukan debug map, inspeksi area tertutup, verifikasi batas ruang, serta identifikasi celah atau bug geometri lingkungan."
})

--// VISUALS TAB
local VisualsTab = Window:CreateTab("👁️ Visuals", 4483362458)

VisualsTab:CreateSection("ESP Settings")

VisualsTab:CreateToggle({
    Name = "ESP ON",
    CurrentValue = false,
    Callback = function(v)
        Settings.ESP = v
        if not v then
            for player, data in pairs(ESPData) do
                HideAllDrawings(data)
            end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Callback = function(v) Settings.ESPNames = v end,
})

VisualsTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Callback = function(v) Settings.ESPDistance = v end,
})

VisualsTab:CreateToggle({
    Name = "Off-Screen Arrows",
    CurrentValue = true,
    Callback = function(v) Settings.ESPArrows = v end,
})

VisualsTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(v) Settings.ESPMaxDistance = v end,
})

--// KEYBIND SYSTEM
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        ToggleFly()
    end
end)

--// PLAYER EVENTS
Players.PlayerRemoving:Connect(function(player)
    CleanupESP(player)
end)

Players.PlayerAdded:Connect(function(player)
    CleanupESP(player)
end)

--// CHARACTER RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function()
    if Settings.NoClip then EnableNoClip() end
end)

--// MAIN LOOPS
RunService.RenderStepped:Connect(function()
    HandleFly()
    ESPRenderLoop()
end)

--// INITIALIZATION
if not GetCharacter() then
    LocalPlayer.CharacterAdded:Wait()
end

Rayfield:Notify({
    Title = "Admin Panel V1.4",
    Content = "Script Loaded Successfully",
    Duration = 5,
    Image = 4483362458,
})
