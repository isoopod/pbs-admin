local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { teleport = nil }
cmd.syntax = { "<player>", "<player>" }

cmd.help = [[Teleports one player to another.
	
both players should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(
	self: command.Command,
	player: Player,
	verified: boolean,
	aliasData: any?,
	...: string?
): (number, string)
	local args = { ... }
	local otherA = args[1]
	local otherB = args[2]
	if player and otherA and otherB then
		if self:UserHasPermissionsForCommand(player) then
			local targetA = self:GetPlayer(player, otherA)
			local targetB = self:GetPlayer(player, otherB)
			if targetA and targetB then
				if targetA.Character and targetB.Character then
					targetA.Character:PivotTo(targetB.Character:GetPivot())
					return self.Responses.Success, `Successfully teleported '{targetA}' to '{targetB}'`
				end
				return self.Responses.Error,
					`'{targetA}' or '{targetB}' currently do not have a character, try again later.`
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
