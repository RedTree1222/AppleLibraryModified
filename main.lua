-- Clean up lingering DepthOfField effects from previous script executions before loading the new one
for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
    if v:IsA("DepthOfFieldEffect") then v:Destroy() end
end

local lib = {}
local blur = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/refs/heads/main/Blur.luau"))()
local lucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lib/Icons.luau"))()
lib.ButtonStyle = "Modern"
lib.FolderName = "AppleLibraryModified"
local sections = {}
local workareas = {}
local notifs = {}
local mainTabs = {}
local extraTabs = {}
local isExtraMode = false
local tabSwapCooldown = false
local isSidebarCollapsed = false
local expandedSidebarWidth = 190
local collapseCooldown = false
local visible = true
local dbcooper = false
local scrollSyncConnected = false
local blurEnabled = false

local cleanupKeybinds = {}
local cleanupToggles = {}

local registeredElements = {}
local activeKeybindData = {} 
local isPromptingKeybind = false
local keybindPromptCallback = nil
local keybindPromptElementName = nil
local refreshKeybindsUI = nil

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function getAsset(path)
    local fileName = string.match(path, "[^/]+$") or path
    local localPath = fileName
    local fileExists = isfile and isfile(localPath) or pcall(function() return readfile(localPath) end)

    if not fileExists then
        local url = "https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/" .. path
        local ok, content = pcall(function() return game:HttpGet(url) end)
        if ok and content then
            pcall(function()
                writefile(localPath, content)
                fileExists = true
            end)
        end
    end

    if fileExists then
        local ok, asset = pcall(function() return getcustomasset(localPath) end)
        if ok then return asset end
    end
    return ""
end

local function tp(ins, pos, time)
    TweenService:Create(ins, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position = pos}):Play()
end

local themeElements = {}

local HttpService = game:GetService("HttpService")

local ConfigManager = {
    Elements = {},
    CurrentTheme = "light"
}

-- save cfg
function ConfigManager:Save(name)
    local data = { Elements = {}, Keybinds = {} }
    for flag, element in pairs(self.Elements) do
        if element.Value ~= nil and not string.find(flag, "^Settings_") then
            data.Elements[flag] = element.Value
        end
    end
    for _, bindInfo in ipairs(activeKeybindData) do
        data.Keybinds[bindInfo.Name] = { Key = bindInfo.Key, Enabled = bindInfo.Enabled }
    end
    if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
    if makefolder and not isfolder(lib.FolderName .. "/Configs") then makefolder(lib.FolderName .. "/Configs") end
    writefile(lib.FolderName .. "/Configs/" .. name .. ".json", HttpService:JSONEncode(data))
end

-- load cfg
function ConfigManager:Load(name)
    local path = lib.FolderName .. "/Configs/" .. name .. ".json"
    if isfile and not isfile(path) then return end
    local ok, content = pcall(function() return readfile(path) end)
    if ok and type(content) == "string" and content ~= "" then
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if success and data then
            local elementsData = data.Elements or data
            for flag, value in pairs(elementsData) do
                if self.Elements[flag] and self.Elements[flag].Set then
                    self.Elements[flag]:Set(value)
                end
            end
            if data.Keybinds then
                for elemName, bindData in pairs(data.Keybinds) do
                    -- Backward compatibility: if it's a string, just treat as Key and Enabled=true
                    local keyName = type(bindData) == "table" and bindData.Key or bindData
                    local isEnabled = type(bindData) == "table" and bindData.Enabled or true
                    local keyCode = Enum.KeyCode[keyName]
                    
                    if keyCode and registeredElements[elemName] then
                        local alreadyBound = false
                        for _, existing in ipairs(activeKeybindData) do
                            if existing.Name == elemName then alreadyBound = true break end
                        end
                        if not alreadyBound then
                            table.insert(activeKeybindData, { Name = elemName, Key = keyName, Enabled = isEnabled, Callback = registeredElements[elemName] })
                        end
                    end
                end
                if refreshKeybindsUI then refreshKeybindsUI() end
            end
        end
    end
end

function ConfigManager:Delete(name)
    local path = lib.FolderName .. "/Configs/" .. name .. ".json"
    if isfile and isfile(path) then
        pcall(function() delfile(path) end)
    elseif pcall(function() return readfile(path) end) then
        delfile(path)
    end
end

function ConfigManager:GetConfigs()
    local configs = {}
    if isfolder(lib.FolderName .. "/Configs") then
        local files = listfiles(lib.FolderName .. "/Configs")
        for _, file in ipairs(files) do
            local name = string.match(file, "([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
    end
    return configs
end


function ConfigManager:SaveAutoLoad(name)
    if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
    writefile(lib.FolderName .. "/autoload.txt", name)
end

function ConfigManager:GetAutoLoad()
    local path = lib.FolderName .. "/autoload.txt"
    if isfile and isfile(path) then
        local ok, content = pcall(function() return readfile(path) end)
        if ok and type(content) == "string" and content ~= "" then
            return content
        end
    end
    return nil
end

function ConfigManager:SaveUISettings()
    if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
    local data = {
        theme = self.CurrentTheme,
        disableSplash = self.DisableSplash,
        accentR = self.AccentColor and self.AccentColor.R or nil,
        accentG = self.AccentColor and self.AccentColor.G or nil,
        accentB = self.AccentColor and self.AccentColor.B or nil,
        rainbow = self.Rainbow,
        welcomeShown = self.WelcomeShown,
        Settings = {}
    }
    for flag, element in pairs(self.Elements) do
        if element.Value ~= nil and type(flag) == "string" and string.find(flag, "^Settings_") then
            data.Settings[flag] = element.Value
        end
    end
    writefile(lib.FolderName .. "/ui_settings.json", HttpService:JSONEncode(data))
end

function ConfigManager:LoadUISettings()
    local path = lib.FolderName .. "/ui_settings.json"
    if isfile and not isfile(path) then return end
    local ok, content = pcall(function() return readfile(path) end)
    if ok and type(content) == "string" and content ~= "" then
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if success and data then
            if data.theme then self.CurrentTheme = data.theme end
            if data.disableSplash ~= nil then self.DisableSplash = data.disableSplash end
            if data.accentR and data.accentG and data.accentB then self.AccentColor = Color3.new(data.accentR, data.accentG, data.accentB) end
            if data.rainbow ~= nil then self.Rainbow = data.rainbow end
            if data.Settings then
                for flag, val in pairs(data.Settings) do
                    if self.Elements[flag] then
                        self.Elements[flag]:Set(val)
                    else
                        self.Elements[flag] = { Value = val }
                    end
                end
            end
        end
    end
end

local currentTheme = ConfigManager.CurrentTheme
local currentAccentColor = Color3.fromRGB(21, 103, 251)

local iconMap = {
    ["arrow-left-to-line"] = "rbxassetid://10709768114",
    ["refresh-ccw"] = "rbxassetid://10734933056",
    ["settings"] = "rbxassetid://10734950309",
    ["users"] = "rbxassetid://10747373426",
    ["keyboard"] = "rbxassetid://10723416765",
    ["bell"] = "rbxassetid://10709775704",
    ["package"] = "rbxassetid://10734909540",
    ["warning"] = "rbxassetid://12608260095",
    ["info"] = "rbxassetid://4871684504"
}

local function registerTheme(instance, propertyName, lightValue, darkValue)
    table.insert(themeElements, {
        Instance = instance,
        Property = propertyName,
        Light = lightValue,
        Dark = darkValue
    })
    instance[propertyName] = (currentTheme == "light") and lightValue or darkValue
end

-- build main ui
function lib:init(ti, dosplash, visiblekey, deleteprevious)
    ConfigManager:LoadUISettings()
    -- Load script-specific menu bind
    do
        local bindPath = lib.FolderName .. "/menu_bind.txt"
        if isfile and isfile(bindPath) then
            local ok, saved = pcall(readfile, bindPath)
            if ok and saved and saved ~= "" then
                local kc = Enum.KeyCode[saved]
                if kc then visiblekey = kc end
            end
        end
    end
    
    

    local iconMap = {
        ["arrow-left-to-line"] = "rbxassetid://10709768114",
        ["refresh-ccw"] = "rbxassetid://10734933056",
        ["settings"] = "rbxassetid://10734950309",
        ["users"] = "rbxassetid://10747373426",
        ["keyboard"] = "rbxassetid://10723416765",
        ["bell"] = "rbxassetid://10709775704",
        ["package"] = "rbxassetid://10734909540",
        ["warning"] = "rbxassetid://12608260095",
        ["info"] = "rbxassetid://4871684504"
    }
    
    local function resolveIcon(imageLabel, iconId)
        if type(iconId) ~= "string" then iconId = "rbxassetid://10709768114" end
        if string.find(iconId, "rbxassetid://") then
            imageLabel.Image = iconId
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        elseif lucideIcons[iconId] then
            local data = lucideIcons[iconId]
            imageLabel.Image = "rbxassetid://" .. tostring(data[1])
            imageLabel.ImageRectSize = Vector2.new(data[2][1], data[2][2])
            imageLabel.ImageRectOffset = Vector2.new(data[3][1], data[3][2])
        elseif iconMap[iconId] then
            imageLabel.Image = iconMap[iconId]
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        else
            imageLabel.Image = "rbxassetid://10734909540"
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        end
    end

    local function applyLucide(imgLabel, iconName)
        if iconMap[iconName] then
            imgLabel.Image = iconMap[iconName]
        else
            imgLabel.Image = "rbxassetid://10734909540" -- default to package
        end
    end
    currentTheme = ConfigManager.CurrentTheme

    local errorCatcherEnabled = false
    if ConfigManager.DisableSplash then dosplash = false end
    
    local customKeybinds = {}
    local isPromptingKeybind = false
    local keybindPromptCallback = nil

    if deleteprevious then
        local container = gethui and gethui() or game:GetService("CoreGui")
        for _, v in pairs(container:GetChildren()) do
            if v.Name == "AppleLibrary_GUI" then
                v:Destroy()
            end
        end

    end
    scrgui = Instance.new("ScreenGui")
    scrgui.Name = "AppleLibrary_GUI"
    if syn then syn.protect_gui(scrgui) end
    if gethui then scrgui.Parent = gethui() else scrgui.Parent = game:GetService("CoreGui") end
    scrgui.IgnoreGuiInset = true

    local modalUnlocker = Instance.new("TextButton")
    modalUnlocker.Name = "ModalUnlocker"
    modalUnlocker.Parent = scrgui
    modalUnlocker.BackgroundTransparency = 1
    modalUnlocker.Text = ""
    modalUnlocker.Size = UDim2.new(0, 0, 0, 0)
    modalUnlocker.Modal = false

    if dosplash then
        local splash = Instance.new("Frame")
        splash.Name = "splash"
        splash.Parent = scrgui
        splash.AnchorPoint = Vector2.new(0.5, 0.5)
        splash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        splash.BackgroundTransparency = 0.600
        splash.Position = UDim2.new(0.5, 0, 2, 0)
        splash.Size = UDim2.new(0, 340, 0, 340)
        splash.Visible = true
        splash.ZIndex = 40

        local uc_22 = Instance.new("UICorner")
        uc_22.CornerRadius = UDim.new(0, 18)
        uc_22.Parent = splash

        local sicon = Instance.new("ImageLabel")
        sicon.Name = "sicon"
        sicon.Parent = splash
        sicon.AnchorPoint = Vector2.new(0.5, 0.5)
        sicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sicon.BackgroundTransparency = 1
        sicon.Position = UDim2.new(0.5, 0, 0.5, 0)
        sicon.Size = UDim2.new(0, 191, 0, 190)
        sicon.ZIndex = 40
        sicon.Image = "rbxassetid://12621719043"
        sicon.ScaleType = Enum.ScaleType.Fit
        sicon.TileSize = UDim2.new(1, 0, 20, 0)

        local ug = Instance.new("UIGradient")
        ug.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.01, Color3.fromRGB(61, 61, 61)), ColorSequenceKeypoint.new(0.47, Color3.fromRGB(41, 41, 41)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
        ug.Rotation = 90
        ug.Parent = sicon

        local sshadow = Instance.new("ImageLabel")
        sshadow.Name = "sshadow"
        sshadow.Parent = splash
        sshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        sshadow.BackgroundTransparency = 1
        sshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        sshadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
        sshadow.ZIndex = 39
        sshadow.Image = "rbxassetid://313486536"
        sshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        sshadow.ImageTransparency = 0.400
        sshadow.TileSize = UDim2.new(0, 1, 0, 1)
        splash:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "InOut", "Quart", 1)
        wait(2)
        splash:TweenPosition(UDim2.new(0.5, 0, 2, 0), "InOut", "Quart", 1)
        game:GetService("Debris"):AddItem(splash, 1)
    end

    local isMob = UserInputService.TouchEnabled
    local cScale = isMob and 0.85 or 1.0

    local main = Instance.new("Frame")
    main.ClipsDescendants = true

    local keybindsWindowFrame = Instance.new("Frame")
    keybindsWindowFrame.Name = "keybindsWindowFrame"
    keybindsWindowFrame.Parent = scrgui
    keybindsWindowFrame.BorderSizePixel = 0
    keybindsWindowFrame.Size = UDim2.new(0, 220, 0, 40)
    keybindsWindowFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
    keybindsWindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    keybindsWindowFrame.AutomaticSize = Enum.AutomaticSize.Y
    keybindsWindowFrame.Visible = false
    registerTheme(keybindsWindowFrame, "BackgroundColor3", Color3.fromRGB(249, 249, 255), Color3.fromRGB(18, 18, 24))
    
    local kbBlurFrame = Instance.new("Frame")
    kbBlurFrame.Name = "blurFrame"
    kbBlurFrame.Parent = keybindsWindowFrame
    kbBlurFrame.BackgroundTransparency = 1
    kbBlurFrame.Position = UDim2.new(0, 2, 0, 2)
    kbBlurFrame.Size = UDim2.new(1, -4, 1, -4)
    kbBlurFrame.ZIndex = 0
    
    local kb_uc = Instance.new("UICorner")
    kb_uc.CornerRadius = UDim.new(0, 8)
    kb_uc.Parent = keybindsWindowFrame
    
    local kb_stroke = Instance.new("UIStroke")
    kb_stroke.Parent = keybindsWindowFrame
    kb_stroke.Transparency = 0.8
    kb_stroke.Thickness = 1
    registerTheme(kb_stroke, "Color", Color3.fromRGB(216, 216, 216), Color3.fromRGB(40, 40, 40))

    local kb_topbar = Instance.new("Frame")
    kb_topbar.Name = "topbar"
    kb_topbar.Parent = keybindsWindowFrame
    kb_topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kb_topbar.BackgroundTransparency = 1
    kb_topbar.Size = UDim2.new(1, 0, 0, 40)
    
    local kb_title = Instance.new("TextLabel")
    kb_title.Parent = kb_topbar
    kb_title.BackgroundTransparency = 1
    kb_title.Position = UDim2.new(0, 15, 0, 0)
    kb_title.Size = UDim2.new(1, -30, 1, 0)
    kb_title.Font = Enum.Font.GothamMedium
    kb_title.Text = "Keybinds"
    kb_title.TextSize = 14
    kb_title.TextXAlignment = Enum.TextXAlignment.Left
    registerTheme(kb_title, "TextColor3", Color3.fromRGB(100, 100, 100), Color3.fromRGB(140, 140, 155))

    local kb_container = Instance.new("Frame")
    kb_container.Parent = keybindsWindowFrame
    kb_container.BackgroundTransparency = 1
    kb_container.Position = UDim2.new(0, 0, 0, 40)
    kb_container.Size = UDim2.new(1, 0, 0, 0)
    kb_container.AutomaticSize = Enum.AutomaticSize.Y

    local kb_layout = Instance.new("UIListLayout")
    kb_layout.Parent = kb_container
    kb_layout.SortOrder = Enum.SortOrder.LayoutOrder
    kb_layout.Padding = UDim.new(0, 5)

    local kb_padding = Instance.new("UIPadding")
    kb_padding.Parent = kb_container
    kb_padding.PaddingBottom = UDim.new(0, 10)

    local kbDragging = false
    local kbDragStart, kbStartPos
    kb_topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            kbDragging = true
            kbDragStart = input.Position
            kbStartPos = keybindsWindowFrame.Position
            local c; c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    kbDragging = false
                    c:Disconnect()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if kbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - kbDragStart
            keybindsWindowFrame.Position = UDim2.new(kbStartPos.X.Scale, kbStartPos.X.Offset + delta.X, kbStartPos.Y.Scale, kbStartPos.Y.Offset + delta.Y)
        end
    end)

    main.Name = "main"
    main.Parent = scrgui

    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "blurFrame"
    blurFrame.Parent = main
    blurFrame.BackgroundTransparency = 1
    blurFrame.Position = UDim2.new(0, 0, 0, 0)
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.ZIndex = 0
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 2, 0)
    
    local function updateMainSize()
        local vp = workspace.CurrentCamera.ViewportSize
        local w = math.clamp(721, 400, vp.X - 40)
        local h = math.clamp(584, 300, vp.Y - 40)
        main.Size = UDim2.new(0, w, 0, h)
    end
    updateMainSize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMainSize)
    registerTheme(main, "BackgroundColor3", Color3.fromRGB(245, 245, 250), Color3.fromRGB(18, 18, 24))

    if isMob then
        local fab = Instance.new("ImageButton")
        fab.Name = "MobileFAB"
        fab.Parent = scrgui
        fab.ZIndex = 99999
        fab.AnchorPoint = Vector2.new(1, 0.5)
        fab.Position = UDim2.new(1, -20, 0.5, 0)
        fab.Size = UDim2.new(0, 46, 0, 46)
        fab.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        fab.Image = "rbxassetid://12621719043" -- Library icon
        fab.ImageRectOffset = Vector2.new(0, 0)
        fab.ImageRectSize = Vector2.new(0, 0)
        fab.ScaleType = Enum.ScaleType.Fit
        
        local fabCorner = Instance.new("UICorner")
        fabCorner.CornerRadius = UDim.new(1, 0)
        fabCorner.Parent = fab
        
        local fabStroke = Instance.new("UIStroke")
        fabStroke.Parent = fab
        fabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        fabStroke.Color = Color3.fromRGB(41, 41, 41)
        fabStroke.Thickness = 1.5
        
        local fabDrag = false
        local fabStart = nil
        local fabStartPos = nil
        
        fab.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                fabDrag = true
                fabStart = input.Position
                fabStartPos = fab.Position
                for _, v in ipairs(scrgui:GetDescendants()) do
                    if v:IsA("ScrollingFrame") then v.ScrollingEnabled = false end
                end
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if fabDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - fabStart
                fab.Position = UDim2.new(fabStartPos.X.Scale, fabStartPos.X.Offset + delta.X, fabStartPos.Y.Scale, fabStartPos.Y.Offset + delta.Y)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if fabDrag and fabStart then
                    local dist = (input.Position - fabStart).Magnitude
                    if dist < 10 then
                        if window.ToggleVisible then window:ToggleVisible() end
                    end
                end
                if fabDrag then
                    for _, v in ipairs(scrgui:GetDescendants()) do
                        if v:IsA("ScrollingFrame") then v.ScrollingEnabled = true end
                    end
                end
                fabDrag = false
            end
        end)
    end

    local uiscale = Instance.new("UIScale")
    uiscale.Parent = main
    uiscale.Scale = cScale

    main.BackgroundTransparency = 0.08

    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, 14)
    uc.Parent = main

    local topbar = Instance.new("TextButton")
    topbar.Name = "topbar"
    topbar.Parent = main
    topbar.BackgroundTransparency = 1
    topbar.Text = ""
    topbar.Size = UDim2.new(1, -150, 0, 50)
    topbar.Position = UDim2.new(0, 150, 0, 0)
    topbar.ZIndex = 20

    local dragging = false
    local activeResize = false
    local isAnimatingVis = false
    local dragStart
    local startPos
    local targetX = main.Position.X.Offset
    local targetY = main.Position.Y.Offset
    local currentX = targetX
    local currentY = targetY

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local function updateDrag(input)
        local delta = input.Position - dragStart
        targetX = startPos.X.Offset + delta.X
        targetY = startPos.Y.Offset + delta.Y
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)

    main:GetPropertyChangedSignal("Position"):Connect(function()
        if not dragging and not activeResize and not isAnimatingVis then
            targetX = main.Position.X.Offset
            targetY = main.Position.Y.Offset
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        local followSpeed = 15
        currentX = currentX + (targetX - currentX) * (1 - math.exp(-followSpeed * dt))
        currentY = currentY + (targetY - currentY) * (1 - math.exp(-followSpeed * dt))
        main.Position = UDim2.new(0.5, currentX, 0.5, currentY)
    end)

    local workarea = Instance.new("Frame")
    workarea.Name = "workarea"
    workarea.Parent = main
    registerTheme(workarea, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
    workarea.Position = UDim2.new(0, expandedSidebarWidth + 30, 0, 0)
    workarea.Size = UDim2.new(1, -(expandedSidebarWidth + 30), 1, 0)
    workarea.BackgroundTransparency = 1

    local uc_2 = Instance.new("UICorner")
    uc_2.CornerRadius = UDim.new(0, 14)
    uc_2.Parent = workarea

    local workareacornerhider = Instance.new("Frame")
    workareacornerhider.Name = "workareacornerhider"
    workareacornerhider.Parent = workarea
    registerTheme(workareacornerhider, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
    workareacornerhider.BorderSizePixel = 0
    workareacornerhider.Size = UDim2.new(0, 18, 1, 0)
    workareacornerhider.BackgroundTransparency = 1

    local collapseBtn = Instance.new("ImageButton")
    collapseBtn.Name = "collapseBtn"
    collapseBtn.Parent = main
    collapseBtn.Size = UDim2.new(0, 24, 0, 24)
    collapseBtn.Position = UDim2.new(0, 18, 1, -44)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Image = "rbxassetid://10709768114"
    collapseBtn.ImageColor3 = Color3.fromRGB(140, 140, 155)
    collapseBtn.ZIndex = 25
    registerTheme(collapseBtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))

    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Name = "refreshBtn"
        refreshBtn.Parent = main
    refreshBtn.Size = UDim2.new(0, 24, 0, 24)
    refreshBtn.Position = UDim2.new(0, 18, 1, -84)
    refreshBtn.BackgroundTransparency = 1
    refreshBtn.Image = "rbxassetid://10734933056"
    refreshBtn.ImageColor3 = Color3.fromRGB(140, 140, 155)
    refreshBtn.ZIndex = 25
    registerTheme(refreshBtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))

    refreshBtn.MouseButton1Click:Connect(function()
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(refreshBtn, tweenInfo, {Rotation = refreshBtn.Rotation + 360}):Play()
        local vp = workspace.CurrentCamera.ViewportSize
        local w = math.clamp(721, 400, vp.X - 40)
        local h = math.clamp(584, 300, vp.Y - 40)
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(0, w, 0, h)}):Play()
        
        expandedSidebarWidth = 190
        sidebarResizer.Position = UDim2.new(0, 18 + expandedSidebarWidth - 4, 0, 106)
        if not isSidebarCollapsed then
            TweenService:Create(sidebar, tweenInfo, {Size = UDim2.new(0, expandedSidebarWidth, 1, -124)}):Play()
            TweenService:Create(workarea, tweenInfo, {
                Position = UDim2.new(0, expandedSidebarWidth + 30, 0, 0),
                Size = UDim2.new(1, -(expandedSidebarWidth + 30), 1, 0)
            }):Play()
            
            local searchWidth = expandedSidebarWidth - 8
            TweenService:Create(search, tweenInfo, {Size = UDim2.new(0, searchWidth, 0, 34)}):Play()
            
            for _, btn in ipairs(sidebar:GetChildren()) do
                if btn:IsA("TextButton") and btn.Name == "sidebar2" then
                    TweenService:Create(btn, tweenInfo, {Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34)}):Play()
                elseif btn:IsA("TextLabel") and btn.Name == "sidebardivider" then
                    TweenService:Create(btn, tweenInfo, {Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 20)}):Play()
                end
            end
            
            local highlight = main:FindFirstChild("TabHighlight")
            if highlight then
                TweenService:Create(highlight, tweenInfo, {Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34)}):Play()
            end
        end
    end)

    local search = Instance.new("Frame")
    search.Name = "search"
    search.Parent = main
    registerTheme(search, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
    search.Position = UDim2.new(0, 18, 0, 56)
    search.Size = UDim2.new(0, isSidebarCollapsed and 26 or 182, 0, 34)

    local uc_8 = Instance.new("UICorner")
    uc_8.CornerRadius = UDim.new(0, 10)
    uc_8.Parent = search

    local searchicon = Instance.new("ImageButton")
    searchicon.Name = "searchicon"
    searchicon.Parent = search
    searchicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    searchicon.BackgroundTransparency = 1
    searchicon.BorderColor3 = Color3.fromRGB(27, 42, 53)
    searchicon.Position = UDim2.new(0.0379999988, -2, 0.138999999, 2)
    searchicon.Size = UDim2.new(0, 24, 0, 21)
    searchicon.Image = "rbxassetid://2804603863"
    searchicon.ImageColor3 = Color3.fromRGB(95, 95, 95)
    searchicon.ScaleType = Enum.ScaleType.Fit

    local searchtextbox = Instance.new("TextBox")
    searchtextbox.Name = "searchtextbox"
    searchtextbox.Parent = search
    searchtextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    searchtextbox.BackgroundTransparency = 1
    searchtextbox.ClipsDescendants = true
    searchtextbox.Position = UDim2.new(0.180257514, 0, -0.0162218884, 0)
    searchtextbox.Size = UDim2.new(0, 176, 0, 34)
    searchtextbox.Font = Enum.Font.GothamMedium
    searchtextbox.LineHeight = 0.870
    searchtextbox.PlaceholderText = "Search"
    searchtextbox.Text = ""
    registerTheme(searchtextbox, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    searchtextbox.TextSize = 15
    searchtextbox.TextXAlignment = Enum.TextXAlignment.Left

    searchicon.MouseButton1Click:Connect(function()
        searchtextbox:CaptureFocus()
    end)

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "sidebar"
    sidebar.Parent = main
    registerTheme(sidebar, "BackgroundColor3", Color3.fromRGB(245, 245, 250), Color3.fromRGB(18, 18, 24))
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.new(0, 18, 0, 106)
    sidebar.Size = UDim2.new(0, expandedSidebarWidth, 1, -124)
    sidebar.AutomaticCanvasSize = "Y"
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)

    local sidebarResizer = Instance.new("TextButton")
    sidebarResizer.Name = "sidebarResizer"
    sidebarResizer.Parent = main
    sidebarResizer.Size = UDim2.new(0, 8, 1, -124)
    sidebarResizer.Position = UDim2.new(0, 18 + expandedSidebarWidth - 4, 0, 106)
    sidebarResizer.BackgroundTransparency = 1
    sidebarResizer.Text = ""
    sidebarResizer.ZIndex = 30
    
    local sidebarResizing = false
    local sidebarStartX = 0
    local sidebarStartWidth = 0

    sidebarResizer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sidebarResizing = true
            sidebarStartX = input.Position.X
            sidebarStartWidth = expandedSidebarWidth
            
            local c; c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    sidebarResizing = false
                    c:Disconnect()
                end
            end)
        end
    end)
    sidebar.ScrollBarThickness = 0

    local ull_2 = Instance.new("UIListLayout")
    ull_2.Parent = sidebar
    ull_2.SortOrder = Enum.SortOrder.LayoutOrder
    ull_2.Padding = UDim.new(0, 3)

    searchtextbox:GetPropertyChangedSignal("Text"):Connect(function()
        local InputText = string.upper(searchtextbox.Text)
        
        local allTabs = {}
        if isExtraMode then
            for _, t in ipairs(extraTabs) do table.insert(allTabs, t) end
        else
            for _, t in ipairs(mainTabs) do table.insert(allTabs, t) end
        end

        local highlight = main:FindFirstChild("TabHighlight")
        local activeTab = nil
        for _, s in ipairs(sections) do
            if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                activeTab = s
                break
            end
        end

        if InputText == "" then
            -- Restore normal visibility
            for _, t in ipairs(allTabs) do
                local belongsToExtra = false
                for _, et in ipairs(extraTabs) do if t == et then belongsToExtra = true end end
                
                if t.IsDivider then
                    t.Label.Visible = belongsToExtra and isExtraMode or not isExtraMode
                else
                    t.TabButton.Visible = belongsToExtra and isExtraMode or not isExtraMode
                end
                
                -- Restore element visibility
                if t.ElementsList then
                    for _, elemData in ipairs(t.ElementsList) do
                        if elemData.gui then elemData.gui.Visible = true end
                    end
                end
            end
            if highlight then highlight.Visible = true end
        else
            -- Search active: search all tabs and their internal elements!
            for _, t in ipairs(allTabs) do
                if t.IsDivider then
                    t.Label.Visible = false
                else
                    local btn = t.TabButton
                    local match = false
                    
                    if string.find(string.upper(btn.Text), InputText) then
                        match = true
                    end
                    
                    if t.ElementsList then
                        for _, elemData in ipairs(t.ElementsList) do
                            local elemMatch = string.find(elemData.text, InputText) ~= nil
                            if elemData.gui then elemData.gui.Visible = elemMatch end
                            if elemMatch then match = true end
                        end
                    end
                    
                    btn.Visible = match
                end
            end
            if activeTab and highlight then
                highlight.Visible = activeTab.Visible
            end
        end
        
        -- Glues the TabHighlight to the active tab as UIListLayout shuffles things around
        if activeTab and highlight then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if activeTab and highlight then
                    highlight.Position = UDim2.new(0, activeTab.AbsolutePosition.X - main.AbsolutePosition.X, 0, activeTab.AbsolutePosition.Y - main.AbsolutePosition.Y)
                else
                    if connection then connection:Disconnect() end
                end
            end)
            task.delay(0.2, function()
                if connection then connection:Disconnect() end
            end)
        end
    end)

    local buttons = Instance.new("Frame")
    buttons.Name = "buttons"
    buttons.Parent = main
    buttons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttons.BackgroundTransparency = 1
    buttons.Position = UDim2.new(0, 18, 0, 0)
    buttons.Size = UDim2.new(0, 105, 0, 57)

    local ull_3 = Instance.new("UIListLayout")
    ull_3.Parent = buttons
    ull_3.FillDirection = Enum.FillDirection.Horizontal
    ull_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ull_3.SortOrder = Enum.SortOrder.LayoutOrder
    ull_3.VerticalAlignment = Enum.VerticalAlignment.Center
    ull_3.Padding = UDim.new(0, 10)

    local close = Instance.new("TextButton")
    close.Name = "close"
        close.Parent = buttons
    close.BackgroundColor3 = Color3.fromRGB(254, 94, 86)
    close.Size = UDim2.new(0, 16, 0, 16)
    close.AutoButtonColor = false
    close.Font = Enum.Font.SourceSans
    close.Text = ""
    close.TextColor3 = Color3.fromRGB(255, 50, 50)
    close.TextSize = 14
    close.MouseButton1Click:Connect(function()
        if blur:HasBinding(blurFrame) then
            blur:UnbindFrame(blurFrame)
        end
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("DepthOfFieldEffect") then v:Destroy() end
        end
        local neonFolder = workspace.CurrentCamera:FindFirstChild("Neon")
        if neonFolder then neonFolder:Destroy() end
        RunService:UnbindFromRenderStep("AppleLibMouseUnlock")
        UserInputService.MouseIconEnabled = true
        task.delay(0.1, function()
            UserInputService.MouseIconEnabled = true
        end)
        if visibleKeyConn then visibleKeyConn:Disconnect() end
        for _, conn in ipairs(cleanupKeybinds) do
            if conn.Connected then conn:Disconnect() end
        end
        for _, toggleInfo in ipairs(cleanupToggles) do
            if toggleInfo.callback then
                pcall(toggleInfo.callback, toggleInfo.default)
            end
        end
        scrgui:Destroy()
    end)

    local uc_18 = Instance.new("UICorner")
    uc_18.CornerRadius = UDim.new(1, 0)
    uc_18.Parent = close

    local minimize = Instance.new("TextButton")
    minimize.Name = "minimize"
        minimize.Parent = buttons
    minimize.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
    minimize.Size = UDim2.new(0, 16, 0, 16)
    minimize.AutoButtonColor = false
    minimize.Font = Enum.Font.SourceSans
    minimize.Text = ""
    minimize.TextColor3 = Color3.fromRGB(255, 50, 50)
    minimize.TextSize = 14

    local uc_19 = Instance.new("UICorner")
    uc_19.CornerRadius = UDim.new(1, 0)
    uc_19.Parent = minimize

    local resize = Instance.new("TextButton")
    resize.Name = "resize"
    resize.Parent = buttons
    resize.BackgroundColor3 = Color3.fromRGB(39, 200, 63)
    resize.Size = UDim2.new(0, 16, 0, 16)
    resize.AutoButtonColor = false
    resize.Font = Enum.Font.SourceSans
    resize.Text = ""
    resize.TextColor3 = Color3.fromRGB(255, 50, 50)
    resize.TextSize = 14
    
    resize.MouseButton1Click:Connect(function()
        if tabSwapCooldown then return end
        tabSwapCooldown = true
        isExtraMode = not isExtraMode

        local outgoingTabs = isExtraMode and mainTabs or extraTabs
        local incomingTabs = isExtraMode and extraTabs or mainTabs
        
        local highlight = main:FindFirstChild("TabHighlight")
        if highlight then
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
        end

        -- Phase 1: Animate out
        for _, t in ipairs(outgoingTabs) do
            if t.IsDivider then
                TweenService:Create(t.Label, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    TextTransparency = 1
                }):Play()
            else
                local btn = t.TabButton
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 0, 0, 34),
                    TextTransparency = 1,
                    BackgroundTransparency = 1
                }):Play()
                local ico = btn:FindFirstChild("iconImg")
                if ico then
                    TweenService:Create(ico, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        ImageTransparency = 1
                    }):Play()
                end
            end
        end

        task.delay(0.25, function()
            -- Phase 2: Swap visibility
            for _, t in ipairs(outgoingTabs) do
                if t.IsDivider then t.Label.Visible = false else t.TabButton.Visible = false end
            end
            
            local firstSection = nil
            local firstIncomingIdx = nil
            for i, t in ipairs(incomingTabs) do
                if t.IsDivider and not firstIncomingIdx then firstIncomingIdx = i end
            end

            for i, t in ipairs(incomingTabs) do
                local txtTrans = isSidebarCollapsed and 1 or 0
                local padLeft = isSidebarCollapsed and 0 or 40
                
                if t.IsDivider then
                    local isFirstInMode = (i == firstIncomingIdx)
                    local targetHeight = isSidebarCollapsed and 12 or 20
                    if isFirstInMode and isSidebarCollapsed then targetHeight = 0 end
                    
                    t.Label.TextTransparency = 1
                    t.Label.Visible = true
                    TweenService:Create(t.Label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        TextTransparency = txtTrans,
                        Size = UDim2.new(0, isSidebarCollapsed and 34 or (expandedSidebarWidth - 7), 0, targetHeight)
                    }):Play()
                    
                    local line = t.Label:FindFirstChild("Line")
                    if line then
                        if isFirstInMode then
                            TweenService:Create(line, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                        else
                            TweenService:Create(line, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = isSidebarCollapsed and 0 or 1 }):Play()
                        end
                    end
                else
                    local btn = t.TabButton
                    btn.Size = UDim2.new(0, 0, 0, 34)
                    btn.TextTransparency = 1
                    btn.BackgroundTransparency = 1
                    btn.Visible = true
                    local ico = btn:FindFirstChild("iconImg")
                    if ico then ico.ImageTransparency = 1 end
                    
                    local padding = btn:FindFirstChildOfClass("UIPadding")
                    if padding then
                        TweenService:Create(padding, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { PaddingLeft = UDim.new(0, padLeft) }):Play()
                    end

                    if not firstSection then firstSection = t end

                    -- Phase 3: Animate in
                    local bgTrans = (btn.Name == "sidebar2_selected") and 1 or 0.93
                    local currentTargetWidth = isSidebarCollapsed and 34 or (expandedSidebarWidth - 7)
                    TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, currentTargetWidth, 0, 34),
                        TextTransparency = txtTrans,
                        BackgroundTransparency = bgTrans
                    }):Play()
                    if ico then
                        TweenService:Create(ico, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            ImageTransparency = 0,
                            Position = isSidebarCollapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, -16, 0.5, 0)
                        }):Play()
                    end
                end
            end

            -- Auto-select first tab
            if firstSection then
                firstSection:Select()
                if highlight then
                    TweenService:Create(highlight, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0
                    }):Play()
                    
                    local activeTab = nil
                    for _, s in ipairs(sections) do
                        if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                            activeTab = s
                            break
                        end
                    end
                    if activeTab then
                        local connection
                        connection = RunService.RenderStepped:Connect(function()
                            if activeTab and highlight then
                                highlight.Position = UDim2.new(0, activeTab.AbsolutePosition.X - main.AbsolutePosition.X, 0, activeTab.AbsolutePosition.Y - main.AbsolutePosition.Y)
                            else
                                if connection then connection:Disconnect() end
                            end
                        end)
                        task.delay(0.3, function()
                            if connection then connection:Disconnect() end
                        end)
                    end
                end
            end
            
            task.delay(0.3, function()
                tabSwapCooldown = false
            end)
        end)
    end)

    local uc_20 = Instance.new("UICorner")
    uc_20.CornerRadius = UDim.new(1, 0)
    uc_20.Parent = resize

    local title = Instance.new("TextLabel")
    title.Name = "title"
    title.Parent = workarea
    title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 2
    title.Position = UDim2.new(0, 16, 0, 16)
    title.Size = UDim2.new(1, -32, 0, 30)
    title.Font = Enum.Font.GothamBold
    title.LineHeight = 1.180
    registerTheme(title, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
    title.TextSize = 22
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left

    local moonbtn = Instance.new("ImageButton")
    moonbtn.Name = "moonbtn"
        moonbtn.Parent = main
    moonbtn.Size = UDim2.new(0, 24, 0, 24)
    moonbtn.Position = UDim2.new(1, -40, 0, 16)
    moonbtn.BackgroundTransparency = 1
    moonbtn.Image = getAsset("Assets/blackmoon.png")
    moonbtn.ZIndex = 21

    local function toggleTheme()
        currentTheme = (currentTheme == "light") and "dark" or "light"
        ConfigManager:SaveUISettings(currentTheme, ConfigManager.DisableSplash, ConfigManager.AccentColor, ConfigManager.Rainbow)
        moonbtn.Image = getAsset(currentTheme == "light" and "Assets/blackmoon.png" or "Assets/whitemoon.png")
        for _, item in ipairs(themeElements) do
            pcall(function()
                if item.IsToggle and item.GetToggleState() then
                    item.Instance[item.Property] = currentAccentColor
                else
                    item.Instance[item.Property] = (currentTheme == "light") and item.Light or item.Dark
                end
            end)
        end
        local bgL = Color3.fromRGB(0, 0, 0)
        local bgD = Color3.fromRGB(255, 255, 255)
        local txtL = Color3.fromRGB(100, 100, 100)
        local txtD = Color3.fromRGB(140, 140, 155)
        for _, v in next, sections do
            v.BackgroundColor3 = (currentTheme == "light") and bgL or bgD
            local ico = v:FindFirstChild("iconImg")
            if v.Name == "sidebar2_selected" then
                v.TextColor3 = Color3.fromRGB(255, 255, 255)
                if ico then ico.ImageColor3 = Color3.fromRGB(255, 255, 255) end
            else
                v.TextColor3 = (currentTheme == "light") and txtL or txtD
                if ico then ico.ImageColor3 = (currentTheme == "light") and txtL or txtD end
            end
        end
    end

    moonbtn.MouseButton1Click:Connect(toggleTheme)

    local resizeRight = Instance.new("TextButton")
    resizeRight.Name = "resizeRight"
    resizeRight.Parent = main
    resizeRight.Size = UDim2.new(0, 8, 1, -10)
    resizeRight.Position = UDim2.new(1, -8, 0, 0)
    resizeRight.BackgroundTransparency = 1
    resizeRight.Text = ""
    resizeRight.ZIndex = 11

    local resizeBottom = Instance.new("TextButton")
    resizeBottom.Name = "resizeBottom"
    resizeBottom.Parent = main
    resizeBottom.Size = UDim2.new(1, -10, 0, 8)
    resizeBottom.Position = UDim2.new(0, 0, 1, -8)
    resizeBottom.BackgroundTransparency = 1
    resizeBottom.Text = ""
    resizeBottom.ZIndex = 11

    local resizeCorner = Instance.new("TextButton")
    resizeCorner.Name = "resizeCorner"
    resizeCorner.Parent = main
    resizeCorner.Size = UDim2.new(0, 15, 0, 15)
    resizeCorner.Position = UDim2.new(1, -15, 1, -15)
    resizeCorner.BackgroundTransparency = 1
    resizeCorner.Text = ""
    resizeCorner.ZIndex = 12

    local resizeStartSize
    local resizeStartMouse
    local resizeStartPos

    local function setupResize(btn, type)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                activeResize = type
                resizeStartSize = main.Size
                resizeStartMouse = input.Position
                resizeStartPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        activeResize = false
                    end
                end)
            end
        end)
    end

    setupResize(resizeRight, "right")
    setupResize(resizeBottom, "bottom")
    setupResize(resizeCorner, "corner")

    UserInputService.InputChanged:Connect(function(input)

        if sidebarResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local deltaX = input.Position.X - sidebarStartX
            expandedSidebarWidth = math.clamp(sidebarStartWidth + deltaX, 150, 400)
            
            if not isSidebarCollapsed then
                sidebar.Size = UDim2.new(0, expandedSidebarWidth, 1, -124)
                sidebarResizer.Position = UDim2.new(0, 18 + expandedSidebarWidth - 4, 0, 106)
                workarea.Position = UDim2.new(0, expandedSidebarWidth + 30, 0, 0)
                workarea.Size = UDim2.new(1, -(expandedSidebarWidth + 30), 1, 0)
                
                for b, v in next, sections do
                    v.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34)
                end
                for _, t in ipairs(mainTabs) do
                    if t.IsDivider then t.Label.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 20) else
                        t.TabButton.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34)
                    end
                end
                for _, t in ipairs(extraTabs) do
                    if t.IsDivider then t.Label.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 20) else
                        t.TabButton.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34)
                    end
                end
                local highlight = main:FindFirstChild("TabHighlight")
                if highlight then highlight.Size = UDim2.new(0, expandedSidebarWidth - 7, 0, 34) end
                local currentSearch = main:FindFirstChild("search")
                if currentSearch then currentSearch.Size = UDim2.new(0, expandedSidebarWidth - 8, 0, 34) end
            end
        end
        if activeResize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartMouse
            local newWidth = main.Size.X.Offset
            local newHeight = main.Size.Y.Offset

            if activeResize == "right" or activeResize == "corner" then
                newWidth = math.max(resizeStartSize.X.Offset + delta.X, 350)
            end
            if activeResize == "bottom" or activeResize == "corner" then
                newHeight = math.max(resizeStartSize.Y.Offset + delta.Y, 250)
            end

            local deltaWidth = newWidth - resizeStartSize.X.Offset
            local deltaHeight = newHeight - resizeStartSize.Y.Offset

            targetX = resizeStartPos.X.Offset + (deltaWidth / 2)
            targetY = resizeStartPos.Y.Offset + (deltaHeight / 2)

            main.Size = UDim2.new(0, newWidth, 0, newHeight)
            currentX = targetX
            currentY = targetY
            main.Position = UDim2.new(0.5, currentX, 0.5, currentY)
        end
    end)



    local notif = Instance.new("Frame")
    notif.Name = "notif"
    notif.Parent = main
    notif.AnchorPoint = Vector2.new(0.5, 0.5)
    registerTheme(notif, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    notif.Position = UDim2.new(0.5, 0, 0.5, 0)
    notif.Size = UDim2.new(0, 304, 0, 362)
    notif.Visible = false
    notif.ZIndex = 101

    local uc_11 = Instance.new("UICorner")
    uc_11.CornerRadius = UDim.new(0, 18)
    uc_11.Parent = notif

    local notificon = Instance.new("ImageLabel")
    notificon.Name = "notificon"
    notificon.Parent = notif
    notificon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notificon.BackgroundTransparency = 1
    notificon.Position = UDim2.new(0.335526317, 0, 0.0994475111, 0)
    notificon.Size = UDim2.new(0, 100, 0, 100)
    notificon.ZIndex = 102
    notificon.Image = "rbxassetid://4871684504"
    notificon.ImageColor3 = Color3.fromRGB(95, 95, 95)

    local notifbutton1 = Instance.new("TextButton")
    notifbutton1.Name = "notifbutton1"
    notifbutton1.Parent = notif
    notifbutton1.BackgroundColor3 = currentAccentColor
    notifbutton1.Position = UDim2.new(0.0559210554, 0, 0.817679524, 0)
    notifbutton1.Size = UDim2.new(0, 270, 0, 50)
    notifbutton1.ZIndex = 102
    notifbutton1.Font = Enum.Font.Gotham
    notifbutton1.Text = "OK"
    notifbutton1.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifbutton1.TextSize = 21

    local uc_12 = Instance.new("UICorner")
    uc_12.CornerRadius = UDim.new(0, 9)
    uc_12.Parent = notifbutton1

    local notifshadow = Instance.new("ImageLabel")
    notifshadow.Name = "notifshadow"
    notifshadow.Parent = notif
    notifshadow.AnchorPoint = Vector2.new(0.5, 0.5)
    notifshadow.BackgroundTransparency = 1
    notifshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    notifshadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
    notifshadow.Image = "rbxassetid://313486536"
    notifshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)

    local notifdarkness = Instance.new("Frame")
    notifdarkness.Name = "notifdarkness"
    notifdarkness.Parent = main
    notifdarkness.AnchorPoint = Vector2.new(0.5, 0.5)
    notifdarkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notifdarkness.BackgroundTransparency = 0.600
    notifdarkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    notifdarkness.Size = UDim2.new(0, 721, 0, 584)
    notifdarkness.ZIndex = 100
    notifdarkness.Visible = false

    local uc_13 = Instance.new("UICorner")
    uc_13.CornerRadius = UDim.new(0, 18)
    uc_13.Parent = notifdarkness

    local keybindPromptFrame = Instance.new("Frame")
    keybindPromptFrame.Name = "keybindPromptFrame"
    keybindPromptFrame.Parent = main
    keybindPromptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    registerTheme(keybindPromptFrame, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    keybindPromptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    keybindPromptFrame.Size = UDim2.new(0, 304, 0, 160)
    keybindPromptFrame.Visible = false
    keybindPromptFrame.ZIndex = 101

    local uc_kp = Instance.new("UICorner")
    uc_kp.CornerRadius = UDim.new(0, 18)
    uc_kp.Parent = keybindPromptFrame

    local kpTitle = Instance.new("TextLabel")
    kpTitle.Name = "kpTitle"
    kpTitle.Parent = keybindPromptFrame
    kpTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kpTitle.BackgroundTransparency = 1
    kpTitle.Position = UDim2.new(0, 0, 0, 30)
    kpTitle.Size = UDim2.new(1, 0, 0, 50)
    kpTitle.ZIndex = 102
    kpTitle.Font = Enum.Font.GothamMedium
    kpTitle.Text = "Press a key to bind..."
    registerTheme(kpTitle, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    kpTitle.TextSize = 24

    local kpSub = Instance.new("TextLabel")
    kpSub.Name = "kpSub"
    kpSub.Parent = keybindPromptFrame
    kpSub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kpSub.BackgroundTransparency = 1
    kpSub.Position = UDim2.new(0, 0, 0, 80)
    kpSub.Size = UDim2.new(1, 0, 0, 30)
    kpSub.ZIndex = 102
    kpSub.Font = Enum.Font.Gotham
    kpSub.Text = "Press ESC to cancel"
    registerTheme(kpSub, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(150, 150, 170))
    kpSub.TextSize = 16

    local notiftitle = Instance.new("TextLabel")
    notiftitle.Name = "notiftitle"
    notiftitle.Parent = notif
    notiftitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notiftitle.BackgroundTransparency = 1
    notiftitle.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    notiftitle.Size = UDim2.new(0, 200, 0, 50)
    notiftitle.ZIndex = 102
    notiftitle.Font = Enum.Font.GothamMedium
    notiftitle.Text = "Notice"
    registerTheme(notiftitle, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    notiftitle.TextSize = 28

    local notiftext = Instance.new("TextLabel")
    notiftext.Name = "notiftext"
    notiftext.Parent = notif
    notiftext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notiftext.BackgroundTransparency = 1
    notiftext.Position = UDim2.new(0.0822368413, 0, 0.513812184, 0)
    notiftext.Size = UDim2.new(0, 254, 0, 66)
    notiftext.ZIndex = 102
    notiftext.Font = Enum.Font.Gotham
    notiftext.Text = "We would like to contact you regarding your car's extended warranty."
    registerTheme(notiftext, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    notiftext.TextSize = 16
    notiftext.TextWrapped = true

    local notif2 = Instance.new("Frame")
    notif2.Name = "notif2"
    notif2.Parent = main
    notif2.AnchorPoint = Vector2.new(0.5, 0.5)
    registerTheme(notif2, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    notif2.Position = UDim2.new(0.5, 0, 0.5, 0)
    notif2.Size = UDim2.new(0, 304, 0, 362)
    notif2.Visible = false
    notif2.ZIndex = 101

    local uc_14 = Instance.new("UICorner")
    uc_14.CornerRadius = UDim.new(0, 18)
    uc_14.Parent = notif2

    local notif2icon = Instance.new("ImageLabel")
    notif2icon.Name = "notif2icon"
    notif2icon.Parent = notif2
    notif2icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notif2icon.BackgroundTransparency = 1
    notif2icon.Position = UDim2.new(0.335526317, 0, 0.0994475111, 0)
    notif2icon.Size = UDim2.new(0, 100, 0, 100)
    notif2icon.ZIndex = 102
    notif2icon.Image = "rbxassetid://12608260095"
    notif2icon.ImageColor3 = Color3.fromRGB(95, 95, 95)

    local notif2title = Instance.new("TextLabel")
    notif2title.Name = "notif2title"
    notif2title.Parent = notif2
    notif2title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notif2title.BackgroundTransparency = 1
    notif2title.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    notif2title.Size = UDim2.new(0, 200, 0, 50)
    notif2title.ZIndex = 102
    notif2title.Font = Enum.Font.GothamMedium
    notif2title.Text = "Notice"
    registerTheme(notif2title, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    notif2title.TextSize = 28

    local notif2text = Instance.new("TextLabel")
    notif2text.Name = "notif2text"
    notif2text.Parent = notif2
    notif2text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notif2text.BackgroundTransparency = 1
    notif2text.Position = UDim2.new(0.0822368413, 0, 0.513812184, 0)
    notif2text.Size = UDim2.new(0, 254, 0, 66)
    notif2text.ZIndex = 102
    notif2text.Font = Enum.Font.Gotham
    notif2text.Text = "We would like to contact you regarding your car's extended warranty."
    registerTheme(notif2text, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    notif2text.TextSize = 16
    notif2text.TextWrapped = true

    local notif2button1 = Instance.new("TextButton")
    notif2button1.Name = "notif2button1"
    notif2button1.Parent = notif2
    notif2button1.BackgroundColor3 = currentAccentColor
    notif2button1.Position = UDim2.new(0.0559210517, 0, 0.715469658, 0)
    notif2button1.Size = UDim2.new(0, 270, 0, 40)
    notif2button1.ZIndex = 102
    notif2button1.Font = Enum.Font.Gotham
    notif2button1.Text = "Sure!"
    notif2button1.TextColor3 = Color3.fromRGB(255, 255, 255)
    notif2button1.TextSize = 21

    local uc_15 = Instance.new("UICorner")
    uc_15.CornerRadius = UDim.new(0, 9)
    uc_15.Parent = notif2button1

    local notif2shadow = Instance.new("ImageLabel")
    notif2shadow.Name = "notif2shadow"
    notif2shadow.Parent = notif2
    notif2shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    notif2shadow.BackgroundTransparency = 1
    notif2shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    notif2shadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
    notif2shadow.Image = "rbxassetid://313486536"
    notif2shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)

    local notif2darkness = Instance.new("Frame")
    notif2darkness.Name = "notif2darkness"
    notif2darkness.Parent = main
    notif2darkness.AnchorPoint = Vector2.new(0.5, 0.5)
    notif2darkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notif2darkness.BackgroundTransparency = 0.600
    notif2darkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    notif2darkness.Size = UDim2.new(0, 721, 0, 584)
    notif2darkness.ZIndex = 100
    notif2darkness.Visible = false

    local uc_16 = Instance.new("UICorner")
    uc_16.CornerRadius = UDim.new(0, 18)
    uc_16.Parent = notif2darkness

    local notif2button2 = Instance.new("TextButton")
    notif2button2.Name = "notif2button2"
    notif2button2.Parent = notif2
    notif2button2.BackgroundColor3 = currentAccentColor
    notif2button2.BackgroundTransparency = 1
    notif2button2.Position = UDim2.new(0.0526315793, 0, 0.842541456, 0)
    notif2button2.Size = UDim2.new(0, 270, 0, 40)
    notif2button2.ZIndex = 102
    notif2button2.Font = Enum.Font.Gotham
    notif2button2.Text = "Go away."
    registerTheme(notif2button2, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    notif2button2.TextSize = 21

    local uc_17 = Instance.new("UICorner")
    uc_17.CornerRadius = UDim.new(0, 9)
    uc_17.Parent = notif2button2

    if ti then
        title.Text = ti
    else
        title.Text = ""
    end

    tp(main, UDim2.new(0.5, 0, 0.5, 0), 1)
    window = {}



    local originalMouseIconEnabled = true
    local originalMouseBehavior = Enum.MouseBehavior.Default

    local cursorRenderName = "AppleLibMouseUnlock"
    pcall(function() RunService:UnbindFromRenderStep(cursorRenderName) end)
    RunService:BindToRenderStep(cursorRenderName, 2000, function() -- 2000 is late enough to override CoreGui
        if visible then
            -- Allow user to right-click drag the camera in third person without fighting the loop
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end)

    local lastX, lastY = 0, 0
    -- toggle ui visibility
    function window:PromptKeybind(callback, flag)
        if isPromptingKeybind then return end
        isPromptingKeybind = true
        keybindPromptCallback = callback
        keybindPromptElementName = flag or "Unknown"
        if kpTitle then kpTitle.Text = "Binding: " .. (flag or "") end
        if kpSub then kpSub.Text = "Press a key... [ESC to cancel]" end
        if notifdarkness then 
            notifdarkness.ZIndex = 100
            notifdarkness.Visible = true 
        end
        if keybindPromptFrame then keybindPromptFrame.Visible = true end
    end
    
    function window:ToggleVisible()
        if dbcooper then return end
        if not visible then
            originalMouseIconEnabled = UserInputService.MouseIconEnabled
        end
        visible = not visible
        dbcooper = true
        isAnimatingVis = true
        
        modalUnlocker.Modal = visible
        
        if visible then
            if blurEnabled then
                blur:BindFrame(blurFrame, {
                    Transparency = 0.98,
                    Color = Color3.fromRGB(255, 255, 255)
                })
            end
            targetX = lastX
            targetY = lastY
            task.delay(0.5, function() 
                dbcooper = false 
                isAnimatingVis = false 
            end)
        else
            if blur:HasBinding(blurFrame) then
                blur:UnbindFrame(blurFrame)
            end
            lastX = targetX
            lastY = targetY
            targetY = 2000
            task.delay(0.5, function() 
                dbcooper = false 
                isAnimatingVis = false 
            end)
        end
    end

    local visibleKeyConn
    local function rebindVisibleKey(newKey)
        if visibleKeyConn then visibleKeyConn:Disconnect() end
        visiblekey = newKey
        visibleKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == visiblekey then
                window:ToggleVisible()
            end
        end)
    end
    if visiblekey then
        minimize.MouseButton1Click:Connect(function()
            window:ToggleVisible()
        end)
        rebindVisibleKey(visiblekey)
    end



    local activeNotifs = {}
    local notifBaseY = isMob and 0.15 or 0.08
    local notifSpacing = isMob and 85 or 105

    -- temp notif
    function window:TempNotify(text1, text2, icon)
        for b,v in next, scrgui:GetChildren() do
            if v.Name == "tempnotif" then 
                -- Snap instantly to avoid X-axis tween overlap bugs when spammed
                v.Position = v.Position + UDim2.new(0,0,0,130)
            end
        end
        local tempnotif = Instance.new("Frame")
        tempnotif.Name = "tempnotif"
        tempnotif.Parent = scrgui
        tempnotif.AnchorPoint = Vector2.new(0.5, 0.5)
        registerTheme(tempnotif, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
        tempnotif.BackgroundTransparency = 0.150
        tempnotif.Position = UDim2.new(1, -250, 0.0794737339, 0)
        tempnotif.Size = UDim2.new(0, 447, 0, 117)
        tempnotif.Visible = true
        tempnotif.ZIndex = 101

        local uc_21 = Instance.new("UICorner")
        uc_21.CornerRadius = UDim.new(0, 18)
        uc_21.Parent = tempnotif

        local t2 = Instance.new("TextLabel")
        t2.Name = "t2"
        t2.Parent = tempnotif
        t2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        t2.BackgroundTransparency = 1
        t2.Position = UDim2.new(0.236927822, 0, 0.470085472, 0)
        t2.Size = UDim2.new(0, 326, 0, 52)
        t2.ZIndex = 102
        t2.Font = Enum.Font.Gotham
        t2.Text = text2
        registerTheme(t2, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        t2.TextSize = 16
        t2.TextWrapped = true
        t2.TextXAlignment = Enum.TextXAlignment.Left
        t2.TextYAlignment = Enum.TextYAlignment.Top

        local t1 = Instance.new("TextLabel")
        t1.Name = "t1"
        t1.Parent = tempnotif
        t1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        t1.BackgroundTransparency = 1
        t1.Position = UDim2.new(0.234690696, 0, 0.193464488, 0)
        t1.Size = UDim2.new(0, 327, 0, 25)
        t1.ZIndex = 102
        t1.Font = Enum.Font.GothamMedium
        t1.Text = text1
        registerTheme(t1, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        t1.TextSize = 28
        t1.TextXAlignment = Enum.TextXAlignment.Left

        local ticon = Instance.new("ImageLabel")
        ticon.Name = "ticon"
        ticon.Parent = tempnotif
        ticon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ticon.BackgroundTransparency = 1
        ticon.Position = UDim2.new(0.0311112702, 0, 0.193464488, 0)
        ticon.Size = UDim2.new(0, 71, 0, 71)
        ticon.ZIndex = 102
        resolveIcon(ticon, icon)
        registerTheme(ticon, "ImageColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        ticon.ScaleType = Enum.ScaleType.Fit

        local tshadow = Instance.new("ImageLabel")
        tshadow.Name = "tshadow"
        tshadow.Parent = tempnotif
        tshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        tshadow.BackgroundTransparency = 1
        tshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        tshadow.Size = UDim2.new(1.12, 0, 1.20000005, 0)
        tshadow.ZIndex = 100
        tshadow.Image = "rbxassetid://313486536"
        tshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        tshadow.ImageTransparency = 0.400
        tshadow.TileSize = UDim2.new(0, 1, 0, 1)
        
        -- Snap in exactly like original to prevent spam bugs
        tempnotif.Position = UDim2.new(1, -250, 0.0794737339, 0)

        -- Slide out animation after 4.5 seconds, then destroy at 5 seconds
        task.delay(4.5, function()
            if tempnotif and tempnotif.Parent then
                TweenService:Create(tempnotif, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, 250, tempnotif.Position.Y.Scale, tempnotif.Position.Y.Offset)
                }):Play()
                game:GetService("Debris"):AddItem(tempnotif, 0.5)
            end
        end)
    end

    function window:Notify(txt1, txt2, b1, icohn, callback)
        if notif.Visible == true or notif2.Visible == true then return "Already visible" end
        notiftitle.Text = txt1
        notiftext.Text = txt2
        resolveIcon(notificon, icohn)
        if not notif:FindFirstChild("notifScale") then
            local notifScale = Instance.new("UIScale")
            notifScale.Name = "notifScale"
            notifScale.Parent = notif
        end
        local notifScale = notif.notifScale
        
        notif.Size = UDim2.new(0, 304, 0, 362)
        notifScale.Scale = 0.8
        notif.Position = UDim2.new(0.5, 0, 0.5, 40)
        notifdarkness.Visible = true
        notif.Visible = true
        notifbutton1.Text = b1

        TweenService:Create(notifScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        con1 = notifbutton1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if callback then callback() end
            TweenService:Create(notifScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif.Visible = false
                notifdarkness.Visible = false
            end)
        end)
    end

    -- two btn notif
    function window:Notify2(txt1, txt2, b1, b2, icohn, callback, callback2)
        if notif.Visible == true or notif2.Visible == true then return "Already visible" end
        notif2title.Text = txt1
        notif2text.Text = txt2
        resolveIcon(notif2icon, icohn)
        if not notif2:FindFirstChild("notif2Scale") then
            local notif2Scale = Instance.new("UIScale")
            notif2Scale.Name = "notif2Scale"
            notif2Scale.Parent = notif2
        end
        local notif2Scale = notif2.notif2Scale
        
        notif2.Size = UDim2.new(0, 304, 0, 362)
        notif2Scale.Scale = 0.8
        notif2.Position = UDim2.new(0.5, 0, 0.5, 40)
        notif2darkness.Visible = true
        notif2.Visible = true
        notif2button1.Text = b1
        notif2button2.Text = b2

        TweenService:Create(notif2Scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(notif2, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        con1 = notif2button1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback then callback() end
            TweenService:Create(notif2Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif2.Visible = false
                notif2darkness.Visible = false
            end)
        end)
        con2 = notif2button2.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback2 then callback2() end
            TweenService:Create(notif2Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif2.Visible = false
                notif2darkness.Visible = false
            end)
        end)
    end

    function window:Divider(name, isExtra)
        local sidebardivider = Instance.new("TextLabel")
        sidebardivider.Name = "sidebardivider"
        sidebardivider.Parent = sidebar
        sidebardivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sidebardivider.BackgroundTransparency = 1
        sidebardivider.BorderSizePixel = 2
        sidebardivider.Position = UDim2.new(0, 0, 0.00215982716, 0)
        sidebardivider.Size = UDim2.new(0, isSidebarCollapsed and 34 or (expandedSidebarWidth - 7), 0, 20)
        sidebardivider.Font = Enum.Font.GothamBold
        sidebardivider.Text = name
        registerTheme(sidebardivider, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
        sidebardivider.TextSize = 11
        sidebardivider.TextWrapped = true
        sidebardivider.TextXAlignment = Enum.TextXAlignment.Left
        sidebardivider.TextYAlignment = Enum.TextYAlignment.Bottom

        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Parent = sidebardivider
        line.Size = UDim2.new(0, 30, 0, 2)
        line.Position = UDim2.new(0.5, 0, 0.5, 0)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundTransparency = 1
        line.BorderSizePixel = 0
        registerTheme(line, "BackgroundColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))

        if isExtra then
            table.insert(extraTabs, {IsDivider = true, Label = sidebardivider})
            sidebardivider.Visible = false
        else
            table.insert(mainTabs, {IsDivider = true, Label = sidebardivider})
        end
    end

    -- new section
    function window:Section(name, iconId, isExtra)
        local sidebar2 = Instance.new("TextButton")
        sidebar2.ClipsDescendants = true
        sidebar2.Name = "sidebar2"
        sidebar2.Parent = sidebar
        local bgL = Color3.fromRGB(0, 0, 0)
        local bgD = Color3.fromRGB(255, 255, 255)
        local txtL = Color3.fromRGB(100, 100, 100)
        local txtD = Color3.fromRGB(140, 140, 155)

        sidebar2.BackgroundColor3 = (currentTheme == "light") and bgL or bgD
        sidebar2.BackgroundTransparency = 0.93
        sidebar2.Size = UDim2.new(0, isSidebarCollapsed and 34 or (expandedSidebarWidth - 7), 0, 34)
        sidebar2.ZIndex = 20
        sidebar2.AutoButtonColor = false
        sidebar2.Font = Enum.Font.GothamMedium
        sidebar2.Text = name
        sidebar2.TextColor3 = (currentTheme == "light") and txtL or txtD
        sidebar2.TextSize = 15

        if iconId then
            sidebar2.TextXAlignment = Enum.TextXAlignment.Left
            local uipadding = Instance.new("UIPadding")
            uipadding.PaddingLeft = UDim.new(0, 40)
            uipadding.Parent = sidebar2

            local iconImg = Instance.new("ImageLabel")
            iconImg.Name = "iconImg"
            iconImg.Size = UDim2.new(0, 18, 0, 18)
            iconImg.Position = UDim2.new(0, -16, 0.5, 0)
            iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
            iconImg.BackgroundTransparency = 1
            iconImg.Parent = sidebar2
            iconImg.ZIndex = 20
            iconImg.Active = false
            resolveIcon(iconImg, iconId)
            registerTheme(iconImg, "ImageColor3", txtL, txtD)
        end

        local uc_10 = Instance.new("UICorner")
        uc_10.CornerRadius = UDim.new(0, 9)
        uc_10.Parent = sidebar2
        table.insert(sections, sidebar2)

        local workareamain = Instance.new("ScrollingFrame")
        workareamain.Name = "workareamain"
        workareamain.Parent = workarea
        workareamain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        workareamain.BackgroundTransparency = 1
        workareamain.BorderSizePixel = 0
        workareamain.Position = UDim2.new(0, 0, 0, 56)
        workareamain.Size = UDim2.new(1, 0, 1, -72)
        workareamain.ZIndex = 3
        workareamain.CanvasSize = UDim2.new(0, 0, 0, 0)
        workareamain.AutomaticCanvasSize = Enum.AutomaticSize.Y
        workareamain.ScrollBarThickness = 2
        workareamain.Visible = false

        local ull = Instance.new("UIListLayout")
        ull.Parent = workareamain
        ull.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ull.SortOrder = Enum.SortOrder.LayoutOrder
        ull.Padding = UDim.new(0, 5)

        local uiPadding = Instance.new("UIPadding")
        uiPadding.Parent = workareamain
        uiPadding.PaddingLeft = UDim.new(0, 16)
        uiPadding.PaddingRight = UDim.new(0, 16)
        uiPadding.PaddingTop = UDim.new(0, 5)
        uiPadding.PaddingBottom = UDim.new(0, 5)

        table.insert(workareas, workareamain)

        local sec = {}
        sec.SearchableText = {}
        sec.ElementsList = {}
        sec.TabButton = sidebar2

        function sec:Select()
            if workareamain.Visible then return end

            for b, v in next, sections do
                v.BackgroundColor3 = (currentTheme == "light") and bgL or bgD
                v.BackgroundTransparency = 0.93
                v.TextColor3 = (currentTheme == "light") and txtL or txtD
                v.Name = "sidebar2"
                local ico = v:FindFirstChild("iconImg")
                if ico then
                    ico.ImageColor3 = (currentTheme == "light") and txtL or txtD
                end
            end
            sidebar2.BackgroundTransparency = 1
            sidebar2.TextColor3 = Color3.fromRGB(255, 255, 255)
            sidebar2.Name = "sidebar2_selected"
            local myIco = sidebar2:FindFirstChild("iconImg")
            if myIco then
                myIco.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end

            local isNewHighlight = false
            local highlight = main:FindFirstChild("TabHighlight")
            if highlight then highlight.Visible = true end
            if not highlight then
                isNewHighlight = true
                highlight = Instance.new("Frame")
                highlight.Name = "TabHighlight"
                highlight.Parent = main
                highlight.BackgroundColor3 = currentAccentColor
                local currentHighlightWidth = isSidebarCollapsed and 34 or (expandedSidebarWidth - 7)
                highlight.Size = UDim2.new(0, currentHighlightWidth, 0, 34)
                highlight.ZIndex = 1
                local uc = Instance.new("UICorner", highlight)
                uc.CornerRadius = UDim.new(0, 9)
                table.insert(themeElements, {
                    Instance = highlight,
                    Property = "BackgroundColor3",
                    Light = currentAccentColor,
                    Dark = currentAccentColor
                })
                if not scrollSyncConnected then
                    scrollSyncConnected = true
                    sidebar:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                        local activeHighlight = main:FindFirstChild("TabHighlight")
                        if activeHighlight then
                            local activeTab = nil
                            for _, s in ipairs(sections) do
                                if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                                    activeTab = s
                                    break
                                end
                            end
                            if activeTab then
                                activeHighlight.Position = UDim2.new(0, activeTab.AbsolutePosition.X - main.AbsolutePosition.X, 0, activeTab.AbsolutePosition.Y - main.AbsolutePosition.Y)
                            end
                        end
                    end)
                end
            end

            local targetY = sidebar2.AbsolutePosition.Y - main.AbsolutePosition.Y
            local targetX = sidebar2.AbsolutePosition.X - main.AbsolutePosition.X
            local currentHighlightWidth = isSidebarCollapsed and 34 or (expandedSidebarWidth - 7)
            if isNewHighlight then
                highlight.Position = UDim2.new(0, targetX, 0, targetY)
                highlight.Size = UDim2.new(0, currentHighlightWidth, 0, 34)
            else
                TweenService:Create(highlight, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, targetX, 0, targetY),
                    Size = UDim2.new(0, currentHighlightWidth, 0, 34)
                }):Play()
            end

            for b, v in next, workareas do
                if v ~= workareamain then
                    v.Visible = false
                end
            end
            workareamain.Visible = true
            workareamain.Position = UDim2.new(0, 0, 0, 76)
            TweenService:Create(workareamain, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 56)
            }):Play()
        end

        function sec:GetContainer()
            return workareamain
        end

        -- div
        function sec:Divider(name)
            local section = Instance.new("TextLabel")
            section.Name = "section"
            section.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = section })
            section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            section.BackgroundTransparency = 1
            section.BorderSizePixel = 2
            section.Size = UDim2.new(1, 0, 0, 50)
            section.Font = Enum.Font.GothamBold
            section.LineHeight = 1.180
            section.Text = name
            registerTheme(section, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
            section.TextSize = 13
            section.TextWrapped = true
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.TextYAlignment = Enum.TextYAlignment.Bottom
        end

        -- btn
        function sec:Button(name, callback)
            table.insert(sec.SearchableText, string.upper(name))
            local flag = name
            registeredElements[flag] = callback
            
            local button = Instance.new("TextButton")
            button.Name = "button"
            button.Text = name
            button.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = button })
            button.Size = UDim2.new(1, 0, 0, 37)
            button.ZIndex = 20
            button.Font = Enum.Font.GothamBold
            button.TextSize = 14
            
            local uc_3 = Instance.new("UICorner")
            uc_3.Parent = button

            if lib.ButtonStyle == "Glossy" then
                button.BackgroundColor3 = currentAccentColor
                button.BackgroundTransparency = 0
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                uc_3.CornerRadius = UDim.new(0, 12)
                
                local grad2 = Instance.new("UIGradient", button)
                grad2.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(0.49, Color3.new(0.8, 0.8, 0.8)),
                    ColorSequenceKeypoint.new(0.50, Color3.new(0.6, 0.6, 0.6)),
                    ColorSequenceKeypoint.new(1.00, Color3.new(0.5, 0.5, 0.5))
                })
                grad2.Rotation = 90
            else
                button.BackgroundColor3 = currentAccentColor
                button.BackgroundTransparency = 0
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                uc_3.CornerRadius = UDim.new(0, 8)
            end

            local ogSize = UDim2.new(1, 0, 0, 37)
            button.MouseButton1Down:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -6, 0, 35)}):Play()
            end)
            button.MouseButton1Up:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = ogSize}):Play()
            end)
            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.1), {Size = ogSize}):Play()
            end)

            button.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            
            button.MouseButton2Click:Connect(function()
                window:PromptKeybind(callback, flag)
            end)
        end

        function sec:Label(name)
            table.insert(sec.SearchableText, string.upper(name))
            local label = Instance.new("TextLabel")
            label.Name = "label"
            label.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = label })
            label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            label.BackgroundTransparency = 1
            label.BorderSizePixel = 2
            label.Size = UDim2.new(1, 0, 0, 37)
            label.Font = Enum.Font.GothamMedium
            registerTheme(label, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
            label.TextSize = 16
            label.TextWrapped = true
            label.Text = name
        end

        -- switch
        function sec:Switch(name, defaultmode, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            flag = flag or name
            local mode = (ConfigManager.Elements[flag] ~= nil and ConfigManager.Elements[flag].Value ~= nil) and ConfigManager.Elements[flag].Value or defaultmode
            table.insert(cleanupToggles, { default = defaultmode, callback = callback })
            local toggleswitch = Instance.new("Frame")
            toggleswitch.Name = "toggleswitch"
            toggleswitch.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = toggleswitch })
            toggleswitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleswitch.BackgroundTransparency = 1
            toggleswitch.BorderSizePixel = 0
            toggleswitch.Size = UDim2.new(1, 0, 0, 37)

            local switchlabel = Instance.new("TextLabel")
            switchlabel.Name = "switchlabel"
            switchlabel.Parent = toggleswitch
            switchlabel.BackgroundTransparency = 1
            switchlabel.Size = UDim2.new(1, -60, 1, 0)
            switchlabel.Font = Enum.Font.GothamMedium
            switchlabel.Text = name
            registerTheme(switchlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            switchlabel.TextSize = 16
            switchlabel.TextWrapped = true
            switchlabel.TextXAlignment = Enum.TextXAlignment.Left

            local Frame = Instance.new("TextButton")
            Frame.Parent = toggleswitch
            Frame.ZIndex = 20
            Frame.Position = UDim2.new(1, -56, 0.5, -14)
            Frame.Size = UDim2.new(0, 56, 0, 28)
            Frame.Text = ""
            Frame.AutoButtonColor = false

            local uc_4 = Instance.new("UICorner")
            uc_4.CornerRadius = UDim.new(5, 0)
            uc_4.Parent = Frame

            local TextButton = Instance.new("TextButton")
            TextButton.Parent = Frame
            TextButton.ZIndex = 21
            TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextButton.Size = UDim2.new(0, 26, 0, 26)
            TextButton.AutoButtonColor = false
            TextButton.Text = ""

            local uc_5 = Instance.new("UICorner")
            uc_5.CornerRadius = UDim.new(5, 0)
            uc_5.Parent = TextButton

            local function updateSwitchVisual()
                if mode == false then
                    TextButton.Position = UDim2.new(0, 1, 0, 1)
                    Frame.BackgroundColor3 = (currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                else
                    TextButton.Position = UDim2.new(0, 29, 0, 1)
                    Frame.BackgroundColor3 = currentAccentColor
                end
            end

            updateSwitchVisual()
            if callback then
                pcall(callback, mode)
            end

            local function toggle()
                mode = not mode
                if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = mode end
                if type(flag) == "string" and string.find(flag, "^Settings_") then ConfigManager:SaveUISettings() end
                if callback then callback(mode) end
                if mode then
                    TextButton:TweenPosition(UDim2.new(0, 29, 0, 1), "In", "Sine", 0.1, true)
                    Frame.BackgroundColor3 = currentAccentColor
                else
                    TextButton:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
                    Frame.BackgroundColor3 = (currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                end
            end
            
            
            table.insert(themeElements, {
                Instance = Frame,
                Property = "BackgroundColor3",
                Light = Color3.fromRGB(216, 216, 216),
                Dark = Color3.fromRGB(60, 60, 60),
                IsToggle = true,
                GetToggleState = function() return mode end
            })

            Frame.MouseButton1Click:Connect(toggle)
            TextButton.MouseButton1Click:Connect(toggle)

            Frame.MouseButton2Click:Connect(function()
                window:PromptKeybind(toggle, flag)
            end)
            TextButton.MouseButton2Click:Connect(function()
                window:PromptKeybind(toggle, flag)
            end)
            
            registeredElements[flag] = toggle

            ConfigManager.Elements[flag] = { Value = mode, Set = function(self, val) if mode ~= val then toggle() end end }
        end

        -- text box
        function sec:TextField(name, placeholder, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            flag = flag or name
            local textfield = Instance.new("Frame")
            textfield.Name = "textfield"
            textfield.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = textfield })
            textfield.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            textfield.BackgroundTransparency = 1
            textfield.BorderSizePixel = 0
            textfield.Size = UDim2.new(1, 0, 0, 37)

            local textfieldlabel = Instance.new("TextLabel")
            textfieldlabel.Name = "textfieldlabel"
            textfieldlabel.Parent = textfield
            textfieldlabel.BackgroundTransparency = 1
            textfieldlabel.Size = UDim2.new(1, -240, 1, 0)
            textfieldlabel.Font = Enum.Font.GothamMedium
            textfieldlabel.Text = name
            registerTheme(textfieldlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            textfieldlabel.TextSize = 16
            textfieldlabel.TextWrapped = true
            textfieldlabel.TextXAlignment = Enum.TextXAlignment.Left

            local Frame_2 = Instance.new("Frame")
            Frame_2.Parent = textfield
            registerTheme(Frame_2, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            Frame_2.Position = UDim2.new(1, -233, 0.5, -17)
            Frame_2.Size = UDim2.new(0, 233, 0, 34)

            local uc_6 = Instance.new("UICorner")
            uc_6.CornerRadius = UDim.new(0, 8)
            uc_6.Parent = Frame_2

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = Frame_2
            TextBox.ZIndex = 20
            TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextBox.BackgroundTransparency = 1
            TextBox.BorderColor3 = Color3.fromRGB(27, 42, 53)
            TextBox.BorderSizePixel = 0
            TextBox.ClipsDescendants = true
            TextBox.Position = UDim2.new(0.0643776804, 0, 0, -2)
            TextBox.Size = UDim2.new(0, 203, 0, 34)
            TextBox.ClearTextOnFocus = false
            TextBox.Font = Enum.Font.GothamMedium
            TextBox.LineHeight = 0.870
            TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
            TextBox.PlaceholderText = placeholder or "Type..."
            TextBox.Text = ""
            registerTheme(TextBox, "TextColor3", Color3.fromRGB(160, 160, 180), Color3.fromRGB(140, 140, 155))
            TextBox.TextSize = 15
            TextBox.TextXAlignment = Enum.TextXAlignment.Left

            ConfigManager.Elements[flag] = { Value = TextBox.Text, Set = function(self, val) TextBox.Text = val; if callback then callback(val) end end }
            if callback then
                TextBox.FocusLost:Connect(function()
                    if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = TextBox.Text end
                    callback(TextBox.Text)
                end)
            end
        end

        -- slider
        function sec:Slider(name, min, max, default, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            flag = flag or name
            default = (ConfigManager.Elements[flag] ~= nil and ConfigManager.Elements[flag].Value ~= nil) and ConfigManager.Elements[flag].Value or default
            local sliderrow = Instance.new("Frame")
            sliderrow.Name = "sliderrow"
            sliderrow.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = sliderrow })
            sliderrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sliderrow.BackgroundTransparency = 1
            sliderrow.BorderSizePixel = 0
            sliderrow.Size = UDim2.new(1, 0, 0, 37)

            local sliderlabel = Instance.new("TextLabel")
            sliderlabel.Name = "sliderlabel"
            sliderlabel.Parent = sliderrow
            sliderlabel.BackgroundTransparency = 1
            sliderlabel.Size = UDim2.new(1, -250, 1, 0)
            sliderlabel.Font = Enum.Font.GothamMedium
            sliderlabel.Text = name
            registerTheme(sliderlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            sliderlabel.TextSize = 16
            sliderlabel.TextWrapped = true
            sliderlabel.TextXAlignment = Enum.TextXAlignment.Left

            local valuelabel = Instance.new("TextLabel")
            valuelabel.Name = "valuelabel"
            valuelabel.Parent = sliderrow
            valuelabel.BackgroundTransparency = 1
            valuelabel.Position = UDim2.new(1, -55, 0, 0)
            valuelabel.Size = UDim2.new(0, 55, 1, 0)
            valuelabel.Font = Enum.Font.GothamMedium
            valuelabel.Text = tostring(default)
            valuelabel.TextColor3 = currentAccentColor
            valuelabel.TextSize = 19
            valuelabel.TextXAlignment = Enum.TextXAlignment.Right

            local rail = Instance.new("Frame")
            rail.Name = "rail"
            rail.Parent = sliderrow
            registerTheme(rail, "BackgroundColor3", Color3.fromRGB(200, 200, 215), Color3.fromRGB(45, 45, 58))
            rail.Position = UDim2.new(1, -240, 0.5, -3)
            rail.Size = UDim2.new(0, 180, 0, 4)
            rail.BorderSizePixel = 0

            local uc_r = Instance.new("UICorner")
            uc_r.CornerRadius = UDim.new(1, 0)
            uc_r.Parent = rail

            local fill = Instance.new("Frame")
            fill.Name = "fill"
            fill.Parent = rail
            fill.BackgroundColor3 = currentAccentColor
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(0, 0, 1, 0)

            local uc_f = Instance.new("UICorner")
            uc_f.CornerRadius = UDim.new(1, 0)
            uc_f.Parent = fill

            local thumb = Instance.new("TextButton")
            thumb.Name = "thumb"
            thumb.Parent = rail
            thumb.BackgroundColor3 = currentAccentColor
            thumb.Size = UDim2.new(0, 14, 0, 14)
            thumb.Position = UDim2.new(0, -7, 0.5, -7)
            thumb.Text = ""
            thumb.AutoButtonColor = false
            thumb.ZIndex = 20
            thumb.BorderSizePixel = 0

            local uc_t = Instance.new("UICorner")
            uc_t.CornerRadius = UDim.new(1, 0)
            uc_t.Parent = thumb

            local currentValue = math.clamp(default, min, max)

            local function setValue(v)
                currentValue = math.clamp(math.round(v), min, max)
                if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
                if type(flag) == "string" and string.find(flag, "^Settings_") then ConfigManager:SaveUISettings() end
                local scale = (currentValue - min) / (max - min)
                fill.Size = UDim2.new(scale, 0, 1, 0)
                thumb.Position = UDim2.new(scale, -7, 0.5, -7)
                valuelabel.Text = tostring(currentValue)
                if callback then callback(currentValue) end
            end

            setValue(default)

            local draggingSlider = false

            thumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                end
            end)

            rail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    local relX = math.clamp(input.Position.X - rail.AbsolutePosition.X, 0, rail.AbsoluteSize.X)
                    setValue(min + (max - min) * (relX / rail.AbsoluteSize.X))
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local relX = math.clamp(input.Position.X - rail.AbsolutePosition.X, 0, rail.AbsoluteSize.X)
                    setValue(min + (max - min) * (relX / rail.AbsoluteSize.X))
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)
            ConfigManager.Elements[flag] = { Value = currentValue, Set = function(self, val) setValue(val) end }
        end

        -- drop list
        function sec:Dropdown(name, options, default, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            if type(options) == 'table' then for _, o in ipairs(options) do table.insert(sec.SearchableText, string.upper(tostring(o))) end end
            flag = flag or name
            default = (ConfigManager.Elements[flag] ~= nil and ConfigManager.Elements[flag].Value ~= nil) and ConfigManager.Elements[flag].Value or default
            local droprow = Instance.new("Frame")
            droprow.Name = "droprow"
            droprow.Parent = workareamain
            local searchStr = string.upper(name)
            if type(options) == "table" then for _, o in ipairs(options) do searchStr = searchStr .. " " .. string.upper(tostring(o)) end end
            table.insert(sec.ElementsList, { text = searchStr, gui = droprow })
            droprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            droprow.BackgroundTransparency = 1
            droprow.BorderSizePixel = 0
            droprow.Size = UDim2.new(1, 0, 0, 37)

            local droplabel_top = Instance.new("TextLabel")
            droplabel_top.Name = "droplabel_top"
            droplabel_top.Parent = droprow
            droplabel_top.BackgroundTransparency = 1
            droplabel_top.Size = UDim2.new(1, -240, 1, 0)
            droplabel_top.Font = Enum.Font.GothamMedium
            droplabel_top.Text = name
            registerTheme(droplabel_top, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            droplabel_top.TextSize = 16
            droplabel_top.TextWrapped = true
            droplabel_top.TextXAlignment = Enum.TextXAlignment.Left

            local dropbtn = Instance.new("TextButton")
            dropbtn.Name = "dropbtn"
            dropbtn.ZIndex = 20
            dropbtn.Parent = droprow
            registerTheme(dropbtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            dropbtn.Position = UDim2.new(1, -233, 0.5, -17)
            dropbtn.Size = UDim2.new(0, 233, 0, 34)
            dropbtn.Font = Enum.Font.Gotham
            local droplabel = Instance.new("TextLabel", dropbtn)
            droplabel.BackgroundTransparency = 1
            droplabel.Size = UDim2.new(1, -20, 1, 0)
            droplabel.Position = UDim2.new(0, 10, 0, 0)
            droplabel.Font = Enum.Font.Gotham
            droplabel.ZIndex = 21
            registerTheme(droplabel, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
            droplabel.TextSize = 14
            droplabel.TextXAlignment = Enum.TextXAlignment.Left
            dropbtn.AutoButtonColor = false
            dropbtn.Text = ""
            droplabel.Text = (default or (options[1] or ""))
            dropbtn.ClipsDescendants = true

            local uc_db = Instance.new("UICorner")
            uc_db.CornerRadius = UDim.new(0, 9)
            uc_db.Parent = dropbtn

            local arrow = Instance.new("TextLabel")
            arrow.Name = "arrow"
            arrow.Parent = dropbtn
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -28, 0, 0)
            arrow.Size = UDim2.new(0, 24, 1, 0)
            arrow.Font = Enum.Font.GothamMedium
            arrow.Text = "v"
            arrow.TextColor3 = Color3.fromRGB(95, 95, 95)
            arrow.TextSize = 14
            arrow.ZIndex = 21

            local currentValue = default or (options[1] or "")

            local listframe = Instance.new("ScrollingFrame")
            listframe.Name = "listframe"
            listframe.Parent = workareamain
            registerTheme(listframe, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
            listframe.BorderSizePixel = 0
            listframe.Size = UDim2.new(1, 0, 0, 0)
            listframe.ClipsDescendants = true
            listframe.Visible = false
            listframe.ZIndex = 30
            listframe.CanvasSize = UDim2.new(0, 0, 0, 0)
            listframe.AutomaticCanvasSize = Enum.AutomaticSize.Y
            listframe.ScrollBarThickness = 2
            listframe.ScrollBarImageColor3 = currentAccentColor

            local uc_lf = Instance.new("UICorner")
            uc_lf.CornerRadius = UDim.new(0, 9)
            uc_lf.Parent = listframe

            local listlayout = Instance.new("UIListLayout")
            listlayout.Parent = listframe
            listlayout.SortOrder = Enum.SortOrder.LayoutOrder
            listlayout.Padding = UDim.new(0, 2)

            local listpadding = Instance.new("UIPadding")
            listpadding.Parent = listframe
            listpadding.PaddingTop = UDim.new(0, 4)
            listpadding.PaddingBottom = UDim.new(0, 4)

            local opened = false

            local function closeList()
                opened = false
                arrow.Text = "v"
                TweenService:Create(listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.15)
                listframe.Visible = false
            end

            local function openList()
                opened = true
                arrow.Text = "^"
                local contentH = listlayout.AbsoluteContentSize.Y + 8
                local clampedH = math.min(contentH, 150)
                listframe.Visible = true
                listframe.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, clampedH)}):Play()
            end

            
            local DropdownObj = {}
            function DropdownObj:Refresh(newOptions)
                for _, child in ipairs(listframe:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                options = newOptions
                if #options > 0 then
                    currentValue = options[1]
                    droplabel.Text = currentValue
                    if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
                if type(flag) == "string" and string.find(flag, "^Settings_") then ConfigManager:SaveUISettings() end
                    if callback then callback(currentValue) end
                end
                for _, opt in ipairs(options) do
                    local optbtn = Instance.new("TextButton")
                    optbtn.Name = "optbtn"
                    optbtn.Parent = listframe
                    optbtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    optbtn.BackgroundTransparency = 1
                    optbtn.Size = UDim2.new(1, -8, 0, 30)
                    optbtn.Position = UDim2.new(0, 4, 0, 0)
                    optbtn.Font = Enum.Font.GothamMedium
                    optbtn.Text = opt
                    registerTheme(optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                    optbtn.TextSize = 14
                    optbtn.AutoButtonColor = false
                    optbtn.ZIndex = 35

                    local uc_ob = Instance.new("UICorner")
                    uc_ob.CornerRadius = UDim.new(0, 7)
                    uc_ob.Parent = optbtn

                    optbtn.MouseEnter:Connect(function()
                        TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                    end)
                    optbtn.MouseLeave:Connect(function()
                        TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    end)

                    optbtn.MouseButton1Click:Connect(function()
                        TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                        currentValue = opt
                        if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
                if type(flag) == "string" and string.find(flag, "^Settings_") then ConfigManager:SaveUISettings() end
                        droplabel.Text = opt
                        closeList()
                        if callback then callback(currentValue) end
                    end)
                end
            end
            -- Note: We do not call DropdownObj:Refresh(options) here initially to avoid firing the callback twice,
            -- we just manually construct the initial options.
            for _, opt in ipairs(options) do
                local optbtn = Instance.new("TextButton")
                optbtn.Name = "optbtn"
                optbtn.Parent = listframe
                optbtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                optbtn.BackgroundTransparency = 1
                optbtn.Size = UDim2.new(1, -8, 0, 30)
                optbtn.Position = UDim2.new(0, 4, 0, 0)
                optbtn.Font = Enum.Font.GothamMedium
                optbtn.Text = opt
                registerTheme(optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                optbtn.TextSize = 14
                optbtn.AutoButtonColor = false
                optbtn.ZIndex = 35

                local uc_ob = Instance.new("UICorner")
                uc_ob.CornerRadius = UDim.new(0, 7)
                uc_ob.Parent = optbtn

                optbtn.MouseEnter:Connect(function()
                    TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                end)
                optbtn.MouseLeave:Connect(function()
                    TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                end)

                optbtn.MouseButton1Click:Connect(function()
                    TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    currentValue = opt
                    if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
                if type(flag) == "string" and string.find(flag, "^Settings_") then ConfigManager:SaveUISettings() end
                    droplabel.Text = opt
                    closeList()
                    if callback then callback(currentValue) end
                end)
            end
            
            ConfigManager.Elements[flag] = { Value = currentValue, Set = function(self, val) currentValue = val; droplabel.Text = val; if callback then callback(val) end end }

            dropbtn.MouseButton1Click:Connect(function()
                if opened then
                    closeList()
                else
                    openList()
                end
            end)

            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and opened then
                    local absPos = dropbtn.AbsolutePosition
                    local absSize = dropbtn.AbsoluteSize
                    local mpos = Vector2.new(input.Position.X, input.Position.Y)
                    local inBtn = mpos.X >= absPos.X and mpos.X <= absPos.X + absSize.X and mpos.Y >= absPos.Y and mpos.Y <= absPos.Y + absSize.Y
                    local lPos = listframe.AbsolutePosition
                    local lSize = listframe.AbsoluteSize
                    local inList = mpos.X >= lPos.X and mpos.X <= lPos.X + lSize.X and mpos.Y >= lPos.Y and mpos.Y <= lPos.Y + lSize.Y
                    if not inBtn and not inList then
                        closeList()
                    end
                end
            end)
            return DropdownObj
        end

        -- multi drop list
        function sec:MultiDropdown(name, options, defaultOptions, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            if type(options) == 'table' then for _, o in ipairs(options) do table.insert(sec.SearchableText, string.upper(tostring(o))) end end
            flag = flag or name
            defaultOptions = defaultOptions or {}
            local droprow = Instance.new("Frame")
            droprow.Name = "droprow"
            droprow.Parent = workareamain
            local searchStr = string.upper(name)
            if type(options) == "table" then for _, o in ipairs(options) do searchStr = searchStr .. " " .. string.upper(tostring(o)) end end
            table.insert(sec.ElementsList, { text = searchStr, gui = droprow })
            droprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            droprow.BackgroundTransparency = 1
            droprow.BorderSizePixel = 0
            droprow.Size = UDim2.new(1, 0, 0, 37)

            local droplabel_top = Instance.new("TextLabel")
            droplabel_top.Name = "droplabel_top"
            droplabel_top.Parent = droprow
            droplabel_top.BackgroundTransparency = 1
            droplabel_top.Size = UDim2.new(1, -240, 1, 0)
            droplabel_top.Font = Enum.Font.GothamMedium
            droplabel_top.Text = name
            registerTheme(droplabel_top, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            droplabel_top.TextSize = 16
            droplabel_top.TextWrapped = true
            droplabel_top.TextXAlignment = Enum.TextXAlignment.Left

            local dropbtn = Instance.new("TextButton")
            dropbtn.Name = "dropbtn"
            dropbtn.ZIndex = 20
            dropbtn.Parent = droprow
            registerTheme(dropbtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            dropbtn.Position = UDim2.new(1, -233, 0.5, -17)
            dropbtn.Size = UDim2.new(0, 233, 0, 34)
            dropbtn.Font = Enum.Font.Gotham
            local droplabel = Instance.new("TextLabel", dropbtn)
            droplabel.BackgroundTransparency = 1
            droplabel.Size = UDim2.new(1, -20, 1, 0)
            droplabel.Position = UDim2.new(0, 10, 0, 0)
            droplabel.Font = Enum.Font.Gotham
            droplabel.ZIndex = 21
            registerTheme(droplabel, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
            droplabel.TextSize = 14
            droplabel.TextXAlignment = Enum.TextXAlignment.Left
            dropbtn.AutoButtonColor = false
            dropbtn.Text = ""
            dropbtn.ClipsDescendants = true

            local uc_db = Instance.new("UICorner")
            uc_db.CornerRadius = UDim.new(0, 9)
            uc_db.Parent = dropbtn

            local arrow = Instance.new("TextLabel")
            arrow.Name = "arrow"
            arrow.Parent = dropbtn
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -28, 0, 0)
            arrow.Size = UDim2.new(0, 24, 1, 0)
            arrow.Font = Enum.Font.GothamMedium
            arrow.Text = "v"
            arrow.TextColor3 = Color3.fromRGB(95, 95, 95)
            arrow.TextSize = 14
            arrow.ZIndex = 21

            local currentValues = {}
            for _, v in ipairs(defaultOptions) do table.insert(currentValues, v) end

            local function updateLabel()
                if #currentValues == 0 then
                    droplabel.Text = "None"
                else
                    droplabel.Text = table.concat(currentValues, ", ")
                end
            end
            updateLabel()

            local listframe = Instance.new("ScrollingFrame")
            listframe.Name = "listframe"
            listframe.Parent = workareamain
            registerTheme(listframe, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
            listframe.BorderSizePixel = 0
            listframe.Size = UDim2.new(1, 0, 0, 0)
            listframe.ClipsDescendants = true
            listframe.Visible = false
            listframe.ZIndex = 30
            listframe.CanvasSize = UDim2.new(0, 0, 0, 0)
            listframe.AutomaticCanvasSize = Enum.AutomaticSize.Y
            listframe.ScrollBarThickness = 2
            listframe.ScrollBarImageColor3 = currentAccentColor

            local uc_lf = Instance.new("UICorner")
            uc_lf.CornerRadius = UDim.new(0, 9)
            uc_lf.Parent = listframe

            local listlayout = Instance.new("UIListLayout")
            listlayout.Parent = listframe
            listlayout.SortOrder = Enum.SortOrder.LayoutOrder
            listlayout.Padding = UDim.new(0, 2)

            local listpadding = Instance.new("UIPadding")
            listpadding.Parent = listframe
            listpadding.PaddingTop = UDim.new(0, 4)
            listpadding.PaddingBottom = UDim.new(0, 4)

            local opened = false

            local function closeList()
                opened = false
                arrow.Text = "v"
                TweenService:Create(listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.15)
                listframe.Visible = false
            end

            local function openList()
                opened = true
                arrow.Text = "^"
                local contentH = listlayout.AbsoluteContentSize.Y + 8
                local clampedH = math.min(contentH, 150)
                listframe.Visible = true
                listframe.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, clampedH)}):Play()
            end

            local function isSelected(opt)
                for _, v in ipairs(currentValues) do
                    if v == opt then return true end
                end
                return false
            end

            local DropdownObj = {}
            function DropdownObj:Refresh(newOptions)
                for _, child in ipairs(listframe:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                options = newOptions
                for _, opt in ipairs(options) do
                    local optbtn = Instance.new("TextButton")
                    optbtn.Name = "optbtn"
                    optbtn.Parent = listframe
                    optbtn.BackgroundColor3 = currentAccentColor
                    optbtn.BackgroundTransparency = isSelected(opt) and 0 or 1
                    optbtn.Size = UDim2.new(1, -8, 0, 30)
                    optbtn.Position = UDim2.new(0, 4, 0, 0)
                    optbtn.Font = Enum.Font.GothamMedium
                    optbtn.Text = opt
                    
                    if isSelected(opt) then
                        optbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    else
                        registerTheme(optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                    end
                    
                    optbtn.TextSize = 14
                    optbtn.AutoButtonColor = false
                    optbtn.ZIndex = 35

                    local uc_ob = Instance.new("UICorner")
                    uc_ob.CornerRadius = UDim.new(0, 7)
                    uc_ob.Parent = optbtn

                    local isHovering = false
                    optbtn.MouseEnter:Connect(function()
                        isHovering = true
                        if not isSelected(opt) then
                            TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                        end
                    end)
                    optbtn.MouseLeave:Connect(function()
                        isHovering = false
                        if not isSelected(opt) then
                            TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                        end
                    end)

                    optbtn.MouseButton1Click:Connect(function()
                        if isSelected(opt) then
                            for i, v in ipairs(currentValues) do
                                if v == opt then table.remove(currentValues, i) break end
                            end
                            local targetTrans = isHovering and 0.5 or 1
                            TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = targetTrans}):Play()
                            registerTheme(optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                        else
                            table.insert(currentValues, opt)
                            TweenService:Create(optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
                            optbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                        updateLabel()
                        if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValues end
                        if callback then callback(currentValues) end
                    end)
                end
            end
            DropdownObj:Refresh(options)
            
            ConfigManager.Elements[flag] = { Value = currentValues, Set = function(self, val) currentValues = val; updateLabel(); DropdownObj:Refresh(options); if callback then callback(val) end end }

            dropbtn.MouseButton1Click:Connect(function()
                if opened then
                    closeList()
                else
                    openList()
                end
            end)

            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and opened then
                    local absPos = dropbtn.AbsolutePosition
                    local absSize = dropbtn.AbsoluteSize
                    local mpos = Vector2.new(input.Position.X, input.Position.Y)
                    local inBtn = mpos.X >= absPos.X and mpos.X <= absPos.X + absSize.X and mpos.Y >= absPos.Y and mpos.Y <= absPos.Y + absSize.Y
                    
                    local lPos = listframe.AbsolutePosition
                    local lSize = listframe.AbsoluteSize
                    local inList = mpos.X >= lPos.X and mpos.X <= lPos.X + lSize.X and mpos.Y >= lPos.Y and mpos.Y <= lPos.Y + lSize.Y
                    
                    if not inBtn and not inList then
                        closeList()
                    end
                end
            end)
            return DropdownObj
        end

        -- clr picker
        function sec:ColorPicker(name, default, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            flag = flag or name
            local cprow = Instance.new("Frame")
            cprow.Name = "cprow"
            cprow.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = cprow })
            cprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cprow.BackgroundTransparency = 1
            cprow.BorderSizePixel = 0
            cprow.Size = UDim2.new(1, 0, 0, 37)

            local cplabel = Instance.new("TextLabel")
            cplabel.Name = "cplabel"
            cplabel.Parent = cprow
            cplabel.BackgroundTransparency = 1
            cplabel.Size = UDim2.new(1, -80, 1, 0)
            cplabel.Font = Enum.Font.GothamMedium
            cplabel.Text = name
            registerTheme(cplabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            cplabel.TextSize = 16
            cplabel.TextWrapped = true
            cplabel.TextXAlignment = Enum.TextXAlignment.Left

            local preview = Instance.new("TextButton")
            preview.Name = "preview"
            preview.Parent = cprow
            preview.BackgroundColor3 = default or currentAccentColor
            preview.Position = UDim2.new(1, -70, 0.5, -14)
            preview.Size = UDim2.new(0, 70, 0, 28)
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.ZIndex = 20
            preview.BorderSizePixel = 0

            local uc_cp = Instance.new("UICorner")
            uc_cp.CornerRadius = UDim.new(0, 8)
            uc_cp.Parent = preview

            local us_cp = Instance.new("UIStroke", preview)
            us_cp.ApplyStrokeMode = "Border"
            us_cp.Color = currentAccentColor
            us_cp.Thickness = 1

            local currentColor = default or currentAccentColor
            local pickerOpen = false

            local pickerframe = Instance.new("Frame")
            pickerframe.Name = "pickerframe"
            pickerframe.Parent = workareamain
            registerTheme(pickerframe, "BackgroundColor3", Color3.fromRGB(245, 245, 245), Color3.fromRGB(40, 40, 40))
            pickerframe.BorderSizePixel = 0
            pickerframe.Size = UDim2.new(1, 0, 0, 0)
            pickerframe.ClipsDescendants = true
            pickerframe.Visible = false
            pickerframe.ZIndex = 5

            local uc_pf = Instance.new("UICorner")
            uc_pf.CornerRadius = UDim.new(0, 9)
            uc_pf.Parent = pickerframe

            local hsvmap = Instance.new("ImageLabel")
            hsvmap.Name = "hsvmap"
            hsvmap.Parent = pickerframe
            hsvmap.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            hsvmap.Position = UDim2.new(0, 8, 0, 8)
            hsvmap.Size = UDim2.new(0, 200, 0, 130)
            hsvmap.Image = "rbxassetid://4155801252"
            hsvmap.ZIndex = 6
            hsvmap.BorderSizePixel = 0

            local uc_hm = Instance.new("UICorner")
            uc_hm.CornerRadius = UDim.new(0, 6)
            uc_hm.Parent = hsvmap

            local satcursor = Instance.new("Frame")
            satcursor.Name = "satcursor"
            satcursor.Parent = hsvmap
            satcursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            satcursor.AnchorPoint = Vector2.new(0.5, 0.5)
            satcursor.Position = UDim2.new(1, 0, 0, 0)
            satcursor.Size = UDim2.new(0, 10, 0, 10)
            satcursor.ZIndex = 7
            satcursor.BorderSizePixel = 0

            local uc_sc = Instance.new("UICorner")
            uc_sc.CornerRadius = UDim.new(1, 0)
            uc_sc.Parent = satcursor

            local huerail = Instance.new("Frame")
            huerail.Name = "huerail"
            huerail.Parent = pickerframe
            huerail.Position = UDim2.new(0, 218, 0, 8)
            huerail.Size = UDim2.new(0, 16, 0, 130)
            huerail.BorderSizePixel = 0
            huerail.ZIndex = 6

            local uc_hr = Instance.new("UICorner")
            uc_hr.CornerRadius = UDim.new(1, 0)
            uc_hr.Parent = huerail

            local huegrad = Instance.new("UIGradient")
            local huekeys = {}
            for i = 0, 1, 0.1 do
                table.insert(huekeys, ColorSequenceKeypoint.new(math.min(i, 1), Color3.fromHSV(i, 1, 1)))
            end
            huegrad.Color = ColorSequence.new(huekeys)
            huegrad.Rotation = 90
            huegrad.Parent = huerail

            local huecursor = Instance.new("Frame")
            huecursor.Name = "huecursor"
            huecursor.Parent = huerail
            huecursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            huecursor.AnchorPoint = Vector2.new(0.5, 0.5)
            huecursor.Position = UDim2.new(0.5, 0, 0, 0)
            huecursor.Size = UDim2.new(1, 4, 0, 6)
            huecursor.ZIndex = 7
            huecursor.BorderSizePixel = 0

            local uc_hc = Instance.new("UICorner")
            uc_hc.CornerRadius = UDim.new(1, 0)
            uc_hc.Parent = huecursor

            local hexlabel = Instance.new("TextLabel")
            hexlabel.Name = "hexlabel"
            hexlabel.Parent = pickerframe
            hexlabel.BackgroundTransparency = 1
            hexlabel.Position = UDim2.new(0, 244, 0, 8)
            hexlabel.Size = UDim2.new(0, 60, 0, 20)
            hexlabel.Font = Enum.Font.Gotham
            hexlabel.Text = "Hex"
            registerTheme(hexlabel, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            hexlabel.TextSize = 16
            hexlabel.TextXAlignment = Enum.TextXAlignment.Left
            hexlabel.ZIndex = 6

            local hexbox = Instance.new("TextBox")
            hexbox.Name = "hexbox"
            hexbox.Parent = pickerframe
            registerTheme(hexbox, "BackgroundColor3", Color3.fromRGB(240, 240, 240), Color3.fromRGB(45, 45, 45))
            hexbox.Position = UDim2.new(0, 244, 0, 28)
            hexbox.Size = UDim2.new(0, 156, 0, 28)
            hexbox.Font = Enum.Font.Gotham
            hexbox.Text = "#" .. currentColor:ToHex()
            registerTheme(hexbox, "TextColor3", Color3.fromRGB(12, 12, 12), Color3.fromRGB(240, 240, 240))
            hexbox.TextSize = 16
            hexbox.ClearTextOnFocus = false
            hexbox.ZIndex = 6
            hexbox.BorderSizePixel = 0

            local uc_hb = Instance.new("UICorner")
            uc_hb.CornerRadius = UDim.new(0, 7)
            uc_hb.Parent = hexbox

            local H, S, V = Color3.toHSV(currentColor)

            local function refreshDisplay()
                hsvmap.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                huecursor.Position = UDim2.new(0.5, 0, H, 0)
                satcursor.Position = UDim2.new(S, 0, 1 - V, 0)
                local col = Color3.fromHSV(H, S, V)
                preview.BackgroundColor3 = col
                currentColor = col
                if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = {R=col.R, G=col.G, B=col.B} end
                hexbox.Text = "#" .. col:ToHex()
                if callback then callback(col) end
            end

            local draggingHSV = false
            local draggingHue = false

            hsvmap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHSV = true
                    if workareamain then workareamain.ScrollingEnabled = false end
                end
            end)
            hsvmap.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHSV = false
                    if workareamain then workareamain.ScrollingEnabled = true end
                end
            end)
            huerail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = true
                    if workareamain then workareamain.ScrollingEnabled = false end
                end
            end)
            huerail.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = false
                    if workareamain then workareamain.ScrollingEnabled = true end
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if draggingHSV then
                        local relX = math.clamp(input.Position.X - hsvmap.AbsolutePosition.X, 0, hsvmap.AbsoluteSize.X)
                        local relY = math.clamp(input.Position.Y - hsvmap.AbsolutePosition.Y, 0, hsvmap.AbsoluteSize.Y)
                        S = relX / hsvmap.AbsoluteSize.X
                        V = 1 - (relY / hsvmap.AbsoluteSize.Y)
                        refreshDisplay()
                    elseif draggingHue then
                        local relY = math.clamp(input.Position.Y - huerail.AbsolutePosition.Y, 0, huerail.AbsoluteSize.Y)
                        H = relY / huerail.AbsoluteSize.Y
                        refreshDisplay()
                    end
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHSV = false
                    draggingHue = false
                end
            end)

            hexbox.FocusLost:Connect(function(enter)
                if enter then
                    local ok, col = pcall(Color3.fromHex, hexbox.Text)
                    if ok and typeof(col) == "Color3" then
                        H, S, V = Color3.toHSV(col)
                        refreshDisplay()
                    end
                end
            end)

            refreshDisplay()

            ConfigManager.Elements[flag] = { Value = {R=currentColor.R, G=currentColor.G, B=currentColor.B}, Set = function(self, val) local col = Color3.new(val.R, val.G, val.B); H,S,V = Color3.toHSV(col); refreshDisplay() end }
            preview.MouseButton1Click:Connect(function()
                if pickerOpen then
                    pickerOpen = false
                    TweenService:Create(pickerframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    task.wait(0.15)
                    pickerframe.Visible = false
                else
                    pickerOpen = true
                    pickerframe.Visible = true
                    pickerframe.Size = UDim2.new(1, 0, 0, 0)
                    TweenService:Create(pickerframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 155)}):Play()
                end
            end)
        end

        -- keybind
        function sec:Keybind(name, default, callback, flag)
            table.insert(sec.SearchableText, string.upper(name))
            flag = flag or name
            local kbrow = Instance.new("Frame")
            kbrow.Name = "kbrow"
            kbrow.Parent = workareamain
            table.insert(sec.ElementsList, { text = string.upper(name), gui = kbrow })
            kbrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            kbrow.BackgroundTransparency = 1
            kbrow.BorderSizePixel = 0
            kbrow.Size = UDim2.new(1, 0, 0, 37)

            local kblabel = Instance.new("TextLabel")
            kblabel.Name = "kblabel"
            kblabel.Parent = kbrow
            kblabel.BackgroundTransparency = 1
            kblabel.Size = UDim2.new(1, -80, 1, 0)
            kblabel.Font = Enum.Font.GothamMedium
            kblabel.Text = name
            registerTheme(kblabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            kblabel.TextSize = 16
            kblabel.TextWrapped = true
            kblabel.TextXAlignment = Enum.TextXAlignment.Left

            local kbbtn = Instance.new("TextButton")
                        kbbtn.Name = "kbbtn"
            kbbtn.Parent = kbrow
            registerTheme(kbbtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            kbbtn.Position = UDim2.new(1, -70, 0.5, -17)
            kbbtn.Size = UDim2.new(0, 70, 0, 34)
            kbbtn.Font = Enum.Font.GothamBold
            kbbtn.TextColor3 = currentAccentColor
            kbbtn.TextSize = 14
            kbbtn.AutoButtonColor = false
            kbbtn.Text = default and default.Name or "None"
            kbbtn.ZIndex = 20
            kbbtn.BorderSizePixel = 0

            local uc_kb = Instance.new("UICorner")
            uc_kb.CornerRadius = UDim.new(0, 9)
            uc_kb.Parent = kbbtn

            local us_kb = Instance.new("UIStroke", kbbtn)
            us_kb.ApplyStrokeMode = "Border"
            us_kb.Color = currentAccentColor
            us_kb.Thickness = 1

            local currentKey = default
            local picking = false

            kbbtn.MouseButton1Click:Connect(function()
                if picking then return end
                picking = true
                kbbtn.Text = "..."
                kbbtn.TextColor3 = Color3.fromRGB(95, 95, 95)

                task.wait(0.2)

                local con
                local cancelled = false
                task.delay(5, function()
                    if picking and not cancelled then
                        picking = false
                        kbbtn.Text = currentKey and currentKey.Name or "None"
                        kbbtn.TextColor3 = currentAccentColor
                        if con then con:Disconnect() end
                    end
                end)
                con = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        cancelled = true
                        currentKey = input.KeyCode
                        if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentKey.Name end
                        kbbtn.Text = input.KeyCode.Name
                        kbbtn.TextColor3 = currentAccentColor
                        picking = false
                        con:Disconnect()
                    end
                end)
            end)

            ConfigManager.Elements[flag] = { Value = currentKey and currentKey.Name or "None", Set = function(self, val) if val == "None" then currentKey = nil; kbbtn.Text = "None" else currentKey = Enum.KeyCode[val]; kbbtn.Text = val end end }
            local kbConn = UserInputService.InputBegan:Connect(function(input, gp)
                if not picking and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
                    if currentKey and input.KeyCode == currentKey then
                        if callback then callback() end
                    end
                end
            end)
            table.insert(cleanupKeybinds, kbConn)
        end

        -- text block
        function sec:Paragraph(title, content)
            local para = Instance.new("TextLabel")
            para.Name = "para"
            para.Parent = workareamain
            local searchStr = string.upper(title) .. " " .. string.upper(content)
            table.insert(sec.ElementsList, { text = searchStr, gui = para })
            para.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            para.BackgroundTransparency = 1
            para.BorderSizePixel = 0
            para.Size = UDim2.new(1, 0, 0, 56)
            para.Font = Enum.Font.Gotham
            para.Text = ""
            para.TextColor3 = Color3.fromRGB(95, 95, 95)
            para.TextSize = 21

            local ptitle = Instance.new("TextLabel")
            ptitle.Name = "ptitle"
            ptitle.Parent = para
            ptitle.BackgroundTransparency = 1
            ptitle.Size = UDim2.new(1, 0, 0, 24)
            ptitle.Position = UDim2.new(0, 0, 0, 0)
            ptitle.Font = Enum.Font.GothamMedium
            ptitle.Text = title
            registerTheme(ptitle, "TextColor3", Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
            ptitle.TextSize = 21
            ptitle.TextWrapped = true
            ptitle.TextXAlignment = Enum.TextXAlignment.Left

            local pcontent = Instance.new("TextLabel")
            pcontent.Name = "pcontent"
            pcontent.Parent = para
            pcontent.BackgroundTransparency = 1
            pcontent.Size = UDim2.new(1, 0, 0, 28)
            pcontent.Position = UDim2.new(0, 0, 0, 24)
            pcontent.Font = Enum.Font.Gotham
            pcontent.Text = content
            registerTheme(pcontent, "TextColor3", Color3.fromRGB(100, 100, 120), Color3.fromRGB(140, 140, 155))
            pcontent.TextSize = 14
            pcontent.TextWrapped = true
            pcontent.TextXAlignment = Enum.TextXAlignment.Left
        end

        sidebar2.MouseButton1Click:Connect(function()
            sec:Select()
        end)

        if isExtra then
            table.insert(extraTabs, sec)
            sidebar2.Visible = false
        else
            table.insert(mainTabs, sec)
        end

        return sec
    end

    
    -- settings
    local function CreateSettingsTab()
        local setsec = window:Section("Settings", "rbxassetid://10734950309", true)
        setsec:Divider("UI Settings")
        
        setsec:Keybind("Menu Bind", visiblekey or Enum.KeyCode.LeftControl, function()
            -- this fires the menu toggle when you press the bind
            window:ToggleVisible()
        end, "Settings_MenuBind")
        -- override the keybind element's fire so it instead rebinds the key
        do
            local mbFlag = "Settings_MenuBind"
            local origEl = ConfigManager.Elements[mbFlag]
            if origEl then
                -- watch for value changes to rebind the key
                task.spawn(function()
                    local lastVal = origEl.Value
                    while true do
                        task.wait(0.2)
                        if not origEl then break end
                        local v = origEl.Value
                        if v and v ~= lastVal then
                            lastVal = v
                            local kc = Enum.KeyCode[v]
                            if kc then
                                rebindVisibleKey(kc)
                                -- save to script folder
                                local bindPath = lib.FolderName .. "/menu_bind.txt"
                                if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
                                pcall(writefile, bindPath, v)
                            end
                        end
                    end
                end)
            end
        end

        setsec:Switch("Keybinds Window", false, function(v)
            keybindsWindowFrame.Visible = v
            if blurEnabled then
                if v then
                    blur:BindFrame(keybindsWindowFrame.blurFrame, {
                        Transparency = 0.98,
                        Color = Color3.fromRGB(255, 255, 255)
                    })
                else
                    if blur:HasBinding(keybindsWindowFrame.blurFrame) then
                        blur:UnbindFrame(keybindsWindowFrame.blurFrame)
                    end
                end
            end
        end, "Settings_KeybindsWindow")

        setsec:Switch("Disable Splash Screen", ConfigManager.DisableSplash or false, function(v)
            ConfigManager.DisableSplash = v; ConfigManager:SaveUISettings()
        end)
        
        setsec:Divider("Config Manager")
        
        local configsList = ConfigManager:GetConfigs()
        if #configsList == 0 then configsList = {"Default"} end
        local activeConfig = configsList[1]
        
        local configDropdown = setsec:Dropdown("Select Config", configsList, configsList[1], function(opt)
            activeConfig = opt
        end, "Settings_ConfigDropdown")
        
        setsec:Button("Refresh Configs", function()
            local newList = ConfigManager:GetConfigs()
            if #newList == 0 then newList = {"Default"} end
            if configDropdown and configDropdown.Refresh then
                configDropdown:Refresh(newList)
            end
        end)

        setsec:TextField("Create New Config", "Type name and save...", function(txt)
            activeConfig = txt
        end, "ConfigNameInput")
        
        setsec:Button("Save Config", function()
            if activeConfig and activeConfig ~= "" then
                ConfigManager:Save(activeConfig)
                window:TempNotify("Config Saved", "Saved config as " .. activeConfig, "rbxassetid://12608259004")
                local newList = ConfigManager:GetConfigs()
                if #newList == 0 then newList = {"Default"} end
                if configDropdown and configDropdown.Refresh then
                    configDropdown:Refresh(newList)
                end
            end
        end)
        
        setsec:Button("Load Config", function()
            if activeConfig and activeConfig ~= "" then
                ConfigManager:Load(activeConfig)
                window:TempNotify("Config Loaded", "Loaded config " .. activeConfig, "rbxassetid://12608259004")
            end
        end)
        
        setsec:Button("Delete Config", function()
            if activeConfig and activeConfig ~= "" then
                ConfigManager:Delete(activeConfig)
                window:TempNotify("Config Deleted", "Deleted config " .. activeConfig, "rbxassetid://12608259004")
                local newList = ConfigManager:GetConfigs()
                if #newList == 0 then newList = {"Default"} end
                if configDropdown and configDropdown.Refresh then
                    configDropdown:Refresh(newList)
                end
            end
        end)
        
        setsec:Button("Set as AutoLoad", function()
            if activeConfig and activeConfig ~= "" then
                ConfigManager:SaveAutoLoad(activeConfig)
                window:TempNotify("AutoLoad Set", activeConfig .. " will now auto-load on start.", "rbxassetid://12608259004")
            end
        end)
        
        setsec:Divider("UI Customization")
        

        
        setsec:Switch("Custom Crosshair", false, function(v)
            useCustomCursor = v
            end, "Settings_Crosshair")

        setsec:Slider("UI Transparency", 0, 100, 15, function(v)
            main.BackgroundTransparency = v / 100
            keybindsWindowFrame.BackgroundTransparency = v / 100
        end, "Settings_UITransparency")
        
        local function matchColor(c1, c2)
            return math.abs(c1.R - c2.R) < 0.01 and math.abs(c1.G - c2.G) < 0.01 and math.abs(c1.B - c2.B) < 0.01
        end

        local function applyAccent(c)
            local oldAccent = currentAccentColor
            currentAccentColor = c
            for _, item in ipairs(themeElements) do
                if type(item.Light) == "userdata" and matchColor(item.Light, oldAccent) then item.Light = c end
                if type(item.Dark) == "userdata" and matchColor(item.Dark, oldAccent) then item.Dark = c end
            end
            for _, obj in next, scrgui:GetDescendants() do
                if obj:IsA("GuiObject") or obj:IsA("UIStroke") then
                    pcall(function()
                        if matchColor(obj.BackgroundColor3, oldAccent) then obj.BackgroundColor3 = c end
                    end)
                    pcall(function()
                        if matchColor(obj.TextColor3, oldAccent) then obj.TextColor3 = c end
                    end)
                    pcall(function()
                        if matchColor(obj.Color, oldAccent) then obj.Color = c end
                    end)
                end
            end
        end

        setsec:ColorPicker("Accent Color", ConfigManager.AccentColor or Color3.fromRGB(21, 103, 251), function(c)
            ConfigManager.AccentColor = c
            ConfigManager:SaveUISettings()
            applyAccent(c)
        end, "Settings_AccentColor")

        local rainbowConnection
        if ConfigManager.AccentColor then
            applyAccent(ConfigManager.AccentColor)
        end
        setsec:Switch("Rainbow Accent", ConfigManager.Rainbow or false, function(v)
            ConfigManager.Rainbow = v
            ConfigManager:SaveUISettings()
            if v then
                local hue = 0
                rainbowConnection = RunService.RenderStepped:Connect(function(dt)
                    hue = (hue + dt * 0.1) % 1
                    applyAccent(Color3.fromHSV(hue, 1, 1))
                end)
            else
                if rainbowConnection then rainbowConnection:Disconnect() end
            end
        end, "Settings_Rainbow")

        setsec:Switch("Transparent Sidebar", false, function(v)
            if v then
                workarea.BackgroundTransparency = 0
                workareacornerhider.BackgroundTransparency = 0
            else
                workarea.BackgroundTransparency = 1
                workareacornerhider.BackgroundTransparency = 1
            end
        end, "Settings_TransparentSidebar")

        setsec:Switch("Global Error Catcher", false, function(v)
            errorCatcherEnabled = v
        end, "Settings_ErrorCatcher")

        setsec:Switch("Blur Background", false, function(v)
            blurEnabled = v
            if v then
                if visible then
                    blur:BindFrame(blurFrame, {
                        Transparency = 0.98,
                        Color = Color3.fromRGB(255, 255, 255)
                    })
                    if keybindsWindowFrame.Visible then
                        blur:BindFrame(keybindsWindowFrame.blurFrame, {
                            Transparency = 0.98,
                            Color = Color3.fromRGB(255, 255, 255)
                        })
                    end
                end
            else
                if blur:HasBinding(blurFrame) then
                    blur:UnbindFrame(blurFrame)
                end
                if blur:HasBinding(keybindsWindowFrame.blurFrame) then
                    blur:UnbindFrame(keybindsWindowFrame.blurFrame)
                end
            end
        end, "Settings_BlurBackground")

        setsec:Slider("UI Scale", 0.4, 1.5, cScale, function(v)
            uiscale.Scale = v
        end, "Settings_UIScale")
    end
    
    -- credits
    local function CreateCreditsTab()
        local credSec = window:Section("Credits", "rbxassetid://10747373426", true)
        credSec:Divider("Modified AppleLibrary")
        
        local container = credSec:GetContainer()
        
        local redTreeContainer = Instance.new("Frame")
        redTreeContainer.Parent = container
        redTreeContainer.Size = UDim2.new(1, 0, 0, 60)
        redTreeContainer.BackgroundTransparency = 1

        local redTree = Instance.new("TextLabel")
        redTree.Parent = redTreeContainer
        redTree.Size = UDim2.new(1, 0, 1, 0)
        redTree.BackgroundTransparency = 1
        redTree.Font = Enum.Font.GothamBold
        redTree.Text = "RedTree1222"
        redTree.TextSize = 28
        redTree.TextColor3 = Color3.fromRGB(255, 255, 255)
        redTree.ZIndex = 2
        
        local grad1 = Instance.new("UIGradient", redTree)
        grad1.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 50, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
        })
        
        task.spawn(function()
            local rot = 0
            while task.wait() do
                if not redTree.Parent then break end
                rot = rot + 0.3
                grad1.Rotation = rot
            end
        end)
        
        local zoroC = Instance.new("Frame")
        zoroC.Parent = container
        zoroC.Size = UDim2.new(1, 0, 0, 45)
        zoroC.BackgroundTransparency = 1

        local zoroT = Instance.new("TextLabel")
        zoroT.Parent = zoroC
        zoroT.Size = UDim2.new(1, 0, 1, 0)
        zoroT.BackgroundTransparency = 1
        zoroT.Font = Enum.Font.FredokaOne
        zoroT.Text = "Zoro"
        zoroT.TextSize = 28
        zoroT.TextColor3 = Color3.fromRGB(255, 255, 255)
        zoroT.ZIndex = 2

        local zoroG = Instance.new("UIGradient", zoroT)
        zoroG.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 20))
        })

        task.spawn(function()
            local r = 0
            while task.wait() do
                if not zoroT.Parent then break end
                r = r + 0.15
                zoroG.Rotation = r
            end
        end)
        
        credSec:Divider("Original Creator")
        
        local hamza = Instance.new("TextLabel")
        hamza.Parent = container
        hamza.Size = UDim2.new(1, 0, 0, 40)
        hamza.BackgroundTransparency = 1
        hamza.Font = Enum.Font.GothamMedium
        hamza.Text = "@mham-z (Hamza)"
        hamza.TextSize = 18
        hamza.TextColor3 = Color3.fromRGB(200, 200, 210)
        
        local grad2 = Instance.new("UIGradient", hamza)
        grad2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 180))
        })
        task.spawn(function()
            local r = 0
            while task.wait() do
                if not hamza.Parent then break end
                r = r + 0.5
                grad2.Rotation = r
            end
        end)
    end
    
    local keybindSec = nil
    local function CreateKeybindsTab()
        keybindSec = window:Section("Keybinds", "rbxassetid://10723416765", true)
        
        refreshKeybindsUI = function()

            for _, child in ipairs(kb_container:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            
            for index, bindInfo in ipairs(activeKeybindData) do
                local row = Instance.new("Frame")
                row.Parent = kb_container
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 20)

                local isToggle = ConfigManager.Elements[bindInfo.Name] and type(ConfigManager.Elements[bindInfo.Name].Value) == "boolean"

                if isToggle then
                    -- Tiny Toggle UI indicator on the far left
                    local tglFrame = Instance.new("Frame")
                    tglFrame.Parent = row
                    tglFrame.ZIndex = 20
                    tglFrame.Position = UDim2.new(0, 15, 0.5, -6)
                    tglFrame.Size = UDim2.new(0, 24, 0, 12)
                    tglFrame.BackgroundColor3 = (currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                    
                    local uc_tgl = Instance.new("UICorner")
                    uc_tgl.CornerRadius = UDim.new(5, 0)
                    uc_tgl.Parent = tglFrame
                    
                    local tglBtn = Instance.new("Frame")
                    tglBtn.Parent = tglFrame
                    tglBtn.ZIndex = 21
                    tglBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    tglBtn.Size = UDim2.new(0, 10, 0, 10)
                    tglBtn.Position = UDim2.new(0, 1, 0, 1)
                    
                    local uc_tglb = Instance.new("UICorner")
                    uc_tglb.CornerRadius = UDim.new(5, 0)
                    uc_tglb.Parent = tglBtn
                    
                    task.spawn(function()
                        while tglFrame.Parent do
                            local state = ConfigManager.Elements[bindInfo.Name].Value
                            if state then
                                tglBtn.Position = UDim2.new(0, 13, 0, 1)
                                tglFrame.BackgroundColor3 = currentAccentColor
                            else
                                tglBtn.Position = UDim2.new(0, 1, 0, 1)
                                tglFrame.BackgroundColor3 = (currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                            end
                            task.wait(0.1)
                        end
                    end)
                end

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Parent = row
                nameLabel.BackgroundTransparency = 1
                nameLabel.Position = UDim2.new(0, isToggle and 45 or 15, 0, 0)
                nameLabel.Size = UDim2.new(0.5, isToggle and -45 or -15, 1, 0)
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.Text = bindInfo.Name
                nameLabel.TextColor3 = (currentTheme == "light") and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(140, 140, 155)
                nameLabel.TextSize = 13
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left

                local keyLabel = Instance.new("TextLabel")
                keyLabel.Parent = row
                keyLabel.BackgroundTransparency = 1
                keyLabel.Position = UDim2.new(0.5, 0, 0, 0)
                keyLabel.Size = UDim2.new(0.5, -15, 1, 0)
                keyLabel.Font = Enum.Font.GothamBold
                keyLabel.Text = "[" .. bindInfo.Key .. "]"
                keyLabel.TextColor3 = currentAccentColor
                keyLabel.TextSize = 13
                keyLabel.TextXAlignment = Enum.TextXAlignment.Right
            end

            local container = keybindSec:GetContainer()
            for _, child in ipairs(container:GetChildren()) do
                if child.Name == "kbrow" or child.Name == "label" then
                    child:Destroy()
                end
            end
            
            for index, bindInfo in ipairs(activeKeybindData) do
                local kbrow = Instance.new("Frame")
                kbrow.Name = "kbrow"
                kbrow.Parent = container
                kbrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                kbrow.BackgroundTransparency = 1
                kbrow.Size = UDim2.new(1, 0, 0, 37)
                
                local tglFrame = Instance.new("TextButton")
                tglFrame.Parent = kbrow
                tglFrame.ZIndex = 20
                tglFrame.Position = UDim2.new(0, 0, 0.5, -14)
                tglFrame.Size = UDim2.new(0, 56, 0, 28)
                tglFrame.Text = ""
                tglFrame.AutoButtonColor = false
                tglFrame.BackgroundColor3 = bindInfo.Enabled and currentAccentColor or ((currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60))
                local uc_tgl = Instance.new("UICorner")
                uc_tgl.CornerRadius = UDim.new(5, 0)
                uc_tgl.Parent = tglFrame
                
                local tglBtn = Instance.new("TextButton")
                tglBtn.Parent = tglFrame
                tglBtn.ZIndex = 21
                tglBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                tglBtn.Size = UDim2.new(0, 26, 0, 26)
                tglBtn.Position = bindInfo.Enabled and UDim2.new(0, 29, 0, 1) or UDim2.new(0, 1, 0, 1)
                tglBtn.AutoButtonColor = false
                tglBtn.Text = ""
                local uc_tglb = Instance.new("UICorner")
                uc_tglb.CornerRadius = UDim.new(5, 0)
                uc_tglb.Parent = tglBtn
                
                local function toggleBind()
                    bindInfo.Enabled = not bindInfo.Enabled
                    if bindInfo.Enabled then
                        tglBtn:TweenPosition(UDim2.new(0, 29, 0, 1), "In", "Sine", 0.1, true)
                        tglFrame.BackgroundColor3 = currentAccentColor
                    else
                        tglBtn:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
                        tglFrame.BackgroundColor3 = (currentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                    end
                end
                tglFrame.MouseButton1Click:Connect(toggleBind)
                tglBtn.MouseButton1Click:Connect(toggleBind)

                local kblabel = Instance.new("TextLabel")
                kblabel.Parent = kbrow
                kblabel.BackgroundTransparency = 1
                kblabel.Position = UDim2.new(0, 66, 0, 0)
                kblabel.Size = UDim2.new(1, -170, 1, 0)
                kblabel.Font = Enum.Font.GothamMedium
                kblabel.Text = bindInfo.Name
                registerTheme(kblabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
                kblabel.TextSize = 16
                kblabel.TextXAlignment = Enum.TextXAlignment.Left

                local rebindBtn = Instance.new("TextButton")
                rebindBtn.Parent = kbrow
                rebindBtn.ZIndex = 20
                rebindBtn.Position = UDim2.new(1, -95, 0.5, -14)
                rebindBtn.Size = UDim2.new(0, 60, 0, 28)
                rebindBtn.Font = Enum.Font.GothamMedium
                rebindBtn.Text = "[" .. bindInfo.Key .. "]"
                registerTheme(rebindBtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
                registerTheme(rebindBtn, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(200, 200, 200))
                rebindBtn.TextSize = 14
                local uc_reb = Instance.new("UICorner")
                uc_reb.CornerRadius = UDim.new(0, 6)
                uc_reb.Parent = rebindBtn
                
                rebindBtn.MouseButton1Click:Connect(function()
                    window:PromptKeybind(bindInfo.Callback, bindInfo.Name)
                end)

                local delBtn = Instance.new("TextButton")
                delBtn.Parent = kbrow
                delBtn.ZIndex = 20
                delBtn.Position = UDim2.new(1, -30, 0.5, -14)
                delBtn.Size = UDim2.new(0, 28, 0, 28)
                delBtn.Font = Enum.Font.GothamMedium
                delBtn.Text = "🗑️"
                registerTheme(delBtn, "BackgroundColor3", Color3.fromRGB(255, 100, 100), Color3.fromRGB(180, 50, 50))
                delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                delBtn.TextSize = 16
                local uc_del = Instance.new("UICorner")
                uc_del.CornerRadius = UDim.new(0, 6)
                uc_del.Parent = delBtn
                
                delBtn.MouseButton1Click:Connect(function()
                    table.remove(activeKeybindData, index)
                    refreshKeybindsUI()
                end)
            end
        end
    end
    
    CreateSettingsTab()
    CreateCreditsTab()
    CreateKeybindsTab()


    collapseBtn.MouseButton1Click:Connect(function()
        if collapseCooldown then return end
        collapseCooldown = true
        isSidebarCollapsed = not isSidebarCollapsed

        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local rot = isSidebarCollapsed and 180 or 0
        TweenService:Create(collapseBtn, tweenInfo, { Rotation = rot }):Play()

        local sideWidth = isSidebarCollapsed and 40 or expandedSidebarWidth
        local workPosX = isSidebarCollapsed and 70 or (expandedSidebarWidth + 30)
        
        TweenService:Create(sidebar, tweenInfo, { Size = UDim2.new(0, sideWidth, 1, -124) }):Play()
        TweenService:Create(workarea, tweenInfo, {
            Position = UDim2.new(0, workPosX, 0, 0),
            Size = UDim2.new(1, -workPosX, 1, 0)
        }):Play()
        
        TweenService:Create(title, tweenInfo, {
            Position = UDim2.new(0, isSidebarCollapsed and 16 or 16, 0, isSidebarCollapsed and 50 or 16),
            TextTransparency = 0
        }):Play()

        local searchWidth = isSidebarCollapsed and 34 or (expandedSidebarWidth - 8)
        TweenService:Create(search, tweenInfo, { Size = UDim2.new(0, searchWidth, 0, 34) }):Play()
        TweenService:Create(searchtextbox, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            TextTransparency = isSidebarCollapsed and 1 or 0
        }):Play()
        
        local sIconPos = isSidebarCollapsed and UDim2.new(0.5, -12, 0.5, -10) or UDim2.new(0.038, -2, 0.139, 2)
        TweenService:Create(searchicon, tweenInfo, { Position = sIconPos }):Play()

        local allTabs = {}
        for _, t in ipairs(mainTabs) do table.insert(allTabs, t) end
        for _, t in ipairs(extraTabs) do table.insert(allTabs, t) end

        local firstMainIdx = nil
        local firstExtraIdx = nil
        for i, t in ipairs(mainTabs) do
            if t.IsDivider and not firstMainIdx then firstMainIdx = i end
        end
        for i, t in ipairs(extraTabs) do
            if t.IsDivider and not firstExtraIdx then firstExtraIdx = i end
        end

        local txtTrans = isSidebarCollapsed and 1 or 0
        local padLeft = isSidebarCollapsed and 0 or 40
        local highlightWidth = isSidebarCollapsed and 34 or (expandedSidebarWidth - 7)
        local targetIconPos = isSidebarCollapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, -16, 0.5, 0)

        local highlight = main:FindFirstChild("TabHighlight")
        if highlight then
            TweenService:Create(highlight, tweenInfo, { Size = UDim2.new(0, highlightWidth, 0, 34) }):Play()
        end

        for i, t in ipairs(allTabs) do
            local isFirstMain = firstMainIdx and (t == mainTabs[firstMainIdx]) or false
            local isFirstExtra = firstExtraIdx and (t == extraTabs[firstExtraIdx]) or false
            
            if t.IsDivider then
                local isFirstInMode = (isFirstMain and not isExtraMode) or (isFirstExtra and isExtraMode)
                local targetHeight = isSidebarCollapsed and 12 or 20
                if isFirstInMode and isSidebarCollapsed then
                    targetHeight = 0 -- Eliminate top gap!
                end
                TweenService:Create(t.Label, tweenInfo, {
                    TextTransparency = txtTrans,
                    Size = UDim2.new(0, highlightWidth, 0, targetHeight)
                }):Play()
                
                local line = t.Label:FindFirstChild("Line")
                if line then
                    if (isFirstMain and not isExtraMode) or (isFirstExtra and isExtraMode) then
                        -- never show line for the top divider of the current mode
                        TweenService:Create(line, tweenInfo, { BackgroundTransparency = 1 }):Play()
                    else
                        TweenService:Create(line, tweenInfo, { BackgroundTransparency = isSidebarCollapsed and 0 or 1 }):Play()
                    end
                end
            else
                local btn = t.TabButton
                local padding = btn:FindFirstChildOfClass("UIPadding")
                if padding then
                    TweenService:Create(padding, tweenInfo, { PaddingLeft = UDim.new(0, padLeft) }):Play()
                end
                TweenService:Create(btn, tweenInfo, {
                    TextTransparency = txtTrans,
                    Size = UDim2.new(0, highlightWidth, 0, 34)
                }):Play()
                
                local ico = btn:FindFirstChild("iconImg")
                if ico then
                    TweenService:Create(ico, tweenInfo, { Position = targetIconPos }):Play()
                end
            end
        end

        -- Retrigger sec:Select active TabHighlight positional sync so it bounces cleanly
        local activeTab = nil
        for _, s in ipairs(sections) do
            if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                activeTab = s
                break
            end
        end
        if activeTab and highlight then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if activeTab and highlight then
                    highlight.Position = UDim2.new(0, activeTab.AbsolutePosition.X - main.AbsolutePosition.X, 0, activeTab.AbsolutePosition.Y - main.AbsolutePosition.Y)
                else
                    if connection then connection:Disconnect() end
                end
            end)
            task.delay(0.4, function()
                if connection then connection:Disconnect() end
            end)
        end

        task.delay(0.4, function() collapseCooldown = false end)
    end)

    local autoloadConfig = ConfigManager:GetAutoLoad()
    if autoloadConfig then
        task.spawn(function()
            task.wait(1)
            ConfigManager:Load(autoloadConfig)
            window:TempNotify("AutoLoad", "Loaded config: " .. autoloadConfig, "rbxassetid://12608259004")
        end)
    end

    local ScriptContext = game:GetService("ScriptContext")
    local seenErrors = {}
    ScriptContext.Error:Connect(function(message, trace, script)
        if errorCatcherEnabled then
            local errMsg = tostring(message)
            if not seenErrors[errMsg] then
                seenErrors[errMsg] = true
                task.spawn(function()
                    task.wait(0.5)
                    window:Notify2("Script Error", errMsg, "Copy", "OK", "rbxassetid://12608259004", function()
                        if setclipboard then setclipboard(errMsg .. "\n" .. tostring(trace)) end
                    end, function() end)
                end)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if isPromptingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                isPromptingKeybind = false
                if keybindPromptFrame then keybindPromptFrame.Visible = false end
                if notifdarkness then notifdarkness.Visible = false end
            elseif input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Backspace then
                isPromptingKeybind = false
                if keybindPromptFrame then keybindPromptFrame.Visible = false end
                if notifdarkness then notifdarkness.Visible = false end
                
                -- Remove existing bind for this element if rebinding
                for i = #activeKeybindData, 1, -1 do
                    if activeKeybindData[i].Name == keybindPromptElementName then
                        table.remove(activeKeybindData, i)
                    end
                end
                
                table.insert(activeKeybindData, { Name = keybindPromptElementName, Key = input.KeyCode.Name, Enabled = true, Callback = keybindPromptCallback })
                
                if refreshKeybindsUI then refreshKeybindsUI() end
                window:TempNotify("Keybind Set", "Bound to: " .. input.KeyCode.Name, "rbxassetid://12608259004")
            end
            return
        end

        if not isPromptingKeybind and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            for _, bindInfo in ipairs(activeKeybindData) do
                if bindInfo.Enabled and bindInfo.Key == input.KeyCode.Name then
                    if bindInfo.Callback then
                        pcall(bindInfo.Callback)
                    end
                end
            end
        end
    end)

    return window
end

return lib
