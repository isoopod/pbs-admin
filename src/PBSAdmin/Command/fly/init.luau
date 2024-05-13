local cmd = {}

local command = require(script.Parent)

cmd.config = {
	minRank = 2;
	aliases = {};
	syntax = {"<player>"};
	
	help = [[Toggles flight for a player. 
	Format: &lt;player&gt;
		
	player should match the name of a player in the server
		using 'me' as the player name will use yourself]]; 

	__call = function(self: command.Command, player: Player, verified: boolean, ...: string?): (number, string)
        local args = {...}
		local other = args[1]
		if player and other then
			if self:UserHasPermissionsForCommand(player) then
				local target = self:GetPlayer(player,other,"false")
				if target then
                    -- Toggle the flight script for this palyer
                    -- If they already have flight, disable it
                    if target.Character and target.Character:FindFirstChild("PBSADMIN_FlyScript") then
                        target.Character.PBSADMIN_FlyScript:Destroy()
                        return self.Responses.Success, `Flight removed for '{target}'`
                    elseif target.Character then
                        script.PBSADMIN_FlyScript:Clone().Parent = target.Character
                        return self.Responses.Success, `Flight activated for '{target}'`
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
}

return cmd