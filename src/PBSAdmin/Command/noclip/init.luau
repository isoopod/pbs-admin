local cmd = {}

local command = require(script.Parent)

cmd.config = {
	minRank = 2;
	aliases = {};
	syntax = {"<player>"};
	
	help = [[Toggles noclip for a player. 
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
                    if target.Character and target.Character:FindFirstChild("PBSADMIN_NoClip") then
                        target.Character.PBSADMIN_NoClip:Destroy()
                        return self.Responses.Success, `Noclip removed for '{target}'`
                    elseif target.Character then
                        script.PBSADMIN_NoClip:Clone().Parent = target.Character
                        return self.Responses.Success, `Noclip activated for '{target}'`
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

local PhysicsService = game:GetService("PhysicsService")
-- If the noclip collision group is not created yet, then create it
if not PhysicsService:IsCollisionGroupRegistered("PlayerNoclip") then
	PhysicsService:RegisterCollisionGroup("PlayerNoclip")
end

-- Each runtime make noclip not collide with any other collision groups
-- This is needed incase another script generates a collision group at any point
for _,v in PhysicsService:GetRegisteredCollisionGroups() do
	if v.name ~= "PlayerNoclip" then
		PhysicsService:CollisionGroupSetCollidable("PlayerNoclip", v.name, false)
	end
end


return cmd