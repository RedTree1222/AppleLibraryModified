# apple library
ui library that looks like apple's macos and ipados.

## what you need
you need an executor with `gethui()` or `syn.protect_gui`. tested on potassium and delta.

## how to use
load it directly from github:
```lua
local library = loadstring(game:HttpGet("https://github.com/RedTree1222/AppleLibraryModified/blob/main/main.lua?raw=true"))()
```

make a window:
```lua
local window = library:init("title text", true, Enum.KeyCode.LeftControl, true)
```

check out the [example](example_test.lua) if you want to see everything in action.

# docs
## window stuff
holds everything.
```lua
local window = library:init(titleText: string, splash: boolean, showHideKeybind: KeyCode, deletePreviousUI: boolean)
```

## notifications
- temp notify: pops up top-right, no buttons, leaves on its own.
```lua
window:TempNotify(titleText: string, paragraphText: string, icon: string)
```
- notify 1: one button, pops up over the window.
```lua
window:Notify(titleText: string, paragraphText: string, button1Text: string, icon: string)
```
- notify 2: two buttons, pops up over window.
```lua
window:Notify2(titleText: string, paragraphText: string, button1Text: string, button2Text: string, icon: string)
```

## sidebar
- divider: just text to split things in the sidebar.
```lua
window:Divider(text: string)
```
- section/tab: holds your elements. returns a table.
  you can pass a second arg for the icon. The library now integrates all **1,747 official Lucide icons** dynamically!
  You can use any Lucide icon name.
  Check out [lucide.dev/icons](https://lucide.dev/icons) for the full list of supported names.
  
  If you want to use a custom image, you can still pass ANY direct Roblox asset ID as well!
  ```lua
  local section = window:Section(text: string, icon: string)
  -- Example using built-in Lucide:
  local sec1 = window:Section("Main", "swords")
  -- Example using custom asset ID:
  local sec2 = window:Section("Custom", "rbxassetid://123456789")
  ```

## elements
- divider: splits elements.
```lua
section:Divider(text: string)
```
- label: just text for notes.
```lua
section:Label(text: string)
```
- paragraph: bigger text block.
```lua
section:Paragraph(title: string, content: string)
```
- button: clicks and does stuff.
```lua
section:Button(text: string, callback: function)
```
- switch: on/off toggle.
```lua
section:Switch(text: string, callback: function)
```
- text field: type stuff in.
```lua
section:TextField(text: string, placeholderText: string, callback: function)
```
- slider: slide to pick a number.
```lua
section:Slider(text: string, min: number, max: number, default: number, callback: function)
```
- dropdown: pick one thing from a list.
```lua
section:Dropdown(text: string, options: table, default: string, callback: function)
```
- multi dropdown: pick lots of things from a list.
```lua
section:MultiDropdown(text: string, options: table, defaultOptions: table, callback: function)
```
- colorpicker: pick a color.
```lua
section:Colorpicker(text: string, default: Color3, callback: function)
```
- keybind: press a key to set it.
```lua
section:Keybind(text: string, default: KeyCode, callback: function)
```

## extra stuff
- hide/show:
```lua
window:ToggleVisible()
```
- extra mode: click the green button top left to swap to your settings/credits.
- collapse: click the bottom left button to shrink the sidebar to just icons (exactly like obsidian).
- custom cursor: uses obsidian style hand pointer when hovering over things. you can disable this in the settings tab.

# images
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075132.png)
### window
![image](https://user-images.githubusercontent.com/82454201/221863995-7f86524a-c4ea-4123-8978-d57a99421b7c.png)
### splash
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075116.png)
### temp notif
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075056.png)

got questions? dm me on discord: external.py
