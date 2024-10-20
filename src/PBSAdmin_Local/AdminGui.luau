local ContextActionService = game:GetService("ContextActionService")
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
local UserInputService = game:GetService("UserInputService")

local gui = {}

export type CommandBar = Frame & {
	input: TextBox,
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
	cmd.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	cmd.BackgroundTransparency = 0.3
	cmd.Position = UDim2.new(0.5, 0, 0.5, 0)
	cmd.Size = UDim2.new(0.75, 0, 0.05, 0)
	cmd.Visible = false

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = cmd

	input.Name = "input"
	input.AnchorPoint = Vector2.new(0.5, 0)
	input.BackgroundTransparency = 1
	input.Position = UDim2.new(0.5, 0, 0, 0)
	input.Size = UDim2.new(1, -20, 1, 0)
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.Code
	input.ZIndex = 2
	input.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
	input.Text = ""
	input.RichText = true
	input.TextColor3 = Color3.new(1, 1, 1)
	input.TextSize = 14.000
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.Parent = cmd

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
	CleanUp.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	CleanUp.BackgroundTransparency = 0.3
	CleanUp.Image = "rbxasset://textures/RoduxDevtools/ClearList.png"
	UICorner:Clone().Parent = CleanUp
	CleanUp.Parent = OutputFrame

	BG.Name = "BG"
	BG.ZIndex = 0
	BG.Position = UDim2.fromScale(0, 1.5)
	BG.Visible = false
	UICorner:Clone().Parent = BG
	BG.Parent = cmd

	UIGradient.Color = ColorSequence.new(Color3.fromRGB(65, 65, 65))
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

local scrollDelta = 20 ^ -1
function gui.ScrollGui()
	local scr = Instance.new("ScreenGui")
	scr.Name = "PBSAdmin_LIST"

	local drag = Instance.new("TextButton")
	drag.BackgroundTransparency = 1
	drag.Size = UDim2.new(0, 385, 0, 20)
	drag.AutomaticSize = Enum.AutomaticSize.X
	drag.Position = UDim2.new(0.5, -200, 0.5, -200)
	drag.AutoButtonColor = false
	drag.Text = ""
	drag.Parent = scr
	Instance.new("UIDragDetector", drag)

	local main = Instance.new("Frame", drag)
	main.BackgroundColor3 = Color3.new(0, 0, 0)
	main.BackgroundTransparency = 0.3
	main.Size = UDim2.new(0, 0, 0, 400)
	main.AutomaticSize = Enum.AutomaticSize.X
	main.ZIndex = 7
	main.ClipsDescendants = true
	Instance.new("UICorner", main)

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = uiPadding.PaddingBottom
	uiPadding.PaddingRight = uiPadding.PaddingBottom
	uiPadding.PaddingTop = uiPadding.PaddingBottom
	uiPadding.Parent = main

	local cmf = Instance.new("Frame")
	cmf.AutomaticSize = Enum.AutomaticSize.X
	cmf.BackgroundTransparency = 1
	cmf.Position = UDim2.new(0, 0, 0, -9)
	cmf.ZIndex = 8
	cmf.Parent = main

	local down = Instance.new("ImageButton")
	down.Image = "http://www.roblox.com/asset/?id=108326725"
	down.BackgroundTransparency = 1
	down.Size = UDim2.new(0, 25, 0, 25)
	down.Position = UDim2.new(1, -20, 1, -20)
	down.ZIndex = 9
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
	cls.FontFace = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold)
	cls.TextSize = 18
	cls.Text = "X"
	cls.TextColor3 = Color3.new(1, 1, 1)
	cls.Parent = main

	local ent = Instance.new("TextLabel")
	ent.BackgroundTransparency = 1
	ent.FontFace = Font.new("rbxasset://fonts/families/Arimo.json")
	ent.TextSize = 18
	ent.ZIndex = 8
	ent.Text = ""
	ent.TextColor3 = Color3.new(1, 1, 1)
	ent.TextStrokeColor3 = Color3.new(0, 0, 0)
	ent.Size = UDim2.new(1, 0, 0, 18)
	ent.TextStrokeTransparency = 0.8
	ent.TextXAlignment = "Left"
	ent.TextYAlignment = "Top"

	cls.Activated:Connect(function(inputObject: InputObject, clickCount: number): ()
		scr:Destroy()
		ent:Destroy()
	end)

	local downv = false
	local upv = false

	local function frameDown()
		downv = true
		upv = false
		local pos = cmf.Position
		if pos.Y.Offset <= 371 - ((#cmf:GetChildren() - 1) * 20) then
			downv = false
			return
		end
		repeat
			pos += UDim2.new(0, 0, 0, -12)
			if pos.Y.Offset <= 371 - ((#cmf:GetChildren() - 1) * 20) then
				pos = UDim2.new(0, 0, 0, 371 - ((#cmf:GetChildren() - 1) * 20))
				downv = false
			end
			cmf:TweenPosition(pos, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, scrollDelta, true)
			task.wait(scrollDelta)
		until downv == false
	end
	local function frameUp()
		upv = true
		downv = false
		local pos = cmf.Position
		if pos.Y.Offset >= -9 then
			upv = false
			return
		end
		repeat
			pos += UDim2.new(0, 0, 0, 12)
			if pos.Y.Offset >= -9 then
				pos = UDim2.new(0, 0, 0, -9)
				upv = false
			end
			cmf:TweenPosition(pos, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, scrollDelta, true)
			task.wait(scrollDelta)
		until upv == false
	end

	down.MouseButton1Down:Connect(frameDown)
	down.MouseButton1Up:Connect(function(): ()
		downv = false
	end)

	up.MouseButton1Down:Connect(frameUp)
	up.MouseButton1Up:Connect(function(): ()
		upv = false
	end)

	local function handleInput(_, _, inputObject: InputObject): Enum.ContextActionResult?
		local pos = UserInputService:GetMouseLocation()
		if table.find(PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y), main) then
			if not (upv or downv) then
				if inputObject.Position.Z > 0 then
					frameUp()
				else
					frameDown()
				end
				task.delay(0.5, function()
					upv = false
					downv = false
				end)
			end
			return Enum.ContextActionResult.Sink
		end

		return Enum.ContextActionResult.Pass
	end
	ContextActionService:BindAction("SrollGui", handleInput, false, Enum.UserInputType.MouseWheel)

	main.Destroying:Connect(function()
		ContextActionService:UnbindAction("ScrollGui")
	end)

	return scr, cmf, ent, 0
end

return gui
