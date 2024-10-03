-- This script is assinged to players with admin permissions to send them messages involving thier commands
-- Cannot actually do anything

local replicatedStorage = game:GetService("ReplicatedStorage")
local contextActionService = game:GetService("ContextActionService")
local userInputService = game:GetService("UserInputService")
local keys = { Enum.KeyCode.Quote, Enum.KeyCode.QuotedDouble }

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

input.FocusLost:Connect(function(enterPressed: boolean)
	if not enterPressed then
		return
	end
	cmd.Output.Text = ""

	local commandData = string.split(input.Text, " ")
	local command = commandData[1]
	table.remove(commandData, 1)
	if not aliasMap[command] then
		remote:FireServer(input.Text)
	else
		aliasMap[command](unpack(commandData))
		-- does not support output information
		cmd.Output.Text = ""
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

remote.OnClientEvent:Connect(function(response: number | string, body: string)
	if typeof(response) == "string" then
		buildAutofill()
	else
		cmd.Output.Text = responseTags[response] .. body .. "</font>"
		LastResponseType = response
	end
end)

-- gets the 'distance' between two strings
function levenshteinDistance(str1: string, str2: string): number
	local len1, len2 = #str1, #str2
	local matrix = {}
	for i = 0, len1 do
		matrix[i] = { [0] = i }
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end
	for i = 1, len1 do
		for j = 1, len2 do
			local cost = str1:sub(i, i) == str2:sub(j, j) and 0 or 1
			matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
		end
	end
	return matrix[len1][len2]
end

function closestMatch(input: string, targets: { string }): string
	-- Only consider targets that start with input
	local filteredTargets = {}
	for _, target in targets do
		if typeof(target) ~= "string" then
			print(target, targets, autofill)
		end
		if target:sub(1, #input) == input then
			table.insert(filteredTargets, target)
		end
	end

	if #filteredTargets == 0 then
		return "" -- No matching targets found
	end

	local minDistance = math.huge
	local closest
	for _, target in filteredTargets do
		local distance = levenshteinDistance(input, target)
		if distance < minDistance then
			minDistance = distance
			closest = target
		end
	end
	return closest
end

local function openConsole(_, inputState: Enum.UserInputState, _inputObject: InputObject?)
	if
		cmd.Visible
		and _inputObject
		and (_inputObject.KeyCode == Enum.KeyCode.Up or _inputObject.KeyCode == Enum.KeyCode.Down)
	then
		return Enum.ContextActionResult.Sink
	end
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
	local words = string.split(input.Text, " ")
	local len = table.maxn(words)

	-- fill the rest of the command thats already been written
	local prediciton = ""
	for i = 1, len - 1 do
		prediciton ..= words[i] .. " "
	end

	local alias = autofill[words[1]]
	if alias and len > 1 then
		-- suggest the argument closest to whatever is currently written
		local targets = alias[len - 1]
		if targets then
			if typeof(targets) == "string" and targets ~= "any" then
				prediciton ..= closestMatch(words[len], table.pack(targets))
			elseif typeof(targets) == "table" then
				prediciton ..= closestMatch(words[len], targets)
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
		prediciton ..= closestMatch(words[1], targets)
	end

	cmd.autofill.Text = prediciton
end)

userInputService.InputBegan:Connect(function(_inputObject: InputObject)
	if cmd.Visible then
		if _inputObject.KeyCode == Enum.KeyCode.Up and #cmdHistory > 0 then
			historyI = math.clamp(historyI - 1, 1, #cmdHistory + 1)
			input.Text = cmdHistory[historyI]
			input:CaptureFocus()
		elseif _inputObject.KeyCode == Enum.KeyCode.Down and #cmdHistory > 0 then
			historyI = math.clamp(historyI + 1, 1, #cmdHistory + 1)
			if historyI > #cmdHistory then
				input.Text = ""
			else
				input.Text = cmdHistory[historyI]
			end
			input:CaptureFocus()
		end
	end
end)

table.insert(keys, Enum.KeyCode.Up)
table.insert(keys, Enum.KeyCode.Down)
contextActionService:BindAction("openPBSAdminConsole", openConsole, true, table.unpack(keys))
