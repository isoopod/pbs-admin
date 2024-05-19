local command = require(script.Parent)

local cmd: command.cmd = {}::command.cmd

cmd.minRank = 2;
cmd.aliases = {};
cmd.syntax = {"<player>", "<number>"};

cmd.help = [[Sets a players Health. Default Health is 100. 
Format: &lt;player&gt; &lt;number&gt;
	
both players should match the name of a player in the server 
	using 'me' as the player name will use yourself]]; 

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = {...}
	local other = args[1]
	local health = tonumber(args[2])
	if player and other and health then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player,other,"false")
			if target then
				if target.Character and target.Character:FindFirstChild("Humanoid") then
					target.Character.Humanoid.MaxHealth = health
					target.Character.Humanoid.Health = health
					return self.Responses.Success, `Successfully set the Health of '{target}' to '{health}'`
				end
				return self.Responses.Error, `'{target}' currently does not have a character, try again later.`
			else
				return self.Responses.Error, "Could not find both players"
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd