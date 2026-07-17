local lib = {}
local blur = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/refs/heads/main/Blur.luau"))()
lib.ButtonStyle = "Modern"
lib.FolderName = "AppleLibraryModified"
local sections = {}
local workareas = {}
local notifs = {}
local visible = true
local dbcooper = false
local scrollSyncConnected = false

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

function ConfigManager:Save(name)
    local data = {}
    for flag, element in pairs(self.Elements) do
        if element.Value ~= nil then
            data[flag] = element.Value
        end
    end
    if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
    if makefolder and not isfolder(lib.FolderName .. "/Configs") then makefolder(lib.FolderName .. "/Configs") end
    writefile(lib.FolderName .. "/Configs/" .. name .. ".json", HttpService:JSONEncode(data))
end

function ConfigManager:Load(name)
    local path = lib.FolderName .. "/Configs/" .. name .. ".json"
    if isfile and not isfile(path) then return end
    local ok, content = pcall(function() return readfile(path) end)
    if ok and type(content) == "string" and content ~= "" then
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if success and data then
            for flag, value in pairs(data) do
                if self.Elements[flag] and self.Elements[flag].Set then
                    self.Elements[flag]:Set(value)
                end
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

function ConfigManager:SaveTheme(theme)
    self.CurrentTheme = theme
    if makefolder and not isfolder(lib.FolderName) then makefolder(lib.FolderName) end
    writefile(lib.FolderName .. "/theme.json", HttpService:JSONEncode({theme = theme}))
end

function ConfigManager:LoadTheme()
    local path = lib.FolderName .. "/theme.json"
    if isfile and not isfile(path) then return end
    local ok, content = pcall(function() return readfile(path) end)
    if ok and type(content) == "string" and content ~= "" then
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if success and data and data.theme then
            self.CurrentTheme = data.theme
        end
    end
end

local currentTheme = ConfigManager.CurrentTheme
local currentAccentColor = Color3.fromRGB(21, 103, 251)

local function registerTheme(instance, propertyName, lightValue, darkValue)
    table.insert(themeElements, {
        Instance = instance,
        Property = propertyName,
        Light = lightValue,
        Dark = darkValue
    })
    instance[propertyName] = (currentTheme == "light") and lightValue or darkValue
end

function lib:init(ti, dosplash, visiblekey, deleteprevious)
    ConfigManager:LoadTheme()
    currentTheme = ConfigManager.CurrentTheme

    if syn then
        cg = game:GetService("CoreGui")
        local oldGui = cg:FindFirstChild("ScreenGui")
        if oldGui and deleteprevious then
            local oldMain = oldGui:FindFirstChild("main")
            if oldMain then
                tp(oldMain, oldMain.Position + UDim2.new(0, 0, 2, 0), 0.5)
            end
            game:GetService("Debris"):AddItem(oldGui, 1)
        end

        scrgui = Instance.new("ScreenGui")
        syn.protect_gui(scrgui)
        scrgui.Parent = game:GetService("CoreGui")
    elseif gethui then
        local oldGui = gethui():FindFirstChild("ScreenGui")
        if oldGui and deleteprevious then
            local oldMain = oldGui:FindFirstChild("main")
            if oldMain then
                tp(oldMain, oldMain.Position + UDim2.new(0, 0, 2, 0), 0.5)
            end
            game:GetService("Debris"):AddItem(oldGui, 1)
        end

        scrgui = Instance.new("ScreenGui")
        scrgui.Parent = gethui()
    else
        cg = game:GetService("CoreGui")
        local oldGui = cg:FindFirstChild("ScreenGui")
        if oldGui and deleteprevious then
            local oldMain = oldGui:FindFirstChild("main")
            if oldMain then
                tp(oldMain, oldMain.Position + UDim2.new(0, 0, 2, 0), 0.5)
            end
            game:GetService("Debris"):AddItem(oldGui, 1)
        end
        scrgui = Instance.new("ScreenGui")
        scrgui.Parent = cg
    end
    scrgui.IgnoreGuiInset = true

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

    local main = Instance.new("CanvasGroup")
    main.Name = "main"
    main.Parent = scrgui
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 2, 0)
    main.Size = UDim2.new(0, 721, 0, 584)
    registerTheme(main, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 30, 30))

    main.GroupTransparency = 0.150
    blur:BindFrame(main, {
        Transparency = 0.98,
        Color = Color3.fromRGB(255, 255, 255)
    })

    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, 18)
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
    registerTheme(workarea, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 30, 30))
    workarea.Position = UDim2.new(0, 263, 0, 0)
    workarea.Size = UDim2.new(1, -263, 1, 0)

    local uc_2 = Instance.new("UICorner")
    uc_2.CornerRadius = UDim.new(0, 18)
    uc_2.Parent = workarea

    local workareacornerhider = Instance.new("Frame")
    workareacornerhider.Name = "workareacornerhider"
    workareacornerhider.Parent = workarea
    registerTheme(workareacornerhider, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 30, 30))
    workareacornerhider.BorderSizePixel = 0
    workareacornerhider.Size = UDim2.new(0, 18, 1, 0)

    local search = Instance.new("Frame")
    search.Name = "search"
    search.Parent = main
    registerTheme(search, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(45, 45, 45))
    search.Position = UDim2.new(0, 18, 0, 56)
    search.Size = UDim2.new(0, 225, 0, 34)

    local uc_8 = Instance.new("UICorner")
    uc_8.CornerRadius = UDim.new(0, 9)
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
    searchtextbox.Font = Enum.Font.Gotham
    searchtextbox.LineHeight = 0.870
    searchtextbox.PlaceholderText = "Search"
    searchtextbox.Text = ""
    registerTheme(searchtextbox, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    searchtextbox.TextSize = 22
    searchtextbox.TextXAlignment = Enum.TextXAlignment.Left

    searchicon.MouseButton1Click:Connect(function()
        searchtextbox:CaptureFocus()
    end)

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "sidebar"
    sidebar.Parent = main
    sidebar.Active = true
    registerTheme(sidebar, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 30, 30))
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.new(0, 18, 0, 106)
    sidebar.Size = UDim2.new(0, 233, 1, -124)
    sidebar.AutomaticCanvasSize = "Y"
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.ScrollBarThickness = 2

    local ull_2 = Instance.new("UIListLayout")
    ull_2.Parent = sidebar
    ull_2.SortOrder = Enum.SortOrder.LayoutOrder
    ull_2.Padding = UDim.new(0, 5)

    RunService:BindToRenderStep("search", 1, function()
        if not searchtextbox:IsFocused() then
            for b, v in next, sidebar:GetChildren() do
                if not v:IsA("TextButton") then return end
                v.Visible = true
            end
        end
        local InputText = string.upper(searchtextbox.Text)
        for _, button in pairs(sidebar:GetChildren()) do
            if button:IsA("TextButton") then
                if InputText == "" or string.find(string.upper(button.Text), InputText) ~= nil then
                    button.Visible = true
                else
                    button.Visible = false
                end
            end
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

    local uc_20 = Instance.new("UICorner")
    uc_20.CornerRadius = UDim.new(1, 0)
    uc_20.Parent = resize

    local title = Instance.new("TextLabel")
    title.Name = "title"
    title.Parent = main
    title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 2
    title.Position = UDim2.new(0, 281, 0, 20)
    title.Size = UDim2.new(1, -340, 0, 30)
    title.Font = Enum.Font.Gotham
    title.LineHeight = 1.180
    registerTheme(title, "TextColor3", Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
    title.TextSize = 28
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
        ConfigManager:SaveTheme(currentTheme)
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
        for _, v in next, sections do
            if v.BackgroundTransparency == 1 then
                v.TextColor3 = (currentTheme == "light") and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
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
    notif.ZIndex = 3

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
    notificon.ZIndex = 3
    notificon.Image = "rbxassetid://4871684504"
    notificon.ImageColor3 = Color3.fromRGB(95, 95, 95)

    local notifbutton1 = Instance.new("TextButton")
    notifbutton1.Name = "notifbutton1"
    notifbutton1.Parent = notif
    notifbutton1.BackgroundColor3 = currentAccentColor
    notifbutton1.Position = UDim2.new(0.0559210554, 0, 0.817679524, 0)
    notifbutton1.Size = UDim2.new(0, 270, 0, 50)
    notifbutton1.ZIndex = 3
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
    notifdarkness.Parent = notif
    notifdarkness.AnchorPoint = Vector2.new(0.5, 0.5)
    notifdarkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notifdarkness.BackgroundTransparency = 0.600
    notifdarkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    notifdarkness.Size = UDim2.new(0, 721, 0, 584)
    notifdarkness.ZIndex = 2

    local uc_13 = Instance.new("UICorner")
    uc_13.CornerRadius = UDim.new(0, 18)
    uc_13.Parent = notifdarkness

    local notiftitle = Instance.new("TextLabel")
    notiftitle.Name = "notiftitle"
    notiftitle.Parent = notif
    notiftitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notiftitle.BackgroundTransparency = 1
    notiftitle.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    notiftitle.Size = UDim2.new(0, 200, 0, 50)
    notiftitle.ZIndex = 3
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
    notiftext.ZIndex = 3
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
    notif2.ZIndex = 3

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
    notif2icon.ZIndex = 3
    notif2icon.Image = "rbxassetid://12608260095"
    notif2icon.ImageColor3 = Color3.fromRGB(95, 95, 95)

    local notif2title = Instance.new("TextLabel")
    notif2title.Name = "notif2title"
    notif2title.Parent = notif2
    notif2title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notif2title.BackgroundTransparency = 1
    notif2title.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    notif2title.Size = UDim2.new(0, 200, 0, 50)
    notif2title.ZIndex = 3
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
    notif2text.ZIndex = 3
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
    notif2button1.ZIndex = 3
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
    notif2darkness.Parent = notif2
    notif2darkness.AnchorPoint = Vector2.new(0.5, 0.5)
    notif2darkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notif2darkness.BackgroundTransparency = 0.600
    notif2darkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    notif2darkness.Size = UDim2.new(0, 721, 0, 584)
    notif2darkness.ZIndex = 2

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
    notif2button2.ZIndex = 3
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

    local customCursorAsset = getAsset("Assets/cursor.png")
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()

    local customCursor = Instance.new("ImageLabel")
    customCursor.Name = "CustomCursor"
    customCursor.Parent = scrgui
    customCursor.BackgroundTransparency = 1
    customCursor.Size = UDim2.new(0, 28, 0, 28)
    customCursor.AnchorPoint = Vector2.new(0, 0)
    customCursor.ZIndex = 100000
    customCursor.Visible = false

    local useCustomCursor = true
    local function updateCursor()
        if customCursorAsset ~= "" and useCustomCursor then
            customCursor.Image = customCursorAsset
            if visible then
                UserInputService.MouseIconEnabled = false
                customCursor.Visible = true
            else
                UserInputService.MouseIconEnabled = true
                customCursor.Visible = false
            end
        else
            UserInputService.MouseIconEnabled = true
            customCursor.Visible = false
        end
    end
    updateCursor()

    RunService.RenderStepped:Connect(function()
        if customCursor.Visible then
            local pos = UserInputService:GetMouseLocation()
            customCursor.Position = UDim2.new(0, pos.X, 0, pos.Y)
        end
    end)

    local lastX, lastY = 0, 0
    function window:ToggleVisible()
        if dbcooper then return end
        visible = not visible
        dbcooper = true
        isAnimatingVis = true
        updateCursor()
        if visible then
            targetX = lastX
            targetY = lastY
            task.wait(0.5)
            dbcooper = false
            isAnimatingVis = false
        else
            lastX = targetX
            lastY = targetY
            targetY = 2000
            task.wait(0.5)
            dbcooper = false
            isAnimatingVis = false
        end
    end

    if visiblekey then
        minimize.MouseButton1Click:Connect(function()
            window:ToggleVisible()
        end)
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == visiblekey then
                window:ToggleVisible()
            end
        end)
    end

    function window:GreenButton(callback)
        if _G.gbutton_123123 then _G.gbutton_123123:Disconnect() end
        _G.gbutton_123123 = resize.MouseButton1Click:Connect(function()
            callback()
        end)
    end

    function window:TempNotify(text1, text2, icon)
        for b, v in next, scrgui:GetChildren() do
            if v.Name == "tempnotif" then
                TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Position = v.Position + UDim2.new(0, 0, 0, 130)
                }):Play()
            end
        end
        local tempnotif = Instance.new("Frame")
        tempnotif.Name = "tempnotif"
        tempnotif.Parent = scrgui
        tempnotif.AnchorPoint = Vector2.new(0.5, 0.5)
        registerTheme(tempnotif, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
        tempnotif.BackgroundTransparency = 0.150
        tempnotif.Position = UDim2.new(1, 200, 0.0794737339, 0)
        tempnotif.Size = UDim2.new(0, 447, 0, 117)
        tempnotif.Visible = true
        tempnotif.ZIndex = 4

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
        t2.ZIndex = 4
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
        t1.ZIndex = 4
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
        ticon.ZIndex = 4
        ticon.Image = icon
        ticon.ImageColor3 = Color3.fromRGB(95, 95, 95)
        ticon.ScaleType = Enum.ScaleType.Fit

        local tshadow = Instance.new("ImageLabel")
        tshadow.Name = "tshadow"
        tshadow.Parent = tempnotif
        tshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        tshadow.BackgroundTransparency = 1
        tshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        tshadow.Size = UDim2.new(1.12, 0, 1.20000005, 0)
        tshadow.ZIndex = 3
        tshadow.Image = "rbxassetid://313486536"
        tshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        tshadow.ImageTransparency = 0.400
        tshadow.TileSize = UDim2.new(0, 1, 0, 1)

        local finalPos = UDim2.new(1, -250, 0.0794737339, 0)
        TweenService:Create(tempnotif, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Position = finalPos
        }):Play()

        task.delay(4.5, function()
            TweenService:Create(tempnotif, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                Position = finalPos + UDim2.new(0, 500, 0, 0)
            }):Play()
            task.delay(0.5, function()
                tempnotif:Destroy()
            end)
        end)
    end

    function window:Notify(txt1, txt2, b1, icohn, callback)
        if notif.Visible == true or notif2.Visible == true then return "Already visible" end
        notiftitle.Text = txt1
        notiftext.Text = txt2
        notificon = icohn
        notif.Size = UDim2.new(0, 240, 0, 280)
        notif.Position = UDim2.new(0.5, 0, 0.5, 40)
        notif.Visible = true
        notifbutton1.Text = b1

        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 304, 0, 362),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        con1 = notifbutton1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if callback then callback() end
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 240, 0, 280),
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif.Visible = false
            end)
        end)
    end

    function window:Notify2(txt1, txt2, b1, b2, icohn, callback, callback2)
        if notif.Visible == true or notif2.Visible == true then return "Already visible" end
        notif2title.Text = txt1
        notif2text.Text = txt2
        notif2icon = icohn
        notif2.Size = UDim2.new(0, 240, 0, 280)
        notif2.Position = UDim2.new(0.5, 0, 0.5, 40)
        notif2.Visible = true
        notif2button1.Text = b1
        notif2button2.Text = b2

        TweenService:Create(notif2, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 304, 0, 362),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()

        con1 = notif2button1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback then callback() end
            TweenService:Create(notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 240, 0, 280),
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif2.Visible = false
            end)
        end)
        con2 = notif2button2.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback2 then callback2() end
            TweenService:Create(notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 240, 0, 280),
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                notif2.Visible = false
            end)
        end)
    end

    function window:Divider(name)
        local sidebardivider = Instance.new("TextLabel")
        sidebardivider.Name = "sidebardivider"
        sidebardivider.Parent = sidebar
        sidebardivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sidebardivider.BackgroundTransparency = 1
        sidebardivider.BorderSizePixel = 2
        sidebardivider.Position = UDim2.new(0, 0, 0.00215982716, 0)
        sidebardivider.Size = UDim2.new(0, 226, 0, 26)
        sidebardivider.Font = Enum.Font.Gotham
        sidebardivider.Text = name
        registerTheme(sidebardivider, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(180, 180, 180))
        sidebardivider.TextSize = 21
        sidebardivider.TextWrapped = true
        sidebardivider.TextXAlignment = Enum.TextXAlignment.Left
        sidebardivider.TextYAlignment = Enum.TextYAlignment.Bottom
    end

    function window:Section(name)
        local sidebar2 = Instance.new("TextButton")
        sidebar2.Name = "sidebar2"
        sidebar2.Parent = sidebar
        sidebar2.BackgroundColor3 = currentAccentColor
        sidebar2.BackgroundTransparency = 1
        sidebar2.Size = UDim2.new(0, 226, 0, 37)
        sidebar2.ZIndex = 2
        sidebar2.AutoButtonColor = false
        sidebar2.Font = Enum.Font.Gotham
        sidebar2.Text = name
        sidebar2.TextColor3 = (currentTheme == "light") and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        sidebar2.TextSize = 21

        local uc_10 = Instance.new("UICorner")
        uc_10.CornerRadius = UDim.new(0, 9)
        uc_10.Parent = sidebar2
        table.insert(sections, sidebar2)

        local workareamain = Instance.new("ScrollingFrame")
        workareamain.Name = "workareamain"
        workareamain.Parent = workarea
        workareamain.Active = true
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

        function sec:Select()
            if workareamain.Visible then return end

            for b, v in next, sections do
                v.BackgroundTransparency = 1
                v.TextColor3 = (currentTheme == "light") and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            end
            sidebar2.BackgroundTransparency = 1
            sidebar2.TextColor3 = Color3.fromRGB(255, 255, 255)

            local isNewHighlight = false
            local highlight = main:FindFirstChild("TabHighlight")
            if not highlight then
                isNewHighlight = true
                highlight = Instance.new("Frame")
                highlight.Name = "TabHighlight"
                highlight.Parent = main
                highlight.BackgroundColor3 = currentAccentColor
                highlight.Size = UDim2.new(0, 226, 0, 37)
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
            if isNewHighlight then
                highlight.Position = UDim2.new(0, targetX, 0, targetY)
            else
                TweenService:Create(highlight, TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, targetX, 0, targetY)
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

        function sec:Divider(name)
            local section = Instance.new("TextLabel")
            section.Name = "section"
            section.Parent = workareamain
            section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            section.BackgroundTransparency = 1
            section.BorderSizePixel = 2
            section.Size = UDim2.new(1, 0, 0, 50)
            section.Font = Enum.Font.Gotham
            section.LineHeight = 1.180
            section.Text = name
            registerTheme(section, "TextColor3", Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
            section.TextSize = 25
            section.TextWrapped = true
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.TextYAlignment = Enum.TextYAlignment.Bottom
        end

        function sec:Button(name, callback)
            local button = Instance.new("TextButton")
            button.Name = "button"
            button.Text = name
            button.Parent = workareamain
            button.Size = UDim2.new(1, 0, 0, 37)
            button.ZIndex = 2
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 16
            
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
                uc_3.CornerRadius = UDim.new(0, 6)
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
        end

        function sec:Label(name)
            local label = Instance.new("TextLabel")
            label.Name = "label"
            label.Parent = workareamain
            label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            label.BackgroundTransparency = 1
            label.BorderSizePixel = 2
            label.Size = UDim2.new(1, 0, 0, 37)
            label.Font = Enum.Font.Gotham
            registerTheme(label, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            label.TextSize = 21
            label.TextWrapped = true
            label.Text = name
        end

        function sec:Switch(name, defaultmode, callback, flag)
            flag = flag or name
            local mode = defaultmode
            local toggleswitch = Instance.new("TextLabel")
            toggleswitch.Name = "toggleswitch"
            toggleswitch.Parent = workareamain
            toggleswitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleswitch.BackgroundTransparency = 1
            toggleswitch.BorderSizePixel = 2
            toggleswitch.Size = UDim2.new(1, 0, 0, 37)
            toggleswitch.Font = Enum.Font.Gotham
            toggleswitch.Text = name
            registerTheme(toggleswitch, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            toggleswitch.TextSize = 21
            toggleswitch.TextWrapped = true
            toggleswitch.TextXAlignment = Enum.TextXAlignment.Left

            local Frame = Instance.new("TextButton")
            Frame.Parent = toggleswitch
            Frame.Position = UDim2.new(1, -70, 0.5, -18)
            Frame.Size = UDim2.new(0, 70, 0, 36)
            Frame.Text = ""
            Frame.AutoButtonColor = false

            local uc_4 = Instance.new("UICorner")
            uc_4.CornerRadius = UDim.new(5, 0)
            uc_4.Parent = Frame

            local TextButton = Instance.new("TextButton")
            TextButton.Parent = Frame
            TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextButton.Size = UDim2.new(0, 34, 0, 34)
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
                    TextButton.Position = UDim2.new(0, 35, 0, 1)
                    Frame.BackgroundColor3 = currentAccentColor
                end
            end

            updateSwitchVisual()

            local function toggle()
                mode = not mode
                if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = mode end
                if callback then callback(mode) end
                if mode then
                    TextButton:TweenPosition(UDim2.new(0, 35, 0, 1), "In", "Sine", 0.1, true)
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
            ConfigManager.Elements[flag] = { Value = mode, Set = function(self, val) if mode ~= val then toggle() end end }
        end

        function sec:TextField(name, placeholder, callback, flag)
            flag = flag or name
            local textfield = Instance.new("TextLabel")
            textfield.Name = "textfield"
            textfield.Parent = workareamain
            textfield.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            textfield.BackgroundTransparency = 1
            textfield.BorderSizePixel = 2
            textfield.Size = UDim2.new(1, 0, 0, 37)
            textfield.Font = Enum.Font.Gotham
            textfield.Text = name
            registerTheme(textfield, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            textfield.TextSize = 21
            textfield.TextWrapped = true
            textfield.TextXAlignment = Enum.TextXAlignment.Left

            local Frame_2 = Instance.new("Frame")
            Frame_2.Parent = textfield
            registerTheme(Frame_2, "BackgroundColor3", Color3.fromRGB(240, 240, 240), Color3.fromRGB(45, 45, 45))
            Frame_2.Position = UDim2.new(1, -233, 0.5, -17)
            Frame_2.Size = UDim2.new(0, 233, 0, 34)

            local uc_6 = Instance.new("UICorner")
            uc_6.CornerRadius = UDim.new(0, 9)
            uc_6.Parent = Frame_2

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = Frame_2
            TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextBox.BackgroundTransparency = 1
            TextBox.BorderColor3 = Color3.fromRGB(27, 42, 53)
            TextBox.BorderSizePixel = 0
            TextBox.ClipsDescendants = true
            TextBox.Position = UDim2.new(0.0643776804, 0, 0, -2)
            TextBox.Size = UDim2.new(0, 203, 0, 34)
            TextBox.ClearTextOnFocus = false
            TextBox.Font = Enum.Font.Gotham
            TextBox.LineHeight = 0.870
            TextBox.PlaceholderColor3 = Color3.fromRGB(113, 113, 113)
            TextBox.PlaceholderText = placeholder or "Type..."
            TextBox.Text = ""
            registerTheme(TextBox, "TextColor3", Color3.fromRGB(12, 12, 12), Color3.fromRGB(240, 240, 240))
            TextBox.TextSize = 21
            TextBox.TextXAlignment = Enum.TextXAlignment.Left

            ConfigManager.Elements[flag] = { Value = TextBox.Text, Set = function(self, val) TextBox.Text = val; if callback then callback(val) end end }
            if callback then
                TextBox.FocusLost:Connect(function()
                    if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = TextBox.Text end
                    callback(TextBox.Text)
                end)
            end
        end

        function sec:Slider(name, min, max, default, callback, flag)
            flag = flag or name
            local sliderrow = Instance.new("TextLabel")
            sliderrow.Name = "sliderrow"
            sliderrow.Parent = workareamain
            sliderrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sliderrow.BackgroundTransparency = 1
            sliderrow.BorderSizePixel = 0
            sliderrow.Size = UDim2.new(1, 0, 0, 37)
            sliderrow.Font = Enum.Font.Gotham
            sliderrow.Text = name
            registerTheme(sliderrow, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            sliderrow.TextSize = 21
            sliderrow.TextWrapped = true
            sliderrow.TextXAlignment = Enum.TextXAlignment.Left

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
            registerTheme(rail, "BackgroundColor3", Color3.fromRGB(216, 216, 216), Color3.fromRGB(60, 60, 60))
            rail.Position = UDim2.new(1, -240, 0.5, -3)
            rail.Size = UDim2.new(0, 180, 0, 6)
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
            thumb.ZIndex = 4
            thumb.BorderSizePixel = 0

            local uc_t = Instance.new("UICorner")
            uc_t.CornerRadius = UDim.new(1, 0)
            uc_t.Parent = thumb

            local currentValue = math.clamp(default, min, max)

            local function setValue(v)
                currentValue = math.clamp(math.round(v), min, max)
                if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
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

            thumb.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)

            rail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    local relX = math.clamp(input.Position.X - rail.AbsolutePosition.X, 0, rail.AbsoluteSize.X)
                    setValue(min + (max - min) * (relX / rail.AbsoluteSize.X))
                end
            end)

            rail.InputEnded:Connect(function(input)
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

        function sec:Dropdown(name, options, default, callback, flag)
            flag = flag or name
            local droprow = Instance.new("TextLabel")
            droprow.Name = "droprow"
            droprow.Parent = workareamain
            droprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            droprow.BackgroundTransparency = 1
            droprow.BorderSizePixel = 0
            droprow.Size = UDim2.new(1, 0, 0, 37)
            droprow.Font = Enum.Font.Gotham
            droprow.Text = name
            registerTheme(droprow, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            droprow.TextSize = 21
            droprow.TextWrapped = true
            droprow.TextXAlignment = Enum.TextXAlignment.Left

            local dropbtn = Instance.new("TextButton")
            dropbtn.Name = "dropbtn"
            dropbtn.Parent = droprow
            registerTheme(dropbtn, "BackgroundColor3", Color3.fromRGB(240, 240, 240), Color3.fromRGB(45, 45, 45))
            dropbtn.Position = UDim2.new(1, -233, 0.5, -17)
            dropbtn.Size = UDim2.new(0, 233, 0, 34)
            dropbtn.Font = Enum.Font.Gotham
            registerTheme(dropbtn, "TextColor3", Color3.fromRGB(12, 12, 12), Color3.fromRGB(240, 240, 240))
            dropbtn.TextSize = 18
            dropbtn.AutoButtonColor = false
            dropbtn.TextXAlignment = Enum.TextXAlignment.Left
            dropbtn.Text = "  " .. (default or (options[1] or ""))
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

            local currentValue = default or (options[1] or "")

            local listframe = Instance.new("Frame")
            listframe.Name = "listframe"
            listframe.Parent = workareamain
            registerTheme(listframe, "BackgroundColor3", Color3.fromRGB(245, 245, 245), Color3.fromRGB(40, 40, 40))
            listframe.BorderSizePixel = 0
            listframe.Size = UDim2.new(1, 0, 0, 0)
            listframe.ClipsDescendants = true
            listframe.Visible = false
            listframe.ZIndex = 5

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
                for _, opt in ipairs(options) do
                    local optbtn = Instance.new("TextButton")
                    optbtn.Name = "optbtn"
                    optbtn.Parent = listframe
                    optbtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    optbtn.BackgroundTransparency = 1
                    optbtn.Size = UDim2.new(1, -8, 0, 30)
                    optbtn.Position = UDim2.new(0, 4, 0, 0)
                    optbtn.Font = Enum.Font.Gotham
                    optbtn.Text = opt
                    registerTheme(optbtn, "TextColor3", Color3.fromRGB(12, 12, 12), Color3.fromRGB(240, 240, 240))
                    optbtn.TextSize = 18
                    optbtn.AutoButtonColor = false
                    optbtn.ZIndex = 6

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
                        currentValue = opt
                        if ConfigManager.Elements[flag] then ConfigManager.Elements[flag].Value = currentValue end
                        dropbtn.Text = "  " .. opt
                        closeList()
                        if callback then callback(currentValue) end
                    end)
                end
            end
            DropdownObj:Refresh(options)
            
            ConfigManager.Elements[flag] = { Value = currentValue, Set = function(self, val) currentValue = val; dropbtn.Text = "  " .. val; if callback then callback(val) end end }

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

        function sec:ColorPicker(name, default, callback, flag)
            flag = flag or name
            local cprow = Instance.new("TextLabel")
            cprow.Name = "cprow"
            cprow.Parent = workareamain
            cprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cprow.BackgroundTransparency = 1
            cprow.BorderSizePixel = 0
            cprow.Size = UDim2.new(1, 0, 0, 37)
            cprow.Font = Enum.Font.Gotham
            cprow.Text = name
            registerTheme(cprow, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            cprow.TextSize = 21
            cprow.TextWrapped = true
            cprow.TextXAlignment = Enum.TextXAlignment.Left

            local preview = Instance.new("TextButton")
            preview.Name = "preview"
            preview.Parent = cprow
            preview.BackgroundColor3 = default or currentAccentColor
            preview.Position = UDim2.new(1, -70, 0.5, -14)
            preview.Size = UDim2.new(0, 70, 0, 28)
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.ZIndex = 3
            preview.BorderSizePixel = 0

            local uc_cp = Instance.new("UICorner")
            uc_cp.CornerRadius = UDim.new(0, 9)
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
                end
            end)
            hsvmap.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHSV = false
                end
            end)
            huerail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = true
                end
            end)
            huerail.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = false
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

        function sec:Keybind(name, default, callback, flag)
            flag = flag or name
            local kbrow = Instance.new("TextLabel")
            kbrow.Name = "kbrow"
            kbrow.Parent = workareamain
            kbrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            kbrow.BackgroundTransparency = 1
            kbrow.BorderSizePixel = 0
            kbrow.Size = UDim2.new(1, 0, 0, 37)
            kbrow.Font = Enum.Font.Gotham
            kbrow.Text = name
            registerTheme(kbrow, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            kbrow.TextSize = 21
            kbrow.TextWrapped = true
            kbrow.TextXAlignment = Enum.TextXAlignment.Left

            local kbbtn = Instance.new("TextButton")
            kbbtn.Name = "kbbtn"
            kbbtn.Parent = kbrow
            registerTheme(kbbtn, "BackgroundColor3", Color3.fromRGB(240, 240, 240), Color3.fromRGB(45, 45, 45))
            kbbtn.Position = UDim2.new(1, -70, 0.5, -17)
            kbbtn.Size = UDim2.new(0, 70, 0, 34)
            kbbtn.Font = Enum.Font.GothamMedium
            kbbtn.TextColor3 = currentAccentColor
            kbbtn.TextSize = 16
            kbbtn.AutoButtonColor = false
            kbbtn.Text = default and default.Name or "None"
            kbbtn.ZIndex = 3
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
                con = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
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
            UserInputService.InputBegan:Connect(function(input, gp)
                if not picking and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
                    if currentKey and input.KeyCode == currentKey then
                        if callback then callback() end
                    end
                end
            end)
        end

        function sec:Paragraph(title, content)
            local para = Instance.new("TextLabel")
            para.Name = "para"
            para.Parent = workareamain
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
            registerTheme(pcontent, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            pcontent.TextSize = 17
            pcontent.TextWrapped = true
            pcontent.TextXAlignment = Enum.TextXAlignment.Left
        end

        sidebar2.MouseButton1Click:Connect(function()
            sec:Select()
        end)

        return sec
    end

    
    local function CreateSettingsTab()
        local setsec = window:Section("⚙️ Settings")
        setsec:Divider("Config Manager")
        
        local activeConfig = "Default"
        local configsList = ConfigManager:GetConfigs()
        if #configsList == 0 then configsList = {"Default"} end
        
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
        

        
        setsec:Switch("Custom Crosshair", true, function(v)
            useCustomCursor = v
            updateCursor()
        end, "Settings_Crosshair")

        setsec:Slider("UI Transparency", 0, 100, 15, function(v)
            main.GroupTransparency = v / 100
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

        setsec:ColorPicker("Accent Color", Color3.fromRGB(21, 103, 251), function(c)
            applyAccent(c)
        end, "Settings_AccentColor")

        local rainbowConnection
        setsec:Switch("Rainbow Accent", false, function(v)
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

        setsec:Switch("Transparent Sidebar", true, function(v)
            if v then
                workarea.BackgroundTransparency = 0
                workareacornerhider.BackgroundTransparency = 0
            else
                workarea.BackgroundTransparency = 1
                workareacornerhider.BackgroundTransparency = 1
            end
        end, "Settings_TransparentSidebar")

        setsec:Switch("Blur Background", true, function(v)
            if v then
                blur:BindFrame(main, {
                    Transparency = 0.98,
                    Color = Color3.fromRGB(255, 255, 255)
                })
            else
                if blur:HasBinding(main) then
                    blur:UnbindFrame(main)
                end
            end
        end, "Settings_BlurBackground")
    end
    CreateSettingsTab()


    local autoloadConfig = ConfigManager:GetAutoLoad()
    if autoloadConfig then
        task.spawn(function()
            task.wait(1)
            ConfigManager:Load(autoloadConfig)
            window:TempNotify("AutoLoad", "Loaded config: " .. autoloadConfig, "rbxassetid://12608259004")
        end)
    end

    return window
end

return lib
