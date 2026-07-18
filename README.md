# Apple Library
UI Library in the style of Apple's MacOS and iPadOS

## Software requirements
Requires a Roblox utility with `gethui()` or `syn.protect_gui` function. Tested on Potassium and Delta.


## How to use?
- Load the UI Library from GitHub repository.
```lua
local library = loadstring(game:HttpGet("https://github.com/RedTree1222/AppleLibraryModified/blob/main/main.lua?raw=true"))()
```
- Create a window.
```lua
local window = library:init("Titlebar", true, Enum.KeyCode.RightShift, true)
```
- Now you can add menus, elements, dividers, etc.
- A [template](/example.lua) is given if you want to see how elements, menus, etc are done.

# Apple Library: Documentation
## Creating window
- Window: It holds everything except temporary notifications.
```lua
local window = library:init(titleText: string, splash: boolean, showHideKeybind: KeyCode, deletePreviousUI: boolean)
```
## Notifications
- Temporary Notification: Appears on top-right corner. Has no buttons but has one icon. Deletes after few seconds.
```lua
window:TempNotify(titleText: string, paragraphText: string, icon: string)
```
- Notification 1: Has one button and one icon. Appears over window.
```lua
window:Notify(titleText: string, paragraphText: string, button1Text: string, icon: string)
```
- Notification 2 Has two buttons and one icon. Appears over window.
```lua
window:Notify2(titleText: string, paragraphText: string, button1Text: string, button2Text: string, icon: string)
```
## Sidebar menus and dividers
- Section Divider: Simple text label to divide sections in sidebar.
```lua
 window:Divider(text: string)
```
- Section: Contains many elements. Returns a table so make sure this is a variable.
```lua
local section = window:Section(text: string)
```
## Section elements
- Divider: Similar to Section Divider.
```lua
section:Divider(text: string)
```
- Label: Texts you can use for notes or further information.
```lua
section:Label(text: string)
```
- Button: Executes callback when clicked.
```lua
section:Button(text: string, callback: function)
```
- Switch: Toggle switch that executes callback with boolean parameter
```lua
section:Switch(text: string, callback: function)
```
- Text Field: Textbox which executes callback when it loses focus.
```lua
section:TextField(text: string, placeholderText: string, callback: function)
```
- Slider: Interactive slider to select a number between a minimum and maximum value.
```lua
section:Slider(text: string, min: number, max: number, default: number, callback: function)
```
- Dropdown: Clickable dropdown menu to select a single option from a list.
```lua
section:Dropdown(text: string, options: table, default: string, callback: function)
```
- Multi Dropdown: Clickable dropdown menu to select multiple options from a list.
```lua
section:MultiDropdown(text: string, options: table, defaultOptions: table, callback: function)
```
- Colorpicker: An interactive color wheel to select a Color3 value.
```lua
section:Colorpicker(text: string, default: Color3, callback: function)
```
- Keybind: A button that listens for a key press to assign a new KeyCode.
```lua
section:Keybind(text: string, default: KeyCode, callback: function)
```

## Miscellanous
- Toggle Visibility: Hides/Shows window.
```lua
window:ToggleVisible()
```
- Green Button: Sets the callback of the green traffic light button.
```lua
window:GreenButton(callback: function)
```

# Apple Library: Images

![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075132.png)

### Window
![image](https://user-images.githubusercontent.com/82454201/221863995-7f86524a-c4ea-4123-8978-d57a99421b7c.png)

### Splash
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075116.png)

### Temporary Notification
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075056.png)

### Notification 1
![image](https://raw.githubusercontent.com/RedTree1222/AppleLibraryModified/main/Assets/Screenshot%202026-07-18%20075104.png)

### Notification 2
# Any inquiries? Contact me on Discord: external.py
