local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player(s)>", "<number>" }

cmd.help = [[Sets a JumpPower for players. JumpPower defaults to 50.]]

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	local power = tonumber(args[2]) or 50
	if player then
		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then
			return self.Responses.Error, "Affected 0 players"
		end

		for _, target in targets do
			if target.Character and target.Character:FindFirstChild("Humanoid") then
				target.Character.Humanoid.JumpPower = power
			end
		end
		return self.Responses.Success, `Successfully gave {if #targets == 1 then self:FormatUsername(targets[1]) else other} {power} JumpPower`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
