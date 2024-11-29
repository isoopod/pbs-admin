local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { { "visitor", "member", "trusted", "admin" } }

cmd.help = [[Changes the default role to give new players.

valid roles are 'visitor', 'member', 'trusted', 'admin'. If a role is not provided, it will default to visitor.
]]

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local role = args[1] and args[1]:lower() or "visitor"
	if player then
		if table.find(cmd.syntax[1] :: any, role) then
			if permissions.roleValues[role] < permissions.roleValues[permissions.GetUserPermissions(player.UserId)] then
				permissions.untrustedRole = role

				return self.Responses.Success, `Default role has been changed to {role}`
			else
				return self.Responses.Error, "Can only set the default role to one lower than yours"
			end
		else
			return self.Responses.Error, "Invalid role name"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
