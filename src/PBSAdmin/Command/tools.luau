local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { unTools = false }
cmd.syntax = { "<player>" }

cmd.help = [[Gives a player tools until they leave. 
Format: &lt;player&gt;
	
player should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(
	self: command.Command,
	player: Player,
	verified: boolean,
	aliasData: any?,
	...: string?
): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				if self:IsUserVerified(player, target) or verified then
					if verified then
						if aliasData == nil then
							self:GiveToolsForRole(target, "member")
							permissions._CachedPermissions[other] = true
						else
							self:GiveToolsForRole(target, "none")
							permissions._CachedPermissions[other] = nil
						end
						return self.Responses.Success,
							`tools {if aliasData == nil then "given to" else "removed from"} {target}`
					else
						return self.Responses.Verify,
							`Are you sure you want to {if aliasData == nil then "give tools to" else "remove tools from"} user '{target}'? Y/N`
					end
				else
					return self.Responses.Verify,
						`'{target}' is not phone or government id verified, are you sure you want to give them tools? Y/N`
				end
			else
				return self.Responses.Error,
					"Other player not found, make sure they aren't the only person with that approximate name"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
