# NebulaGui

UI library for Roblox executor scripts. Deep black and violet with a lilac glow, made for PC and mobile.

```lua
local Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/TrilhaX/NebulaGui/main/src.lua"))()
```

A full example that matches the design mockup is in [`example.lua`](example.lua).

## Highlights

- **Responsive.** The window fits the screen and follows rotation. Below 640 px wide the tab list becomes a slide-in drawer and the search collapses to an icon. When there isn't room for two columns, sections drop to one.
- **Aligned rows.** Slider names, bars and values line up in columns. A long name moves the control to its own line instead of squeezing it.
- **Auto-translate.** Uses Google with 8 languages (EN, PT, ES, RU, TH, VI, ID, FI). The language is detected from the Roblox locale and can be changed from the globe button. Translations are cached in `NebulaGui/i18n/`.
- **Search** in the top bar (Ctrl+F). Picking a result opens its tab, expands collapsed groups, scrolls to the element and highlights it.
- **Floating button** you can drag, which opens and closes the window. Its position is remembered.
- **Notifications, dialogs and configs** (save, load, delete, load on start).
- **Executor-safe.** UI goes in `gethui()` or `CoreGui` (never `PlayerGui`), there are no global hooks, and the file compiles with `luau-compile -O0`. The avatar uses `rbxthumb://` and the ScreenGui uses safe-area insets.

## API

### Window

```lua
local Window = Nebula:Window({
	Title = "OneHub",
	Subtitle = "Anime Adventures",
	Size = Vector2.new(840, 540),      -- desired size; shrinks to fit the screen
	Folder = "One Hub/_AA_",           -- where configs + settings are saved
	Keybind = Enum.KeyCode.RightControl,
	Language = "en",                   -- optional, otherwise saved choice / Roblox locale
	Theme = { Accent = Color3.fromHex("8B5CF6") }, -- optional overrides
	FloatingButton = true,
	HideProfile = false,
	StartHidden = false,
	CloseConfirm = true,
})
```

| Method | Description |
| --- | --- |
| `Window:Category(name)` | Small heading in the tab list |
| `Window:Tab({ Name, Icon? })` | Adds a tab; returns a `Tab` |
| `Window:Notify({ Title, Content?, Duration?, Icon?, Translate? })` | Toast at the bottom right |
| `Window:Dialog({ Title, Content?, Buttons = {{ Name, Primary?, Callback? }} })` | Modal dialog |
| `Window:SetVisible(bool)` / `Window:Toggle()` | Show or hide the window |
| `Window:SetKeybind(KeyCode)` | Changes the toggle key |
| `Window:SetLanguage("pt")` | Changes the language |
| `Window:SaveConfig(name)` / `LoadConfig` / `DeleteConfig` / `ListConfigs()` | Configs (every element with a `Flag`) |
| `Window:ConfigSection(tab)` | Ready-made configs UI |
| `Window:LoadAutoConfig()` | Call at the end of your script |
| `Window:Destroy()` | Removes everything and disconnects all signals |
| `Window.Flags[flag]` | Access any flagged element |

### Tab and Section

```lua
local Tab = Window:Tab({ Name = "Auto Farm" })
local Section = Tab:Section({ Name = "Farm", Side = "Left" }) -- "Left" | "Right"
```

### Elements

Every element is available on a `Section` and on a `Collapsible`. Elements that take a `Flag` have `:Set(value, silent?)` and `:Get()`. All elements also have `:SetVisible(bool)` and `:Destroy()`.

| Element | Options | Extra methods |
| --- | --- | --- |
| `Toggle` | `Name, Description?, Default, Flag, Callback(bool)` | |
| `Slider` | `Name, Min, Max, Step, Default, Suffix?, Flag, Callback(number)` | |
| `Input` | `Name, Placeholder?, Default?, Numeric?, Live?, Width?, Flag, Callback(text)` | |
| `Dropdown` | `Name, Options, Default?, Multi?, Placeholder?, Width?, Flag, Callback(value \| {values})` | `:Refresh(options, keepSelection?)` |
| `Button` | `Name, Primary?, Callback()` | `:SetText(text)` |
| `Stepper` | `Name, Min?, Max?, Step?, Default?, Flag, Callback(number)` | |
| `Segmented` | `Name, Options, Default?, Width?, Flag, Callback(option)` | |
| `Keybind` | `Name, Default?, Flag, Callback()` (key pressed), `Changed(KeyCode?)` | |
| `Label` | `Text` (or a string), `Size?`, `Color?` | `:Set(text)` |
| `Paragraph` | `Title, Content` | `:Set(title?, content?)` |
| `Value` | `Name, Value` | `:Set(value)` |
| `Card` | `Title, Image?, ImageSize?` | `:Set(title?, image?)` |
| `InfoBox` | `Title?, Text, Open?` | `:Set(text)` |
| `Collapsible` | `Name, Open?` | returns a container that has every element above |
| `ReorderList` | `Items, Flag, Callback(items), OnRemove(item, index)?` | `:Add(item)`, `:SetActive(index)` |
| `Divider` | | |

Option names in `Segmented` are shown translated, but callbacks always receive the original value. Dropdown options and list items are never translated.

## Theme

| Token | Hex |
| --- | --- |
| Background | `#07060B` |
| Surface | `#100C18` |
| Elevated | `#181225` |
| Border | `#2A2140` |
| Accent (violet) | `#8B5CF6` |
| Glow (lilac) | `#C4B5FD` |
| Text | `#EEEAF8` |
| Muted | `#A49CBA` |

Font: Montserrat.
