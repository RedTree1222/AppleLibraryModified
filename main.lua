-- AppleLibrary (Modified with Dropdown and all requested features)
local lib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

function lib:init(title, visible, toggleKey, allowResize)
    local window = {}
    local visible = visible or true
    local toggleKey = toggleKey or Enum.KeyCode.RightShift
    local allowResize = allowResize or false

    -- Main GUI
    local scrgui = Instance.new("ScreenGui")
    scrgui.Name = "AppleLibrary"
    scrgui.ResetOnSpawn = false
    scrgui.Parent = game:GetService("CoreGui")

    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Visible = visible
    main.ZIndex = 3
    main.Parent = scrgui

    local dbcooper = false

    local sections = {}
    local workareas = {}

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "sidebar"
    sidebar.Parent = main
    sidebar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    sidebar.Size = UDim2.new(0, 230, 1, 0)
    sidebar.ZIndex = 3

    local uc_sidebar = Instance.new("UICorner")
    uc_sidebar.CornerRadius = UDim.new(0, 9)
    uc_sidebar.Parent = sidebar

    -- Workarea (right side)
    local workarea = Instance.new("Frame")
    workarea.Name = "workarea"
    workarea.Parent = main
    workarea.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    workarea.Position = UDim2.new(0, 230, 0, 0)
    workarea.Size = UDim2.new(1, -230, 1, 0)
    workarea.ZIndex = 3

    -- Titlebar
    local titlebar = Instance.new("TextLabel")
    titlebar.Name = "titlebar"
    titlebar.Parent = main
    titlebar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    titlebar.Size = UDim2.new(1, 0, 0, 40)
    titlebar.Position = UDim2.new(0, 0, 0, 0)
    titlebar.Font = Enum.Font.GothamBold
    titlebar.TextSize = 24
    titlebar.TextColor3 = Color3.fromRGB(50, 50, 50)
    titlebar.Text = title or "Apple Library"
    titlebar.ZIndex = 4

    local uc_titlebar = Instance.new("UICorner")
    uc_titlebar.CornerRadius = UDim.new(0, 9)
    uc_titlebar.Parent = titlebar

    -- Minimize Button
    local minimize = Instance.new("TextButton")
    minimize.Name = "minimize"
    minimize.Parent = main
    minimize.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
    minimize.Size = UDim2.new(0, 20, 0, 20)
    minimize.Position = UDim2.new(1, -30, 0, 10)
    minimize.Text = ""
    minimize.ZIndex = 5

    local uc_minimize = Instance.new("UICorner")
    uc_minimize.CornerRadius = UDim.new(0, 10)
    uc_minimize.Parent = minimize

    -- Resize grip (optional)
    local resize
    if allowResize then
        resize = Instance.new("TextButton")
        resize.Name = "resize"
        resize.Parent = main
        resize.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
        resize.Size = UDim2.new(0, 16, 0, 16)
        resize.Position = UDim2.new(1, -20, 1, -20)
        resize.Text = ""
        resize.ZIndex = 5

        local uc_resize = Instance.new("UICorner")
        uc_resize.CornerRadius = UDim.new(0, 8)
        uc_resize.Parent = resize
    end

-- PART 1 END -- will continue with UI element functions and notifications in part 2
    -- Helper Tween function
    local function tp(frame, pos, dur)
        TweenService:Create(frame, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos}):Play()
    end

    -- Window toggle
    local visible = visible
    function window:ToggleVisible()
        if dbcooper then return end
        dbcooper = true
        visible = not visible
        if visible then
            tp(main, UDim2.new(0.5, 0, 0.5, 0), 0.5)
            task.wait(0.5)
        else
            tp(main, UDim2.new(0.5, 0, 1.5, 0), 0.5)
            task.wait(0.5)
        end
        main.Visible = visible
        dbcooper = false
    end

    -- Toggle with minimize button and key
    minimize.MouseButton1Click:Connect(function()
        window:ToggleVisible()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            window:ToggleVisible()
        end
    end)

    -- Sections creation function
    function window:Section(name)
        local sec = {}

        -- Sidebar button
        local sidebar2 = Instance.new("TextButton")
        sidebar2.Name = "sidebar2"
        sidebar2.Parent = sidebar
        sidebar2.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
        sidebar2.BackgroundTransparency = 1
        sidebar2.Size = UDim2.new(0, 226, 0, 37)
        sidebar2.ZIndex = 2
        sidebar2.AutoButtonColor = false
        sidebar2.Font = Enum.Font.Gotham
        sidebar2.Text = name
        sidebar2.TextColor3 = Color3.fromRGB(0, 0, 0)
        sidebar2.TextSize = 21

        local uc_10 = Instance.new("UICorner")
        uc_10.CornerRadius = UDim.new(0, 9)
        uc_10.Parent = sidebar2

        table.insert(sections, sidebar2)

        -- Workarea frame
        local workareamain = Instance.new("ScrollingFrame")
        workareamain.Name = "workareamain"
        workareamain.Parent = workarea
        workareamain.Active = true
        workareamain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        workareamain.BackgroundTransparency = 1
        workareamain.BorderSizePixel = 0
        workareamain.Position = UDim2.new(0.039, 0, 0.095, 0)
        workareamain.Size = UDim2.new(0, 422, 0, 312)
        workareamain.ZIndex = 3
        workareamain.CanvasSize = UDim2.new(0, 0, 0, 0)
        workareamain.ScrollBarThickness = 2
        workareamain.Visible = false

        local ull = Instance.new("UIListLayout")
        ull.Parent = workareamain
        ull.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ull.SortOrder = Enum.SortOrder.LayoutOrder
        ull.Padding = UDim.new(0, 5)

        table.insert(workareas, workareamain)

        -- Select function to show this section
        function sec:Select()
            for _, v in pairs(sections) do
                v.BackgroundTransparency = 1
                v.TextColor3 = Color3.fromRGB(0, 0, 0)
            end
            sidebar2.BackgroundTransparency = 0
            sidebar2.TextColor3 = Color3.fromRGB(255, 255, 255)
            for _, v in pairs(workareas) do
                v.Visible = false
            end
            workareamain.Visible = true
        end

        -- Divider element inside section
        function sec:Divider(text)
            local divider = Instance.new("TextLabel")
            divider.Name = "divider"
            divider.Parent = workareamain
            divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            divider.BackgroundTransparency = 1
            divider.BorderSizePixel = 2
            divider.Size = UDim2.new(0, 418, 0, 50)
            divider.Font = Enum.Font.Gotham
            divider.LineHeight = 1.18
            divider.Text = text
            divider.TextColor3 = Color3.fromRGB(0, 0, 0)
            divider.TextSize = 25
            divider.TextWrapped = true
            divider.TextXAlignment = Enum.TextXAlignment.Left
            divider.TextYAlignment = Enum.TextYAlignment.Bottom
        end

        -- Button element
        function sec:Button(name, callback)
            local button = Instance.new("TextButton")
            button.Name = "button"
            button.Parent = workareamain
            button.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
            button.BackgroundTransparency = 1
            button.Size = UDim2.new(0, 418, 0, 37)
            button.Font = Enum.Font.Gotham
            button.TextColor3 = Color3.fromRGB(21, 103, 251)
            button.TextSize = 21
            button.Text = name

            local uc_3 = Instance.new("UICorner")
            uc_3.CornerRadius = UDim.new(0, 9)
            uc_3.Parent = button

            local us = Instance.new("UIStroke")
            us.Parent = button
            us.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            us.Color = Color3.fromRGB(21, 103, 251)
            us.Thickness = 1

            if callback then
                button.MouseButton1Click:Connect(function()
                    coroutine.wrap(function()
                        button.TextSize -= 3
                        task.wait(0.06)
                        button.TextSize += 3
                    end)()
                    callback()
                end)
            end
        end

-- PART 2 END -- ready to continue with labels, switches, textfields, dropdowns, notifications, and more in part 3
        -- Label element
        function sec:Label(text)
            local label = Instance.new("TextLabel")
            label.Name = "label"
            label.Parent = workareamain
            label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0, 418, 0, 37)
            label.Font = Enum.Font.Gotham
            label.TextColor3 = Color3.fromRGB(95, 95, 95)
            label.TextSize = 21
            label.TextWrapped = true
            label.Text = text
        end

        -- Switch element
        function sec:Switch(text, defaultState, callback)
            local state = defaultState or false

            local container = Instance.new("Frame")
            container.Name = "switchContainer"
            container.Parent = workareamain
            container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(0, 418, 0, 37)

            local label = Instance.new("TextLabel")
            label.Parent = container
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.8, 0, 1, 0)
            label.Font = Enum.Font.Gotham
            label.TextColor3 = Color3.fromRGB(95, 95, 95)
            label.TextSize = 21
            label.Text = text
            label.TextXAlignment = Enum.TextXAlignment.Left

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Parent = container
            toggleFrame.Position = UDim2.new(0.85, 0, 0.1, 0)
            toggleFrame.Size = UDim2.new(0, 50, 0, 26)
            toggleFrame.BackgroundColor3 = state and Color3.fromRGB(21, 103, 251) or Color3.fromRGB(216, 216, 216)
            toggleFrame.ClipsDescendants = true
            toggleFrame.AnchorPoint = Vector2.new(0, 0.5)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.ZIndex = 3
            toggleFrame.Name = "toggleFrame"
            toggleFrame.AutoButtonColor = false

            local toggleButton = Instance.new("TextButton")
            toggleButton.Parent = toggleFrame
            toggleButton.Size = UDim2.new(0, 22, 0, 22)
            toggleButton.Position = state and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleButton.AutoButtonColor = false
            toggleButton.Text = ""
            toggleButton.Name = "toggleButton"
            toggleButton.ZIndex = 4

            local toggleButtonCorner = Instance.new("UICorner")
            toggleButtonCorner.Parent = toggleButton
            toggleButtonCorner.CornerRadius = UDim.new(1, 0)

            local toggleFrameCorner = Instance.new("UICorner")
            toggleFrameCorner.Parent = toggleFrame
            toggleFrameCorner.CornerRadius = UDim.new(1, 0)

            local function updateToggle()
                if state then
                    toggleButton:TweenPosition(UDim2.new(1, -24, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
                    toggleFrame.BackgroundColor3 = Color3.fromRGB(21, 103, 251)
                else
                    toggleButton:TweenPosition(UDim2.new(0, 2, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
                    toggleFrame.BackgroundColor3 = Color3.fromRGB(216, 216, 216)
                end
            end

            toggleButton.MouseButton1Click:Connect(function()
                state = not state
                updateToggle()
                if callback then callback(state) end
            end)

            toggleFrame.MouseButton1Click:Connect(function()
                state = not state
                updateToggle()
                if callback then callback(state) end
            end)

            updateToggle()
        end

        -- TextField element
        function sec:TextField(text, placeholder, callback)
            local container = Instance.new("Frame")
            container.Name = "textfieldContainer"
            container.Parent = workareamain
            container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(0, 418, 0, 37)

            local label = Instance.new("TextLabel")
            label.Parent = container
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.Font = Enum.Font.Gotham
            label.TextColor3 = Color3.fromRGB(95, 95, 95)
            label.TextSize = 21
            label.Text = text
            label.TextXAlignment = Enum.TextXAlignment.Left

            local inputFrame = Instance.new("Frame")
            inputFrame.Parent = container
            inputFrame.Position = UDim2.new(0.42, 0, 0.1, 0)
            inputFrame.Size = UDim2.new(0.55, 0, 0.8, 0)
            inputFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            inputFrame.ClipsDescendants = true
            inputFrame.Name = "inputFrame"
            inputFrame.ZIndex = 3
            inputFrame.BorderSizePixel = 0

            local inputBox = Instance.new("TextBox")
            inputBox.Parent = inputFrame
            inputBox.Size = UDim2.new(1, -10, 1, 0)
            inputBox.Position = UDim2.new(0, 5, 0, 0)
            inputBox.BackgroundTransparency = 1
            inputBox.Font = Enum.Font.Gotham
            inputBox.PlaceholderText = placeholder or "Type here..."
            inputBox.Text = ""
            inputBox.TextColor3 = Color3.fromRGB(12, 12, 12)
            inputBox.TextSize = 21
            inputBox.ClearTextOnFocus = false
            inputBox.TextXAlignment = Enum.TextXAlignment.Left

            inputBox.FocusLost:Connect(function()
                if callback then callback(inputBox.Text) end
            end)
        end

        -- Dropdown element
        function sec:Dropdown(name, options, callback)
            local dropdownOpen = false
            local selectedOption = nil

            local container = Instance.new("Frame")
            container.Name = "dropdownContainer"
            container.Parent = workareamain
            container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(0, 418, 0, 37)

            local label = Instance.new("TextLabel")
            label.Parent = container
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 0, 0, 0)
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.Font = Enum.Font.Gotham
            label.TextColor3 = Color3.fromRGB(95, 95, 95)
            label.TextSize = 21
            label.Text = name
            label.TextXAlignment = Enum.TextXAlignment.Left

            local dropdownButton = Instance.new("TextButton")
            dropdownButton.Parent = container
            dropdownButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            dropdownButton.Position = UDim2.new(0.52, 0, 0.1, 0)
            dropdownButton.Size = UDim2.new(0.45, 0, 0.8, 0)
            dropdownButton.Text = "Select..."
            dropdownButton.Font = Enum.Font.Gotham
            dropdownButton.TextColor3 = Color3.fromRGB(12, 12, 12)
            dropdownButton.TextSize = 21
            dropdownButton.AutoButtonColor = false

            local uc_ddl = Instance.new("UICorner")
            uc_ddl.Parent = dropdownButton
            uc_ddl.CornerRadius = UDim.new(0, 9)

            local dropdownList = Instance.new("Frame")
            dropdownList.Parent = container
            dropdownList.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            dropdownList.Position = UDim2.new(0.52, 0, 1, 5)
            dropdownList.Size = UDim2.new(0.45, 0, 0, 0)
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            dropdownList.ZIndex = 5
            dropdownList.BorderSizePixel = 0

            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = dropdownList
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 2)

            local function closeDropdown()
                dropdownOpen = false
                dropdownList.Visible = false
                dropdownList:TweenSize(UDim2.new(0.45, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
            end

            local function openDropdown()
                dropdownOpen = true
                dropdownList.Visible = true
                local totalHeight = (#options * 30) + ((#options - 1) * 2)
                dropdownList:TweenSize(UDim2.new(0.45, 0, 0, totalHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
            end

            dropdownButton.MouseButton1Click:Connect(function()
                if dropdownOpen then
                    closeDropdown()
                else
                    openDropdown()
                end
            end)

            for i, option in ipairs(options) do
                local optButton = Instance.new("TextButton")
                optButton.Parent = dropdownList
                optButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                optButton.Size = UDim2.new(1, 0, 0, 30)
                optButton.Text = option
                optButton.Font = Enum.Font.Gotham
                optButton.TextColor3 = Color3.fromRGB(12, 12, 12)
                optButton.TextSize = 21
                optButton.AutoButtonColor = false
                optButton.Name = "option"..i

                optButton.MouseButton1Click:Connect(function()
                    selectedOption = option
                    dropdownButton.Text = option
                    closeDropdown()
                    if callback then callback(option) end
                end)
            end

        end

        -- Select the section button by default
        sidebar2.MouseButton1Click:Connect(function()
            sec:Select()
        end)

        return sec
    end

    return window
end

return lib
