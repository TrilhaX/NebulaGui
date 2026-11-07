-- NebulaGui example — mirrors the mockup (Auto Farm + unit abilities panel)
local Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/TrilhaX/NebulaGui/main/src.lua"))()

local Window = Nebula:Window({
	Title = "OneHub",
	Subtitle = "Anime Adventures",
	Size = Vector2.new(840, 540),       -- start size on PC
	MobileSize = Vector2.new(600, 340), -- start size on phones/tablets
	Folder = "One Hub/_AA_",
	Keybind = Enum.KeyCode.RightControl,
})

-- quick switches behind the sliders button in the top bar (MacLib GlobalSetting)
Window:GlobalSetting({ Name = "Notifications", Default = Window:GetNotificationsState(), Callback = function(v) Window:SetNotificationsState(v) end })
Window:GlobalSetting({ Name = "Show my profile", Default = Window:GetUserInfoState(), Callback = function(v) Window:SetUserInfoState(v) end })
Window:GlobalSetting({ Name = "Low CPU (black screen)", Callback = function(v) Window:SetLowCpu(v) end })

Window:OnUnload(function() print("NebulaGui closed") end)

Window:Category("Main")
local Farm = Window:Tab({ Name = "Auto Farm" })
local Abilities = Window:Tab({ Name = "Unit abilities" })
Window:Category("System")
local Settings = Window:Tab({ Name = "Configs" })

-- Auto Farm ------------------------------------------------------------------
local main = Farm:Section({ Name = "Farm", Side = "Left" })
main:Toggle({ Name = "Auto Start", Description = "Starts the match by itself", Flag = "AutoStart", Callback = print })
-- a gear next to the switch opens a side panel with more options
main:Toggle({ Name = "Auto Replay", Flag = "AutoReplay", Callback = print, Settings = function(panel)
	panel:Stepper({ Name = "Replays before leaving", Min = 0, Max = 50, Default = 10, Flag = "ReplayCount" })
	panel:Toggle({ Name = "Stop on low HP", Flag = "ReplayStopHP" })
	panel:InfoBox({ Title = "Tip", Text = "0 means replay forever." })
end })
-- or a row that is only a gear
main:Gear({ Name = "Webhook options", Description = "What gets sent to Discord", Build = function(panel)
	panel:Toggle({ Name = "Send on win", Default = true, Flag = "WhWin" })
	panel:Toggle({ Name = "Send on loss", Flag = "WhLoss" })
	panel:Dropdown({ Name = "Ping", Options = { "Nobody", "Me", "@everyone" }, Default = "Me", Flag = "WhPing" })
end })
main:Dropdown({ Name = "Map", Options = { "Planet Namak", "Shiganshina", "Snowy Town", "Hidden Sand Village" }, Default = "Planet Namak", Flag = "Map", Callback = print })
main:Button({ Name = "Join now", Primary = true, Callback = function()
	Window:Notify({ Title = "Joining", Content = "Teleporting to the selected map." })
end })

local tune = Farm:Section({ Name = "Farm settings", Side = "Right" })
tune:Slider({ Name = "Delay", Min = 0, Max = 2, Step = 0.1, Default = 0.4, Suffix = "s", Flag = "Delay" })
tune:Slider({ Name = "Max wave", Min = 1, Max = 50, Default = 25, Flag = "MaxWave" })
tune:Slider({ Name = "Leave automatically after this many wins", Min = 0, Max = 20, Default = 3, Flag = "LeaveAfter" })
tune:Input({ Name = "Webhook", Placeholder = "https://discord.com/api/…", Flag = "Webhook" })
tune:Keybind({ Name = "Panic key", Default = Enum.KeyCode.P, Flag = "PanicKey", Callback = function() print("panic") end })

-- Unit abilities ---------------------------------------------------------------
local ab = Abilities:Section({ Name = "Unit abilities", Side = "Left" })
local preview = ab:Card({ Title = "Carrot (Ultra)", Image = "" })
ab:Dropdown({ Name = "Units with abilities", Options = { "Carrot (Ultra)", "Sprintwagon", "Kazzy" }, Default = "Carrot (Ultra)", Callback = function(v) preview:Set(v) end })
ab:Toggle({ Name = "Use ability", Default = true, Flag = "UseAbility" })
ab:Slider({ Name = "Start from wave", Min = 0, Max = 50, Default = 0, Flag = "AbilityWave" })
ab:Segmented({ Name = "After the last step", Options = { "Cycle", "Once" }, Default = "Cycle", Flag = "AbilityMode" })

local steps = ab:Collapsible({ Name = "Add a step", Open = true })
local copy = steps:Stepper({ Name = "Copy (#)", Min = 1, Max = 6, Default = 1 })
local waitS = steps:Stepper({ Name = "Wait before casting (seconds)", Min = 0, Max = 120, Default = 0 })
steps:Toggle({ Name = "Wait for a boss in range" })
steps:Stepper({ Name = "Wait for enemies in range", Min = 0, Max = 20, Default = 0 })
steps:Segmented({ Name = "Conditions", Options = { "And", "Or" } })

local list = ab:ReorderList({
	Items = { "Carrot (Ultra)#1", "10s → Carrot (Ultra)#2", "15s → Carrot (Ultra)#3" },
	Flag = "AbilitySteps",
	Callback = function(items) print("order:", table.concat(items, " | ")) end,
})
steps:Button({ Name = "Add step", Primary = true, Callback = function()
	local w = waitS:Get()
	list:Add((w > 0 and (w .. "s → ") or "") .. "Carrot (Ultra)#" .. copy:Get())
end })
list:SetActive(2)
ab:Value({ Name = "Now on", Value = "Step 2" })
ab:InfoBox({
	Title = "Information",
	Text = "Each step waits for its conditions, then casts that copy's ability (#1 is the first one placed). Time counts from the previous cast. Copies that aren't on the map are skipped. Cycle starts again from the first step; Once stops after the last.",
})

-- Configs + interface extras (UI size, hide, low CPU, FPS boost, hide character…) ---
Window:ConfigSection(Settings)
Window:SettingsSection(Settings)

local look = Settings:Section({ Name = "Look" })
look:Header("Colors")
look:Colorpicker({ Name = "Accent", Default = Color3.fromHex("8B5CF6"), Flag = "Accent", Callback = print })
look:SubLabel("Accent changes apply to new elements only.")

Window:LoadAutoConfig()
