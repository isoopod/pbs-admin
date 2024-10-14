local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { walkspeed = nil }
cmd.syntax = { "<player(s)>", "<number>" }

cmd.help = [[Sets the WalkSpeed for players. WalkSpeed defaults to 16.]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	local speed = tonumber(args[2]) or 16
	if player then
		if self:UserHasPermissionsForCommand(player) then
			local targets = self:GetBulkPlayers(player, other)

			if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

			for _, target in targets do
				if target.Character and target.Character:FindFirstChild("Humanoid") then target.Character.Humanoid.WalkSpeed = speed end
			end

			return self.Responses.Success, `Successfully gave {if #targets == 1 then targets[1] else other} WalkSpeed {speed}`
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
