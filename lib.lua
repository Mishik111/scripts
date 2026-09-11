--!strict
-- ShootingMenu.lua
-- UI-only recreation of the uploaded 465x368 HTML menu for Roblox.
-- Exact artwork usage: Menu.new({ TopImage = "rbxassetid://YOUR_UPLOADED_IMAGE_ID" })
-- This module creates the interface; it does NOT implement aimbot, silent-aim,
-- triggerbot, damage, or exploit functionality.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Menu = {}
Menu.__index = Menu

local COLORS = {
	Background = Color3.fromRGB(4, 4, 4),
	Panel2 = Color3.fromRGB(16, 16, 18),
	Line = Color3.fromRGB(40, 40, 43),
	Muted = Color3.fromRGB(141, 141, 147),
	Text = Color3.fromRGB(238, 238, 239),
	Blue = Color3.fromRGB(20, 88, 216),
	Blue2 = Color3.fromRGB(22, 79, 202),
	White = Color3.fromRGB(241, 241, 243),
	Cell = Color3.fromRGB(16, 16, 19),
	CellToggle = Color3.fromRGB(37, 38, 42),
}

local function make<T>(className: string, props: {[string]: any}, parent: Instance?): T
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		obj[k] = v
	end
	if parent then
		obj.Parent = parent
	end
	return obj :: any
end

local function corner(parent: Instance, radius: number)
	return make("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, parent)
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
	}, parent)
end

local function tween(instance: Instance, duration: number, props: {[string]: any})
	TweenService:Create(
		instance,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

local function makeLabel(parent: Instance, text: string, size: number, color: Color3)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		TextSize = size,
		Font = Enum.Font.Arial,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

function Menu.new(config)
	config = config or {}

	local self = setmetatable({}, Menu)
	self.Visible = true
	self._connections = {}
	self._tabs = {}
	self._currentTab = 1
	self._destroyed = false

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	self.Gui = make("ScreenGui", {
		Name = config.Name or "ShootingMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	self.Root = make("Frame", {
		Name = "Wrap",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(465, 368),
		BackgroundTransparency = 1,
	}, self.Gui)

	self.Panel = make("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, self.Root)
	corner(self.Panel, 5)

	-- Exact top artwork hook.
	-- The original HTML points at https://i.imgur.com/v8LYnia.png.
	-- Roblox ImageLabel cannot use that external URL directly; upload the PNG
	-- to Roblox as an image/decal and pass the resulting rbxassetid here.
	self.TopArt = make("Frame", {
		Size = UDim2.new(1, 0, 0, 47),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, self.Panel)

	if config.TopImage then
		self.TopImage = make("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = config.TopImage, -- e.g. "rbxassetid://123456789"
			ScaleType = Enum.ScaleType.Crop,
			ResampleMode = Enum.ResamplerMode.Default,
		}, self.TopArt)
	else
		local placeholder = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "UPLOAD v8LYnia.png → set TopImage",
			TextColor3 = Color3.fromRGB(80, 80, 86),
			TextSize = 8,
			Font = Enum.Font.Arial,
		}, self.TopArt)
	end

	-- Sidebar
	self.Sidebar = make("Frame", {
		Position = UDim2.fromOffset(0, 47),
		Size = UDim2.new(0, 50, 1, -64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, self.Panel)
	stroke(self.Sidebar, Color3.fromRGB(37, 38, 42), 1, 0.1).Parent = self.Sidebar

	local iconGlyphs = {"▦", "⊙", "◉", "□", "▣", "⌂"}
	for i, glyph in ipairs(iconGlyphs) do
		local button = make("TextButton", {
			Name = "SideButton" .. i,
			Size = UDim2.fromOffset(50, 49),
			Position = UDim2.fromOffset(0, (i - 1) * 50),
			BackgroundColor3 = COLORS.Background,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = glyph,
			TextColor3 = Color3.fromRGB(133, 133, 139),
			TextSize = 19,
			Font = Enum.Font.Arial,
			AutoButtonColor = false,
		}, self.Sidebar)

		button.MouseButton1Click:Connect(function()
			self:SetSideIndex(i)
		end)

		self._sideButtons = self._sideButtons or {}
		table.insert(self._sideButtons, button)
	end

	self.Gear = make("TextButton", {
		Name = "Gear",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.fromOffset(50, 49),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "⚙",
		TextColor3 = Color3.fromRGB(133, 133, 139),
		TextSize = 19,
		Font = Enum.Font.Arial,
		AutoButtonColor = false,
	}, self.Sidebar)

	-- Content
	self.Content = make("Frame", {
		Position = UDim2.fromOffset(50, 47),
		Size = UDim2.new(1, -50, 1, -64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, self.Panel)

	-- Tabs
	self.TabsBar = make("Frame", {
		Size = UDim2.new(1, -26, 0, 38),
		Position = UDim2.fromOffset(13, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, self.Content)
	local tabsLine = make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(37, 38, 42),
		BorderSizePixel = 0,
	}, self.TabsBar)

	local tabs = config.Tabs or {
		"ВЕКТОРНЫЙ АИМБОТ",
		"САЙЛЕНТ АИМБОТ",
		"ТРИГГЕР",
		"ДАМГЕР",
	}

	local x = 0
	for i, name in ipairs(tabs) do
		local tab = make("TextButton", {
			Name = "Tab" .. i,
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(math.max(44, #name * 4 + 18), 38),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = name,
			TextColor3 = i == 1 and COLORS.White or Color3.fromRGB(125, 127, 133),
			TextSize = 10,
			Font = Enum.Font.Arial,
			AutoButtonColor = false,
		}, self.TabsBar)

		local activeLine = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, -2, 0, 2),
			BackgroundColor3 = COLORS.White,
			BorderSizePixel = 0,
			Visible = i == 1,
		}, tab)

		tab.MouseButton1Click:Connect(function()
			self:SetTab(i)
		end)

		self._tabs[i] = {button = tab, line = activeLine}
		x += tab.Size.X.Offset + 3
	end

	-- Main toggle
	self.MainToggle = make("Frame", {
		Position = UDim2.fromOffset(13, 50),
		Size = UDim2.new(1, -26, 0, 30),
		BackgroundColor3 = COLORS.Blue,
		BorderSizePixel = 0,
	}, self.Content)
	makeLabel(self.MainToggle, "Включить: Векторный аимбот", 10, COLORS.White).Position = UDim2.fromOffset(8, 0)

	local switch = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(26, 16),
		BackgroundColor3 = Color3.fromRGB(14, 82, 200),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, self.MainToggle)
	stroke(switch, Color3.new(1, 1, 1), 1, 0.2)
	local switchKnob = make("Frame", {
		Position = UDim2.fromOffset(13, 2),
		Size = UDim2.fromOffset(11, 10),
		BackgroundColor3 = Color3.fromRGB(247, 247, 248),
		BorderSizePixel = 0,
	}, switch)
	self.MainSwitch = {button = switch, knob = switchKnob, value = config.Enabled ~= false}
	if not self.MainSwitch.value then
		switchKnob.Position = UDim2.fromOffset(2, 2)
	end
	switch.MouseButton1Click:Connect(function()
		self:SetMainEnabled(not self.MainSwitch.value)
	end)

	-- Sliders
	self.Sliders = {}
	self:_createSlider(13, 104, "РАДИУС", 40.00, config.Radius or 40, config.RadiusMax or 100, "Radius")
	self:_createSlider(13, 166, "ПЛАВНОСТЬ", 1.00, config.Smoothness or 1, config.SmoothnessMax or 20, "Smoothness")

	makeLabel(self.Content, "РИСОВАТЬ РАДИУС", 9, Color3.fromRGB(119, 120, 126)).Position = UDim2.fromOffset(13, 225)
	local boneHeader = makeLabel(self.Content, "КОСТЬ: ГОЛОВА", 9, Color3.fromRGB(119, 120, 126))
	boneHeader.AnchorPoint = Vector2.new(1, 0)
	boneHeader.Position = UDim2.new(1, -13, 0, 225)

	self.Grid = make("Frame", {
		Position = UDim2.fromOffset(13, 251),
		Size = UDim2.new(1, -26, 0, 100),
		BackgroundTransparency = 1,
	}, self.Content)

	local grid = make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 31),
		CellPadding = UDim2.fromOffset(7, 7),
		FillDirectionMaxCells = 2,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.Grid)

	local cells = config.Options or {
		{label = "РИСОВАТЬ РАДИУС", type = "dropdown"},
		{label = "КОСТЬ: ГОЛОВА", type = "dropdown"},
		{label = "ЗАКРЕПИТЬСЯ НА ПОСЛЕДНЕМ", type = "toggle", value = true},
		{label = "ЕСЛИ ВИДИМ", type = "toggle", value = false},
		{label = "ИГНОРИРОВАТЬ В МАШИНЕ", type = "toggle", value = false},
		{label = "ЕСЛИ ПЕРЕЗАРЯЖАЕТСЯ", type = "toggle", value = false},
	}

	self.Options = {}
	for i, option in ipairs(cells) do
		self:_createOptionCell(i, option)
	end

	self:_buildBottomDecoration()
	self:_enableDragging()
	self:SetSideIndex(2)

	return self
end

function Menu:_buildBottomDecoration()
	local deco = make("Frame", {
		Position = UDim2.new(0, 51, 1, -33),
		Size = UDim2.new(1, -72, 0, 23),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, self.Panel)

	local topLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(37, 38, 42),
		BorderSizePixel = 0,
	}, deco)

	local function diag(x, side)
		local l = make("Frame", {
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(1, 28),
			BackgroundColor3 = Color3.fromRGB(37, 38, 42),
			BorderSizePixel = 0,
			Rotation = side,
			AnchorPoint = Vector2.new(0, 0),
		}, deco)
		return l
	end
	diag(50, -45)
	diag(math.max(80, deco.AbsoluteSize.X - 83), 45)

	for _, x in ipairs({34, 116, 0}) do
		if x ~= 0 then
			make("Frame", {
				Position = UDim2.fromOffset(x, 0),
				Size = UDim2.fromOffset(1, 8),
				BackgroundColor3 = Color3.fromRGB(46, 47, 50),
				BorderSizePixel = 0,
			}, deco)
		end
	end
	local rightTicks = {deco.Size.X.Offset - 107, deco.Size.X.Offset - 37}
	for _, x in ipairs(rightTicks) do
		make("Frame", {
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(1, 8),
			BackgroundColor3 = Color3.fromRGB(46, 47, 50),
			BorderSizePixel = 0,
		}, deco)
	end

	local footer = makeLabel(self.Panel, "SHOOTING UI  •  465 × 368", 7, Color3.fromRGB(78, 79, 85))
	footer.Position = UDim2.new(1, -158, 1, -18)
	footer.Size = UDim2.fromOffset(145, 10)
	footer.TextXAlignment = Enum.TextXAlignment.Right
end

function Menu:_createSlider(y: number, labelY: number, label: string, defaultText: number, value: number, maxValue: number, key: string)
	local section = make("Frame", {
		Position = UDim2.fromOffset(13, y),
		Size = UDim2.new(1, -26, 0, 44),
		BackgroundTransparency = 1,
	}, self.Content)

	local labelText = makeLabel(section, label, 8, Color3.fromRGB(225, 225, 228))
	labelText.Size = UDim2.new(1, -80, 0, 14)

	local valueText = makeLabel(section, string.format("%.2f", value), 8, Color3.fromRGB(233, 233, 235))
	valueText.AnchorPoint = Vector2.new(1, 0)
	valueText.Position = UDim2.new(1, 0, 0, 0)
	valueText.Size = UDim2.fromOffset(60, 14)
	valueText.TextXAlignment = Enum.TextXAlignment.Right

	local track = make("Frame", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 7),
		BackgroundColor3 = Color3.fromRGB(24, 24, 27),
		BorderSizePixel = 0,
	}, section)
	corner(track, 1)

	local fill = make("Frame", {
		Size = UDim2.fromScale(math.clamp(value / maxValue, 0, 1), 1),
		BackgroundColor3 = Color3.fromRGB(193, 193, 197),
		BorderSizePixel = 0,
	}, track)
	corner(fill, 1)

	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(math.clamp(value / maxValue, 0, 1), 0, 0.5, 0),
		Size = UDim2.fromOffset(4, 9),
		BackgroundColor3 = Color3.fromRGB(214, 214, 218),
		BorderSizePixel = 0,
	}, track)

	local plus = makeLabel(section, "+", 14, Color3.fromRGB(138, 138, 144))
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.Position = UDim2.new(1, -2, 0, 27)
	plus.Size = UDim2.fromOffset(12, 16)
	plus.TextXAlignment = Enum.TextXAlignment.Right

	local slider = {
		track = track,
		fill = fill,
		knob = knob,
		valueLabel = valueText,
		value = value,
		max = maxValue,
		key = key,
		_dragging = false,
	}
	self.Sliders[key] = slider

	local function update(inputX: number)
		local localX = math.clamp(inputX - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
		local ratio = track.AbsoluteSize.X > 0 and localX / track.AbsoluteSize.X or 0
		slider.value = ratio * maxValue
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueText.Text = string.format("%.2f", slider.value)

		if self.OnSliderChanged then
			self.OnSliderChanged(key, slider.value)
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			slider._dragging = true
			update(input.Position.X)
		end
	end)

	track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			slider._dragging = false
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if slider._dragging and
			(input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end))
end

function Menu:_createOptionCell(index: number, option)
	local cell = make("Frame", {
		BackgroundColor3 = index == 3 and COLORS.Blue or COLORS.Cell,
		BorderSizePixel = 0,
		LayoutOrder = index,
	}, self.Grid)

	local label = makeLabel(cell, option.label or ("OPTION " .. index), 9, COLORS.White)
	label.Position = UDim2.fromOffset(8, 0)
	label.Size = UDim2.new(1, -52, 1, 0)

	if option.type == "dropdown" then
		local drop = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.fromRGB(38, 38, 43),
			BorderSizePixel = 0,
			Text = "▼",
			TextColor3 = Color3.fromRGB(155, 155, 161),
			TextSize = 9,
			Font = Enum.Font.Arial,
			AutoButtonColor = false,
		}, cell)

		drop.MouseButton1Click:Connect(function()
			if self.OnDropdown then
				self.OnDropdown(index, option)
			end
		end)

		self.Options[index] = {cell = cell, button = drop, value = option.value}
	else
		local button = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(26, 12),
			BackgroundColor3 = index == 3 and Color3.fromRGB(17, 77, 186) or COLORS.CellToggle,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, cell)
		local knob = make("Frame", {
			Position = (option.value == true) and UDim2.fromOffset(15, 2) or UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = (option.value == true) and COLORS.White or Color3.fromRGB(214, 214, 216),
			BorderSizePixel = 0,
		}, button)

		local state = {
			cell = cell,
			button = button,
			knob = knob,
			value = option.value == true,
			label = option.label,
		}
		self.Options[index] = state

		button.MouseButton1Click:Connect(function()
			self:SetOption(index, not state.value)
		end)
	end
end

function Menu:ResetToHtmlDefaults()
	self:SetMainEnabled(true)
	self:SetSlider("Radius", 40)
	self:SetSlider("Smoothness", 1)
	for i, option in ipairs(self.Options) do
		if option.button and i >= 3 then
			self:SetOption(i, i == 3)
		end
	end
	self:SetTab(1)
	self:SetSideIndex(2)
end

function Menu:SetMainEnabled(enabled: boolean)
	self.MainSwitch.value = enabled
	local button = self.MainSwitch.button
	local knob = self.MainSwitch.knob
	tween(knob, 0.12, {
		Position = enabled and UDim2.fromOffset(13, 2) or UDim2.fromOffset(2, 2),
	})
	if self.OnMainToggle then
		self.OnMainToggle(enabled)
	end
end

function Menu:SetOption(index: number, enabled: boolean)
	local option = self.Options[index]
	if not option or not option.button then return end

	option.value = enabled
	local activeBg = index == 3 and Color3.fromRGB(17, 77, 186) or COLORS.CellToggle
	option.button.BackgroundColor3 = enabled and activeBg or COLORS.CellToggle
	tween(option.knob, 0.12, {
		Position = enabled and UDim2.fromOffset(15, 2) or UDim2.fromOffset(2, 2),
		BackgroundColor3 = enabled and COLORS.White or Color3.fromRGB(214, 214, 216),
	})

	if self.OnOptionChanged then
		self.OnOptionChanged(index, enabled, option.label)
	end
end

function Menu:SetSlider(key: string, value: number)
	local slider = self.Sliders[key]
	if not slider then return end
	value = math.clamp(value, 0, slider.max)
	local ratio = value / slider.max
	slider.value = value
	slider.fill.Size = UDim2.fromScale(ratio, 1)
	slider.knob.Position = UDim2.new(ratio, 0, 0.5, 0)
	slider.valueLabel.Text = string.format("%.2f", value)
end

function Menu:SetTab(index: number)
	if not self._tabs[index] then return end
	self._currentTab = index

	for i, tab in ipairs(self._tabs) do
		local selected = i == index
		tab.button.TextColor3 = selected and COLORS.White or Color3.fromRGB(125, 127, 133)
		tab.line.Visible = selected
	end

	if self.OnTabChanged then
		self.OnTabChanged(index)
	end
end

function Menu:SetSideIndex(index: number)
	if not self._sideButtons then return end
	for i, button in ipairs(self._sideButtons) do
		local selected = i == index
		button.BackgroundTransparency = selected and 0 or 1
		button.BackgroundColor3 = COLORS.Blue
		button.TextColor3 = selected and COLORS.White or Color3.fromRGB(133, 133, 139)
	end
end

function Menu:SetVisible(visible: boolean)
	self.Visible = visible
	self.Gui.Enabled = visible
end

function Menu:_enableDragging()
	local dragging = false
	local dragStart
	local startPos

	self.Panel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self.Root.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local delta = input.Position - dragStart
		self.Root.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end))
end

function Menu:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in ipairs(self._connections) do
		pcall(function() connection:Disconnect() end)
	end
	self.Gui:Destroy()
end

return Menu
