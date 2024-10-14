local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { r15 = Enum.HumanoidRigType.R15, r6 = Enum.HumanoidRigType.R6 }
cmd.syntax = { "<player>" }

cmd.help = [[Refreshes a player, instantly resetting them in place.
	
both players should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.aliasHelp = {
	r15 = [[Refreshes a player and forces their avatar into r15]],
	r6 = [[Refreshes a player and forces their avatar into r6]],
}

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- forcing the rigtype is different
					if aliasData then
						target:SetAttribute("ForcedRigtype", aliasData.Name)
						local desc = Players:GetHumanoidDescriptionFromUserId(target.CharacterAppearanceId)
						local morph = Players:CreateHumanoidModelFromDescription(desc, aliasData :: Enum.HumanoidRigType)
						morph:PivotTo(target.Character:GetPivot())
						morph.Name = target.Name
						local oldChar = target.Character
						target.Character = morph
						morph.Parent = workspace
						oldChar:Destroy()
					else
						local cf = target.Character:GetPivot()
						target:LoadCharacter()
						repeat
							task.wait()
						until target.Character and target.Character:FindFirstChild("HumanoidRootPart")
						target.Character:PivotTo(cf)
					end

					return self.Responses.Success, if aliasData then `Set {target.DisplayName} ({target}) to {aliasData.Name}` else `Reset {target.DisplayName} ({target})`
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
