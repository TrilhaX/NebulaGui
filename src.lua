--!nonstrict
--[[
	NebulaGui
	UI library for Roblox executor scripts — deep black & violet, nebula glow.
	https://github.com/TrilhaX/NebulaGui

	Rules this file follows:
	  * no function has more than ~60 locals (executor compiles with -O0, limit is 200)
	  * no global hooks (no hookfunction / hookmetamethod / getgenv writes)
	  * UI lives in gethui() or CoreGui, never PlayerGui
]]

local cloneref = cloneref or function(o) return o end
local Svc = setmetatable({}, {
	__index = function(t, k)
		local s = cloneref(game:GetService(k))
		rawset(t, k, s)
		return s
	end,
})

local Nebula = { Version = "0.1.0", Windows = {} }

-- image icons (Creator Store assets, loaded through rbxthumb so decal ids work too).
-- any kind not listed here is drawn with frames. Override with Nebula:Window({ Icons = { gear = "rbxassetid://..." } })
-- each icon tries these sources in order; if none loads, the drawn version stays
local function src(id) return { "rbxassetid://" .. id, "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150" } end
Nebula.Icons = {
	gear = src(130522520017662),
	eye = src(6523858422),
	eyeoff = src(133178224707634),
	globe = src(11395780614),
}
local T = {} -- theme
local F = {} -- fonts
local U = {} -- utilities
local Tr = {} -- translator
local FS = {} -- file system
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Container = {}
Container.__index = Container

---------------------------------------------------------------------------
-- Theme & fonts
---------------------------------------------------------------------------
do
	local hex = Color3.fromHex
	T.Background = hex("07060B")
	T.Surface = hex("100C18")
	T.Sidebar = hex("0B0812")
	T.Elevated = hex("181225")
	T.Elevated2 = hex("241B38")
	T.Border = hex("2A2140")
	T.BorderHi = hex("3B2D5C")
	T.Accent = hex("8B5CF6")
	T.Glow = hex("C4B5FD")
	T.Text = hex("EEEAF8")
	T.Muted = hex("A49CBA")
	T.Faint = hex("5E5577")
	T.Danger = hex("F472B6")
	T.DangerText = hex("F9A8D4")
	T.White = Color3.new(1, 1, 1)
	T.Roundness = 1.65 -- multiplies every corner radius (1 = original, higher = rounder)

	local fam = "rbxasset://fonts/families/Montserrat.json"
	F.Regular = Font.new(fam, Enum.FontWeight.Regular)
	F.Medium = Font.new(fam, Enum.FontWeight.Medium)
	F.SemiBold = Font.new(fam, Enum.FontWeight.SemiBold)
	F.Bold = Font.new(fam, Enum.FontWeight.Bold)

	local ok = pcall(function() return Enum.Font.Montserrat end)
	F.Measure = ok and Enum.Font.Montserrat or Enum.Font.Gotham
end

Nebula.Theme = T

---------------------------------------------------------------------------
-- Public option types (documentation + checked by Studio's type checker)
---------------------------------------------------------------------------
type Callback<T> = ((T) -> ())?

export type WindowOptions = {
	Title: string?,
	Subtitle: string?,
	Logo: (string | boolean)?,
	Icons: { [string]: string | { string } }?,
	Theme: { [string]: any }?,
	Size: (Vector2 | UDim2)?,
	MobileSize: (Vector2 | UDim2)?,
	Folder: string?,
	Keybind: EnumItem?,
	Language: string?,
	Scale: number?,
	CloseConfirm: boolean?,
	HideNotice: boolean?,
	BlackHole: boolean?,
	HideUserInfo: boolean?,
	HideProfile: boolean?,
	FloatingButton: boolean?,
	FloatImage: string?,
	StartHidden: boolean?,
}

-- fields every named row understands (Settings adds a gear that opens the side panel)
type RowOptions = {
	Name: string?,
	Description: string?,
	Flag: string?,
	Settings: ((panel: any) -> ())?,
	SettingsTitle: string?,
}

export type ToggleOptions = RowOptions & { Default: boolean?, Callback: Callback<boolean> }
export type SliderOptions = RowOptions & {
	Min: number?, Max: number?, Step: number?, Increment: number?, Default: number?, Suffix: string?,
	Callback: Callback<number>,
}
export type InputOptions = RowOptions & {
	Placeholder: string?, Default: string?, Width: number?, Numeric: boolean?, MaxLength: number?,
	AcceptedCharacters: ("All" | "Numeric" | "Alphabetic" | "AlphaNumeric")?,
	Live: boolean?, Changed: Callback<string>, onChanged: Callback<string>, Callback: Callback<string>,
}
export type DropdownOptions = RowOptions & {
	Options: { any }?, Default: any, Multi: boolean?, Placeholder: string?, Width: number?,
	Search: boolean?, Callback: Callback<any>,
}
export type ButtonOptions = { Name: string?, Primary: boolean?, Flag: string?, Callback: (() -> ())? }
export type StepperOptions = RowOptions & { Min: number?, Max: number?, Step: number?, Default: number?, Callback: Callback<number> }
export type SegmentedOptions = RowOptions & { Options: { any }?, Default: any, Width: number?, Callback: Callback<any> }
export type KeybindOptions = RowOptions & { Default: (EnumItem | string)?, Callback: (() -> ())?, Changed: Callback<EnumItem?> }
export type ColorpickerOptions = RowOptions & { Default: (Color3 | string)?, Callback: Callback<Color3> }
export type LabelOptions = { Text: string?, Size: number?, Color: Color3?, Flag: string? }
export type ParagraphOptions = { Title: string?, Content: string?, Flag: string? }
export type ValueOptions = { Name: string?, Value: any, Flag: string? }
export type CardOptions = { Title: string?, Image: string?, ImageSize: number?, Flag: string? }
export type InfoBoxOptions = { Title: string?, Text: string?, Content: string?, Open: boolean?, Flag: string? }
export type CollapsibleOptions = { Name: string?, Open: boolean? }
export type GearOptions = { Name: string?, Description: string?, Title: string?, Build: ((panel: any) -> ())?, Settings: ((panel: any) -> ())?, Flag: string? }
export type HeaderOptions = { Name: string?, Text: string?, Flag: string? }
-- an item can be a plain value or { Text, Description?, Removable?, Locked?, Badge?, Color? }
export type ReorderItem = any
export type ReorderListOptions = {
	Items: { ReorderItem }?, Flag: string?,
	Removable: boolean?, Reorderable: boolean?, Draggable: boolean?, Arrows: boolean?, Numbered: boolean?,
	RemoveText: string?, ConfirmRemove: boolean?, EmptyText: (string | boolean)?, MaxItems: number?,
	Format: ((item: ReorderItem, index: number) -> string)?,
	Callback: Callback<{ ReorderItem }>,
	OnRemove: ((item: ReorderItem, index: number) -> ())?,
	OnMove: ((item: ReorderItem, from: number, to: number) -> ())?,
	OnClick: ((item: ReorderItem, index: number) -> ())?,
}
export type TabOptions = { Name: string?, Icon: string? }
export type SectionOptions = { Name: string?, Description: string?, Side: ("Left" | "Right")? }
export type NotifyOptions = { Title: string?, Content: string?, Duration: number?, Icon: string?, Translate: boolean?, Force: boolean? }
export type DialogButton = { Name: string?, Primary: boolean?, Callback: (() -> ())? }
export type DialogOptions = { Title: string?, Content: string?, Buttons: { DialogButton }? }
export type GlobalSettingOptions = { Name: string?, Default: boolean?, Callback: Callback<boolean> }
export type PanelOptions = { Title: string?, Build: ((panel: any) -> ())?, Key: any, OnState: Callback<boolean> }

---------------------------------------------------------------------------
-- File system (all optional — every call is guarded)
---------------------------------------------------------------------------
do
	local function has(f) return type(f) == "function" end

	function FS.ok() return has(writefile) and has(readfile) and has(isfile) end

	function FS.mkdir(path)
		if not (has(makefolder) and has(isfolder)) then return end
		local acc = ""
		for part in string.gmatch(path, "[^/\\]+") do
			acc = (acc == "") and part or (acc .. "/" .. part)
			local ok, exists = pcall(isfolder, acc)
			if ok and not exists then pcall(makefolder, acc) end
		end
	end

	function FS.read(p)
		if not FS.ok() then return nil end
		local ok, r = pcall(function()
			if isfile(p) then return readfile(p) end
			return nil
		end)
		return ok and r or nil
	end

	function FS.write(p, s)
		if not FS.ok() then return false end
		return (pcall(writefile, p, s))
	end

	function FS.del(p)
		if has(delfile) then return (pcall(delfile, p)) end
		return false
	end

	function FS.list(dir)
		if not has(listfiles) then return {} end
		local ok, r = pcall(listfiles, dir)
		return (ok and type(r) == "table") and r or {}
	end

	function FS.readJSON(p)
		local s = FS.read(p)
		if not s then return nil end
		local ok, d = pcall(Svc.HttpService.JSONDecode, Svc.HttpService, s)
		return (ok and type(d) == "table") and d or nil
	end

	function FS.writeJSON(p, d)
		local ok, s = pcall(Svc.HttpService.JSONEncode, Svc.HttpService, d)
		if ok then return FS.write(p, s) end
		return false
	end
end

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
do
	function U.new(class, props)
		local o = Instance.new(class)
		local parent
		for k, v in pairs(props or {}) do
			if k == "Parent" then parent = v else o[k] = v end
		end
		if o:IsA("GuiObject") and (props == nil or props.BorderSizePixel == nil) then
			o.BorderSizePixel = 0
		end
		if parent then o.Parent = parent end
		return o
	end

	function U.corner(o, r)
		return U.new("UICorner", { Parent = o, CornerRadius = UDim.new(0, math.floor((r or 8) * T.Roundness + 0.5)) })
	end

	function U.round(o)
		return U.new("UICorner", { Parent = o, CornerRadius = UDim.new(1, 0) })
	end

	function U.stroke(o, color, transparency, thickness)
		return U.new("UIStroke", {
			Parent = o,
			Color = color or T.Border,
			Transparency = transparency or 0,
			Thickness = thickness or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	end

	function U.pad(o, t, r, b, l)
		return U.new("UIPadding", {
			Parent = o,
			PaddingTop = UDim.new(0, t or 0),
			PaddingRight = UDim.new(0, r or t or 0),
			PaddingBottom = UDim.new(0, b or t or 0),
			PaddingLeft = UDim.new(0, l or r or t or 0),
		})
	end

	function U.list(o, padding, horizontal)
		return U.new("UIListLayout", {
			Parent = o,
			Padding = UDim.new(0, padding or 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		})
	end

	function U.text(props)
		props.BackgroundTransparency = 1
		props.FontFace = props.FontFace or F.Medium
		props.TextColor3 = props.TextColor3 or T.Text
		props.TextSize = props.TextSize or 13
		props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
		props.Text = props.Text or ""
		return U.new("TextLabel", props)
	end

	function U.button(props)
		props.Text = props.Text or ""
		props.AutoButtonColor = false
		if props.BackgroundTransparency == nil then props.BackgroundTransparency = 1 end
		return U.new("TextButton", props)
	end

	function U.tween(o, t, props, style, direction)
		local tw = Svc.TweenService:Create(
			o,
			TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
			props
		)
		tw:Play()
		return tw
	end

	local measureCache, measureCount = {}, 0
	function U.measure(text, size, width)
		if text == nil or text == "" then return Vector2.new(0, 0) end
		width = math.floor(width or 1e4)
		local key = size .. "|" .. width .. "|" .. text
		local hit = measureCache[key]
		if hit then return hit end
		local ok, v = pcall(Svc.TextService.GetTextSize, Svc.TextService, text, size, F.Measure, Vector2.new(width, 1e4))
		v = ok and v or Vector2.new(#text * size * 0.55, size + 3)
		measureCount += 1
		if measureCount > 3000 then -- bounded: drop everything rather than grow forever
			measureCache, measureCount = {}, 0
		end
		measureCache[key] = v
		return v
	end

	-- height of wrapped text; measured a bit narrower because labels use heavier weights
	function U.measureH(text, size, width)
		if text == nil or text == "" then return 0 end
		return math.ceil(U.measure(text, size, math.max(width * 0.93, 10)).Y)
	end

	function U.safe(fn, ...)
		if type(fn) ~= "function" then return end
		local args = table.pack(...)
		task.spawn(function()
			local ok, err = pcall(fn, table.unpack(args, 1, args.n))
			if not ok then warn("[NebulaGui] callback error: " .. tostring(err)) end
		end)
	end

	function U.onClick(btn, fn)
		return btn.Activated:Connect(fn)
	end

	function U.hover(btn, enter, leave)
		btn.MouseEnter:Connect(enter)
		btn.MouseLeave:Connect(leave)
	end

	function U.isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end

	function U.httpGet(url)
		local req = (type(syn) == "table" and syn.request)
			or (type(http) == "table" and http.request)
			or http_request
			or request
		if type(req) == "function" then
			local r = req({ Url = url, Method = "GET" })
			if r and (r.StatusCode == nil or r.StatusCode < 300) then return r.Body end
			return nil
		end
		return game:HttpGet(url)
	end

	function U.guiParent(gui)
		if type(protect_gui) == "function" then
			pcall(protect_gui, gui)
		elseif type(syn) == "table" and type(syn.protect_gui) == "function" then
			pcall(syn.protect_gui, gui)
		end
		if type(gethui) == "function" then
			pcall(function() gui.Parent = gethui() end)
		end
		if not gui.Parent then
			pcall(function() gui.Parent = Svc.CoreGui end)
		end
		if not gui.Parent then error("[NebulaGui] no access to gethui() or CoreGui") end
	end

	function U.cleanName(s)
		s = tostring(s or "")
		s = s:gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		return s
	end

	-- Generic drag helper (mouse + touch). onMove receives the total delta.
	function U.drag(win, handle, onBegin, onMove, onEnd)
		local active, start, moved
		handle.InputBegan:Connect(function(i)
			if not U.isPress(i) then return end
			active, start, moved = i, i.Position, false
			if onBegin then onBegin() end
		end)
		win:_Connect(Svc.UserInputService.InputChanged, function(i)
			if not active then return end
			if i.UserInputType == Enum.UserInputType.MouseMovement or i == active then
				local d = Vector2.new(i.Position.X - start.X, i.Position.Y - start.Y)
				if d.Magnitude > 5 then moved = true end
				onMove(d)
			end
		end)
		win:_Connect(Svc.UserInputService.InputEnded, function(i)
			if not active then return end
			if i == active or i.UserInputType == Enum.UserInputType.MouseButton1 then
				active = nil
				if onEnd then onEnd(moved) end
			end
		end)
	end
end

---------------------------------------------------------------------------
-- Icons drawn with frames (no asset ids needed)
---------------------------------------------------------------------------
do
	local function bar(holder, color, w, h, x, y, rot)
		return U.new("Frame", {
			Parent = holder,
			BackgroundColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.new(w, 0, 0, h),
			Rotation = rot or 0,
		})
	end

	local function ring(holder, color, s, x, y, th)
		local r = U.new("Frame", {
			Parent = holder,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(s, s),
		})
		U.round(r)
		U.stroke(r, color, 0, th or 1.6)
		return r
	end

	local builders = {}
	builders.close = function(h, c) bar(h, c, 1, 2, 0.5, 0.5, 45); bar(h, c, 1, 2, 0.5, 0.5, -45) end
	builders.min = function(h, c) bar(h, c, 0.8, 2, 0.5, 0.5) end
	builders.minus = function(h, c) bar(h, c, 0.7, 2, 0.5, 0.5) end
	builders.plus = function(h, c) bar(h, c, 0.7, 2, 0.5, 0.5); bar(h, c, 0.7, 2, 0.5, 0.5, 90) end
	builders.menu = function(h, c)
		bar(h, c, 0.9, 2, 0.5, 0.22); bar(h, c, 0.9, 2, 0.5, 0.5); bar(h, c, 0.9, 2, 0.5, 0.78)
	end
	builders.down = function(h, c) bar(h, c, 0.5, 2, 0.325, 0.525, 45); bar(h, c, 0.5, 2, 0.675, 0.525, -45) end
	builders.up = function(h, c) bar(h, c, 0.5, 2, 0.325, 0.475, -45); bar(h, c, 0.5, 2, 0.675, 0.475, 45) end
	builders.check = function(h, c) bar(h, c, 0.36, 2, 0.28, 0.6, 45); bar(h, c, 0.66, 2, 0.6, 0.48, -45) end
	builders.search = function(h, c) ring(h, c, 0.62, 0.42, 0.42, 2); bar(h, c, 0.34, 2, 0.8, 0.8, 45) end
	builders.globe = function(h, c)
		ring(h, c, 0.9, 0.5, 0.5, 1.6); bar(h, c, 0.9, 1.6, 0.5, 0.5)
		local e = ring(h, c, 0.9, 0.5, 0.5, 1.4)
		e.Size = UDim2.fromScale(0.42, 0.9)
	end
	builders.info = function(h, c)
		ring(h, c, 0.95, 0.5, 0.5, 1.6)
		bar(h, c, 0.09, 2, 0.5, 0.3)
		local b = bar(h, c, 0.09, 2, 0.5, 0.62)
		b.Size = UDim2.new(0, 2, 0.34, 0)
	end
	builders.eye = function(h, c)
		local e = ring(h, c, 0.9, 0.5, 0.5, 1.6)
		e.Size = UDim2.fromScale(0.95, 0.6)
		local p = bar(h, c, 0, 0, 0.5, 0.5)
		p.Size = UDim2.fromScale(0.28, 0.28)
		U.round(p)
	end
	builders.eyeoff = function(h, c)
		builders.eye(h, c)
		bar(h, c, 1.1, 2, 0.5, 0.5, -40)
	end
	builders.gear = function(h, c)
		for k = 0, 7 do
			local a = math.rad(k * 45)
			local t = bar(h, c, 0, 0, 0.5 + math.cos(a) * 0.36, 0.5 + math.sin(a) * 0.36, k * 45)
			t.Size = UDim2.fromScale(0.2, 0.2)
		end
		ring(h, c, 0.66, 0.5, 0.5, 2.2)
		ring(h, c, 0.26, 0.5, 0.5, 1.6)
	end
	builders.sliders = function(h, c)
		for i, y in ipairs({ 0.22, 0.5, 0.78 }) do
			bar(h, c, 0.9, 2, 0.5, y)
			local k = bar(h, c, 0, 0, ({ 0.3, 0.68, 0.45 })[i], y)
			k.Size = UDim2.fromOffset(6, 6)
			U.round(k)
		end
	end
	builders.grip = function(h, c)
		for _, x in ipairs({ 0.32, 0.68 }) do
			for _, y in ipairs({ 0.2, 0.5, 0.8 }) do
				local d = bar(h, c, 0, 0, x, y)
				d.Size = UDim2.fromOffset(3, 3)
				U.round(d)
			end
		end
	end

	-- resolves an image icon once per kind: first source that actually loads wins
	local iconState = {}
	function U.resolveIcon(kind, cb)
		local st = iconState[kind]
		if st and st.done then return cb(st.url) end
		if st then return table.insert(st.waiters, cb) end
		st = { waiters = { cb } }
		iconState[kind] = st
		task.spawn(function()
			local list = Nebula.Icons[kind]
			if type(list) == "string" then list = { list } end
			local found
			for _, url in ipairs(list or {}) do
				local status
				pcall(function()
					Svc.ContentProvider:PreloadAsync({ url }, function(_, s) status = s end)
				end)
				-- status nil = PreloadAsync unavailable in this executor: trust the first source
				if status == nil or status == Enum.AssetFetchStatus.Success then
					found = url
					break
				end
			end
			st.done, st.url = true, found
			for _, w in ipairs(st.waiters) do pcall(w, found) end
			st.waiters = nil
		end)
	end

	function U.icon(kind, parent, size, color, props)
		local h = U.new("Frame", {
			Parent = parent,
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
		})
		for k, v in pairs(props or {}) do h[k] = v end
		-- drawn version shows immediately; swapped for the image once it loads
		local drawn = U.new("Frame", { Parent = h, Name = "Drawn", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
		local b = builders[kind]
		if b then b(drawn, color or T.Text) end
		if Nebula.Icons[kind] then
			local img = U.new("ImageLabel", {
				Parent = h,
				Name = "Image",
				BackgroundTransparency = 1,
				ImageColor3 = color or T.Text,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				Visible = false,
			})
			U.resolveIcon(kind, function(url)
				if url and img.Parent then
					img.Image = url
					img.Visible = true
					drawn.Visible = false
				end
			end)
		end
		return h
	end

	function U.iconColor(h, color)
		for _, d in ipairs(h:GetDescendants()) do
			if d:IsA("ImageLabel") then d.ImageColor3 = color end
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = color end
			if d:IsA("UIStroke") then d.Color = color end
		end
	end

	-- Nebula logo: two counter-rotating comet rings + glowing core
	-- image logo when one is given, otherwise the drawn nebula
	function U.brandLogo(parent, size, image, props)
		if image then
			local img = U.new("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Image = image, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(size, size) })
			for k, v in pairs(props or {}) do img[k] = v end
			U.round(img)
			return img
		end
		return U.logo(parent, size, true, props)
	end

	function U.logo(parent, size, spin, props)
		local f = U.new("Frame", { Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) })
		for k, v in pairs(props or {}) do f[k] = v end
		local gradients = {}
		for i, s in ipairs({ 0.92, 0.56 }) do
			local r = U.new("Frame", {
				Parent = f,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(s, s),
			})
			U.round(r)
			local st = U.stroke(r, T.White, 0, i == 1 and math.max(2, size / 14) or math.max(1.5, size / 20))
			gradients[i] = U.new("UIGradient", {
				Parent = st,
				Color = ColorSequence.new(T.Accent, T.Glow),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.55, 0.25),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = i == 1 and 0 or 180,
			})
		end
		local core = U.new("Frame", {
			Parent = f,
			BackgroundColor3 = T.Glow,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.2, 0.2),
		})
		U.round(core)
		if spin then
			local info = TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
			Svc.TweenService:Create(gradients[1], info, { Rotation = 360 }):Play()
			Svc.TweenService:Create(gradients[2], info, { Rotation = -180 }):Play()
		end
		return f
	end
end

---------------------------------------------------------------------------
-- Translator (Google, 8 languages, cached on disk)
---------------------------------------------------------------------------
do
	Tr.Lang = "en"
	Tr.Cache = {}
	Tr.Failed = {}
	Tr.Loaded = {}
	Tr.Pending = {}
	Tr.Items = {} -- strong keys: weak Instance keys can lose entries when the proxy is collected
	Tr.Listeners = {}
	Tr.Codes = { "en", "pt", "es", "ru", "th", "vi", "id", "fi" }
	Tr.Names = {
		en = "English",
		pt = "Português",
		es = "Español",
		ru = "Русский",
		th = "ไทย",
		vi = "Tiếng Việt",
		id = "Bahasa Indonesia",
		fi = "Suomi",
	}
	Tr.Folder = "NebulaGui/i18n"

	function Tr.Detect()
		local ok, id = pcall(function() return Svc.LocalizationService.RobloxLocaleId end)
		local code = ok and type(id) == "string" and id:sub(1, 2):lower() or "en"
		return Tr.Names[code] and code or "en"
	end

	function Tr.Load(lang)
		if Tr.Loaded[lang] then return end
		Tr.Loaded[lang] = true
		local d = FS.readJSON(Tr.Folder .. "/" .. lang .. ".json")
		Tr.Cache[lang] = Tr.Cache[lang] or {}
		if d then
			for k, v in pairs(d) do Tr.Cache[lang][k] = v end
		end
	end

	function Tr.Save(lang)
		FS.mkdir(Tr.Folder)
		FS.writeJSON(Tr.Folder .. "/" .. lang .. ".json", Tr.Cache[lang] or {})
	end

	local function skip(s)
		return s == "" or s:match("^[%s%d%p]*$") ~= nil
	end

	function Tr.Lookup(s)
		if Tr.Lang == "en" or type(s) ~= "string" then return s end
		local c = Tr.Cache[Tr.Lang]
		return (c and c[s]) or s
	end

	function Tr.Get(s)
		if type(s) ~= "string" then return s end
		if Tr.Lang == "en" or skip(s) then return s end
		local c = Tr.Cache[Tr.Lang]
		if c and c[s] then return c[s] end
		Tr.Queue(s)
		return s
	end

	local registrations = 0
	function Tr.Register(obj, s, prop)
		if s == nil then return end
		s = tostring(s)
		registrations += 1
		if registrations % 300 == 0 then
			-- drop labels that were destroyed (notifications, popups, removed rows)
			for o in pairs(Tr.Items) do
				if not o.Parent then Tr.Items[o] = nil end
			end
		end
		Tr.Items[obj] = { s, prop or "Text" }
		obj[prop or "Text"] = Tr.Get(s)
	end

	function Tr.Unregister(obj)
		Tr.Items[obj] = nil
	end

	function Tr.Queue(s)
		local failed = Tr.Failed[Tr.Lang]
		if skip(s) or (failed and failed[s]) then return end
		Tr.Pending[s] = true
		if not Tr._scheduled then
			Tr._scheduled = true
			task.delay(0.25, Tr.Flush)
		end
	end

	function Tr.Flush()
		Tr._scheduled = false
		local lang = Tr.Lang
		local list = {}
		for s in pairs(Tr.Pending) do table.insert(list, s) end
		Tr.Pending = {}
		if lang == "en" or #list == 0 then return end
		task.spawn(function()
			Tr.Fetch(lang, list)
			Tr.Save(lang)
			if Tr.Lang == lang then Tr.Apply() end
		end)
	end

	-- one Google request; returns the translated string or nil
	local function googleRequest(lang: string, q: string): string?
		local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl="
			.. lang .. "&dt=t&q=" .. Svc.HttpService:UrlEncode(q)
		local ok, body = pcall(U.httpGet, url)
		if not ok or type(body) ~= "string" then return nil end
		local ok2, data = pcall(Svc.HttpService.JSONDecode, Svc.HttpService, body)
		if not ok2 or type(data) ~= "table" or type(data[1]) ~= "table" then return nil end
		local out = {}
		for _, seg in ipairs(data[1]) do
			if type(seg) == "table" and type(seg[1]) == "string" then table.insert(out, seg[1]) end
		end
		return table.concat(out)
	end

	local function trim(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	function Tr.Fetch(lang, texts)
		Tr.Load(lang)
		local cache = Tr.Cache[lang]
		Tr.Failed[lang] = Tr.Failed[lang] or {}
		local failed = Tr.Failed[lang]
		local chunk, size = {}, 0

		local function single(s)
			local r = googleRequest(lang, s)
			if r and r ~= "" then cache[s] = trim(r) else failed[s] = true end
		end

		local function flush()
			if #chunk == 0 then return end
			local r = googleRequest(lang, table.concat(chunk, "\n"))
			local lines = if r then string.split(r, "\n") else {}
			if #lines == #chunk then
				for i, s in ipairs(chunk) do cache[s] = trim(lines[i]) end
			else
				for _, s in ipairs(chunk) do single(s) end
			end
			chunk, size = {}, 0
		end

		for _, s in ipairs(texts) do
			if s:find("\n", 1, true) then
				single(s)
			else
				if size + #s > 1400 then flush() end
				table.insert(chunk, s)
				size += #s + 1
			end
		end
		flush()
	end

	function Tr.Apply()
		local c = Tr.Cache[Tr.Lang]
		for obj, info in pairs(Tr.Items) do
			if obj.Parent then
				local v = (Tr.Lang ~= "en" and c and c[info[1]]) or info[1]
				pcall(function() obj[info[2]] = v end)
			else
				Tr.Items[obj] = nil
			end
		end
		-- a listener returns "remove" once its UI is gone, so destroyed windows/dropdowns don't pile up
		for i = #Tr.Listeners, 1, -1 do
			local ok, r = pcall(Tr.Listeners[i])
			if ok and r == "remove" then table.remove(Tr.Listeners, i) end
		end
	end

	function Tr.SetLang(lang)
		if not Tr.Names[lang] then return end
		Tr.Lang = lang
		if lang ~= "en" then
			Tr.Load(lang)
			local c = Tr.Cache[lang]
			for _, info in pairs(Tr.Items) do
				if not c[info[1]] then Tr.Queue(info[1]) end
			end
		end
		Tr.Apply()
	end
end

Nebula.Translator = Tr

---------------------------------------------------------------------------
-- Window: construction
---------------------------------------------------------------------------
local SIDEBAR_W = 196
local TOUCH = Svc.UserInputService.TouchEnabled and not Svc.UserInputService.KeyboardEnabled
local SMALL_BTN = TOUCH and 30 or 26 -- small round buttons (stepper ±, eye, list arrows)
local HEADER_H = 52
local MIN_W, MIN_H = 260, 200

function Nebula:Window(o: WindowOptions?)
	o = o or {}
	if type(o.Icons) == "table" then
		for k, v in pairs(o.Icons) do Nebula.Icons[k] = v end
	end
	if type(o.Theme) == "table" then
		for k, v in pairs(o.Theme) do T[k] = v end
	end
	local self = setmetatable({}, Window)
	self.Title = o.Title or "NebulaGui"
	if o.Logo == false then
		self.Logo = nil
	else
		self.Logo = o.Logo or "rbxassetid://100199291949935" -- OneHub logo
	end
	self.Subtitle = o.Subtitle or ""
	-- start size depends on the device; it is not restored from the last session on purpose
	local uis = Svc.UserInputService
	self.IsMobile = uis.TouchEnabled and not uis.KeyboardEnabled
	local function vec(v, fallback)
		if typeof(v) == "UDim2" then return Vector2.new(v.X.Offset, v.Y.Offset) end
		if typeof(v) == "Vector2" then return v end
		return fallback
	end
	if self.IsMobile then
		self.DefaultSize = vec(o.MobileSize, Vector2.new(600, 340))
	else
		self.DefaultSize = vec(o.Size, Vector2.new(840, 540))
	end
	self.Desired = self.DefaultSize
	self.Folder = o.Folder or ("NebulaGui/" .. U.cleanName(self.Title))
	self.Keybind = o.Keybind or Enum.KeyCode.RightControl
	self.CloseConfirm = o.CloseConfirm ~= false
	self.Flags = {}
	self.Tabs = {}
	self._conns = {}
	self._relayouts = {}
	self._index = {}
	self._order = 0
	self.Offset = Vector2.new(0, 0)
	self.Cols = 0
	self.Visible = true
	self._unload = {}
	self._globals = {}
	self.HideNotice = o.HideNotice ~= false
	self.BlackHole = o.BlackHole -- false = plain fade/scale instead of the black hole animation

	FS.mkdir(self.Folder .. "/configs")
	self.Settings = FS.readJSON(self.Folder .. "/nebula.json") or {}
	self.UserScale = math.clamp(tonumber(self.Settings.Scale) or o.Scale or 1, 0.5, 1.5)
	self.NotificationsEnabled = self.Settings.Notifications ~= false
	if self.Settings.HideUserInfo ~= nil then
		self.ProfileHidden = self.Settings.HideUserInfo
	else
		self.ProfileHidden = o.HideUserInfo == true
	end

	self:_BuildShell()
	self:_BuildSidebar(o)
	self:_BuildHeader()
	self:_BuildFloat(o)
	self:_BuildNotifications()

	self:_Connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), function() self:_Layout() end)
	self:_Connect(Svc.UserInputService.InputBegan, function(i, gp) self:_OnKey(i, gp) end)
	-- never cover Roblox's own menu (Esc / Leave): hide everything while it is open
	pcall(function()
		self:_Connect(Svc.GuiService.MenuOpened, function() self:_MenuCover(true) end)
		self:_Connect(Svc.GuiService.MenuClosed, function() self:_MenuCover(false) end)
		if Svc.GuiService.MenuIsOpen then self:_MenuCover(true) end
	end)
	table.insert(Tr.Listeners, function()
		if not self.Gui.Parent then return "remove" end
		self:_RelayoutAll()
	end)

	Tr.SetLang(self.Settings.Language or o.Language or Tr.Detect())
	self:_Layout()
	if o.StartHidden then self:SetVisible(false, true) end

	table.insert(Nebula.Windows, self)
	return self
end

function Window:_Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._conns, c)
	return c
end

-- same, but also disconnected when `owner` is destroyed (element:Destroy(), list rows…)
function Window:_ConnectFor(owner, signal, fn)
	local c = self:_Connect(signal, fn)
	owner.Destroying:Connect(function()
		c:Disconnect()
		local i = table.find(self._conns, c)
		if i then table.remove(self._conns, i) end
	end)
	return c
end

function Window:_SaveSettings()
	FS.writeJSON(self.Folder .. "/nebula.json", self.Settings)
end

function Window:_BuildShell()
	local gui = U.new("ScreenGui", {
		Name = "NebulaGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
		IgnoreGuiInset = true,
	})
	pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
	U.guiParent(gui)
	self.Gui = gui

	local holder = U.new("Frame", {
		Parent = gui,
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self.Desired.X, self.Desired.Y),
	})
	self.Holder = holder
	self.Scale = U.new("UIScale", { Parent = holder })

	-- violet glow behind the window
	U.new("ImageLabel", {
		Parent = holder,
		Name = "Glow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = T.Accent,
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 70, 1, 70),
	})

	local main = U.new("Frame", {
		Parent = holder,
		Name = "Main",
		BackgroundColor3 = T.Surface,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	})
	U.corner(main, 14)
	U.stroke(main, T.Border)
	self.Main = main

	self.Content = U.new("Frame", {
		Parent = main,
		Name = "Content",
		BackgroundTransparency = 1,
		ZIndex = 1,
		Position = UDim2.fromOffset(SIDEBAR_W, 0),
		Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
	})
	self.Pages = U.new("Frame", {
		Parent = self.Content,
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER_H),
		Size = UDim2.new(1, 0, 1, -HEADER_H - 10),
	})
	self.Scrim = U.button({
		Parent = main,
		Name = "Scrim",
		BackgroundColor3 = T.Background,
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Visible = false,
	})
	U.onClick(self.Scrim, function() self:_Drawer(false) end)

	self.Overlay = U.new("Frame", {
		Parent = holder,
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
	})

	-- resize grip: any size from MIN_W x MIN_H up to the whole screen, mouse or touch
	local touch = Svc.UserInputService.TouchEnabled
	local grip = U.button({
		Parent = main,
		Name = "Resize",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(touch and 30 or 18, touch and 30 or 18),
		ZIndex = 9,
	})
	local lines = {}
	for i = 1, 3 do
		lines[i] = U.new("Frame", {
			Parent = grip,
			BackgroundColor3 = T.Faint,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -3, 1, -3 - (i - 1) * 4),
			Size = UDim2.fromOffset(2 + (i - 1) * 4, 2),
		})
		U.round(lines[i])
	end
	local function tint(c) for _, l in ipairs(lines) do U.tween(l, 0.12, { BackgroundColor3 = c }) end end
	U.hover(grip, function() tint(T.Glow) end, function() if not self._resizing then tint(T.Faint) end end)
	self.Grip = grip

	-- the top-left corner stays put while the bottom-right follows the pointer
	local baseSize, baseOff
	U.drag(self, grip, function()
		self._resizing = true
		baseSize, baseOff = self.Size or self.Desired, self.Offset
		tint(T.Glow)
	end, function(d)
		local us = self.UserScale
		local maxS = self.Gui.AbsoluteSize / us
		local nw = math.clamp(baseSize.X + d.X / us, MIN_W, math.max(MIN_W, maxS.X))
		local nh = math.clamp(baseSize.Y + d.Y / us, MIN_H, math.max(MIN_H, maxS.Y))
		self.Desired = Vector2.new(math.floor(nw), math.floor(nh))
		self.Offset = baseOff + (self.Desired - baseSize) * us / 2
		self:_Layout()
	end, function()
		self._resizing = false
		tint(T.Faint)
	end)
end

function Window:_BuildSidebar(o)
	local side = U.new("Frame", {
		Parent = self.Main,
		Name = "Sidebar",
		BackgroundColor3 = T.Sidebar,
		Size = UDim2.new(0, SIDEBAR_W, 1, 0),
		ZIndex = 3,
	})
	U.new("Frame", {
		Parent = side,
		BackgroundColor3 = T.Border,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
	})
	self.Sidebar = side

	-- brand
	local brand = U.new("Frame", { Parent = side, BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 16), Size = UDim2.new(1, -32, 0, 34) })
	U.brandLogo(brand, 30, self.Logo, { Position = UDim2.fromOffset(0, 2) })
	self.TitleLabel = U.text({ Parent = brand, Text = self.Title, FontFace = F.Bold, TextSize = 15, Position = UDim2.fromOffset(40, 1), Size = UDim2.new(1, -40, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd })
	self.SubtitleLabel = U.text({ Parent = brand, Text = self.Subtitle, TextSize = 11, TextColor3 = T.Muted, Position = UDim2.fromOffset(40, 19), Size = UDim2.new(1, -40, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })

	local profileH = o.HideProfile and 0 or 62
	local list = U.new("ScrollingFrame", {
		Parent = side,
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62 - profileH),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.Accent,
	})
	U.pad(list, 4, 12, 8, 12)
	U.list(list, 4)
	self.TabList = list

	if not o.HideProfile then self:_BuildProfile(side) end
end

function Window:_BuildProfile(side)
	local lp = Svc.Players.LocalPlayer
	local card = U.new("Frame", {
		Parent = side,
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.new(1, -24, 0, 48),
	})
	U.corner(card, 10)
	U.stroke(card, T.Border)
	local av = U.new("ImageLabel", {
		Parent = card,
		BackgroundColor3 = T.Elevated2,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(32, 32),
		Image = lp and ("rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150") or "",
	})
	U.round(av)
	U.stroke(av, T.Accent, 0, 2)
	local veil = U.new("Frame", { Parent = av, BackgroundColor3 = T.Elevated2, Size = UDim2.fromScale(1, 1), Visible = false })
	U.round(veil)
	U.new("UIGradient", { Parent = veil, Color = ColorSequence.new(T.Accent, T.Elevated2), Rotation = 45 })
	local display = U.text({ Parent = card, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -84, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
	local user = U.text({ Parent = card, TextSize = 10, TextColor3 = T.Muted, Position = UDim2.fromOffset(48, 25), Size = UDim2.new(1, -84, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })

	-- eye button: hides avatar + names (for recording / screenshots)
	local eye = U.button({ Parent = card, BackgroundColor3 = T.Elevated, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(SMALL_BTN, SMALL_BTN) })
	U.corner(eye, 7)
	U.hover(eye, function() U.tween(eye, 0.12, { BackgroundTransparency = 0 }) end, function() U.tween(eye, 0.12, { BackgroundTransparency = 1 }) end)
	U.onClick(eye, function() self:SetUserInfoHidden(not self.ProfileHidden) end)

	local icon
	self._applyProfile = function()
		local hidden = self.ProfileHidden
		local dn = lp and lp.DisplayName or "Player"
		local un = lp and lp.Name or ""
		display.Text = hidden and string.rep("•", math.min(#dn, 10)) or dn
		user.Text = hidden and ("@" .. string.rep("•", math.min(#un, 10))) or ("@" .. un)
		veil.Visible = hidden
		if icon then icon:Destroy() end
		icon = U.icon(hidden and "eyeoff" or "eye", eye, 14, hidden and T.Glow or T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	end
	self._applyProfile()
end

-- solid = filled background + bright icon (used where the icon image is dark/thin)
function Window:_HeaderButton(name, kind, solid)
	local b = U.button({
		Parent = self.Header,
		Name = name,
		BackgroundColor3 = T.Elevated,
		BackgroundTransparency = solid and 0 or 1,
		Size = UDim2.fromOffset(32, 32),
	})
	U.corner(b, 8)
	if solid then U.stroke(b, T.Border) end
	local idle = solid and T.Text or T.Muted
	local hot = solid and T.Glow or T.Text
	local ic = U.icon(kind, b, solid and 16 or 14, idle, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	U.hover(b, function()
		if not solid then U.tween(b, 0.15, { BackgroundTransparency = 0 }) end
		U.iconColor(ic, hot)
	end, function()
		if not solid then U.tween(b, 0.15, { BackgroundTransparency = 1 }) end
		U.iconColor(ic, idle)
	end)
	return b
end

function Window:_BuildHeader()
	local header = U.new("Frame", {
		Parent = self.Content,
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
	})
	U.new("Frame", { Parent = header, BackgroundColor3 = T.Border, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1) })
	self.Header = header

	self.Burger = self:_HeaderButton("Menu", "menu")
	self.Burger.BackgroundTransparency = 0
	self.Burger.Size = UDim2.fromOffset(40, 36)
	U.stroke(self.Burger, T.BorderHi)
	U.onClick(self.Burger, function() self:_Drawer(true) end)

	self.TabTitle = U.text({ Parent = header, FontFace = F.Bold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd })

	-- drag the window by the header
	local base
	U.drag(self, header, function() base = self.Offset end, function(d)
		self.Offset = base + d
		self:_Place()
	end)

	self:_BuildSearch()

	local lang = U.button({ Parent = header, Name = "Language", BackgroundColor3 = T.Elevated, BackgroundTransparency = 0, Size = UDim2.fromOffset(58, 32) })
	U.corner(lang, 8)
	U.stroke(lang, T.Border)
	U.icon("globe", lang, 14, T.Glow, { Position = UDim2.new(0, 9, 0.5, -7) })
	self.LangLabel = U.text({ Parent = lang, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0) })
	U.onClick(lang, function() self:_LanguagePopup() end)
	self.LangBtn = lang
	table.insert(Tr.Listeners, function()
		if not self.LangLabel.Parent then return "remove" end
		self.LangLabel.Text = string.upper(Tr.Lang)
	end)

	self.GearBtn = self:_HeaderButton("Settings", "gear", true)
	self.GearBtn.Visible = false
	U.onClick(self.GearBtn, function() self:_GlobalPopup() end)

	self.MinBtn = self:_HeaderButton("Minimize", "min")
	U.onClick(self.MinBtn, function() self:SetVisible(false) end)
	self.CloseBtn = self:_HeaderButton("Close", "close")
	U.onClick(self.CloseBtn, function() self:Close() end)
end

-- asks before destroying (CloseConfirm = false skips the dialog)
function Window:Close()
	if self._closing or self._destroyed then return end
	if not self.CloseConfirm then return self:CloseAnimated() end
	do
		self:Dialog({
			Title = "Close the interface?",
			Content = "Everything will stop running. You'll need to execute the script again.",
			Buttons = {
				{ Name = "Cancel" },
				{ Name = "Close", Primary = true, Callback = function() self:CloseAnimated() end },
			},
		})
	end
end

-- destroys the window with the collapse animation (Destroy() stays instant)
function Window:CloseAnimated()
	if self._closing or self._destroyed then return end
	self._closing = true
	task.spawn(function()
		task.wait() -- let the dialog disappear first
		local ok, err = pcall(function()
			self:_Collapse(function() self:Destroy() end)
		end)
		if not ok then
			warn("[NebulaGui] close: " .. tostring(err))
			self:Destroy()
		end
	end)
end

function Window:_BuildSearch()
	local sf = U.new("Frame", {
		Parent = self.Header,
		Name = "Search",
		BackgroundColor3 = T.Background,
		Size = UDim2.fromOffset(230, 32),
		ZIndex = 2,
	})
	U.corner(sf, 8)
	local st = U.stroke(sf, T.Border)
	self.SearchIcon = U.icon("search", sf, 14, T.Muted, { Position = UDim2.new(0, 10, 0.5, -7) })
	local box = U.new("TextBox", {
		Parent = sf,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -40, 1, 0),
		FontFace = F.Medium,
		TextSize = 12,
		TextColor3 = T.Text,
		PlaceholderColor3 = T.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = "",
		ClipsDescendants = true,
	})
	Tr.Register(box, "Search…", "PlaceholderText")
	local hit = U.button({ Parent = sf, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3 })
	U.onClick(hit, function()
		self.SearchOpen = true
		self:_LayoutHeader()
		box:CaptureFocus()
	end)
	box.Focused:Connect(function()
		st.Color = T.Accent
		if self._openPanel and self._openPanel.Inside then self:ClosePanel() end
	end)
	box.FocusLost:Connect(function()
		st.Color = T.Border
		task.delay(0.2, function()
			self:_HideSearchResults()
			if self.Compact and box.Text == "" then
				self.SearchOpen = false
				self:_LayoutHeader()
			end
		end)
	end)
	local searchToken = 0
	box:GetPropertyChangedSignal("Text"):Connect(function()
		searchToken += 1
		local t = searchToken
		task.delay(0.12, function()
			if t == searchToken then self:_Search(box.Text) end
		end)
	end)
	self.SearchFrame, self.SearchBox, self.SearchHit = sf, box, hit
end

function Window:_BuildFloat(o)
	if o.FloatingButton == false then return end
	local size = Svc.UserInputService.TouchEnabled and 48 or 52
	local fb = U.button({
		Parent = self.Gui,
		Name = "Float",
		BackgroundColor3 = T.Surface,
		BackgroundTransparency = 0,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromOffset(24, 120),
	})
	U.corner(fb, 16)
	U.stroke(fb, T.Accent, 0.35, 1.5)
	U.brandLogo(fb, size - 12, self.Logo, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	if o.FloatImage then
		U.new("ImageLabel", { Parent = fb, BackgroundTransparency = 1, Image = o.FloatImage, Size = UDim2.fromScale(1, 1) })
	end
	self.Float = fb
	local p = self.Settings.Float
	if type(p) == "table" then fb.Position = UDim2.fromOffset(tonumber(p[1]) or 24, tonumber(p[2]) or 120) end

	local base
	U.drag(self, fb, function() base = fb.Position end, function(d)
		fb.Position = UDim2.fromOffset(base.X.Offset + d.X, base.Y.Offset + d.Y)
		self:_ClampFloat()
	end, function(moved)
		if moved then
			self.Settings.Float = { fb.Position.X.Offset, fb.Position.Y.Offset }
			self:_SaveSettings()
		else
			self:SetVisible(not self.Visible)
		end
	end)
end

function Window:_ClampFloat()
	local fb = self.Float
	if not fb then return end
	local scr = self.Gui.AbsoluteSize
	local s = fb.AbsoluteSize
	fb.Position = UDim2.fromOffset(
		math.clamp(fb.Position.X.Offset, 4, math.max(4, scr.X - s.X - 4)),
		math.clamp(fb.Position.Y.Offset, 4, math.max(4, scr.Y - s.Y - 4))
	)
end

function Window:_BuildNotifications()
	local h = U.new("Frame", {
		Parent = self.Gui,
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 290, 1, -32),
	})
	local l = U.list(h, 8)
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	l.HorizontalAlignment = Enum.HorizontalAlignment.Right
	self.NotifyHolder = h
end

---------------------------------------------------------------------------
-- Window: layout / responsiveness
---------------------------------------------------------------------------
-- current visual scale of the window (user scale × open animation)
function Window:_S()
	local s = self.Scale and self.Scale.Scale or 1
	return s > 0 and s or 1
end

function Window:_Layout()
	local real = self.Gui.AbsoluteSize
	if real.X <= 0 then return end
	-- work in "design" pixels: the UIScale on the holder multiplies everything by UserScale
	local us = self.UserScale
	local scr = real / us
	local w = math.max(MIN_W, math.min(self.Desired.X, scr.X))
	local h = math.max(MIN_H, math.min(self.Desired.Y, scr.Y))
	self.Holder.Size = UDim2.fromOffset(w, h)
	self.Size = Vector2.new(w, h)
	if not self._animating then self.Scale.Scale = us end

	local compact = w < 640
	if compact ~= self.Compact then self:_SetCompact(compact) end

	local contentW = w - (compact and 0 or SIDEBAR_W) - 36
	local cols = contentW >= 520 and 2 or 1
	if cols ~= self.Cols then
		self.Cols = cols
		for _, tab in ipairs(self.Tabs) do tab:_SetCols(cols) end
	end

	self.NotifyHolder.Size = UDim2.new(0, math.min(290, real.X - 32), 1, -32)
	self:_LayoutHeader()
	self:_Place()
	self:_ClampFloat()
	if self._openPanel then self:_PlacePanel(self._openPanel) end
end

function Window:_Place()
	if self._vortexing then return end
	local scr = self.Gui.AbsoluteSize
	local size = (self.Size or self.Desired) * self.UserScale
	local mx = math.max(0, (scr.X - size.X) / 2)
	local my = math.max(0, (scr.Y - size.Y) / 2)
	self.Offset = Vector2.new(math.clamp(self.Offset.X, -mx, mx), math.clamp(self.Offset.Y, -my, my))
	self.Holder.Position = UDim2.new(0.5, self.Offset.X, 0.5, self.Offset.Y)
end

function Window:_SetCompact(compact)
	self.Compact = compact
	self.SearchOpen = false
	self:_Drawer(false, true)
	if compact then
		self.Content.Position = UDim2.new()
		self.Content.Size = UDim2.fromScale(1, 1)
	else
		self.Sidebar.Position = UDim2.new()
		self.Content.Position = UDim2.fromOffset(SIDEBAR_W, 0)
		self.Content.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
	end
	for _, tab in ipairs(self.Tabs) do
		tab.Button.Size = UDim2.new(1, 0, 0, compact and 44 or 36)
	end
end

function Window:_Drawer(open, instant)
	if not self.Compact then
		self.Scrim.Visible = false
		return
	end
	self.DrawerOpen = open
	local target = open and UDim2.new() or UDim2.fromOffset(-SIDEBAR_W - 12, 0)
	if instant then self.Sidebar.Position = target else U.tween(self.Sidebar, 0.25, { Position = target }) end
	self.Scrim.Visible = open
end

function Window:_LayoutHeader()
	-- design pixels (the holder's UIScale must not move the buttons)
	local compact = self.Compact
	local W = self.Size and (self.Size.X - (compact and 0 or SIDEBAR_W)) or self.Header.AbsoluteSize.X / self:_S()
	if W <= 0 then return end
	local x = 18
	self.Burger.Visible = compact
	if compact then
		self.Burger.Position = UDim2.fromOffset(8, 8)
		x = 58
	end
	local right = W - 10
	self.CloseBtn.Position = UDim2.fromOffset(right - 32, 10)
	right -= 34
	self.MinBtn.Position = UDim2.fromOffset(right - 32, 10)
	right -= 40
	self.LangBtn.Position = UDim2.fromOffset(right - 58, 10)
	right -= 66
	if #self._globals > 0 then
		self.GearBtn.Visible = true
		self.GearBtn.Position = UDim2.fromOffset(right - 32, 10)
		right -= 40
	else
		self.GearBtn.Visible = false
	end

	local sf = self.SearchFrame
	if compact then
		if self.SearchOpen then
			sf.Position = UDim2.fromOffset(8, 8)
			sf.Size = UDim2.fromOffset(W - 16, 36)
			sf.ZIndex = 20
		else
			sf.Position = UDim2.fromOffset(right - 40, 8)
			sf.Size = UDim2.fromOffset(40, 36)
			sf.ZIndex = 2
		end
		self.SearchBox.Visible = self.SearchOpen
		self.SearchHit.Visible = not self.SearchOpen
		self.SearchIcon.Position = self.SearchOpen and UDim2.new(0, 10, 0.5, -7) or UDim2.new(0.5, -7, 0.5, -7)
		right -= 48
	else
		local sw = math.clamp(right - x - 140, 140, 240)
		sf.Position = UDim2.fromOffset(right - sw, 10)
		sf.Size = UDim2.fromOffset(sw, 32)
		sf.ZIndex = 2
		self.SearchBox.Visible = true
		self.SearchHit.Visible = false
		self.SearchIcon.Position = UDim2.new(0, 10, 0.5, -7)
		right -= sw + 10
	end
	self.TabTitle.Position = UDim2.fromOffset(x, 0)
	self.TabTitle.Size = UDim2.fromOffset(math.max(0, right - x), HEADER_H)
end

function Window:_Watch(cont, row, fn)
	local last = -1
	local function run(force)
		local x = row.AbsoluteSize.X
		if x > 0 and (force or x ~= last) then
			last = x
			fn(math.floor(x / self.UserScale + 0.5))
		end
	end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not self._animating then run(false) end
	end)
	table.insert(cont.Tab._relayouts, { row, run })
	task.defer(run, true)
	return run
end

function Window:_RelayoutAll()
	for _, tab in ipairs(self.Tabs) do tab:_Relayout() end
	self:_LayoutHeader()
end

function Window:_OnKey(i, gp)
	if gp then return end
	if i.KeyCode == self.Keybind then
		self:SetVisible(not self.Visible)
		return
	end
	local uis = Svc.UserInputService
	if i.KeyCode == Enum.KeyCode.F and (uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.RightControl)) then
		if self.Visible then
			self.SearchOpen = true
			self:_LayoutHeader()
			task.defer(function() self.SearchBox:CaptureFocus() end)
		end
	end
end

---------------------------------------------------------------------------
-- Window: public API
---------------------------------------------------------------------------
function Window:SetVisible(v, instant)
	if self._closing then return end
	if self.Visible == v and self.Holder.Visible == v then return end
	self.Visible = v
	self:_ClosePopup()
	-- with the floating button on screen, the window is sucked into / spat out of the black hole
	local hole = self.Float and self.Float.Visible and self.Float.Parent and self.BlackHole ~= false
	if not instant and hole then
		self._hideToken = (self._hideToken or 0) + 1
		self:_Vortex(v)
		if not v then self:_HideNotice() end
		return
	end
	self:_VxCancel()
	if v then
		self._hideToken = (self._hideToken or 0) + 1
		self.Holder.Visible = true
		if not instant then
			self._animating = true
			self.Scale.Scale = self.UserScale * 0.96
			U.tween(self.Scale, 0.2, { Scale = self.UserScale })
			task.delay(0.22, function()
				self._animating = false
				self.Scale.Scale = self.UserScale
			end)
		end
	else
		self._hideToken = (self._hideToken or 0) + 1
		local token = self._hideToken
		if instant then
			self.Holder.Visible = false
		else
			self._animating = true
			U.tween(self.Scale, 0.14, { Scale = self.UserScale * 0.96 }, Enum.EasingStyle.Quad)
			task.delay(0.14, function()
				if self._hideToken ~= token or self.Visible then return end
				self.Holder.Visible = false
				self.Scale.Scale = self.UserScale
				self._animating = false
			end)
		end
		if not instant then self:_HideNotice() end
	end
end

function Window:_HideNotice()
	if not self.HideNotice or self._noticeShown then return end
	self._noticeShown = true -- once per session, so it doesn't nag
	local how = self.Float and "Tap the black hole" or "Press the toggle key"
	local key = self.Keybind and (" or press " .. self.Keybind.Name) or ""
	self:Notify({ Title = "Interface hidden", Content = how .. key .. " to open it again.", Icon = "eyeoff" })
end

-- Black hole animation, built from clones of the window so the real UI is never touched.
-- Closing: the hole tugs at the pieces closest to it first, then grabs more and more, faster
-- and faster, until the empty window shell itself is swallowed.
-- Opening (fast): everything is spat out of the hole in a mess, then snaps back into place.
do
	local MAX_PIECES = 70
	local TUG = 0.14

	local function outQuint(u) return 1 - (1 - u) ^ 5 end
	local function outBack(u)
		local c1 = 1.5
		local v = u - 1
		return 1 + (c1 + 1) * v * v * v + c1 * v * v
	end
	local function rotate(v, a)
		local c, s = math.cos(a), math.sin(a)
		return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
	end
	local function rand(a, b) return a + math.random() * (b - a) end

	-- does this object draw something by itself (ignoring its children)?
	local function drawsBg(g)
		if g.BackgroundTransparency < 1 then return true end
		if (g:IsA("ImageLabel") or g:IsA("ImageButton")) and g.Image ~= "" and g.ImageTransparency < 1 then return true end
		local st = g:FindFirstChildOfClass("UIStroke")
		return st ~= nil and st.Enabled and st.Transparency < 1 and st.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
	end

	local function drawsAnything(g)
		if drawsBg(g) then return true end
		if (g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox")) and g.Text ~= "" and g.TextTransparency < 1 then return true end
		for _, c in ipairs(g:GetChildren()) do
			if c:IsA("GuiObject") then return true end
		end
		return false
	end

	local function hasGuiKids(g)
		for _, c in ipairs(g:GetChildren()) do
			if c:IsA("GuiObject") and c.Visible then return true end
		end
		return false
	end

	-- copy of a container's own look (fill, image, corner, stroke, gradient) without its children
	local function bgCopy(g)
		local img = g:IsA("ImageLabel") or g:IsA("ImageButton")
		local c = Instance.new(img and "ImageLabel" or "Frame")
		c.BorderSizePixel = 0
		c.BackgroundColor3 = g.BackgroundColor3
		c.BackgroundTransparency = g.BackgroundTransparency
		c.Rotation = g.Rotation
		if img then
			for _, p in ipairs({ "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ImageRectOffset", "ImageRectSize", "ResampleMode" }) do
				pcall(function() c[p] = g[p] end)
			end
		end
		for _, k in ipairs(g:GetChildren()) do
			if k:IsA("UICorner") or k:IsA("UIGradient") or (k:IsA("UIStroke") and k.ApplyStrokeMode == Enum.ApplyStrokeMode.Border) then
				k:Clone().Parent = c
			end
		end
		return c
	end

	-- turns a clone into a free-floating piece centred on `center` (overlay pixels)
	local function makePiece(st, g, center, absSize, kind)
		local mult = 1
		for _, k in ipairs(g:GetChildren()) do
			if k:IsA("UIScale") then
				mult *= k.Scale
				k:Destroy()
			elseif k:IsA("UISizeConstraint") or k:IsA("UIAspectRatioConstraint") then
				k:Destroy()
			end
		end
		local s = st.us * (mult > 0 and mult or 1)
		pcall(function() g.AutomaticSize = Enum.AutomaticSize.None end)
		if g:IsA("GuiButton") then g.Active = false end
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Size = UDim2.fromOffset(absSize.X / s, absSize.Y / s)
		g.Position = UDim2.fromOffset(center.X, center.Y)
		g.Visible = true
		st.z += 1
		g.ZIndex = st.z
		local sc = Instance.new("UIScale")
		sc.Scale = s
		sc.Parent = g
		g.Parent = st.overlay
		local p = { g = g, sc = sc, s = s, p0 = center, r0 = g.Rotation, kind = kind }
		table.insert(st.pieces, p)
		return p
	end

	-- walk the visible UI and cut it into pieces: small chunks are cloned whole, big
	-- containers are split into their own background + their children
	local function collect(st, parent, x0, y0, x1, y1)
		for _, c in ipairs(parent:GetChildren()) do
			if #st.pieces >= MAX_PIECES then return end
			if c:IsA("GuiObject") and c.Visible then
				local p, s = c.AbsolutePosition, c.AbsoluteSize
				local ix0, iy0 = math.max(p.X, x0), math.max(p.Y, y0)
				local ix1, iy1 = math.min(p.X + s.X, x1), math.min(p.Y + s.Y, y1)
				if s.X >= 1 and s.Y >= 1 and ix1 - ix0 >= 1 and iy1 - iy0 >= 1 then
					local full = ix0 - p.X < 1 and iy0 - p.Y < 1 and p.X + s.X - ix1 < 1 and p.Y + s.Y - iy1 < 1
					local kids = hasGuiKids(c)
					if full and (not kids or s.X * s.Y <= st.maxArea) then
						local cl = drawsAnything(c) and c:Clone()
						if cl then makePiece(st, cl, p + s / 2 - st.origin, s, "leaf") end
					elseif kids then
						local bg
						if drawsBg(c) then
							local isz = Vector2.new(ix1 - ix0, iy1 - iy0)
							bg = makePiece(st, bgCopy(c), Vector2.new(ix0, iy0) + isz / 2 - st.origin, isz, "bg")
						end
						local first = #st.pieces + 1
						if c.ClipsDescendants or c:IsA("ScrollingFrame") then
							collect(st, c, ix0, iy0, ix1, iy1)
						else
							collect(st, c, x0, y0, x1, y1)
						end
						if bg then bg.first, bg.last = first, #st.pieces end
					end
				end
			end
		end
	end

	function Window:_VxCapture()
		local gui = self.Gui
		local main = self.Main
		local holder = self.Holder
		local overlay = Instance.new("Frame")
		overlay.Name = "Vortex"
		overlay.BackgroundTransparency = 1
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.ZIndex = 1
		local fb = self.Float
		if fb and fb.ZIndex < 2 then fb.ZIndex = 2 end
		local st = {
			overlay = overlay,
			pieces = {},
			z = 2,
			us = self.UserScale,
			origin = gui.AbsolutePosition,
			hole = fb and (fb.AbsolutePosition - gui.AbsolutePosition + fb.AbsoluteSize / 2) or (gui.AbsoluteSize / 2),
		}
		local mp, ms = main.AbsolutePosition, main.AbsoluteSize
		st.maxArea = ms.X * ms.Y * 0.06

		-- the shell: glow + the window's own background, swallowed last / spat first
		local hs = holder.AbsoluteSize
		local shell = Instance.new("Frame")
		shell.BackgroundTransparency = 1
		shell.AnchorPoint = Vector2.new(0.5, 0.5)
		shell.Size = UDim2.fromOffset(hs.X / st.us, hs.Y / st.us)
		local glow = holder:FindFirstChild("Glow")
		if glow then glow:Clone().Parent = shell end
		local mbg = bgCopy(main)
		mbg.Size = UDim2.fromScale(1, 1)
		mbg.Parent = shell
		shell.Parent = overlay
		local sc = Instance.new("UIScale")
		sc.Scale = st.us
		sc.Parent = shell
		shell.ZIndex = 1
		local c0 = holder.AbsolutePosition + hs / 2 - st.origin
		shell.Position = UDim2.fromOffset(c0.X, c0.Y)
		st.shell = { g = shell, sc = sc, s = st.us, p0 = c0, r0 = 0, kind = "shell" }

		collect(st, main, mp.X, mp.Y, mp.X + ms.X, mp.Y + ms.Y)
		overlay.Parent = gui
		return st
	end

	-- runs `step(t)` every frame until it returns true; false if the animation was cancelled
	function Window:_VxRun(gen, step)
		local t0 = os.clock()
		local last = t0
		while true do
			Svc.RunService.RenderStepped:Wait()
			if self._destroyed or self._vxGen ~= gen then return false end
			local now = os.clock()
			if step(now - t0, now - last) then return true end
			last = now
		end
	end

	local function place(p, pos, scale, rot)
		p.g.Position = UDim2.fromOffset(pos.X, pos.Y)
		p.sc.Scale = math.max(0, scale)
		p.g.Rotation = rot
	end

	function Window:_VxClose(gen)
		local st = self:_VxCapture()
		self.Holder.Visible = false
		local H = st.hole
		local pieces = st.pieces

		-- schedule: closest to the hole first, the gaps between grabs keep shrinking
		local leaves = {}
		for _, p in ipairs(pieces) do
			if p.kind == "leaf" then
				p.d = (p.p0 - H).Magnitude + rand(0, 60)
				table.insert(leaves, p)
			end
		end
		table.sort(leaves, function(a, b) return a.d < b.d end)
		local n = math.max(1, #leaves)
		for k, p in ipairs(leaves) do
			local f = (k - 1) / n
			p.L = TUG + 0.62 * f ^ 0.55
			p.F = 0.44 - 0.16 * f
		end
		-- a container's background goes right after the last of its children
		for i = #pieces, 1, -1 do
			local p = pieces[i]
			if p.kind == "bg" then
				local m = 0
				for j = p.first or i + 1, p.last or i do
					if pieces[j].L then m = math.max(m, pieces[j].L) end
				end
				p.L = (m > 0 and m or 0.35) + 0.06
				p.F = 0.32
			end
		end
		local shell = st.shell
		local lastL = 0
		for _, p in ipairs(pieces) do lastL = math.max(lastL, p.L) end
		shell.L = lastL + 0.1
		shell.F = 0.38
		table.insert(pieces, shell)
		local total = 0
		for _, p in ipairs(pieces) do
			total = math.max(total, p.L + p.F)
			p.spin = rand(0.85, 1.25)
			p.d = p.d or rand(0, 60)
			local dir = H - p.p0
			p.dir = dir.Magnitude > 1 and dir.Unit or Vector2.zero
		end

		local fb = self.Float
		local pulse = fb:FindFirstChild("Pulse") or U.new("UIScale", { Parent = fb, Name = "Pulse" })
		local gulp = 0
		self:_HoleRing(false, math.min(0.9, total * 0.7))
		task.delay(shell.L, function()
			if self._vxGen == gen then self:_HoleRing(false, shell.F) end
		end)

		local ok = self:_VxRun(gen, function(t, dt)
			for _, p in ipairs(pieces) do
				if p.g.Visible then
					local u = (t - p.L) / p.F
					if u >= 1 then
						p.g.Visible = false
						gulp = math.min(0.22, gulp + (p.kind == "shell" and 0.2 or 0.05))
					elseif u >= 0 then
						-- swallowed: accelerating spiral, spinning and shrinking into the hole
						local e = u * u
						local k = 1 - e
						local rel = p.p0 + p.dir * 6 - H
						local pos = H + rotate(rel, e * math.pi * 1.3 * p.spin) * k
						place(p, pos, p.s * k ^ 1.4, p.r0 + e * 320 * p.spin)
					elseif p.kind == "shell" then
						-- the empty window gets dragged and shaken more and more
						local g = math.clamp(t / p.L, 0, 1) ^ 2
						local shake = Vector2.new(math.sin(t * 47), math.cos(t * 39)) * 2.2 * g
						place(p, p.p0 + (H - p.p0) * 0.05 * g + shake, p.s * (1 - 0.06 * g), p.r0 + math.sin(t * 31) * 1.4 * g)
					else
						-- tug: the piece trembles and leans towards the hole right before being taken
						local a = math.clamp((t - (p.L - TUG)) / TUG, 0, 1)
						if a > 0 then
							local shake = Vector2.new(math.sin(t * 61 + p.d), math.cos(t * 53 + p.d)) * 1.6 * a
							place(p, p.p0 + p.dir * 6 * a + shake, p.s * (1 - 0.04 * a), p.r0 + math.sin(t * 57 + p.d) * 3 * a)
						end
					end
				end
			end
			gulp *= 0.9 ^ (dt * 60)
			pulse.Scale = 1 + 0.12 * math.min(1, t / total) + gulp
			return t >= total
		end)
		if ok and pulse.Parent then U.tween(pulse, 0.35, { Scale = 1 }, Enum.EasingStyle.Back) end
		st.overlay:Destroy()
		return ok
	end

	function Window:_VxOpen(gen)
		-- lay the window out at home (still hidden) so every piece knows where it belongs
		local holder = self.Holder
		holder.Visible = false
		self.Scale.Scale = self.UserScale
		self._vortexing = false
		self:_Place()
		self._vortexing = true
		Svc.RunService.RenderStepped:Wait()
		if self._destroyed or self._vxGen ~= gen then return false end
		local st = self:_VxCapture()
		local H = st.hole
		local pieces = st.pieces
		table.insert(pieces, st.shell)

		local total = 0
		for _, p in ipairs(pieces) do
			local shell = p.kind == "shell"
			local mess = shell and 0.3 or (p.kind == "bg" and 0.55 or 1)
			local out = p.p0 - H
			out = out.Magnitude > 1 and out.Unit or Vector2.new(0, -1)
			local jitter = rotate(Vector2.new(1, 0), rand(0, math.pi * 2)) * rand(8, 34)
			p.E = shell and 0 or rand(0.015, 0.085)
			p.P1 = shell and 0.13 or rand(0.13, 0.18)
			p.H = shell and 0.02 or rand(0, 0.05)
			p.P2 = shell and 0.2 or rand(0.2, 0.26)
			p.M = p.p0 + (out * rand(18, 55) + jitter) * mess
			p.rm = p.r0 + rand(-26, 26) * mess
			p.sm = p.s * (1 + rand(-0.1, 0.1) * mess)
			p.rs = p.r0 + rand(-240, 240)
			total = math.max(total, p.E + p.P1 + p.H + p.P2)
			place(p, H, 0, p.rs)
		end

		self:_HoleRing(true, 0.4)
		local ok = self:_VxRun(gen, function(t)
			for _, p in ipairs(pieces) do
				local u1 = (t - p.E) / p.P1
				local u2 = (t - p.E - p.P1 - p.H) / p.P2
				if u2 >= 1 then
					place(p, p.p0, p.s, p.r0)
				elseif u2 >= 0 then
					-- settles back into its slot
					local e = outBack(u2)
					place(p, p.M:Lerp(p.p0, e), p.sm + (p.s - p.sm) * e, p.rm + (p.r0 - p.rm) * e)
				elseif u1 >= 0 then
					-- spat out of the hole
					local e = outQuint(math.min(1, u1))
					place(p, H:Lerp(p.M, e), p.s * 0.15 + (p.sm - p.s * 0.15) * e, p.rs + (p.rm - p.rs) * e)
				end
			end
			return t >= total
		end)
		if ok then holder.Visible = true end
		st.overlay:Destroy()
		return ok
	end

	function Window:_Vortex(opening)
		-- one animation at a time; whatever the user asked for last plays right after
		if self._vxBusy then return end
		self._vxBusy = true
		self._vxGen = (self._vxGen or 0) + 1
		local gen = self._vxGen
		self._animating = true
		self._vortexing = true
		task.spawn(function()
			local ok, res = pcall(function()
				if opening then return self:_VxOpen(gen) end
				return self:_VxClose(gen)
			end)
			if not ok then warn("[NebulaGui] vortex: " .. tostring(res)) end
			-- never leave clones behind, even if the animation errored halfway
			for _, ch in ipairs(self.Gui:GetChildren()) do
				if ch.Name == "Vortex" then ch:Destroy() end
			end
			if self._vxGen ~= gen or self._destroyed then
				self._vxBusy = false
				return
			end
			self._vxBusy = false
			self._animating = false
			self._vortexing = false
			self.Holder.Visible = self.Visible
			self.Scale.Scale = self.UserScale
			self:_Place()
			if self.Visible ~= opening then
				self:_Vortex(self.Visible)
			elseif opening then
				task.defer(function() self:_RelayoutAll() end)
			end
		end)
	end

	-- cancels a running black hole animation (instant show/hide)
	function Window:_VxCancel()
		if not self._vxBusy then return end
		self._vxGen = (self._vxGen or 0) + 1
		self._vxBusy = false
		self._animating = false
		self._vortexing = false
		local ov = self.Gui:FindFirstChild("Vortex")
		if ov then ov:Destroy() end
		self.Scale.Scale = self.UserScale
		self:_Place()
	end

	-- closing the hub for good (X): a new black hole opens in the middle of the window,
	-- swallows every piece and the floating button, then collapses into a flash and is gone
	function Window:_Collapse(done)
		self:_VxCancel()
		self._vxGen = (self._vxGen or 0) + 1
		local gen = self._vxGen
		self._vxBusy = true
		self._animating = true
		self._vortexing = true
		local shown = self.Holder.Visible
		local st = self:_VxCapture()
		self.Holder.Visible = false
		local pieces = st.pieces
		local C = shown and st.shell.p0 or st.hole
		if shown then table.insert(pieces, st.shell) else st.shell.g:Destroy() end
		local fb = self.Float
		if fb and fb.Visible then
			local cl = fb:Clone()
			if cl then
				local fp = makePiece(st, cl, fb.AbsolutePosition + fb.AbsoluteSize / 2 - st.origin, fb.AbsoluteSize, "float")
				fp.s = st.us
				fp.sc.Scale = st.us
			end
			fb.Visible = false
		end

		-- schedule: nearest to the centre first, the window shell and the button last
		local n = math.max(1, #pieces)
		for _, p in ipairs(pieces) do
			local v = C - p.p0
			p.d = v.Magnitude + rand(0, 40)
			p.dir = v.Magnitude > 1 and v.Unit or Vector2.zero
		end
		table.sort(pieces, function(a, b)
			local ka = a.kind == "float" and 2 or (a.kind == "shell" and 1 or 0)
			local kb = b.kind == "float" and 2 or (b.kind == "shell" and 1 or 0)
			if ka ~= kb then return ka < kb end
			return a.d < b.d
		end)
		local total = 0
		for k, p in ipairs(pieces) do
			local f = (k - 1) / n
			p.L = 0.18 + 0.42 * f ^ 0.7
			p.F = p.kind == "shell" and 0.36 or (p.kind == "float" and 0.4 or 0.34)
			p.spin = rand(0.9, 1.3)
			total = math.max(total, p.L + p.F)
		end

		-- the singularity
		local core = U.new("Frame", {
			Parent = st.overlay,
			BackgroundColor3 = T.Background,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(C.X, C.Y),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = st.z + 5,
		})
		U.round(core)
		local ring = U.stroke(core, T.Glow, 0, 3)
		local grad = U.new("UIGradient", {
			Parent = ring,
			Color = ColorSequence.new(T.Accent, T.Glow),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.15),
				NumberSequenceKeypoint.new(1, 0.85),
			}),
		})
		local halo = U.new("ImageLabel", {
			Parent = st.overlay,
			BackgroundTransparency = 1,
			Image = "rbxassetid://6015897843",
			ImageColor3 = T.Accent,
			ImageTransparency = 0.35,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(49, 49, 450, 450),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(C.X, C.Y),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = st.z + 4,
		})
		local coreSize = 0
		local gulp = 0

		local ok = self:_VxRun(gen, function(t, dt)
			for _, p in ipairs(pieces) do
				if p.g.Visible then
					local u = (t - p.L) / p.F
					if u >= 1 then
						p.g.Visible = false
						gulp = math.min(14, gulp + (p.kind == "leaf" and 3 or 9))
					elseif u >= 0 then
						local e = u * u
						local k = 1 - e
						local pos = C + rotate(p.p0 - C, e * math.pi * 1.4 * p.spin) * k
						place(p, pos, p.s * k ^ 1.3, p.r0 + e * 360 * p.spin)
					else
						-- everything trembles while the hole forms
						local a = math.clamp(t / p.L, 0, 1) ^ 2
						local shake = Vector2.new(math.sin(t * 59 + p.d), math.cos(t * 47 + p.d)) * 1.8 * a
						place(p, p.p0 + p.dir * 4 * a + shake, p.s * (1 - 0.03 * a), p.r0 + math.sin(t * 53 + p.d) * 2 * a)
					end
				end
			end
			gulp *= 0.88 ^ (dt * 60)
			coreSize = 58 * outBack(math.min(1, t / 0.22)) + gulp
			core.Size = UDim2.fromOffset(coreSize, coreSize)
			halo.Size = UDim2.fromOffset(coreSize * 2.6, coreSize * 2.6)
			grad.Rotation = (t * 540) % 360
			return t >= total
		end)
		if not ok then
			st.overlay:Destroy()
			return done()
		end

		-- collapse to a point, then a lilac flash and a shockwave
		U.tween(core, 0.16, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		U.tween(halo, 0.16, { Size = UDim2.fromOffset(0, 0), ImageTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.16)
		if self._destroyed then return end
		local flash = U.new("Frame", {
			Parent = st.overlay,
			BackgroundColor3 = T.Glow,
			BackgroundTransparency = 0.1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(C.X, C.Y),
			Size = UDim2.fromOffset(8, 8),
			ZIndex = st.z + 6,
		})
		U.round(flash)
		local wave = U.new("Frame", {
			Parent = st.overlay,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(C.X, C.Y),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = st.z + 6,
		})
		U.round(wave)
		local ws = U.stroke(wave, T.Glow, 0, 3)
		U.tween(flash, 0.32, { Size = UDim2.fromOffset(90, 90), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
		U.tween(wave, 0.45, { Size = UDim2.fromOffset(420, 420) }, Enum.EasingStyle.Quint)
		U.tween(ws, 0.45, { Transparency = 1, Thickness = 0.5 })
		task.wait(0.45)
		done()
	end
end

-- shockwave ring around the floating button: bursts out (opening) or collapses in (closing)
function Window:_HoleRing(opening, dur)
	local fb = self.Float
	if not fb then return end
	local size = fb.AbsoluteSize.X
	local ring = U.new("Frame", {
		Parent = self.Gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fb.AbsolutePosition.X - self.Gui.AbsolutePosition.X + size / 2, fb.AbsolutePosition.Y - self.Gui.AbsolutePosition.Y + size / 2),
		ZIndex = 0,
	})
	U.round(ring)
	local st = U.stroke(ring, T.Glow, 0.2, 2)
	if opening then
		ring.Size = UDim2.fromOffset(size, size)
		U.tween(ring, dur, { Size = UDim2.fromOffset(size * 3.4, size * 3.4) }, Enum.EasingStyle.Quint)
		U.tween(st, dur, { Transparency = 1, Thickness = 0.5 })
		local sc = fb:FindFirstChild("Pulse") or U.new("UIScale", { Parent = fb, Name = "Pulse" })
		sc.Scale = 1.2
		U.tween(sc, dur, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		ring.Size = UDim2.fromOffset(size * 3.2, size * 3.2)
		st.Transparency = 0.8
		U.tween(ring, dur, { Size = UDim2.fromOffset(size * 0.6, size * 0.6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		U.tween(st, dur, { Transparency = 0.1, Thickness = 3 })
		task.delay(dur, function()
			if st.Parent then U.tween(st, 0.15, { Transparency = 1 }) end
		end)
	end
	task.delay(dur + 0.2, function() ring:Destroy() end)
end

-- MacLib-style alias: HideUI(true) hides, HideUI(false) shows
function Window:HideUI(state)
	self:SetVisible(not state)
end

function Window:SetState(state) self:SetVisible(state) end
function Window:GetState() return self.Visible end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetKeybind(key)
	self.Keybind = key
end

function Window:SetLanguage(code)
	if not Tr.Names[code] then return end
	self.Settings.Language = code
	self:_SaveSettings()
	Tr.SetLang(code)
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, fn in ipairs(self._unload) do pcall(fn) end
	-- undo every world change the extras made
	pcall(function() self:SetLowCpu(false) end)
	pcall(function() self:SetFPSBoost(false) end)
	pcall(function() self:SetHidePlayer(false) end)
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
	pcall(function() self.Gui:Destroy() end)
	local i = table.find(Nebula.Windows, self)
	if i then table.remove(Nebula.Windows, i) end
end

function Window:Category(name)
	self._order += 1
	local l = U.text({
		Parent = self.TabList,
		FontFace = F.Bold,
		TextSize = 10,
		TextColor3 = T.Muted,
		Size = UDim2.new(1, 0, 0, 28),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = self._order,
	})
	U.pad(l, 0, 8, 6, 8)
	Tr.Register(l, string.upper(name))
	return l
end

function Window:SelectTab(tab)
	if self.Current == tab then
		self:_Drawer(false)
		return
	end
	self:_ClosePopup()
	for _, t in ipairs(self.Tabs) do
		local on = t == tab
		t.Page.Visible = on
		U.tween(t.Button, 0.18, { BackgroundTransparency = on and 0.84 or 1 })
		U.tween(t.Stroke, 0.18, { Transparency = on and 0.6 or 1 })
		t.Label.TextColor3 = on and T.Text or T.Muted
		t.Label.FontFace = on and F.SemiBold or F.Medium
		if t.Icon then t.Icon.ImageColor3 = on and T.Glow or T.Muted end
	end
	self.Current = tab
	Tr.Register(self.TabTitle, tab.Name)
	self:_Drawer(false)
	task.defer(function() tab:_Relayout() end)
end

function Window:Tab(arg: string | TabOptions)
	local o: TabOptions = if type(arg) == "string" then { Name = arg } else arg
	local tab = setmetatable({ Window = self, Name = o.Name or "Tab", Sections = {}, _relayouts = {} }, Tab)
	self._order += 1

	local btn = U.button({
		Parent = self.TabList,
		BackgroundColor3 = T.Accent,
		Size = UDim2.new(1, 0, 0, self.Compact and 44 or 36),
		LayoutOrder = self._order,
	})
	U.corner(btn, 8)
	tab.Stroke = U.stroke(btn, T.Accent, 1)
	local x = 12
	if o.Icon then
		tab.Icon = U.new("ImageLabel", {
			Parent = btn,
			BackgroundTransparency = 1,
			Image = o.Icon,
			ImageColor3 = T.Muted,
			Position = UDim2.new(0, 10, 0.5, -8),
			Size = UDim2.fromOffset(16, 16),
		})
		x = 34
	end
	tab.Label = U.text({ Parent = btn, TextColor3 = T.Muted, Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 8, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	Tr.Register(tab.Label, tab.Name)
	tab.Button = btn
	U.hover(btn, function()
		if self.Current ~= tab then U.tween(btn, 0.12, { BackgroundTransparency = 0.93 }) end
	end, function()
		if self.Current ~= tab then U.tween(btn, 0.12, { BackgroundTransparency = 1 }) end
	end)
	U.onClick(btn, function() self:SelectTab(tab) end)

	local page = U.new("ScrollingFrame", {
		Parent = self.Pages,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent,
		Visible = false,
	})
	-- side padding is done with offsets, not UIPadding: in a ScrollingFrame an
	-- AutomaticSize child ignores the padding width and overflows on the right
	U.new("UIPadding", { Parent = page, PaddingBottom = UDim.new(0, 18) })
	local cols = U.new("Frame", {
		Parent = page,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 16),
		Size = UDim2.new(1, -36, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	tab.Page = page
	tab.Left = U.new("Frame", { Parent = cols, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
	tab.Right = U.new("Frame", { Parent = cols, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
	U.list(tab.Left, 14)
	U.list(tab.Right, 14)

	table.insert(self.Tabs, tab)
	tab:_SetCols(self.Cols == 0 and 2 or self.Cols)
	if not self.Current then self:SelectTab(tab) end
	return tab
end

---------------------------------------------------------------------------
-- Popups (dropdowns, language picker)
---------------------------------------------------------------------------
function Window:_OpenPopup(anchor, width, height)
	self:_ClosePopup()
	local ov = self.Overlay
	local catcher = U.button({ Parent = ov, Size = UDim2.fromScale(1, 1), ZIndex = 1 })
	local pop = U.new("CanvasGroup", { Parent = ov, BackgroundColor3 = T.Surface, ZIndex = 2, Active = true })
	U.corner(pop, 10)
	U.stroke(pop, T.BorderHi)
	local s = self:_S()
	local rel = (anchor.AbsolutePosition - ov.AbsolutePosition) / s
	local asz = anchor.AbsoluteSize / s
	-- bounds = the whole screen, in overlay coordinates (the side panel can sit outside the window)
	local lo = -ov.AbsolutePosition / s
	local hi = lo + self.Gui.AbsoluteSize / s
	catcher.Position = UDim2.fromOffset(lo.X, lo.Y)
	catcher.Size = UDim2.fromOffset(hi.X - lo.X, hi.Y - lo.Y)
	height = math.min(height, hi.Y - lo.Y - 16)
	local x = math.clamp(rel.X + asz.X - width, lo.X + 8, math.max(lo.X + 8, hi.X - width - 8))
	local y = rel.Y + asz.Y + 6
	if y + height > hi.Y - 8 then y = math.max(lo.Y + 8, rel.Y - height - 6) end
	pop.Size = UDim2.fromOffset(width, height)
	pop.Position = UDim2.fromOffset(x, y - 6)
	U.tween(pop, 0.16, { Position = UDim2.fromOffset(x, y) })
	U.onClick(catcher, function() self:_ClosePopup() end)
	self._popup = { pop, catcher }
	return pop
end

function Window:_ClosePopup()
	if self._popup then
		for _, g in ipairs(self._popup) do g:Destroy() end
		self._popup = nil
	end
end

function Window:_PopupRow(parent, text, selected, onClick)
	local b = U.button({ Parent = parent, BackgroundColor3 = T.Accent, BackgroundTransparency = selected and 0.82 or 1, Size = UDim2.new(1, 0, 0, 30) })
	U.corner(b, 6)
	U.text({ Parent = b, Text = text, TextSize = 12, TextColor3 = selected and T.Text or T.Muted, FontFace = selected and F.SemiBold or F.Medium, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -36, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	if selected then U.icon("check", b, 12, T.Glow, { Position = UDim2.new(1, -22, 0.5, -6) }) end
	U.hover(b, function()
		if not selected then b.BackgroundTransparency = 0.92 end
	end, function()
		if not selected then b.BackgroundTransparency = 1 end
	end)
	U.onClick(b, onClick)
	return b
end

function Window:_LanguagePopup()
	local pop = self:_OpenPopup(self.LangBtn, 200, #Tr.Codes * 32 + 8)
	U.pad(pop, 4)
	U.list(pop, 2)
	for i, code in ipairs(Tr.Codes) do
		local r = self:_PopupRow(pop, string.upper(code) .. "   " .. Tr.Names[code], code == Tr.Lang, function()
			self:_ClosePopup()
			self:SetLanguage(code)
		end)
		r.LayoutOrder = i
	end
end

---------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------
function Window:_Index(cont, name, label, row)
	if not name or name == "" or cont.Tab.NoIndex then return end
	table.insert(self._index, { name = name, label = label, row = row, cont = cont, tab = cont.Tab })
end

function Window:_HideSearchResults()
	if self._searchPop then
		self._searchPop:Destroy()
		self._searchPop = nil
	end
end

function Window:_Search(q)
	self:_HideSearchResults()
	q = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then return end
	for i = #self._index, 1, -1 do
		if not self._index[i].row.Parent then table.remove(self._index, i) end
	end
	local found = {}
	for _, e in ipairs(self._index) do
		if e.row.Parent and (e.name:lower():find(q, 1, true) or e.label.Text:lower():find(q, 1, true)) then
			table.insert(found, e)
			if #found >= 8 then break end
		end
	end
	local ov = self.Overlay
	local sf = self.SearchFrame
	local s = self:_S()
	local rel = (sf.AbsolutePosition - ov.AbsolutePosition) / s
	local ssz = sf.AbsoluteSize / s
	local w = math.max(ssz.X, 300)
	local h = math.max(1, #found) * 38 + 8
	local pop = U.new("Frame", {
		Parent = ov,
		Active = true,
		BackgroundColor3 = T.Surface,
		ZIndex = 3,
		Position = UDim2.fromOffset(math.clamp(rel.X + ssz.X - w, 8, math.max(8, ov.AbsoluteSize.X / s - w - 8)), rel.Y + ssz.Y + 6),
		Size = UDim2.fromOffset(w, h),
	})
	U.corner(pop, 10)
	U.stroke(pop, T.BorderHi)
	U.pad(pop, 4)
	U.list(pop, 2)
	self._searchPop = pop
	if #found == 0 then
		U.text({ Parent = pop, Text = Tr.Lookup("No results"), TextColor3 = T.Muted, TextSize = 12, Size = UDim2.new(1, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Center })
		return
	end
	for i, e in ipairs(found) do
		local b = U.button({ Parent = pop, BackgroundColor3 = T.Accent, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = i })
		U.corner(b, 6)
		U.text({ Parent = b, Text = e.label.Text, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -10, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		-- right side: what the element is (lilac) · which tab it's in
		local kind = e.row:GetAttribute("NebulaKind")
		local where = (kind and ('<font color="#' .. T.Glow:ToHex() .. '">' .. Tr.Get(kind) .. "</font>  ·  ") or "") .. e.tab.Label.Text
		U.text({ Parent = b, Text = where, RichText = true, TextSize = 11, TextColor3 = T.Muted, Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.5, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
		U.hover(b, function() b.BackgroundTransparency = 0.88 end, function() b.BackgroundTransparency = 1 end)
		U.onClick(b, function()
			self:_HideSearchResults()
			self.SearchBox.Text = ""
			self.SearchBox:ReleaseFocus()
			self:_Reveal(e)
		end)
	end
end

function Window:_Reveal(e)
	task.spawn(function()
		self:SelectTab(e.tab)
		e.cont:_Reveal()
		task.wait()
		task.wait()
		local page = e.tab.Page
		local y = (e.row.AbsolutePosition.Y - page.AbsolutePosition.Y) / self:_S() + page.CanvasPosition.Y - 24
		U.tween(page, 0.35, { CanvasPosition = Vector2.new(0, math.max(0, y)) })
		local st = e.row:FindFirstChild("NebulaHighlight") or U.stroke(e.row, T.Accent, 1, 2)
		st.Name = "NebulaHighlight"
		st.Transparency = 1
		U.tween(st, 0.25, { Transparency = 0 })
		task.wait(1.6)
		if st.Parent then U.tween(st, 0.6, { Transparency = 1 }) end
	end)
end

---------------------------------------------------------------------------
-- Notifications & dialogs
---------------------------------------------------------------------------
function Window:Notify(arg: string | NotifyOptions)
	local o: NotifyOptions = if type(arg) == "string" then { Title = arg } else arg
	if not self.NotificationsEnabled and not o.Force then
		return { Close = function() end }
	end
	local translate = o.Translate ~= false
	local live = {}
	for _, c in ipairs(self.NotifyHolder:GetChildren()) do
		if c:IsA("CanvasGroup") then table.insert(live, c) end
	end
	for i = 1, #live - 3 do live[i]:Destroy() end -- oldest first; keeps 3 + the new one
	local card = U.new("CanvasGroup", {
		Parent = self.NotifyHolder,
		BackgroundColor3 = T.Surface,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
	})
	U.corner(card, 12)
	U.stroke(card, T.BorderHi)
	local inner = U.new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.pad(inner, 12, 14, 14, 14)
	local badge = U.new("Frame", { Parent = inner, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.8, Size = UDim2.fromOffset(30, 30) })
	U.corner(badge, 8)
	U.icon(o.Icon or "check", badge, 14, T.Glow, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local col = U.new("Frame", { Parent = inner, BackgroundTransparency = 1, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -42, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.list(col, 2)
	local title = U.text({ Parent = col, FontFace = F.Bold, TextSize = 13, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 1 })
	if translate then Tr.Register(title, o.Title or "Notice") else title.Text = o.Title or "" end
	if o.Content then
		local c = U.text({ Parent = col, TextSize = 11, TextColor3 = T.Muted, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2 })
		if translate then Tr.Register(c, o.Content) else c.Text = o.Content end
	end
	local bar = U.new("Frame", { Parent = card, BackgroundColor3 = T.Glow, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2) })

	local duration = o.Duration or 4
	U.tween(card, 0.25, { GroupTransparency = 0 })
	Svc.TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
	local closed = false
	local function close()
		if closed then return end
		closed = true
		U.tween(card, 0.25, { GroupTransparency = 1 })
		task.delay(0.26, function() card:Destroy() end)
	end
	local hit = U.button({ Parent = card, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	U.onClick(hit, close)
	task.delay(duration, close)
	return { Close = close }
end

function Window:Dialog(o: DialogOptions?)
	o = o or {}
	self:_ClosePopup()
	if not self.Visible then self:SetVisible(true) end
	local scrim = U.button({ Parent = self.Overlay, BackgroundColor3 = T.Background, BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	U.corner(scrim, 14)
	local card = U.new("Frame", {
		Parent = scrim,
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.min(340, self.Main.AbsoluteSize.X / self:_S() - 32), 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 6,
	})
	U.corner(card, 12)
	U.stroke(card, T.Accent, 0.45, 1.5)
	U.pad(card, 18)
	U.list(card, 10)
	local title = U.text({ Parent = card, FontFace = F.Bold, TextSize = 15, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 1 })
	Tr.Register(title, o.Title or "Confirm")
	if o.Content then
		local c = U.text({ Parent = card, TextSize = 12, TextColor3 = T.Muted, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, LayoutOrder = 2 })
		Tr.Register(c, o.Content)
	end
	local row = U.new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3 })
	local l = U.list(row, 8, true)
	l.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local function close() scrim:Destroy() end
	for i, b in ipairs(o.Buttons or { { Name = "OK", Primary = true } }) do
		local btn = U.button({
			Parent = row,
			BackgroundColor3 = b.Primary and T.Accent or T.Elevated,
			BackgroundTransparency = 0,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = i,
			FontFace = b.Primary and F.Bold or F.SemiBold,
			TextSize = 12,
			TextColor3 = b.Primary and T.White or T.Text,
		})
		U.corner(btn, 8)
		U.pad(btn, 0, 16, 0, 16)
		if not b.Primary then U.stroke(btn, T.Border) end
		Tr.Register(btn, b.Name or "OK")
		U.onClick(btn, function()
			close()
			U.safe(b.Callback)
		end)
	end
	card.Position = UDim2.new(0.5, 0, 0.5, 8)
	U.tween(card, 0.2, { Position = UDim2.fromScale(0.5, 0.5) })
	return { Close = close }
end

---------------------------------------------------------------------------
-- Configs
---------------------------------------------------------------------------
function Window:_Flag(flag, e)
	if flag then self.Flags[flag] = e end
end

function Window:SaveConfig(name)
	name = U.cleanName(name)
	if name == "" then return false end
	local data = {}
	for flag, e in pairs(self.Flags) do
		local ok, v = pcall(e.Get, e)
		if ok then
			if typeof(v) == "EnumItem" then v = v.Name end
			data[flag] = v
		end
	end
	FS.mkdir(self.Folder .. "/configs")
	return FS.writeJSON(self.Folder .. "/configs/" .. name .. ".json", data)
end

function Window:LoadConfig(name)
	name = U.cleanName(name)
	local data = name ~= "" and FS.readJSON(self.Folder .. "/configs/" .. name .. ".json")
	if not data then return false end
	for flag, v in pairs(data) do
		local e = self.Flags[flag]
		if e then pcall(e.Set, e, v) end
	end
	return true
end

function Window:DeleteConfig(name)
	name = U.cleanName(name)
	if name == "" then return false end
	if self.Settings.AutoLoad == name then
		self.Settings.AutoLoad = nil
		self:_SaveSettings()
	end
	return FS.del(self.Folder .. "/configs/" .. name .. ".json")
end

function Window:ListConfigs()
	local out = {}
	for _, p in ipairs(FS.list(self.Folder .. "/configs")) do
		local n = tostring(p):match("([^/\\]+)%.json$")
		if n then table.insert(out, n) end
	end
	table.sort(out)
	return out
end

function Window:SetAutoLoad(name)
	self.Settings.AutoLoad = name
	self:_SaveSettings()
end

function Window:LoadAutoConfig()
	local n = self.Settings.AutoLoad
	if n and self:LoadConfig(n) then
		self:Notify({ Title = "Config loaded", Content = n, Translate = false })
		return true
	end
	return false
end

function Window:ConfigSection(tab, sectionName)
	local s = tab:Section({ Name = sectionName or "Configs" })
	local nameIn = s:Input({ Name = "Name", Placeholder = "my-config" })
	local list = s:Dropdown({ Name = "Saved configs", Options = self:ListConfigs(), Placeholder = "None" })
	local function current()
		local n = U.cleanName(nameIn:Get())
		if n == "" then n = list:Get() or "" end
		return n
	end
	local function refresh() list:Refresh(self:ListConfigs(), true) end
	s:Button({ Name = "Save config", Primary = true, Callback = function()
		local n = current()
		if self:SaveConfig(n) then
			refresh()
			list:Set(n, true)
			self:Notify({ Title = Tr.Lookup("Config saved") .. ": " .. n, Translate = false })
		else
			self:Notify({ Title = "Couldn't save", Content = "Type a name first (letters, numbers, - and _).", Icon = "info" })
		end
	end })
	s:Button({ Name = "Load config", Callback = function()
		local n = current()
		if self:LoadConfig(n) then
			self:Notify({ Title = Tr.Lookup("Config loaded") .. ": " .. n, Translate = false })
		else
			self:Notify({ Title = "Couldn't load", Content = "Pick a saved config first.", Icon = "info" })
		end
	end })
	s:Button({ Name = "Delete config", Callback = function()
		local n = current()
		if n == "" then return end
		self:Dialog({
			Title = "Delete config?",
			Content = "This removes the file for good.",
			Buttons = {
				{ Name = "Cancel" },
				{ Name = "Delete", Primary = true, Callback = function()
					self:DeleteConfig(n)
					refresh()
				end },
			},
		})
	end })
	s:Toggle({
		Name = "Load on start",
		Description = "Loads the selected config when the script runs",
		Default = self.Settings.AutoLoad ~= nil,
		Callback = function(v) self:SetAutoLoad(v and current() ~= "" and current() or nil) end,
	})
	s:Button({ Name = "Refresh list", Callback = refresh })
	return s
end

---------------------------------------------------------------------------
-- Tabs & sections
---------------------------------------------------------------------------
function Tab:_SetCols(n)
	if n == 2 then
		self.Left.Size = UDim2.new(0.5, -7, 0, 0)
		self.Right.Position = UDim2.new(0.5, 7, 0, 0)
		self.Right.Size = UDim2.new(0.5, -7, 0, 0)
		self.Right.Visible = true
	else
		self.Left.Size = UDim2.fromScale(1, 0)
		self.Right.Visible = false
	end
	for _, s in ipairs(self.Sections) do
		s.Frame.Parent = (n == 2 and s.Side == "Right") and self.Right or self.Left
	end
	task.defer(function() self:_Relayout() end)
end

function Tab:_Relayout()
	local list = self._relayouts
	for i = #list, 1, -1 do
		local item = list[i]
		if item[1].Parent then item[2](true) else table.remove(list, i) end
	end
end

function Tab:Section(arg: string | SectionOptions)
	local o: SectionOptions = if type(arg) == "string" then { Name = arg } else arg
	local idx = #self.Sections + 1
	local side = o.Side or ((idx % 2 == 1) and "Left" or "Right")
	local f = U.new("Frame", {
		BackgroundColor3 = T.Elevated,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = idx,
	})
	U.corner(f, 12)
	U.stroke(f, T.Border)
	U.pad(f, 14)
	U.list(f, 12)
	if o.Name then
		local t = U.text({ Parent = f, FontFace = F.Bold, TextSize = 11, TextColor3 = T.Glow, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = -2 })
		Tr.Register(t, string.upper(o.Name))
	end
	if o.Description then
		local d = U.text({ Parent = f, TextSize = 11, TextColor3 = T.Muted, TextWrapped = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = -1 })
		Tr.Register(d, o.Description)
	end
	local c = Container.new(self.Window, self, f, nil)
	c.Frame, c.Side, c.Index = f, side, idx
	table.insert(self.Sections, c)
	f.Parent = (self.Window.Cols ~= 1 and side == "Right") and self.Right or self.Left
	return c
end

---------------------------------------------------------------------------
-- Container (sections and collapsibles share every element)
---------------------------------------------------------------------------
function Container.new(w, tab, body, parent)
	return setmetatable({ Window = w, Tab = tab, Body = body, ParentContainer = parent, _n = 0 }, Container)
end

function Container:_Reveal()
	if self.ParentContainer then self.ParentContainer:_Reveal() end
	if self.SetOpen then self.SetOpen(true) end
end

function Container:_NewRow(h)
	self._n += 1
	local row = U.new("Frame", {
		Parent = self.Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, h or 22),
		LayoutOrder = self._n,
	})
	U.corner(row, 6)
	return row
end

local function element(row, o)
	local e = { Row = row, Flag = o.Flag }
	function e:SetVisible(v) row.Visible = v end
	function e:Destroy() row:Destroy() end
	function e:SetName(t)
		local l = row:FindFirstChild("Title")
		if l then Tr.Register(l, t) end
	end
	-- disabled: dims the row and swallows input
	function e:SetDisabled(on)
		local cover = row:FindFirstChild("Disabled")
		if on and not cover then
			cover = U.button({ Parent = row, Name = "Disabled", BackgroundColor3 = T.Elevated, BackgroundTransparency = 0.35, Size = UDim2.new(1, 4, 1, 4), Position = UDim2.fromOffset(-2, -2), ZIndex = 20 })
			U.corner(cover, 6)
		elseif not on and cover then
			cover:Destroy()
		end
		e.Disabled = on == true
	end
	-- MacLib-style aliases
	e.UpdateName = e.SetName
	e.SetVisibility = e.SetVisible
	return e
end

-- name (+ description) on the left, control on the right.
-- stackable: when the name doesn't fit, the control drops to its own line at full width.
function U.inlineRow(cont, o, ctrlW, ctrlH, stackable)
	local w = cont.Window
	local row = cont:_NewRow(ctrlH)
	local name = U.text({ Parent = row, Name = "Title", FontFace = F.SemiBold, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
	Tr.Register(name, o.Name or "")
	local desc
	if o.Description then
		desc = U.text({ Parent = row, TextSize = 11, TextColor3 = T.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
		Tr.Register(desc, o.Description)
	end
	local ctrl = U.new("Frame", { Parent = row, BackgroundTransparency = 1, Size = UDim2.fromOffset(ctrlW, ctrlH) })
	local gear, gw = nil, 0
	if type(o.Settings) == "function" then
		gear = U.gearButton(w, row, { Title = o.SettingsTitle or o.Name, Build = o.Settings })
		gw = 34
	end
	local run
	name:GetPropertyChangedSignal("Text"):Connect(function() if run then run(true) end end)
	run = w:_Watch(cont, row, function(W)
		-- controls that can stretch (dropdown, input, segmented) give up width on narrow rows;
		-- long names wrap to two lines so every control in a section stays right-aligned.
		-- only really narrow rows (phone portrait) move the control to its own line.
		local cw = stackable and math.min(ctrlW, math.floor(W * 0.5)) or ctrlW
		local avail = W - cw - gw - 12
		local stacked = stackable and avail < 90
		local tw = stacked and W or avail
		local nh = U.measureH(name.Text, 13, tw)
		local dh = desc and U.measureH(desc.Text, 11, tw) or 0
		local th = nh + (desc and (dh + 2) or 0)
		local ty, h
		if stacked then
			ty = 0
			ctrl.Position = UDim2.fromOffset(0, th + 8)
			ctrl.Size = UDim2.fromOffset(W - gw, ctrlH)
			h = th + 8 + ctrlH
			if gear then gear.Position = UDim2.fromOffset(W - 28, th + 8 + math.floor((ctrlH - 28) / 2)) end
		else
			h = math.max(th, ctrlH)
			ty = math.floor((h - th) / 2)
			ctrl.Position = UDim2.fromOffset(W - cw, math.floor((h - ctrlH) / 2))
			ctrl.Size = UDim2.fromOffset(cw, ctrlH)
			if gear then gear.Position = UDim2.fromOffset(W - cw - gw, math.floor((h - 28) / 2)) end
		end
		name.Position = UDim2.fromOffset(0, ty)
		name.Size = UDim2.fromOffset(tw, nh)
		if desc then
			desc.Position = UDim2.fromOffset(0, ty + nh + 2)
			desc.Size = UDim2.fromOffset(tw, dh)
		end
		row.Size = UDim2.new(1, 0, 0, h)
	end)
	w:_Index(cont, o.Name, name, row)
	return row, ctrl, name
end

-- Toggle ---------------------------------------------------------------------
function Container:Toggle(o: ToggleOptions)
	local row, ctrl = U.inlineRow(self, o, 40, 22, false)
	local hit = U.button({ Parent = row, Size = UDim2.fromScale(1, 1), ZIndex = 0 })
	local track = U.new("Frame", { Parent = ctrl, BackgroundColor3 = T.Border, Size = UDim2.fromScale(1, 1) })
	U.round(track)
	local glow = U.stroke(track, T.Accent, 1, 2)
	local knob = U.new("Frame", {
		Parent = track,
		BackgroundColor3 = T.Muted,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
	})
	U.round(knob)
	local e = element(row, o)
	e.Value = o.Default == true
	local function render(t)
		local on = e.Value
		U.tween(track, t, { BackgroundColor3 = on and T.Accent or T.Border })
		U.tween(knob, t, { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = on and T.White or T.Muted })
		U.tween(glow, t, { Transparency = on and 0.55 or 1 })
	end
	function e:Set(v, silent)
		e.Value = v == true
		render(0.18)
		if not silent then U.safe(o.Callback, e.Value) end
	end
	function e:Get() return e.Value end
	U.onClick(hit, function() e:Set(not e.Value) end)
	render(0)
	self.Window:_Flag(o.Flag, e)
	return e
end

-- Slider ---------------------------------------------------------------------
function Container:Slider(o: SliderOptions)
	local w = self.Window
	local min, max = o.Min or 0, o.Max or 100
	local step = o.Step or o.Increment or 1
	local suffix = o.Suffix or ""
	local decimals = step < 1 and #(tostring(step):match("%.(%d+)") or "") or 0
	local row = self:_NewRow(22)
	local name = U.text({ Parent = row, Name = "Title", FontFace = F.SemiBold, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
	Tr.Register(name, o.Name or "")
	local bar = U.button({ Parent = row, Size = UDim2.fromOffset(100, 22) })
	local track = U.new("Frame", { Parent = bar, BackgroundColor3 = T.Border, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 6) })
	U.round(track)
	local fill = U.new("Frame", { Parent = track, BackgroundColor3 = T.Accent, Size = UDim2.fromScale(0, 1) })
	U.round(fill)
	local knob = U.new("Frame", { Parent = bar, BackgroundColor3 = T.Text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16) })
	U.round(knob)
	U.stroke(knob, T.Glow, 0.5, 3)
	local box = U.new("TextBox", {
		Parent = row,
		BackgroundTransparency = 1,
		FontFace = F.Bold,
		TextSize = 12,
		TextColor3 = T.Glow,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		Size = UDim2.fromOffset(48, 22),
		Text = "",
	})
	local e = element(row, o)
	local function fmt(v)
		local s = decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(math.floor(v + 0.5))
		return s .. suffix
	end
	local function render()
		local a = (e.Value - min) / math.max(max - min, 1e-9)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		if not box:IsFocused() then box.Text = fmt(e.Value) end
	end
	function e:Set(v, silent)
		v = tonumber(v) or e.Value or min
		v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		v = tonumber(string.format("%.6f", v))
		local changed = v ~= e.Value
		e.Value = v
		render()
		if changed and not silent then U.safe(o.Callback, v) end
	end
	function e:Get() return e.Value end

	local dragging = false
	local function update(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		e:Set(min + a * (max - min))
	end
	bar.InputBegan:Connect(function(i)
		if U.isPress(i) then
			dragging = true
			self.Tab.Page.ScrollingEnabled = false
			update(i.Position.X)
		end
	end)
	w:_ConnectFor(row, Svc.UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
	w:_ConnectFor(row, Svc.UserInputService.InputEnded, function(i)
		if dragging and U.isPress(i) then
			dragging = false
			self.Tab.Page.ScrollingEnabled = true
		end
	end)
	-- clicking the value clears it: the player just types the new number (the suffix stays)
	local editing = false
	box.PlaceholderColor3 = T.Faint
	box.Focused:Connect(function()
		editing = true
		box.PlaceholderText = fmt(e.Value)
		box.Text = suffix
		box.CursorPosition = 1
		editing = false
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if editing or not box:IsFocused() or suffix == "" then return end
		local digits = box.Text:gsub("[^%d%.%-]", "")
		if box.Text == digits .. suffix then return end
		editing = true
		box.Text = digits .. suffix
		box.CursorPosition = #digits + 1
		editing = false
	end)
	box.FocusLost:Connect(function()
		e:Set(tonumber((box.Text:gsub("[^%d%.%-]", ""))))
		render()
	end)

	self._sliderNames = self._sliderNames or {}
	table.insert(self._sliderNames, name)
	local cont = self
	-- the column fits the longest slider name in this section (max 45% of the row);
	-- names longer than that wrap inside the column instead of breaking the alignment
	local function column(W)
		local widest = 0
		for _, n in ipairs(cont._sliderNames) do
			if n.Parent then widest = math.max(widest, U.measure(n.Text, 13).X * 1.07) end
		end
		return math.clamp(math.ceil(widest) + 4, 70, math.floor(W * 0.45))
	end
	name:GetPropertyChangedSignal("Text"):Connect(function()
		task.defer(function() cont.Tab:_Relayout() end)
	end)

	w:_Watch(self, row, function(W)
		local valW = 48
		if W >= 220 then
			local L = column(W)
			local nh = math.max(16, U.measureH(name.Text, 13, L))
			local h = math.max(22, nh)
			name.TextYAlignment = Enum.TextYAlignment.Center
			name.Position = UDim2.new()
			name.Size = UDim2.fromOffset(L, h)
			bar.Position = UDim2.fromOffset(L + 10, math.floor((h - 22) / 2))
			bar.Size = UDim2.fromOffset(math.max(20, W - L - valW - 20), 22)
			box.Position = UDim2.fromOffset(W - valW, math.floor((h - 22) / 2))
			row.Size = UDim2.new(1, 0, 0, h)
		else
			local nh = U.measureH(name.Text, 13, W)
			name.TextYAlignment = Enum.TextYAlignment.Top
			name.Position = UDim2.new()
			name.Size = UDim2.fromOffset(W, nh)
			bar.Position = UDim2.fromOffset(0, nh + 6)
			bar.Size = UDim2.fromOffset(math.max(20, W - valW - 10), 22)
			box.Position = UDim2.fromOffset(W - valW, nh + 6)
			row.Size = UDim2.new(1, 0, 0, nh + 28)
		end
	end)
	-- a new slider can widen the column: realign the ones already in this section
	task.defer(function() cont.Tab:_Relayout() end)
	w:_Index(self, o.Name, name, row)
	e:Set(o.Default or min, true)
	w:_Flag(o.Flag, e)
	return e
end

-- Input ----------------------------------------------------------------------
function Container:Input(o: InputOptions)
	local row, ctrl = U.inlineRow(self, o, o.Width or 170, 30, true)
	local box = U.new("TextBox", {
		Parent = ctrl,
		BackgroundColor3 = T.Background,
		Size = UDim2.fromScale(1, 1),
		FontFace = F.Medium,
		TextSize = 12,
		TextColor3 = T.Text,
		PlaceholderColor3 = T.Faint,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Text = "",
	})
	U.corner(box, 8)
	local st = U.stroke(box, T.Border)
	U.pad(box, 0, 10, 0, 10)
	if o.Placeholder then Tr.Register(box, o.Placeholder, "PlaceholderText") end
	local e = element(row, o)
	e.Value = ""
	function e:Set(v, silent)
		box.Text = tostring(v or "")
		e.Value = box.Text
		if not silent then U.safe(o.Callback, e.Value) end
	end
	function e:Get() return e.Value end
	-- AcceptedCharacters: "All" | "Numeric" | "Alphabetic" | "AlphaNumeric" (Numeric = true also works)
	local filters = { Numeric = "[^%d%.%-]", Alphabetic = "[^%a%s]", AlphaNumeric = "[^%w%s]" }
	local pattern = filters[o.AcceptedCharacters or (o.Numeric and "Numeric") or "All"]
	if pattern then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = box.Text:gsub(pattern, "")
			if clean ~= box.Text then box.Text = clean end
		end)
	end
	if o.MaxLength then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if #box.Text > o.MaxLength then box.Text = box.Text:sub(1, o.MaxLength) end
		end)
	end
	box.Focused:Connect(function() st.Color = T.Accent end)
	box.FocusLost:Connect(function()
		st.Color = T.Border
		if box.Text ~= e.Value then e:Set(box.Text) end
	end)
	-- Changed (or Live = true): fires on every keystroke; Callback fires when focus is lost
	local changedFn = o.Changed or o.onChanged or (o.Live and o.Callback)
	if changedFn then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if box:IsFocused() then U.safe(changedFn, box.Text) end
		end)
	end
	function e:SetPlaceholder(t) Tr.Register(box, t, "PlaceholderText") end
	e.UpdatePlaceholder = e.SetPlaceholder
	e.UpdateText = e.Set
	e.GetInput = e.Get
	e:Set(o.Default or "", true)
	self.Window:_Flag(o.Flag, e)
	return e
end

-- Dropdown -------------------------------------------------------------------
function Container:Dropdown(o: DropdownOptions)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, o, o.Width or 160, 32, true)
	local btn = U.button({ Parent = ctrl, BackgroundColor3 = T.Background, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1) })
	U.corner(btn, 8)
	local st = U.stroke(btn, T.Border)
	local txt = U.text({ Parent = btn, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	U.icon("down", btn, 12, T.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) })
	U.hover(btn, function() st.Color = T.BorderHi end, function() st.Color = T.Border end)

	local e = element(row, o)
	e.Options = table.clone(o.Options or {})
	e.Multi = o.Multi == true
	e.Search = o.Search
	if e.Search == nil then e.Search = o.Searchable end
	e.Value = e.Multi and {} or nil
	local placeholder = o.Placeholder or (e.Multi and "None" or "Select…")

	function e._display()
		if e.Multi then
			local sel = e:Get()
			for i, v in ipairs(sel) do sel[i] = tostring(v) end
			txt.Text = #sel == 0 and Tr.Lookup(placeholder) or table.concat(sel, ", ")
		else
			txt.Text = e.Value ~= nil and tostring(e.Value) or Tr.Lookup(placeholder)
		end
	end
	function e:Get()
		if not e.Multi then return e.Value end
		local out, seen = {}, {}
		for _, v in ipairs(e.Options) do
			if e.Value[v] then table.insert(out, v); seen[v] = true end
		end
		for v in pairs(e.Value) do
			if not seen[v] then table.insert(out, v) end
		end
		return out
	end
	function e:Set(v, silent)
		if e.Multi then
			e.Value = {}
			for _, x in ipairs(type(v) == "table" and v or {}) do e.Value[x] = true end
		else
			e.Value = v
		end
		e._display()
		if not silent then U.safe(o.Callback, e:Get()) end
	end
	function e:Refresh(opts, keep)
		e.Options = table.clone(opts or {})
		if not keep then e.Value = e.Multi and {} or nil end
		e._display()
	end
	function e:Toggle(v) -- multi helper
		if not e.Multi then return e:Set(v) end
		e.Value[v] = (not e.Value[v]) or nil
		e._display()
		U.safe(o.Callback, e:Get())
	end
	function e:GetOptions() return table.clone(e.Options) end
	function e:IsOption(v) return table.find(e.Options, v) ~= nil end
	function e:AddOptions(list)
		for _, v in ipairs(type(list) == "table" and list or { list }) do
			if not table.find(e.Options, v) then table.insert(e.Options, v) end
		end
		e._display()
	end
	function e:RemoveOptions(list)
		for _, v in ipairs(type(list) == "table" and list or { list }) do
			local i = table.find(e.Options, v)
			if i then table.remove(e.Options, i) end
			if e.Multi then e.Value[v] = nil elseif e.Value == v then e.Value = nil end
		end
		e._display()
	end
	function e:ClearOptions()
		e.Options = {}
		e.Value = e.Multi and {} or nil
		e._display()
	end
	-- MacLib-style aliases
	e.InsertOptions = e.AddOptions
	e.UpdateSelection = e.Set
	U.onClick(btn, function() w:_DropdownPopup(e, ctrl) end)
	table.insert(Tr.Listeners, function()
		if not row.Parent then return "remove" end
		e._display()
	end)

	if e.Multi then e:Set(o.Default or {}, true) else e:Set(o.Default, true) end
	w:_Flag(o.Flag, e)
	return e
end

function Window:_DropdownPopup(e, anchor)
	local opts = e.Options
	-- Search = true always shows the search box, false never; by default only for long lists
	local searchable = e.Search == true or (e.Search == nil and #opts > 6)
	local top = searchable and 40 or 4
	local h = top + math.max(1, math.min(#opts, 7)) * 32 + 6
	local pop = self:_OpenPopup(anchor, math.max(anchor.AbsoluteSize.X, 170), h)
	local search
	if searchable then
		search = U.new("TextBox", {
			Parent = pop,
			BackgroundColor3 = T.Background,
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 0, 28),
			FontFace = F.Medium,
			TextSize = 12,
			TextColor3 = T.Text,
			PlaceholderColor3 = T.Faint,
			PlaceholderText = Tr.Lookup("Search…"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Text = "",
		})
		U.corner(search, 6)
		local sst = U.stroke(search, T.Border)
		U.pad(search, 0, 8, 0, 28)
		U.icon("search", search, 12, T.Muted, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -20, 0.5, 0) })
		search.Focused:Connect(function() sst.Color = T.Accent end)
		search.FocusLost:Connect(function() sst.Color = T.Border end)
	end
	local empty = U.text({
		Parent = pop,
		Text = Tr.Lookup("No results"),
		TextSize = 12,
		TextColor3 = T.Faint,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 0, 32),
		Visible = false,
	})
	local list = U.new("ScrollingFrame", {
		Parent = pop,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent,
	})
	U.pad(list, 2, 4, 4, 4)
	U.list(list, 2)
	local first
	local function build(filter)
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiButton") then c:Destroy() end
		end
		first = nil
		for i, v in ipairs(opts) do
			local s = tostring(v)
			if not filter or s:lower():find(filter, 1, true) then
				if first == nil then first = v end
				local sel = (e.Multi and e.Value[v]) or (not e.Multi and e.Value == v)
				local r = self:_PopupRow(list, s, sel, function()
					if e.Multi then
						e:Toggle(v)
						build(filter)
					else
						self:_ClosePopup()
						e:Set(v)
					end
				end)
				r.LayoutOrder = i
			end
		end
	end
	local function refresh()
		local q = search and search.Text:lower() or ""
		build(q ~= "" and q or nil)
		empty.Visible = first == nil
		list.CanvasPosition = Vector2.zero
	end
	refresh()
	if search then
		search:GetPropertyChangedSignal("Text"):Connect(refresh)
		-- Enter picks the first match
		search.FocusLost:Connect(function(enter)
			if not enter or first == nil or not search.Parent then return end
			if e.Multi then
				e:Toggle(first)
				refresh()
			else
				self:_ClosePopup()
				e:Set(first)
			end
		end)
		-- on PC the box is ready to type; on touch it waits for a tap (no surprise keyboard)
		if not Svc.UserInputService.TouchEnabled then
			task.defer(function() if search.Parent then search:CaptureFocus() end end)
		end
	end
end

-- Button ---------------------------------------------------------------------
function Container:Button(o: ButtonOptions)
	local row = self:_NewRow(o.Primary and 38 or 34)
	local primary = o.Primary == true
	local b = U.button({
		Parent = row,
		BackgroundColor3 = T.Accent,
		BackgroundTransparency = primary and 0 or 0.82,
		Size = UDim2.fromScale(1, 1),
		FontFace = primary and F.Bold or F.SemiBold,
		TextSize = primary and 13 or 12,
		TextColor3 = primary and T.White or T.Text,
	})
	U.corner(b, 9)
	U.stroke(b, primary and T.Glow or T.Accent, primary and 0.6 or 0.2)
	Tr.Register(b, o.Name or "Button")
	local scale = U.new("UIScale", { Parent = b })
	local idle = primary and 0 or 0.82
	U.hover(b, function()
		U.tween(b, 0.12, { BackgroundTransparency = primary and 0.12 or 0.7 })
	end, function()
		U.tween(b, 0.12, { BackgroundTransparency = idle })
	end)
	U.onClick(b, function()
		scale.Scale = 0.97
		U.tween(scale, 0.15, { Scale = 1 })
		U.safe(o.Callback)
	end)
	self.Window:_Index(self, o.Name, b, row)
	local e = element(row, o)
	function e:SetText(t) Tr.Register(b, t) end
	return e
end

-- Stepper (− value +) --------------------------------------------------------
function Container:Stepper(o: StepperOptions)
	local min, max = o.Min or -math.huge, o.Max or math.huge
	local step = o.Step or 1
	local decimals = step < 1 and #(tostring(step):match("%.(%d+)") or "") or 0
	local row, ctrl = U.inlineRow(self, o, SMALL_BTN * 2 + 60, SMALL_BTN + 4, false)
	local pill = U.new("Frame", { Parent = ctrl, BackgroundColor3 = T.Background, Size = UDim2.fromScale(1, 1) })
	U.round(pill)
	U.stroke(pill, T.Border)
	local function side(kind, anchorX, posX)
		local b = U.button({ Parent = pill, BackgroundColor3 = T.Elevated, BackgroundTransparency = 0, AnchorPoint = Vector2.new(anchorX, 0.5), Position = UDim2.new(posX, anchorX == 0 and 2 or -2, 0.5, 0), Size = UDim2.fromOffset(SMALL_BTN, SMALL_BTN) })
		U.round(b)
		U.icon(kind, b, 10, kind == "plus" and T.Glow or T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		return b
	end
	local minus = side("minus", 0, 0)
	local plus = side("plus", 1, 1)
	local box = U.new("TextBox", {
		Parent = pill,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SMALL_BTN + 4, 0),
		Size = UDim2.new(1, -(SMALL_BTN + 4) * 2, 1, 0),
		FontFace = F.Bold,
		TextSize = 13,
		TextColor3 = T.Text,
		ClearTextOnFocus = false,
		Text = "",
	})
	local e = element(row, o)
	local function fmt(v) return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(math.floor(v + 0.5)) end
	function e:Set(v, silent)
		v = math.clamp(tonumber(v) or e.Value or 0, min, max)
		v = tonumber(string.format("%.6f", v))
		local changed = v ~= e.Value
		e.Value = v
		box.Text = fmt(v)
		if changed and not silent then U.safe(o.Callback, v) end
	end
	function e:Get() return e.Value end
	U.onClick(minus, function() e:Set(e.Value - step) end)
	U.onClick(plus, function() e:Set(e.Value + step) end)
	box.FocusLost:Connect(function() e:Set(tonumber((box.Text:gsub("[^%d%.%-]", "")))); box.Text = fmt(e.Value) end)
	e:Set(o.Default or (min > -math.huge and min or 0), true)
	self.Window:_Flag(o.Flag, e)
	return e
end

-- Segmented (A | B | C) ------------------------------------------------------
function Container:Segmented(o: SegmentedOptions)
	local opts = o.Options or {}
	local n = math.max(#opts, 1)
	local cw = o.Width or math.clamp(n * 76, 120, 240)
	local row, ctrl = U.inlineRow(self, o, cw, 32, true)
	local bg = U.new("Frame", { Parent = ctrl, BackgroundColor3 = T.Background, Size = UDim2.fromScale(1, 1) })
	U.corner(bg, 9)
	U.stroke(bg, T.Border)
	local inner = U.new("Frame", { Parent = bg, BackgroundTransparency = 1, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6) })
	local pill = U.new("Frame", { Parent = inner, BackgroundColor3 = T.Accent, Size = UDim2.fromScale(1 / n, 1) })
	U.corner(pill, 7)
	U.stroke(pill, T.Glow, 0.65)
	local e = element(row, o)
	local labels = {}
	for i, opt in ipairs(opts) do
		local b = U.button({ Parent = inner, Position = UDim2.fromScale((i - 1) / n, 0), Size = UDim2.fromScale(1 / n, 1), ZIndex = 2, FontFace = F.Bold, TextSize = 12, TextColor3 = T.Muted })
		Tr.Register(b, tostring(opt))
		labels[i] = b
		U.onClick(b, function() e:Set(opt) end)
	end
	function e:Set(v, silent)
		local idx = table.find(opts, v) or 1
		e.Value = opts[idx]
		U.tween(pill, 0.2, { Position = UDim2.fromScale((idx - 1) / n, 0) })
		for i, b in ipairs(labels) do b.TextColor3 = i == idx and T.White or T.Muted end
		if not silent then U.safe(o.Callback, e.Value) end
	end
	function e:Get() return e.Value end
	e:Set(o.Default or opts[1], true)
	self.Window:_Flag(o.Flag, e)
	return e
end

-- Keybind --------------------------------------------------------------------
function Container:Keybind(o: KeybindOptions)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, o, 92, 30, false)
	local b = U.button({ Parent = ctrl, BackgroundColor3 = T.Background, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), FontFace = F.SemiBold, TextSize = 12, TextColor3 = T.Glow, TextTruncate = Enum.TextTruncate.AtEnd })
	U.corner(b, 8)
	local st = U.stroke(b, T.Border)
	local e = element(row, o)
	local listening = false
	function e:Set(v, silent)
		if type(v) == "string" then v = Enum.KeyCode[v] end
		e.Value = v
		local short = {
			LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift",
			LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp",
			PageUp = "PgUp", PageDown = "PgDn", Insert = "Ins", Delete = "Del",
		}
		b.Text = v and (short[v.Name] or v.Name) or "—"
		if not silent and o.Changed then U.safe(o.Changed, v) end
	end
	function e:Get() return e.Value and e.Value.Name or nil end
	U.onClick(b, function()
		listening = true
		b.Text = "…"
		st.Color = T.Accent
	end)
	w:_ConnectFor(row, Svc.UserInputService.InputBegan, function(i, gp)
		if listening and i.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			st.Color = T.Border
			e:Set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil)
			return
		end
		if not gp and e.Value and i.KeyCode == e.Value then U.safe(o.Callback) end
	end)
	e:Set(o.Default, true)
	w:_Flag(o.Flag, e)
	return e
end

-- Text elements --------------------------------------------------------------
function Container:Label(arg: string | LabelOptions)
	local o: LabelOptions = if type(arg) == "string" then { Text = arg } else arg
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local l = U.text({ Parent = row, TextSize = o.Size or 12, TextColor3 = o.Color or T.Muted, TextWrapped = true, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	Tr.Register(l, o.Text or "")
	local e = element(row, o)
	function e:Set(t) Tr.Register(l, t) end
	return e
end

function Container:Paragraph(o: ParagraphOptions)
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	U.list(row, 3)
	local t = U.text({ Parent = row, FontFace = F.SemiBold, TextWrapped = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
	Tr.Register(t, o.Title or "")
	local c = U.text({ Parent = row, TextSize = 12, TextColor3 = T.Muted, TextWrapped = true, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	Tr.Register(c, o.Content or "")
	self.Window:_Index(self, o.Title, t, row)
	local e = element(row, o)
	function e:Set(title, content)
		if title then Tr.Register(t, title) end
		if content then Tr.Register(c, content) end
	end
	return e
end

function Container:Value(o: ValueOptions)
	local row = self:_NewRow(20)
	local n = U.text({ Parent = row, TextSize = 12, TextColor3 = T.Muted, Size = UDim2.new(0.6, 0, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	Tr.Register(n, o.Name or "")
	local v = U.text({ Parent = row, FontFace = F.Bold, TextSize = 12, TextColor3 = T.Glow, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
	local e = element(row, o)
	function e:Set(x) v.Text = tostring(x) end
	e:Set(o.Value or "-")
	self.Window:_Index(self, o.Name, n, row)
	return e
end

function Container:Divider()
	local row = self:_NewRow(1)
	row.BackgroundTransparency = 0
	row.BackgroundColor3 = T.Border
	return element(row, {})
end

-- Card (title + image, e.g. unit preview) -----------------------------------
function Container:Card(o: CardOptions)
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local card = U.new("Frame", { Parent = row, BackgroundColor3 = T.Surface, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.corner(card, 10)
	U.stroke(card, T.Border)
	U.pad(card, 10)
	U.list(card, 8)
	local title = U.text({ Parent = card, FontFace = F.Bold, TextSize = 12, TextColor3 = T.Glow, Size = UDim2.new(1, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1 })
	local img = U.new("ImageLabel", { Parent = card, BackgroundColor3 = T.Elevated2, Size = UDim2.fromOffset(o.ImageSize or 52, o.ImageSize or 52), ScaleType = Enum.ScaleType.Fit, LayoutOrder = 2 })
	U.corner(img, 10)
	U.stroke(img, T.BorderHi)
	local e = element(row, o)
	function e:Set(t, image)
		if t ~= nil then title.Text = tostring(t) end
		if image ~= nil then img.Image = image end
		img.Visible = img.Image ~= ""
	end
	e:Set(o.Title or "", o.Image or "")
	return e
end

-- InfoBox (collapsible help text) -------------------------------------------
function Container:InfoBox(o: InfoBoxOptions)
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local box = U.new("Frame", { Parent = row, BackgroundColor3 = T.Surface, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.corner(box, 10)
	U.stroke(box, T.Border)
	U.list(box, 0)
	local head = U.button({ Parent = box, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1 })
	U.icon("info", head, 14, T.Glow, { Position = UDim2.new(0, 10, 0.5, -7) })
	local t = U.text({ Parent = head, FontFace = F.Bold, TextSize = 12, TextColor3 = T.Glow, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -64, 1, 0) })
	Tr.Register(t, o.Title or "Information")
	local body = U.new("Frame", { Parent = box, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	U.new("Frame", { Parent = body, BackgroundColor3 = T.Border, Size = UDim2.new(1, 0, 0, 1) })
	local p = U.text({ Parent = body, TextSize = 11, TextColor3 = T.Muted, TextWrapped = true, RichText = true, LineHeight = 1.15, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.pad(p, 10, 12, 12, 12)
	Tr.Register(p, o.Text or o.Content or "")
	local chev
	local function setOpen(v)
		body.Visible = v
		if chev then chev:Destroy() end
		chev = U.icon(v and "up" or "down", head, 12, T.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0) })
	end
	local open = o.Open ~= false
	setOpen(open)
	U.onClick(head, function()
		open = not open
		setOpen(open)
	end)
	self.Window:_Index(self, o.Title or "Information", t, row)
	local e = element(row, o)
	function e:Set(text) Tr.Register(p, text) end
	return e
end

-- Collapsible (sub-group with violet guide line) ------------------------------
function Container:Collapsible(o: CollapsibleOptions)
	local w = self.Window
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	U.list(row, 10)
	local head = U.button({ Parent = row, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1 })
	local name = U.text({ Parent = head, FontFace = F.SemiBold, Size = UDim2.new(1, -36, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	Tr.Register(name, o.Name or "")
	local tb = U.new("Frame", { Parent = head, BackgroundColor3 = T.Surface, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(26, 26) })
	U.corner(tb, 7)
	U.stroke(tb, T.Border)
	local body = U.new("Frame", { Parent = row, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	local line = U.new("Frame", { Parent = body, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.45, Size = UDim2.new(0, 2, 1, 0) })
	U.round(line)
	local inner = U.new("Frame", { Parent = body, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.list(inner, 10)

	local c = Container.new(w, self.Tab, inner, self)
	local chev
	function c.SetOpen(v)
		c.IsOpen = v
		body.Visible = v
		if chev then chev:Destroy() end
		chev = U.icon(v and "up" or "down", tb, 12, T.Glow, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		if v then task.defer(function() self.Tab:_Relayout() end) end
	end
	c.SetOpen(o.Open ~= false)
	U.onClick(head, function() c.SetOpen(not c.IsOpen) end)
	w:_Index(self, o.Name, name, row)
	c.Row = row
	return c
end

---------------------------------------------------------------------------
-- Window extras (ported from MacLib, made reversible)
---------------------------------------------------------------------------
function Window:SetScale(scale)
	self.UserScale = math.clamp(tonumber(scale) or 1, 0.5, 1.5)
	self.Settings.Scale = self.UserScale
	self:_SaveSettings()
	self.Scale.Scale = self.UserScale
	self:_Layout()
	task.defer(function() self:_RelayoutAll() end)
end
function Window:GetScale() return self.UserScale end

function Window:SetSize(size)
	if typeof(size) == "UDim2" then size = Vector2.new(size.X.Offset, size.Y.Offset) end
	if typeof(size) ~= "Vector2" then return end
	self.Desired = size
	self:_Layout()
end
function Window:GetSize() return self.Desired end

function Window:SetTitle(t)
	self.Title = t
	self.TitleLabel.Text = tostring(t)
end
function Window:SetSubtitle(t)
	self.Subtitle = t
	self.SubtitleLabel.Text = tostring(t)
end
Window.UpdateTitle = Window.SetTitle
Window.UpdateSubtitle = Window.SetSubtitle

function Window:SetNotificationsState(on)
	self.NotificationsEnabled = on ~= false
	self.Settings.Notifications = self.NotificationsEnabled
	self:_SaveSettings()
	self.NotifyHolder.Visible = self.NotificationsEnabled
end
function Window:GetNotificationsState() return self.NotificationsEnabled end

-- hides avatar + names on the profile card (the eye button does the same)
function Window:SetUserInfoHidden(hidden)
	self.ProfileHidden = hidden == true
	self.Settings.HideUserInfo = self.ProfileHidden
	self:_SaveSettings()
	if self._applyProfile then self._applyProfile() end
	if self._profileToggle then self._profileToggle:Set(self.ProfileHidden, true) end
end
function Window:SetUserInfoState(shown) self:SetUserInfoHidden(not shown) end
function Window:GetUserInfoState() return not self.ProfileHidden end

function Window:OnUnload(fn)
	if type(fn) == "function" then table.insert(self._unload, fn) end
end
Window.Unload = Window.Destroy

-- Low CPU: stops 3D rendering and covers the game with a black screen (UI stays on top)
function Window:SetLowCpu(on)
	on = on == true
	if on == (self._black ~= nil) then return end
	pcall(function() Svc.RunService:Set3dRenderingEnabled(not on) end)
	if on then
		local g = U.new("ScreenGui", { Name = "NebulaBlackScreen", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998 })
		pcall(function() g.ScreenInsets = Enum.ScreenInsets.None end)
		local f = U.new("Frame", { Parent = g, BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1) })
		local l = U.text({ Parent = f, FontFace = F.SemiBold, TextSize = 14, TextColor3 = T.Faint, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 20), TextXAlignment = Enum.TextXAlignment.Center })
		Tr.Register(l, "Low CPU mode — rendering paused")
		if pcall(U.guiParent, g) then self._black = g else g:Destroy() end
	elseif self._black then
		self._black:Destroy()
		self._black = nil
	end
	if self._lowCpuToggle then self._lowCpuToggle:Set(on, true) end
end
Window.SetBlackScreen = Window.SetLowCpu

-- FPS Boost: low quality, no shadows/effects, plain materials, hidden textures. Turning it off restores everything.
function Window:SetFPSBoost(on)
	on = on == true
	if on == (self._fps ~= nil) then return end
	if on then
		local saved = { props = {} }
		self._fps = saved
		local function keep(inst, prop, value)
			saved.props[inst] = saved.props[inst] or {}
			if saved.props[inst][prop] == nil then saved.props[inst][prop] = inst[prop] end
			inst[prop] = value
		end
		task.spawn(function()
			pcall(function()
				saved.quality = settings().Rendering.QualityLevel
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			pcall(keep, Svc.Lighting, "GlobalShadows", false)
			for _, x in ipairs(Svc.Lighting:GetDescendants()) do
				if x:IsA("PostEffect") and x.Enabled then pcall(keep, x, "Enabled", false) end
			end
			for n, d in ipairs(workspace:GetDescendants()) do
				if self._fps ~= saved then return end
				if d:IsA("Texture") or d:IsA("Decal") then
					if d.Transparency < 1 then pcall(keep, d, "Transparency", 1) end
				elseif d:IsA("BasePart") then
					if d.Material ~= Enum.Material.SmoothPlastic then pcall(keep, d, "Material", Enum.Material.SmoothPlastic) end
					if d.CastShadow then pcall(keep, d, "CastShadow", false) end
				elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
					if d.Enabled then pcall(keep, d, "Enabled", false) end
				end
				if n % 2500 == 0 then task.wait() end
			end
		end)
	else
		local saved = self._fps
		self._fps = nil
		pcall(function()
			if saved.quality then settings().Rendering.QualityLevel = saved.quality end
		end)
		task.spawn(function()
			local n = 0
			for inst, props in pairs(saved.props) do
				for prop, value in pairs(props) do pcall(function() inst[prop] = value end) end
				n += 1
				if n % 2500 == 0 then task.wait() end
			end
		end)
	end
	if self._fpsToggle then self._fpsToggle:Set(on, true) end
end
Window.FPSBoost = Window.SetFPSBoost

-- Hide player: hides your name tags, face, accessories and clothes locally (for recording). Reversible.
function Window:SetHidePlayer(on)
	on = on == true
	if on == (self._hidePlayer ~= nil) then return end
	local lp = Svc.Players.LocalPlayer
	if on then
		local st = { saved = {} }
		self._hidePlayer = st
		local function keep(inst, prop, value)
			if st.saved[inst] == nil then st.saved[inst] = { prop, inst[prop] } end
			inst[prop] = value
		end
		local function apply(char)
			if not char or self._hidePlayer ~= st then return end
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
					pcall(keep, d, "Enabled", false)
				elseif d:IsA("Decal") then
					pcall(keep, d, "Transparency", 1)
				elseif d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
					pcall(keep, d, "Parent", nil)
				end
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(keep, hum, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None) end
		end
		apply(lp and lp.Character)
		if lp then
			st.conn = lp.CharacterAdded:Connect(function(c)
				task.wait(1)
				apply(c)
			end)
		end
	else
		local st = self._hidePlayer
		self._hidePlayer = nil
		if st.conn then st.conn:Disconnect() end
		for inst, rec in pairs(st.saved) do
			pcall(function() inst[rec[1]] = rec[2] end)
		end
	end
	if self._hidePlayerToggle then self._hidePlayerToggle:Set(on, true) end
end
Window.HidePlayer = Window.SetHidePlayer

-- Global settings: quick switches behind the sliders button in the top bar
function Window:GlobalSetting(o: GlobalSettingOptions)
	local g = { Name = o.Name or "Setting", Value = o.Default == true }
	function g:Set(v, silent)
		g.Value = v == true
		if g._render then g._render() end
		if not silent then U.safe(o.Callback, g.Value) end
	end
	function g:Get() return g.Value end
	function g:UpdateState(v) g:Set(v, true) end
	function g:UpdateName(n) g.Name = n end
	table.insert(self._globals, g)
	self:_LayoutHeader()
	return g
end

function Window:_GlobalPopup()
	local list = self._globals
	local pop = self:_OpenPopup(self.GearBtn, 240, #list * 38 + 10)
	U.pad(pop, 5)
	U.list(pop, 2)
	for i, g in ipairs(list) do
		local b = U.button({ Parent = pop, BackgroundColor3 = T.Accent, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = i })
		U.corner(b, 7)
		local l = U.text({ Parent = b, FontFace = F.Medium, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		Tr.Register(l, g.Name)
		local track = U.new("Frame", { Parent = b, BackgroundColor3 = T.Border, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 16) })
		U.round(track)
		local knob = U.new("Frame", { Parent = track, BackgroundColor3 = T.Muted, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(12, 12) })
		U.round(knob)
		g._render = function()
			if not b.Parent then g._render = nil return end
			U.tween(track, 0.15, { BackgroundColor3 = g.Value and T.Accent or T.Border })
			U.tween(knob, 0.15, { Position = g.Value and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = g.Value and T.White or T.Muted })
			l.TextColor3 = g.Value and T.Text or T.Muted
		end
		knob.Position = g.Value and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		g._render()
		U.hover(b, function() b.BackgroundTransparency = 0.92 end, function() b.BackgroundTransparency = 1 end)
		U.onClick(b, function() g:Set(not g.Value) end)
	end
end

-- Ready-made "Interface" section with every extra
function Window:SettingsSection(tab, sectionName)
	local s = tab:Section({ Name = sectionName or "Interface" })
	s:Slider({ Name = "UI size", Min = 0.5, Max = 1.5, Step = 0.05, Default = self.UserScale, Suffix = "x", Callback = function(v) self:SetScale(v) end })
	s:Keybind({ Name = "Toggle UI key", Default = self.Keybind, Changed = function(k) if k then self:SetKeybind(k) end end })
	s:Toggle({ Name = "Notifications", Default = self.NotificationsEnabled, Callback = function(v) self:SetNotificationsState(v) end })
	self._profileToggle = s:Toggle({ Name = "Hide my profile", Description = "Hides your avatar and name on the side panel", Default = self.ProfileHidden, Callback = function(v) self:SetUserInfoHidden(v) end })
	s:Divider()
	self._lowCpuToggle = s:Toggle({ Name = "Low CPU (black screen)", Description = "Stops 3D rendering. The interface stays visible.", Callback = function(v) self:SetLowCpu(v) end })
	self._fpsToggle = s:Toggle({ Name = "FPS Boost", Description = "Lower graphics. Turning it off restores them.", Callback = function(v) self:SetFPSBoost(v) end })
	self._hidePlayerToggle = s:Toggle({ Name = "Hide my character", Description = "Hides your name tag, face, clothes and accessories (only for you)", Callback = function(v) self:SetHidePlayer(v) end })
	s:Divider()
	s:Button({ Name = "Reset window size", Callback = function() self:ResetSize() end })
	s:Button({ Name = "Hide interface", Callback = function() self:SetVisible(false) end })
	s:Button({ Name = "Close interface", Callback = function() self:Close() end })
	return s
end

---------------------------------------------------------------------------
-- More elements: Header, SubLabel, Spacer, Colorpicker
---------------------------------------------------------------------------
function Container:Header(arg: string | HeaderOptions)
	local o: HeaderOptions = if type(arg) == "string" then { Name = arg } else arg
	-- bigger, with breathing room above (except when it's the first thing in the section)
	local first = self._n == 0
	local row = self:_NewRow(first and 22 or 32)
	local l = U.text({ Parent = row, Name = "Title", FontFace = F.Bold, TextSize = 16, TextColor3 = T.Text, TextYAlignment = Enum.TextYAlignment.Bottom, Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(14, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	local mark = U.new("Frame", { Parent = row, BackgroundColor3 = T.Accent, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -3), Size = UDim2.fromOffset(4, 14) })
	U.round(mark)
	Tr.Register(l, o.Name or o.Text or "")
	self.Window:_Index(self, o.Name or o.Text, l, row)
	local e = element(row, o)
	e.Set = e.SetName
	return e
end

function Container:SubLabel(arg: string | LabelOptions)
	local src: LabelOptions = if type(arg) == "string" then { Text = arg } else arg
	return self:Label({ Text = src.Text, Size = src.Size or 11, Color = src.Color or T.Faint })
end

function Container:Spacer(h: number?)
	return element(self:_NewRow(type(h) == "number" and h or 6), {})
end

function Container:Colorpicker(o: ColorpickerOptions)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, o, 52, 26, false)
	local swatch = U.button({ Parent = ctrl, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1) })
	U.corner(swatch, 7)
	U.stroke(swatch, T.BorderHi, 0, 1.5)
	local e = element(row, o)
	local h, s, v = 0, 0, 1
	local function current() return Color3.fromHSV(h, s, v) end

	function e:Set(c, silent)
		if type(c) == "string" then
			local ok, parsed = pcall(Color3.fromHex, c)
			c = ok and parsed or nil
		end
		if typeof(c) ~= "Color3" then return end
		h, s, v = c:ToHSV()
		e.Value = c
		swatch.BackgroundColor3 = c
		if e._sync then e._sync() end
		if not silent then U.safe(o.Callback, c) end
	end
	function e:Get() return "#" .. e.Value:ToHex() end -- hex string so configs can save it
	function e:GetColor() return e.Value end
	e.SetColor = e.Set

	local function open()
		local pop = w:_OpenPopup(ctrl, 236, 200)
		local sv = U.button({ Parent = pop, BackgroundColor3 = Color3.fromHSV(h, 1, 1), BackgroundTransparency = 0, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 120) })
		U.corner(sv, 8)
		local white = U.new("Frame", { Parent = sv, BackgroundColor3 = T.White, Size = UDim2.fromScale(1, 1) })
		U.corner(white, 8)
		U.new("UIGradient", { Parent = white, Transparency = NumberSequence.new(0, 1) })
		local black = U.new("Frame", { Parent = sv, BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1) })
		U.corner(black, 8)
		U.new("UIGradient", { Parent = black, Rotation = 90, Transparency = NumberSequence.new(1, 0) })
		local svKnob = U.new("Frame", { Parent = sv, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), ZIndex = 3 })
		U.round(svKnob)
		U.stroke(svKnob, T.White, 0, 2)

		local hue = U.button({ Parent = pop, BackgroundColor3 = T.White, BackgroundTransparency = 0, Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 12) })
		U.round(hue)
		local keys = {}
		for i = 0, 6 do table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1))) end
		U.new("UIGradient", { Parent = hue, Color = ColorSequence.new(keys) })
		local hueKnob = U.new("Frame", { Parent = hue, BackgroundColor3 = T.White, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 18) })
		U.corner(hueKnob, 3)
		U.stroke(hueKnob, T.Background, 0, 1)

		local hex = U.new("TextBox", {
			Parent = pop,
			BackgroundColor3 = T.Background,
			Position = UDim2.fromOffset(10, 162),
			Size = UDim2.new(1, -20, 0, 28),
			FontFace = F.SemiBold,
			TextSize = 12,
			TextColor3 = T.Text,
			ClearTextOnFocus = false,
			Text = "",
		})
		U.corner(hex, 7)
		U.stroke(hex, T.Border)

		local function sync()
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svKnob.Position = UDim2.fromScale(s, 1 - v)
			hueKnob.Position = UDim2.fromScale(h, 0.5)
			if not hex:IsFocused() then hex.Text = "#" .. current():ToHex():upper() end
		end
		e._sync = sync
		sync()

		local mode, active
		local inset = Svc.GuiService:GetGuiInset()
		local function update(p)
			local pos = Vector2.new(p.X, p.Y + inset.Y) -- input Y excludes the top bar; GUI Y doesn't
			if mode == "sv" then
				local rel = pos - sv.AbsolutePosition
				s = math.clamp(rel.X / sv.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp(rel.Y / sv.AbsoluteSize.Y, 0, 1)
			else
				h = math.clamp((pos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
			end
			e.Value = current()
			swatch.BackgroundColor3 = e.Value
			sync()
			U.safe(o.Callback, e.Value)
		end
		local function begin(m)
			return function(i)
				if not U.isPress(i) then return end
				mode, active = m, i
				update(i.Position)
			end
		end
		sv.InputBegan:Connect(begin("sv"))
		hue.InputBegan:Connect(begin("hue"))
		local c1 = Svc.UserInputService.InputChanged:Connect(function(i)
			if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i == active) then update(i.Position) end
		end)
		local c2 = Svc.UserInputService.InputEnded:Connect(function(i)
			if active and (i == active or i.UserInputType == Enum.UserInputType.MouseButton1) then active = nil end
		end)
		hex.FocusLost:Connect(function()
			local t = hex.Text:gsub("[^%x]", "")
			if #t == 6 then e:Set("#" .. t) else sync() end
		end)
		pop.Destroying:Connect(function()
			c1:Disconnect()
			c2:Disconnect()
			e._sync = nil
		end)
	end
	U.onClick(swatch, open)
	e:Set(o.Default or T.Accent, true)
	w:_Flag(o.Flag, e)
	return e
end

---------------------------------------------------------------------------
-- Side panel (opened by a gear): extra options to the right of the window
---------------------------------------------------------------------------
local PANEL_W = 290

function Window:_MenuCover(on)
	self._menuOpen = on
	self.Gui.Enabled = not on
	if self._black then self._black.Enabled = not on end
end

function Window:ResetSize()
	self.Desired = self.DefaultSize
	self.Offset = Vector2.new(0, 0)
	self:_Layout()
	task.defer(function() self:_RelayoutAll() end)
end

-- small gear button; clicking toggles the side panel built by o.Build(panel)
function U.gearButton(w, parent, o)
	local b = U.button({ Parent = parent, Name = "Gear", BackgroundColor3 = T.Surface, BackgroundTransparency = 0, Size = UDim2.fromOffset(28, 28), ZIndex = 2 })
	U.corner(b, 8)
	local st = U.stroke(b, T.Border)
	local ic = U.icon("gear", b, 14, T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local key = {}
	local function paint(open)
		st.Color = open and T.Accent or T.Border
		U.iconColor(ic, open and T.Glow or T.Muted)
	end
	U.hover(b, function() U.iconColor(ic, T.Glow) end, function()
		paint(w._openPanel ~= nil and w._openPanel.Key == key)
	end)
	local function toggle()
		if w._openPanel and w._openPanel.Key == key then
			w:ClosePanel()
		else
			w:OpenPanel({ Key = key, Title = o.Title, Build = o.Build, OnState = paint })
		end
	end
	U.onClick(b, toggle)
	return b, toggle, key
end

function Window:_BuildPanel(o)
	local frame = U.new("Frame", { Name = "SidePanel", BackgroundColor3 = T.Surface, ClipsDescendants = true, Visible = false, ZIndex = 5, Active = true })
	U.corner(frame, 14)
	U.stroke(frame, T.BorderHi)
	local head = U.new("Frame", { Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48) })
	U.new("Frame", { Parent = head, BackgroundColor3 = T.Border, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1) })
	U.icon("gear", head, 16, T.Glow, { Position = UDim2.new(0, 14, 0.5, -8) })
	local title = U.text({ Parent = head, FontFace = F.Bold, TextSize = 14, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -84, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	Tr.Register(title, o.Title or "Settings")
	local close = U.button({ Parent = head, BackgroundColor3 = T.Elevated, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 30) })
	U.corner(close, 8)
	local cic = U.icon("close", close, 12, T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	U.hover(close, function() close.BackgroundTransparency = 0; U.iconColor(cic, T.Text) end, function() close.BackgroundTransparency = 1; U.iconColor(cic, T.Muted) end)
	U.onClick(close, function() self:ClosePanel() end)

	local scroll = U.new("ScrollingFrame", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -60),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent,
	})
	U.new("UIPadding", { Parent = scroll, PaddingBottom = UDim.new(0, 14) })
	local inner = U.new("Frame", { Parent = scroll, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.list(inner, 12)

	-- a light tab so every element (relayout, sliders, collapsibles) works unchanged
	local ptab = setmetatable({ Window = self, Name = o.Title, Page = scroll, Sections = {}, _relayouts = {}, NoIndex = true }, Tab)
	local c = Container.new(self, ptab, inner, nil)
	local p = { Key = o.Key, Frame = frame, Container = c, Tab = ptab, Title = title, OnState = o.OnState }
	if type(o.Build) == "function" then
		local ok, err = pcall(o.Build, c, p)
		if not ok then warn("[NebulaGui] panel build error: " .. tostring(err)) end
	end
	return p
end

function Window:_PlacePanel(p)
	local us = self:_S()
	local f = p.Frame
	local screenW = self.Gui.AbsoluteSize.X
	local holderRight = self.Holder.AbsolutePosition.X + self.Holder.AbsoluteSize.X
	local fitsOutside = not self.Compact and (screenW - holderRight) >= (PANEL_W + 14) * us
	if fitsOutside then
		f.Parent = self.Holder
		f.AnchorPoint = Vector2.new(0, 0)
		f.Position = UDim2.new(1, 10, 0, 0)
		f.Size = UDim2.new(0, PANEL_W, 1, 0)
	else
		-- not enough room: dock inside the window, on the right, over the content
		f.Parent = self.Main
		f.AnchorPoint = Vector2.new(1, 0)
		f.Position = UDim2.new(1, -8, 0, HEADER_H + 8)
		f.Size = UDim2.new(0, math.min(PANEL_W, (self.Size or self.Desired).X - 16), 1, -HEADER_H - 16)
	end
	p.Inside = not fitsOutside
	return f.Position
end

-- Window:OpenPanel({ Title, Build = function(panel) panel:Toggle(...) end })
function Window:OpenPanel(o: PanelOptions)
	self._panels = self._panels or {}
	local key = o.Key or o
	local p = self._panels[key]
	if not p then
		o.Key = key
		p = self:_BuildPanel(o)
		self._panels[key] = p
	end
	if self._openPanel == p then return p end
	self:ClosePanel()
	self:_ClosePopup()
	self._openPanel = p
	local target = self:_PlacePanel(p)
	p.Frame.Position = target + UDim2.fromOffset(p.Inside and 24 or -16, 0)
	p.Frame.Visible = true
	U.tween(p.Frame, 0.22, { Position = target }, Enum.EasingStyle.Quint)
	if p.OnState then p.OnState(true) end
	task.defer(function() p.Tab:_Relayout() end)
	return p
end

function Window:ClosePanel()
	local p = self._openPanel
	if not p then return end
	self._openPanel = nil
	self:_ClosePopup()
	p.Frame.Visible = false
	if p.OnState then p.OnState(false) end
end

-- New option type: a row with a gear that opens the side panel
-- Container:Gear({ Name, Description?, Title?, Build = function(panel) ... end })
function Container:Gear(o: GearOptions)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, { Name = o.Name, Description = o.Description }, 28, 28, false)
	local b, toggle, key = U.gearButton(w, ctrl, { Title = o.Title or o.Name, Build = o.Build or o.Settings })
	b.Size = UDim2.fromScale(1, 1)
	local hit = U.button({ Parent = row, Size = UDim2.fromScale(1, 1), ZIndex = 0 })
	U.onClick(hit, toggle)
	local e = element(row, o)
	function e:Open() if not (w._openPanel and w._openPanel.Key == key) then toggle() end end
	function e:Close() if w._openPanel and w._openPanel.Key == key then w:ClosePanel() end end
	return e
end

-- ReorderList (numbered steps: drag by the grip, ↑ ↓, remove) -----------------
-- Rows are placed by hand (no UIListLayout) so every move can be animated:
-- the grabbed row lifts and follows the pointer, the others slide out of the way,
-- and on release it snaps into its slot with a small bounce.
function Container:ReorderList(o: ReorderListOptions)
	local w = self.Window
	local ROW, GAP = TOUCH and 44 or 40, 6
	local A = TOUCH and 28 or 22 -- arrow button size
	local STEP = ROW + GAP

	-- list-wide options (each item can override Removable / Locked)
	local removableDefault = o.Removable ~= false
	local reorderable = o.Reorderable ~= false
	local showGrip = reorderable and o.Draggable ~= false
	local showArrows = reorderable and o.Arrows ~= false
	local numbered = o.Numbered ~= false
	local removeText = o.RemoveText or "Remove"

	local row = self:_NewRow(0)
	local list = U.new("Frame", { Parent = row, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0) })
	local empty = U.text({ Parent = row, TextSize = 12, TextColor3 = T.Faint, Size = UDim2.new(1, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
	Tr.Register(empty, o.EmptyText or "Nothing here yet")
	local e = element(row, o)
	e.Items = {}
	local rows = {}
	local drag
	local narrow = false

	-- an item is either a plain value or a table { Text, Description?, Removable?, Locked?, Badge?, Color? }
	local function isRich(v) return type(v) == "table" and (v.Text ~= nil or v.Value ~= nil) end
	local function textOf(v, i)
		if o.Format then
			local ok, t = pcall(o.Format, v, i)
			if ok and t ~= nil then return tostring(t) end
		end
		if isRich(v) then return tostring(v.Text or v.Value) end
		return tostring(v)
	end
	local function removable(r)
		if isRich(r.value) and r.value.Removable ~= nil then return r.value.Removable == true end
		return removableDefault
	end
	-- locked = pinned: it can't move, and nothing can jump over it
	local function locked(r)
		return not reorderable or (isRich(r.value) and r.value.Locked == true)
	end
	local function pathFree(from, to)
		local a, b = math.min(from, to), math.max(from, to)
		for k = a, b do
			if k ~= from and locked(rows[k]) then return false end
		end
		return true
	end

	local function totalH()
		return #rows > 0 and (#rows * STEP - GAP) or 0
	end

	local function paint(r, i)
		local lit = e.Active == i or (drag and drag.r == r)
		local custom = isRich(r.value) and r.value.Color
		r.label.Text = textOf(r.value, i)
		if r.num then
			r.num.Text = (isRich(r.value) and r.value.Badge) and tostring(r.value.Badge) or tostring(i)
			U.tween(r.badge, 0.15, { BackgroundColor3 = lit and T.Accent or (custom or T.Elevated2) })
			r.num.TextColor3 = (lit or custom) and T.White or T.Glow
		end
		r.stroke.Color = lit and T.Accent or T.Border
	end

	local function layout(instant)
		for i, r in ipairs(rows) do
			paint(r, i)
			if not (drag and drag.r == r) then
				local target = UDim2.fromOffset(0, (i - 1) * STEP)
				if instant then
					r.frame.Position = target
				else
					U.tween(r.frame, 0.24, { Position = target }, Enum.EasingStyle.Quint)
				end
			end
		end
		local h = totalH()
		empty.Visible = #rows == 0 and o.EmptyText ~= false
		list.Size = UDim2.new(1, 0, 0, h)
		row.Size = UDim2.new(1, 0, 0, (#rows == 0 and empty.Visible) and 36 or h)
	end

	local function changed()
		e.Items = {}
		for i, r in ipairs(rows) do e.Items[i] = r.value end
		layout(false)
		U.safe(o.Callback, table.clone(e.Items))
	end

	local function moveTo(r, j)
		local i = table.find(rows, r)
		if not i or not j or j < 1 or j > #rows or i == j then return false end
		if locked(r) or not pathFree(i, j) then return false end
		table.remove(rows, i)
		table.insert(rows, j, r)
		U.safe(o.OnMove, r.value, i, j)
		changed()
		return true
	end

	-- horizontal layout of one row depends on what it shows
	local function arrange(r)
		local left = 8
		if r.grip then left = 28 end
		if r.badge then
			r.badge.Position = UDim2.new(0, left, 0.5, -11)
			left += 30
		end
		local right = 6
		if r.arrows then right += A * 2 + 8 end
		if r.rm then
			local rw = narrow and A or math.max(70, U.measure(r.rmText.Text, 11).X + 20)
			r.rm.Size = UDim2.fromOffset(rw, A)
			r.rm.Position = UDim2.new(1, -right, 0.5, 0)
			r.rmText.Visible = not narrow
			r.rmIcon.Visible = narrow
			right += rw + 6
		end
		local hasDesc = r.desc ~= nil
		r.label.Position = UDim2.fromOffset(left, hasDesc and 5 or 0)
		r.label.Size = UDim2.new(1, -left - right, hasDesc and 0 or 1, hasDesc and 16 or 0)
		if r.desc then
			r.desc.Position = UDim2.fromOffset(left, 21)
			r.desc.Size = UDim2.new(1, -left - right, 0, 14)
		end
	end

	local function small(parent, kind, x)
		local b = U.button({ Parent = parent, BackgroundColor3 = T.Elevated2, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(A, A) })
		U.corner(b, 6)
		local ic = U.icon(kind, b, 11, T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		U.hover(b, function()
			U.tween(b, 0.12, { BackgroundTransparency = 0.2 })
			U.iconColor(ic, T.Glow)
		end, function()
			U.tween(b, 0.12, { BackgroundTransparency = 1 })
			U.iconColor(ic, T.Muted)
		end)
		return b
	end

	local function lift(r, on)
		U.tween(r.scale, on and 0.18 or 0.35, { Scale = on and 1.035 or 1 }, on and Enum.EasingStyle.Quart or Enum.EasingStyle.Back)
		U.tween(r.frame, 0.18, { BackgroundColor3 = on and T.Elevated2 or T.Surface })
		U.tween(r.stroke, 0.18, { Thickness = on and 1.6 or 1 })
		r.frame.ZIndex = on and 3 or 1
		if r.gripIcon then U.iconColor(r.gripIcon, on and T.Glow or T.Faint) end
	end

	local function removeRow(r)
		local i = table.find(rows, r)
		if not i or r.removing then return end
		r.removing = true
		table.remove(rows, i)
		if e.Active and e.Active > #rows then e.Active = nil end
		local fr = r.frame
		U.tween(r.scale, 0.18, { Scale = 0.85 })
		U.tween(fr, 0.18, { BackgroundTransparency = 1 })
		U.tween(r.stroke, 0.18, { Transparency = 1 })
		for _, d in ipairs(fr:GetDescendants()) do
			if d:IsA("GuiObject") then d.Visible = false end
		end
		task.delay(0.18, function() fr:Destroy() end)
		U.safe(o.OnRemove, r.value, i)
		changed()
	end

	local function makeRow(value, index)
		local fr = U.new("Frame", {
			Parent = list,
			BackgroundColor3 = T.Surface,
			Position = UDim2.fromOffset(0, (index - 1) * STEP),
			Size = UDim2.new(1, 0, 0, ROW),
		})
		U.corner(fr, 9)
		local r = { frame = fr, value = value, stroke = U.stroke(fr, T.Border), scale = U.new("UIScale", { Parent = fr }) }
		local pinned = locked(r)

		if o.OnClick then
			local hit = U.button({ Parent = fr, Size = UDim2.fromScale(1, 1), ZIndex = 0 })
			U.onClick(hit, function()
				local i = table.find(rows, r)
				if i then U.safe(o.OnClick, r.value, i) end
			end)
		end

		if showGrip and not pinned then
			r.grip = U.button({ Parent = fr, Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0, 24, 1, 0) })
			r.gripIcon = U.icon("grip", r.grip, 12, T.Faint, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
			U.hover(r.grip, function()
				if not drag then U.iconColor(r.gripIcon, T.Glow) end
			end, function()
				if not drag then U.iconColor(r.gripIcon, T.Faint) end
			end)
			r.grip.InputBegan:Connect(function(i)
				if not U.isPress(i) or drag then return end
				local from = table.find(rows, r)
				drag = { r = r, input = i, y = i.Position.Y, base = (from - 1) * STEP, from = from }
				self.Tab.Page.ScrollingEnabled = false
				lift(r, true)
				layout(false)
			end)
		end

		if numbered then
			r.badge = U.new("Frame", { Parent = fr, BackgroundColor3 = T.Elevated2, Size = UDim2.fromOffset(22, 22) })
			U.corner(r.badge, 6)
			r.num = U.text({ Parent = r.badge, FontFace = F.Bold, TextSize = 11, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		end
		r.label = U.text({ Parent = fr, FontFace = F.SemiBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd })
		if isRich(value) and value.Description then
			r.desc = U.text({ Parent = fr, Text = tostring(value.Description), TextSize = 10, TextColor3 = T.Muted, TextTruncate = Enum.TextTruncate.AtEnd })
		end

		if showArrows and not pinned then
			r.arrows = true
			U.onClick(small(fr, "up", -(6 + A + 4)), function()
				local i = table.find(rows, r)
				if i then moveTo(r, i - 1) end
			end)
			U.onClick(small(fr, "down", -6), function()
				local i = table.find(rows, r)
				if i then moveTo(r, i + 1) end
			end)
		elseif showArrows then
			r.arrows = true -- keep the same column width so pinned rows line up with the rest
		end

		if removable(r) then
			r.rm = U.button({ Parent = fr, BackgroundColor3 = T.Danger, BackgroundTransparency = 0.85, AnchorPoint = Vector2.new(1, 0.5) })
			U.corner(r.rm, 6)
			r.rmText = U.text({ Parent = r.rm, FontFace = F.Bold, TextSize = 11, TextColor3 = T.DangerText, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
			Tr.Register(r.rmText, removeText)
			r.rmIcon = U.icon("close", r.rm, 9, T.DangerText, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
			U.hover(r.rm, function() U.tween(r.rm, 0.12, { BackgroundTransparency = 0.7 }) end, function() U.tween(r.rm, 0.12, { BackgroundTransparency = 0.85 }) end)
			U.onClick(r.rm, function()
				if o.ConfirmRemove then
					w:Dialog({
						Title = "Remove this item?",
						Content = textOf(r.value, table.find(rows, r) or 0),
						Buttons = { { Name = "Cancel" }, { Name = removeText, Primary = true, Callback = function() removeRow(r) end } },
					})
				else
					removeRow(r)
				end
			end)
		end
		arrange(r)
		return r
	end

	w:_ConnectFor(row, Svc.UserInputService.InputChanged, function(i)
		if not drag then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i ~= drag.input then return end
		local y = math.clamp(drag.base + (i.Position.Y - drag.y) / w:_S(), -10, totalH() - ROW + 10)
		drag.r.frame.Position = UDim2.fromOffset(0, y)
		local target = math.clamp(math.floor(y / STEP + 0.5) + 1, 1, #rows)
		local cur = table.find(rows, drag.r)
		if cur and target ~= cur and pathFree(cur, target) then
			table.remove(rows, cur)
			table.insert(rows, target, drag.r)
			layout(false)
		end
	end)
	w:_ConnectFor(row, Svc.UserInputService.InputEnded, function(i)
		if not drag or not (i == drag.input or i.UserInputType == Enum.UserInputType.MouseButton1) then return end
		local r, from = drag.r, drag.from
		drag = nil
		self.Tab.Page.ScrollingEnabled = true
		lift(r, false)
		local idx = table.find(rows, r) or 1
		U.tween(r.frame, 0.35, { Position = UDim2.fromOffset(0, (idx - 1) * STEP) }, Enum.EasingStyle.Back)
		if idx ~= from then U.safe(o.OnMove, r.value, from, idx) end
		changed()
	end)

	w:_Watch(self, row, function(W)
		local n = W < 330
		if n == narrow then return end
		narrow = n
		for _, r in ipairs(rows) do arrange(r) end
	end)

	function e:Set(items, silent)
		for _, r in ipairs(rows) do r.frame:Destroy() end
		rows = {}
		drag = nil
		items = type(items) == "table" and items or {}
		for i, v in ipairs(items) do table.insert(rows, makeRow(v, i)) end
		e.Items = table.clone(items)
		layout(true)
		if not silent then U.safe(o.Callback, table.clone(e.Items)) end
	end
	function e:Get() return table.clone(e.Items) end
	function e:Count() return #rows end
	function e:Add(v, at)
		if o.MaxItems and #rows >= o.MaxItems then return false end
		local pos = math.clamp(at or (#rows + 1), 1, #rows + 1)
		local r = makeRow(v, pos)
		table.insert(rows, pos, r)
		r.scale.Scale = 0.9
		U.tween(r.scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		changed()
		return true
	end
	function e:Remove(index)
		local r = rows[index]
		if r then removeRow(r) end
	end
	function e:Update(index, v)
		local r = rows[index]
		if not r then return end
		r.value = v
		r.frame:Destroy()
		rows[index] = makeRow(v, index)
		changed()
	end
	function e:Move(from, to)
		local r = rows[from]
		return r ~= nil and moveTo(r, to)
	end
	function e:Clear() e:Set({}) end
	function e:SetActive(i)
		e.Active = i
		layout(false)
	end
	e:Set(o.Items or {}, true)
	w:_Flag(o.Flag, e)
	return e
end

---------------------------------------------------------------------------
-- Tag every element's row with its type, so search can say what each result is
---------------------------------------------------------------------------
do
	local kinds = {
		Toggle = "Toggle", Slider = "Slider", Input = "Input", Dropdown = "Dropdown", Button = "Button",
		Stepper = "Stepper", Segmented = "Selector", Keybind = "Keybind", Colorpicker = "Color",
		Paragraph = "Paragraph", Value = "Value", InfoBox = "Information", Collapsible = "Group",
		Header = "Header", Gear = "Settings", ReorderList = "List", Label = "Label", Card = "Card",
	}
	for method, kind in pairs(kinds) do
		local original = Container[method]
		Container[method] = function(self, ...)
			local e = original(self, ...)
			if type(e) == "table" and typeof(e.Row) == "Instance" then e.Row:SetAttribute("NebulaKind", kind) end
			return e
		end
	end
end

return Nebula
