-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

-- bytenet integration
local Bytenet = Utils.Bytenet

local remote: RemoteEvent
if not Bytenet then remote = ReplicatedStorage:WaitForChild("PBSADMIN_HINT") end

if Bytenet then
	Bytenet.HINT.listen(function(data)
		-- This data comes from the server and should already be filtered
		AdminGui.hint(data.message, data.duration)
	end)
else
	remote.OnClientEvent:Connect(function(...)
		AdminGui.hint(...)
	end)
end
