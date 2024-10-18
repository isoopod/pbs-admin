-- This script is assinged to players with admin permissions to send them messages involving thier commands
-- Cannot actually do anything

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local keys = { Enum.KeyCode.BackSlash }

local AdminGui = require(script.Parent.AdminGui)

local cmd = AdminGui.BakeCommandBar()
local input = cmd.input
cmd.Parent = script.Parent

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
				if i ~= "Y" and i ~= "N" then table.insert(cmds, i) end
			end
			table.sort(cmds)

			for _, v in cmds do
				num += 1
				local cl = ent:Clone()

				-- formats the syntax table as a readable string
				local syntax = table.concat(
					(function()
						local formatted = {}
						for _, v in autofill[v] do
							table.insert(formatted, typeof(v) == "table" and `\{{table.concat(v, ", ")}\}` or `\{{v}\}`)
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
	if not enterPressed then return end

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
	if cmd.Visible then input:CaptureFocus() end
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
		if cmd.OutputFrame.Output.Text ~= "" then cmd.OutputFrame.Visible = true end
		LastResponseType = response
	end
end)

local function fuzzySearch(query: string, target: string): (number, boolean)
	-- Convert both query and target to lowercase for case-insensitive matching
	query = query:lower()
	target = target:lower()

	local queryLen = #query
	local targetLen = #target

	if queryLen == 0 then return 1, true end -- wildcard when query is empty
	if target:sub(1, 1) == "<" then return 0, false end -- remove pseudo-aliases

	-- Early exit if query is longer than target
	if queryLen > targetLen then return 0, false end

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

function closestMatch(input: string, targets: { string }): string
	-- Only consider targets that start with input
	local filteredTargets = {}
	for _, target in targets do
		target = tostring(target)
		if target:sub(1, #input) == input or input == "" then table.insert(filteredTargets, target) end
	end

	if #filteredTargets == 0 then
		return "" -- No matching targets found
	end

	local maxScore = 0
	local closest = ""
	for _, target in filteredTargets do
		local score = fuzzySearch(input, target)
		if score > maxScore then
			maxScore = score
			closest = target
		end
	end
	return closest
end

local function openConsole(_, inputState: Enum.UserInputState, _inputObject: InputObject?)
	if cmd.Visible and _inputObject and (_inputObject.KeyCode == Enum.KeyCode.Up or _inputObject.KeyCode == Enum.KeyCode.Down) then return Enum.ContextActionResult.Sink end
	if inputState == Enum.UserInputState.Begin then
		input:ReleaseFocus(false)
		cmd.Visible = not cmd.Visible
		if cmd.Visible then
			input.Text = ""
			cmd.autofill.Text = ""
			task.wait(0.1)
			input:CaptureFocus()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function checkKeyMatches(text: string): boolean
	for _, v in keys do
		if v == Enum.KeyCode.Up or v == Enum.KeyCode.Down then continue end
		local key = string.char(v.Value)
		if text:match(key) then return true end
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

local function processPsuedoAlias(alias: string | { string }, input: string): string | { string }
	-- Show a (simplified) version of the psuedo-alias when the player starts typing the next value
	if alias == nil then return { "" } end
	if typeof(alias) == "table" then
		if input == "" then return tostring(alias[1]) end
		return alias
	end
	if input == "" then return alias:gsub("<player%(s%)>", "<player>") end

	if PALookup[alias] then return PALookup[alias]() end

	return alias
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

	local alias = autofill[words[1]]
	if alias and len > 1 then
		-- suggest the argument closest to whatever is currently written
		local targets = processPsuedoAlias(alias[len - 1], words[len])
		if len == 2 then
			if typeof(targets) == "string" then targets = { targets } end
			table.insert(targets, "-help")
		end

		if targets then
			if typeof(targets) == "string" and targets ~= "any" then
				prediciton ..= closestMatch(words[len], { targets })
			elseif typeof(targets) == "table" then
				prediciton ..= closestMatch(words[len], targets)
			end
		end
	elseif words[1] then
		-- suggest the command closest to whatever is currently input
		local targets = {}
		for i in autofill do
			if (i == "Y" or i == "N") and LastResponseType ~= 3 then continue end
			table.insert(targets, i)
		end
		prediciton ..= closestMatch(words[1], targets)
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

-- This just sinsk the input
table.insert(keys, Enum.KeyCode.Up)
table.insert(keys, Enum.KeyCode.Down)
contextActionService:BindAction("openPBSAdminConsole", openConsole, true, unpack(keys))
