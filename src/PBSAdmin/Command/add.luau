local ServerScriptService = game:GetService("ServerScriptService")

local PBSServer = ServerScriptService.PBSServer

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd
local data = require(PBSServer.PBSData)

cmd.minRank = 1
cmd.aliases = { remove = "remove" }
cmd.syntax = { "<player or #userid>" }

cmd.help = [[Gives a player build permissions (or removes it when using remove)
]]

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
			local target = self:GetPlayer(player, other, true)
			if other then
				print(player.Name)
				if self:IsUserVerified(player, target) or verified then
					if aliasData == "remove" then
						data.RemoveWhitelist(player.Name, args[1])
					else
						data.AddWhitelist(player.Name, args[1])
					end
					return self.Responses.Success, "TODO"
				else
					return self.Responses.Verify,
						`'{target}' is not phone or government id verified, are you sure you want to authorize this user? Y/N`
				end
			else
				return self.Responses.Error,
					`Other player matching '{target}' not found, make sure they aren't the only person with that approximate name, or you put a '#' in front for a UserId`
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
