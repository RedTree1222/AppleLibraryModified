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

        function sec:Dropdown(name, options, default, callback)
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
            dropdown.Text = name
        
            local frame = Instance.new("TextButton")
            frame.Parent = dropdown
            frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            frame.Position = UDim2.new(0.55, 0, 0.1, 0)
            frame.Size = UDim2.new(0, 180, 0, 30)
            frame.AutoButtonColor = true
            frame.Text = ""
            
            local uc_frame = Instance.new("UICorner")
            uc_frame.CornerRadius = UDim.new(0, 9)
            uc_frame.Parent = frame
        
            local selectedText = Instance.new("TextLabel")
            selectedText.Parent = frame
            selectedText.BackgroundTransparency = 1
            selectedText.Size = UDim2.new(1, -20, 1, 0)
            selectedText.Position = UDim2.new(0, 5, 0, 0)
            selectedText.Font = Enum.Font.Gotham
            selectedText.TextSize = 18
            selectedText.TextColor3 = Color3.fromRGB(21, 103, 251)
            selectedText.TextXAlignment = Enum.TextXAlignment.Left
            selectedText.Text = default or "Select..."
        
            local arrow = Instance.new("TextLabel")
            arrow.Parent = frame
            arrow.BackgroundTransparency = 1
            arrow.Size = UDim2.new(0, 15, 1, 0)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 18
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.fromRGB(95, 95, 95)
        
            local dropdownList = Instance.new("Frame")
            dropdownList.Parent = dropdown
            dropdownList.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            dropdownList.Position = UDim2.new(0.55, 0, 1, 5)
            dropdownList.Size = UDim2.new(0, 180, 0, 0)
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
        
            local uc_list = Instance.new("UICorner")
            uc_list.CornerRadius = UDim.new(0, 9)
            uc_list.Parent = dropdownList
        
            local ui_list_layout = Instance.new("UIListLayout")
            ui_list_layout.Parent = dropdownList
            ui_list_layout.SortOrder = Enum.SortOrder.LayoutOrder
            ui_list_layout.Padding = UDim.new(0, 2)
        
            local expanded = false
        
            local function toggleDropdown()
                if expanded then
                    expanded = false
                    dropdownList:TweenSize(UDim2.new(0, 180, 0, 0), "Out", "Quad", 0.2, true)
                    task.delay(0.2, function()
                        dropdownList.Visible = false
                    end)
                    arrow.Text = "▼"
                else
                    expanded = true
                    dropdownList.Visible = true
                    local height = #options * 30 + 4
                    dropdownList:TweenSize(UDim2.new(0, 180, 0, height), "Out", "Quad", 0.2, true)
                    arrow.Text = "▲"
                end
            end
        
            frame.MouseButton1Click:Connect(toggleDropdown)
            dropdown.MouseButton1Click:Connect(toggleDropdown)
        
            -- Clear old options (if any)
            for _, child in pairs(dropdownList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
        
            -- Create option buttons
            for i, option in ipairs(options) do
                local optionBtn = Instance.new("TextButton")
                optionBtn.Name = "Option_" .. i
                optionBtn.Parent = dropdownList
                optionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                optionBtn.Size = UDim2.new(1, -4, 0, 30)
                optionBtn.Position = UDim2.new(0, 2, 0, (i-1)*30)
                optionBtn.Font = Enum.Font.Gotham
                optionBtn.TextSize = 18
                optionBtn.TextColor3 = Color3.fromRGB(21, 103, 251)
                optionBtn.Text = option
                optionBtn.AutoButtonColor = true
        
                local uc_opt = Instance.new("UICorner")
                uc_opt.CornerRadius = UDim.new(0, 6)
                uc_opt.Parent = optionBtn
        
                optionBtn.MouseButton1Click:Connect(function()
                    selectedText.Text = option
                    toggleDropdown()
                    if callback then
                        callback(option)
                    end
                end)
            end
        
            return dropdown
        end


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
