local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local gui = {}

local Arimo = Font.new("rbxasset://fonts/families/Arimo.json")
local ArimoBold = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold)

export type CommandBar = Frame & {
	input: TextBox,
	inputDisplay: TextLabel,
	OutputFrame: ScrollingFrame & {
		Output: TextLabel,
		Cleanup: ImageButton,
	},
	autofill: TextLabel,
	autofillSel: Frame & {
		AutofillComponent: TextLabel,
	},
}
function gui.BakeCommandBar(): (CommandBar, Frame & { AutofillComponent: TextLabel })
	local cmd = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local input = Instance.new("TextBox")
	local OutputFrame = Instance.new("ScrollingFrame")
	local Output = Instance.new("TextLabel")
	local BG = Instance.new("Frame")
	local UIGradient = Instance.new("UIGradient")
	local CleanUp = Instance.new("ImageButton")
	local UIPadding = Instance.new("UIPadding")
	local SizeConstraint = Instance.new("UISizeConstraint")
	local autofill = Instance.new("TextLabel")

	local autofillSel = Instance.new("Frame")
	local stroke = Instance.new("UIStroke")
	local autofillComponent = Instance.new("TextLabel")

	cmd.Name = "cmd"
	cmd.AnchorPoint = Vector2.new(0.5, 0.5)
	cmd.BackgroundColor3 = Color3.new(0, 0, 0)
	cmd.BackgroundTransparency = 0.3
	cmd.Position = UDim2.new(0.5, 0, 0.5, 0)
	cmd.Size = UDim2.new(0.75, 0, 0.05, 0)
	cmd.Visible = false

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = cmd

	-- This is where you enter text
	input.Name = "input"
	input.AnchorPoint = Vector2.new(0.5, 0)
	input.BackgroundTransparency = 1
	input.Position = UDim2.new(0.5, 0, 0, 0)
	input.Size = UDim2.new(1, -20, 1, 0)
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.Code
	input.ZIndex = 2
	input.Text = ""
	input.TextColor3 = Color3.new(1, 1, 1)
	input.TextSize = 14
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.Parent = cmd

	-- This is the text you see
	local inputDisplay = Instance.new("TextLabel")
	inputDisplay.Name = "inputDisplay"
	inputDisplay.Interactable = false
	inputDisplay.AnchorPoint = Vector2.new(0.5, 0)
	inputDisplay.BackgroundTransparency = 1
	inputDisplay.Position = UDim2.new(0.5, 0, 0, 0)
	inputDisplay.Size = UDim2.new(1, -20, 1, 0)
	inputDisplay.Font = Enum.Font.Code
	inputDisplay.ZIndex = 3
	inputDisplay.Text = ""
	inputDisplay.RichText = true
	inputDisplay.TextColor3 = Color3.new(1, 1, 1)
	inputDisplay.TextSize = 14
	inputDisplay.TextXAlignment = Enum.TextXAlignment.Left
	inputDisplay.Parent = cmd

	local function updOutSize()
		OutputFrame.CanvasSize = UDim2.fromOffset(0, math.max(Output.TextBounds.Y + 10, 24))
		OutputFrame.Size = UDim2.new(1, 0, 0, OutputFrame.CanvasSize.Y.Offset)
		BG.Size = UDim2.new(1, 0, 0, math.clamp(OutputFrame.Size.Y.Offset, 0, 240))
	end
	OutputFrame.Name = "OutputFrame"
	OutputFrame.BackgroundTransparency = 1
	Output:GetPropertyChangedSignal("Text"):Connect(updOutSize)
	updOutSize()
	OutputFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		BG.Visible = OutputFrame.Visible
	end)
	OutputFrame.Size = UDim2.fromScale(1, 0)
	OutputFrame.Position = UDim2.fromScale(0, 1.5)
	OutputFrame.ScrollBarThickness = 0
	OutputFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	OutputFrame.Visible = false
	OutputFrame.Parent = cmd

	SizeConstraint.MaxSize = Vector2.new(math.huge, 240)
	SizeConstraint.Parent = OutputFrame

	CleanUp.Name = "Cleanup"
	CleanUp.AnchorPoint = Vector2.new(1, 0)
	CleanUp.Position = UDim2.new(1, -4, 0, 4)
	CleanUp.Size = UDim2.fromOffset(24, 24)
	CleanUp.BackgroundColor3 = Color3.new()
	CleanUp.BackgroundTransparency = 0.3
	CleanUp.Image = "rbxasset://textures/RoduxDevtools/ClearList.png"
	UICorner:Clone().Parent = CleanUp
	CleanUp.Parent = OutputFrame

	local redBorder = Instance.new("UIStroke")
	redBorder.Color = Color3.new(1)
	redBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	redBorder.Thickness = 1.5
	redBorder.Parent = CleanUp

	BG.Name = "BG"
	BG.ZIndex = 0
	BG.Position = UDim2.fromScale(0, 1.5)
	BG.Visible = false
	UICorner:Clone().Parent = BG
	BG.Parent = cmd

	UIGradient.Color = ColorSequence.new(Color3.new())
	UIGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.49375),
		NumberSequenceKeypoint.new(0.440873, 0.625),
		NumberSequenceKeypoint.new(0.768083, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})
	UIGradient.Rotation = 90
	UIGradient.Parent = BG

	Output.Name = "Output"
	Output.BackgroundTransparency = 1
	Output.AutomaticSize = Enum.AutomaticSize.Y
	Output.Size = UDim2.fromScale(1, 0)
	Output.Position = UDim2.fromOffset(0, 4)
	Output.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold)
	Output.Text = ""
	Output.TextColor3 = Color3.new(1, 1, 1)
	Output.TextSize = 14
	Output.TextStrokeTransparency = 0
	Output.TextWrapped = true
	Output.TextXAlignment = Enum.TextXAlignment.Left
	Output.TextYAlignment = Enum.TextYAlignment.Top
	Output.RichText = true
	Output.Parent = OutputFrame

	UIPadding.PaddingLeft = UDim.new(0, 12)
	UIPadding.PaddingRight = UDim.new(0, 24)
	UIPadding.Parent = Output

	autofill.Name = "autofill"
	autofill.BackgroundTransparency = 1
	autofill.AnchorPoint = Vector2.new(0.5, 0)
	autofill.Position = UDim2.new(0.5, 0, 0, 0)
	autofill.Size = UDim2.new(1, -20, 1, 0)
	autofill.Font = Enum.Font.Code
	autofill.Text = ""
	autofill.TextColor3 = Color3.new(1, 1, 1)
	autofill.TextSize = 14
	autofill.TextTransparency = 0.4
	autofill.TextXAlignment = Enum.TextXAlignment.Left
	autofill.Parent = cmd

	autofillSel.Name = "autofullSel"
	autofillSel.Visible = false
	autofillSel.Size = UDim2.fromOffset(100, 20)
	autofillSel.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	autofillSel.ZIndex = 2
	autofillSel.AnchorPoint = Vector2.new(0, 1)
	autofillSel.ClipsDescendants = true

	local autofillSizeConst = SizeConstraint:Clone()
	autofillSizeConst.MaxSize = Vector2.new(math.huge, 100)
	autofillSizeConst.MinSize = Vector2.new(100, 20)
	autofillSizeConst.Parent = autofillSel

	UICorner:Clone().Parent = autofillSel

	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(12, 12, 12)
	stroke.Thickness = 2
	stroke.Parent = autofillSel

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = autofillSel

	autofillComponent.Name = "AutofillComponent"
	autofillComponent.ZIndex = 3
	autofillComponent.BackgroundColor3 = Color3.fromRGB(21, 122, 255)
	autofillComponent.BackgroundTransparency = 1
	autofillComponent.Size = UDim2.new(1, 0, 0, 20)
	input.Font = Enum.Font.Code
	autofillComponent.TextColor3 = Color3.new(1, 1, 1)
	autofillComponent.TextXAlignment = Enum.TextXAlignment.Left
	autofillComponent.Parent = autofillSel

	UICorner:Clone().Parent = autofillComponent
	local compPadding = UIPadding:Clone()
	compPadding.PaddingLeft = UDim.new(0, 4)
	compPadding.PaddingRight = compPadding.PaddingLeft
	compPadding.Parent = autofillComponent

	return cmd, autofillSel
end

export type row = Frame & {
	Content: Frame & {
		Entry: TextLabel,
	},
	Index: TextLabel,
}

local scrollDelta = 0.05
function gui.ScrollGui(name: string): (ScreenGui, ScrollingFrame, row)
	local scr = Instance.new("ScreenGui")
	scr.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	scr.Name = `PBSAdmin_LIST_{name}`

	local windowScale = Instance.new("UIScale")
	windowScale.Parent = scr

	local drag = Instance.new("Frame")
	drag.BackgroundTransparency = 1
	drag.Size = UDim2.new(0, 385, 0, 20)
	drag.AutomaticSize = Enum.AutomaticSize.X
	drag.Position = UDim2.new(0.5, -200, 0.5, -200)
	drag.Parent = scr
	Instance.new("UIDragDetector").Parent = drag

	local main = Instance.new("Frame")
	main.BackgroundColor3 = Color3.new(0, 0, 0)
	main.BackgroundTransparency = 0.3
	main.Size = UDim2.new(0, 0, 0, 400)
	main.AutomaticSize = Enum.AutomaticSize.X
	main.ClipsDescendants = true
	main.Parent = drag
	Instance.new("UICorner").Parent = main

	local topbar = Instance.new("Frame")
	topbar.AutomaticSize = Enum.AutomaticSize.X
	topbar.BackgroundTransparency = 1
	topbar.Size = UDim2.fromOffset(0, 20)
	topbar.Parent = main

	local topbarList = Instance.new("UIListLayout")
	topbarList.Padding = UDim.new(0, 8)
	topbarList.FillDirection = Enum.FillDirection.Horizontal
	topbarList.VerticalAlignment = Enum.VerticalAlignment.Center
	topbarList.SortOrder = Enum.SortOrder.LayoutOrder
	topbarList.Parent = topbar

	local title = Instance.new("TextLabel")
	title.Text = name
	title.FontFace = ArimoBold
	title.BackgroundTransparency = 1
	title.AutomaticSize = Enum.AutomaticSize.X
	title.Size = UDim2.fromScale(0, 20)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20
	title.Parent = topbar

	local search = Instance.new("TextBox")
	search.BackgroundColor3 = Color3.new()
	search.Size = UDim2.fromOffset(200, 18)
	search.TextColor3 = Color3.new(1, 1, 1)
	search.FontFace = Arimo
	search.TextSize = 14
	search.PlaceholderText = "Type here to search..."
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.LayoutOrder = 1
	search.Text = ""
	search.ClearTextOnFocus = true
	search.Parent = topbar

	local scorner = Instance.new("UICorner")
	scorner.CornerRadius = UDim.new(0, 4)
	scorner.Parent = search

	local spadding = Instance.new("UIPadding")
	spadding.PaddingLeft = UDim.new(0, 2)
	spadding.PaddingRight = spadding.PaddingLeft
	spadding.Parent = search

	local ssttroke = Instance.new("UIStroke")
	ssttroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ssttroke.Color = Color3.fromRGB(80, 80, 80)
	ssttroke.Thickness = 2
	ssttroke.Parent = search

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = uiPadding.PaddingBottom
	uiPadding.PaddingRight = uiPadding.PaddingBottom
	uiPadding.PaddingTop = uiPadding.PaddingBottom
	uiPadding.Parent = main

	local cmf = Instance.new("ScrollingFrame")
	cmf.AutomaticSize = Enum.AutomaticSize.X
	cmf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cmf.AnchorPoint = Vector2.yAxis
	cmf.CanvasSize = UDim2.fromScale(0, 0)
	cmf.ScrollBarThickness = 0
	cmf.BackgroundTransparency = 1
	cmf.Size = UDim2.new(0, 0, 1, -24)
	cmf.Position = UDim2.fromScale(0, 1)

	cmf.Parent = main

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = cmf

	local cmpadding = Instance.new("UIPadding")
	cmpadding.PaddingRight = UDim.new(0, 48)
	cmpadding.Parent = cmf
	cmpadding:Clone().Parent = topbar

	local down = Instance.new("ImageButton")
	down.Image = "http://www.roblox.com/asset/?id=108326725"
	down.BackgroundTransparency = 1
	down.Size = UDim2.new(0, 25, 0, 25)
	down.Position = UDim2.new(1, -20, 1, -20)
	down.Parent = main

	local up = down:Clone()
	up.Image = "http://www.roblox.com/asset/?id=108326682"
	up.Parent = main
	up.Position = UDim2.new(1, -20, 1, -50)

	local cls = Instance.new("TextButton")
	cls.Style = "RobloxButtonDefault"
	cls.Size = UDim2.new(0, 20, 0, 20)
	cls.Position = UDim2.new(1, -15, 0, -5)
	cls.ZIndex = 10
	cls.FontFace = ArimoBold
	cls.TextSize = 18
	cls.Text = "X"
	cls.TextColor3 = Color3.new(1, 1, 1)
	cls.Parent = main

	local row = Instance.new("Frame")
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(0, 0)
	row.ClipsDescendants = true -- for the stroke on the index

	local index = Instance.new("TextLabel")
	index.Name = "Index"
	index.BackgroundTransparency = 1
	index.Size = UDim2.new(0, 24, 1, 0)
	index.FontFace = ArimoBold
	index.TextSize = 14
	index.AutoLocalize = false
	index.TextColor3 = Color3.new(1, 1, 1)
	index.TextXAlignment = Enum.TextXAlignment.Left
	index.TextYAlignment = Enum.TextYAlignment.Top
	index.Parent = row

	local ipadding = Instance.new("UIPadding")
	ipadding.PaddingLeft = UDim.new(0, 2)
	ipadding.PaddingTop = ipadding.PaddingLeft
	ipadding.Parent = index

	local istroke = Instance.new("UIStroke")
	istroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	istroke.Color = Color3.fromRGB(128, 128, 128)
	istroke.Parent = index

	local content = Instance.new("Frame")
	content.AutomaticSize = Enum.AutomaticSize.X
	content.BackgroundTransparency = 1
	content.Name = "Content"
	content.Position = UDim2.fromOffset(32, 0)
	content.Size = UDim2.fromOffset(0, 20)
	content.Parent = row

	local ent = Instance.new("TextLabel")
	ent.Name = "Entry"
	ent.BackgroundTransparency = 1
	ent.AutomaticSize = Enum.AutomaticSize.XY
	ent.FontFace = Arimo
	ent.AutoLocalize = false
	ent.TextSize = 18
	ent.TextColor3 = Color3.new(1, 1, 1)
	ent.TextStrokeColor3 = Color3.new(0, 0, 0)
	ent.Size = UDim2.fromScale(0, 0)
	ent.TextStrokeTransparency = 0.8
	ent.TextXAlignment = Enum.TextXAlignment.Left
	ent.Parent = content

	cls.Activated:Connect(function(): ()
		scr:Destroy()
		ent:Destroy()
	end)

	local downv = false
	local upv = false

	local targetPosition = cmf.CanvasPosition
	cmf:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not downv and not upv then targetPosition = cmf.CanvasPosition end
	end)

	local scrollSpeed = 9
	local function frameDown()
		downv = true
		while downv do
			TweenService:Create(cmf, TweenInfo.new(0.25), { CanvasPosition = targetPosition + Vector2.new(0, scrollSpeed) }):Play()
			targetPosition += Vector2.new(0, scrollSpeed)
			targetPosition = targetPosition:Max(Vector2.zero):Min(list.AbsoluteContentSize - Vector2.new(0, cmf.AbsoluteSize.Y))
			task.wait(scrollDelta)
		end
	end
	local function frameUp()
		upv = true
		while upv do
			TweenService:Create(cmf, TweenInfo.new(0.25), { CanvasPosition = targetPosition - Vector2.new(0, scrollSpeed) }):Play()
			targetPosition -= Vector2.new(0, scrollSpeed)
			targetPosition = targetPosition:Max(Vector2.zero):Min(list.AbsoluteContentSize - Vector2.new(0, cmf.AbsoluteSize.Y))
			task.wait(scrollDelta)
		end
	end

	down.MouseButton1Down:Connect(frameDown)
	down.MouseButton1Up:Connect(function(): ()
		downv = false
	end)

	up.MouseButton1Down:Connect(frameUp)
	up.MouseButton1Up:Connect(function(): ()
		upv = false
	end)

	search.FocusLost:Connect(function(enter: boolean)
		if enter then
			for _, v in cmf:GetChildren() do
				if v:IsA("Frame") then v.Visible = string.match(v.Name, `^{search.Text}`) end
			end
		end
	end)

	scr:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		windowScale.Scale = math.clamp(scr.AbsoluteSize.Y / 800, 0.5, 1.5)
	end)
	windowScale.Scale = math.clamp(scr.AbsoluteSize.Y / 800, 0.5, 1.5)

	return scr, cmf, row
end

function gui.message(ttl: string, str: string, typewriter: boolean?, duration: number?): ()
	local scr = Instance.new("ScreenGui")
	scr.Name = "MessageGUI"

	local bg = Instance.new("Frame")
	bg.Name = "bg"
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BorderSizePixel = 0
	bg.BackgroundTransparency = 1
	bg.Size = UDim2.new(10, 0, 10, 0)
	bg.Position = UDim2.new(-5, 0, -5, 0)
	bg.ZIndex = 8
	bg.Parent = scr

	local title = Instance.new("TextLabel")
	title.Name = "title"
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.Size = UDim2.new(1, 0, 0, 50)
	title.ZIndex = 9
	title.FontFace = ArimoBold
	title.TextSize = 36
	title.Text = ttl
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.8
	title.RichText = true
	title.Parent = scr

	local msg = title:Clone()
	msg.Name = "msg"
	msg.Position = UDim2.new(0.0625, 0, 0, 0)
	msg.Size = UDim2.new(0.875, 0, 1, 0)
	msg.FontFace = Arimo
	msg.Text = str
	msg.TextSize = 24
	msg.TextYAlignment = Enum.TextYAlignment.Center
	msg.TextWrapped = true
	msg.MaxVisibleGraphemes = 0
	msg.RichText = true
	msg.Parent = scr

	scr.Parent = script.Parent

	-- Fade-in Tween
	local fadeInTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bg, fadeInTweenInfo, { BackgroundTransparency = 0.3 }):Play()
	TweenService:Create(title, fadeInTweenInfo, { TextTransparency = 0, TextStrokeTransparency = 0.8 }):Play()
	TweenService:Create(msg, fadeInTweenInfo, { TextTransparency = 0, TextStrokeTransparency = 0.8 }):Play()

	-- Text Scrolling Effect
	if typewriter then
		local charInterval = duration and duration / #str or 1 / 19

		for i = 1, #str do
			msg.MaxVisibleGraphemes = i
			task.wait(charInterval)
		end
		task.wait(2.5)
	else
		-- Display full text immediately if scroll is false
		msg.MaxVisibleGraphemes = -1
		task.wait(duration or #str / 50 + 2.5)
	end

	-- Fade-out Tween and Cleanup
	local fadeOutTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(bg, fadeOutTweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(title, fadeOutTweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(msg, fadeOutTweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(scr, 0.5)
end

return gui
