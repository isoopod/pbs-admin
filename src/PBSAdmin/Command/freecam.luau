local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player>" }

cmd.help = [[Puts the player in freecam. Shorthand for invis and noclip]]

local noclip = command.new("noclip")
local invis = command.new("invis")
assert(noclip and invis, "Missing noclip or invis")

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player and other then
		local target = self:GetPlayer(player, other)
		if target and self:CanUserModifyOther(player, target) then
			-- Attempt to disable noclip and invis
			pcall(function()
				-- Use the targets percise name, since this command does not take bulk players and the other commands do
				noclip(player, nil, false, target.Name)
				invis(player, nil, true, target.Name)
			end)

			if target:GetAttribute("InFreecam") then
				target:SetAttribute("InFreecam", nil)
			else
				target:SetAttribute("InFreecam", true)
				pcall(function()
					-- Use the targets percise name, since this command does not take bulk players and the other commands do
					noclip(player, nil, nil, target.Name)
					invis(player, nil, nil, target.Name)
				end)
			end
			return self.Responses.Success, `Toggled freecam for {self:FormatUsername(target)}`
		else
			return self.Responses.Error, "Other player not found, make sure they aren't the only person with that approximate name"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
