-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

-- bytenet integration
local Bytenet = Utils.Bytenet

local remote: RemoteEvent
if not Bytenet then remote = ReplicatedStorage:WaitForChild("PBSADMIN_HISTORY") end

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

local function openLogs(logs: { HistoryEntry })
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_LIST_History") then
		local scr, cmf, ent = AdminGui.ScrollGui("History")

		local c = 1
		for i = #logs, 1, -1 do
			local v = logs[i]

			local cl = ent:Clone()

			cl.Index.Text = c
			-- assemble the message
			local username = getUsername(v.userid)
			local action = colorForAction(v.action)
			cl.Content.Entry.RichText = true
			cl.Content.Entry.Text = truncateString(`{username}{action} {v.message}`, 128, true)
			cl.LayoutOrder = c
			cl.Name = Utils.removeRichTextTags(cl.Content.Entry.Text)
			cl.Parent = cmf

			c += 1
		end
		--TODO: Implement metadata on hover/click entries, for example highlight a placed part if it still exists, or placing a selectionbox where a part was deleted

		scr.Parent = script.Parent.Parent
	end
end

if Bytenet then
	Bytenet.HISTORY.listen(function(data)
		openLogs(data)
	end)
else
	remote.OnClientEvent:Connect(function(...)
		openLogs(...)
	end)
end
