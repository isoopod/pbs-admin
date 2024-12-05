local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { untools = false }
cmd.syntax = { "<player(s)>" }

cmd.help = [[Temporarily gives a player member (or a higher saved role) permissions until they rejoin.]]
cmd.aliasHelp = { untools = "Temporarily gives a player the visitor role until they rejoin, removing their ability to build." }

function cmd.__call(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		local targets = self:GetBulkPlayers(player, other)

		local filteredTargets = {}
		-- Filter out targets we cannot effect
		for _, v in targets do
			if self:CanUserModifyOther(player, v) then table.insert(filteredTargets, v) end
		end
		targets = filteredTargets

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		local logs = {}
		for _, target in targets do
			if self:IsUserVerified(player, target) or verified then
				if verified then
					if aliasData == nil then
						permissions._CachedPermissions[target.UserId] = nil
						local role = permissions.GetUserPermissions(target.UserId)
						if role == "visitor" then role = "member" end
						if script.Parent.Parent:GetAttribute("leaderstats") then target.leaderstats.Role.Value = string.gsub(role, "^%l", string.upper) end
						self:GiveToolsForRole(target, role)
						permissions._CachedPermissions[target.UserId] = role
					else
						permissions._CachedPermissions[target.UserId] = "visitor"
						if script.Parent.Parent:GetAttribute("leaderstats") then target.leaderstats.Role.Value = "Visitor" end
						self:GiveToolsForRole(target, "visitor")
					end
					table.insert(logs, `tools {if aliasData == nil then "given to" else "removed from"} {self:FormatUsername(target)}`)
				else
					return self.Responses.Verify, `Are you sure you want to {if aliasData == nil then "give tools to" else "remove tools from"} '{other}'? Y/N`
				end
			else
				return self.Responses.Verify, `some players are not phone or government id verified, are you sure you want to give them tools? Y/N`
			end
		end
		return self.Responses.Success, table.concat(logs, "\n")
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
