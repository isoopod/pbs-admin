local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local AdminGui = require(script.Parent.Parent.AdminGui)
local autofill = require(script.Parent.Parent.Autofill)
local cmd = require(script.Parent)

local Arimo = Font.new("rbxasset://fonts/families/Arimo.json")

local boundsParams = Instance.new("GetTextBoundsParams")
boundsParams.Font = Arimo

cmd.register({ "cmds", "commands" }, {}, "Shows a list of all usable commands", function()
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_LIST_Commands") then
		local scr, cmf, ent = AdminGui.ScrollGui("Commands")
		local num = 1

		local commands = autofill.getVerboseAutofill()

		local cmds = {}
		for k in commands do
			table.insert(cmds, k)
		end
		table.sort(cmds)

		local maxWidth = 0
		boundsParams.Size = 18
		boundsParams.RichText = false
		boundsParams.Width = math.huge

		for _, k in cmds do
			local cl = ent:Clone()

			-- formats the syntax table as a readable string
			local syntax = table.concat(
				(function()
					local formatted = {}
					for _, s in commands[k].syntax do
						table.insert(formatted, typeof(s) == "table" and `\{{table.concat(s, ", ")}\}` or `\{{s}\}`)
					end
					return formatted
				end)(),
				" "
			)

			cl.Index.Text = tostring(num)
			cl.Content.Entry.Text = `{k} {syntax}`
			cl.Name = k
			cl.LayoutOrder = num
			cl.Parent = cmf

			-- Create the expandable help section
			boundsParams.Text = cl.Content.Entry.Text
			maxWidth = math.max(TextService:GetTextBoundsAsync(boundsParams).X, maxWidth)

			num += 1
		end

		boundsParams.Size = 16
		boundsParams.RichText = true
		boundsParams.Width = maxWidth
		for _, cl in cmf:GetChildren() do
			if cl:IsA("Frame") then
				-- Create the expandable help section
				local help = Instance.new("TextLabel")
				help.Size = UDim2.fromOffset(maxWidth, 0)
				help.BackgroundTransparency = 1
				help.FontFace = Font.new("rbxasset://fonts/families/Arimo.json")
				help.TextSize = 17
				help.TextWrapped = true
				help.RichText = true
				help.Position = UDim2.fromOffset(0, 20)
				help.TextColor3 = Color3.new(1, 1, 1)
				help.TextXAlignment = Enum.TextXAlignment.Left
				help.TextYAlignment = Enum.TextYAlignment.Top
				help.Text = commands[cl.Name].help
				help.Parent = cl.Content

				-- Create the expand/collapse button and handle input
				boundsParams.Text = help.Text
				local expandedHeight = TextService:GetTextBoundsAsync(boundsParams).Y

				local expand = Instance.new("ImageButton")
				expand.Image = "rbxassetid://111731667038016"
				expand.BackgroundTransparency = 1
				expand.Size = UDim2.fromOffset(20, 20)
				expand.Position = UDim2.fromScale(1, 0)
				expand.Activated:Connect(function()
					if expand.Rotation == 90 then
						expand.Rotation = 0
						TweenService:Create(help, TweenInfo.new(0.5), { Size = UDim2.fromOffset(maxWidth, 0) }):Play()
					else
						expand.Rotation = 90
						TweenService:Create(help, TweenInfo.new(0.5), { Size = UDim2.fromOffset(maxWidth, expandedHeight) }):Play()
					end
				end)
				expand.Parent = cl.Content.Entry
			end
		end

		scr.Parent = script.Parent.Parent
	end
	return cmd.Responses.Success, "Opened commands menu"
end)

return nil
