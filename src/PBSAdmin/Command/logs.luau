local command = require(script.Parent)

local Bytenet = command.PublicUtils.Bytenet

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = {}

cmd.help = [[Opens a list of all commands executed by all players in this server.]]

function cmd.__call(self: command.Command, player: Player): (number, string)
	Bytenet.LOGS.sendTo(command.logs, player)
	return self.Responses.Success, "Opened logs"
end

return cmd
