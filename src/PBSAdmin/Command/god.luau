local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { ungod = true }
cmd.syntax = { "<player(s)>" }

cmd.help = [[Enables invincibility for players.]]
cmd.aliasHelp = { ungod = [[Removes invinbility for players]] }

function cmd.__call(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		for _, target in targets do
			if aliasData == true and target.Character and target.Character:FindFirstChild("PBSADMIN_GOD") then
				target.Character.PBSADMIN_GOD:Destroy()
			elseif not aliasData and target.Character then
				local ForceField = Instance.new("ForceField")
				ForceField.Visible = false
				ForceField.Name = "PBSADMIN_GOD"
				ForceField.Parent = target.Character
			end
		end

		return self.Responses.Success, `Successfully {aliasData and "removed" or "enabled"} god mode for {if #targets == 1 then self.FormatUsername(targets[1]) else other}`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
