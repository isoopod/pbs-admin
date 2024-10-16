local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = {}
cmd.syntax = { "<player>" }

cmd.help = [[Toggles click teleportation for a player.]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				-- Toggle the flight script for this palyer
				-- If they already have flight, disable it
				if target.Character and target.Character:FindFirstChild("PBSADMIN_ClickTP") then
					target.Character.PBSADMIN_ClickTP:Destroy()
					return self.Responses.Success, `Click tp removed for '{self.FormatUsername(target)}'`
				elseif target.Character then
					script.PBSADMIN_ClickTP:Clone().Parent = target.Character
					return self.Responses.Success, `Click tp activated for '{self.FormatUsername(target)}'`
				end

				return self.Responses.Error, `'{self.FormatUsername(target)}' currently does not have a character, try again later.`
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
