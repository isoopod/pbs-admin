local command = require(script.Parent)
local health = require(script.Parent.health)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = health.minRank -- this is basically just a alias for the health command
cmd.syntax = { "<player(s)>" } -- the reason its not an actual alias is because the syntax is different

cmd.help = [[Kills players]]

function cmd.__call(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		local exec = command.new("health")
		if exec then
			return exec(player, verified, aliasData, other, "0")
		end
		return self.Responses.Error, "Missing health command"
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
