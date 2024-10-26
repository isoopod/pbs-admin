-- This script is assinged to players with admin permissions to send them messages involving thier commands
-- Cannot actually do anything

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local keys = { Enum.KeyCode.BackSlash }

local AdminGui = require(script.Parent.AdminGui)

local cmd, suggestions = AdminGui.BakeCommandBar()
local input = cmd.input
cmd.Parent = script.Parent
local suggestionTemplate = suggestions.AutofillComponent
suggestionTemplate.Parent = nil
suggestions.Parent = script.Parent

local isMobile: ImageButton?

local remote: RemoteEvent = replicatedStorage:WaitForChild("PBSAdminRemote")
local get: RemoteFunction = replicatedStorage:WaitForChild("PBSAdminGetAutofill")

local responseTags = {
	'<font color="#ff3d3d">', -- error
	'<font color="#fff">', -- success
	'<font color="#6ec0ff">', -- confirmation request
	'<font color="#b0b0b0">', -- de-emphasis
	'<font color="#fbdc27">', -- warning
}
local LastResponseType = 1

-- build the autocomplete table
local autofill: { [string]: { string | { string } } }

local cmdHistory: { string } = {}
local historyI: number

-- These are commands we can do directly on the client without having to validate on the server
-- Use for harmless commands like the cmds list
local clientSideCommands = {
	cmds = function()
		if not script.Parent.Parent:FindFirstChild("PBSAdmin_CMDS") then
			local scr, cmf, ent, num = AdminGui.ScrollGui()
			scr.Name = "PBSAdmin_CMDS"

			local cmds = {}
			for i in autofill do
				if i ~= "Y" and i ~= "N" then
					table.insert(cmds, i)
				end
			end
			table.sort(cmds)

			for _, v in cmds do
				num += 1
				local cl = ent:Clone()

				-- formats the syntax table as a readable string
				local syntax = table.concat(
					(function()
						local formatted = {}
						for _, s in autofill[v] do
							table.insert(formatted, typeof(s) == "table" and `\{{table.concat(s, ", ")}\}` or `\{{s}\}`)
						end
						return formatted
					end)(),
					" "
				)
				cl.Text = `{num} {v} {syntax}`
				cl.Position = UDim2.fromOffset(0, num * 20)
				cl.Parent = cmf
			end

			scr.Parent = script.Parent.Parent
		end
	end,
}

local aliasMap = {
	cmds = clientSideCommands.cmds,
	commands = clientSideCommands.cmds,
}

function buildAutofill()
	autofill = {
		-- Y/N confirmation 'commands'
		["Y"] = {},
		["N"] = {},
	}

	for name, syntax in get:InvokeServer() do
		autofill[name] = syntax
	end

	for name in aliasMap do
		autofill[name] = {}
	end
end
buildAutofill()

cmd.OutputFrame.Cleanup.Activated:Connect(function()
	cmd.OutputFrame.Output.Text = ""
	cmd.OutputFrame.Visible = false
	input:CaptureFocus()
end)

input.FocusLost:Connect(function(enterPressed: boolean)
	if not enterPressed then
		return
	end

	local commandData = string.split(input.Text, " ")
	local command = commandData[1]
	table.remove(commandData, 1)
	if not aliasMap[command] then
		remote:FireServer(input.Text)
	else
		aliasMap[command](unpack(commandData))
		LastResponseType = 2
	end

	table.insert(cmdHistory, input.Text)
	historyI = #cmdHistory + 1
	input.Text = ""
	task.wait(0.1)
	if cmd.Visible then
		input:CaptureFocus()
	end
end)

local function timeNow(): string
	local dt = DateTime.now()
	return dt:FormatLocalTime("LTS", "en-us")
end

remote.OnClientEvent:Connect(function(response: number | string, body: string)
	if typeof(response) == "string" then
		buildAutofill()
	else
		cmd.OutputFrame.Output.Text = `{responseTags[4]}[{timeNow()}]:</font> {responseTags[response]}{body}</font>\n\n{cmd.OutputFrame.Output.Text}`
		if cmd.OutputFrame.Output.Text ~= "" then
			cmd.OutputFrame.Visible = true
		end
		LastResponseType = response
	end
end)

local function fuzzySearch(query: string, target: string): (number, boolean)
	-- Convert both query and target to lowercase for case-insensitive matching
	query = query:lower()
	target = target:lower()

	local queryLen = #query
	local targetLen = #target

	if queryLen == 0 then
		return 1, true
	end -- wildcard when query is empty
	if target:sub(1, 1) == "<" then
		return 0, false
	end -- remove pseudo-aliases

	-- Early exit if query is longer than target
	if queryLen > targetLen then
		return 0, false
	end

	local queryIndex = 1
	local matchCount = 0

	-- Loop through each character of the target string
	for targetIndex = 1, targetLen do
		if queryIndex <= queryLen and query:sub(queryIndex, queryIndex) == target:sub(targetIndex, targetIndex) then
			-- Character match found, move to the next query character
			queryIndex += 1
			matchCount += 1
		end
	end

	-- Check if all characters in the query were matched
	local matched = (queryIndex > queryLen)

	-- Similarity score based on number of matches and length of the target
	local score = matchCount / targetLen

	return score, matched
end

function closestMatch(inp: string, targets: { string }): { string }
	-- Only consider targets that start with inp
	local filteredTargets = {}
	for _, target in targets do
		target = tostring(target)
		if target:sub(1, #inp) == inp or inp == "" then
			table.insert(filteredTargets, target)
		end
	end

	if #filteredTargets == 0 then
		return { "" } -- No matching targets found
	end

	table.sort(filteredTargets, function(a, b)
		return fuzzySearch(inp, a) > fuzzySearch(inp, b)
	end)

	return filteredTargets
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
			userInputService.InputEnded:Wait()
			input:CaptureFocus()
			if isMobile then
				isMobile.Position = UDim2.fromScale(1, -0.45)
			end
		elseif isMobile then
			isMobile.Position = UDim2.fromScale(1, -0.95)
		end
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

local PALookup = {}
PALookup = {
	["<player>"] = function()
		local a = {}
		for _, p in Players:GetPlayers() do
			table.insert(a, p.Name)
			if not table.find(a, p.DisplayName) then
				table.insert(a, p.DisplayName) -- display names are not unique, and duplicates arent helpful
			end
		end
		table.insert(a, "me")
		return a
	end,
	["<player(s)>"] = function()
		local a = PALookup["<player>"]()
		table.insert(a, "all")
		table.insert(a, "others")
		table.insert(a, "team")
		return a
	end,
	["<player / #userid>"] = function()
		return PALookup["<player>"]()
	end,
	["<boolean>"] = function()
		return { "true", "false" }
	end,
}

local function processPsuedoAlias(alias: string | { string }, inp: string): string | { string }
	-- Show a (simplified) version of the psuedo-alias when the player starts typing the next value
	if alias == nil then
		return { "" }
	end
	if typeof(alias) == "table" then
		if inp == "" then
			return tostring(alias[1])
		end
		return alias
	end
	if inp == "" then
		return alias:gsub("<player%(s%)>", "<player>")
	end

	if PALookup[alias] then
		return PALookup[alias]()
	end

	return alias
end

local function trimBeforeLastNewline(inp: string): string
	local lastNewlineIndex = inp:match(".*()\n")
	if lastNewlineIndex then
		return inp:sub(lastNewlineIndex + 1)
	else
		return inp
	end
end

local function GetTextCursorAbsolutePosition(textbox: TextBox): Vector2
	local trimtext = string.sub(textbox.Text, 1, textbox.CursorPosition - 1)
	local textboundsY = TextService:GetTextSize(trimtext, textbox.TextSize, textbox.Font, textbox.AbsoluteSize)
	local lastline = trimBeforeLastNewline(trimtext)
	local textboundsX = TextService:GetTextSize(lastline, textbox.TextSize, textbox.Font, textbox.AbsoluteSize)
	return textbox.AbsolutePosition + Vector2.new(textboundsX.X, textboundsY.Y)
end

function getMaxWidth(strings: { string }, textLabel: TextLabel): number
	local maxWidth = 0

	local params = Instance.new("GetTextBoundsParams")
	params.Font = textLabel.FontFace
	params.Size = textLabel.TextSize
	params.Width = math.huge
	for _, v in strings do
		params.Text = v
		local bounds = TextService:GetTextBoundsAsync(params)
		if bounds.X > maxWidth then
			maxWidth = bounds.X
		end
	end

	return maxWidth
end

input:GetPropertyChangedSignal("Text"):Connect(function()
	local plainText = input.Text:gsub("<[^>]+>", "") -- clear rich text formatting
	if checkKeyMatches(plainText) then
		input:ReleaseFocus(false)
		openConsole(nil, Enum.UserInputState.Begin)
	end

	-- Generate autofill
	local words = string.split(plainText, " ")
	local len = #words

	-- fill autofill with the rest of the command thats already been written
	local prediciton = `{table.concat(words, " ", 1, len - 1)}{len > 1 and " " or ""}`
	local entries = { "" }

	local alias = autofill[words[1]]
	if alias and len > 1 then
		-- suggest the argument closest to whatever is currently written
		local targets = processPsuedoAlias(alias[len - 1], words[len])
		if len == 2 then
			if typeof(targets) == "string" then
				targets = { targets }
			end
			table.insert(targets, "-help")
		end

		if targets then
			if typeof(targets) == "string" and targets ~= "any" then
				entries = closestMatch(words[len], { targets })
			elseif typeof(targets) == "table" then
				entries = closestMatch(words[len], targets)
			end
		end
	elseif words[1] then
		-- suggest the command closest to whatever is currently input
		local targets = {}
		for i in autofill do
			if (i == "Y" or i == "N") and LastResponseType ~= 3 then
				continue
			end
			table.insert(targets, i)
		end
		entries = closestMatch(words[1], targets)
	end

	prediciton ..= entries[1]

	local cursorCorner = GetTextCursorAbsolutePosition(input) + Vector2.new(10, -cmd.AbsoluteSize.Y * 0.5)
	local width = getMaxWidth(entries, suggestionTemplate)
	suggestions.Position = UDim2.fromOffset(cursorCorner.X, cursorCorner.Y)
	suggestions.Size = UDim2.fromOffset(width, #entries * 20)
	if entries[1] ~= "" and not isMobile then
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
			end
			entry.Text = v
			entry.LayoutOrder = i
			entry.Parent = suggestions
		end
	else
		suggestions.Visible = false
	end

	cmd.autofill.Text = prediciton

	--Lint command
end)

userInputService.InputBegan:Connect(function(_inputObject: InputObject)
	if cmd.Visible then
		-- Navigate up in command history
		if _inputObject.KeyCode == Enum.KeyCode.Up and #cmdHistory > 0 then
			historyI = math.clamp(historyI - 1, 1, #cmdHistory + 1)
			input.Text = cmdHistory[historyI]
			input.CursorPosition = (utf8.len(input.Text) or 0) + 1
			input:CaptureFocus()
		-- Navigate down in command history
		elseif _inputObject.KeyCode == Enum.KeyCode.Down and #cmdHistory > 0 then
			historyI = math.clamp(historyI + 1, 1, #cmdHistory + 1)
			if historyI > #cmdHistory then
				input.Text = ""
			else
				input.Text = cmdHistory[historyI]
			end
			input.CursorPosition = (utf8.len(input.Text) or 0) + 1
			input:CaptureFocus()
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
contextActionService:BindAction("openPBSAdminConsole", openConsole, true, unpack(keys))
contextActionService:SetPosition("openPBSAdminConsole", UDim2.fromScale(0.7, -0.45))
contextActionService:SetImage("openPBSAdminConsole", "rbxassetid://98927197503750")

-- If the button is made that means that the user is on mobile.
-- We should apply some changes so it is easier to use the command bar on mobile
isMobile = contextActionService:GetButton("openPBSAdminConsole")
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
