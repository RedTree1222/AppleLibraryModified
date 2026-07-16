local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/refs/heads/main/main.lua"))()

local window = library:init("Titlebar", true, Enum.KeyCode.LeftControl, true)

window:Divider("Navigation")

local sectionA = window:Section("Elements")

sectionA:Divider("Basic")

sectionA:Button("Click me!", function()
    print("clicked")
end)

sectionA:Label("Lorem ipsum dolor sit amet.")

sectionA:Switch("Toggle me!", false, function(a)
    print(a)
end)

sectionA:TextField("Enter text", "Type here...", function(a)
    print(a)
end)

sectionA:Divider("New")

sectionA:Slider("Slider", 0, 100, 50, function(v)
    print(v)
end)

sectionA:Dropdown("Dropdown", {"One", "Two", "Three"}, "One", function(v)
    print(v)
end)

sectionA:ColorPicker("Color", Color3.fromRGB(21, 103, 251), function(c)
    print(c)
end)

sectionA:Keybind("Keybind", Enum.KeyCode.F, function()
    print("keybind fired")
end)

sectionA:Paragraph("Hello!", "This is a paragraph with some content below the title.")

window:Divider("Notifications")

local sectionB = window:Section("Notifications")

sectionB:Button("Temp Notify", function()
    window:TempNotify("Heads up!", "Something happened.", "rbxassetid://12608259004")
end)

sectionB:Button("Notify 1", function()
    window:Notify("Hello!", "I am a notification", "OK", "rbxassetid://12608259004", function()
        print(1)
    end)
end)

sectionB:Button("Notify 2", function()
    window:Notify2("Hello!", "I am a notification", "Yes", "No", "rbxassetid://12608259004", function()
        print(1)
    end, function()
        print(2)
    end)
end)

window:GreenButton(function()
    print("green button clicked")
end)

sectionA:Select()
