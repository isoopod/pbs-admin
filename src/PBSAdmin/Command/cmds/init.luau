--!nocheck
local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 0
cmd.aliases = {}
cmd.syntax = { "any" }

cmd.help = [[Spectates another player. 
Format: &lt;player&gt;
	
player should match the name of a player in the server
	using 'me' as the player name will use yourself]]

cmd.__call = function(
	self: command.Command,
	player: Player,
	verified: boolean,
	aliasData: any?,
	...: string?
): (number, string)
	if player then
		if self:UserHasPermissionsForCommand(player) then
			local gui = player.PlayerGui and player.PlayerGui:FindFirstChild("PBSADMIN_CMDS")
			if gui then
				gui:SetAttribute("upd", not gui:GetAttribute("upd"))
			else
				local Gui = script.PBSADMIN_CMDS:Clone()
				Gui.Parent = player.PlayerGui
				return self.Responses.Success, `Cmds opened successfully`
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	end
	return self.Responses.Error, "Unknown error"
end

script.PBSADMIN_CMDS:SetAttribute("upd", false)

return cmd
