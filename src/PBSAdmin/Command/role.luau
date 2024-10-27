local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player / #userid>", { "", "member", "trusted", "admin", "owner" } }

cmd.help = [[Changes a players role. 

valid roles are 'none' or left blank, 'member', 'trusted', 'admin', 'owner'

To ban a user, see the ban commands.
]]

function cmd.__call(self: command.Command, player: Player, verified: boolean, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local role = args[2] and args[2]:lower()
	if role and role == "none" then
		role = nil
	end
	local roleName = if not role then "" else role
	if player and other and role then
		local target = self:GetPlayer(player, other, true)
		if target then
			if self:IsUserVerified(player, target) or verified then
				if self:CanUserModifyOther(player, target) then
					if table.find(cmd.syntax[2] :: any, string.lower(roleName)) then
						if
							permissions.roleValues[roleName] < permissions.roleValues[permissions.GetUserPermissions(player.UserId)]
							or permissions.GetUserPermissions(player.UserId) == "owner"
						then
							if verified then
								permissions.EditPersistentRole(target.UserId, role)

								if other:sub(1, 1) ~= "#" then
									if roleName == "banned" then
										target:Kick("You have been banned")
									else
										self:GiveToolsForRole(target, if roleName == "" then "none" else roleName)
									end

									local leaderstats = script.Parent.Parent:GetAttribute("leaderstats") and target:FindFirstChild("leaderstats")
									if leaderstats then
										leaderstats.Role.Value = role:gsub("^%l", string.upper)
									end
								end

								return self.Responses.Success, `{self:FormatUsername(target)} now has role {role}`
							else
								return self.Responses.Verify,
									`Are you sure you want to give user '{self:FormatUsername(target)}' the '{if roleName == "" then "none" else roleName}' role? Y/N`
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
				return self.Responses.Verify, `'{self:FormatUsername(target)}' is not phone or government id verified, are you sure you want to authorize this user? Y/N`
			end
		else
			return self.Responses.Error,
				`Other player matching '{other}' not found, make sure they aren't the only person with that approximate name, or you put a '#' in front for a UserId`
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
