local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { unfly = false }
cmd.syntax = { "<player(s)>" }

cmd.help = [[Toggles flight for a player.]]
cmd.aliasHelp = { unfly = [[Removes flight for a player.]] }

function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player and other then
		-- Try to disable noclip
		pcall(function()
			local noclip = command.new("noclip")
			if noclip then
				noclip(player, nil, false, other)
			end
		end)

		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then
			return self.Responses.Error, "Affected 0 players"
		end

		local logs = {}

		for _, target in targets do
			-- Toggle the flight script for this palyer
			-- If they already have flight, disable it
			-- Alternativley, if the command was unfly then dont give it
			local flyscript = target.Character and target.Character:FindFirstChild("PBSADMIN_FlyScript")
			if flyscript then
				flyscript:Destroy()
				table.insert(logs, `Flight removed for '{self:FormatUsername(target)}'`)
				continue
			elseif target.Character and aliasData ~= false then
				script.PBSADMIN_FlyScript:Clone().Parent = target.Character
				table.insert(logs, `Flight activated for '{self:FormatUsername(target)}'`)
				continue
			end

			if aliasData == false then
				table.insert(logs, `<font color="#fbdc27">'{self:FormatUsername(target)}' does not have flight enabled</font>`)
				continue
			end
			table.insert(logs, `<font color="#fbdc27">'{self:FormatUsername(target)}' currently does not have a character, try again later.</font>`)
		end

		return self.Responses.Success, table.concat(logs, "\n")
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
