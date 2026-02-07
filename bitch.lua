repeat task.wait() until game:IsLoaded()
--why
local function isAdonisAC(tab) 
    return rawget(tab,"Detected") and typeof(rawget(tab,"Detected"))=="function" and rawget(tab,"RLocked") 
end
for _,v in next,getgc(true) do 
    if typeof(v)=="table" and isAdonisAC(v) then 
        for i,f in next,v do 
            if rawequal(i,"Detected") then 
                local old 
                old=hookfunction(f,function(action,info,crash)
                    if rawequal(action,"_") and rawequal(info,"_") and rawequal(crash,false) then 
                        return old(action,info,crash) 
                    end 
                    return task.wait(9e9) 
                end) 
                warn("bypassed") 
                break 
            end 
        end 
    end 
end

for _,v in pairs(getgc(true)) do 
    if type(v)=="table" then 
        local func=rawget(v,"DTXC1") 
        if type(func)=="function" then 
            hookfunction(func,function() return end) 
            break 
        end 
    end 
end

getgenv().CONFIG={
    Ragebot={
        Enabled=false,RapidFire=false,FireRate=30,Prediction=true,
        PredictionAmount=0.12,TeamCheck=false,VisibilityCheck=true,
        FOV=9e9,ShowFOV=false,Wallbang=true,Tracers=true,
        TracerColor=Color3.fromRGB(255,0,0),TracerWidth=1,
        TracerLifetime=3,ShootRange=15,HitRange=15,
        HitNotify=true,AutoReload=true,HitSound=true,
        HitColor=Color3.fromRGB(255,182,193),UseTargetList=true,
        UseWhitelist=true,HitNotifyDuration=5,LowHealthCheck=false,
        SelectedHitSound="skeet",FriendCheck=false,MaxTarget=0
    }
}

getgenv().Lists={
    TargetList={},
    Whitelist={}
}

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

local screenHeight = workspace.CurrentCamera.ViewportSize.Y
local windowHeight = (screenHeight < 400) and 350 or 605

local function Register_Font(Name, Weight, Style, Asset)
    if not isfile(Asset.Id) then
        writefile(Asset.Id, Asset.Font)
    end

    if isfile(Name .. ".font") then
        delfile(Name .. ".font")
    end

    local Data = {
        name = Name,
        faces = {
            {
                name = "Normal",
                weight = Weight,
                style = Style,
                assetId = getcustomasset(Asset.Id),
            },
        },
    }
    writefile(Name .. ".font", HttpService:JSONEncode(Data))

    return getcustomasset(Name .. ".font")
end

local mainFont
if getcustomasset then
    local ProggyTiny = Register_Font("ProggyTinyFont", 100, "Normal", {
        Id = "ProggyTiny.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyTiny.ttf"),
    })
    mainFont = Font.new(ProggyTiny, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local Library, Notifications, themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/helloxyzcodervisuals/bbotv3mobile/refs/heads/main/bbotv3mobile.lua"))()

local Window = Library:Window({
    name = "gamesense.cc",
    size = UDim2.new(0, 455, 0, windowHeight)
})

local Tabs = {
    Combat = Window:Tab({Name = "Ragebot"}),
    Misc = Window:Tab({Name = "Misc"})
}

local RagebotTab = Tabs.Combat
local MiscTab = Tabs.Misc

local instantReloadConnections={}
local characterAddedConnection
local cachedBestPositions={history={},target=nil}
local lastShotTime=0
local hitNotifications={}
local notificationYOffset=5
local MAX_VISIBLE_NOTIFICATIONS=15

local function getCurrentTool()
    if LocalPlayer.Character then 
        for _,tool in pairs(LocalPlayer.Character:GetChildren()) do 
            if tool:IsA("Tool") then 
                return tool 
            end 
        end 
    end
    return nil
end

local function autoReload()
    if not getgenv().CONFIG.Ragebot.AutoReload then
        for _,conn in pairs(instantReloadConnections) do if conn then conn:Disconnect() end end
        instantReloadConnections={}
        if characterAddedConnection then characterAddedConnection:Disconnect() characterAddedConnection=nil end
        return
    end
    local tool=getCurrentTool()
    if not tool then return end
    local values=tool:FindFirstChild("Values")
    if not values then return end
    local ammo=values:FindFirstChild("SERVER_Ammo")
    local storedAmmo=values:FindFirstChild("SERVER_StoredAmmo")
    if not ammo or not storedAmmo then return end
    for _,conn in pairs(instantReloadConnections) do if conn then conn:Disconnect() end end
    instantReloadConnections={}
    if characterAddedConnection then characterAddedConnection:Disconnect() characterAddedConnection=nil end
    local gunR_remote=ReplicatedStorage:WaitForChild("Events"):WaitForChild("GNX_R")
    local me=Players.LocalPlayer
    local function setupToolListeners(toolObj)
        if not toolObj or not toolObj:FindFirstChild("IsGun") then return end
        local values=toolObj:FindFirstChild("Values")
        if not values then return end
        local ammo=values:FindFirstChild("SERVER_Ammo")
        local storedAmmo=values:FindFirstChild("SERVER_StoredAmmo")
        if not ammo or not storedAmmo then return end
        local conn1=storedAmmo:GetPropertyChangedSignal("Value"):Connect(function()
            local currentRagebot=getgenv().CONFIG.Ragebot.AutoReload
            if currentRagebot then gunR_remote:FireServer(tick(),"KLWE89U0",toolObj) end
        end)
        if storedAmmo.Value~=0 then gunR_remote:FireServer(tick(),"KLWE89U0",toolObj) end
        local conn2=ammo:GetPropertyChangedSignal("Value"):Connect(function()
            local currentRagebot=getgenv().CONFIG.Ragebot.AutoReload
            if currentRagebot and storedAmmo.Value~=0 then gunR_remote:FireServer(tick(),"KLWE89U0",toolObj) end
        end)
        table.insert(instantReloadConnections,conn1)
        table.insert(instantReloadConnections,conn2)
    end
    local char=me.Character
    if char then
        local tool=char:FindFirstChildOfClass("Tool")
        if tool then setupToolListeners(tool) end
        local conn3=char.ChildAdded:Connect(function(obj) if obj:IsA("Tool") then setupToolListeners(obj) end end)
        table.insert(instantReloadConnections,conn3)
    end
    characterAddedConnection=me.CharacterAdded:Connect(function(charr)
        repeat task.wait() until charr and charr.Parent
        local conn4=charr.ChildAdded:Connect(function(obj) if obj:IsA("Tool") then setupToolListeners(obj) end end)
        table.insert(instantReloadConnections,conn4)
    end)
end

local function canSeeTarget(targetPart)
    if not getgenv().CONFIG.Ragebot.VisibilityCheck then return true end
    local localHead=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not localHead then return false end
    local raycastParams=RaycastParams.new()
    raycastParams.FilterType=Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances={LocalPlayer.Character}
    local startPos=localHead.Position
    local endPos=targetPart.Position
    local direction=(endPos-startPos)
    local distance=direction.Magnitude
    local raycastResult=Workspace:Raycast(startPos,direction.Unit*distance,raycastParams)
    if raycastResult then
        local hitPart=raycastResult.Instance
        if hitPart and hitPart.CanCollide then
            local model=hitPart:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid=model:FindFirstChild("Humanoid")
                if humanoid then
                    local targetPlayer=Players:GetPlayerFromCharacter(model)
                    if targetPlayer then return true end
                end
            end
            return false
        end
    end
    local secondRaycast=Workspace:Raycast(startPos+direction.Unit*0.5,direction.Unit*(distance-0.5),raycastParams)
    if secondRaycast then
        local hitPart=secondRaycast.Instance
        if hitPart and hitPart.CanCollide then
            local model=hitPart:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid=model:FindFirstChild("Humanoid")
                if humanoid then
                    local targetPlayer=Players:GetPlayerFromCharacter(model)
                    if targetPlayer then return true end
                end
            end
            return false
        end
    end
    return true
end

local function showNotification(message)
    Notifications:Create({
        Name = message,
        LifeTime = 3
    })
end

local function createHitNotification(toolName, offsetValue, playerName)
    if not getgenv().CONFIG.Ragebot.HitNotify then return end
    
    local targetPlayer = game:GetService("Players"):FindFirstChild(playerName)
    local health = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") and math.floor(targetPlayer.Character.Humanoid.Health) or 0
    
    local message = "Hit " .. playerName .. " on head, Health: " .. tostring(health) .. ", Offset: " .. string.format("%.2f", offsetValue)
    showNotification(message)
end

local function playHitSound()
    if not getgenv().CONFIG.Ragebot.HitSound then return end
    local soundIds={
        ["Bameware"]="rbxassetid://3124331820",
        ["Bell"]="rbxassetid://6534947240",
        ["Bubble"]="rbxassetid://6534947588",
        ["Pick"]="rbxassetid://1347140027",
        ["Pop"]="rbxassetid://198598793",
        ["Rust"]="rbxassetid://1255040462",
        ["Sans"]="rbxassetid://3188795283",
        ["Fart"]="rbxassetid://130833677",
        ["Big"]="rbxassetid://5332005053",
        ["Vine"]="rbxassetid://5332680810",
        ["Bruh"]="rbxassetid://4578740568",
        ["Skeet"]="rbxassetid://5633695679",
        ["Neverlose"]="rbxassetid://6534948092",
        ["Fatality"]="rbxassetid://6534947869",
        ["Bonk"]="rbxassetid://5766898159",
        ["Minecraft"]="rbxassetid://4018616850"
    }
    local soundId=soundIds[getgenv().CONFIG.Ragebot.SelectedHitSound]or soundIds["Skeet"]
    local sound=Instance.new("Sound")
    sound.SoundId=soundId
    sound.Volume=0.75
    sound.Parent=Workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound,0.75)
end

local function fuzzyFindPlayer(name)
    if not name or name == "" then return nil end
    
    local lowerName = name:lower()
    local possiblePlayers = {}
    
    for _,player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local playerName = player.Name:lower()
        if playerName:find(lowerName) then
            table.insert(possiblePlayers, player)
        elseif player.DisplayName:lower():find(lowerName) then
            table.insert(possiblePlayers, player)
        end
    end
    
    if #possiblePlayers == 1 then
        return possiblePlayers[1]
    elseif #possiblePlayers > 1 then
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _,player in pairs(possiblePlayers) do
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                local localHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                if head and localHead then
                    local distance = (head.Position - localHead.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
        
        return closestPlayer
    end
    
    return nil
end

local function getClosestTarget()
    local closest=nil
    local shortestDistance=math.huge
    local targetCount=0
    
    if getgenv().CONFIG.Ragebot.FriendCheck then
        for _,player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
                local found = false
                for _,wlName in ipairs(getgenv().Lists.Whitelist) do
                    if wlName == player.Name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(getgenv().Lists.Whitelist, player.Name)
                end
            end
        end
    end
    
    for _,player in pairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        
        if getgenv().CONFIG.Ragebot.UseWhitelist then
            local isWhitelisted = false
            for _,wlName in ipairs(getgenv().Lists.Whitelist) do
                if wlName ~= "" and (wlName == player.Name or fuzzyFindPlayer(wlName) == player) then
                    isWhitelisted = true
                    break
                end
            end
            if isWhitelisted then continue end
        end
        
        if getgenv().CONFIG.Ragebot.UseTargetList then
            local isTarget = false
            for _,targetName in ipairs(getgenv().Lists.TargetList) do
                if targetName ~= "" and (targetName == player.Name or fuzzyFindPlayer(targetName) == player) then
                    isTarget = true
                    break
                end
            end
            if not isTarget then continue end
        end
        
        if getgenv().CONFIG.Ragebot.TeamCheck and player.Team==LocalPlayer.Team then continue end
        local character=player.Character
        if character then
            local humanoid=character:FindFirstChild("Humanoid")
            local head=character:FindFirstChild("Head")
            if humanoid and humanoid.Health>0 and head then
                local hasForcefield=false
                for _,child in pairs(character:GetChildren()) do if child:IsA("ForceField") then hasForcefield=true break end end
                if hasForcefield then continue end
                if getgenv().CONFIG.Ragebot.LowHealthCheck and humanoid.Health<15 then continue end
                local distance=(head.Position-LocalPlayer.Character.Head.Position).Magnitude
                if getgenv().CONFIG.Ragebot.MaxTarget>0 then targetCount=targetCount+1 if targetCount>getgenv().CONFIG.Ragebot.MaxTarget then break end end
                if distance<shortestDistance then if canSeeTarget(head) then closest=head shortestDistance=distance end end
            end
        end
    end
    return closest
end

local function checkClearPath(startPos,endPos)
    local raycastParams=RaycastParams.new()
    raycastParams.FilterType=Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances={LocalPlayer.Character}
    local direction=(endPos-startPos)
    local distance=direction.Magnitude
    local raycastResult=Workspace:Raycast(startPos,direction.Unit*distance,raycastParams)
    if raycastResult then
        local hitPart=raycastResult.Instance
        if hitPart and hitPart.CanCollide then
            local model=hitPart:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid=model:FindFirstChild("Humanoid")
                if not humanoid then return false end
            else return false end
        end
    end
    return true
end

local function wallbang()
    local localHead=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not localHead then return nil end
    local target=getClosestTarget()
    if not target then cachedBestPositions.history={} cachedBestPositions.target=nil return nil,nil end
    local startPos=localHead.Position
    local targetPos=target.Position
    if not getgenv().CONFIG.Ragebot.Wallbang then return startPos,targetPos end
    local raycastParams=RaycastParams.new()
    raycastParams.FilterType=Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances={LocalPlayer.Character}
    local direction=targetPos-startPos
    local distance=direction.Magnitude
    local directRay=Workspace:Raycast(startPos,direction.Unit*distance,raycastParams)
    if not directRay then return startPos,targetPos end
    if cachedBestPositions.target~=target then cachedBestPositions.history={} cachedBestPositions.target=target end
    if#cachedBestPositions.history>0 then
        local stillValid={}
        for i=1,#cachedBestPositions.history do
            local cache=cachedBestPositions.history[i]
            local cachedShootDistance=(cache.shootPos-startPos).Magnitude
            local cachedHitDistance=(cache.hitPos-targetPos).Magnitude
            if cachedShootDistance<=getgenv().CONFIG.Ragebot.ShootRange and cachedHitDistance<=getgenv().CONFIG.Ragebot.HitRange then
                if checkClearPath(startPos,cache.shootPos) and checkClearPath(cache.shootPos,cache.hitPos) then
                    local shootToHitRay=Workspace:Raycast(cache.shootPos,(cache.hitPos-cache.shootPos).Unit*(cache.hitPos-cache.shootPos).Magnitude,raycastParams)
                    if not shootToHitRay then table.insert(stillValid,cache) end
                end
            end
        end
        cachedBestPositions.history=stillValid
        if#cachedBestPositions.history>0 then local selected=cachedBestPositions.history[math.random(1,#cachedBestPositions.history)] return selected.shootPos,selected.hitPos end
    end
    local validPoints={}
    for i=1,100 do
        local shootOffset=Vector3.new(math.random(-getgenv().CONFIG.Ragebot.ShootRange,getgenv().CONFIG.Ragebot.ShootRange),math.random(-getgenv().CONFIG.Ragebot.ShootRange,getgenv().CONFIG.Ragebot.ShootRange),math.random(-getgenv().CONFIG.Ragebot.ShootRange,getgenv().CONFIG.Ragebot.ShootRange))
        local shootPos=startPos+shootOffset
        local hitOffset=Vector3.new(math.random(-getgenv().CONFIG.Ragebot.HitRange,getgenv().CONFIG.Ragebot.HitRange),math.random(-getgenv().CONFIG.Ragebot.HitRange,getgenv().CONFIG.Ragebot.HitRange),math.random(-getgenv().CONFIG.Ragebot.HitRange,getgenv().CONFIG.Ragebot.HitRange))
        local hitPos=targetPos+hitOffset
        if(shootPos-startPos).Magnitude<=getgenv().CONFIG.Ragebot.ShootRange and(hitPos-targetPos).Magnitude<=getgenv().CONFIG.Ragebot.HitRange then
            if checkClearPath(startPos,shootPos) and checkClearPath(shootPos,hitPos) then
                local shootToHitRay=Workspace:Raycast(shootPos,(hitPos-shootPos).Unit*(hitPos-shootPos).Magnitude,raycastParams)
                if not shootToHitRay then table.insert(validPoints,{shootPos=shootPos,hitPos=hitPos,score=(shootPos-startPos).Magnitude+(hitPos-targetPos).Magnitude}) end
            end
        end
    end
    if#validPoints>0 then
        table.sort(validPoints,function(a,b) return a.score<b.score end)
        local maxCache=math.random(90,100)
        for i=1,math.min(#validPoints,maxCache) do table.insert(cachedBestPositions.history,validPoints[i]) end
        return validPoints[1].shootPos,validPoints[1].hitPos
    end
    local randomY=math.random(-16,-14)
    local fallbackShootPos=Vector3.new(startPos.X,randomY,startPos.Z)
    local fallbackHitPos=Vector3.new(targetPos.X,randomY,targetPos.Z)
    return fallbackShootPos,fallbackHitPos
end

local function createTracer(startPos,endPos)
    if not getgenv().CONFIG.Ragebot.Tracers then return end
    local tracerModel=Instance.new("Model")
    tracerModel.Name="TracerBeam"
    local beam=Instance.new("Beam")
    beam.Color=ColorSequence.new(getgenv().CONFIG.Ragebot.TracerColor)
    beam.Width0=getgenv().CONFIG.Ragebot.TracerWidth
    beam.Width1=getgenv().CONFIG.Ragebot.TracerWidth
    beam.Texture="rbxassetid://7136858729"
    beam.TextureSpeed=1
    beam.Brightness=2
    beam.LightEmission=2
    beam.FaceCamera=true
    local a0=Instance.new("Attachment")
    local a1=Instance.new("Attachment")
    a0.WorldPosition=startPos
    a1.WorldPosition=endPos
    beam.Attachment0=a0
    beam.Attachment1=a1
    beam.Parent=tracerModel
    a0.Parent=tracerModel
    a1.Parent=tracerModel
    tracerModel.Parent=Workspace
    local tweenInfo=TweenInfo.new(getgenv().CONFIG.Ragebot.TracerLifetime,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
    local tween=TweenService:Create(beam,tweenInfo,{Brightness=0})
    tween:Play()
    tween.Completed:Connect(function() if tracerModel then tracerModel:Destroy() end end)
end

local function RandomString(length)
    local charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result=""
    for i=1,length do result=result..charset:sub(math.random(1,#charset),math.random(1,#charset)) end
    return result
end

local function shootAtTarget(targetHead)
    if not targetHead then return false end
    local localHead=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not localHead then return false end
    local tool=getCurrentTool()
    if not tool then return false end
    local values=tool:FindFirstChild("Values")
    local hitMarker=tool:FindFirstChild("Hitmarker")
    if not values or not hitMarker then return false end
    local ammo=values:FindFirstChild("SERVER_Ammo")
    local storedAmmo=values:FindFirstChild("SERVER_StoredAmmo")
    if not ammo or not storedAmmo then return false end
    if ammo.Value<=0 then autoReload() return false end
    local bestShootPos,bestHitPos=wallbang()
    if not bestShootPos or not bestHitPos then return false end
    local hitPosition=bestHitPos
    if getgenv().CONFIG.Ragebot.Prediction then local velocity=targetHead.Velocity or Vector3.zero hitPosition=hitPosition+velocity*getgenv().CONFIG.Ragebot.PredictionAmount end
    local hitDirection=(hitPosition-bestShootPos).Unit
    local randomKey=RandomString(30).."0"
    local args1={tick(),randomKey,tool,"FDS9I83",bestShootPos,{hitDirection},false}
    local args2={"🧈",tool,randomKey,1,targetHead,hitPosition,hitDirection}
    local events=ReplicatedStorage:WaitForChild("Events")
    local GNX_S=events:WaitForChild("GNX_S")
    local ZFKLF__H=events:WaitForChild("ZFKLF__H")
    local targetPlayer=Players:GetPlayerFromCharacter(targetHead.Parent)
    if targetPlayer then 
        createHitNotification(tool.Name,(bestShootPos-localHead.Position).Magnitude,targetPlayer.Name) 
        playHitSound() 
    end
    GNX_S:FireServer(unpack(args1))
    ZFKLF__H:FireServer(unpack(args2))
    hitMarker:Fire(targetHead)
    storedAmmo.Value=storedAmmo.Value
    createTracer(bestShootPos,hitPosition)
    return true
end

coroutine.wrap(function()
    while true do
        if not getgenv().CONFIG.Ragebot.Enabled then task.wait(0.001) else
            if not LocalPlayer.Character then task.wait(0.001) else
                if not LocalPlayer.Character:FindFirstChild("Head") then task.wait(0.001) else
                    local target=getClosestTarget()
                    local waitTimeValue=0.01
                    if target then
                        local currentTime=tick()
                        local WaitTime=1/(getgenv().CONFIG.Ragebot.FireRate*1)
                        if getgenv().CONFIG.Ragebot.RapidFire then
                            local rapidWaitTime=0
                            if currentTime-lastShotTime>=rapidWaitTime then shootAtTarget(target) lastShotTime=currentTime end
                            waitTimeValue=0
                        else
                            if currentTime-lastShotTime>=WaitTime then shootAtTarget(target) lastShotTime=currentTime end
                            waitTimeValue=WaitTime/2
                        end
                    end
                    task.wait(waitTimeValue)
                end
            end
        end
    end
end)()

local MainSection = RagebotTab:Section({Name = "Main", Side = "Left"})
local AimSection = RagebotTab:Section({Name = "Aim Settings", Side = "Right"})
local VisualSection = RagebotTab:Section({Name = "Visuals", Side = "Left"})
local TargetSection = RagebotTab:Section({Name = "Targeting", Side = "Right"})
local MiscMainSection = MiscTab:Section({Name = "Target Lists", Side = "Left"})
local MiscToolsSection = MiscTab:Section({Name = "Tools", Side = "Right"})

local EnableToggle = MainSection:Toggle({Name = "Enable Ragebot", Default = false, Callback = function(value)
    getgenv().CONFIG.Ragebot.Enabled = value
end})
EnableToggle:Keybind({Name = "Keybind", ShowInList = true})

MainSection:Toggle({Name = "Rapid Fire", Default = false, Callback = function(value)
    getgenv().CONFIG.Ragebot.RapidFire = value
end})

MainSection:Toggle({Name = "Auto Reload", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.AutoReload = value
    autoReload()
end})

MainSection:Slider({Name = "Fire Rate", Default = 30, Min = 1, Max = 100, Callback = function(value)
    getgenv().CONFIG.Ragebot.FireRate = value
end})

TargetSection:Toggle({Name = "Team Check", Default = false, Callback = function(value)
    getgenv().CONFIG.Ragebot.TeamCheck = value
end})

TargetSection:Toggle({Name = "Visibility Check", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.VisibilityCheck = value
end})

TargetSection:Toggle({Name = "Wallbang", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.Wallbang = value
end})

TargetSection:Toggle({Name = "Friend Check", Default = false, Callback = function(value)
    getgenv().CONFIG.Ragebot.FriendCheck = value
end})

TargetSection:Toggle({Name = "Low Health Check", Default = false, Callback = function(value)
    getgenv().CONFIG.Ragebot.LowHealthCheck = value
end})

AimSection:Toggle({Name = "Prediction", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.Prediction = value
end})

AimSection:Slider({Name = "Prediction Amount", Default = 0.12, Min = 0.05, Max = 0.3, Callback = function(value)
    getgenv().CONFIG.Ragebot.PredictionAmount = value
end})

AimSection:Slider({Name = "Shoot Range", Default = 15, Min = 1, Max = 30, Callback = function(value)
    getgenv().CONFIG.Ragebot.ShootRange = value
end})

AimSection:Slider({Name = "Hit Range", Default = 15, Min = 1, Max = 30, Callback = function(value)
    getgenv().CONFIG.Ragebot.HitRange = value
end})

AimSection:Slider({Name = "Max Targets", Default = 0, Min = 0, Max = 10, Callback = function(value)
    getgenv().CONFIG.Ragebot.MaxTarget = value
end})

local TracersToggle = VisualSection:Toggle({Name = "Tracers", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.Tracers = value
end})
TracersToggle:Colorpicker({Name = "Tracer Color", Default = Color3.fromRGB(255,0,0), Callback = function(color)
    getgenv().CONFIG.Ragebot.TracerColor = color
end})

VisualSection:Slider({Name = "Tracer Width", Default = 1, Min = 0.1, Max = 5, Callback = function(value)
    getgenv().CONFIG.Ragebot.TracerWidth = value
end})

VisualSection:Slider({Name = "Tracer Lifetime", Default = 3, Min = 0.5, Max = 10, Callback = function(value)
    getgenv().CONFIG.Ragebot.TracerLifetime = value
end})

local HitNotifyToggle = VisualSection:Toggle({Name = "Hit Notify", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.HitNotify = value
end})
HitNotifyToggle:Colorpicker({Name = "Hit Color", Default = Color3.fromRGB(255,182,193), Callback = function(color)
    getgenv().CONFIG.Ragebot.HitColor = color
end})

VisualSection:Toggle({Name = "Hit Sound", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.HitSound = value
end})

local hitSoundOptions = {
    "Skeet",
    "Neverlose",
    "Fatality",
    "Bameware",
    "Bell",
    "Bubble",
    "Pick",
    "Pop",
    "Rust",
    "Sans",
    "Fart",
    "Big",
    "Vine",
    "Bruh",
    "Bonk",
    "Minecraft"
}

VisualSection:Dropdown({Name = "Hit Sound Select", Default = "Skeet", Options = hitSoundOptions, Callback = function(value)
    getgenv().CONFIG.Ragebot.SelectedHitSound = value
end})

VisualSection:Slider({Name = "Hit Notify Duration", Default = 5, Min = 1, Max = 10, Callback = function(value)
    getgenv().CONFIG.Ragebot.HitNotifyDuration = value
end})

TargetSection:Toggle({Name = "Use Target List", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.UseTargetList = value
end})

TargetSection:Toggle({Name = "Use Whitelist", Default = true, Callback = function(value)
    getgenv().CONFIG.Ragebot.UseWhitelist = value
end})

local targetTextBox = MiscMainSection:Textbox({
    Name = "Add Player to Target List",
    Default = "PlayerName",
    Callback = function(value)
        if value and value ~= "" then
            table.insert(getgenv().Lists.TargetList, value)
            showNotification("Added " .. value .. " to Target List")
        end
    end
})

local whitelistTextBox = MiscMainSection:Textbox({
    Name = "Add Player to Whitelist",
    Default = "PlayerName",
    Callback = function(value)
        if value and value ~= "" then
            table.insert(getgenv().Lists.Whitelist, value)
            showNotification("Added " .. value .. " to Whitelist")
        end
    end
})

MiscMainSection:Button({Name = "Add Closest to Target List", Callback = function()
    local target = getClosestTarget()
    if target then
        local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
        if targetPlayer then
            table.insert(getgenv().Lists.TargetList, targetPlayer.Name)
            showNotification("Added " .. targetPlayer.Name .. " to Target List")
        end
    end
end})

MiscMainSection:Button({Name = "Add Closest to Whitelist", Callback = function()
    local target = getClosestTarget()
    if target then
        local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
        if targetPlayer then
            table.insert(getgenv().Lists.Whitelist, targetPlayer.Name)
            showNotification("Added " .. targetPlayer.Name .. " to Whitelist")
        end
    end
end})

MiscToolsSection:Button({Name = "Add All Friends to Whitelist", Callback = function()
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
            local found = false
            for _,wlName in ipairs(getgenv().Lists.Whitelist) do
                if wlName == player.Name then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(getgenv().Lists.Whitelist, player.Name)
                count = count + 1
            end
        end
    end
    showNotification("Added " .. count .. " friends to Whitelist")
end})

MiscToolsSection:Button({Name = "Clear Whitelist", Callback = function()
    getgenv().Lists.Whitelist = {}
    showNotification("Whitelist cleared")
end})

MiscToolsSection:Button({Name = "Clear Target List", Callback = function()
    getgenv().Lists.TargetList = {}
    showNotification("Target List cleared")
end})

MiscToolsSection:Button({Name = "Print Target List", Callback = function()
    print("=== Target List ===")
    for i, name in ipairs(getgenv().Lists.TargetList) do
        print(i .. ". " .. name)
    end
    print("==================")
end})

MiscToolsSection:Button({Name = "Print Whitelist", Callback = function()
    print("=== Whitelist ===")
    for i, name in ipairs(getgenv().Lists.Whitelist) do
        print(i .. ". " .. name)
    end
    print("=================")
end})
Window.ToggleKeybindList(false)
Window.ToggleStatus(false)
Window.ChangeTitle("bitchsense.cc")
-- Config Functions
Library:Configs(Window)
local MiscTab = Window:Tab({Name = "Misc"})
local VisualTab = Window:Tab({Name = "Visual"})

local speedEnabled = false
local speedValue = 50
local speedConnection = nil
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local noclipEnabled = false
local noclipConnection = nil
local jumpPowerEnabled = false
local jumpPowerValue = 100
local jumpPowerConnection = nil
local loopFOVEnabled = false
local fovConnection = nil
local hideHeadEnabled = false
local char = nil
local torso = nil
local originalMotor6Ds = {}
local renderConnection = nil
local originalHook = nil
local infStaminaEnabled = false
local infStaminaHook = nil
local noFallEnabled = false
local noFallHook = nil
local lockpickEnabled = false
local lockpickAddedConnection = nil
local instantPromptEnabled = false
local instantPromptConnection = nil
local autoDoorEnabled = false
local doorConnection = nil
local safeESPEnabled = false
local safeColor = Color3.fromRGB(255,215,0)
local bulletTracersEnabled = false
local tracerColor = Color3.fromRGB(255,50,50)
local tracerWidth = 0.2
local tracerLifetime = 1
local SafeESP = {Enabled = false,Safes = {},Visuals = {}}

local QuickUIFrame = Instance.new("Frame")
QuickUIFrame.Name = "QuickUIFrame"
QuickUIFrame.Size = UDim2.new(0,80,0,30)
QuickUIFrame.Position = UDim2.new(0,10,0,50)
QuickUIFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
QuickUIFrame.BackgroundTransparency = 0.5
QuickUIFrame.BorderSizePixel = 0
local QuickUIText = Instance.new("TextButton")
QuickUIText.Name = "QuickUIText"
QuickUIText.Size = UDim2.new(1,0,1,0)
QuickUIText.BackgroundTransparency = 1
QuickUIText.Text = "FLY OFF"
QuickUIText.TextColor3 = Color3.fromRGB(255,50,50)
QuickUIText.Font = Enum.Font.GothamBold
QuickUIText.TextSize = 12
QuickUIText.Parent = QuickUIFrame
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuickUIScreen"
ScreenGui.Parent = game:GetService("CoreGui")
QuickUIFrame.Parent = ScreenGui

local function enableSpeed()
    if speedConnection then speedConnection:Disconnect() speedConnection = nil end
    speedConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid.WalkSpeed = speedValue
    end)
end

local function disableSpeed()
    if speedConnection then speedConnection:Disconnect() speedConnection = nil end
    local character = LocalPlayer.Character
    if character then local humanoid = character:FindFirstChild("Humanoid") if humanoid then humanoid.WalkSpeed = 16 end end
end

local function startFlying()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root then return end
    local RagdollEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("__RZDONL")
    RagdollEvent:FireServer("__---r",Vector3.zero,CFrame.new(-4574,3,-443,0,0,1,0,1,0,-1,0,0),false)
    for _,child in ipairs(Char:GetDescendants()) do if child:IsA("Motor6D") then child.Enabled = false end end
    Hum.PlatformStand = true
    Hum:ChangeState(Enum.HumanoidStateType.Freefall)
    local flyMotors = {}
    for _,part in ipairs(Char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= Root then
            local motor = Instance.new("Motor6D")
            motor.Name = "FlyMotor"
            motor.Part0 = Root
            motor.Part1 = part
            motor.C1 = CFrame.new()
            motor.C0 = Root.CFrame:ToObjectSpace(part.CFrame)
            motor.Parent = part
            table.insert(flyMotors,motor)
        end
    end
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled then
            if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            Hum.PlatformStand = false
            Root.Velocity = Vector3.new(0,0,0)
            Hum:ChangeState(Enum.HumanoidStateType.Running)
            RagdollEvent:FireServer("__---r",Vector3.zero,CFrame.new(-4574,3,-443,0,0,1,0,1,0,-1,0,0),true)
            for _,motor in ipairs(flyMotors) do motor:Destroy() end
            for _,child in ipairs(Char:GetDescendants()) do if child:IsA("Motor6D") and child.Name ~= "FlyMotor" then child.Enabled = true end end
            return
        end
        local Cam = Workspace.CurrentCamera
        if not Cam then return end
        local cameraLook = Cam.CFrame.LookVector
        local IsMoving = Hum.MoveDirection.Magnitude > 0
        local targetLook = Vector3.new(cameraLook.X,cameraLook.Y,cameraLook.Z)
        if targetLook.Magnitude > 0 then targetLook = targetLook.Unit Root.CFrame = CFrame.new(Root.Position,Root.Position+targetLook) end
        if IsMoving then
            local moveVector = Vector3.new(cameraLook.X,cameraLook.Y,cameraLook.Z).Unit
            Root.Velocity = moveVector * flySpeed
            RagdollEvent:FireServer("__---r",Vector3.zero,CFrame.new(-4574,3,-443,0,0,1,0,1,0,-1,0,0),false)
        else Root.Velocity = Vector3.new(0,0,0) end
    end)
end

local function disableFlying()
    flyEnabled = false
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    local character = LocalPlayer.Character
    if not character then return end
    for _,part in pairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled or not character or not character.Parent then stopNoclip() return end
        for _,part in pairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end)
end

local function stopNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    local character = LocalPlayer.Character
    if not character then return end
    for _,part in pairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
end

local function enableJumpPower()
    if jumpPowerConnection then jumpPowerConnection:Disconnect() jumpPowerConnection = nil end
    jumpPowerConnection = RunService.Heartbeat:Connect(function()
        if not jumpPowerEnabled then return end
        if not LocalPlayer.Character then return end
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if humanoid:GetState() == Enum.HumanoidStateType.Jumping then hrp.Velocity = Vector3.new(hrp.Velocity.X,jumpPowerValue,hrp.Velocity.Z) end
    end)
end

local function disableJumpPower()
    if jumpPowerConnection then jumpPowerConnection:Disconnect() jumpPowerConnection = nil end
end

local function enableLoopFOV()
    if fovConnection then fovConnection:Disconnect() fovConnection = nil end
    fovConnection = RunService.RenderStepped:Connect(function() workspace.CurrentCamera.FieldOfView = 120 end)
end

local function disableLoopFOV()
    if fovConnection then fovConnection:Disconnect() fovConnection = nil end
end

local function hideHead()
    if not LocalPlayer.Character then return end
    char = LocalPlayer.Character
    torso = char:FindFirstChild("Torso")
    if not torso then return end
    originalMotor6Ds = {}
    for _,motor in pairs(char:GetDescendants()) do if motor:IsA("Motor6D") then originalMotor6Ds[motor] = {Part0 = motor.Part0,Part1 = motor.Part1,C0 = motor.C0,C1 = motor.C1} end end
    hideHeadEnabled = true
    if not originalHook then
        originalHook = hookmetamethod(game,"__namecall",function(self,...)
            local methodName = getnamecallmethod()
            if tostring(methodName) == "FireServer" then
                if self.Name == "MOVZREP" then local fixedArguments = {{{Vector3.new(-5721.2001953125,-5,971.5162353515625),Vector3.new(-4181.38818359375,-6,11.123311996459961),Vector3.new(0.006237113382667303,-6,-0.18136750161647797),true,true,true,false},false,false,15.8}} return originalHook(self,table.unpack(fixedArguments)) end
            end
            return originalHook(self,...)
        end)
    end
    if renderConnection then renderConnection:Disconnect() end
    renderConnection = RunService.RenderStepped:Connect(function()
        if torso and torso.Parent then
            for motor,originalData in pairs(originalMotor6Ds) do if motor and motor.Parent then motor.C0 = originalData.C0 motor.C1 = originalData.C1 end end
            local neck = torso:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then neck.C0 = CFrame.new(0,0,0.75)*CFrame.Angles(math.rad(90),0,0) neck.C1 = CFrame.new(0,0.25,0)*CFrame.Angles(0,0,0) end
        else if renderConnection then renderConnection:Disconnect() renderConnection = nil end end
    end)
end

local function enableInfStamina()
    if infStaminaHook then return end
    local module
    for i,v in pairs(game:GetService("StarterPlayer").StarterPlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and v.Name == "XIIX" then module = v break end end
    if module then
        module = require(module)
        local ac = module["XIIX"]
        local glob = getfenv(ac)["_G"]
        local stamina = getupvalues((getupvalues(glob["S_Check"]))[2])[1]
        if stamina ~= nil then infStaminaHook = hookfunction(stamina,function() return 100,100 end) end
    end
end

local function disableInfStamina()
    if infStaminaHook then hookfunction(stamina,infStaminaHook) infStaminaHook = nil end
end

local function enableNoFallDmg()
    if noFallHook then return end
    noFallHook = hookmetamethod(game,"__namecall",function(self,...)
        local args = {...}
        if getnamecallmethod() == "FireServer" and not checkcaller() and args[1] == "FlllD" and args[4] == false then args[2] = 0 args[3] = 0 end
        return noFallHook(self,unpack(args))
    end)
end

local function disableNoFallDmg()
    if noFallHook then hookmetamethod(game,"__namecall",noFallHook) noFallHook = nil end
end

local function enableLockpick()
    lockpickEnabled = true
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    local function lockpick(gui)
        for _,a in pairs(gui:GetDescendants()) do
            if a:IsA("ImageLabel") and a.Name == "Bar" and a.Parent.Name ~= "Attempts" then
                local oldsize = a.Size
                RunService.RenderStepped:Connect(function()
                    if lockpickEnabled then a.Size = UDim2.new(0,280,0,280) else a.Size = oldsize end
                end)
            end
        end
    end
    if lockpickAddedConnection then lockpickAddedConnection:Disconnect() end
    lockpickAddedConnection = PlayerGui.ChildAdded:Connect(function(child) if child:IsA("ScreenGui") and child.Name == "LockpickGUI" then lockpick(child) end end)
    for _,child in pairs(PlayerGui:GetChildren()) do if child:IsA("ScreenGui") and child.Name == "LockpickGUI" then lockpick(child) end end
end

local function disableLockpick()
    lockpickEnabled = false
    if lockpickAddedConnection then lockpickAddedConnection:Disconnect() lockpickAddedConnection = nil end
end

local function enableInstantPrompt()
    instantPromptEnabled = true
    for _,obj in pairs(game:GetDescendants()) do if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end end
    if instantPromptConnection then instantPromptConnection:Disconnect() end
    instantPromptConnection = game.DescendantAdded:Connect(function(obj) if obj:IsA("ProximityPrompt") then task.wait() obj.HoldDuration = 0 end end)
end

local function disableInstantPrompt()
    instantPromptEnabled = false
    if instantPromptConnection then instantPromptConnection:Disconnect() instantPromptConnection = nil end
    for _,obj in pairs(game:GetDescendants()) do if obj:IsA("ProximityPrompt") then obj.HoldDuration = 1 end end
end

local function enableAutoDoor()
    autoDoorEnabled = true
    if doorConnection then doorConnection:Disconnect() end
    doorConnection = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then return end
        local charRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not charRoot then return end
        local Map = Workspace:FindFirstChild("Map")
        if not Map then return end
        local Doors = Map:FindFirstChild("Doors")
        if not Doors then return end
        local closestDoor = nil
        local closestDistance = 15
        for _,door in pairs(Doors:GetChildren()) do
            local knob = door:FindFirstChild("Knob1") or door:FindFirstChild("Knob2")
            if knob then
                local distance = (knob.Position - charRoot.Position).Magnitude
                if distance < closestDistance then closestDistance = distance closestDoor = door end
            end
        end
        if closestDoor then
            local knob = closestDoor:FindFirstChild("Knob1") or closestDoor:FindFirstChild("Knob2")
            local events = closestDoor:FindFirstChild("Events")
            local toggleEvent = events and events:FindFirstChild("Toggle")
            if knob and toggleEvent then local args = {"Open",knob} toggleEvent:FireServer(unpack(args)) end
        end
    end)
end

local function disableAutoDoor()
    autoDoorEnabled = false
    if doorConnection then doorConnection:Disconnect() doorConnection = nil end
end

local function addSafeESP(model)
    if not model or not model.Parent then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = safeColor
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255,140,0)
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SafeESP"
    billboard.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    billboard.Size = UDim2.new(0,200,0,50)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = safeColor
    textLabel.TextSize = 14
    textLabel.FontFace = Font.new("rbxassetid://12187371840")
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Text = model.Name
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1,0,0,20)
    distanceLabel.Position = UDim2.new(0,0,0,20)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(200,200,200)
    distanceLabel.TextSize = 12
    distanceLabel.FontFace = Font.new("rbxassetid://12187371840")
    distanceLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = billboard
    distanceLabel.Parent = billboard
    billboard.Parent = model
    SafeESP.Safes[model] = true
    SafeESP.Visuals[model] = {highlight = highlight,billboard = billboard,textLabel = textLabel,distanceLabel = distanceLabel}
    RunService.Heartbeat:Connect(function()
        if not safeESPEnabled or not model.Parent then highlight:Destroy() billboard:Destroy() SafeESP.Safes[model] = nil SafeESP.Visuals[model] = nil return end
        if LocalPlayer and LocalPlayer.Character then
            local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart and billboard.Adornee then local distance = (humanoidRootPart.Position - billboard.Adornee.Position).Magnitude distanceLabel.Text = string.format("%d studs",math.floor(distance)) billboard.Enabled = distance <= 100 end
        end
    end)
end

local function scanWorkspace()
    for _,item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Model") then
            local itemName = item.Name:lower()
            if itemName:find("mediumsafe") or itemName:find("smallsafe") then if not SafeESP.Safes[item] then addSafeESP(item) end end
        end
    end
end

local function updateSafeColor(color)
    safeColor = color
    for model,visuals in pairs(SafeESP.Visuals) do
        if visuals.highlight then visuals.highlight.FillColor = color end
        if visuals.textLabel then visuals.textLabel.TextColor3 = color end
    end
end

local function enableSafeESP(value)
    safeESPEnabled = value
    SafeESP.Enabled = value
    if value then
        scanWorkspace()
        Workspace.DescendantAdded:Connect(function(item)
            if item:IsA("Model") then
                local itemName = item.Name:lower()
                if itemName:find("mediumsafe") or itemName:find("smallsafe") then task.wait(0.1) addSafeESP(item) end
            end
        end)
    else
        for model,visuals in pairs(SafeESP.Visuals) do if visuals.highlight then visuals.highlight:Destroy() end if visuals.billboard then visuals.billboard:Destroy() end end
        SafeESP.Safes = {}
        SafeESP.Visuals = {}
    end
end

local function createTracer(startPos,endPos)
    if not bulletTracersEnabled then return end
    local tracerModel = Instance.new("Model")
    tracerModel.Name = "Tracer"
    local beam = Instance.new("Beam")
    beam.Color = ColorSequence.new(tracerColor)
    beam.Width0 = tracerWidth
    beam.Width1 = tracerWidth
    beam.Texture = "rbxassetid://7136858729"
    beam.TextureSpeed = 1
    beam.Brightness = 2
    beam.LightEmission = 1
    beam.FaceCamera = true
    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")
    a0.WorldPosition = startPos
    a1.WorldPosition = endPos
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Parent = tracerModel
    a0.Parent = tracerModel
    a1.Parent = tracerModel
    tracerModel.Parent = Workspace
    local tweenInfo = TweenInfo.new(tracerLifetime,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
    local tween = TweenService:Create(beam,tweenInfo,{Brightness = 0,Width0 = 0,Width1 = 0})
    tween:Play()
    tween.Completed:Connect(function() if tracerModel then tracerModel:Destroy() end end)
    task.delay(tracerLifetime+0.1,function() if tracerModel and tracerModel.Parent then tracerModel:Destroy() end end)
end

local function trackGlobalBullets()
    if _G.TracersRunning then return end
    _G.TracersRunning = true
    local bfr = Camera:FindFirstChild("Bullets")
    if not bfr then bfr = Instance.new("Folder") bfr.Name = "Bullets" bfr.Parent = Camera end
    local function tblt(blt)
        if not blt:IsA("BasePart") then return end
        local stp = blt.Position
        local lsp = stp
        local stc = 0
        local con
        con = RunService.Heartbeat:Connect(function()
            if not blt or not blt.Parent then
                con:Disconnect()
                if(lsp-stp).Magnitude > 1 then createTracer(stp,lsp) end
                return
            end
            local cp = blt.Position
            if(cp-lsp).Magnitude < 0.1 then
                stc = stc + 1
                if stc > 3 then con:Disconnect() if(cp-stp).Magnitude > 1 then createTracer(stp,cp) end end
            else stc = 0 lsp = cp end
        end)
    end
    bfr.ChildAdded:Connect(tblt)
    for _,v in ipairs(bfr:GetChildren()) do tblt(v) end
end

QuickUIText.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then 
        QuickUIText.Text = "FLY ON" 
        QuickUIText.TextColor3 = Color3.fromRGB(50,255,50) 
        startFlying()
    else 
        QuickUIText.Text = "FLY OFF" 
        QuickUIText.TextColor3 = Color3.fromRGB(255,50,50) 
        disableFlying() 
    end
end)

local MiscMovementSection = MiscTab:Section({Name = "Movement", Side = "Left"})
local MiscToolsSection = MiscTab:Section({Name = "Tools", Side = "Right"})
local MiscListsSection = MiscTab:Section({Name = "Lists", Side = "Left"})
local MiscVisualsSection = MiscTab:Section({Name = "Visuals", Side = "Right"})

local speedToggle = MiscMovementSection:Toggle({Name = "Speed", Default = false, Callback = function(value)
    speedEnabled = value
    if value then enableSpeed() else disableSpeed() end
end})
speedToggle:Keybind({Name = "Keybind", ShowInList = true})
MiscMovementSection:Slider({Name = "Value", Default = 50, Min = 16, Max = 200, Callback = function(value)
    speedValue = value
end})

local flyToggle = MiscMovementSection:Toggle({Name = "Fly", Default = false, Callback = function(value)
    flyEnabled = value
    if value then 
        QuickUIText.Text = "FLY ON" 
        QuickUIText.TextColor3 = Color3.fromRGB(50,255,50) 
        startFlying()
    else 
        QuickUIText.Text = "FLY OFF" 
        QuickUIText.TextColor3 = Color3.fromRGB(255,50,50) 
        disableFlying() 
    end
end})
flyToggle:Keybind({Name = "Keybind", ShowInList = true})
MiscMovementSection:Slider({Name = "Speed", Default = 50, Min = 10, Max = 200, Callback = function(value)
    flySpeed = value
end})

local noclipToggle = MiscMovementSection:Toggle({Name = "Noclip", Default = false, Callback = function(value)
    noclipEnabled = value
    if value then startNoclip() else stopNoclip() end
end})
noclipToggle:Keybind({Name = "Keybind", ShowInList = true})

local jumpToggle = MiscMovementSection:Toggle({Name = "Jump Power", Default = false, Callback = function(value)
    jumpPowerEnabled = value
    if value then enableJumpPower() else disableJumpPower() end
end})
MiscMovementSection:Slider({Name = "Value", Default = 100, Min = 50, Max = 300, Callback = function(value)
    jumpPowerValue = value
end})

local fovToggle = MiscToolsSection:Toggle({Name = "Loop FOV", Default = false, Callback = function(value)
    loopFOVEnabled = value
    if value then enableLoopFOV() else disableLoopFOV() end
end})

local headToggle = MiscToolsSection:Toggle({Name = "Hide Head", Default = false, Callback = function(value)
    hideHeadEnabled = value
    if value then hideHead() end
end})

local staminaToggle = MiscToolsSection:Toggle({Name = "Inf Stamina", Default = false, Callback = function(value)
    infStaminaEnabled = value
    if value then enableInfStamina() else disableInfStamina() end
end})

local fallToggle = MiscToolsSection:Toggle({Name = "No Fall Damage", Default = false, Callback = function(value)
    noFallEnabled = value
    if value then enableNoFallDmg() else disableNoFallDmg() end
end})

local lockpickToggle = MiscToolsSection:Toggle({Name = "No Fail Lockpick", Default = false, Callback = function(value)
    lockpickEnabled = value
    if value then enableLockpick() else disableLockpick() end
end})

local promptToggle = MiscToolsSection:Toggle({Name = "Instant Prompt", Default = false, Callback = function(value)
    instantPromptEnabled = value
    if value then enableInstantPrompt() else disableInstantPrompt() end
end})

local doorToggle = MiscToolsSection:Toggle({Name = "Auto Door", Default = false, Callback = function(value)
    autoDoorEnabled = value
    if value then enableAutoDoor() else disableAutoDoor() end
end})

local safeESPToggle = MiscVisualsSection:Toggle({Name = "Safe ESP", Default = false, Callback = function(value)
    enableSafeESP(value)
end})
safeESPToggle:Keybind({Name = "Keybind", ShowInList = true})
safeESPToggle:Colorpicker({Name = "Color", Default = Color3.fromRGB(255,215,0), Callback = function(color)
    updateSafeColor(color)
end})

local tracerToggle = MiscVisualsSection:Toggle({Name = "Bullet Tracers", Default = false, Callback = function(value)
    bulletTracersEnabled = value
    if value then trackGlobalBullets() end
end})
tracerToggle:Colorpicker({Name = "Color", Default = Color3.fromRGB(255,50,50), Callback = function(color)
    tracerColor = color
end})
MiscVisualsSection:Slider({Name = "Width", Default = 2, Min = 1, Max = 5, Callback = function(value)
    tracerWidth = value/1
end})
MiscVisualsSection:Slider({Name = "Lifetime", Default = 10, Min = 1, Max = 100, Callback = function(value)
    tracerLifetime = value/5
end})

local richShaderEnabled = false
local richColor = Color3.fromRGB(255,200,150)
local richBrightness = 20
local richContrast = 50
local richSaturation = 150
local richPlayerEnabled = false
local richPlayerColor = Color3.fromRGB(255,255,255)
local richPlayerTransparency = 0
local originalPlayerProperties = {}
local originalPlayerMaterials = {}

local espEnabled = true
local espMainColor = Color3.fromRGB(255,50,50)
local espWhitelistColor = Color3.fromRGB(50,255,50)
local espTargetlistColor = Color3.fromRGB(255,50,255)
local espTeamCheck = false
local espShowHealth = true
local espShowDistance = true
local espBoxFilled = true
local espBoxOutline = true
local espBoxAlpha = 3
local espUseWhitelistColor = true
local espUseTargetlistColor = true

local espDrawings = {}
local espUIs = {}
local playerConnections = {}
local espScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
espScreenGui.Name = "Skeet_2D_ESP"
espScreenGui.IgnoreGuiInset = true

local function Register_Font()
    local HttpService = game:GetService("HttpService")
    
    if not isfile("ProggyTiny.ttf") then
        writefile("ProggyTiny.ttf", game:HttpGet("https://raw.githubusercontent.com/i77lhm/storage/refs/heads/main/fonts/ProggyClean.ttf"))
    end
    
    local fontData = {
        name = "ProggyTinyFont",
        faces = {{
            name = "Normal",
            weight = 400,
            style = "normal",
            assetId = getcustomasset("ProggyTiny.ttf")
        }}
    }
    
    writefile("ProggyTiny.font", HttpService:JSONEncode(fontData))
    return getcustomasset("ProggyTiny.font")
end

local mainFont = Font.new(Register_Font(), Enum.FontWeight.Regular, Enum.FontStyle.Normal)

local function getPlayerColor(player)
    if espUseTargetlistColor then
        for _,targetName in ipairs(getgenv().Lists.TargetList) do
            if targetName == player.Name then
                return espTargetlistColor
            end
        end
    end
    
    if espUseWhitelistColor then
        for _,wlName in ipairs(getgenv().Lists.Whitelist) do
            if wlName == player.Name then
                return espWhitelistColor
            end
        end
    end
    
    return espMainColor
end

local function createESP(player)
    if player == LocalPlayer then return end
    
    local drawings = {
        box_out = Drawing.new("Square"),
        box = Drawing.new("Square"),
        box_fill = Drawing.new("Square")
    }
    
    local uis = {
        health_bg = Instance.new("Frame", espScreenGui),
        health_fill = Instance.new("Frame"),
        name_text = Instance.new("TextLabel", espScreenGui),
        info_text = Instance.new("TextLabel", espScreenGui)
    }

    uis.health_fill.Parent = uis.health_bg
    uis.health_fill.BorderSizePixel = 0
    uis.health_bg.BorderSizePixel = 0
    uis.health_bg.BackgroundColor3 = Color3.new(0, 0, 0)
    
    local gradient = Instance.new("UIGradient", uis.health_fill)
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 1, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
    })

    drawings.box_fill.Transparency = 1
    drawings.box_fill.Filled = true
    drawings.box_fill.Thickness = 0

    local function setupText(textLabel)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.FontFace = mainFont
        textLabel.TextSize = 10
        textLabel.TextStrokeTransparency = 0
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
    end
    
    setupText(uis.name_text)
    setupText(uis.info_text)
    uis.info_text.TextXAlignment = Enum.TextXAlignment.Left
    uis.info_text.TextYAlignment = Enum.TextYAlignment.Top
    
    espDrawings[player] = drawings
    espUIs[player] = uis

    playerConnections[player] = RunService.RenderStepped:Connect(function()
        if not espEnabled then
            drawings.box_out.Visible = false
            drawings.box.Visible = false
            drawings.box_fill.Visible = false
            uis.health_bg.Visible = false
            uis.name_text.Visible = false
            uis.info_text.Visible = false
            return
        end
        
        if espTeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            drawings.box_out.Visible = false
            drawings.box.Visible = false
            drawings.box_fill.Visible = false
            uis.health_bg.Visible = false
            uis.name_text.Visible = false
            uis.info_text.Visible = false
            return
        end
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local vec, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local playerColor = getPlayerColor(player)
                
                local size_x = 2200 / vec.Z
                local size_y = 3200 / vec.Z
                local x = vec.X - size_x / 2
                local y = vec.Y - size_y / 2

                local boxAlpha = (espBoxAlpha or 3) / 10
                
                if espBoxOutline then
                    drawings.box_out.Visible = true
                    drawings.box_out.Position = Vector2.new(x, y)
                    drawings.box_out.Size = Vector2.new(size_x, size_y)
                    drawings.box_out.Color = Color3.new(0, 0, 0)
                    drawings.box_out.Transparency = 1 - boxAlpha
                else
                    drawings.box_out.Visible = false
                end
                
                if espBoxFilled then
                    drawings.box_fill.Visible = true
                    drawings.box_fill.Position = Vector2.new(x, y)
                    drawings.box_fill.Size = Vector2.new(size_x, size_y)
                    drawings.box_fill.Color = playerColor
                    drawings.box_fill.Transparency = 1 - boxAlpha
                else
                    drawings.box_fill.Visible = false
                end
                
                drawings.box.Visible = true
                drawings.box.Position = Vector2.new(x, y)
                drawings.box.Size = Vector2.new(size_x, size_y)
                drawings.box.Color = playerColor
                drawings.box.Transparency = 1 - boxAlpha

                if espShowHealth then
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    uis.health_bg.Visible = true
                    uis.health_bg.Position = UDim2.new(0, x - 6, 0, y)
                    uis.health_bg.Size = UDim2.new(0, 4, 0, size_y)
                    uis.health_fill.Position = UDim2.new(0, 1, 1 - healthPercent, 0)
                    uis.health_fill.Size = UDim2.new(0, 2, healthPercent, 0)
                else
                    uis.health_bg.Visible = false
                end

                uis.name_text.Visible = true
                uis.name_text.TextSize = 10
                uis.name_text.Position = UDim2.new(0, x, 0, y - 15)
                uis.name_text.Size = UDim2.new(0, size_x, 0, 10)
                uis.name_text.Text = player.Name
                uis.name_text.TextColor3 = playerColor

                if espShowDistance then
                    uis.info_text.Visible = true
                    uis.info_text.TextSize = 10
                    uis.info_text.Position = UDim2.new(0, x + size_x + 4, 0, y)
                    uis.info_text.Size = UDim2.new(0, 100, 0, 100)
                    uis.info_text.Text = string.format("hp: %d\ndist: %dm", math.floor(humanoid.Health), math.floor(vec.Z))
                    uis.info_text.TextColor3 = playerColor
                else
                    uis.info_text.Visible = false
                end
            else
                drawings.box_out.Visible = false
                drawings.box.Visible = false
                drawings.box_fill.Visible = false
                uis.health_bg.Visible = false
                uis.name_text.Visible = false
                uis.info_text.Visible = false
            end
        else
            drawings.box_out.Visible = false
            drawings.box.Visible = false
            drawings.box_fill.Visible = false
            uis.health_bg.Visible = false
            uis.name_text.Visible = false
            uis.info_text.Visible = false
        end
    end)
end

local function removeESP(player)
    if espDrawings[player] then
        espDrawings[player].box_out:Remove()
        espDrawings[player].box:Remove()
        espDrawings[player].box_fill:Remove()
    end
    
    if espUIs[player] then
        espUIs[player].health_bg:Destroy()
        espUIs[player].name_text:Destroy()
        espUIs[player].info_text:Destroy()
    end
    
    if playerConnections[player] then
        playerConnections[player]:Disconnect()
    end
    
    espDrawings[player] = nil
    espUIs[player] = nil
    playerConnections[player] = nil
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(removeESP)

LocalPlayer.CharacterRemoving:Connect(function()
    for player in pairs(espDrawings) do
        removeESP(player)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if espEnabled then
        task.wait(1)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not espDrawings[player] then
                createESP(player)
            end
        end
    end
end)

local function applyRichPlayer()
    local char = LocalPlayer.Character
    if not char then return end
    if not next(originalPlayerProperties) then
        for _,partName in ipairs({"Torso","Right Leg","Right Arm","Left Leg","Left Arm","Head"}) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                originalPlayerProperties[partName] = {Color = part.Color,Transparency = part.Transparency}
                originalPlayerMaterials[partName] = part.Material
            end
        end
    end
    for _,partName in ipairs({"Torso","Right Leg","Right Arm","Left Leg","Left Arm","Head"}) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = richPlayerColor
            part.Transparency = richPlayerTransparency/100
            part.Material = Enum.Material.ForceField
        end
    end
end

local function resetRichPlayer()
    local char = LocalPlayer.Character
    if not char then return end
    for partName,properties in pairs(originalPlayerProperties) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then part.Color = properties.Color part.Transparency = properties.Transparency end
    end
    for partName,material in pairs(originalPlayerMaterials) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then part.Material = material end
    end
    originalPlayerProperties = {}
    originalPlayerMaterials = {}
end

LocalPlayer.CharacterAdded:Connect(function() 
    if richPlayerEnabled then 
        applyRichPlayer() 
    end 
end)

local VisualShaderSection = VisualTab:Section({Name = "Shader", Side = "Left"})
local VisualPlayerSection = VisualTab:Section({Name = "Player", Side = "Right"})
local VisualESPSection = VisualTab:Section({Name = "ESP", Side = "Left"})

local shaderToggle = VisualShaderSection:Toggle({Name = "Rich Shader", Default = false, Callback = function(value)
    richShaderEnabled = value
    if value then
        local colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "RichShaderEffect"
        colorCorrection.Parent = game:GetService("Lighting")
        colorCorrection.Brightness = richBrightness/100
        colorCorrection.Contrast = richContrast/100
        colorCorrection.Saturation = richSaturation/100
        colorCorrection.TintColor = richColor
    else
        local lighting = game:GetService("Lighting")
        local effect = lighting:FindFirstChild("RichShaderEffect")
        if effect then effect:Destroy() end
    end
end})
shaderToggle:Colorpicker({Name = "Ambient Color", Default = Color3.fromRGB(255,200,150), Callback = function(color)
    richColor = color
    if richShaderEnabled then 
        local lighting = game:GetService("Lighting") 
        local effect = lighting:FindFirstChild("RichShaderEffect") 
        if effect then effect.TintColor = color end
    end
end})
shaderToggle:Slider({Name = "Brightness", Default = 20, Min = 0, Max = 100, Callback = function(value)
    richBrightness = value
    if richShaderEnabled then 
        local lighting = game:GetService("Lighting") 
        local effect = lighting:FindFirstChild("RichShaderEffect") 
        if effect then effect.Brightness = value/100 end
    end
end})
shaderToggle:Slider({Name = "Contrast", Default = 50, Min = 0, Max = 100, Callback = function(value)
    richContrast = value
    if richShaderEnabled then 
        local lighting = game:GetService("Lighting") 
        local effect = lighting:FindFirstChild("RichShaderEffect") 
        if effect then effect.Contrast = value/100 end
    end
end})
shaderToggle:Slider({Name = "Saturation", Default = 150, Min = 0, Max = 200, Callback = function(value)
    richSaturation = value
    if richShaderEnabled then 
        local lighting = game:GetService("Lighting") 
        local effect = lighting:FindFirstChild("RichShaderEffect") 
        if effect then effect.Saturation = value/100 end
    end
end})

local playerToggle = VisualPlayerSection:Toggle({Name = "Rich Player", Default = false, Callback = function(value)
    richPlayerEnabled = value
    if value then 
        if LocalPlayer.Character then applyRichPlayer() end 
    else 
        if LocalPlayer.Character then resetRichPlayer() end 
    end
end})
playerToggle:Colorpicker({Name = "Player Color", Default = Color3.fromRGB(255,255,255), Callback = function(color)
    richPlayerColor = color
    if richPlayerEnabled and LocalPlayer.Character then applyRichPlayer() end
end})
VisualPlayerSection:Slider({Name = "Transparency", Default = 0, Min = 0, Max = 100, Callback = function(value)
    richPlayerTransparency = value
    if richPlayerEnabled and LocalPlayer.Character then applyRichPlayer() end
end})

local espToggle = VisualESPSection:Toggle({Name = "ESP Enabled", Default = true, Callback = function(value)
    espEnabled = value
end})
espToggle:Keybind({Name = "Keybind", ShowInList = true})
espToggle:Colorpicker({Name = "ESP Color", Default = Color3.fromRGB(255,50,50), Callback = function(color)
    espMainColor = color
end})

local teamToggle = VisualESPSection:Toggle({Name = "Team Check", Default = false, Callback = function(value)
    espTeamCheck = value
end})

local whitelistToggle = VisualESPSection:Toggle({Name = "Use Whitelist Color", Default = true, Callback = function(value)
    espUseWhitelistColor = value
end})
whitelistToggle:Colorpicker({Name = "Whitelist Color", Default = Color3.fromRGB(50,255,50), Callback = function(color)
    espWhitelistColor = color
end})

local targetlistToggle = VisualESPSection:Toggle({Name = "Use Targetlist Color", Default = true, Callback = function(value)
    espUseTargetlistColor = value
end})
targetlistToggle:Colorpicker({Name = "Targetlist Color", Default = Color3.fromRGB(255,50,255), Callback = function(color)
    espTargetlistColor = color
end})

local healthToggle = VisualESPSection:Toggle({Name = "Show Health", Default = true, Callback = function(value)
    espShowHealth = value
end})

local distanceToggle = VisualESPSection:Toggle({Name = "Show Distance", Default = true, Callback = function(value)
    espShowDistance = value
end})

local filledToggle = VisualESPSection:Toggle({Name = "Box Filled", Default = true, Callback = function(value)
    espBoxFilled = value
end})

local outlineToggle = VisualESPSection:Toggle({Name = "Box Outline", Default = true, Callback = function(value)
    espBoxOutline = value
end})

local alphaSlider = VisualESPSection:Slider({Name = "Box Alpha", Default = 3, Min = 0, Max = 10, Callback = function(value)
    espBoxAlpha = value
end})
