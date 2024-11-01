local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { teleport = nil }
cmd.syntax = { "<player(s)>", "<player>" }

cmd.help = [[Teleports players to one other player.]]

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local otherA = args[1]
	local otherB = args[2]
	if player and otherA and otherB then
		local targetA = self:GetBulkPlayers(player, otherA)
		local targetB = self:GetPlayer(player, otherB)

		if not targetB then return self.Responses.Error, "Could not find destination player" end
		if #targetA == 0 then return self.Responses.Error, "Affected 0 players" end

		for _, target in targetA do
			local humanoid: Humanoid? = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.RootPart and targetB then
				if target.Character and targetB.Character then
					humanoid.Sit = false
					humanoid.RootPart.AssemblyLinearVelocity = Vector3.zero
					humanoid.RootPart.AssemblyAngularVelocity = Vector3.zero
					task.wait(0.1)
					target.Character:PivotTo(targetB.Character:GetPivot())
				end
			end
		end
		return self.Responses.Success, `Successfully teleported {if #targetA == 1 then self:FormatUsername(targetA[1]) else otherA} to {self:FormatUsername(targetB)}`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
