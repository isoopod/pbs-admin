local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { watch = nil }
cmd.syntax = { "<player>" }

cmd.help = [[Spectates another player.]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				local gui = player.Character and player.Character:FindFirstChild("PBSADMIN_Spectate")
				if gui then gui:Destroy() end
				if target.Character and player.Character then
					local spectate = script.PBSADMIN_Spectate:Clone()
					spectate:SetAttribute("Target", target.Name)
					spectate.Parent = player.Character
					return self.Responses.Success, `You are now spectating '{self.FormatUsername(target)}'. Press backspace to stop spectating`
				end

				return self.Responses.Error, `You or '{self.FormatUsername(target)}' currently do not have a character, try again later.`
			else
				return self.Responses.Error, "Other player not found, make sure they aren't the only person with that approximate name"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
