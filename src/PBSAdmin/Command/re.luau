local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { r15 = Enum.HumanoidRigType.R15, r6 = Enum.HumanoidRigType.R6 }
cmd.syntax = { "<player>" }

cmd.help = [[Refreshes a player, instantly resetting them in place.
The r6 and r15 aliases will set their avatar to r6 or r15.
	
both players should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local speed = tonumber(args[2])
	if player and other and speed then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- forcing the rigtype is different
					if aliasData then
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

					return self.Responses.Success, `Successfully set the WalkSpeed of '{target}' to '{speed}'`
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
