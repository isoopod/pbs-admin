local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd
local permissions = require(script.Parent.Parent.Permissions)

cmd.minRank = 3
cmd.aliases = {}
cmd.syntax = { "<player / #userid>", "<reason?>" }

cmd.help = [[Permanently bans a player for a specified amount of time. Will also remove any permission the user may have had. Alt detection is enabled.
	The ban will last until removed through the unban command
]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local reason = args[2]
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other, true)
			if target then
				if verified then
					local displayReason = "You have been permanently banned from this PBS."
					local s, e = pcall(Players.BanAsync, Players, {
						UserIds = { target.UserId },
						ApplyToUniverse = true,
						Duration = -1,
						DisplayReason = displayReason,
						PrivateReason = reason,
						ExcludeAltAccounts = true,
					})
					if not s then return self.Responses.Error, `BanAsync error: {e}` end
					permissions.EditPersistentRole(target.UserId)
					return self.Responses.Success, `{self.FormatUsername(target)} has been permanently banned`
				else
					return self.Responses.Verify, `Are you sure you want to permanently ban {self.FormatUsername(target)}?`
				end
			else
				return self.Responses.Error, "Player could not be found"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
