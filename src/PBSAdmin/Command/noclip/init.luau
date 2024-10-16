local PhysicsService = game:GetService("PhysicsService")

-- If the noclip collision group is not created yet, then create it
if not PhysicsService:IsCollisionGroupRegistered("PlayerNoclip") then PhysicsService:RegisterCollisionGroup("PlayerNoclip") end

-- Each runtime make noclip not collide with any other collision groups
-- This is needed incase another script generates a collision group at any point
for _, v in PhysicsService:GetRegisteredCollisionGroups() do
	if v.name ~= "PlayerNoclip" then PhysicsService:CollisionGroupSetCollidable("PlayerNoclip", v.name, false) end
end

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { unnoclip = false }
cmd.syntax = { "<player>" }

cmd.help = [[Toggles noclip for a player.]]
cmd.aliasHelp = { unnoclip = [[Removes flight for a player.]] }

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other)
			if target then
				-- Toggle the flight script for this palyer
				-- If they already have flight, disable it
				-- Alternatively, if the command was unNoclip, then dont give noclip
				local noclip = target.Character and target.Character:FindFirstChild("PBSADMIN_NoClip")
				if noclip then
					noclip:Destroy()
					return self.Responses.Success, `Noclip removed for '{target}'`
				elseif target.Character and aliasData ~= false then
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

return cmd
