-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

-- bytenet integration
local Bytenet = Utils.Bytenet

local remote: RemoteEvent
if not Bytenet then remote = ReplicatedStorage:WaitForChild("PBSADMIN_LOGS") end

local function truncateString(str, maxLength, addEllipsis)
	if #str <= maxLength then
		return str
	else
		-- Truncate the string and add ellipsis if specified
		local truncation = string.sub(str, 1, maxLength)
		return addEllipsis and truncation .. "..." or truncation
	end
end

local function openLogs(logs: { string })
	if not script.Parent.Parent:FindFirstChild("PBSAdmin_LIST_Logs") then
		local scr, cmf, ent = AdminGui.ScrollGui("Logs")

		for i, v in logs do
			local cl = ent:Clone()

			cl.Index.Text = tostring(i)
			cl.Content.Entry.Text = truncateString(v, 128, true)
			cl.LayoutOrder = i
			cl.Parent = cmf
		end
		scr.Parent = script.Parent.Parent
	end
end

if Bytenet then
	Bytenet.LOGS.listen(function(data)
		openLogs(data)
	end)
else
	remote.OnClientEvent:Connect(function(...)
		openLogs(...)
	end)
end
