local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { vis = true }
cmd.syntax = { "<player(s)>" }

cmd.help = [[Toggles invisibility for players]]
cmd.aliasHelp = { vis = [[Makes players visible]] }

function cmd.__call(self: command.Command, player: Player, _, aliasData, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player then
		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then
			return self.Responses.Error, "Affected 0 players"
		end

		for _, target in targets do
			for _, v in target.Character:GetDescendants() do
				if v:IsA("BasePart") or v:IsA("Decal") then
					if v:GetAttribute("OriginalTransparency") then
						v.Transparency = v:GetAttribute("OriginalTransparency")
						v:SetAttribute("OriginalTransparency", nil)
					elseif not aliasData then
						v:SetAttribute("OriginalTransparency", v.Transparency)
						v.Transparency = 1
					end
				end
			end
		end

		local msg
		if aliasData then
			msg = `Successfully made {if #targets == 1 then self:FormatUsername(targets[1]) else other} visible`
		else
			msg = `Successfully toggled invisibility for {if #targets == 1 then self:FormatUsername(targets[1]) else other}`
		end
		return self.Responses.Success, msg
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
