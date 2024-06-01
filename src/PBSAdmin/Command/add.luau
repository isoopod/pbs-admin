--!nocheck
--!nolint
-- Remove these (above) from the module when you work on it again, if its still giving me warnings ill refactor myself it but for now its more important to finish it [isoopod]
local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PBSServer = ServerScriptService.PBSServer

local command = require(script.Parent)
local permissions = require(script.Parent.Parent.Permissions)

local cmd: command.cmd = {}::command.cmd
local data = require(PBSServer.PBSData)

cmd.minRank = 1;
cmd.aliases = {};
cmd.syntax = {{"true", "false"}, "<player or userid>", {"banned", "", "member", "admin", "owner"}};

cmd.help = [[Changes a players role. 
Format: &lt;use userid&gt; &lt;player or userid&gt; &lt;role&gt;

use userid should be either true or false

player name should match the start of someones name in the server if use userid is false, otherwise an exact userid
	using 'me' as the player name will use yourself

valid roles are 'banned', 'none' or left blank, 'member', 'admin', 'owner'
]];

-- [isoopod]: I made some changes to the GetPlayer method, see the new role module to see how to update this
-- we no longer use a 'useUserId' field, instead if the player field starts with '#' and canUseUserId is set to true, it will use offline players

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = {...}
	local useUserid = args[1]
	local other = args[2]
	local role = args[3]
	if role and role == "none" then role = nil end
	local roleName = if not role then "" else role
	if player and useUserid and other and role then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player,other,useUserid)
			if target then
				if self:IsUserVerified(player,target) or verified then
					--data.EditPlayerData(player,3)
					-- need to wait for an example of what the zone datatype looks like to be able to add on
					
					return self.Responses.Success, "TODO"
				else
					return self.Responses.Verify, `'{target}' is not phone or government id verified, are you sure you want to authorize this user? Y/N`
				end
			else
				return self.Responses.Error, `Other player matching '{target}' not found, make sure they aren't the only person with that approximate name and you set UseUserid ('{useUserid}') to 'true' or 'false'`
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd