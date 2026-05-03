--[[ 
PLEXYNEX HUB
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
    SpeedHack = false,
    SpeedValue = 100,
    JumpHold = false,
    JumpHoldPower = 50,
    Freecam = false,
    Speed = 2,
    Sensitivity = 0.2,
    NoClip = false,
    ClickTP = false,
    Godmode = false,
    Aimbot = false,
    AimbotFOV = 100,
    AimbotSmoothness = 0.3,
    AimbotTeamCheck = false,
    AimbotShowFOV = false,
    AimbotVisibilityCheck = false,
    ESP = false,
    ESPBoxes = false,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = false,
    ESPLines = false,
    ESPArrows = true,
    ESPTeamCheck = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPMaxDistance = 1000,
    -- Lighting
    CustomBrightness = false,
    Brightness = 3,
    FullbrightEnabled = false,
    CustomTime = false,
    TimeHour = 12,
    CustomAmbient = false,
    AmbientColor = Color3.fromRGB(255, 255, 255),
    -- Player Select Teleport
    SelectedPlayer = nil,
    AutoRefreshPlayerList = true,
}

--// SAVE ORIGINAL LIGHTING VALUES
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
}

--// LIGHTING SYSTEM
local function EnableFullbright()
    Lighting.Brightness = 5
    Lighting.ClockTime = 14 -- siang terus
    Lighting.FogEnd = 1e10
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

local function DisableFullbright()
    for k,v in pairs(OriginalLighting) do
        Lighting[k] = v
    end
end

local function SetTime(hour)
    Lighting.ClockTime = hour
end

local function SetAmbient(color)
    Lighting.Ambient = color
    Lighting.OutdoorAmbient = color
end

local function HandleLighting()
    -- Custom Time
    if Settings.CustomTime then
        SetTime(Settings.TimeHour)
    end
    
    -- Custom Ambient
    if Settings.CustomAmbient then
        SetAmbient(Settings.AmbientColor)
    end
end

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

--// VISIBILITY CHECK FUNCTION
local function IsVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    
    if distance > 1000 then return false end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result = workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    
    return false
end

--// FOV CIRCLE
local FOVCircle

local function CreateFOVCircle()
    if FOVCircle then return end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Transparency = 0.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Settings.AimbotFOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Visible = false
end

local function UpdateFOVCircle()
    if not FOVCircle then CreateFOVCircle() end
    
    if Settings.AimbotShowFOV and Settings.Aimbot then
        FOVCircle.Radius = Settings.AimbotFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
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

--// SPEED SYSTEM
local function ToggleSpeedHack()
    Settings.SpeedHack = not Settings.SpeedHack
    Rayfield:Notify({
        Title = "Speed Hack",
        Content = Settings.SpeedHack and "Enabled (" .. Settings.SpeedValue .. ")" or "Disabled",
        Duration = 1,
        Image = 4483362458,
    })
end

local function HandleSpeed()
    local humanoid = GetHumanoid()
    if not humanoid then return end
    humanoid.WalkSpeed = Settings.SpeedHack and Settings.SpeedValue or 16
end

--// JUMP HOLD SYSTEM
local JumpHoldConnection
local isJumping = false

local function EnableJumpHold()
    if JumpHoldConnection then return end
    
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.JumpPower = Settings.JumpHoldPower
        humanoid.AutoJumpEnabled = true
    end
    
    JumpHoldConnection = RunService.Heartbeat:Connect(function()
        if not Settings.JumpHold then
            DisableJumpHold()
            return
        end
        
        local humanoid = GetHumanoid()
        if not humanoid then return end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            if not isJumping then
                isJumping = true
                local root = GetRoot()
                if root then
                    root.Velocity = Vector3.new(root.Velocity.X, Settings.JumpHoldPower, root.Velocity.Z)
                end
                humanoid.Jump = true
                humanoid.JumpPower = Settings.JumpHoldPower
            else
                local root = GetRoot()
                if root and root.Velocity.Y < Settings.JumpHoldPower then
                    root.Velocity = Vector3.new(root.Velocity.X, Settings.JumpHoldPower, root.Velocity.Z)
                end
            end
        else
            if isJumping then
                isJumping = false
                local humanoid = GetHumanoid()
                if humanoid then humanoid.Jump = false end
            end
        end
    end)
end

local function DisableJumpHold()
    if JumpHoldConnection then
        JumpHoldConnection:Disconnect()
        JumpHoldConnection = nil
    end
    isJumping = false
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.JumpPower = 50
        humanoid.Jump = false
        humanoid.AutoJumpEnabled = false
    end
end

-- FREECAM SISTEM START
--// STATE
local moveDir = Vector3.zero
local yaw, pitch = 0, 0
local holdingRightClick = false

--// CONNECTIONS
local freecamConn
local inputBeganConn
local inputEndedConn
local inputChangedConn

--// CHARACTER CONTROL
local function FreezeCharacter()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
    end
end

local function RestoreCharacter()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.AutoRotate = true
    end
end

--// INPUT (ONLY ACTIVE IN FREECAM)
local function EnableInput()
    inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.KeyCode == Enum.KeyCode.W then moveDir += Vector3.new(0,0,-1) end
        if input.KeyCode == Enum.KeyCode.S then moveDir += Vector3.new(0,0,1) end
        if input.KeyCode == Enum.KeyCode.A then moveDir += Vector3.new(-1,0,0) end
        if input.KeyCode == Enum.KeyCode.D then moveDir += Vector3.new(1,0,0) end
        if input.KeyCode == Enum.KeyCode.Space then moveDir += Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then moveDir += Vector3.new(0,-1,0) end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holdingRightClick = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)

    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then moveDir -= Vector3.new(0,0,-1) end
        if input.KeyCode == Enum.KeyCode.S then moveDir -= Vector3.new(0,0,1) end
        if input.KeyCode == Enum.KeyCode.A then moveDir -= Vector3.new(-1,0,0) end
        if input.KeyCode == Enum.KeyCode.D then moveDir -= Vector3.new(1,0,0) end
        if input.KeyCode == Enum.KeyCode.Space then moveDir -= Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then moveDir -= Vector3.new(0,-1,0) end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            holdingRightClick = false
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and holdingRightClick then
            yaw -= input.Delta.X * Settings.Sensitivity
            pitch -= input.Delta.Y * Settings.Sensitivity
            pitch = math.clamp(pitch, -80, 80)
        end
    end)
end

local function DisableInput()
    if inputBeganConn then inputBeganConn:Disconnect() end
    if inputEndedConn then inputEndedConn:Disconnect() end
    if inputChangedConn then inputChangedConn:Disconnect() end

    moveDir = Vector3.zero
    holdingRightClick = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

--// FREECAM CORE
local function EnableFreecam()
    if freecamConn then return end

    FreezeCharacter()
    EnableInput()

    -- 🔴 SYNC ROTASI DARI CAMERA (FIX UTAMA)
    local camCF = Camera.CFrame
    local camPos = camCF.Position
    local look = camCF.LookVector

    yaw = math.deg(math.atan2(-look.X, -look.Z))
    pitch = math.deg(math.asin(look.Y))

    Camera.CameraType = Enum.CameraType.Scriptable

    freecamConn = RunService.RenderStepped:Connect(function()
        local rot = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
        local move = rot:VectorToWorldSpace(moveDir) * Settings.Speed

        camPos += move
        Camera.CFrame = CFrame.new(camPos) * rot
    end)
end

local function DisableFreecam()
    if freecamConn then
        freecamConn:Disconnect()
        freecamConn = nil
    end

    DisableInput()
    RestoreCharacter()

    Camera.CameraType = Enum.CameraType.Custom
end
-- FREECAM SISTEM END

--// GODMODE SYSTEM
local GodmodeConnection

local function EnableGodmode()
    if GodmodeConnection then return end
    GodmodeConnection = RunService.Heartbeat:Connect(function()
        if Settings.Godmode then
            local h = GetHumanoid()
            if h and h.Health > 0 then h.Health = h.MaxHealth end
        end
    end)
end

local function DisableGodmode()
    if GodmodeConnection then GodmodeConnection:Disconnect(); GodmodeConnection = nil end
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

--// CLICK TP SYSTEM
local ClickTPConnection

local function EnableClickTP()
    if ClickTPConnection then return end
    
    ClickTPConnection = Mouse.Button1Down:Connect(function()
        if not Settings.ClickTP then return end
        
        local root = GetRoot()
        if not root then return end
        
        local mousePos = Mouse.Hit.Position
        root.CFrame = CFrame.new(mousePos + Vector3.new(0, 3, 0))
    end)
end

local function DisableClickTP()
    if ClickTPConnection then
        ClickTPConnection:Disconnect()
        ClickTPConnection = nil
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
    if d.Box then d.Box.Visible = false end
    if d.Name then d.Name.Visible = false end
    if d.Dist then d.Dist.Visible = false end
    if d.HealthText then d.HealthText.Visible = false end
    if d.HealthBar then d.HealthBar.Visible = false end
    if d.HealthBarBG then d.HealthBarBG.Visible = false end
    if d.Line then d.Line.Visible = false end
    HideArrow(d.Arrow)
end

local function RemoveAllDrawings(d)
    if not d then return end
    if d.Box then pcall(function() d.Box:Remove() end) end
    if d.Name then pcall(function() d.Name:Remove() end) end
    if d.Dist then pcall(function() d.Dist:Remove() end) end
    if d.HealthText then pcall(function() d.HealthText:Remove() end) end
    if d.HealthBar then pcall(function() d.HealthBar:Remove() end) end
    if d.HealthBarBG then pcall(function() d.HealthBarBG:Remove() end) end
    if d.Line then pcall(function() d.Line:Remove() end) end
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
    
    local skip = Settings.ESPTeamCheck and player.Team == LocalPlayer.Team
    
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
    
    local shouldShow = not skip and not tooFar and onScreen
    local shouldShowArrow = Settings.ESPArrows and not skip and not tooFar and not onScreen
    
    -- BOX
    if Settings.ESPBoxes then
        if not d.Box then
            d.Box = Drawing.new("Square")
            d.Box.Thickness = 2
            d.Box.Filled = false
        end
        
        if shouldShow then
            pcall(function()
                local top = head.Position + Vector3.new(0, 0.5, 0)
                local bottom = root.Position - Vector3.new(0, 3, 0)
                local topScreen, topOnScreen = WorldToScreen(top)
                local bottomScreen, bottomOnScreen = WorldToScreen(bottom)
                
                if topOnScreen and bottomOnScreen then
                    local height = math.abs(topScreen.Y - bottomScreen.Y)
                    local width = height * 0.65
                    
                    d.Box.Position = Vector2.new(headPos.X - width/2, topScreen.Y)
                    d.Box.Size = Vector2.new(width, height)
                    d.Box.Color = Settings.ESPColor
                    d.Box.Visible = true
                    
                    d.BoxHeight = height
                    d.BoxWidth = width
                    d.BoxTop = topScreen.Y
                    d.BoxLeft = headPos.X - width/2
                else
                    d.Box.Visible = false
                end
            end)
        else
            d.Box.Visible = false
        end
    elseif d.Box then
        d.Box.Visible = false
    end
    
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
    
    -- HEALTH
    if Settings.ESPHealth then
        if not d.HealthBarBG then
            d.HealthBarBG = Drawing.new("Square")
            d.HealthBarBG.Filled = true
            d.HealthBarBG.Color = Color3.fromRGB(0, 0, 0)
            d.HealthBarBG.Transparency = 0.7
        end
        
        if not d.HealthBar then
            d.HealthBar = Drawing.new("Square")
            d.HealthBar.Filled = true
        end
        
        if not d.HealthText then
            d.HealthText = Drawing.new("Text")
            d.HealthText.Size = 11
            d.HealthText.Center = true
            d.HealthText.Outline = true
            d.HealthText.Color = Color3.fromRGB(255, 255, 255)
        end
        
        if shouldShow then
            local barWidth = 4
            local barHeight
            local barX
            local barY
            
            if d.BoxWidth then
                barHeight = d.BoxHeight or 50
                barX = d.BoxLeft - barWidth - 3
                barY = d.BoxTop or (headPos.Y)
            else
                barHeight = 50
                barX = headPos.X - 30
                barY = headPos.Y - 15
            end
            
            d.HealthBarBG.Position = Vector2.new(barX, barY)
            d.HealthBarBG.Size = Vector2.new(barWidth, barHeight)
            d.HealthBarBG.Visible = true
            
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local filledHeight = barHeight * healthPercent
            
            local healthColor
            if healthPercent > 0.6 then
                healthColor = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.3 then
                healthColor = Color3.fromRGB(255, 255, 0)
            else
                healthColor = Color3.fromRGB(255, 0, 0)
            end
            
            d.HealthBar.Color = healthColor
            d.HealthBar.Position = Vector2.new(barX, barY + (barHeight - filledHeight))
            d.HealthBar.Size = Vector2.new(barWidth, filledHeight)
            d.HealthBar.Visible = true
            
            d.HealthText.Position = Vector2.new(barX + barWidth/2, barY - 8)
            d.HealthText.Text = string.format("%.0f", humanoid.Health)
            d.HealthText.Visible = true
        else
            d.HealthBarBG.Visible = false
            d.HealthBar.Visible = false
            if d.HealthText then d.HealthText.Visible = false end
        end
    else
        if d.HealthBarBG then d.HealthBarBG.Visible = false end
        if d.HealthBar then d.HealthBar.Visible = false end
        if d.HealthText then d.HealthText.Visible = false end
    end
    
    -- TRACER LINES
    if Settings.ESPLines then
        if not d.Line then
            d.Line = Drawing.new("Line")
            d.Line.Thickness = 1
        end
        
        if shouldShow then
            pcall(function()
                local myPos, myOnScreen = WorldToScreen(myRoot.Position)
                if myOnScreen then
                    d.Line.From = Vector2.new(myPos.X, myPos.Y)
                    d.Line.To = Vector2.new(headPos.X, headPos.Y)
                    d.Line.Color = Settings.ESPColor
                    d.Line.Visible = true
                else
                    d.Line.Visible = false
                end
            end)
        else
            d.Line.Visible = false
        end
    elseif d.Line then
        d.Line.Visible = false
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

--// AIMBOT
local function HandleAimbot()
    if not Settings.Aimbot then return end
    
    local closest = nil
    local minDist = Settings.AimbotFOV
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local h = char:FindFirstChild("Humanoid")
        if not head or not h or h.Health <= 0 then continue end
        if Settings.AimbotTeamCheck and player.Team == LocalPlayer.Team then continue end
        
        if Settings.AimbotVisibilityCheck then
            if not IsVisible(head) then continue end
        end
        
        local pos, onScreen = WorldToScreen(head.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if dist < minDist then
            minDist = dist
            closest = head
        end
    end
    
    if closest then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Position), Settings.AimbotSmoothness)
    end
end

--// TELEPORT TO SELECTED PLAYER
local function TeleportToPlayer(player)
    if typeof(player) ~= "Instance" then return false end
    if not player:IsDescendantOf(Players) then return false end

    local targetChar = GetCharacterSafe(player)
    local myChar = GetCharacterSafe(LocalPlayer)

    local targetRoot = GetRootSafe(targetChar)
    local myRoot = GetRootSafe(myChar)

    if not targetRoot or not myRoot then return false end

    local success = false
    
    pcall(function()
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
        success = true
    end)

    return success
end

--// TELEPORT FUNCTIONS (ORIGINAL)
local function TeleportToNearest()
    local myRoot = GetRoot()
    if not myRoot then return end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = player
                end
            end
        end
    end
    
    if nearest then
        TeleportToPlayer(nearest)
        Rayfield:Notify({Title = "Success", Content = "Teleported to " .. nearest.Name, Duration = 2, Image = 4483362458})
    else
        Rayfield:Notify({Title = "Error", Content = "No players found!", Duration = 2, Image = 4483362458})
    end
end

local function TeleportToFarthest()
    local myRoot = GetRoot()
    if not myRoot then return end
    
    local farthest = nil
    local maxDist = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist > maxDist then
                    maxDist = dist
                    farthest = player
                end
            end
        end
    end
    
    if farthest then
        TeleportToPlayer(farthest)
        Rayfield:Notify({Title = "Success", Content = "Teleported to " .. farthest.Name, Duration = 2, Image = 4483362458})
    else
        Rayfield:Notify({Title = "Error", Content = "No players found!", Duration = 2, Image = 4483362458})
    end
end

local function TeleportToRandom()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            table.insert(players, player)
        end
    end
    
    if #players > 0 then
        local random = players[math.random(1, #players)]
        TeleportToPlayer(random)
        Rayfield:Notify({Title = "Success", Content = "Teleported to " .. random.Name, Duration = 2, Image = 4483362458})
    else
        Rayfield:Notify({Title = "Error", Content = "No players found!", Duration = 2, Image = 4483362458})
    end
end

local function TeleportToHighest()
    local myRoot = GetRoot()
    if not myRoot then return end
    
    local highest = nil
    local highestY = -math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Position.Y > highestY and obj.Size.Magnitude > 10 then
            highestY = obj.Position.Y
            highest = obj
        end
    end
    
    if highest then
        local targetPos = highest.Position + Vector3.new(0, highest.Size.Y/2 + 5, 0)
        pcall(function() myRoot.CFrame = CFrame.new(targetPos) end)
        Rayfield:Notify({Title = "Success", Content = "Highest point: " .. math.floor(highestY) .. " studs", Duration = 2, Image = 4483362458})
    else
        local targetPos = Vector3.new(myRoot.Position.X, 10000, myRoot.Position.Z)
        pcall(function() myRoot.CFrame = CFrame.new(targetPos) end)
        Rayfield:Notify({Title = "Teleported", Content = "Sent to max height!", Duration = 2, Image = 4483362458})
    end
end

--// UI CREATION
local Window = Rayfield:CreateWindow({
    Name = "Plexynex Script",
    LoadingTitle = "Plexynex Script",
    LoadingSubtitle = "by PlexyDev",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

--// MAIN TAB
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateSection("Movement | [Warn! Anti Cheat Detected]")

MainTab:CreateToggle({
    Name = "Fly [F]",
    CurrentValue = false,
    Callback = function(v) Settings.Fly = v; if not v then DisableFly() end end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(v) Settings.FlySpeed = v end,
})

MainTab:CreateToggle({
    Name = "Speed Hack [G]",
    CurrentValue = false,
    Callback = function(v) Settings.SpeedHack = v end,
})

MainTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v) Settings.SpeedValue = v end,
})

MainTab:CreateSection("Keybinds")

MainTab:CreateParagraph({
    Title = "Shortcuts",
    Content = "[F] = Toggle Fly\n[G] = Toggle Speed Hack"
})

MainTab:CreateSection("Jump Hold")

MainTab:CreateToggle({
    Name = "Jump Hold",
    CurrentValue = false,
    Callback = function(v)
        Settings.JumpHold = v
        if v then EnableJumpHold() else DisableJumpHold() end
    end,
})

MainTab:CreateSlider({
    Name = "Jump Hold Power [Warn! Anti Cheat Detected]",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v) Settings.JumpHoldPower = v end,
})

MainTab:CreateSection("Freecam")

MainTab:CreateToggle({
    Name = "Freecam",
    CurrentValue = false,
    Callback = function(v)
        Settings.Freecam = v
        if v then EnableFreecam() else DisableFreecam() end
    end
})

MainTab:CreateSlider({
    Name = "Speed",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v)
        Settings.Speed = v
    end
})

MainTab:CreateSlider({
    Name = "Sensitivity",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Callback = function(v)
        Settings.Sensitivity = v
    end
})

MainTab:CreateSection("Other")

MainTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Callback = function(v) Settings.NoClip = v; if v then EnableNoClip() else DisableNoClip() end end,
})

MainTab:CreateSection("Click Teleport")

MainTab:CreateToggle({
    Name = "Click TP",
    CurrentValue = false,
    Callback = function(v)
        Settings.ClickTP = v
        if v then EnableClickTP() else DisableClickTP() end
    end,
})

--// COMBAT TAB
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

CombatTab:CreateSection("Self")

CombatTab:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Callback = function(v) Settings.Godmode = v; if v then EnableGodmode() else DisableGodmode() end end,
})

CombatTab:CreateParagraph({
    Title = "Godmode Info",
    Content = "Max HP + auto-heal (client-side)"
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) Settings.Aimbot = v end,
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Callback = function(v) Settings.AimbotShowFOV = v end,
})

CombatTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = false,
    Callback = function(v) Settings.AimbotVisibilityCheck = v end,
})

CombatTab:CreateSlider({
    Name = "FOV",
    Range = {20, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v) Settings.AimbotFOV = v end,
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.1, 1},
    Increment = 0.1,
    CurrentValue = 0.3,
    Callback = function(v) Settings.AimbotSmoothness = v end,
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(v) Settings.AimbotTeamCheck = v end,
})

--// VISUALS TAB
local VisualsTab = Window:CreateTab("👁️ Visuals", 4483362458)

VisualsTab:CreateSection("ESP Settings [Safe]")

VisualsTab:CreateToggle({
    Name = "Enable ESP",
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
    Name = "Boxes",
    CurrentValue = false,
    Callback = function(v) Settings.ESPBoxes = v end,
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
    Name = "Health",
    CurrentValue = false,
    Callback = function(v) Settings.ESPHealth = v end,
})

VisualsTab:CreateToggle({
    Name = "Tracer Lines",
    CurrentValue = false,
    Callback = function(v) Settings.ESPLines = v end,
})

VisualsTab:CreateToggle({
    Name = "Off-Screen Arrows",
    CurrentValue = true,
    Callback = function(v) Settings.ESPArrows = v end,
})

VisualsTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(v) Settings.ESPTeamCheck = v end,
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(v) Settings.ESPColor = v end,
})

VisualsTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(v) Settings.ESPMaxDistance = v end,
})

--// TELEPORT TAB (DENGAN PLAYER SELECT + AUTO/MANUAL REFRESH)
local TeleportTab = Window:CreateTab("🌐 Teleport", 4483362458)

--// PLAYER SELECT TELEPORT SYSTEM
local selectedPlayer = nil
local dropdownRef

TeleportTab:CreateSection("🎯 Select Player to Teleport")

-- Dropdown untuk memilih player
dropdownRef = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = {},
    CurrentOption = nil,
    Callback = function(option)
        local ok, err = pcall(function()
            if typeof(option) == "table" then
                option = option[1]
            end

            local foundPlayer = nil
            
            -- Mencoba mencari player dari format "DisplayName (@Username)"
            -- Ekstrak username dari format yang dipilih
            local username = option:match("%(@(.+)%)$")
            
            if username then
                -- Format: "DisplayName (@Username)"
                foundPlayer = Players:FindFirstChild(username)
            else
                -- Format: Hanya DisplayName (sama dengan username)
                foundPlayer = Players:FindFirstChild(option)
            end
            
            if foundPlayer then
                selectedPlayer = foundPlayer
                Settings.SelectedPlayer = foundPlayer
            else
                warn("Player not found:", option)
            end
        end)

        if not ok then
            warn("Dropdown error:", err)
        end
    end,
})

-- Update dropdown player list
local function UpdatePlayerList()
    if not dropdownRef then return end

    local list = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local displayName = p.DisplayName
            local username = p.Name
            local formattedName
            
            if displayName ~= username then
                formattedName = displayName .. " (@" .. username .. ")"
            else
                formattedName = displayName
            end
            
            table.insert(list, formattedName)
        end
    end

    print("Detected players:", #list)

    pcall(function()
        dropdownRef:Refresh(list)
    end)
end

-- Tombol teleport ke player terpilih
TeleportTab:CreateButton({
    Name = "📌 Teleport to Selected Player",
    Callback = function()
        local ok, err = pcall(function()
            if not selectedPlayer then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No player selected! Use dropdown first.",
                    Duration = 3
                })
                return
            end

            if not selectedPlayer.Parent then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Selected player has left the game!",
                    Duration = 3
                })
                selectedPlayer = nil
                Settings.SelectedPlayer = nil
                if Settings.AutoRefreshPlayerList then
                    UpdatePlayerList()
                end
                return
            end

            Rayfield:Notify({
                Title = "Teleporting...",
                Content = "Attempting to teleport to " .. selectedPlayer.Name,
                Duration = 2
            })

            local success = TeleportToPlayer(selectedPlayer)

            if success then
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Teleported to " .. selectedPlayer.Name,
                    Duration = 3
                })
            else
                Rayfield:Notify({
                    Title = "Fail",
                    Content = "Teleport failed. Try again or move closer.",
                    Duration = 3
                })
            end
        end)

        if not ok then
            warn("Teleport error:", err)
        end
    end,
})

TeleportTab:CreateSection("🔄 Player List Settings")

-- Toggle Auto Refresh
TeleportTab:CreateToggle({
    Name = "Auto Refresh Player List",
    CurrentValue = true,
    Callback = function(v) 
        Settings.AutoRefreshPlayerList = v
        Rayfield:Notify({
            Title = "Player List Refresh",
            Content = v and "Auto Refresh: ON" or "Manual Refresh Only",
            Duration = 2
        })
    end,
})

-- Tombol Manual Refresh
TeleportTab:CreateButton({
    Name = "🔄 Manual Refresh (Update List)",
    Callback = function()
        UpdatePlayerList()
        Rayfield:Notify({
            Title = "Player List",
            Content = "Player list refreshed!",
            Duration = 1
        })
    end,
})

TeleportTab:CreateParagraph({
    Title = "Refresh Info",
    Content = "• Auto ON: Updates automatically\n• Auto OFF: Use manual refresh button\n• Turn OFF to prevent scroll reset"
})

TeleportTab:CreateSection("Quick Teleport")

TeleportTab:CreateButton({
    Name = "🎯 Teleport to Nearest Player",
    Callback = function() TeleportToNearest() end,
})

TeleportTab:CreateButton({
    Name = "📏 Teleport to Farthest Player",
    Callback = function() TeleportToFarthest() end,
})

TeleportTab:CreateButton({
    Name = "🎲 Teleport to Random Player",
    Callback = function() TeleportToRandom() end,
})

TeleportTab:CreateSection("World Teleport")

TeleportTab:CreateButton({
    Name = "🏔️ Teleport to Highest Point",
    Callback = function() TeleportToHighest() end,
})

TeleportTab:CreateSection("Info")

TeleportTab:CreateParagraph({
    Title = "How to Use Player Select",
    Content = "1. Select player from dropdown\n2. Click 'Teleport to Selected Player'\n3. Turn OFF Auto Refresh if scroll bothers you"
})

--// LIGHTING TAB
local LightingTab = Window:CreateTab("💡 Lighting", 4483362458)

LightingTab:CreateSection("Brightness")

LightingTab:CreateToggle({
    Name = "Fullbright (Remove Darkness & Shadow)",
    CurrentValue = false,
    Callback = function(v)
        FullbrightEnabled = v
        if v then
            EnableFullbright()
        else
            DisableFullbright()
        end
    end,
})

LightingTab:CreateSection("Time")

LightingTab:CreateToggle({
    Name = "Custom Time (24h)",
    CurrentValue = false,
    Callback = function(v)
        Settings.CustomTime = v
        if not v then
            SetTime(OriginalLighting.ClockTime)
        end
    end,
})

LightingTab:CreateSlider({
    Name = "Time (Hours)",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Callback = function(v) Settings.TimeHour = v end,
})

LightingTab:CreateParagraph({
    Title = "Time Reference",
    Content = "0 = Midnight | 6 = Sunrise\n12 = Noon | 18 = Sunset | 24 = Midnight"
})

LightingTab:CreateSection("Ambient")

LightingTab:CreateToggle({
    Name = "Custom Ambient",
    CurrentValue = false,
    Callback = function(v)
        Settings.CustomAmbient = v
        if not v then
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        end
    end,
})

LightingTab:CreateColorPicker({
    Name = "Ambient Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(v) Settings.AmbientColor = v end,
})

LightingTab:CreateParagraph({
    Title = "Info",
    Content = "All lighting changes are client-side only.\nSafe to use, no anti-cheat detection."
})

--// KEYBIND SYSTEM
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        ToggleFly()
    end
    
    if input.KeyCode == Enum.KeyCode.G then
        ToggleSpeedHack()
    end
end)

--// PLAYER EVENTS
Players.PlayerRemoving:Connect(function(player)
    CleanupESP(player)
    if selectedPlayer == player then
        selectedPlayer = nil
        Settings.SelectedPlayer = nil
    end
    -- Hanya auto-refresh jika di-enable
    if Settings.AutoRefreshPlayerList then
        UpdatePlayerList()
    end
end)

Players.PlayerAdded:Connect(function(player)
    CleanupESP(player)
    -- Hanya auto-refresh jika di-enable
    if Settings.AutoRefreshPlayerList then
        UpdatePlayerList()
    end
end)

--// CHARACTER RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function()
    if Settings.NoClip then EnableNoClip() end
    if Settings.JumpHold then EnableJumpHold() end
end)

--// MAIN LOOPS
RunService.RenderStepped:Connect(function()
    HandleFly()
    HandleAimbot()
    UpdateFOVCircle()
    ESPRenderLoop()
    HandleLighting()
end)

RunService.Heartbeat:Connect(function()
    HandleSpeed()
end)

--// INITIALIZATION
if not GetCharacter() then
    LocalPlayer.CharacterAdded:Wait()
end

CreateFOVCircle()

--// INITIAL PLAYER LIST UPDATE
task.wait(1)
UpdatePlayerList()

Rayfield:Notify({
    Title = "Plexynex Dev",
    Content = "Ultimate Script V2",
    Duration = 5,
    Image = 4483362458,
})