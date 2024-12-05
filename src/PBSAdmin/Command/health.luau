local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { heal = true }
cmd.syntax = { "<player(s)>", "<number>" }

cmd.help = [[Sets a player's Health and MaxHealth. Default Health is 100.]]
cmd.aliasHelp = { heal = [[Increments the player's health (not max health)]] }

function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local health = tonumber(args[2])
	if player and other and health then
		local targets = self:GetBulkPlayers(player, other)

		local filteredTargets = {}
		-- Filter out targets we cannot effect
		for _, v in targets do
			if self:CanUserModifyOther(player, v) then table.insert(filteredTargets, v) end
		end
		targets = filteredTargets

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		for _, target in targets do
			if target.Character and target.Character:FindFirstChild("Humanoid") then
				if not aliasData then
					target.Character.Humanoid.MaxHealth = health
					target.Character.Humanoid.Health = health
				else
					target.Character.Humanoid.Health += health
				end
			end
		end

		return self.Responses.Success,
			`Successfully {aliasData and "incremented" or "set"} health of {if #targets == 1 then self:FormatUsername(targets[1]) else other} {aliasData and "by" or "to"} {health}`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
