local command = require(script.Parent)

local PakNet = command.PublicUtils.PakNet

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = {}

cmd.help = [[Opens a list of all commands executed by all players in this server.]]

function cmd.__call(self: command.Command, player: Player): (number, string)
	PakNet.LOGS:Fire(player, command.logs)
	return self.Responses.Success, "Opened logs"
end

return cmd
