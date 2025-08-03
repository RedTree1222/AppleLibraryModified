-- Roblox UI Library Extended v1.0

local lib = {}

function lib:CreateWindow(title, visiblekey)
    local scrgui = Instance.new("ScreenGui")
    scrgui.Name = "ExtendedUILib"
    scrgui.ResetOnSpawn = false
    scrgui.Parent = game:GetService("CoreGui") -- or PlayerGui

    local visible = true
    local dbcooper = false

    -- Main window frame
    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Visible = true
    main.ZIndex = 2
    main.Parent = scrgui

    local UICorner = Instance.new("UICorner", main)
    UICorner.CornerRadius = UDim.new(0, 16)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    sidebar.Size = UDim2.new(0, 180, 1, 0)
    sidebar.Parent = main

    local UICornerSidebar = Instance.new("UICorner", sidebar)
    UICornerSidebar.CornerRadius = UDim.new(0, 16)

    -- Workarea for pages
    local workarea = Instance.new("Frame")
    workarea.Name = "Workarea"
    workarea.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    workarea.Position = UDim2.new(0, 190, 0, 0)
    workarea.Size = UDim2.new(1, -190, 1, 0)
    workarea.Parent = main

    local UICornerWorkarea = Instance.new("UICorner", workarea)
    UICornerWorkarea.CornerRadius = UDim.new(0, 16)

    local sections = {}
    local workareas = {}

    -- Tween function to toggle visibility with smooth animation
    local TweenService = game:GetService("TweenService")
    local function tp(obj, pos, dur)
        local tween = TweenService:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad), {Position = pos})
        tween:Play()
    end

    -- Window toggle visibility function
    local window = {}

    function window:ToggleVisible()
        if dbcooper then return end
        visible = not visible
        dbcooper = true
        if visible then
            tp(main, UDim2.new(0.5, 0, 0.5, 0), 0.5)
            task.wait(0.5)
            dbcooper = false
        else
            tp(main, main.Position + UDim2.new(0, 0, 2, 0), 0.5)
            task.wait(0.5)
            dbcooper = false
        end
    end

    if visiblekey then
        game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == visiblekey then
                window:ToggleVisible()
            end
        end)
    end

    -- Section creation (tabs)
    function window:Section(name)
        local sidebarButton = Instance.new("TextButton")
        sidebarButton.Name = "SidebarButton"
        sidebarButton.Text = name
        sidebarButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sidebarButton.Size = UDim2.new(1, 0, 0, 40)
        sidebarButton.Font = Enum.Font.GothamSemibold
        sidebarButton.TextSize = 18
        sidebarButton.TextColor3 = Color3.fromRGB(50, 50, 50)
        sidebarButton.Parent = sidebar
        sidebarButton.AutoButtonColor = false

        local UICornerSB = Instance.new("UICorner", sidebarButton)
        UICornerSB.CornerRadius = UDim.new(0, 8)

        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Name = "ContentFrame"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.Position = UDim2.new(0, 0, 0, 0)
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentFrame.ScrollBarThickness = 8
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = false
        contentFrame.Parent = workarea

        local UIListLayout = Instance.new("UIListLayout", contentFrame)
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 10)

        table.insert(sections, sidebarButton)
        table.insert(workareas, contentFrame)

        function sidebarButton:Select()
            for _, btn in pairs(sections) do
                btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextColor3 = Color3.fromRGB(50, 50, 50)
            end
            for _, area in pairs(workareas) do
                area.Visible = false
            end

            sidebarButton.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
            sidebarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            contentFrame.Visible = true
        end

        sidebarButton.MouseButton1Click:Connect(function()
            sidebarButton:Select()
        end)

        local sectionAPI = {}

        -- Button
        function sectionAPI:Button(name, callback)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -20, 0, 40)
            button.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 18
            button.Text = name
            button.Parent = contentFrame

            local UICornerBtn = Instance.new("UICorner", button)
            UICornerBtn.CornerRadius = UDim.new(0, 8)

            button.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)
        end

        -- Label
        function sectionAPI:Label(text)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(60, 60, 60)
            label.Text = text
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = contentFrame
        end

        -- Toggle switch
        function sectionAPI:Switch(name, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 40)
            frame.BackgroundTransparency = 1
            frame.Parent = contentFrame

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(60, 60, 60)
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 50, 0, 25)
            toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
            toggleBtn.BackgroundColor3 = default and Color3.fromRGB(21, 103, 251) or Color3.fromRGB(220, 220, 220)
            toggleBtn.Text = ""
            toggleBtn.Parent = frame

            local UICornerToggle = Instance.new("UICorner", toggleBtn)
            UICornerToggle.CornerRadius = UDim.new(0, 12)

            local toggleCircle = Instance.new("Frame")
            toggleCircle.Size = UDim2.new(0, 23, 0, 23)
            toggleCircle.Position = default and UDim2.new(0.5, 0, 0.12, 0) or UDim2.new(0.05, 0, 0.12, 0)
            toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleCircle.Parent = toggleBtn

            local UICornerCircle = Instance.new("UICorner", toggleCircle)
            UICornerCircle.CornerRadius = UDim.new(1, 0)

            local toggled = default

            local function updateToggle()
                if toggled then
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
                    toggleCircle:TweenPosition(UDim2.new(0.5, 0, 0.12, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.15, true)
                else
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
                    toggleCircle:TweenPosition(UDim2.new(0.05, 0, 0.12, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.15, true)
                end
            end

            toggleBtn.MouseButton1Click:Connect(function()
                toggled = not toggled
                updateToggle()
                if callback then
                    callback(toggled)
                end
            end)

            updateToggle()
        end

        -- Text field
        function sectionAPI:TextField(name, placeholder, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 40)
            frame.BackgroundTransparency = 1
            frame.Parent = contentFrame

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(60, 60, 60)
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local textbox = Instance.new("TextBox")
            textbox.Size = UDim2.new(0.55, 0, 0.7, 0)
            textbox.Position = UDim2.new(0.45, 0, 0.15, 0)
            textbox.PlaceholderText = placeholder or ""
            textbox.ClearTextOnFocus = false
            textbox.Text = ""
            textbox.Font = Enum.Font.Gotham
            textbox.TextSize = 16
            textbox.TextColor3 = Color3.fromRGB(0, 0, 0)
            textbox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            textbox.Parent = frame

            local UICornerTB = Instance.new("UICorner", textbox)
            UICornerTB.CornerRadius = UDim.new(0, 6)

            textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed and callback then
                    callback(textbox.Text)
                end
            end)
        end

        -- Dropdown
        function sectionAPI:Dropdown(name, options, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundTransparency = 1
            frame.Parent = contentFrame

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(60, 60, 60)
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Size = UDim2.new(0.55, 0, 0.8, 0)
            dropdownBtn.Position = UDim2.new(0.45, 0, 0.1, 0)
            dropdownBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            dropdownBtn.Text = default or "Select..."
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.TextColor3 = Color3.fromRGB(50, 50, 50)
            dropdownBtn.TextSize = 16
            dropdownBtn.Parent = frame

            local UICornerDD = Instance.new("UICorner", dropdownBtn)
            UICornerDD.CornerRadius = UDim.new(0, 6)

            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(0, dropdownBtn.AbsoluteSize.X, 0, 0)
            dropdownFrame.Position = UDim2.new(0.45, 0, 1, 0)
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            dropdownFrame.ClipsDescendants = true
            dropdownFrame.Parent = frame

            local UIListLayoutDD = Instance.new("UIListLayout", dropdownFrame)
            UIListLayoutDD.SortOrder = Enum.SortOrder.LayoutOrder

            local open = false

            local function closeDropdown()
                open = false
                dropdownFrame:TweenSize(UDim2.new(0, dropdownBtn.AbsoluteSize.X, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
            end

            local function openDropdown()
                open = true
                local totalHeight = #options * 30
                dropdownFrame:TweenSize(UDim2.new(0, dropdownBtn.AbsoluteSize.X, 0, totalHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
            end

            dropdownBtn.MouseButton1Click:Connect(function()
                if open then
                    closeDropdown()
                else
                    openDropdown()
                end
            end)

            for i, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                optBtn.TextColor3 = Color3.fromRGB(21, 103, 251)
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 16
                optBtn.Text = option
                optBtn.Parent = dropdownFrame

                optBtn.MouseButton1Click:Connect(function()
                    dropdownBtn.Text = option
                    if callback then
                        callback(option)
                    end
                    closeDropdown()
                end)
            end

            return dropdownBtn
        end

        -- Slider
        function sectionAPI:Slider(name, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundTransparency = 1
            frame.Parent = contentFrame

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(60, 60, 60)
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.3, 0, 0.5, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Text = tostring(default)
            valueLabel.Font = Enum.Font.Gotham
            valueLabel.TextSize = 16
            valueLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
            valueLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = frame

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(0.55, 0, 0.3, 0)
            sliderFrame.Position = UDim2.new(0.35, 0, 0.6, 0)
            sliderFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            sliderFrame.Parent = frame

            local UICornerSlider = Instance.new("UICorner", sliderFrame)
            UICornerSlider.CornerRadius = UDim.new(0, 8)

            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new((default - min) / (max - min), 1, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
            sliderFill.Parent = sliderFrame

            local UICornerFill = Instance.new("UICorner", sliderFill)
            UICornerFill.CornerRadius = UDim.new(0, 8)

            local dragging = false

            sliderFrame
            sliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)

            sliderFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            sliderFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    local relativeX = math.clamp(input.Position.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X)
                    local value = min + (relativeX / sliderFrame.AbsoluteSize.X) * (max - min)
                    value = math.floor(value * 100) / 100 -- round to 2 decimals
                    sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    valueLabel.Text = tostring(value)
                    if callback then
                        callback(value)
                    end
                end
            end)

        end

        -- Notification (global for the library)
        function window:Notify(text, duration)
            duration = duration or 3
            local notif = Instance.new("Frame")
            notif.Size = UDim2.new(0, 300, 0, 50)
            notif.Position = UDim2.new(1, -310, 1, -60)
            notif.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
            notif.AnchorPoint = Vector2.new(0, 1)
            notif.Parent = scrgui

            local UICornerNotif = Instance.new("UICorner", notif)
            UICornerNotif.CornerRadius = UDim.new(0, 12)

            local label = Instance.new("TextLabel")
            label.Text = text
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 18
            label.TextWrapped = true
            label.Parent = notif

            local tweenService = game:GetService("TweenService")
            local tweenIn = tweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -310, 1, -70)})
            tweenIn:Play()

            delay(duration, function()
                local tweenOut = tweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 310, 1, -70)})
                tweenOut:Play()
                tweenOut.Completed:Connect(function()
                    notif:Destroy()
                end)
            end)
        end

        -- Select first tab by default
        if #sections > 0 then
            sections[1]:Select()
        end

        return sectionAPI
    end

    return window
end

return lib
function sec:Switch(name, defaultmode, callback)
    local mode = defaultmode
    local toggleswitch = Instance.new("TextLabel")
    toggleswitch.Name = "toggleswitch"
    toggleswitch.Parent = workareamain
    toggleswitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleswitch.BackgroundTransparency = 1
    toggleswitch.BorderSizePixel = 2
    toggleswitch.Size = UDim2.new(0, 418, 0, 37)
    toggleswitch.Font = Enum.Font.Gotham
    toggleswitch.Text = name
    toggleswitch.TextColor3 = Color3.fromRGB(95, 95, 95)
    toggleswitch.TextSize = 21
    toggleswitch.TextWrapped = true
    toggleswitch.TextXAlignment = Enum.TextXAlignment.Left

    local Frame = Instance.new("TextButton")
    Frame.Parent = toggleswitch
    Frame.Position = UDim2.new(0.832535863, 0, 0.0270270277, 0)
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

    if defaultmode == false then
        TextButton.Position = UDim2.new(0, 1, 0, 1)
        Frame.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
    else
        TextButton.Position = UDim2.new(0, 35, 0, 1)
        Frame.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
    end

    Frame.MouseButton1Click:Connect(function()
        mode = not mode

        if callback then
            callback(mode)
        end

        if mode then
            TextButton:TweenPosition(UDim2.new(0, 35, 0, 1), "In", "Sine", 0.1, true)
            Frame.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
        else
            TextButton:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
            Frame.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
        end
    end)
    TextButton.MouseButton1Click:Connect(function()
        mode = not mode

        if callback then
            callback(mode)
        end

        if mode then
            TextButton:TweenPosition(UDim2.new(0, 35, 0, 1), "In", "Sine", 0.1, true)
            Frame.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
        else
            TextButton:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
            Frame.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
        end
    end)
end

function sec:Dropdown(name, options, defaultIndex, callback)
    local dropdown = Instance.new("TextLabel")
    dropdown.Name = "dropdown"
    dropdown.Parent = workareamain
    dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.BackgroundTransparency = 1
    dropdown.Size = UDim2.new(0, 418, 0, 37)
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextColor3 = Color3.fromRGB(95, 95, 95)
    dropdown.TextSize = 21
    dropdown.TextWrapped = true
    dropdown.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.Text = name .. ": " .. options[defaultIndex]

    local open = false
    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    listFrame.Position = UDim2.new(0, 0, 1, 0)
    listFrame.Size = UDim2.new(0, 418, 0, #options * 30)
    listFrame.ClipsDescendants = true
    listFrame.Visible = false
    listFrame.Parent = dropdown

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = listFrame
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, option in ipairs(options) do
        local optionLabel = Instance.new("TextButton")
        optionLabel.Text = option
        optionLabel.Size = UDim2.new(1, 0, 0, 30)
        optionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        optionLabel.TextColor3 = Color3.fromRGB(21, 103, 251)
        optionLabel.Font = Enum.Font.Gotham
        optionLabel.TextSize = 18
        optionLabel.Parent = listFrame

        optionLabel.MouseButton1Click:Connect(function()
            dropdown.Text = name .. ": " .. option
            listFrame.Visible = false
            open = false
            if callback then
                callback(option, i)
            end
        end)
    end

    dropdown.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
    end)

    -- To allow dropdown to be clicked, set as button
    dropdown.MouseButton1Click = dropdown.MouseButton1Click or Instance.new("TextButton").MouseButton1Click

    return dropdown
end


function sec:TextField(name, placeholder, callback)
    local textfield = Instance.new("TextLabel")
    textfield.Name = "textfield"
    textfield.Parent = workareamain
    textfield.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textfield.BackgroundTransparency = 1
    textfield.BorderSizePixel = 2
    textfield.Size = UDim2.new(0, 418, 0, 37)
    textfield.Font = Enum.Font.Gotham
    textfield.Text = name
    textfield.TextColor3 = Color3.fromRGB(95, 95, 95)
    textfield.TextSize = 21
    textfield.TextWrapped = true
    textfield.TextXAlignment = Enum.TextXAlignment.Left

    local Frame_2 = Instance.new("Frame")
    Frame_2.Parent = textfield
    Frame_2.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    Frame_2.Position = UDim2.new(0.441926777, 0, 0.0270270277, 0)
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
    TextBox.TextColor3 = Color3.fromRGB(12, 12, 12)
    TextBox.TextSize = 21
    TextBox.TextXAlignment = Enum.TextXAlignment.Left

    if callback then
        TextBox.FocusLost:Connect(function()
            callback(TextBox.Text)
        end)
    end
end

sidebar2.MouseButton1Click:Connect(function()
    sec:Select()
end)

return sec
end

return window
end

return lib
