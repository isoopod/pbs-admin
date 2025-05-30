local command = require(script.Parent)

local PakNet = command.PublicUtils.PakNet

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player(s)>", "<number>" }

cmd.help = [[Places a countdown timer at the top of the screen for the affected players.
	the second argument is how long the countdown will take in seconds, as a positive integer.
]]

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local length = tonumber(args[2])
	if player and other and length then
		length = math.floor(length)
		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		task.spawn(function()
			for i = 0, length do
				local t = tostring(length - i)
				PakNet.HINT:FireList(targets, { message = t, duration = 1 })
				task.wait(1)
			end
		end)
		return self.Responses.Success, `Started countdown`
	end
	return self.Responses.Error, "Invalid Parameters"
end

return cmd
