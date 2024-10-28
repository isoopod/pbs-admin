-- This script is assinged to players with admin permissions to send them messages involving thier commands
-- Cannot actually do anything

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer
local keys = { Enum.KeyCode.BackSlash } -- The first key in this array is the one the user will be told to press to open the console

local AdminGui = require(script.Parent.AdminGui)
local Autofill = require(script.Parent.Autofill)
local ClientCommands = require(script.Parent.ClientCommands)
local PsuedoAlias = require(script.Parent.PsuedoAlias)
local Utils = require(script.Parent.Utils)

-- Initialize the client commands
for _, v in script.Parent.ClientCommands:GetChildren() do
	if v:IsA("ModuleScript") then
		pcall(require, v)
	end
end

-- Tell the player their rank
-- NOTE: This relies on the 'leaderstats' attribute being enabled
task.spawn(function()
	local leaderstats = Player:WaitForChild("leaderstats", 1)
	if leaderstats then
		local role: StringValue? = leaderstats:WaitForChild("Role", 1)
		if role then
			local message = if role.Value == ""
				then `This place uses PBS Admin. Press {keys[1].Name} to open the console.`
				else `You're a{Utils.vowelPrefix(role.Value)} {Utils.ColorTextForRole(role.Value .. "!", role.Value)}\n\nPress <font color='#ffcc55'>{keys[1].Name}</font> to open the console.`
			AdminGui.message("<font color='#ff0000'>[SYSTEM]</font>", message)
		end
	end
end)

local cmd, suggestions = AdminGui.BakeCommandBar()
local input = cmd.input
cmd.Parent = script.Parent

local suggestionTemplate = suggestions.AutofillComponent
suggestionTemplate.Parent = nil
suggestions.Parent = script.Parent

local isMobile: ImageButton?

-- bytenet integration
local Bytenet = Utils.Bytenet

local remote: RemoteEvent?
if not Bytenet then
	remote = ReplicatedStorage:WaitForChild("PBSAdminRemote")
end

local responseTags = {
	'<font color="#ff3d3d">', -- error
	'<font color="#fff">', -- success
	'<font color="#6ec0ff">', -- confirmation request
	'<font color="#b0b0b0">', -- de-emphasis
	'<font color="#fbdc27">', -- warning
}
local LastResponseType = 1

local cmdHistory: { string } = {}
local historyI: number

local currentSuggestion: number?

Autofill.buildAutofill()

cmd.OutputFrame.Cleanup.Activated:Connect(function()
	cmd.OutputFrame.Output.Text = ""
	cmd.OutputFrame.Visible = false
	input:CaptureFocus()
end)

function commandResponse(response: number, body: string): ()
	cmd.OutputFrame.Output.Text = `{responseTags[4]}[{Utils.timeNow()}]:</font> {responseTags[response]}{body}</font>\n\n{cmd.OutputFrame.Output.Text}`
	if cmd.OutputFrame.Output.Text ~= "" then
		cmd.OutputFrame.Visible = true
	end
	LastResponseType = response
end

input.FocusLost:Connect(function(enterPressed: boolean)
	if not enterPressed then
		return
	end

	local commandData = string.split(input.Text, " ")
	local command = commandData[1]
	table.remove(commandData, 1)
	if not ClientCommands.cmdData[command] then
		if Bytenet then
			Bytenet.ExecuteCommand.send(input.Text)
		elseif remote then
			remote:FireServer(input.Text)
		end
	else
		local clientCmd = ClientCommands.cmdData[command]
		commandResponse(clientCmd(unpack(commandData)))
	end

	table.insert(cmdHistory, input.Text)
	historyI = #cmdHistory + 1
	input.Text = ""
	task.wait(0.1)
	if cmd.Visible then
		input:CaptureFocus()
	end
end)

if Bytenet then
	Bytenet.CommandReturn.listen(function(data)
		commandResponse(data.response, data.body)
	end)
elseif remote then
	remote.OnClientEvent:Connect(function(response: number, body: string)
		commandResponse(response, body)
	end)
end

local function openConsole(_, inputState: Enum.UserInputState, _inputObject: InputObject?)
	if cmd.Visible and _inputObject and (_inputObject.KeyCode == Enum.KeyCode.Up or _inputObject.KeyCode == Enum.KeyCode.Down) then
		return Enum.ContextActionResult.Sink
	end
	if inputState == Enum.UserInputState.Begin then
		input:ReleaseFocus(false)
		cmd.Visible = not cmd.Visible
		if not cmd.Visible then
			suggestions.Visible = false
		end
		if cmd.Visible then
			input.Text = ""
			cmd.autofill.Text = ""
			UserInputService.InputEnded:Wait()
			input:CaptureFocus()
			if isMobile then
				isMobile.Position = UDim2.fromScale(1, -0.45)
			end
		elseif isMobile then
			isMobile.Position = UDim2.fromScale(1, -0.95)
		end
		currentSuggestion = nil
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function checkKeyMatches(text: string): boolean
	for _, v in keys do
		if v == Enum.KeyCode.Up or v == Enum.KeyCode.Down then
			continue
		end
		local key = string.char(v.Value)
		if text:match(key) then
			return true
		end
	end
	return false
end

input:GetPropertyChangedSignal("Text"):Connect(function()
	if checkKeyMatches(input.Text) then
		input:ReleaseFocus(false)
		openConsole(nil, Enum.UserInputState.Begin)
	end
	-- Generate autofill
	local words = string.split(input.Text, " ")
	local len = #words

	-- fill autofill with the rest of the command thats already been written
	local prediciton = `{table.concat(words, " ", 1, len - 1)}{len > 1 and " " or ""}`
	local entries = { "" }

	local alias = Autofill.autofill[words[1]] or {}
	if alias and len > 1 then
		-- suggest the argument closest to whatever is currently written
		local targets = PsuedoAlias.processPsuedoAlias(alias[len - 1], words[len])
		if len == 2 then
			if type(targets) == "string" then
				targets = { targets }
			end
			-- add -help to the first parameter
			table.insert(targets, "-help")
		end

		if targets then
			if type(targets) == "string" and targets ~= "any" then
				entries = Utils.closestMatch(words[len], { targets })
			elseif type(targets) == "table" then
				entries = Utils.closestMatch(words[len], targets)
			end
		end
	elseif words[1] and words[1] ~= "" then
		-- suggest the command closest to whatever is currently input
		local targets = {}
		for i in Autofill.autofill do
			if (i == "Y" or i == "N") and LastResponseType ~= 3 then
				continue
			end
			table.insert(targets, i)
		end
		entries = Utils.closestMatch(words[1], targets)
	end

	prediciton ..= entries[1]

	-- Filter out any psuedo-aliases for the suggestions box
	entries = Utils.filter(entries, function(entry: string): boolean
		return entry:match("^<.+>$") == nil
	end)

	local cursorCorner = Utils.GetTextCursorAbsolutePosition(input) + Vector2.new(10, -cmd.AbsoluteSize.Y * 0.5)
	local width = Utils.getMaxWidth(entries, suggestionTemplate)
	suggestions.Position = UDim2.fromOffset(cursorCorner.X, cursorCorner.Y)
	suggestions.Size = UDim2.fromOffset(width, #entries * 20)

	currentSuggestion = nil

	if words[len] ~= "" and entries[1] ~= "" and not isMobile then
		if not (#entries == 1 and words[len] == entries[1]) then
			for _, v in suggestions:GetChildren() do
				if v:IsA("TextLabel") then
					v:Destroy()
				end
			end
			suggestions.Visible = true

			for i, v in entries do
				local entry = suggestionTemplate:Clone()
				if i == 1 then
					entry.BackgroundTransparency = 0
					currentSuggestion = 1
				end
				entry.Text = v
				entry.LayoutOrder = i
				entry.Parent = suggestions
			end
		else
			suggestions.Visible = false
		end
	else
		suggestions.Visible = false
	end

	cmd.autofill.Text = prediciton

	--Lint command
	local reconstructedInput = {}

	for i, v in words do
		-- Disregard the last word if the user is not done writing it
		if words[len] == v and not (words[len] == entries[1]) and entries[1] ~= "" then
			table.insert(reconstructedInput, Utils.stringEscapeRichText(v))
		else
			local syntax = i == 1 and Autofill.autofill or alias[i - 1]

			-- Some commands allow for variadics at the end of the command.
			-- Find the highest syntax that isn't nil
			while syntax == nil and i > 1 do
				i -= 1
				syntax = alias[i - 1] -- Move up the alias list until a valid syntax is found
			end

			-- Check if the syntax is a string and begins with "<"
			if type(syntax) == "string" and syntax:sub(1, 4) == "<..." then
				-- Remove the "..." from the syntax to get the current syntax
				syntax = syntax:gsub("%.+", "")
			end
			if PsuedoAlias.lintParamerter(syntax, v) then
				table.insert(reconstructedInput, Utils.stringEscapeRichText(v))
			else
				table.insert(reconstructedInput, `{responseTags[1]}<u>{Utils.stringEscapeRichText(v)}</u></font>`)
			end
		end
	end

	cmd.inputDisplay.Text = table.concat(reconstructedInput, " ")
end)

local function navigateSuggestions(up: boolean): boolean
	if currentSuggestion then
		local newSuggestion = math.clamp(currentSuggestion + (up and -1 or 1), 1, #suggestions:GetChildren() - 4)
		if newSuggestion ~= currentSuggestion then
			currentSuggestion = newSuggestion
			-- Handle highlighting
			local totalSuggestions = #suggestions:GetChildren() - 4
			local displayRange = 5 -- Number of suggestions to display at once
			local halfRange = displayRange // 2

			for _, v in suggestions:GetChildren() do
				if v:IsA("TextLabel") then
					-- Determine the visibility range based on the current suggestion's position
					local lowerBound, upperBound

					if currentSuggestion <= halfRange + 1 then
						-- Near the start: show the first `displayRange` suggestions
						lowerBound = 1
						upperBound = displayRange
					elseif currentSuggestion >= totalSuggestions - halfRange then
						-- Near the end: show the last `displayRange` suggestions
						lowerBound = totalSuggestions - displayRange + 1
						upperBound = totalSuggestions
					else
						-- Middle: centre `currentSuggestion` with `displayRange` around it
						lowerBound = currentSuggestion - halfRange
						upperBound = currentSuggestion + halfRange
					end

					-- Toggle visibility and highlight current suggestion
					if v.LayoutOrder >= lowerBound and v.LayoutOrder <= upperBound then
						v.Visible = true
						if v.LayoutOrder == currentSuggestion then
							-- Set this suggestion as highlighted
							cmd.autofill.Text = cmd.autofill.Text:gsub("%S+$", v.Text)
							v.BackgroundTransparency = 0
						else
							-- Set this suggestion as not highlighted
							v.BackgroundTransparency = 1
						end
					else
						-- Hide suggestions outside the visible range
						v.Visible = false
					end
				end
			end
		end
		return true
	end
	return false
end

UserInputService.InputBegan:Connect(function(_inputObject: InputObject)
	if cmd.Visible then
		-- Navigate up in command history or suggestions
		if _inputObject.KeyCode == Enum.KeyCode.Up then
			if not navigateSuggestions(true) and #cmdHistory > 0 then
				historyI = math.clamp(historyI - 1, 1, #cmdHistory + 1)
				input.Text = cmdHistory[historyI]
				input.CursorPosition = (utf8.len(input.Text) or 0) + 1
				input:CaptureFocus()
			end
		-- Navigate down in command history or suggestions
		elseif _inputObject.KeyCode == Enum.KeyCode.Down then
			if not navigateSuggestions(false) and #cmdHistory > 0 then
				historyI = math.clamp(historyI + 1, 1, #cmdHistory + 1)
				if historyI > #cmdHistory then
					input.Text = ""
				else
					input.Text = cmdHistory[historyI]
				end
				input.CursorPosition = (utf8.len(input.Text) or 0) + 1
				input:CaptureFocus()
			end
		-- Autocomplete
		elseif _inputObject.KeyCode == Enum.KeyCode.Tab and (#input.Text < #cmd.autofill.Text:gsub("<[^>]+>", "")) then
			local text = cmd.autofill.Text
			RunService.PreRender:Wait()
			input.Text = text
			input.CursorPosition = (utf8.len(input.Text) or 0) + 1
		end
	end
end)

-- This just sinks the up and down arrows if the command bar is open
table.insert(keys, Enum.KeyCode.Up)
table.insert(keys, Enum.KeyCode.Down)
ContextActionService:BindAction("openPBSAdminConsole", openConsole, true, unpack(keys))
ContextActionService:SetPosition("openPBSAdminConsole", UDim2.fromScale(0.7, -0.45))
ContextActionService:SetImage("openPBSAdminConsole", "rbxassetid://98927197503750")

-- If the button is made that means that the user is on mobile.
-- We should apply some changes so it is easier to use the command bar on mobile
isMobile = ContextActionService:GetButton("openPBSAdminConsole")
if isMobile then
	local CAS_CONTAINER = isMobile:FindFirstAncestorWhichIsA("ScreenGui")
	-- Will probably break some other context button positioning but worth it.
	-- This is the best way to get context buttons in the topbar
	if CAS_CONTAINER then
		CAS_CONTAINER.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end
	cmd.Size = UDim2.new(0.75, 0, 0, isMobile.AbsoluteSize.Y)
	cmd.Position = UDim2.new(0.45, 0, 0, isMobile.AbsolutePosition.Y + isMobile.AbsoluteSize.Y / 2)
	isMobile.AnchorPoint = Vector2.new(1, 0)
	isMobile.Position = UDim2.fromScale(1, -0.95)
end
