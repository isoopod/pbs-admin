local command = require(script.Parent)

local cmd: command.cmd = {}::command.cmd

cmd.minRank = 2;
cmd.aliases = {};
cmd.syntax = {"<player>"};

cmd.help = [[Toggles invincibility for a player. 
Format: &lt;player&gt;
	
player should match the name of a player in the server
	using 'me' as the player name will use yourself]]; 

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = {...}
	local other = args[1]
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player,other,"false")
			if target then
				if target.Character and target.Character:FindFirstChild("PBSADMIN_GOD") then
					target.Character.PBSADMIN_GOD:Destroy()
					return self.Responses.Success, `God mode removed for '{target}'`
				elseif target.Character then
					local ForceField = Instance.new("ForceField")
					ForceField.Visible = false
					ForceField.Name = "PBSADMIN_GOD"
					ForceField.Parent = target.Character
					return self.Responses.Success, `God mode activated for '{target}'`
				end
				
				return self.Responses.Error, `'{target}' currently does not have a character, try again later.`
			else
				return self.Responses.Error, "Other player not found, make sure they aren't the only person with that approximate name"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd