local library = loadstring(readfile("AppleLibraryModified/main.lua"))()

local window = library:init("Example", true, Enum.KeyCode.LeftControl, true)

window:Divider("Main Tabs")

-- Main Section
local sec = window:Section("Main Section", "home")

sec:Divider("Elements")
sec:Label("This is a label.")
sec:Paragraph("Paragraph", "This is a paragraph with more detailed information.")

sec:Button("Button", function()
    print("Button clicked!")
end)

sec:Switch("Switch", false, function(state)
    print("Switch is now: ", state)
end)

sec:TextField("Text Field", "Placeholder...", function(text)
    print("Text entered: ", text)
end)

sec:Slider("Slider", 0, 100, 50, function(value)
    print("Slider value: ", value)
end)

sec:Dropdown("Dropdown", {"Option 1", "Option 2", "Option 3"}, "Option 1", function(selected)
    print("Dropdown selected: ", selected)
end)

sec:MultiDropdown("Multi Dropdown", {"Apples", "Bananas", "Cherries"}, {"Apples"}, function(selectedTable)
    print("Multi Dropdown selected: ", table.concat(selectedTable, ", "))
end)

sec:ColorPicker("Colorpicker", Color3.fromRGB(255, 0, 0), function(color)
    print("Color selected: ", color)
end)

sec:Keybind("Keybind", Enum.KeyCode.E, function()
    print("Keybind pressed!")
end)

window:Divider("Other")

local notifSec = window:Section("Notifications", "bell")

notifSec:Button("Temp Notification", function()
    window:TempNotify("Example", "This is a temporary notification.", "bell")
end)

notifSec:Button("Notification 1", function()
    window:Notify("Notify 1", "This is a notification with one button.", "Okay", "info")
end)

notifSec:Button("Notification 2", function()
    window:Notify2("Notify 2", "This is a notification with two buttons.", "Yes", "No", "warning")
end)
