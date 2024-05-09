--[[ 
See comments at start of the Permissions module for details on how to add permissions in studio
Use this to give yourself owner

See the GitHub (https://github.com/isoopod/pbs-admin) for further instructions and documentation

SCRIPT ATTRIBUTES
leaderstats | if we should show the users role in leaderstats (will wait to see if leaderstats is created before falling back to creating a new leaderstats)
isVerified_Only | Only players who have verified a non VOIP phone number or government id on their account can have permissions. (in studio everyone is verified for testing)
This is pretty strict so i'd only use this if you are having serious issues with alts, meaning only owners can give an unverified player permissions
]]
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")
local Command = require(script.Command)
local perms = require(script.Permissions)

-- needs to run first
players.PlayerAdded:Connect(function(player: Player) 
	local rank = perms.GetUserPermissions(player.UserId)
	local rankValue = perms.roleValues[rank]
	
	--TODO implement roblox ban and alt detection apis
	if rankValue == -1 then
		player:Kick("You are banned from this PBS")
	end
	
	Command.PublicUtils.GiveToolsForRole(player::any, rank)

	-- creating leaderstats may yield so keep at bottom
	if script:GetAttribute("leaderstats") then
		local leaderstats = player:WaitForChild("LeaderStats",5)
		-- if no leaderstats is created anywhere else within 5 seconds then create our own
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		local role = Instance.new("StringValue")
		role.Name = "Role"
		role.Value = rank
		role.Parent = leaderstats
	end
end)

-- PBS Admin used to use text chat service but has moved completley to a custom command console.
-- The chat un-archiver functionality has remained however to avoid extra dependancies.
local TextChannels = textChatService:WaitForChild("TextChannels")
local TextChatCommands = textChatService:WaitForChild("TextChatCommands")
TextChannels.Archivable = false
TextChatCommands.Archivable = false

local messagePlayer = Instance.new("RemoteEvent")
messagePlayer.Name = "PBSAdminRemote"
messagePlayer.Archivable = false
messagePlayer.Parent = replicatedStorage

messagePlayer.OnServerEvent:Connect(function(player: Player, command: string)
	
end)

players.PlayerRemoving:Connect(function(player: Player)
	perms.PlayerRemoving(player)
end)