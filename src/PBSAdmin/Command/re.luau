local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { r15 = Enum.HumanoidRigType.R15, r6 = Enum.HumanoidRigType.R6 }
cmd.syntax = { "<player>" }

cmd.help = [[Refreshes a player, instantly resetting them in place.]]

cmd.aliasHelp = {
	r15 = [[Refreshes a player and forces their avatar into r15]],
	r6 = [[Refreshes a player and forces their avatar into r6]],
}

function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player then
		local target = self:GetPlayer(player, other)
		if target and self:CanUserModifyOther(player, target) then
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

				return self.Responses.Success, if aliasData then `Set {self:FormatUsername(target)} to {aliasData.Name}` else `Reset {self:FormatUsername(target)}`
			end
			return self.Responses.Error, `'{self:FormatUsername(target)}' currently does not have a character, try again later.`
		else
			return self.Responses.Error, "Could not find both players"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
