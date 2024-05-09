local cmd = {}

local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

cmd.config = {
	minRank = 2;
	aliases = {};
	syntax = {{"true, false"}, "any", {"banned", "", "member", "admin", "owner"}};
	
	__tostring = function(): string
		return [[Changes a players role. Format: 
		/role {use userid} {player name} {valid role} \n 
		use userid should be either true or false \n 
		player name should match the start of someones name in the server if use userid is false, otherwise an exact userid \n 
		role can be left blank to remove their role entirely]] 
	end;
	__call = function(self: command.Command, player: Player, ...: string): (boolean, string)
		local args = {...}
		local useUserid = args[1]
		local other = args[2]
		local role = args[3]
		if player and useUserid and other and role then
			if self:UserHasPermissionsForCommand(player) then
				local target = self:GetPlayer(player,other,useUserid)
				if target then
					if self:IsUserVerified(player,target) then
						if self:CanUserModifyOther(player,target) then
							if table.find(cmd.config.syntax[3],role) then
								if permissions.roleValues[role] < permissions.roleValues[permissions.GetUserPermissions(player.UserId)] or permissions.GetUserPermissions(player.UserId) == "owner" then
									permissions.EditPersistentRole(target.UserId)
									
									if string.lower(useUserid) == "false" then
										if role == "banned" then
											target:Kick("You have been banned")
										end

										self:GiveToolsForRole(target,role)
										
										if permissions.roleValues[role] > 1 and not target.PlayerGui:FindFirstChild("PBSAdmin_Local") then
											script.Parent.Parent.PBSAdmin_Local:Clone().Parent = target:WaitForChild("PlayerGui")
										end
										
                                        local leaderstats = script.Parent.Parent:GetAttribute("leaderstats") and target:FindFirstChild("leaderstats")
										if leaderstats then
											leaderstats.Role.Value = role
										end
									end
									
									return true, `{target} now has role {role}`
								else
									return false, "Can only modify roles to ones lower than yours"
								end
							else
								return false, "Invalid role name"
							end
						else
							return false, "Cannot modify other users permissions as they are higher"
						end
					else
						return false, "This user is not phone or government id verified so can only be modified by an owner"
					end
				else
					return false, "Other player not found, make sure they aren't the only person with that approximate name and you set UseUserid to the correct value"
				end
			else
				return false, "You do not have permissions to run this command"
			end
		else
			return false, "Invalid Parameters"
		end
	end;
}

return cmd
