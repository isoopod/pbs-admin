local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = {}
cmd.syntax = { "<player>", "<number>" }

cmd.help = [[Sets a players JumpPower. Default JumpPower is 50. 
	
both players should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local power = tonumber(args[2])
	if player and other and power then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				if target.Character and target.Character:FindFirstChild("Humanoid") then
					target.Character.Humanoid.JumpPower = power
					return self.Responses.Success, `Successfully set the JumpPower of '{target}' to '{power}'`
				end
				return self.Responses.Error, `'{target}' currently does not have a character, try again later.`
			else
				return self.Responses.Error, "Could not find both players"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
