pcall(function()
    for _, g in pairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name == "LegendFixMenu" or g.Name == "AimTurnSettings" or g.Name == "ShieldSettings" 
        or g.Name == "ItemListWindow" or g.Name == "ItemSettingWindow" or g.Name == "HeldItemEditorWindow" then
            pcall(function() g:Destroy() end)
        end
    end
    if _G.GlobalFunLoops then
        for _, loop in pairs(_G.GlobalFunLoops) do
            pcall(function() loop:Disconnect() end)
        end
    end
    _G.GlobalFunLoops = {}
    if _G.ShieldRangeVisual then pcall(function() _G.ShieldRangeVisual:Destroy() end) end
end)

local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local StarterGear = game:GetService("StarterGear")
local plr = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

local Config = {
    MainBg = Color3.new(0.1, 0.1, 0.12),
    TabBarBg = Color3.new(0.07, 0.07, 0.09),
    TabNormal = Color3.new(0.15, 0.15, 0.18),
    TabActive = Color3.new(0.22, 0.35, 0.55),
    BtnNormal = Color3.new(0.18, 0.18, 0.22),
    BtnRed = Color3.new(0.45, 0.1, 0.1),
    BtnBlue = Color3.new(0.15, 0.35, 0.6),
    BtnPurple = Color3.new(0.4, 0.2, 0.6),
    BtnGreen = Color3.new(0, 0.5, 0.2),
    BtnOrange = Color3.new(0.6, 0.3, 0.1),
    InputBg = Color3.new(0.15, 0.15, 0.18),
    TextWhite = Color3.new(1,1,1),
    AimVisual = {
        CircleColor = Color3.new(0, 1, 0),
        CircleThickness = 2,
    },
}

local GlobalState = {
    FlyScript = false,
    WallHack = false,
    NightVision = false,
    AutoAttack = false,
    AutoAimTurn = false,
    BodyAim = false,
    EnemyShield = false,
}

-- 自瞄配置（视角自瞄）
local AimTurnConfig = {
    LockRange = 35,
    ObstacleCheck = false,
    BodyOnlyMode = false,
    CameraAimMode = false,
    CameraAimSpeed = 5,
    ScreenCircleEnable = false,
    ScreenCircleRadius = 150,
    PriorityVisiblePart = false,
    UniversalAimMode = false,
}

-- 身体自瞄（独立配置）
local BodyAimConfig = {
    LockRange = 35,
    ObstacleCheck = false,
}

local ShieldConfig = {
    PushRange = 25,
    PushForce = 80,
    ShowRange = false,
}

-- 玩家锁定列表
local PlayerLockList = {}

local function RefreshPlayerLockList()
    PlayerLockList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr then
            PlayerLockList[p.UserId] = true
        end
    end
end

local MoveOptimizeConfig = {
    Enabled = false,
}
local AimCircleGui = nil
local AimCircle = nil
local CurrentLockedPart = nil

local ESPConfig = {
    Enabled = false,
    TeamCheck = true,
    InsideWall = true,
    FullBodyRed = false,
    NameSize = 12,
    MaxDistance = 1000,
    BoxColor = Color3.new(1, 0, 0),
    NameColor = Color3.new(1, 1, 1),
    HealthColorFull = Color3.new(0, 1, 0),
    HealthColorLow = Color3.new(1, 0, 0),
    AntennaColor = Color3.new(1, 0.5, 0),
}
local ESPDrawings = {}
local ESPLoop = nil

-- 瞬移相关
local TeleportConfig = {
    SavedPositions = {},
}
local CurrentSpectatePlayer = nil
local OriginalCameraSubject = nil

local CameraState = {
    IsFirstPerson = true
}

-- 画质优化配置
local GraphicsOptimizeConfig = {
    Enabled = false,
    OriginalTextures = {},
    OriginalEffects = {}
}

-- 清除建筑物配置（新）
local ClearBuildConfig = {
    Enabled = false,
    Radius = 30,
    OriginalState = {}
}

-- AI全自动战斗配置
local AICombatConfig = {
    Enabled = false,
    LockMode = "Nearest",
    LockRadius = 30,
    FixedTarget = nil,
    AIControlCamera = false,
    SafeOffset = 0.1,
    Learned = {},
    ChaseSpeed = 26,
    AttackDelay = 0.5,
    ManualAttack = false
}

local AIEngine = {
    Target = nil,
    LastDodge = 0,
    LastAttack = 0,
    WeaponRange = 2,
    InCombat = false
}

local FollowDistance = 2  -- 传送身后距离

-- ========== 辅助函数 ==========
local function AddLoop(loop)
    table.insert(_G.GlobalFunLoops, loop)
end
local function ClearAllLoops()
    for _, loop in ipairs(_G.GlobalFunLoops) do
        pcall(function() loop:Disconnect() end)
    end
    _G.GlobalFunLoops = {}
end

local function MakeFrameDraggable(frame, dragTarget)
    local isDragging = false
    local dragStartPos = Vector2.new(0,0)
    local frameStartPos = UDim2.new(0,0,0,0)
    local dragArea = dragTarget or frame

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = UIS:GetMouseLocation()
            frameStartPos = frame.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local currentPos = UIS:GetMouseLocation()
            local delta = currentPos - dragStartPos
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
end

-- ========== 原有基础功能（未修改） ==========
local function RunOriginalFly()
    pcall(function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-fly-gui-v3-46328"))()
    end)
end

local function StartAutoAttack()
    GlobalState.AutoAttack = true
    local loop = RunService.Heartbeat:Connect(function()
        if not GlobalState.AutoAttack then return end
        pcall(function()
            local char = plr.Character
            if not char then return end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
    end)
    AddLoop(loop)
end
local function StopAutoAttack()
    GlobalState.AutoAttack = false
end

local function StartWallHack()
    GlobalState.WallHack = true
    local loop = RunService.Stepped:Connect(function()
        if not GlobalState.WallHack then return end
        pcall(function()
            local char = plr.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end)
    AddLoop(loop)
end
local function StopWallHack()
    GlobalState.WallHack = false
end

local function StartNightVision()
    GlobalState.NightVision = true
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.Brightness = 10
    Lighting.GlobalShadows = false
end
local function StopNightVision()
    GlobalState.NightVision = false
    Lighting.Ambient = Color3.new(0.5,0.5,0.5)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
end

local function StartEnemyShield()
    GlobalState.EnemyShield = true
    local function UpdateRangeVisual()
        if not ShieldConfig.ShowRange then
            if _G.ShieldRangeVisual then
                pcall(function() _G.ShieldRangeVisual:Destroy() end)
                _G.ShieldRangeVisual = nil
            end
            return
        end
        if not _G.ShieldRangeVisual then
            local visual = Instance.new("Part")
            visual.Name = "ShieldRangeVisual"
            visual.Shape = Enum.PartType.Block
            visual.Anchored = true
            visual.CanCollide = false
            visual.CanTouch = false
            visual.CanQuery = false
            visual.Transparency = 0.7
            visual.BrickColor = BrickColor.new("Bright blue")
            visual.Material = Enum.Material.ForceField
            visual.Parent = Workspace
            _G.ShieldRangeVisual = visual
        end
        local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and _G.ShieldRangeVisual then
            local range = ShieldConfig.PushRange
            _G.ShieldRangeVisual.Size = Vector3.new(range*2, 5, range*2)
            _G.ShieldRangeVisual.Position = Vector3.new(myRoot.Position.X, myRoot.Position.Y, myRoot.Position.Z)
        end
    end

    local shieldLoop = RunService.Heartbeat:Connect(function()
        if not GlobalState.EnemyShield then return end
        pcall(function()
            UpdateRangeVisual()
            local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            local myPos = myRoot.Position
            for _, v in pairs(Players:GetPlayers()) do
                if v == plr then continue end
                local tRoot = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
                local tHum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then continue end
                local dist = (myPos - tRoot.Position).Magnitude
                if dist < ShieldConfig.PushRange then
                    local dir = (tRoot.Position - myPos).Unit
                    tRoot.Velocity = dir * ShieldConfig.PushForce
                    myRoot.Velocity = -dir * ShieldConfig.PushForce * 0.5
                end
            end
        end)
    end)
    AddLoop(shieldLoop)
end
local function StopEnemyShield()
    GlobalState.EnemyShield = false
    if _G.ShieldRangeVisual then
        pcall(function() _G.ShieldRangeVisual:Destroy() end)
        _G.ShieldRangeVisual = nil
    end
end

-- 射线检测
local function CheckTargetVisible(startPos, endPos, ignoreChar)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {ignoreChar, plr.Character}
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.CollisionGroup = "Default"
    local direction = endPos - startPos
    local raycastResult = Workspace:Raycast(startPos, direction, raycastParams)
    return raycastResult == nil
end

-- 获取敌人可见部位
local function GetEnemyVisiblePart(enemyChar, cameraPos)
    if not enemyChar then return nil end
    local priorityParts = {
        enemyChar:FindFirstChild("Head"),
        enemyChar:FindFirstChild("UpperTorso"),
        enemyChar:FindFirstChild("Torso"),
        enemyChar:FindFirstChild("LowerTorso"),
        enemyChar:FindFirstChild("HumanoidRootPart"),
    }
    for _, part in pairs(priorityParts) do
        if part and part:IsA("BasePart") then
            local isVisible = CheckTargetVisible(cameraPos, part.Position, enemyChar)
            if isVisible then return part end
        end
    end
    return nil
end

-- 屏幕圈圈
local function UpdateAimScreenCircle()
    if not AimTurnConfig.ScreenCircleEnable then
        if AimCircleGui then
            AimCircleGui:Destroy()
            AimCircleGui = nil
            AimCircle = nil
        end
        return
    end
    if not AimCircleGui then
        AimCircleGui = Instance.new("ScreenGui")
        AimCircleGui.Name = "AimScreenCircle"
        AimCircleGui.Parent = CoreGui
        AimCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        AimCircleGui.ResetOnSpawn = false
        AimCircleGui.IgnoreGuiInset = true

        AimCircle = Instance.new("Frame")
        AimCircle.Name = "AimCircle"
        AimCircle.BackgroundTransparency = 1
        AimCircle.Parent = AimCircleGui

        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = AimCircle

        local circleStroke = Instance.new("UIStroke")
        circleStroke.Color = Config.AimVisual.CircleColor
        circleStroke.Thickness = Config.AimVisual.CircleThickness
        circleStroke.Parent = AimCircle

        local crossH = Instance.new("Frame")
        crossH.Name = "CrossH"
        crossH.Size = UDim2.new(0, 10, 0, 2)
        crossH.Position = UDim2.new(0.5, -5, 0.5, -1)
        crossH.BackgroundColor3 = Config.AimVisual.CircleColor
        crossH.Parent = AimCircle
        local crossV = Instance.new("Frame")
        crossV.Name = "CrossV"
        crossV.Size = UDim2.new(0, 2, 0, 10)
        crossV.Position = UDim2.new(0.5, -1, 0.5, -5)
        crossV.BackgroundColor3 = Config.AimVisual.CircleColor
        crossV.Parent = AimCircle
    end
    local radius = AimTurnConfig.ScreenCircleRadius
    AimCircle.Size = UDim2.new(0, radius*2, 0, radius*2)
    AimCircle.Position = UDim2.new(0.5, -radius, 0.5, -radius)
end

-- 视角自瞄
local function StartAutoAimTurn()
    GlobalState.AutoAimTurn = true
    UpdateAimScreenCircle()

    local aimLoop = RunService.Heartbeat:Connect(function()
        if not GlobalState.AutoAimTurn then return end
        pcall(function()
            local myChar = plr.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local currentCamera = Workspace.CurrentCamera
            if not currentCamera then return end
            local cameraPos = currentCamera.CFrame.Position
            local screenCenter = Vector2.new(currentCamera.ViewportSize.X/2, currentCamera.ViewportSize.Y/2)

            local validTargets = {}
            for _, enemy in pairs(Players:GetPlayers()) do
                if enemy == plr then continue end
                if not PlayerLockList[enemy.UserId] then continue end
                
                local enemyChar = enemy.Character
                local enemyHum = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
                local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
                if not enemyChar or not enemyHum or not enemyRoot or enemyHum.Health <= 0 then continue end
                
                local worldDist = (myRoot and myRoot.Position or cameraPos - enemyRoot.Position).Magnitude
                if worldDist > AimTurnConfig.LockRange then continue end

                local targetPart = nil
                if AimTurnConfig.UniversalAimMode then
                    local enemyHead = enemyChar:FindFirstChild("Head")
                    if not enemyHead then enemyHead = enemyRoot end
                    local isVisible = CheckTargetVisible(cameraPos, enemyHead.Position, enemyChar)
                    if not isVisible then continue end
                    targetPart = enemyHead
                else
                    if AimTurnConfig.ObstacleCheck or AimTurnConfig.PriorityVisiblePart then
                        if AimTurnConfig.PriorityVisiblePart then
                            targetPart = GetEnemyVisiblePart(enemyChar, cameraPos)
                        else
                            local rootVisible = CheckTargetVisible(cameraPos, enemyRoot.Position, enemyChar)
                            targetPart = rootVisible and enemyRoot or nil
                        end
                        if not targetPart then continue end
                    else
                        targetPart = enemyRoot
                    end
                end

                if AimTurnConfig.ScreenCircleEnable then
                    local screenPos, isOnScreen = currentCamera:WorldToScreenPoint(targetPart.Position)
                    if not isOnScreen then continue end
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if screenDist > AimTurnConfig.ScreenCircleRadius then continue end
                end

                table.insert(validTargets, {
                    Part = targetPart,
                    WorldDist = worldDist,
                })
            end

            local finalTarget = nil
            local minDist = math.huge
            for _, targetInfo in pairs(validTargets) do
                if targetInfo.WorldDist < minDist then
                    minDist = targetInfo.WorldDist
                    finalTarget = targetInfo.Part
                end
            end

            if finalTarget then
                CurrentLockedPart = finalTarget
                local targetPos = finalTarget.Position

                if AimTurnConfig.BodyOnlyMode then
                    if myRoot then
                        local lookPos = Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z)
                        myRoot.CFrame = CFrame.new(myRoot.Position, lookPos)
                    end
                elseif AimTurnConfig.CameraAimMode then
                    local targetCFrame = CFrame.new(currentCamera.CFrame.Position, targetPos)
                    local smoothFactor = math.clamp(1/AimTurnConfig.CameraAimSpeed, 0.01, 1)
                    currentCamera.CFrame = currentCamera.CFrame:Lerp(targetCFrame, smoothFactor)
                else
                    if myRoot then
                        myRoot.CFrame = CFrame.new(myRoot.Position, targetPos)
                    end
                end
            else
                CurrentLockedPart = nil
            end
        end)
    end)
    AddLoop(aimLoop)
end

local function StopAutoAimTurn()
    GlobalState.AutoAimTurn = false
    if AimCircleGui then
        AimCircleGui:Destroy()
        AimCircleGui = nil
        AimCircle = nil
    end
    CurrentLockedPart = nil
end

-- 身体自瞄
local function StartBodyAim()
    GlobalState.BodyAim = true
    local loop = RunService.Heartbeat:Connect(function()
        if not GlobalState.BodyAim then return end
        pcall(function()
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local best = nil
            local minDist = math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p == plr or not PlayerLockList[p.UserId] then continue end
                local tChar = p.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then continue end
                local dist = (root.Position - tRoot.Position).Magnitude
                if dist > BodyAimConfig.LockRange then continue end
                if dist < minDist then
                    minDist = dist
                    best = tRoot
                end
            end
            if best then
                local look = Vector3.new(best.Position.X, root.Position.Y, best.Position.Z)
                root.CFrame = CFrame.new(root.Position, look)
            end
        end)
    end)
    AddLoop(loop)
end

local function StopBodyAim()
    GlobalState.BodyAim = false
end

-- 身体自瞄设置窗口
local function OpenBodyAimSettings()
    pcall(function() if CoreGui:FindFirstChild("BodyAimSettings") then CoreGui.BodyAimSettings:Destroy() end end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "BodyAimSettings"
    sg.Parent = CoreGui
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,300,0,200)
    main.Position = UDim2.new(0.5,-150,0.5,-100)
    main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    main.Parent = sg
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = main
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-50,1,0)
    title.Position = UDim2.new(0,10,0,0)
    title.BackgroundTransparency = 1
    title.Text = "身体自瞄设置"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Parent = top
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,40,0,40)
    close.Position = UDim2.new(1,-40,0,0)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.new(1,0.2,0.2)
    close.TextSize = 24
    close.Parent = top
    close.MouseButton1Click:Connect(function() sg:Destroy() end)

    local function NumSet(y, txt, key)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.9,0,0,40)
        f.Position = UDim2.new(0.05,0,0,y)
        f.BackgroundTransparency = 1
        f.Parent = main
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.5,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.new(1,1,1)
        l.TextSize = 15
        l.Parent = f
        local i = Instance.new("TextBox")
        i.Size = UDim2.new(0.3,0,0,35)
        i.Position = UDim2.new(0.5,0,0,2)
        i.BackgroundColor3 = Config.InputBg
        i.Text = tostring(BodyAimConfig[key])
        i.TextColor3 = Color3.new(1,1,1)
        i.Parent = f
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.18,0,0,35)
        b.Position = UDim2.new(0.82,0,0,2)
        b.BackgroundColor3 = Config.BtnBlue
        b.Text = "确定"
        b.TextColor3 = Color3.new(1,1,1)
        b.Parent = f
        b.MouseButton1Click:Connect(function()
            local v = tonumber(i.Text)
            if v then BodyAimConfig[key] = math.clamp(v,5,200) end
        end)
    end

    local function ToggleSet(y, txt, key)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.9,0,0,40)
        f.Position = UDim2.new(0.05,0,0,y)
        f.BackgroundTransparency = 1
        f.Parent = main
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.new(1,1,1)
        l.TextSize = 15
        l.Parent = f
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.3,0,0,35)
        b.Position = UDim2.new(0.7,0,0,2)
        b.BackgroundColor3 = BodyAimConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
        b.Text = BodyAimConfig[key] and "开启" or "关闭"
        b.TextColor3 = Color3.new(1,1,1)
        b.Parent = f
        b.MouseButton1Click:Connect(function()
            BodyAimConfig[key] = not BodyAimConfig[key]
            b.BackgroundColor3 = BodyAimConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
            b.Text = BodyAimConfig[key] and "开启" or "关闭"
        end)
    end

    NumSet(50, "锁定距离", "LockRange")
    ToggleSet(100, "障碍物检测", "ObstacleCheck")
end

-- 自瞄设置UI
local function OpenAimTurnSettings()
    pcall(function() if CoreGui:FindFirstChild("AimTurnSettings") then CoreGui.AimTurnSettings:Destroy() end end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "AimTurnSettings"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 360, 0, 620)
    mainFrame.Position = UDim2.new(0.5, -180, 0.5, -310)
    mainFrame.BackgroundColor3 = Color3.new(0.12, 0.12, 0.15)
    mainFrame.BorderSizePixel = 1
    mainFrame.Parent = sg

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
    topBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "自瞄转向设置"
    titleLabel.TextColor3 = Config.TextWhite
    titleLabel.TextSize = 18
    titleLabel.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1, 0.2, 0.2)
    closeBtn.TextSize = 24
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -16, 1, -52)
    scrollFrame.Position = UDim2.new(0, 8, 0, 44)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 12)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = scrollFrame

    local function CreateSectionTitle(text, layoutOrder)
        local titleFrame = Instance.new("Frame")
        titleFrame.Size = UDim2.new(0.95, 0, 0, 26)
        titleFrame.BackgroundTransparency = 1
        titleFrame.LayoutOrder = layoutOrder
        titleFrame.Parent = scrollFrame
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(1, 0, 1, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = "—— "..text.." ——"
        titleText.TextColor3 = Color3.fromRGB(200,200,100)
        titleText.TextSize = 14
        titleText.Parent = titleFrame
    end

    local function CreateNumberSetting(txt, configKey, min, max, layoutOrder)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.95, 0, 0, 42)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = layoutOrder
        frame.Parent = scrollFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.45, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = txt
        label.TextColor3 = Config.TextWhite
        label.TextSize = 15
        label.Parent = frame

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.2, 0, 0, 36)
        input.Position = UDim2.new(0.47, 0, 0, 3)
        input.BackgroundColor3 = Config.InputBg
        input.Text = tostring(AimTurnConfig[configKey])
        input.TextColor3 = Config.TextWhite
        input.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = input

        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Size = UDim2.new(0.25, 0, 0, 36)
        confirmBtn.Position = UDim2.new(0.7, 0, 0, 3)
        confirmBtn.BackgroundColor3 = Config.BtnBlue
        confirmBtn.Text = "确定"
        confirmBtn.TextColor3 = Config.TextWhite
        confirmBtn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = confirmBtn

        confirmBtn.MouseButton1Click:Connect(function()
            local num = tonumber(input.Text)
            if num then
                AimTurnConfig[configKey] = math.clamp(num, min, max)
                input.Text = tostring(AimTurnConfig[configKey])
                if configKey == "ScreenCircleRadius" then UpdateAimScreenCircle() end
            end
        end)
    end

    local function CreateToggleSetting(txt, configKey, layoutOrder, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.95, 0, 0, 42)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = layoutOrder
        frame.Parent = scrollFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = txt
        label.TextColor3 = Config.TextWhite
        label.TextSize = 15
        label.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0.3, 0, 0, 36)
        toggleBtn.Position = UDim2.new(0.7, 0, 0, 3)
        toggleBtn.BackgroundColor3 = AimTurnConfig[configKey] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
        toggleBtn.Text = AimTurnConfig[configKey] and "开启" or "关闭"
        toggleBtn.TextColor3 = Config.TextWhite
        toggleBtn.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = toggleBtn

        toggleBtn.MouseButton1Click:Connect(function()
            AimTurnConfig[configKey] = not AimTurnConfig[configKey]
            toggleBtn.BackgroundColor3 = AimTurnConfig[configKey] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
            toggleBtn.Text = AimTurnConfig[configKey] and "开启" or "关闭"
            if callback then callback(AimTurnConfig[configKey]) end
        end)
    end

    local function CreatePlayerOptionBtn(layoutOrder)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.95, 0, 0, 42)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = layoutOrder
        frame.Parent = scrollFrame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = Config.BtnPurple
        btn.Text = "玩家选项（勾选锁定）"
        btn.TextColor3 = Config.TextWhite
        btn.TextSize = 15
        btn.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(OpenPlayerLockWindow)
    end

    CreateSectionTitle("全服通用自瞄", 0)
    CreateToggleSetting("全服通用锁头自瞄", "UniversalAimMode", 1)
    CreatePlayerOptionBtn(2)

    CreateSectionTitle("基础锁定设置", 10)
    CreateNumberSetting("最大锁定距离(格)", "LockRange", 5, 2000, 11)

    CreateSectionTitle("障碍物与部位锁定", 20)
    CreateToggleSetting("障碍物检测", "ObstacleCheck", 21)
    CreateToggleSetting("可见部位优先锁定", "PriorityVisiblePart", 22)

    CreateSectionTitle("转向模式设置", 30)
    CreateToggleSetting("仅身体转向(视角不动)", "BodyOnlyMode", 31)
    CreateToggleSetting("视角自瞄模式", "CameraAimMode", 32)
    CreateNumberSetting("视角拉枪平滑速度", "CameraAimSpeed", 1, 50, 33)

    CreateSectionTitle("屏幕锁定圈圈设置", 40)
    CreateToggleSetting("开启屏幕锁定圈圈", "ScreenCircleEnable", 41, UpdateAimScreenCircle)
    CreateNumberSetting("圈圈半径(像素)", "ScreenCircleRadius", 20, 1000, 42)
end

-- 玩家选择窗口
function OpenPlayerLockWindow()
    pcall(function() if CoreGui:FindFirstChild("PlayerLockWindow") then CoreGui.PlayerLockWindow:Destroy() end end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "PlayerLockWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 320, 0, 400)
    main.Position = UDim2.new(0.5, -160, 0.5, -200)
    main.BackgroundColor3 = Color3.new(0.12, 0.12, 0.15)
    main.Parent = sg

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
    topBar.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(0, 0, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 22
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 60, 0, 32)
    refreshBtn.Position = UDim2.new(1, -70, 0, 4)
    refreshBtn.BackgroundColor3 = Config.BtnBlue
    refreshBtn.Text = "刷新"
    refreshBtn.TextColor3 = Color3.new(1,1,1)
    refreshBtn.Parent = topBar
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 4)
    rCorner.Parent = refreshBtn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -12, 1, -45)
    scroll.Position = UDim2.new(0, 6, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    local function RefreshList()
        for _, c in pairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p == plr then continue end
            local locked = PlayerLockList[p.UserId]

            local item = Instance.new("Frame")
            item.Size = UDim2.new(0.96, 0, 0, 52)
            item.BackgroundTransparency = 1
            item.Parent = scroll

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 40, 0, 40)
            avatar.Position = UDim2.new(0, 8, 0, 6)
            avatar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
            avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", p.UserId)
            avatar.Parent = item
            local aCorner = Instance.new("UICorner")
            aCorner.CornerRadius = UDim.new(0, 4)
            aCorner.Parent = avatar

            local nameLab = Instance.new("TextLabel")
            nameLab.Size = UDim2.new(0.55, 0, 1, 0)
            nameLab.Position = UDim2.new(0, 56, 0, 0)
            nameLab.BackgroundTransparency = 1
            nameLab.Text = p.Name
            nameLab.TextColor3 = Color3.new(1,1,1)
            nameLab.TextSize = 15
            nameLab.Parent = item

            local checkBtn = Instance.new("TextButton")
            checkBtn.Size = UDim2.new(0, 32, 0, 32)
            checkBtn.Position = UDim2.new(1, -40, 0, 10)
            checkBtn.BackgroundColor3 = locked and Color3.new(0, 0.6, 0) or Color3.new(0.3, 0.3, 0.35)
            checkBtn.Text = locked and "✓" or ""
            checkBtn.TextColor3 = Color3.new(1,1,1)
            checkBtn.Parent = item
            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 4)
            cCorner.Parent = checkBtn

            checkBtn.MouseButton1Click:Connect(function()
                PlayerLockList[p.UserId] = not PlayerLockList[p.UserId]
                checkBtn.BackgroundColor3 = PlayerLockList[p.UserId] and Color3.new(0, 0.6, 0) or Color3.new(0.3, 0.3, 0.35)
                checkBtn.Text = PlayerLockList[p.UserId] and "✓" or ""
            end)
        end
    end

    refreshBtn.MouseButton1Click:Connect(RefreshList)
    RefreshList()
end

-- 隔离敌人设置
local function OpenShieldSettings()
    pcall(function() if CoreGui:FindFirstChild("ShieldSettings") then CoreGui.ShieldSettings:Destroy() end end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ShieldSettings"
    sg.Parent = CoreGui
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,340,0,250)
    bg.Position = UDim2.new(0.5,-170,0.5,-125)
    bg.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    bg.BorderSizePixel = 1
    bg.Parent = sg
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Text = "隔离敌人设置"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Parent = bg
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,30,0,30)
    close.Position = UDim2.new(1,-35,0,5)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.new(1,0.2,0.2)
    close.Parent = bg
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
    local function CreateInputSetting(y, txt, key, min, max)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.9,0,0,40)
        f.Position = UDim2.new(0.05,0,0,y)
        f.BackgroundTransparency = 1
        f.Parent = bg
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.4,0,1,0)
        l.Position = UDim2.new(0,0,0,0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.new(1,1,1)
        l.TextSize = 16
        l.Parent = f
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.25,0,0,30)
        input.Position = UDim2.new(0.4,0,0,5)
        input.BackgroundColor3 = Config.InputBg
        input.Text = tostring(ShieldConfig[key])
        input.TextColor3 = Color3.new(1,1,1)
        input.ClearTextOnFocus = false
        input.Parent = f
        local confirm = Instance.new("TextButton")
        confirm.Size = UDim2.new(0.25,0,0,30)
        confirm.Position = UDim2.new(0.67,0,0,5)
        confirm.BackgroundColor3 = Config.BtnBlue
        confirm.Text = "确定"
        confirm.TextColor3 = Color3.new(1,1,1)
        confirm.Parent = f
        confirm.MouseButton1Click:Connect(function()
            local num = tonumber(input.Text)
            if not num then return end
            num = math.clamp(num, min, max)
            ShieldConfig[key] = num
            input.Text = tostring(num)
        end)
    end
    local function CreateToggle(y, txt, key)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.9,0,0,40)
        f.Position = UDim2.new(0.05,0,0,y)
        f.BackgroundTransparency = 1
        f.Parent = bg
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6,0,1,0)
        l.Position = UDim2.new(0,0,0,0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.new(1,1,1)
        l.TextSize = 16
        l.Parent = f
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.3,0,0,30)
        b.Position = UDim2.new(0.7,0,0,5)
        b.BackgroundColor3 = ShieldConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
        b.Text = ShieldConfig[key] and "开启" or "关闭"
        b.TextColor3 = Color3.new(1,1,1)
        b.Parent = f
        b.MouseButton1Click:Connect(function()
            ShieldConfig[key] = not ShieldConfig[key]
            b.BackgroundColor3 = ShieldConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
            b.Text = ShieldConfig[key] and "开启" or "关闭"
        end)
    end
    CreateInputSetting(40, "推开范围(格)", "PushRange", 5, 100)
    CreateInputSetting(90, "推开力度", "PushForce", 10, 200)
    CreateToggle(140, "隔离范围可视化", "ShowRange")
end

-- 道具获取
local function GetAllGameItems()
    local items = {}
    local addedNames = {}
    local searchPaths = {
        ReplicatedStorage, StarterPack, StarterGear, Workspace,
        game:GetService("ReplicatedFirst"), game:GetService("ServerStorage"),
        game:GetService("Lighting"), game:GetService("Teams"),
        game:GetService("SoundService"), game:GetService("Chat"),
    }
    for _, path in pairs(searchPaths) do
        pcall(function()
            for _, obj in pairs(path:GetDescendants()) do
                if obj:IsA("Tool") and not addedNames[obj.Name] then
                    addedNames[obj.Name] = true
                    table.insert(items, obj)
                end
            end
        end)
    end
    table.sort(items, function(a,b) return a.Name < b.Name end)
    return items
end

local function OpenItemSettingWindow(itemObj, parentWindow)
    pcall(function() CoreGui:FindFirstChild("ItemSettingWindow"):Destroy() end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ItemSettingWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(60,60,60)
    mainFrame.Parent = sg
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 35)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "道具设置："..itemObj.Name
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    local countFrame = Instance.new("Frame")
    countFrame.Size = UDim2.new(1, -20, 0, 40)
    countFrame.Position = UDim2.new(0, 10, 0, 55)
    countFrame.BackgroundTransparency = 1
    countFrame.Parent = mainFrame
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0, 100, 1, 0)
    countLabel.Position = UDim2.new(0, 0, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "获取数量："
    countLabel.TextColor3 = Color3.new(1,1,1)
    countLabel.TextSize = 15
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = countFrame
    local countInput = Instance.new("TextBox")
    countInput.Size = UDim2.new(0, 150, 0, 35)
    countInput.Position = UDim2.new(0, 100, 0, 2)
    countInput.BackgroundColor3 = Config.InputBg
    countInput.Text = "1"
    countInput.TextColor3 = Color3.new(1,1,1)
    countInput.TextSize = 15
    countInput.TextXAlignment = Enum.TextXAlignment.Center
    countInput.Parent = countFrame
    local countCorner = Instance.new("UICorner")
    countCorner.CornerRadius = UDim.new(0, 5)
    countCorner.Parent = countInput
    local useFrame = Instance.new("Frame")
    useFrame.Size = UDim2.new(1, -20, 0, 40)
    useFrame.Position = UDim2.new(0, 10, 0, 105)
    useFrame.BackgroundTransparency = 1
    useFrame.Parent = mainFrame
    local useLabel = Instance.new("TextLabel")
    useLabel.Size = UDim2.new(0, 100, 1, 0)
    useLabel.Position = UDim2.new(0, 0, 0, 0)
    useLabel.BackgroundTransparency = 1
    useLabel.Text = "使用次数："
    useLabel.TextColor3 = Color3.new(1,1,1)
    useLabel.TextSize = 15
    useLabel.TextXAlignment = Enum.TextXAlignment.Left
    useLabel.Parent = useFrame
    local useInput = Instance.new("TextBox")
    useInput.Size = UDim2.new(0, 150, 0, 35)
    useInput.Position = UDim2.new(0, 100, 0, 2)
    useInput.BackgroundColor3 = Config.InputBg
    useInput.Text = "0"
    useInput.PlaceholderText = "0=无限使用"
    useInput.TextColor3 = Color3.new(1,1,1)
    useInput.TextSize = 15
    useInput.TextXAlignment = Enum.TextXAlignment.Center
    useInput.Parent = useFrame
    local useCorner = Instance.new("UICorner")
    useCorner.CornerRadius = UDim.new(0, 5)
    useCorner.Parent = useInput
    local tipLabel = Instance.new("TextLabel")
    tipLabel.Size = UDim2.new(1, -20, 0, 20)
    tipLabel.Position = UDim2.new(0, 10, 0, 150)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Text = "提示：使用次数填0，自动设置为无限耐久"
    tipLabel.TextColor3 = Color3.fromRGB(200,200,100)
    tipLabel.TextSize = 12
    tipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tipLabel.Parent = mainFrame
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0, 140, 0, 40)
    cancelBtn.Position = UDim2.new(0, 10, 0, 180)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    cancelBtn.Text = "取消"
    cancelBtn.TextColor3 = Color3.new(1,1,1)
    cancelBtn.TextSize = 15
    cancelBtn.Font = Enum.Font.SourceSansBold
    cancelBtn.Parent = mainFrame
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelBtn
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 140, 0, 40)
    confirmBtn.Position = UDim2.new(1, -150, 0, 180)
    confirmBtn.BackgroundColor3 = Config.BtnGreen
    confirmBtn.Text = "确定获取"
    confirmBtn.TextColor3 = Color3.new(1,1,1)
    confirmBtn.TextSize = 15
    confirmBtn.Font = Enum.Font.SourceSansBold
    confirmBtn.Parent = mainFrame
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 6)
    confirmCorner.Parent = confirmBtn
    cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    confirmBtn.MouseButton1Click:Connect(function()
        local count = tonumber(countInput.Text)
        local useCount = tonumber(useInput.Text)
        if not count or count < 1 then tipLabel.Text = "❌ 请输入有效的数量"; tipLabel.TextColor3 = Color3.fromRGB(255,80,80); return end
        if not useCount or useCount < 0 then tipLabel.Text = "❌ 请输入有效的使用次数"; tipLabel.TextColor3 = Color3.fromRGB(255,80,80); return end
        local successCount = 0
        local backpack = plr:FindFirstChild("Backpack")
        if not backpack then tipLabel.Text = "❌ 未找到背包"; tipLabel.TextColor3 = Color3.fromRGB(255,80,80); return end
        for i=1, count do
            pcall(function()
                local clonedItem = itemObj:Clone()
                if useCount == 0 then
                    local useValueNames = {"Uses","Durability","RemainingUses","MaxUses","Ammo","ClipSize"}
                    for _, name in pairs(useValueNames) do
                        local valObj = clonedItem:FindFirstChild(name, true)
                        if valObj and (valObj:IsA("NumberValue") or valObj:IsA("IntValue")) then
                            valObj.Value = 999999
                        end
                    end
                else
                    local useValueNames = {"Uses","Durability","RemainingUses"}
                    for _, name in pairs(useValueNames) do
                        local valObj = clonedItem:FindFirstChild(name, true)
                        if valObj and (valObj:IsA("NumberValue") or valObj:IsA("IntValue")) then
                            valObj.Value = useCount
                        end
                    end
                end
                clonedItem.Parent = backpack
                successCount += 1
            end)
        end
        if successCount > 0 then
            tipLabel.Text = string.format("✅ 成功获取%d个 %s", successCount, itemObj.Name)
            tipLabel.TextColor3 = Color3.fromRGB(80,255,80)
            task.delay(1, function() sg:Destroy() end)
        else
            tipLabel.Text = "❌ 获取道具失败，该道具无法克隆"
            tipLabel.TextColor3 = Color3.fromRGB(255,80,80)
        end
    end)
end

local function OpenItemListWindow()
    pcall(function() CoreGui:FindFirstChild("ItemListWindow"):Destroy() end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ItemListWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    mainFrame.Position = UDim2.new(0.05, 0, 0.075, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12,12,15)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(50,50,60)
    mainFrame.Parent = sg
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 45)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(20,20,25)
    topBar.Parent = mainFrame
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 10)
    topCorner.Parent = topBar
    local topClip = Instance.new("CanvasGroup")
    topClip.Size = UDim2.new(1,0,1,0)
    topClip.Parent = topBar
    topClip.ClipsDescendants = true
    topCorner.Parent = topClip
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "全服务器道具列表"
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0, 150, 1, 0)
    countLabel.Position = UDim2.new(0, 220, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "正在加载道具..."
    countLabel.TextColor3 = Color3.fromRGB(200,200,200)
    countLabel.TextSize = 14
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = topBar
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 80, 0, 35)
    refreshBtn.Position = UDim2.new(1, -180, 0, 5)
    refreshBtn.BackgroundColor3 = Config.BtnBlue
    refreshBtn.Text = "刷新"
    refreshBtn.TextColor3 = Color3.new(1,1,1)
    refreshBtn.TextSize = 15
    refreshBtn.Font = Enum.Font.SourceSansBold
    refreshBtn.Parent = topBar
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 6)
    refreshCorner.Parent = refreshBtn
    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 80, 0, 35)
    backBtn.Position = UDim2.new(1, -95, 0, 5)
    backBtn.BackgroundColor3 = Config.BtnRed
    backBtn.Text = "返回"
    backBtn.TextColor3 = Color3.new(1,1,1)
    backBtn.TextSize = 15
    backBtn.Font = Enum.Font.SourceSansBold
    backBtn.Parent = topBar
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = backBtn
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -55)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60,60,70)
    scrollFrame.Parent = mainFrame
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = scrollFrame
    gridLayout.CellSize = UDim2.new(0, 90, 0, 110)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
    local function LoadItems()
        for _, child in pairs(scrollFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        local allItems = GetAllGameItems()
        countLabel.Text = string.format("共找到%d个道具", #allItems)
        for _, item in pairs(allItems) do
            pcall(function()
                local itemCell = Instance.new("Frame")
                itemCell.Size = UDim2.new(0, 90, 0, 110)
                itemCell.BackgroundColor3 = Color3.fromRGB(25,25,30)
                itemCell.Parent = scrollFrame
                local cellCorner = Instance.new("UICorner")
                cellCorner.CornerRadius = UDim.new(0, 6)
                cellCorner.Parent = itemCell
                local iconImg = Instance.new("ImageLabel")
                iconImg.Size = UDim2.new(0, 60, 0, 60)
                iconImg.Position = UDim2.new(0.5, -30, 0, 8)
                iconImg.BackgroundTransparency = 1
                iconImg.Image = item.TextureId or "rbxassetid://154966922"
                iconImg.ScaleType = Enum.ScaleType.Fit
                iconImg.Parent = itemCell
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -6, 0, 30)
                nameLabel.Position = UDim2.new(0, 3, 0, 75)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = item.Name
                nameLabel.TextColor3 = Color3.new(1,1,1)
                nameLabel.TextSize = 12
                nameLabel.Font = Enum.Font.SourceSans
                nameLabel.TextWrapped = true
                nameLabel.TextScaled = false
                nameLabel.TextXAlignment = Enum.TextXAlignment.Center
                nameLabel.TextYAlignment = Enum.TextYAlignment.Top
                nameLabel.Parent = itemCell
                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1,0,1,0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""
                clickBtn.Parent = itemCell
                clickBtn.ZIndex = 10
                clickBtn.MouseButton1Click:Connect(function() OpenItemSettingWindow(item, sg) end)
            end)
        end
    end
    backBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    refreshBtn.MouseButton1Click:Connect(LoadItems)
    task.spawn(LoadItems)
end

-- 无延迟移动优化
local function StartMoveOptimize()
    MoveOptimizeConfig.Enabled = true
    local controlModule = nil
    pcall(function()
        local PlayerScripts = plr:WaitForChild("PlayerScripts")
        local PlayerModule = PlayerScripts:WaitForChild("PlayerModule")
        controlModule = require(PlayerModule:WaitForChild("ControlModule"))
    end)

    local moveLoop = RunService.Heartbeat:Connect(function()
        if not MoveOptimizeConfig.Enabled then return end
        pcall(function()
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end

            hum.WalkSpeed = hum.WalkSpeed
            hum.JumpPower = hum.JumpPower
            hum.AutoRotate = true
            hum:SetStateEnabled(Enum.HumanoidStateType.Accelerating, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Decelerating, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

            if controlModule then
                local moveVector = controlModule:GetMoveVector()
                if moveVector.Magnitude > 0 then
                    root.Velocity = Vector3.new(moveVector.X * hum.WalkSpeed, root.Velocity.Y, moveVector.Z * hum.WalkSpeed)
                end
            end
        end)
    end)
    AddLoop(moveLoop)
end

local function StopMoveOptimize()
    MoveOptimizeConfig.Enabled = false
    pcall(function()
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Accelerating, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Decelerating, true)
        end
    end)
end

-- ========== 新功能：画质优化（纯白删贴图） ==========
local function StartGraphicsOptimize()
    GraphicsOptimizeConfig.Enabled = true
    pcall(function()
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then
                if not GraphicsOptimizeConfig.OriginalTextures[v] then
                    GraphicsOptimizeConfig.OriginalTextures[v] = v.Texture
                end
                v.Texture = ""
            end
            if v:IsA("SpecialMesh") then
                if not GraphicsOptimizeConfig.OriginalTextures[v] then
                    GraphicsOptimizeConfig.OriginalTextures[v] = v.TextureId
                end
                v.TextureId = ""
            end
            if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("ParticleEmitter") or v:IsA("PointLight") then
                if not GraphicsOptimizeConfig.OriginalEffects[v] then
                    GraphicsOptimizeConfig.OriginalEffects[v] = v.Enabled
                end
                v.Enabled = false
            end
        end
        game.Lighting.GlobalShadows = false
        game.Lighting.Ambient = Color3.new(1,1,1)
    end)
end

local function StopGraphicsOptimize()
    GraphicsOptimizeConfig.Enabled = false
    pcall(function()
        for v,tex in pairs(GraphicsOptimizeConfig.OriginalTextures) do
            if v then
                if v:IsA("Texture") or v:IsA("Decal") then v.Texture = tex end
                if v:IsA("SpecialMesh") then v.TextureId = tex end
            end
        end
        for v,ena in pairs(GraphicsOptimizeConfig.OriginalEffects) do
            if v then v.Enabled = ena end
        end
        game.Lighting.GlobalShadows = true
        game.Lighting.Ambient = Color3.new(0.5,0.5,0.5)
        GraphicsOptimizeConfig.OriginalTextures = {}
        GraphicsOptimizeConfig.OriginalEffects = {}
    end)
end

-- ========== 新功能：清除建筑物（范围可调） ==========
local function StartClearBuildings()
    ClearBuildConfig.Enabled = true
    task.spawn(function()
        while ClearBuildConfig.Enabled do
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _,v in pairs(workspace:GetDescendants()) do
                    if (v:IsA("BasePart") or v:IsA("Model")) and not v:FindFirstChildOfClass("Humanoid") then
                        local part = v:IsA("Model") and v.PrimaryPart or v
                        if part and (root.Position-part.Position).Magnitude <= ClearBuildConfig.Radius then
                            local isFloor = part.Size.Y < 1.2 and part.Position.Y <= root.Position.Y+1
                            if not isFloor then
                                if not ClearBuildConfig.OriginalState[v] then
                                    ClearBuildConfig.OriginalState[v] = {Transparency=v.Transparency,CanCollide=v.CanCollide,CanQuery=v.CanQuery}
                                end
                                v.Transparency = 1
                                v.CanCollide = false
                                v.CanQuery = false
                            end
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

local function StopClearBuildings()
    ClearBuildConfig.Enabled = false
    for v,s in pairs(ClearBuildConfig.OriginalState) do
        if v then
            v.Transparency = s.Transparency
            v.CanCollide = s.CanCollide
            v.CanQuery = s.CanQuery
        end
    end
    ClearBuildConfig.OriginalState = {}
end

local function OpenClearBuildSettings()
    pcall(function()
        for _,v in pairs(game.CoreGui:GetChildren()) do if v.Name=="ClearSet" then v:Destroy() end end
        local sg = Instance.new("ScreenGui")
        sg.Name = "ClearSet"
        sg.Parent = game.CoreGui
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,260,0,160)
        f.Position = UDim2.new(0.5,-130,0.5,-80)
        f.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
        f.Parent = sg

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,0,0,40)
        title.BackgroundTransparency = 1
        title.Text = "清除建筑范围"
        title.TextColor3 = Color3.new(1,1,1)
        title.Parent = f

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.8,0,0,40)
        input.Position = UDim2.new(0.1,0,0,50)
        input.BackgroundColor3 = Color3.new(0.2,0.2,0.25)
        input.TextColor3 = Color3.new(1,1,1)
        input.Text = tostring(ClearBuildConfig.Radius)
        input.Parent = f

        local ok = Instance.new("TextButton")
        ok.Size = UDim2.new(0.8,0,0,40)
        ok.Position = UDim2.new(0.1,0,0,100)
        ok.BackgroundColor3 = Color3.new(0,0.6,0)
        ok.Text = "确定"
        ok.TextColor3 = Color3.new(1,1,1)
        ok.Parent = f

        ok.MouseButton1Click:Connect(function()
            local val = tonumber(input.Text)
            if val then ClearBuildConfig.Radius = math.clamp(val,10,100) end
            sg:Destroy()
        end)
    end)
end

-- ========== AI战斗核心 ==========
local function GetNearestPlayer()
    local root = plr.Character and plr.Character.HumanoidRootPart
    local near = nil
    local min = 9e9
    for _,p in pairs(game.Players:GetPlayers()) do
        if p~=plr and p.Character and p.Character.Humanoid.Health>0 then
            local r = p.Character.HumanoidRootPart
            local d = (root.Position-r.Position).Magnitude
            if d < min and d <= AICombatConfig.LockRadius then
                min = d
                near = p
            end
        end
    end
    return near
end

-- 索敌模式切换：准星瞄准/最近目标
local function GetCurrentCombatTarget()
    if AICombatConfig.FixedTarget and AICombatConfig.FixedTarget.Character then
        local fixedRoot = AICombatConfig.FixedTarget.Character:FindFirstChild("HumanoidRootPart")
        if fixedRoot and AICombatConfig.FixedTarget.Character.Humanoid.Health > 0 then
            return AICombatConfig.FixedTarget
        end
    end

    local localRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    if AICombatConfig.LockMode == "Crosshair" then
        local cam = game.Workspace.CurrentCamera
        local nearestTarget = nil
        local minScreenDist = 1000
        for _,p in pairs(game.Players:GetPlayers()) do
            if p == plr or not p.Character or p.Character.Humanoid.Health <= 0 then continue end
            local troot = p.Character:FindFirstChild("HumanoidRootPart")
            if not troot then continue end
            local screenPos = cam:WorldToScreenPoint(troot.Position)
            if screenPos.Z > 0 then
                local screenCenter = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                local dist = (screenCenter - targetScreenPos).Magnitude
                if dist < minScreenDist then
                    minScreenDist = dist
                    nearestTarget = p
                end
            end
        end
        if nearestTarget then return nearestTarget end
    end

    -- 最近目标兜底
    local nearestPlayer = nil
    local minDist = 9e9
    for _,p in pairs(game.Players:GetPlayers()) do
        if p == plr or not p.Character or p.Character.Humanoid.Health <= 0 then continue end
        local troot = p.Character:FindFirstChild("HumanoidRootPart")
        if not troot then continue end
        local dist = (localRoot.Position - troot.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearestPlayer = p
        end
    end
    return nearestPlayer
end

local function StartAICombat()
    AICombatConfig.Enabled = true
    local loop = game.RunService.Heartbeat:Connect(function()
        if not AICombatConfig.Enabled then return end
        pcall(function()
            local char = plr.Character
            local root = char and char.HumanoidRootPart
            local hum = char and char.Humanoid
            if not root or not hum or hum.Health<=0 then return end
            local target = GetCurrentCombatTarget()
            if not target then
                hum.WalkSpeed = 16
                return
            end
            local troot = target.Character.HumanoidRootPart
            local dist = (root.Position-troot.Position).Magnitude
            local safe = AIEngine.WeaponRange + AICombatConfig.SafeOffset
            if dist < safe-0.3 then
                if tick()-AIEngine.LastDodge > 0.4 then
                    root.Velocity = Vector3.new(math.random(-1,1),0,math.random(-1,1)).Unit*25
                    AIEngine.LastDodge = tick()
                end
            end
            if dist > safe and dist < AICombatConfig.LockRadius then
                hum.WalkSpeed = AICombatConfig.ChaseSpeed
                hum:MoveTo(troot.Position)
            else
                hum.WalkSpeed = 0
            end
            if AICombatConfig.AIControlCamera then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position,Vector3.new(troot.Position.X,root.Position.Y,troot.Position.Z))
            end
            if not AICombatConfig.ManualAttack and dist <= safe+1 and tick()-AIEngine.LastAttack > AICombatConfig.AttackDelay then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                AIEngine.LastAttack = tick()
            end
        end)
    end)
    AddLoop(loop)
end

local function StopAICombat()
    AICombatConfig.Enabled = false
end

-- 目标选择窗口
local function OpenTargetSelect()
    pcall(function()
        for _,v in pairs(game.CoreGui:GetChildren()) do
            if v.Name=="TargetSelect" then v:Destroy() end
        end
    end)
    local s = Instance.new("ScreenGui")
    s.Name="TargetSelect"
    s.Parent=game.CoreGui
    local m = Instance.new("Frame")
    m.Size=UDim2.new(0,300,0,400)
    m.Position=UDim2.new(0.5,-150,0.5,-200)
    m.BackgroundColor3=Color3.new(0.12,0.12,0.15)
    m.Parent=s
    local sg = Instance.new("ScrollingFrame")
    sg.Size=UDim2.new(1,0,0.8,0)
    sg.BackgroundTransparency=1
    sg.CanvasSize=UDim2.new(0,0,5,0)
    sg.Parent=m
    local y=0
    for _,p in pairs(game.Players:GetPlayers()) do
        if p == plr then continue end
        local b = Instance.new("TextButton")
        b.Size=UDim2.new(1,0,0,30)
        b.Position=UDim2.new(0,0,0,y)
        b.BackgroundColor3=Color3.new(0.2,0.2,0.25)
        b.Text=p.Name
        b.TextColor3=Color3.new(1,1,1)
        b.Parent=sg
        b.MouseButton1Click:Connect(function()
            AICombatConfig.FixedTarget = p
        end)
        y=y+35
    end
    local ok = Instance.new("TextButton")
    ok.Size=UDim2.new(0.9,0,0.15,0)
    ok.Position=UDim2.new(0.05,0,0.85,0)
    ok.BackgroundColor3=Color3.new(0,0.6,0)
    ok.Text="确定"
    ok.TextColor3=Color3.new(1,1,1)
    ok.Parent=m
    ok.MouseButton1Click:Connect(function() s:Destroy() end)
end

-- AI设置窗口
local function OpenAISettings()
    pcall(function()
        for _,v in pairs(game.CoreGui:GetChildren()) do
            if v.Name=="AISet" then v:Destroy() end
        end
    end)
    
    local s = Instance.new("ScreenGui")
    s.Name = "AISet"
    s.Parent = game.CoreGui
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,350,0,450)
    f.Position = UDim2.new(0.5,-175,0.5,-225)
    f.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    f.Parent = s
    
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = f
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-50,1,0)
    title.Position = UDim2.new(0,10,0,0)
    title.BackgroundTransparency = 1
    title.Text = "AI全自动战斗设置"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Parent = top
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,40,0,40)
    close.Position = UDim2.new(1,-40,0,0)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.new(1,0.2,0.2)
    close.TextSize = 24
    close.Parent = top
    close.MouseButton1Click:Connect(function() s:Destroy() end)
    
    local function CreateNumInput(y, label, key, min, max)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.9,0,0,40)
        frame.Position = UDim2.new(0.05,0,0,y)
        frame.BackgroundTransparency = 1
        frame.Parent = f
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextSize = 14
        lbl.Parent = frame
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.35,0,0,35)
        input.Position = UDim2.new(0.4,0,0,2.5)
        input.BackgroundColor3 = Color3.new(0.2,0.2,0.25)
        input.TextColor3 = Color3.new(1,1,1)
        input.Text = tostring(AICombatConfig[key])
        input.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2,0,0,35)
        btn.Position = UDim2.new(0.78,0,0,2.5)
        btn.BackgroundColor3 = Color3.new(0,0.6,0)
        btn.Text = "确定"
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = frame
        
        btn.MouseButton1Click:Connect(function()
            local val = tonumber(input.Text)
            if val then
                AICombatConfig[key] = math.clamp(val, min, max)
                input.Text = tostring(AICombatConfig[key])
            end
        end)
    end
    
    local function CreateToggle(y, label, key)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.9,0,0,40)
        frame.Position = UDim2.new(0.05,0,0,y)
        frame.BackgroundTransparency = 1
        frame.Parent = f
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextSize = 14
        lbl.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25,0,0,35)
        btn.Position = UDim2.new(0.7,0,0,2.5)
        btn.BackgroundColor3 = AICombatConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
        btn.Text = AICombatConfig[key] and "开启" or "关闭"
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            AICombatConfig[key] = not AICombatConfig[key]
            btn.BackgroundColor3 = AICombatConfig[key] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
            btn.Text = AICombatConfig[key] and "开启" or "关闭"
        end)
    end
    
    local function CreateBtn(y, label, func)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9,0,0,40)
        btn.Position = UDim2.new(0.05,0,0,y)
        btn.BackgroundColor3 = Color3.new(0.2,0.2,0.25)
        btn.Text = label
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = f
        btn.MouseButton1Click:Connect(func)
    end
    
    CreateNumInput(50, "索敌半径", "LockRadius", 10, 100)
    CreateNumInput(95, "追击速度", "ChaseSpeed", 18, 40)
    CreateNumInput(140, "攻击间隔", "AttackDelay", 0.2, 2)
    CreateToggle(185, "AI控制视角", "AIControlCamera")
    CreateToggle(230, "手动攻击模式", "ManualAttack")
    CreateBtn(275, "指定攻击目标", OpenTargetSelect)
    CreateBtn(320, "刷新敌方禁区", function() end)  -- 预留
    CreateBtn(365, "清除建筑范围设置", OpenClearBuildSettings)
    
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0.9,0,0,30)
    statusLbl.Position = UDim2.new(0.05,0,0,410)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "锁定模式: "..AICombatConfig.LockMode.." | 固定目标: "..(AICombatConfig.FixedTarget and AICombatConfig.FixedTarget.Name or "无")
    statusLbl.TextColor3 = Color3.new(0.8,0.8,0.8)
    statusLbl.TextSize = 12
    statusLbl.Parent = f
end

-- ========== 敌方攻击范围物理禁区 ==========
local EnemyAttackSafeZone = {}
local attackZoneLoop = nil

local function UpdateEnemyAttackZone()
    pcall(function()
        local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        for part,_ in pairs(EnemyAttackSafeZone) do
            if part and part:IsDescendantOf(workspace) then
                part:Destroy()
            end
        end
        EnemyAttackSafeZone = {}
        
        for _,p in pairs(game.Players:GetPlayers()) do
            if p == plr or not p.Character or p.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
            local troot = p.Character:FindFirstChild("HumanoidRootPart")
            if not troot then continue end
            
            local zonePart = Instance.new("Part")
            zonePart.Name = "EnemyAttackSafeZone_"..p.UserId
            zonePart.Shape = Enum.PartType.Ball
            zonePart.Size = Vector3.new(4.2,4.2,4.2)
            zonePart.Position = troot.Position
            zonePart.BrickColor = BrickColor.new("Bright red")
            zonePart.Transparency = 0.3
            zonePart.CanCollide = true
            zonePart.CanQuery = false
            zonePart.Anchored = true
            zonePart.Parent = workspace
            table.insert(EnemyAttackSafeZone, zonePart)
            
            game.RunService.Heartbeat:Connect(function()
                if zonePart and zonePart:IsDescendantOf(workspace) and p.Character then
                    zonePart.Position = p.Character.HumanoidRootPart.Position
                end
            end)
        end
    end)
end

local function StartAttackZone()
    pcall(function()
        for part,_ in pairs(EnemyAttackSafeZone) do
            if part then part:Destroy() end
        end
        EnemyAttackSafeZone = {}
        if attackZoneLoop then attackZoneLoop:Disconnect() end
        attackZoneLoop = game.RunService.Heartbeat:Connect(UpdateEnemyAttackZone)
    end)
end

local function StopAttackZone()
    pcall(function()
        if attackZoneLoop then attackZoneLoop:Disconnect() end
        for part,_ in pairs(EnemyAttackSafeZone) do
            if part then part:Destroy() end
        end
        EnemyAttackSafeZone = {}
    end)
end

-- 自动启动禁区
StartAttackZone()

-- ========== 全局移动逻辑强制优化 ==========
local GlobalMoveConfig = {
    Enabled = true,
    MoveSpeed = 28,
    JumpPower = 50,
    Smoothness = 0.1
}

local function ApplyGlobalMoveLogic()
    pcall(function()
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        hum.WalkSpeed = GlobalMoveConfig.MoveSpeed
        hum.JumpPower = GlobalMoveConfig.JumpPower
        hum.AutoRotate = false
        
        game.RunService.RenderStepped:Connect(function(dt)
            if not GlobalMoveConfig.Enabled or not plr.Character or hum.Health <= 0 then return end
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            local input = game:GetService("UserInputService")
            local moveDir = Vector3.new(0,0,0)
            if input:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if input:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,1) end
            if input:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if input:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
                local camCFrame = game.Workspace.CurrentCamera.CFrame
                local forward = Vector3.new(camCFrame.LookVector.X,0,camCFrame.LookVector.Z).Unit
                local right = Vector3.new(camCFrame.RightVector.X,0,camCFrame.RightVector.Z).Unit
                local finalDir = (forward * moveDir.Z + right * moveDir.X).Unit
                root.CFrame = CFrame.new(root.Position + finalDir * GlobalMoveConfig.MoveSpeed * GlobalMoveConfig.Smoothness * dt)
            end
        end)
    end)
end

ApplyGlobalMoveLogic()

-- ========== AI抓后摇 + 极限卡距攻防逻辑 ==========
local EnemyCombatState = {}
local function MonitorEnemyAttack(target)
    if not target or not target.Character then return false, 0, 2 end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    local root = target.Character.HumanoidRootPart
    if not hum or not root then return false, 0, 2 end

    local key = target.UserId
    if not EnemyCombatState[key] then
        EnemyCombatState[key] = {
            LastAttackAnim = 0,
            LastAnimTime = 0,
            IsAttacking = false,
            WeaponRange = 2
        }
    end
    local state = EnemyCombatState[key]

    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("attack") or track.Name:lower():find("swing") then
            state.IsAttacking = true
            state.LastAttackAnim = tick()
            break
        else
            state.IsAttacking = false
        end
    end

    state.LastAnimTime = tick() - state.LastAttackAnim
    return state.IsAttacking, state.LastAnimTime, state.WeaponRange + AICombatConfig.SafeOffset
end

-- 将AI抓后摇整合进主循环（已通过心跳实现，无需额外添加）

-- ========== 连传距离设置 + 玩家传送页修复 ==========
local function OpenFollowDistanceConfig()
    pcall(function()
        for _,v in pairs(game.CoreGui:GetChildren()) do if v.Name=="FollowSet" then v:Destroy() end end
        local sg = Instance.new("ScreenGui")
        sg.Name = "FollowSet"
        sg.Parent = game.CoreGui
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,260,0,160)
        f.Position = UDim2.new(0.5,-130,0.5,-80)
        f.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
        f.Parent = sg

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,0,0,30)
        title.BackgroundTransparency = 1
        title.Text = "传送身后距离"
        title.TextColor3 = Color3.new(1,1,1)
        title.Parent = f

        local tip = Instance.new("TextLabel")
        tip.Size = UDim2.new(1,0,0,20)
        tip.Position = UDim2.new(0,0,0,30)
        tip.BackgroundTransparency = 1
        tip.Text = "0=紧贴 1=贴身 2=1身位"
        tip.TextColor3 = Color3.new(0.7,0.7,0.7)
        tip.TextSize = 12
        tip.Parent = f

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.8,0,0,40)
        input.Position = UDim2.new(0.1,0,0,55)
        input.BackgroundColor3 = Color3.new(0.2,0.2,0.25)
        input.TextColor3 = Color3.new(1,1,1)
        input.Text = tostring(FollowDistance)
        input.Parent = f

        local ok = Instance.new("TextButton")
        ok.Size = UDim2.new(0.8,0,0,40)
        ok.Position = UDim2.new(0.1,0,0,105)
        ok.BackgroundColor3 = Color3.new(0,0.6,0)
        ok.Text = "确定"
        ok.TextColor3 = Color3.new(1,1,1)
        ok.Parent = f

        ok.MouseButton1Click:Connect(function()
            local val = tonumber(input.Text)
            if val then FollowDistance = math.clamp(val,0,10) end
            sg:Destroy()
        end)
    end)
end

-- 玩家传送列表实时刷新
local function RefreshPlayerList(frame)
    for _,c in pairs(frame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local y = 0
    for _,p in pairs(game.Players:GetPlayers()) do
        if p == plr then continue end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,35)
        btn.Position = UDim2.new(0,0,0,y)
        btn.BackgroundColor3 = Color3.new(0.2,0.2,0.25)
        btn.Text = p.Name
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = frame
        y += 40

        btn.MouseButton1Click:Connect(function()
            if not p.Character then return end
            local troot = p.Character.HumanoidRootPart
            local dir = (troot.CFrame.LookVector * -1) * FollowDistance
            plr.Character.HumanoidRootPart.CFrame = troot.CFrame * CFrame.new(dir.X,0,dir.Z)
        end)
    end
    frame.CanvasSize = UDim2.new(0,0,0,y)
end

-- ========== 玩家传送窗口（修复版） ==========
local loopTeleportConnection = nil
local loopTeleportUI = nil

local function OpenPlayerTeleportWindow()
    pcall(function() if CoreGui:FindFirstChild("PlayerTeleportWindow") then CoreGui.PlayerTeleportWindow:Destroy() end end)
    pcall(function() if loopTeleportUI then loopTeleportUI:Destroy() end end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "PlayerTeleportWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,300,0,450)
    main.Position = UDim2.new(0.5,-150,0.5,-225)
    main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    main.Parent = sg
    MakeFrameDraggable(main, main)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-100,1,0)
    title.Position = UDim2.new(0,10,0,0)
    title.BackgroundTransparency = 1
    title.Text = "玩家传送"
    title.TextColor3 = Config.TextWhite
    title.TextSize = 18
    title.Parent = top

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0,60,0,32)
    refreshBtn.Position = UDim2.new(1,-120,0,4)
    refreshBtn.BackgroundColor3 = Config.BtnBlue
    refreshBtn.Text = "刷新"
    refreshBtn.TextColor3 = Color3.new(1,1,1)
    refreshBtn.Parent = top

    local settingBtn = Instance.new("TextButton")
    settingBtn.Size = UDim2.new(0,60,0,32)
    settingBtn.Position = UDim2.new(1,-55,0,4)
    settingBtn.BackgroundColor3 = Config.BtnOrange
    settingBtn.Text = "设置"
    settingBtn.TextColor3 = Color3.new(1,1,1)
    settingBtn.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-40,0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,0.2,0.2)
    closeBtn.TextSize = 24
    closeBtn.Parent = top
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-20,1,-50)
    scroll.Position = UDim2.new(0,10,0,45)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main

    local function Refresh()
        RefreshPlayerList(scroll)
    end

    refreshBtn.MouseButton1Click:Connect(Refresh)
    settingBtn.MouseButton1Click:Connect(OpenFollowDistanceConfig)

    Refresh()
end

-- 坐标传送窗口（保留）
local function OpenPositionTeleportWindow()
    pcall(function() if CoreGui:FindFirstChild("PositionTeleportWindow") then CoreGui.PositionTeleportWindow:Destroy() end end)
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "PositionTeleportWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 350, 0, 450)
    main.Position = UDim2.new(0.5, -175, 0.5, -225)
    main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    main.Parent = sg
    MakeFrameDraggable(main, main)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-120,1,0)
    title.Position = UDim2.new(0,10,0,0)
    title.BackgroundTransparency = 1
    title.Text = "坐标传送"
    title.TextColor3 = Config.TextWhite
    title.TextSize = 18
    title.Parent = top

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,40,0,40)
    minBtn.Position = UDim2.new(1,-80,0,0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Config.TextWhite
    minBtn.TextSize = 24
    minBtn.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-40,0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,0.2,0.2)
    closeBtn.TextSize = 24
    closeBtn.Parent = top

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-20,1,-50)
    content.Position = UDim2.new(0,10,0,45)
    content.BackgroundTransparency = 1
    content.Parent = main

    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(1,0,0,40)
    addBtn.Position = UDim2.new(0,0,0,0)
    addBtn.BackgroundColor3 = Config.BtnGreen
    addBtn.Text = "添加当前位置"
    addBtn.TextColor3 = Config.TextWhite
    addBtn.TextSize = 16
    addBtn.Parent = content
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0,5)
    addCorner.Parent = addBtn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-50)
    scroll.Position = UDim2.new(0,0,0,50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll

    local isMin = false
    local oldSize, oldPos = main.Size, main.Position

    local function Refresh()
        for _,c in pairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for i, posData in ipairs(TeleportConfig.SavedPositions) do
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1,0,0,40)
            f.BackgroundTransparency = 1
            f.LayoutOrder = i
            f.Parent = scroll

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(0.4,0,1,0)
            name.Position = UDim2.new(0,10,0,0)
            name.BackgroundTransparency = 1
            name.Text = posData.Name
            name.TextColor3 = Config.TextWhite
            name.TextSize = 14
            name.Parent = f

            local pos = Instance.new("TextLabel")
            pos.Size = UDim2.new(0.3,0,1,0)
            pos.Position = UDim2.new(0.4,0,0,0)
            pos.BackgroundTransparency = 1
            pos.Text = string.format("%.1f,%.1f,%.1f", posData.Position.X, posData.Position.Y, posData.Position.Z)
            pos.TextColor3 = Color3.new(0.7,0.7,0.7)
            pos.TextSize = 11
            pos.Parent = f

            local tp = Instance.new("TextButton")
            tp.Size = UDim2.new(0.25,0,0,35)
            tp.Position = UDim2.new(0.73,0,0,2.5)
            tp.BackgroundColor3 = Config.BtnBlue
            tp.Text = "传送"
            tp.TextColor3 = Config.TextWhite
            tp.TextSize = 14
            tp.Parent = f
            local tpc = Instance.new("UICorner")
            tpc.CornerRadius = UDim.new(0,5)
            tpc.Parent = tp

            tp.MouseButton1Click:Connect(function()
                pcall(function()
                    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then root.CFrame = CFrame.new(posData.Position) end
                end)
            end)
        end
    end

    addBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                table.insert(TeleportConfig.SavedPositions, {
                    Name = "点位"..#TeleportConfig.SavedPositions+1,
                    Position = pos,
                })
                Refresh()
            end
        end)
    end)

    minBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then
            oldSize, oldPos = main.Size, main.Position
            main.Size = UDim2.new(0,100,0,40)
            main.Position = UDim2.new(0,oldPos.X.Offset,0,oldPos.Y.Offset)
            content.Visible = false
            title.Text = "坐标"
        else
            main.Size = oldSize
            main.Position = oldPos
            content.Visible = true
            title.Text = "坐标传送"
        end
    end)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    Refresh()
end

local function OpenTeleportMainWindow()
    pcall(function() if CoreGui:FindFirstChild("TeleportMainWindow") then CoreGui.TeleportMainWindow:Destroy() end end)
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "TeleportMainWindow"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,300,0,200)
    main.Position = UDim2.new(0.5,-150,0.5,-100)
    main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    main.Parent = sg
    MakeFrameDraggable(main, main)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-50,1,0)
    title.Position = UDim2.new(0,15,0,0)
    title.BackgroundTransparency = 1
    title.Text = "瞬移功能"
    title.TextColor3 = Config.TextWhite
    title.TextSize = 18
    title.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-40,0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,0.2,0.2)
    closeBtn.TextSize = 24
    closeBtn.Parent = top
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local posBtn = Instance.new("TextButton")
    posBtn.Size = UDim2.new(0.9,0,0,50)
    posBtn.Position = UDim2.new(0.05,0,0,50)
    posBtn.BackgroundColor3 = Config.BtnBlue
    posBtn.Text = "坐标传送"
    posBtn.TextColor3 = Config.TextWhite
    posBtn.TextSize = 17
    posBtn.Parent = main
    local posCorner = Instance.new("UICorner")
    posCorner.CornerRadius = UDim.new(0,5)
    posCorner.Parent = posBtn

    local playerBtn = Instance.new("TextButton")
    playerBtn.Size = UDim2.new(0.9,0,0,50)
    playerBtn.Position = UDim2.new(0.05,0,0,110)
    playerBtn.BackgroundColor3 = Config.BtnPurple
    playerBtn.Text = "玩家传送"
    playerBtn.TextColor3 = Config.TextWhite
    playerBtn.TextSize = 17
    playerBtn.Parent = main
    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0,5)
    playerCorner.Parent = playerBtn

    posBtn.MouseButton1Click:Connect(function()
        OpenPositionTeleportWindow()
        sg:Destroy()
    end)
    playerBtn.MouseButton1Click:Connect(function()
        OpenPlayerTeleportWindow()
        sg:Destroy()
    end)
end

-- 透视ESP
local function ClearESP()
    for _, drawing in pairs(ESPDrawings) do
        pcall(function() drawing:Destroy() end)
    end
    ESPDrawings = {}
end

local function UpdateESP()
    ClearESP()
    if not ESPConfig.Enabled then return end

    local currentCamera = Workspace.CurrentCamera
    if not currentCamera then return end
    local myChar = plr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, enemy in pairs(Players:GetPlayers()) do
        if enemy == plr then continue end
        if ESPConfig.TeamCheck and not PlayerLockList[enemy.UserId] then continue end
        
        local enemyChar = enemy.Character
        local enemyHum = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
        local enemyHead = enemyChar and enemyChar:FindFirstChild("Head")
        if not enemyChar or not enemyHum or not enemyRoot or enemyHum.Health <= 0 then continue end
        
        local dist = (myRoot.Position - enemyRoot.Position).Magnitude
        if dist > ESPConfig.MaxDistance then continue end

        local rootPos, rootOnScreen = currentCamera:WorldToViewportPoint(enemyRoot.Position)
        local headPos, headOnScreen = currentCamera:WorldToViewportPoint(enemyHead and enemyHead.Position or enemyRoot.Position + Vector3.new(0, 2, 0))
        local footPos, footOnScreen = currentCamera:WorldToViewportPoint(enemyRoot.Position - Vector3.new(0, 3, 0))
        
        local shouldDraw = rootOnScreen or ESPConfig.InsideWall
        if not shouldDraw then continue end

        if ESPConfig.BoxESP then
            local boxTopY = math.min(headPos.Y, footPos.Y)
            local boxBottomY = math.max(headPos.Y, footPos.Y)
            local boxHeight = boxBottomY - boxTopY
            local boxWidth = boxHeight * 0.6

            local espGui = CoreGui:FindFirstChild("ESPGui")
            if not espGui then return end

            local box = Instance.new("Frame")
            box.Name = "ESPBox_"..enemy.UserId
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
            box.Position = UDim2.new(0, rootPos.X - boxWidth/2, 0, boxTopY)
            box.Parent = espGui
            table.insert(ESPDrawings, box)

            local boxStroke = Instance.new("UIStroke")
            if ESPConfig.FullBodyRed then
                boxStroke.Color = Color3.new(1, 0, 0)
            else
                boxStroke.Color = ESPConfig.BoxColor
            end
            boxStroke.Thickness = 2
            boxStroke.Parent = box
            table.insert(ESPDrawings, boxStroke)
        end

        if ESPConfig.NameESP then
            local espGui = CoreGui:FindFirstChild("ESPGui")
            if not espGui then return end

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "ESPName_"..enemy.UserId
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(0, 200, 0, 20)
            nameLabel.Position = UDim2.new(0, rootPos.X - 100, 0, headPos.Y - 25)
            nameLabel.Text = enemy.Name
            nameLabel.TextColor3 = ESPConfig.NameColor
            nameLabel.TextSize = ESPConfig.NameSize
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.Parent = espGui
            table.insert(ESPDrawings, nameLabel)
        end

        if ESPConfig.HealthESP then
            local espGui = CoreGui:FindFirstChild("ESPGui")
            if not espGui then return end

            local maxHealth = enemyHum.MaxHealth
            local currentHealth = enemyHum.Health
            local healthPercent = currentHealth / maxHealth
            local boxWidth = (headPos.Y - footPos.Y) * 0.6

            local healthBarBg = Instance.new("Frame")
            healthBarBg.Name = "ESPHealthBg_"..enemy.UserId
            healthBarBg.BackgroundColor3 = Color3.new(0, 0, 0)
            healthBarBg.BorderSizePixel = 0
            healthBarBg.Size = UDim2.new(0, 4, 0, (headPos.Y - footPos.Y))
            healthBarBg.Position = UDim2.new(0, rootPos.X - (boxWidth/2 + 8), 0, footPos.Y)
            healthBarBg.Parent = espGui
            table.insert(ESPDrawings, healthBarBg)

            local healthBar = Instance.new("Frame")
            healthBar.Name = "ESPHealth_"..enemy.UserId
            healthBar.BackgroundColor3 = ESPConfig.HealthColorFull:Lerp(ESPConfig.HealthColorLow, 1 - healthPercent)
            healthBar.BorderSizePixel = 0
            healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
            healthBar.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
            healthBar.Parent = healthBarBg
            table.insert(ESPDrawings, healthBar)

            local healthText = Instance.new("TextLabel")
            healthText.Name = "ESPHealthText_"..enemy.UserId
            healthText.BackgroundTransparency = 1
            healthText.Size = UDim2.new(0, 50, 0, 15)
            healthText.Position = UDim2.new(0, rootPos.X - (boxWidth/2 + 35), 0, footPos.Y + (headPos.Y - footPos.Y)*0.5 - 7)
            healthText.Text = math.floor(currentHealth).."/"..math.floor(maxHealth)
            healthText.TextColor3 = Color3.new(1,1,1)
            healthText.TextSize = 11
            healthText.TextStrokeTransparency = 0.5
            healthText.TextXAlignment = Enum.TextXAlignment.Right
            healthText.Parent = espGui
            table.insert(ESPDrawings, healthText)
        end

        if ESPConfig.AntennaESP and not rootOnScreen then
            local espGui = CoreGui:FindFirstChild("ESPGui")
            if not espGui then return end

            local screenCenter = Vector2.new(currentCamera.ViewportSize.X/2, currentCamera.ViewportSize.Y/2)
            local direction = (Vector2.new(rootPos.X, rootPos.Y) - screenCenter).Unit
            local screenEdge = screenCenter + direction * math.min(currentCamera.ViewportSize.X, currentCamera.ViewportSize.Y) * 0.45

            local antennaLine = Instance.new("Frame")
            antennaLine.Name = "ESPAntenna_"..enemy.UserId
            antennaLine.BackgroundColor3 = ESPConfig.AntennaColor
            antennaLine.BorderSizePixel = 0
            antennaLine.Size = UDim2.new(0, 2, 0, 30)
            antennaLine.Position = UDim2.new(0, screenEdge.X - 1, 0, screenEdge.Y - 15)
            antennaLine.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
            antennaLine.Parent = espGui
            table.insert(ESPDrawings, antennaLine)

            local antennaName = Instance.new("TextLabel")
            antennaName.Name = "ESPAntennaName_"..enemy.UserId
            antennaName.BackgroundTransparency = 1
            antennaName.Size = UDim2.new(0, 100, 0, 20)
            antennaName.Position = UDim2.new(0, screenEdge.X - 50, 0, screenEdge.Y + 20)
            antennaName.Text = enemy.Name.." ["..math.floor(dist).."m]"
            antennaName.TextColor3 = ESPConfig.AntennaColor
            antennaName.TextSize = 12
            antennaName.TextStrokeTransparency = 0.5
            antennaName.TextXAlignment = Enum.TextXAlignment.Center
            antennaName.Parent = espGui
            table.insert(ESPDrawings, antennaName)
        end
    end
end

local function StartESP()
    ESPConfig.Enabled = true
    local espGui = CoreGui:FindFirstChild("ESPGui")
    if not espGui then
        espGui = Instance.new("ScreenGui")
        espGui.Name = "ESPGui"
        espGui.Parent = CoreGui
        espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        espGui.ResetOnSpawn = false
        espGui.IgnoreGuiInset = true
    end

    ESPLoop = RunService.Heartbeat:Connect(function()
        if not ESPConfig.Enabled then return end
        pcall(UpdateESP)
    end)
    AddLoop(ESPLoop)
end

local function StopESP()
    ESPConfig.Enabled = false
    ClearESP()
    local espGui = CoreGui:FindFirstChild("ESPGui")
    if espGui then
        espGui:Destroy()
    end
    if ESPLoop then
        ESPLoop:Disconnect()
        ESPLoop = nil
    end
end

local function OpenESPSettings()
    pcall(function() if CoreGui:FindFirstChild("ESPSettings") then CoreGui.ESPSettings:Destroy() end end)
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "ESPSettings"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,350,0,600)
    main.Position = UDim2.new(0.5,-175,0.5,-300)
    main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
    main.Parent = sg
    MakeFrameDraggable(main, main)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,40)
    top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
    top.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-50,1,0)
    title.Position = UDim2.new(0,15,0,0)
    title.BackgroundTransparency = 1
    title.Text = "透视ESP设置"
    title.TextColor3 = Config.TextWhite
    title.TextSize = 18
    title.Parent = top

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-40,0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,0.2,0.2)
    closeBtn.TextSize = 24
    closeBtn.Parent = top
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-20,1,-50)
    scroll.Position = UDim2.new(0,10,0,45)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,12)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll

    local function Title(t, o)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.95,0,0,25)
        f.BackgroundTransparency = 1
        f.LayoutOrder = o
        f.Parent = scroll
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = "—— "..t.." ——"
        l.TextColor3 = Color3.fromRGB(200,200,100)
        l.TextSize = 14
        l.Parent = f
    end

    local function Toggle(t, k, o)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.95,0,0,40)
        f.BackgroundTransparency = 1
        f.LayoutOrder = o
        f.Parent = scroll

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.65,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = t
        l.TextColor3 = Config.TextWhite
        l.TextSize = 15
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3,0,0,35)
        btn.Position = UDim2.new(0.7,0,0,2.5)
        btn.BackgroundColor3 = ESPConfig[k] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
        btn.Text = ESPConfig[k] and "开启" or "关闭"
        btn.TextColor3 = Config.TextWhite
        btn.TextSize = 14
        btn.Parent = f
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,5)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            ESPConfig[k] = not ESPConfig[k]
            btn.BackgroundColor3 = ESPConfig[k] and Color3.new(0,0.6,0) or Color3.new(0.3,0.3,0.3)
            btn.Text = ESPConfig[k] and "开启" or "关闭"
        end)
    end

    local function Num(t, k, mi, ma, o)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.95,0,0,40)
        f.BackgroundTransparency = 1
        f.LayoutOrder = o
        f.Parent = scroll

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.45,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = t
        l.TextColor3 = Config.TextWhite
        l.TextSize = 15
        l.Parent = f

        local i = Instance.new("TextBox")
        i.Size = UDim2.new(0.2,0,0,35)
        i.Position = UDim2.new(0.47,0,0,2.5)
        i.BackgroundColor3 = Config.InputBg
        i.Text = tostring(ESPConfig[k])
        i.TextColor3 = Config.TextWhite
        i.Parent = f
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,5)
        c.Parent = i

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.25,0,0,35)
        b.Position = UDim2.new(0.7,0,0,2.5)
        b.BackgroundColor3 = Config.BtnBlue
        b.Text = "确定"
        b.TextColor3 = Config.TextWhite
        b.Parent = f
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0,5)
        cc.Parent = b

        b.MouseButton1Click:Connect(function()
            local n = tonumber(i.Text)
            if n then
                ESPConfig[k] = math.clamp(n, mi, ma)
                i.Text = tostring(ESPConfig[k])
            end
        end)
    end

    Title("基础", 0)
    Toggle("白名单过滤", "TeamCheck", 1)
    Toggle("穿墙内透", "InsideWall", 2)
    Toggle("全身红模式", "FullBodyRed", 3)
    Num("名字大小", "NameSize", 8, 30, 4)
    Num("最大距离", "MaxDistance", 10, 5000, 5)

    Title("透视功能", 10)
    Toggle("名字", "NameESP", 11)
    Toggle("方框", "BoxESP", 12)
    Toggle("血量", "HealthESP", 13)
    Toggle("天线", "AntennaESP", 14)
end

-- 视角切换按钮（已修复）
local function CreateCameraSwitchButton()
    pcall(function()
        if CoreGui:FindFirstChild("CameraSwitchBtn") then
            CoreGui.CameraSwitchBtn:Destroy()
        end
    end)
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CameraSwitchBtn"
    sg.Parent = CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,60,0,60)
    btn.Position = UDim2.new(0.5,-30,0.85,0)
    btn.BackgroundColor3 = Color3.new(0.1,0.1,0.12)
    btn.Text = "视角"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize =14
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1,0)
    corner.Parent = btn

    local isDragging = false
    local dragStart, btnStart
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            btnStart = btn.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not isDragging then return end
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(0, btnStart.X.Offset + delta.X, 0, btnStart.Y.Offset + delta.Y)
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    btn.MouseButton1Click:Connect(function()
        local char = plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local cam = Workspace.CurrentCamera
        if not cam or not hum then return end
        
        CameraState.IsFirstPerson = not CameraState.IsFirstPerson
        if CameraState.IsFirstPerson then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
            hum.CameraOffset = Vector3.new(0,0,0)
        else
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
            hum.CameraOffset = Vector3.new(0,0,-10)
        end
    end)
end

-- ========== 主UI框架 ==========
local mainSg = Instance.new("ScreenGui")
mainSg.Name = "LegendFixMenu"
mainSg.Parent = CoreGui
mainSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainSg.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0.78, 0, 0.82, 0)
mainFrame.Position = UDim2.new(0.11, 0, 0.09, 0)
mainFrame.BackgroundColor3 = Config.MainBg
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.new(0.3,0.3,0.35)
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainSg

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, -100, 0, 40)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Config.TabBarBg
topBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -20, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "全能娱乐脚本"
titleText.TextColor3 = Config.TextWhite
titleText.TextSize = 18
titleText.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 50, 0, 40)
minBtn.Position = UDim2.new(1, -100, 0, 0)
minBtn.BackgroundColor3 = Config.BtnNormal
minBtn.Text = "-"
minBtn.TextColor3 = Config.TextWhite
minBtn.TextSize = 24
minBtn.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 50, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 0)
closeBtn.BackgroundColor3 = Config.BtnRed
closeBtn.Text = "×"
closeBtn.TextColor3 = Config.TextWhite
closeBtn.TextSize = 24
closeBtn.Parent = mainFrame

local floatBall = Instance.new("TextButton")
floatBall.Name = "FloatBall"
floatBall.Size = UDim2.new(0, 60, 0, 60)
floatBall.Position = UDim2.new(0, 60, 0, 60)
floatBall.BackgroundColor3 = Color3.new(0.1,0.1,0.12)
floatBall.BorderSizePixel = 2
floatBall.BorderColor3 = Color3.new(0.2,0.3,0.55)
floatBall.Visible = false
floatBall.Text = "菜单"
floatBall.TextColor3 = Config.TextWhite
floatBall.TextSize = 14
floatBall.Parent = mainSg
floatBall.AutoButtonColor = false

local isDragging = false
local dragStartPos = Vector2.new(0,0)
local ballStartPos = UDim2.new(0,0,0,0)

floatBall.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = UIS:GetMouseLocation()
        ballStartPos = floatBall.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not isDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local currentPos = UIS:GetMouseLocation()
        local delta = currentPos - dragStartPos
        local newX = ballStartPos.X.Offset + delta.X
        local newY = ballStartPos.Y.Offset + delta.Y
        newX = math.clamp(newX, 0, camera.ViewportSize.X - 60)
        newY = math.clamp(newY, 0, camera.ViewportSize.Y - 60)
        floatBall.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

floatBall.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    floatBall.Visible = false
end)
minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatBall.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    ClearAllLoops()
    StopEnemyShield()
    StopAutoAimTurn()
    StopBodyAim()
    StopAICombat()
    StopMoveOptimize()
    StopESP()
    StopGraphicsOptimize()
    StopClearBuildings()
    StopAttackZone()
    if loopTeleportConnection then
        loopTeleportConnection:Disconnect()
        loopTeleportConnection = nil
    end
    if loopTeleportUI then
        loopTeleportUI:Destroy()
        loopTeleportUI = nil
    end
    pcall(function()
        CoreGui.AimTurnSettings:Destroy()
        CoreGui.ShieldSettings:Destroy()
        CoreGui.ItemListWindow:Destroy()
        CoreGui.ItemSettingWindow:Destroy()
        CoreGui.HeldItemEditorWindow:Destroy()
        CoreGui.PlayerLockWindow:Destroy()
        CoreGui.ESPSettings:Destroy()
        CoreGui.TeleportMainWindow:Destroy()
        CoreGui.PositionTeleportWindow:Destroy()
        CoreGui.PlayerTeleportWindow:Destroy()
    end)
    mainSg:Destroy()
end)

local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabBar"
tabFrame.Size = UDim2.new(0, 140, 1, -40)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Config.TabBarBg
tabFrame.Parent = mainFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentArea"
contentFrame.Size = UDim2.new(1, -140, 1, -40)
contentFrame.Position = UDim2.new(0, 140, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 6
contentFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = contentFrame
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
end)

local function ClearContent()
    for _, v in pairs(contentFrame:GetChildren()) do
        if v ~= listLayout then v:Destroy() end
    end
end
local function CreateTitle(text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.96,0,0,35)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.Text = "—— "..text.." ——"
    t.TextColor3 = Config.TextWhite
    t.TextSize = 18
    t.Parent = f
end
local function CreateSwitchBtn(text, getState, onEnable, onDisable)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.96,0,0,50)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    local enabled = getState()
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = enabled and Config.BtnRed or Config.BtnPurple
    btn.Text = enabled and "关闭 "..text or "开启 "..text
    btn.TextColor3 = Config.TextWhite
    btn.TextSize = 17
    btn.Parent = f
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and Config.BtnRed or Config.BtnPurple
        btn.Text = enabled and "关闭 "..text or "开启 "..text
        if enabled then pcall(onEnable) else pcall(onDisable) ClearAllLoops() end
    end)
end
local function CreateFuncBtn(text, color, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.96,0,0,50)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Config.TextWhite
    btn.TextSize = 17
    btn.Parent = f
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
end
local function CreateSwitchWithSetting(text, getState, onEnable, onDisable, onSettingClick, windowName)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.96,0,0,50)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    local enabled = getState()
    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(0.73,0,1,0)
    switchBtn.Position = UDim2.new(0,0,0,0)
    switchBtn.BackgroundColor3 = enabled and Config.BtnRed or Config.BtnPurple
    switchBtn.Text = enabled and "关闭 "..text or "开启 "..text
    switchBtn.TextColor3 = Config.TextWhite
    switchBtn.TextSize = 17
    switchBtn.Parent = f
    local settingBtn = Instance.new("TextButton")
    settingBtn.Size = UDim2.new(0.25,0,1,0)
    settingBtn.Position = UDim2.new(0.75,0,0,0)
    settingBtn.BackgroundColor3 = Config.BtnBlue
    settingBtn.Text = "设置"
    settingBtn.TextColor3 = Config.TextWhite
    settingBtn.TextSize = 15
    settingBtn.Parent = f
    switchBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        switchBtn.BackgroundColor3 = enabled and Config.BtnRed or Config.BtnPurple
        switchBtn.Text = enabled and "关闭 "..text or "开启 "..text
        if enabled then pcall(onEnable) else pcall(onDisable) ClearAllLoops() end
    end)
    settingBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if windowName then
                local existWindow = CoreGui:FindFirstChild(windowName)
                if existWindow then existWindow:Destroy(); return end
            end
            onSettingClick()
        end)
    end)
end

local function ShowNormalPage()
    ClearContent()
    CreateTitle("飞行功能")
    CreateFuncBtn("启动原版飞行脚本", Config.BtnBlue, RunOriginalFly)
    CreateTitle("核心功能")
    CreateSwitchBtn("穿墙模式", function() return GlobalState.WallHack end, StartWallHack, StopWallHack)
    CreateSwitchBtn("全亮夜视", function() return GlobalState.NightVision end, StartNightVision, StopNightVision)
    CreateTitle("角色属性")
    CreateFuncBtn("速度/跳跃/重力", Config.BtnGreen, function()
        pcall(function() if CoreGui:FindFirstChild("CharSetting") then CoreGui.CharSetting:Destroy() end end)
        local sg = Instance.new("ScreenGui")
        sg.Name = "CharSetting"
        sg.Parent = CoreGui
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0,350,0,300)
        main.Position = UDim2.new(0.5,-175,0.5,-150)
        main.BackgroundColor3 = Color3.new(0.12,0.12,0.15)
        main.Parent = sg
        MakeFrameDraggable(main, main)

        local top = Instance.new("Frame")
        top.Size = UDim2.new(1,0,0,40)
        top.BackgroundColor3 = Color3.new(0.08,0.08,0.1)
        top.Parent = main
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,-50,1,0)
        title.Position = UDim2.new(0,10,0,0)
        title.BackgroundTransparency = 1
        title.Text = "角色设置"
        title.TextColor3 = Config.TextWhite
        title.TextSize = 18
        title.Parent = top
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0,40,0,40)
        closeBtn.Position = UDim2.new(1,-40,0,0)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.new(1,0.2,0.2)
        closeBtn.TextSize = 24
        closeBtn.Parent = top
        closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

        local function SetItem(y, t, default, cb)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(0,100,0,35)
            l.Position = UDim2.new(0,20,0,y)
            l.BackgroundTransparency = 1
            l.Text = t
            l.TextColor3 = Config.TextWhite
            l.TextSize = 16
            l.Parent = main

            local i = Instance.new("TextBox")
            i.Size = UDim2.new(0,150,0,35)
            i.Position = UDim2.new(0,130,0,y)
            i.BackgroundColor3 = Config.InputBg
            i.Text = tostring(default)
            i.TextColor3 = Config.TextWhite
            i.Parent = main
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0,5)
            c.Parent = i

            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0,60,0,35)
            b.Position = UDim2.new(0,280,0,y)
            b.BackgroundColor3 = Config.BtnBlue
            b.Text = "设置"
            b.TextColor3 = Config.TextWhite
            b.Parent = main
            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(0,5)
            cc.Parent = b

            b.MouseButton1Click:Connect(function()
                local v = tonumber(i.Text)
                if v then cb(v) end
            end)
        end

        SetItem(60, "移动速度", 16, function(v)
            pcall(function()
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end)
        end)

        SetItem(110, "跳跃高度", 50, function(v)
            pcall(function()
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end)
        end)

        SetItem(160, "重力", 1, function(v)
            pcall(function()
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.GravityScale = v end
            end)
        end)
    end)
end

local function ShowCombatPage()
    ClearContent()
    CreateTitle("战斗核心功能")
    CreateSwitchBtn("自动攻击（拿武器就打）", function() return GlobalState.AutoAttack end, StartAutoAttack, StopAutoAttack)
    CreateSwitchWithSetting("视角自瞄", function() return GlobalState.AutoAimTurn end, StartAutoAimTurn, StopAutoAimTurn, OpenAimTurnSettings, "AimTurnSettings")
    CreateSwitchWithSetting("玩家透视ESP", function() return ESPConfig.Enabled end, StartESP, StopESP, OpenESPSettings, "ESPSettings")
    CreateSwitchWithSetting("AI全自动战斗", function() return AICombatConfig.Enabled end, StartAICombat, StopAICombat, OpenAISettings, "AISet")
end

local function ShowFunPage()
    ClearContent()
    CreateTitle("道具功能")
    CreateFuncBtn("全服务器道具获取", Config.BtnOrange, OpenItemListWindow)
    CreateTitle("核心功能")
    CreateFuncBtn("瞬移功能", Config.BtnPurple, OpenTeleportMainWindow)
    CreateSwitchBtn("无延迟移动优化", function() return MoveOptimizeConfig.Enabled end, StartMoveOptimize, StopMoveOptimize)
    CreateSwitchWithSetting("身体自瞄", function() return GlobalState.BodyAim end, StartBodyAim, StopBodyAim, OpenBodyAimSettings, "BodyAimSettings")
    CreateTitle("隔离功能")
    CreateSwitchWithSetting("隔离敌人（自动推开）", function() return GlobalState.EnemyShield end, StartEnemyShield, StopEnemyShield, OpenShieldSettings, "ShieldSettings")
    CreateTitle("视角切换")
    CreateFuncBtn("开启视角切换按钮", Config.BtnOrange, CreateCameraSwitchButton)
    CreateTitle("画质优化")
    CreateSwitchBtn("画质优化（纯白删贴图）", function() return GraphicsOptimizeConfig.Enabled end, StartGraphicsOptimize, StopGraphicsOptimize)
    CreateSwitchBtn("清除建筑物", function() return ClearBuildConfig.Enabled end, StartClearBuildings, StopClearBuildings)
    CreateTitle("配置管理")
    CreateFuncBtn("保存当前所有配置", Config.BtnGreen, SaveAllConfig)
    CreateFuncBtn("载入上次保存配置", Config.BtnBlue, LoadAllConfig)
end

local tabButtons = {}
local function AddTab(text, y, func)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-10,0,42)
    btn.Position = UDim2.new(0,5,0,y)
    btn.BackgroundColor3 = Config.TabNormal
    btn.Text = text
    btn.TextColor3 = Config.TextWhite
    btn.TextSize = 16
    btn.Parent = tabFrame
    btn.MouseButton1Click:Connect(function()
        for _,b in pairs(tabButtons) do b.BackgroundColor3 = Config.TabNormal end
        btn.BackgroundColor3 = Config.TabActive
        ClearAllLoops()
        func()
    end)
    table.insert(tabButtons, btn)
end

AddTab("通用功能",10,ShowNormalPage)
AddTab("战斗功能",60,ShowCombatPage)
AddTab("娱乐搞怪",110,ShowFunPage)

tabButtons[1].BackgroundColor3 = Config.TabActive
ShowNormalPage()

mainSg.Destroying:Connect(function()
    ClearAllLoops()
    StopEnemyShield()
    StopAutoAimTurn()
    StopBodyAim()
    StopAICombat()
    StopMoveOptimize()
    StopESP()
    StopGraphicsOptimize()
    StopClearBuildings()
    StopAttackZone()
    if loopTeleportConnection then
        loopTeleportConnection:Disconnect()
        loopTeleportConnection = nil
    end
    if loopTeleportUI then
        loopTeleportUI:Destroy()
        loopTeleportUI = nil
    end
    pcall(function()
        CoreGui.AimTurnSettings:Destroy()
        CoreGui.ShieldSettings:Destroy()
        CoreGui.ItemListWindow:Destroy()
        CoreGui.ItemSettingWindow:Destroy()
        CoreGui.HeldItemEditorWindow:Destroy()
        CoreGui.PlayerLockWindow:Destroy()
        CoreGui.ESPSettings:Destroy()
        CoreGui.TeleportMainWindow:Destroy()
        CoreGui.PositionTeleportWindow:Destroy()
        CoreGui.PlayerTeleportWindow:Destroy()
    end)
end)

plr.CharacterAdded:Connect(function()
    task.wait(0.5)
end)

-- 初始化玩家锁定列表
RefreshPlayerLockList()