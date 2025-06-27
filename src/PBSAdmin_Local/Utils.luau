local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local api = {}

function api.trimBeforeLastNewline(inp: string): string
	local lastNewlineIndex = inp:match(".*()\n")
	if lastNewlineIndex then
		return inp:sub(lastNewlineIndex + 1)
	else
		return inp
	end
end

function api.filter<T>(t: { T }, comp: (T) -> boolean): { T }
	local filtered = {}
	for _, v in t do
		if comp(v) then table.insert(filtered, v) end
	end
	return filtered
end

function api.timeNow(): string
	local dt = DateTime.now()
	return dt:FormatLocalTime("LTS", "en-us")
end

function api.fuzzySearch(query: string, target: string): (number, boolean)
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

function api.closestMatch(inp: string, targets: { string }): { string }
	-- Only consider targets that start with inp
	local filteredTargets = {}
	for _, target in targets do
		target = tostring(target)
		if target:sub(1, #inp) == inp or inp == "" then table.insert(filteredTargets, target) end
	end

	if #filteredTargets == 0 then
		return { "" } -- No matching targets found
	end

	table.sort(filteredTargets, function(a, b)
		return api.fuzzySearch(inp, a) > api.fuzzySearch(inp, b)
	end)

	return filteredTargets
end

function api.GetTextCursorAbsolutePosition(textbox: TextBox): Vector2
	local trimtext = string.sub(textbox.Text, 1, textbox.CursorPosition - 1)
	local textboundsY = TextService:GetTextSize(trimtext, textbox.TextSize, textbox.Font, textbox.AbsoluteSize)
	local lastline = api.trimBeforeLastNewline(trimtext)
	local textboundsX = TextService:GetTextSize(lastline, textbox.TextSize, textbox.Font, textbox.AbsoluteSize)
	return textbox.AbsolutePosition + Vector2.new(textboundsX.X, textboundsY.Y)
end

function api.getMaxWidth(strings: { string }, textLabel: TextLabel): number
	local maxWidth = 0

	local params = Instance.new("GetTextBoundsParams")
	params.Font = textLabel.FontFace
	params.Size = textLabel.TextSize
	params.Width = math.huge
	for _, v in strings do
		params.Text = v
		local bounds = TextService:GetTextBoundsAsync(params)
		if bounds.X > maxWidth then maxWidth = bounds.X end
	end

	return maxWidth
end

-- For handling a or an in a string
function api.aOrAn(word: string): string
	if word == "Trusted" then return "" end
	local vowels = { "a", "e", "i", "o", "u" }
	local firstChar = word:sub(1, 1):lower()

	for _, vowel in vowels do
		if firstChar == vowel then return "an " end
	end
	return "a "
end

local roleColors = {
	Banned = "'#b8b8b8'",
	Visitor = "'#ffffff'",
	Member = "'#efb838'",
	Trusted = "'#04afec'",
	Admin = "'#aa00aa'",
	Owner = "'#ff0000'",
}
function api.ColorTextForRole(text: string, role: string): string
	return `<font color={roleColors[role]}>{text}</font>`
end

function api.stringEscapeRichText(s: string): string
	s = string.gsub(s, "&", "&amp;") -- (must do & first)
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, '"', "&quot;")
	s = string.gsub(s, "'", "&apos;")
	return s
end

function api.removeRichTextTags(input: string): string
	return input:gsub("<[^>]+>", "")
end

-- PakNet integration
if ReplicatedStorage:FindFirstChild("PBSReplicated") then
	if ReplicatedStorage.PBSReplicated.Utils.PakNetSchemas:FindFirstChild("PBSAdminPackets") then
		api.PakNet = require(ReplicatedStorage.PBSReplicated.Utils.PakNetSchemas.PBSAdminPackets)
	end
end

return api
