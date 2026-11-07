--!nocheck
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
		return U.new("UICorner", { Parent = o, CornerRadius = UDim.new(0, r or 8) })
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

	function U.tween(o, t, props, style)
		local tw = Svc.TweenService:Create(
			o,
			TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			props
		)
		tw:Play()
		return tw
	end

	function U.measure(text, size, width)
		if text == nil or text == "" then return Vector2.new(0, 0) end
		local ok, v = pcall(Svc.TextService.GetTextSize, Svc.TextService, text, size, F.Measure, Vector2.new(width or 1e4, 1e4))
		return ok and v or Vector2.new(#text * size * 0.55, size + 3)
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
	builders.grip = function(h, c)
		for _, x in ipairs({ 0.32, 0.68 }) do
			for _, y in ipairs({ 0.2, 0.5, 0.8 }) do
				local d = bar(h, c, 0, 0, x, y)
				d.Size = UDim2.fromOffset(3, 3)
				U.round(d)
			end
		end
	end

	function U.icon(kind, parent, size, color, props)
		local h = U.new("Frame", {
			Parent = parent,
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
		})
		for k, v in pairs(props or {}) do h[k] = v end
		local b = builders[kind]
		if b then b(h, color or T.Text) end
		return h
	end

	function U.iconColor(h, color)
		for _, d in ipairs(h:GetDescendants()) do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = color end
			if d:IsA("UIStroke") then d.Color = color end
		end
	end

	-- Nebula logo: two counter-rotating comet rings + glowing core
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

	function Tr.Register(obj, s, prop)
		if s == nil then return end
		s = tostring(s)
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
	local function googleRequest(lang, q)
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
			local lines = r and string.split(r, "\n") or {}
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
		for _, fn in ipairs(Tr.Listeners) do pcall(fn) end
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
local HEADER_H = 52

function Nebula:Window(o)
	o = o or {}
	if type(o.Theme) == "table" then
		for k, v in pairs(o.Theme) do T[k] = v end
	end
	local self = setmetatable({}, Window)
	self.Title = o.Title or "NebulaGui"
	self.Subtitle = o.Subtitle or ""
	if typeof(o.Size) == "UDim2" then
		self.Desired = Vector2.new(o.Size.X.Offset, o.Size.Y.Offset)
	elseif typeof(o.Size) == "Vector2" then
		self.Desired = o.Size
	else
		self.Desired = Vector2.new(840, 540)
	end
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

	FS.mkdir(self.Folder .. "/configs")
	self.Settings = FS.readJSON(self.Folder .. "/nebula.json") or {}

	self:_BuildShell()
	self:_BuildSidebar(o)
	self:_BuildHeader()
	self:_BuildFloat(o)
	self:_BuildNotifications()

	self:_Connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), function() self:_Layout() end)
	self:_Connect(Svc.UserInputService.InputBegan, function(i, gp) self:_OnKey(i, gp) end)
	table.insert(Tr.Listeners, function()
		if self.Gui.Parent then self:_RelayoutAll() end
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
		Size = UDim2.new(1, 0, 1, -HEADER_H),
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
		Parent = main,
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
	})

	-- resize grip (mouse users only)
	local grip = U.button({
		Parent = main,
		Name = "Resize",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 9,
	})
	for i = 1, 2 do
		U.new("Frame", {
			Parent = grip,
			BackgroundColor3 = T.Faint,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.62 + i * 0.08, 0.62 + i * 0.08),
			Size = UDim2.new(0.5 - i * 0.18, 0, 0, 2),
			Rotation = -45,
		})
	end
	self.Grip = grip
	local base
	U.drag(self, grip, function() base = self.Desired end, function(d)
		self.Desired = Vector2.new(math.max(480, base.X + d.X), math.max(320, base.Y + d.Y))
		self:_Layout()
	end, function()
		self.Settings.Size = { self.Desired.X, self.Desired.Y }
		self:_SaveSettings()
	end)
	if type(self.Settings.Size) == "table" then
		self.Desired = Vector2.new(tonumber(self.Settings.Size[1]) or self.Desired.X, tonumber(self.Settings.Size[2]) or self.Desired.Y)
	end
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
	U.logo(brand, 30, true, { Position = UDim2.fromOffset(0, 2) })
	U.text({ Parent = brand, Text = self.Title, FontFace = F.Bold, TextSize = 15, Position = UDim2.fromOffset(40, 1), Size = UDim2.new(1, -40, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd })
	U.text({ Parent = brand, Text = self.Subtitle, TextSize = 11, TextColor3 = T.Muted, Position = UDim2.fromOffset(40, 19), Size = UDim2.new(1, -40, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })

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
	U.text({ Parent = card, Text = lp and lp.DisplayName or "Player", FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -54, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
	U.text({ Parent = card, Text = lp and ("@" .. lp.Name) or "", TextSize = 10, TextColor3 = T.Muted, Position = UDim2.fromOffset(48, 25), Size = UDim2.new(1, -54, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
end

function Window:_HeaderButton(name, kind)
	local b = U.button({
		Parent = self.Header,
		Name = name,
		BackgroundColor3 = T.Elevated,
		Size = UDim2.fromOffset(32, 32),
	})
	U.corner(b, 8)
	local ic = U.icon(kind, b, 14, T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	U.hover(b, function()
		U.tween(b, 0.15, { BackgroundTransparency = 0 })
		U.iconColor(ic, T.Text)
	end, function()
		U.tween(b, 0.15, { BackgroundTransparency = 1 })
		U.iconColor(ic, T.Muted)
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
	table.insert(Tr.Listeners, function() self.LangLabel.Text = string.upper(Tr.Lang) end)

	self.MinBtn = self:_HeaderButton("Minimize", "min")
	U.onClick(self.MinBtn, function() self:SetVisible(false) end)
	self.CloseBtn = self:_HeaderButton("Close", "close")
	U.onClick(self.CloseBtn, function()
		if not self.CloseConfirm then return self:Destroy() end
		self:Dialog({
			Title = "Close the interface?",
			Content = "Everything will stop running. You'll need to execute the script again.",
			Buttons = {
				{ Name = "Cancel" },
				{ Name = "Close", Primary = true, Callback = function() self:Destroy() end },
			},
		})
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
	box.Focused:Connect(function() st.Color = T.Accent end)
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
	box:GetPropertyChangedSignal("Text"):Connect(function() self:_Search(box.Text) end)
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
	U.logo(fb, size - 20, true, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
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
function Window:_Layout()
	local scr = self.Gui.AbsoluteSize
	if scr.X <= 0 then return end
	local w = math.max(300, math.min(self.Desired.X, scr.X - 16))
	local h = math.max(240, math.min(self.Desired.Y, scr.Y - 16))
	self.Holder.Size = UDim2.fromOffset(w, h)
	self.Size = Vector2.new(w, h)

	local compact = w < 640
	if compact ~= self.Compact then self:_SetCompact(compact) end

	local contentW = w - (compact and 0 or SIDEBAR_W) - 36
	local cols = contentW >= 520 and 2 or 1
	if cols ~= self.Cols then
		self.Cols = cols
		for _, tab in ipairs(self.Tabs) do tab:_SetCols(cols) end
	end

	local touchOnly = Svc.UserInputService.TouchEnabled and not Svc.UserInputService.MouseEnabled
	self.Grip.Visible = not compact and not touchOnly
	self.NotifyHolder.Size = UDim2.new(0, math.min(290, scr.X - 32), 1, -32)
	self:_LayoutHeader()
	self:_Place()
	self:_ClampFloat()
end

function Window:_Place()
	local scr = self.Gui.AbsoluteSize
	local size = self.Size or self.Desired
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
	local W = self.Header.AbsoluteSize.X
	if W <= 0 then return end
	local compact = self.Compact
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
			fn(x)
		end
	end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() run(false) end)
	table.insert(cont.Tab._relayouts, function() run(true) end)
	task.defer(run, true)
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
	self.Visible = v
	self:_ClosePopup()
	if v then
		self.Holder.Visible = true
		if not instant then
			self.Scale.Scale = 0.96
			U.tween(self.Scale, 0.2, { Scale = 1 })
		end
	else
		self.Holder.Visible = false
	end
end

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

function Window:Tab(o)
	if type(o) == "string" then o = { Name = o } end
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
	U.pad(page, 16, 18, 18, 18)
	local cols = U.new("Frame", { Parent = page, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
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
	local pop = U.new("Frame", { Parent = ov, BackgroundColor3 = T.Surface, ZIndex = 2, ClipsDescendants = true })
	U.corner(pop, 10)
	U.stroke(pop, T.BorderHi)
	local rel = anchor.AbsolutePosition - ov.AbsolutePosition
	local area = ov.AbsoluteSize
	height = math.min(height, area.Y - 16)
	local x = math.clamp(rel.X + anchor.AbsoluteSize.X - width, 8, math.max(8, area.X - width - 8))
	local y = rel.Y + anchor.AbsoluteSize.Y + 6
	if y + height > area.Y - 8 then y = math.max(8, rel.Y - height - 6) end
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
	if not name or name == "" then return end
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
	local found = {}
	for _, e in ipairs(self._index) do
		if e.row.Parent and (e.name:lower():find(q, 1, true) or e.label.Text:lower():find(q, 1, true)) then
			table.insert(found, e)
			if #found >= 8 then break end
		end
	end
	local ov = self.Overlay
	local sf = self.SearchFrame
	local rel = sf.AbsolutePosition - ov.AbsolutePosition
	local w = math.max(sf.AbsoluteSize.X, 240)
	local h = math.max(1, #found) * 38 + 8
	local pop = U.new("Frame", {
		Parent = ov,
		BackgroundColor3 = T.Surface,
		ZIndex = 3,
		Position = UDim2.fromOffset(math.clamp(rel.X + sf.AbsoluteSize.X - w, 8, math.max(8, ov.AbsoluteSize.X - w - 8)), rel.Y + sf.AbsoluteSize.Y + 6),
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
		U.text({ Parent = b, Text = e.label.Text, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.62, -10, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		U.text({ Parent = b, Text = e.tab.Label.Text, TextSize = 11, TextColor3 = T.Muted, Position = UDim2.fromScale(0.62, 0), Size = UDim2.new(0.38, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
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
		local y = e.row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 24
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
function Window:Notify(o)
	if type(o) == "string" then o = { Title = o } end
	local translate = o.Translate ~= false
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

function Window:Dialog(o)
	o = o or {}
	self:_ClosePopup()
	if not self.Visible then self:SetVisible(true) end
	local scrim = U.button({ Parent = self.Overlay, BackgroundColor3 = T.Background, BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	local card = U.new("Frame", {
		Parent = scrim,
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.min(340, self.Main.AbsoluteSize.X - 32), 0),
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
	for _, fn in ipairs(self._relayouts) do fn() end
end

function Tab:Section(o)
	if type(o) == "string" then o = { Name = o } end
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
		local t = U.text({ Parent = f, FontFace = F.Bold, TextSize = 11, TextColor3 = T.Glow, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0 })
		Tr.Register(t, string.upper(o.Name))
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
	return e
end

-- name (+ description) on the left, control on the right.
-- stackable: when the name doesn't fit, the control drops to its own line at full width.
function U.inlineRow(cont, o, ctrlW, ctrlH, stackable)
	local w = cont.Window
	local row = cont:_NewRow(ctrlH)
	local name = U.text({ Parent = row, FontFace = F.SemiBold, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
	Tr.Register(name, o.Name or "")
	local desc
	if o.Description then
		desc = U.text({ Parent = row, TextSize = 11, TextColor3 = T.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
		Tr.Register(desc, o.Description)
	end
	local ctrl = U.new("Frame", { Parent = row, BackgroundTransparency = 1, Size = UDim2.fromOffset(ctrlW, ctrlH) })
	w:_Watch(cont, row, function(W)
		local avail = W - ctrlW - 12
		local stacked = stackable and (U.measure(name.Text, 13).X * 1.07 > avail)
		local tw = stacked and W or avail
		local nh = U.measureH(name.Text, 13, tw)
		local dh = desc and U.measureH(desc.Text, 11, tw) or 0
		local th = nh + (desc and (dh + 2) or 0)
		local ty, h
		if stacked then
			ty = 0
			ctrl.Position = UDim2.fromOffset(0, th + 8)
			ctrl.Size = UDim2.fromOffset(W, ctrlH)
			h = th + 8 + ctrlH
		else
			h = math.max(th, ctrlH)
			ty = math.floor((h - th) / 2)
			ctrl.Position = UDim2.fromOffset(W - ctrlW, math.floor((h - ctrlH) / 2))
			ctrl.Size = UDim2.fromOffset(ctrlW, ctrlH)
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
function Container:Toggle(o)
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
function Container:Slider(o)
	local w = self.Window
	local min, max = o.Min or 0, o.Max or 100
	local step = o.Step or o.Increment or 1
	local suffix = o.Suffix or ""
	local decimals = step < 1 and #(tostring(step):match("%.(%d+)") or "") or 0
	local row = self:_NewRow(22)
	local name = U.text({ Parent = row, FontFace = F.SemiBold, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
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
	w:_Connect(Svc.UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
	w:_Connect(Svc.UserInputService.InputEnded, function(i)
		if dragging and U.isPress(i) then
			dragging = false
			self.Tab.Page.ScrollingEnabled = true
		end
	end)
	box.FocusLost:Connect(function()
		e:Set(tonumber((box.Text:gsub("[^%d%.%-]", ""))))
		render()
	end)

	w:_Watch(self, row, function(W)
		local L = math.clamp(math.floor(W * 0.36), 80, 150)
		local valW = 48
		if U.measure(name.Text, 13).X * 1.07 <= L then
			name.Position = UDim2.new()
			name.Size = UDim2.fromOffset(L, 22)
			name.TextYAlignment = Enum.TextYAlignment.Center
			bar.Position = UDim2.fromOffset(L + 10, 0)
			bar.Size = UDim2.fromOffset(math.max(20, W - L - valW - 20), 22)
			box.Position = UDim2.fromOffset(W - valW, 0)
			row.Size = UDim2.new(1, 0, 0, 22)
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
	w:_Index(self, o.Name, name, row)
	e:Set(o.Default or min, true)
	w:_Flag(o.Flag, e)
	return e
end

-- Input ----------------------------------------------------------------------
function Container:Input(o)
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
	if o.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = box.Text:gsub("[^%d%.%-]", "")
			if clean ~= box.Text then box.Text = clean end
		end)
	end
	box.Focused:Connect(function() st.Color = T.Accent end)
	box.FocusLost:Connect(function()
		st.Color = T.Border
		if box.Text ~= e.Value then e:Set(box.Text) end
	end)
	if o.Live then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if box:IsFocused() then
				e.Value = box.Text
				U.safe(o.Callback, e.Value)
			end
		end)
	end
	e:Set(o.Default or "", true)
	self.Window:_Flag(o.Flag, e)
	return e
end

-- Dropdown -------------------------------------------------------------------
function Container:Dropdown(o)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, o, o.Width or 160, 32, true)
	local btn = U.button({ Parent = ctrl, BackgroundColor3 = T.Background, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1) })
	U.corner(btn, 8)
	local st = U.stroke(btn, T.Border)
	local txt = U.text({ Parent = btn, FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	U.icon("down", btn, 12, T.Muted, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) })
	U.hover(btn, function() st.Color = T.BorderHi end, function() st.Color = T.Border end)

	local e = element(row, o)
	e.Options = o.Options or {}
	e.Multi = o.Multi == true
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
		e.Options = opts or {}
		if not keep then e.Value = e.Multi and {} or nil end
		e._display()
	end
	function e:Toggle(v) -- multi helper
		if not e.Multi then return e:Set(v) end
		e.Value[v] = (not e.Value[v]) or nil
		e._display()
		U.safe(o.Callback, e:Get())
	end
	U.onClick(btn, function() w:_DropdownPopup(e, ctrl) end)
	table.insert(Tr.Listeners, function() if row.Parent then e._display() end end)

	if e.Multi then e:Set(o.Default or {}, true) else e:Set(o.Default, true) end
	w:_Flag(o.Flag, e)
	return e
end

function Window:_DropdownPopup(e, anchor)
	local opts = e.Options
	local searchable = #opts > 6
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
		U.stroke(search, T.Border)
		U.pad(search, 0, 8, 0, 8)
	end
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
	local function build(filter)
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiButton") then c:Destroy() end
		end
		for i, v in ipairs(opts) do
			local s = tostring(v)
			if not filter or s:lower():find(filter, 1, true) then
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
	build(nil)
	if search then
		search:GetPropertyChangedSignal("Text"):Connect(function()
			local q = search.Text:lower()
			build(q ~= "" and q or nil)
		end)
	end
end

-- Button ---------------------------------------------------------------------
function Container:Button(o)
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
function Container:Stepper(o)
	local min, max = o.Min or -math.huge, o.Max or math.huge
	local step = o.Step or 1
	local decimals = step < 1 and #(tostring(step):match("%.(%d+)") or "") or 0
	local row, ctrl = U.inlineRow(self, o, 108, 30, false)
	local pill = U.new("Frame", { Parent = ctrl, BackgroundColor3 = T.Background, Size = UDim2.fromScale(1, 1) })
	U.round(pill)
	U.stroke(pill, T.Border)
	local function side(kind, anchorX, posX)
		local b = U.button({ Parent = pill, BackgroundColor3 = T.Elevated, BackgroundTransparency = 0, AnchorPoint = Vector2.new(anchorX, 0.5), Position = UDim2.new(posX, anchorX == 0 and 2 or -2, 0.5, 0), Size = UDim2.fromOffset(26, 26) })
		U.round(b)
		U.icon(kind, b, 10, kind == "plus" and T.Glow or T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		return b
	end
	local minus = side("minus", 0, 0)
	local plus = side("plus", 1, 1)
	local box = U.new("TextBox", {
		Parent = pill,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -60, 1, 0),
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
function Container:Segmented(o)
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
function Container:Keybind(o)
	local w = self.Window
	local row, ctrl = U.inlineRow(self, o, 92, 30, false)
	local b = U.button({ Parent = ctrl, BackgroundColor3 = T.Background, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), FontFace = F.SemiBold, TextSize = 12, TextColor3 = T.Glow })
	U.corner(b, 8)
	local st = U.stroke(b, T.Border)
	local e = element(row, o)
	local listening = false
	function e:Set(v, silent)
		if type(v) == "string" then v = Enum.KeyCode[v] end
		e.Value = v
		b.Text = v and v.Name or "—"
		if not silent and o.Changed then U.safe(o.Changed, v) end
	end
	function e:Get() return e.Value and e.Value.Name or nil end
	U.onClick(b, function()
		listening = true
		b.Text = "…"
		st.Color = T.Accent
	end)
	w:_Connect(Svc.UserInputService.InputBegan, function(i, gp)
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
function Container:Label(o)
	if type(o) == "string" then o = { Text = o } end
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local l = U.text({ Parent = row, TextSize = o.Size or 12, TextColor3 = o.Color or T.Muted, TextWrapped = true, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	Tr.Register(l, o.Text or "")
	local e = element(row, o)
	function e:Set(t) Tr.Register(l, t) end
	return e
end

function Container:Paragraph(o)
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

function Container:Value(o)
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
function Container:Card(o)
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
function Container:InfoBox(o)
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
function Container:Collapsible(o)
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

-- ReorderList (numbered steps with drag, ↑ ↓ and remove) ----------------------
function Container:ReorderList(o)
	local w = self.Window
	local row = self:_NewRow(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local list = U.new("Frame", { Parent = row, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y })
	U.list(list, 6)
	local e = element(row, o)
	e.Items = {}
	local rows = {}
	local drag

	local function renumber()
		for i, r in ipairs(rows) do
			local active = e.Active == i
			r.frame.LayoutOrder = i
			r.num.Text = tostring(i)
			r.badge.BackgroundColor3 = active and T.Accent or T.Elevated2
			r.num.TextColor3 = active and T.White or T.Glow
			r.stroke.Color = (active or (drag and drag.r == r)) and T.Accent or T.Border
		end
	end
	local function changed()
		e.Items = {}
		for i, r in ipairs(rows) do e.Items[i] = r.value end
		renumber()
		U.safe(o.Callback, table.clone(e.Items))
	end
	local function move(r, delta)
		local i = table.find(rows, r)
		local j = i and i + delta
		if not j or j < 1 or j > #rows then return end
		table.remove(rows, i)
		table.insert(rows, j, r)
		changed()
	end

	local function small(parent, kind, x)
		local b = U.button({ Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(22, 22) })
		U.icon(kind, b, 11, T.Muted, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		return b
	end

	local function makeRow(value)
		local fr = U.new("Frame", { Parent = list, BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, 40) })
		U.corner(fr, 9)
		local r = { frame = fr, value = value, stroke = U.stroke(fr, T.Border) }
		local grip = U.button({ Parent = fr, Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0, 22, 1, 0) })
		U.icon("grip", grip, 12, T.Faint, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		r.badge = U.new("Frame", { Parent = fr, BackgroundColor3 = T.Elevated2, Position = UDim2.new(0, 28, 0.5, -11), Size = UDim2.fromOffset(22, 22) })
		U.corner(r.badge, 6)
		r.num = U.text({ Parent = r.badge, FontFace = F.Bold, TextSize = 11, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		U.text({ Parent = fr, Text = tostring(value), FontFace = F.SemiBold, TextSize = 12, Position = UDim2.fromOffset(58, 0), Size = UDim2.new(1, -190, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
		local rm = U.button({ Parent = fr, BackgroundColor3 = T.Danger, BackgroundTransparency = 0.85, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0), Size = UDim2.fromOffset(70, 22), FontFace = F.Bold, TextSize = 11, TextColor3 = T.DangerText })
		U.corner(rm, 6)
		Tr.Register(rm, "Remove")
		U.onClick(small(fr, "up", -30), function() move(r, -1) end)
		U.onClick(small(fr, "down", -6), function() move(r, 1) end)
		U.onClick(rm, function()
			local i = table.find(rows, r)
			if not i then return end
			table.remove(rows, i)
			fr:Destroy()
			if e.Active and e.Active > #rows then e.Active = nil end
			U.safe(o.OnRemove, value, i)
			changed()
		end)
		grip.InputBegan:Connect(function(i)
			if not U.isPress(i) then return end
			drag = { r = r, input = i, y = i.Position.Y, from = table.find(rows, r) }
			self.Tab.Page.ScrollingEnabled = false
			renumber()
		end)
		return r
	end

	w:_Connect(Svc.UserInputService.InputChanged, function(i)
		if not drag then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i ~= drag.input then return end
		local target = math.clamp(drag.from + math.floor((i.Position.Y - drag.y) / 46 + 0.5), 1, #rows)
		local cur = table.find(rows, drag.r)
		if cur and target ~= cur then
			table.remove(rows, cur)
			table.insert(rows, target, drag.r)
			renumber()
		end
	end)
	w:_Connect(Svc.UserInputService.InputEnded, function(i)
		if drag and (i == drag.input or i.UserInputType == Enum.UserInputType.MouseButton1) then
			drag = nil
			self.Tab.Page.ScrollingEnabled = true
			changed()
		end
	end)

	function e:Set(items, silent)
		for _, r in ipairs(rows) do r.frame:Destroy() end
		rows = {}
		for _, v in ipairs(type(items) == "table" and items or {}) do table.insert(rows, makeRow(v)) end
		e.Items = table.clone(type(items) == "table" and items or {})
		renumber()
		if not silent then U.safe(o.Callback, table.clone(e.Items)) end
	end
	function e:Get() return table.clone(e.Items) end
	function e:Add(v)
		table.insert(rows, makeRow(v))
		changed()
	end
	function e:SetActive(i)
		e.Active = i
		renumber()
	end
	e:Set(o.Items or {}, true)
	w:_Flag(o.Flag, e)
	return e
end

return Nebula
