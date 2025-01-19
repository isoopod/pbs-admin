local command = require(script.Parent)

local Bytenet = command.PublicUtils.Bytenet

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<number>", "<...any>" }

cmd.help = [[Sends a global hint that appears at the top of the screen.
	The first argument is the duration of the hint. If the duration is 0 then it will be automatically calculated.
	Everything after that will be the message.
]]

function cmd.__call(self: command.Command, player: Player, verified, _, ...: string?): (number, string)
	local args = { ... }
	local duration = tonumber(args[1])
	if duration == 0 then duration = nil end
	local text = table.concat(args, " ", 2)
	if player and text ~= "" then
		local filteredText = self:FilterText(player, text)
		if not verified and filteredText ~= text then
			return self.Responses.Verify, `Your message was filtered (result: "<font color='#ff0000'>{filteredText}</font>"). Send anyway? Y/N`
		end

		filteredText = `{player}: {filteredText}`
		Bytenet.HINT.sendToAll({ message = filteredText, duration = duration })
		return self.Responses.Success, `Hint sent successfully.`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
