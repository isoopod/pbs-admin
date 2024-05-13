local cmd = {}

local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local replicatedStorage = game:GetService("ReplicatedStorage")

cmd.config = {
	minRank = 2;
	aliases = {};
	syntax = {{"true", "false"}, "<player or userid>", {"banned", "", "member", "admin", "owner"}};
	
	help = [[Changes a players role. 
	Format: &lt;use userid&gt; &lt;player or userid&gt; &lt;role&gt;

	use userid should be either true or false

	player name should match the start of someones name in the server if use userid is false, otherwise an exact userid
		using 'me' as the player name will use yourself
	
	valid roles are 'banned', 'none' or left blank, 'member', 'admin', 'owner'
	]];

	__call = function(self: command.Command, player: Player, verified: boolean, ...: string?): (number, string)
		local args = {...}
		local useUserid = args[1]
		local other = args[2]
		local role = args[3]
		if role and role == "none" then role = nil end
		local roleName = if not role then "" else role
		if player and useUserid and other and role then
			if self:UserHasPermissionsForCommand(player) then
				local target = self:GetPlayer(player,other,useUserid)
				if target then
					if self:IsUserVerified(player,target) or verified then
						if self:CanUserModifyOther(player,target) then
							if table.find(cmd.config.syntax[3],roleName) then
								if permissions.roleValues[roleName] < permissions.roleValues[permissions.GetUserPermissions(player.UserId)] or permissions.GetUserPermissions(player.UserId) == "owner" then
									if verified then
										permissions.EditPersistentRole(target.UserId, role)
										
										if string.lower(useUserid) == "false" then
											if roleName == "banned" then
												target:Kick("You have been banned")
											else
												self:GiveToolsForRole(target,if roleName == "" then "none" else roleName)
												local remote: RemoteEvent? = replicatedStorage:FindFirstChild("PBSAdminRemote")
												if remote then remote:FireClient(target,"UpdatedPermissions") end
											end
											
											local leaderstats = script.Parent.Parent:GetAttribute("leaderstats") and target:FindFirstChild("leaderstats")
											if leaderstats then
												leaderstats.Role.Value = role
											end
										end
										
										return self.Responses.Success, `{target} now has role {role}`
									else
										return self.Responses.Verify, `Are you sure you want to give user '{target}' the '{if roleName == "" then "none" else roleName}' role? Y/N`
									end
								else
									return self.Responses.Error, "Can only modify roles to ones lower than yours"
								end
							else
								return self.Responses.Error, "Invalid role name"
							end
						else
							return self.Responses.Error, "Cannot modify other users permissions as they are higher"
						end
					else
						return self.Responses.Verify, `'{target}' is not phone or government id verified, are you sure you want to authorize this user? Y/N`
					end
				else
					return self.Responses.Error, `Other player matching '{target}' not found, make sure they aren't the only person with that approximate name and you set UseUserid ('{useUserid}') to 'true' or 'false'`
				end
			else
				return self.Responses.Error, "You do not have permissions to run this command"
			end
		else
			return self.Responses.Error, "Invalid Parameters"
		end
	end
}

return cmd