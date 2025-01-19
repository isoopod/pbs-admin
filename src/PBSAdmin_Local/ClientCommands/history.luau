-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local Players = game:GetService("Players")

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

local Bytenet = Utils.Bytenet

local function truncateString(str, maxLength, addEllipsis)
	if #str <= maxLength then
		return str
	else
		-- Truncate the string and add ellipsis if specified
		local truncation = string.sub(str, 1, maxLength)
		return addEllipsis and truncation .. "..." or truncation
	end
end

type HistoryEntry = {
	userid: number,
	timestamp: number,
	action: string,
	message: string,
	metadata: any?,
}

local usernameCache = {}
local function getUsername(userid: number): string
	if not usernameCache[userid] then
		local name = Players:GetNameFromUserIdAsync(userid)
		usernameCache[userid] = name and `{name}: ` or ``
	end
	return usernameCache[userid]
end

local function colorForAction(action: string): string
	local colors = {
		Placed = "#52c41d",
		Deleted = "#c41d1d",
		Configured = "#287ceb",
		Wired = "#e0ae19",
	}
	local color = colors[action] or "#fff"
	return `<font color="{color}">{action}</font>`
end

local function buildPage(logs: { HistoryEntry }, page: number, cmf: any, ent: any): ()
	page -= 1
	local c = page * 500 + 1

	for _, v: Instance in cmf:GetChildren() do
		if v.ClassName == "Frame" then v:Destroy() end
	end

	for i = #logs - page * 500, math.max(1, #logs - page * 500 - 499), -1 do
		local v = logs[i]

		local cl = ent:Clone()

		cl.Index.Text = c
		-- assemble the message
		local username = getUsername(v.userid)
		local action = colorForAction(v.action)
		cl.Content.Entry.RichText = true
		cl.Content.Entry.Text = truncateString(`{username}{action} {v.message}`, 128, true)
		cl.LayoutOrder = c
		cl.Name = string.lower(Utils.removeRichTextTags(cl.Content.Entry.Text))
		cl.Parent = cmf

		--TODO: Implement metadata on hover/click entries, for example highlight a placed part if it still exists, or placing a selectionbox where a part was deleted

		c += 1
	end
end

local function openLogs(logs: { HistoryEntry })
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_LIST_History") then
		local scr, cmf, ent = AdminGui.ScrollGui("History")

		local page = 1
		buildPage(logs, 1, cmf, ent)

		local topbar = cmf.Parent:FindFirstChildOfClass("Frame")
		if topbar then
			local left = Instance.new("ImageButton")
			left.Size = UDim2.fromOffset(20, 20)
			left.ImageContent = Content.fromAssetId(90247184996367)
			left.LayoutOrder = 2
			left.BackgroundTransparency = 1
			local right = left:Clone()
			right.ImageContent = Content.fromAssetId(119452792523645)
			right.LayoutOrder = 3

			left.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
			if page == math.ceil(#logs / 500) then right.ImageColor3 = Color3.new(0.5, 0.5, 0.5) end

			left.Activated:Connect(function()
				page = math.max(1, page - 1)
				buildPage(logs, page, cmf, ent)
				left.ImageColor3 = Color3.new(1, 1, 1)
				right.ImageColor3 = Color3.new(1, 1, 1)
				if page == 1 then left.ImageColor3 = Color3.new(0.5, 0.5, 0.5) end
			end)
			right.Activated:Connect(function()
				page = math.min(math.ceil(#logs / 500), page + 1)
				buildPage(logs, page, cmf, ent)
				left.ImageColor3 = Color3.new(1, 1, 1)
				right.ImageColor3 = Color3.new(1, 1, 1)
				if page == math.ceil(#logs / 500) then right.ImageColor3 = Color3.new(0.5, 0.5, 0.5) end
			end)

			left.Parent = topbar
			right.Parent = topbar
		end

		scr.Parent = script.Parent.Parent
	end
end

Bytenet.HISTORY.listen(function(data)
	openLogs(data)
end)
