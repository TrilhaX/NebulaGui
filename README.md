# NebulaGui

UI library for Roblox executor scripts. Deep black and violet with a lilac glow, made for PC and mobile.

```lua
local Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/TrilhaX/NebulaGui/main/src.lua"))()
```

A full example that matches the design mockup is in [`example.lua`](example.lua).

## Highlights

- **Responsive.** The window fits the screen and follows rotation. Drag the bottom-right corner to resize it to any size (mouse or touch), from 260×200 up to the full screen. Below 640 px wide the tab list becomes a slide-in drawer and the search collapses to an icon. When there isn't room for two columns, sections drop to one.
- **Aligned rows.** Slider names, bars and values line up in columns. A long name moves the control to its own line instead of squeezing it.
- **Auto-translate.** Uses Google with 8 languages (EN, PT, ES, RU, TH, VI, ID, FI). The language is detected from the Roblox locale and can be changed from the globe button. Translations are cached in `NebulaGui/i18n/`.
- **Search** in the top bar (Ctrl+F). Picking a result opens its tab, expands collapsed groups, scrolls to the element and highlights it.
- **Floating button** you can drag, which opens and closes the window. Its position is remembered. Closing works like a black hole: it tugs at the pieces of the UI closest to it, then grabs more and more, faster and faster, until the empty window is swallowed. Opening spits everything out in a mess that quickly snaps back into place (`BlackHole = false` turns this off).
- **Notifications, dialogs and configs** (save, load, delete, load on start).
- **Executor-safe.** UI goes in `gethui()` or `CoreGui` (never `PlayerGui`), there are no global hooks, and the file compiles with `luau-compile -O0`. The avatar uses `rbxthumb://` and the ScreenGui uses safe-area insets.

## API

### Window

```lua
local Window = Nebula:Window({
	Title = "OneHub",
	Subtitle = "Anime Adventures",
	Logo = "rbxassetid://100199291949935", -- hub logo (default: OneHub); false = drawn nebula
	Size = Vector2.new(840, 540),      -- start size on PC (always; resizing isn't saved)
	MobileSize = Vector2.new(600, 340), -- start size on touch devices
	Folder = "One Hub/_AA_",           -- where configs + settings are saved
	Keybind = Enum.KeyCode.RightControl,
	Language = "en",                   -- optional, otherwise saved choice / Roblox locale
	Theme = { Accent = Color3.fromHex("8B5CF6") }, -- optional overrides
	FloatingButton = true,
	HideProfile = false,
	StartHidden = false,
	CloseConfirm = true,
	BlackHole = true,                  -- UI torn apart into / spat out of the floating button
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
| `Window:CloseAnimated()` | Same as `Destroy()`, but first a black hole opens in the window, swallows it and the floating button, and collapses in a flash (used by the X button) |
| `Window.Flags[flag]` | Access any flagged element |
| `Window:HideUI(bool)` / `SetState` / `GetState` | MacLib-style show/hide |
| `Window:SetScale(0.5–1.5)` / `GetScale()` | UI size (saved) |
| `Window:SetSize(Vector2)` / `SetTitle` / `SetSubtitle` | Window info |
| `Window:SetNotificationsState(bool)` | Turns toasts on or off (saved) |
| `Window:SetUserInfoHidden(bool)` / `SetUserInfoState(shown)` | Masks avatar + names (also the eye button on the profile card) |
| `Window:SetLowCpu(bool)` | Stops 3D rendering + black screen, UI stays on top |
| `Window:SetFPSBoost(bool)` | Lower graphics; `false` restores everything |
| `Window:SetHidePlayer(bool)` | Hides your name tag, face, clothes and accessories locally; reversible |
| `Window:GlobalSetting({ Name, Default, Callback })` | Switch in the top-bar quick menu; returns `:Set/:Get` |
| `Window:SettingsSection(tab)` | Ready-made "Interface" section with all of the above |
| `Window:Close()` | Asks, then destroys |
| `Window:ResetSize()` | Back to the device's start size and centered |
| `Window:OpenPanel({ Title, Build })` / `ClosePanel()` | Side panel to the right of the window (inside it when there's no room) |
| `Window:OnUnload(fn)` | Runs when the UI is destroyed (all extras are undone automatically) |

### Tab and Section

```lua
local Tab = Window:Tab({ Name = "Auto Farm" })
local Section = Tab:Section({ Name = "Farm", Description = "Optional subtitle", Side = "Left" }) -- "Left" | "Right"
```

### Elements

Every element is available on a `Section` and on a `Collapsible`. Elements that take a `Flag` have `:Set(value, silent?)` and `:Get()`. All elements also have `:SetVisible(bool)`, `:SetDisabled(bool)` (dims and blocks input) and `:Destroy()`.

| Element | Options | Extra methods |
| --- | --- | --- |
| `Toggle` | `Name, Description?, Default, Flag, Callback(bool)` | |
| `Slider` | `Name, Min, Max, Step, Default, Suffix?, Flag, Callback(number)` | |
| `Input` | `Name, Placeholder?, Default?, Numeric?, Live?, Width?, Flag, Callback(text)` | |
| `Dropdown` | `Name, Options, Default?, Multi?, Placeholder?, Width?, Search?, Flag, Callback(value \| {values})` | `:Refresh(options, keepSelection?)` |
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
| `ReorderList` | `Items, Flag, Callback(items)` + options below | `:Add(item, at?)`, `:Remove(i)`, `:Update(i, item)`, `:Move(from, to)`, `:Clear()`, `:Count()`, `:SetActive(i)` |
| `Divider` | | |
| `Header` | `Name` (or a string) | `:Set(text)` |
| `SubLabel` | `Text` (or a string) | `:Set(text)` |
| `Spacer` | height (number) | |
| `Gear` | `Name, Description?, Title?, Build(panel)` | `:Open()`, `:Close()` |
| `Colorpicker` | `Name, Default (Color3), Flag, Callback(Color3)` | `:SetColor(c)`, `:GetColor()` (`:Get()` returns hex for configs) |

Any element with a name and a control (Toggle, Slider-free rows like Dropdown, Input, Stepper, Segmented, Keybind, Colorpicker) accepts `Settings = function(panel) ... end`: a gear appears next to the control and opens the side panel, where `panel` has every element.

The whole UI hides while Roblox's own menu (Esc / Leave) is open, so it never covers it.

`Input` also takes `AcceptedCharacters` (`"Numeric"`, `"Alphabetic"`, `"AlphaNumeric"`), `MaxLength` and `Changed(text)` for every keystroke.
`Dropdown` also has `:AddOptions`, `:RemoveOptions`, `:ClearOptions`, `:GetOptions`, `:IsOption`. `Search = true` always shows a search box at the top of the list (Enter picks the first match), `Search = false` hides it; by default it appears when there are more than 6 options. `Searchable` works as an alias.
Every element has `:SetName(text)`; MacLib names (`UpdateName`, `SetVisibility`, `UpdateSelection`, `InsertOptions`, `UpdateText`, `GetInput`) work as aliases.

Option names in `Segmented` are shown translated, but callbacks always receive the original value. Dropdown options and list items are never translated.

### ReorderList options

List-wide (all optional):

| Option | Default | Effect |
| --- | --- | --- |
| `Removable` | `true` | Shows the Remove button on every row |
| `Reorderable` | `true` | `false` turns off dragging and the arrows |
| `Draggable` / `Arrows` | `true` | Turns off only the grip or only the ↑↓ |
| `Numbered` | `true` | Number badge on the left |
| `RemoveText` | `"Remove"` | Remove button text |
| `ConfirmRemove` | `false` | Asks before removing |
| `EmptyText` | `"Nothing here yet"` | Shown when empty (`false` hides it) |
| `MaxItems` | none | `:Add` returns `false` when full |
| `Format(item, index)` | | Custom row text |
| `OnRemove(item, i)`, `OnMove(item, from, to)`, `OnClick(item, i)` | | Events |

Per item, use a table instead of a plain value:

```lua
list:Add({ Text = "Carrot (Ultra)#1", Description = "Opens the match", Removable = false, Locked = true })
```

| Field | Effect |
| --- | --- |
| `Text` | Row text (`Value` also works) |
| `Description` | Small second line |
| `Removable` | Overrides the list's `Removable` for this row |
| `Locked` | Pinned: can't be moved, and other rows can't jump over it |
| `Badge` | Text in the badge instead of the number |
| `Color` | Badge color (`Color3`) |

## Types

`src.lua` runs in `--!nonstrict` and exports option types for every constructor (`WindowOptions`, `ToggleOptions`, `SliderOptions`, `DropdownOptions`…), so Studio's type checker flags misspelled or wrong-typed options inside the library. Scripts that load it with `loadstring` don't receive these types — that's a Luau limitation, not a missing feature.

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

Icons: the gear, the globe and the eye (show/hide profile) use Creator Store images, set in `Nebula.Icons` and replaceable with `Nebula:Window({ Icons = { gear = "rbxassetid://…" } })`; other icons are drawn.

Font: Montserrat. Corners are scaled by `Theme.Roundness` (default `1.65`; `1` is squarer).
