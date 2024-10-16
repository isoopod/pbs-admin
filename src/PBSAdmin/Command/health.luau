local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = {}
cmd.syntax = { "<player(s)>", "<number>" }

cmd.help = [[Sets a player's Health and MaxHealth. Default Health is 100.]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local health = tonumber(args[2])
	if player and other and health then
		if self:UserHasPermissionsForCommand(player) then
			local targets = self:GetBulkPlayers(player, other)

			if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

			for _, target in targets do
				if target.Character and target.Character:FindFirstChild("Humanoid") then
					target.Character.Humanoid.MaxHealth = health
					target.Character.Humanoid.Health = health
				end
			end

			return self.Responses.Success, `Successfully set health of {if #targets == 1 then targets[1] else other} to {health}`
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
