local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player / #userid>" }

cmd.help = [[Unbans a given user from the game.
]]

function cmd.__call(self: command.Command, player: Player, verified: boolean, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		local target = self:GetPlayer(player, other, true)
		if target then
			if verified then
				local s, e = pcall(Players.UnbanAsync, Players, {
					UserIds = { target.UserId },
					ApplyToUniverse = true,
				})
				if not s then
					return self.Responses.Error, `UnbanAsync error: {e}`
				end
				return self.Responses.Success, `{self:FormatUsername(target)} has been unbanned`
			else
				return self.Responses.Verify, `Are you sure you want to unban {self:FormatUsername(target)}`
			end
		else
			return self.Responses.Error, "Player could not be found"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
