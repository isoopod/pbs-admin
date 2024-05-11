local cmd = {}

local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

cmd.config = {
	minRank = 2;
	aliases = {};
	syntax = {"any"};
	
	help = [[Gives a player tools until they leave. Format: <player> \n \n
		player should match the name of a player in the server \n
		using 'me' as the player name will use yourself]]; 

	__call = function(self: command.Command, player: Player, verified: boolean, ...: string?): (number, string)
		local args = {...}
		local useUserid = args[1]
		local other = args[2]
		if player and other then
			if self:UserHasPermissionsForCommand(player) then
				local target = self:GetPlayer(player,other,useUserid)
				if target then
					if self:IsUserVerified(player,target) or verified then
                        if verified then
                            self:GiveToolsForRole(target, "member")
                            -- add them to the role cache so they can use those assets
                            permissions._CachedPermissions[other] = true
                            return self.Responses.Success, `'{target}' has been given tools until the server restarts.`
                        else
                            return self.Responses.Verify, `Are you sure you want to give tools to user '{target}'? Y/N`
                        end
                        
						
					else
						return self.Responses.Verify, `'{target}' is not phone or government id verified, are you sure you want to give them tools? Y/N`
					end
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