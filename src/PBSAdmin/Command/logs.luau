local ReplicatedStorage = game:GetService("ReplicatedStorage")

local command = require(script.Parent)

local Bytenet = command.PublicUtils.Bytenet
local remote
if not Bytenet then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PBSADMIN_LOGS"
	remote.Archivable = false
	remote.Parent = ReplicatedStorage
end

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = {}

cmd.help = [[Opens a list of all commands executed by all players in this server.]]

function cmd.__call(self: command.Command, player: Player): (number, string)
	if Bytenet then
		Bytenet.LOGS.sendTo(command.logs, player)
	else
		remote:FireClient(player, command.logs)
	end
	return self.Responses.Success, "Opened logs"
end

return cmd
