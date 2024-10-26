local ServerScriptService = game:GetService("ServerScriptService")

local PBSServer = ServerScriptService.PBSServer

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd
local data = require(PBSServer.PBSData)

cmd.minRank = 1
cmd.aliases = { remove = "remove" }
cmd.syntax = { "<player or #userid>" }

cmd.help = [[Gives a player build permissions for you plot (if plots are enabled)]]
cmd.aliasHelp = { remove = [[Removes a player's build permissions for your plot (if plots are enabled)]] }

function cmd.__call(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]

	if player and other then
		local target = self:GetPlayer(player, other, true)
		if target then
			if self:IsUserVerified(player, target) or verified then
				if aliasData == "remove" then
					data.RemoveWhitelist(player.Name, args[1])
				else
					data.AddWhitelist(player.Name, args[1])
				end
				return self.Responses.Success, `Successfully {aliasData and "removed" or "added"} permissions to build on your plot for {self.FormatUsername(target)}`
			else
				return self.Responses.Verify, `'{self.FormatUsername(target)}' is not phone or government id verified, are you sure you want to authorize this user? Y/N`
			end
		else
			return self.Responses.Error,
				`Other player matching '{target}' not found, make sure they aren't the only person with that approximate name, or you put a '#' in front for a UserId`
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
