local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { teleport = nil }
cmd.syntax = { "<player>", "<player>" }

cmd.help = [[Teleports one player to another.
	
both players should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local otherA = args[1]
	local otherB = args[2]
	if player and otherA and otherB then
		if self:UserHasPermissionsForCommand(player) then
			local targetA = self:GetBulkPlayers(player, otherA)
			local targetB = self:GetPlayer(player, otherB)

			if not targetB then return self.Responses.Error, "Could not find destination player" end

			for _, target in targetA do
				local humanoid: Humanoid? = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and targetB then
					if target.Character and targetB.Character then
						humanoid.Sit = false
						task.wait(0.1)
						target.Character:PivotTo(targetB.Character:GetPivot())
					end
				end
			end
			return self.Responses.Success, `Successfully teleported {if #targetA == 1 then targetA[1] else otherA} to {targetB}`
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
