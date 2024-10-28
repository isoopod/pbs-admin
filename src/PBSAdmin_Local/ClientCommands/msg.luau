-- Client commands can just be used as a module loader for clientside portions of commands.
-- There is nothing that enforces a module under here to register a command.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminGui = require(script.Parent.Parent.AdminGui)
local Utils = require(script.Parent.Parent.Utils)

-- bytenet integration
local Bytenet = Utils.Bytenet

local remote: RemoteEvent
if not Bytenet then
	remote = ReplicatedStorage:WaitForChild("PBSADMIN_MSG")
end

if Bytenet then
	Bytenet.MSG.listen(function(data)
		-- This data comes from the server and should already be filtered
		AdminGui.message(data.title, data.message, data.typewrite, data.typewriteDelta)
	end)
else
	remote.OnClientEvent:Connect(function(...)
		AdminGui.message(...)
	end)
end
