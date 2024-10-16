local command = require(script.Parent)
local health = require(script.Parent.health)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = health.minRank -- this is basically just a alias for the health command
cmd.aliases = {}
cmd.syntax = { "<player(s)>" } -- the reason its not an actual alias is because the syntax is different

cmd.help = [[Kills players]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		return health.__call(self, player, verified, aliasData, other, "0")
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
