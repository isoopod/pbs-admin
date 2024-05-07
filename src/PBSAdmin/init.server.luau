--[[ 
See comments at start of the Permissions module for details on how to add permissions in studio
Use this to give yourself owner

Insert tools you want only members+ to have
same applies for GUIs, this can also be used to give the player local scripts and other content, since you can't insert to PlayerScripts on server
Please note that guis cannot rely on ResetOnRespawn otherwise they will be removed if the character resets, and not added back until rejoining

COMMANDS
{use userid} true or false, modifier to {player} to take a full userid number instead of matching a string to a player in a server
{player} matches to any player who's name starts with {player} provided there is only one match
{role} is the correct role name (as to not create random roles)
? indicates field not needed

/role {use userid} {player} {role?}
/tool {player}

Auto member assignment for those with trusted on the discord requires the RoVer API
RoVer API access requires the API key. I can't give this out to everyone (that would be a disaster)
If you would like the API Key, send a message to @isoopod for the key and instructions on how to set it up
I will only give this key if you agree not to make modifications to how it is used in this script that would 
increase the chance of it being abused, and agree not to share the key 
The API key may also be regenerated (effects all using the key) at any point in time, however if you still need the key I will provide the new one
RoVer permissions will only work in live servers or Team Tests due to how secrets work

SCRIPT ATTRIBUTES
leaderstats | if we should show the users role in leaderstats (will wait to see if leaderstats is created before falling back to creating a new leaderstats)
isVerified_Only | Only players who have verified a non VOIP phone number or government id on their account can have permissions. (in studio everyone is verified for testing)
This is pretty strict so i'd only use this if you are having serious issues with alts, meaning only owners can give an unverified player permissions
]]
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local textChatService = game:GetService("TextChatService")
local Command = require(script.Command)
local offlinePlayer = require(script.offlinePlayer)
local perms = require(script.Permissions)

local function giveTools(player: Player)
	local function parentTools(container: Instance)
		for _,v in script.Tools:GetChildren() do
			v:Clone().Parent = container
		end
	end
	
	parentTools(player:WaitForChild("Backpack"))
	parentTools(player:WaitForChild("StarterGear"))
	
	for _,v in script.GUIs:GetChildren() do
		local c = v:Clone()
		if c:IsA("ScreenGui") then
			c.ResetOnSpawn = false
		end
		c.Parent = player:WaitForChild("PlayerGui")
	end
end

-- needs to run first
players.PlayerAdded:Connect(function(player: Player) 
	local rank = perms.GetUserPermissions(player.UserId)
	local rankValue = perms.roleValues[rank]
	
	if rankValue == -1 then
		player:Kick("You are banned from this PBS")
	end
	
	if rankValue >= 2 then
		local adminLocal = script.PBSAdmin_Local:Clone()
		adminLocal.Parent = player:WaitForChild("PlayerGui")
	end
	
	if rankValue >= 1 then
		giveTools(player)
		table.insert(Command.Members,player.UserId)
	end

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

local TextChannels = textChatService:WaitForChild("TextChannels")
local TextChatCommands = textChatService:WaitForChild("TextChatCommands")

TextChannels.Archivable = false
TextChatCommands.Archivable = false

local messagePlayer = Instance.new("RemoteEvent")
messagePlayer.Name = "PBSAdminRemote"
messagePlayer.Archivable = false
messagePlayer.Parent = replicatedStorage

local cmdRole = Instance.new("TextChatCommand")
cmdRole.AutocompleteVisible = false
cmdRole.Name = "RoleCommand"
cmdRole.PrimaryAlias = "/role"
cmdRole.Archivable = false
cmdRole.Parent = TextChatCommands

local cmdTool = Instance.new("TextChatCommand")
cmdTool.AutocompleteVisible = false
cmdTool.Name = "ToolCommand"
cmdTool.PrimaryAlias = "/tool"
cmdTool.Archivable = false
cmdTool.Parent = TextChatCommands

function matchPlayer(player: Player, name: string, useUserid: string?): Player? | offlinePlayer.OfflinePlayer?
	if not name then return nil end
	useUserid = useUserid and string.lower(useUserid) or "false"
	
	if useUserid == "false" then
		-- just match a player in the server
		local players = players:GetPlayers()

		for i = 1,#players do
			if (string.find(string.lower(players[i].Name), name) == 1) then
				return players[i]
			end
		end
	elseif useUserid == "true" then
		-- match a user by their exact userid and return an offlineplayer to stand in
		local userId = tonumber(name)
		if typeof(userId) ~= "number" then return nil end
		local s,user:string = pcall(players.GetNameFromUserIdAsync,players,userId)
		if s then
			local offlineUser = offlinePlayer.new(user,userId)
			return offlineUser
		end 
	else
		messagePlayer:FireClient(player,`/role expects arg 1 to be "true" or "false" \n see "/role -help" for detailed use instructions`, "Error")
	end

	return nil
end

type textsource = {UserId: number}

local function cmdRoleF(originTextSource: TextSource | textsource, unfilteredText: string)
	local player = players:GetPlayerByUserId(originTextSource.UserId)
	local rank = perms.GetUserPermissions(originTextSource.UserId)
	local rankValue = perms.roleValues[rank]
	if player and rankValue >= 2 then
		local words = string.split(unfilteredText," ")
		if not words[2] then return end
		if words[2] == "-help" then messagePlayer:FireClient(player,"Changes a players role. Format: /role {use userid} {player name} {valid role} \n use userid should be either true or false \n player name should match the start of someones name in the server if use userid is false, otherwise an exact userid \n role can be left blank to remove their role entirely"); return end
		local other = matchPlayer(player, words[3], words[2])
		if not other then
			messagePlayer:FireClient(player,`No single player matching {words[3]}`, "Error")
			return
		end
		if rankValue ~= 3 then -- owners can do whatever
			local otherRank = perms.GetUserPermissions(other.UserId)
			if perms.roleValues[otherRank] >= rankValue then
				messagePlayer:FireClient(player,`You do not have permissions to edit {otherRank} {other}`,"Error")
				return
			end
		end
		local role = words[4] or ""
		local roleValue = perms.roleValues[role]
		local StarterGear = other:FindFirstChild("StarterGear") -- Also used to differ offline players from in-game players
		if script:GetAttribute("isVerified_Only") and roleValue > 0 and StarterGear then
			if rank ~= "owner" and not (runService:IsStudio() or other:IsVerified()) then
				messagePlayer:FireClient(player,`{other} is not verified, only an owner can give this person permissions`)
				return
			end
		end
		if roleValue then
			perms.EditPersistentRole(other.UserId,role)
			messagePlayer:FireClient(player, `{other} now has role {role}.`)
			if script:GetAttribute("leaderstats") then
				other.leaderstats.Role.Value = role
			end
			StarterGear = other:FindFirstChild("StarterGear")
			if roleValue == -1 and StarterGear then
				other:Kick("You have been banned.")
			elseif roleValue == 0 and StarterGear then
				if other.Character and other.Character:FindFirstChild("Humanoid") then other.Character.Humanoid:UnequipTools() end
				for _,v in script.Tools:GetChildren() do
					if other.Backpack:FindFirstChild(v.Name) then other.Backpack[v.Name]:Destroy() end
					if other.StarterGear:FindFirstChild(v.Name) then other.StarterGear[v.Name]:Destroy() end
				end
				for _,v in script.GUIs:GetChildren() do
					if other.PlayerGui:FindFirstChild(v.Name) then other.PlayerGui[v.Name]:Destroy() end
				end
			elseif not table.find(Command.Members,other.UserId) and StarterGear then
				giveTools(other)
				table.insert(Command.Members,other.UserId)
			end
			if roleValue > 1 then
				if not other.PlayerGui:FindFirstChild("PBSAdmin_Local") then
					local adminLocal = script.PBSAdmin_Local:Clone()
					adminLocal.Parent = other:WaitForChild("PlayerGui")
				end
			else
				if other.PlayerGui:FindFirstChild("PBSAdmin_Local") then other.PlayerGui.PBSAdmin_Local:Destroy() end
			end
		else
			local formatRoles = ""
			for i in perms.roleValues do
				formatRoles = string.format("%s%q, ",formatRoles,i)
			end
			messagePlayer:FireClient(player,`{role} does not exist! valid roles: {formatRoles}`, "Error")
		end
	end
end

local function cmdToolF(originTextSource: TextSource | textsource, unfilteredText: string)
	local player = players:GetPlayerByUserId(originTextSource.UserId)
	local rank = perms.GetUserPermissions(originTextSource.UserId)
	local rankValue = perms.roleValues[rank]
	if player and rankValue >= 2 then
		local words = string.split(unfilteredText," ")
		if not words[2] then return end
		if words[2] == "-help" then messagePlayer:FireClient(player,"Gives a player tools. Can be useful to give someone tools for that session only. Format: /tool {player name}"); return end
		local other = matchPlayer(player, words[2])
		if not other then
			messagePlayer:FireClient(player,`No single player matching {words[2]}`, "Error")
			return
		end
		giveTools(other)
		messagePlayer:FireClient(player, `{other} has been given tools.`)
	end
end

cmdRole.Triggered:Connect(cmdRoleF) 
cmdTool.Triggered:Connect(cmdToolF) 

messagePlayer.OnServerEvent:Connect(function(player: Player, command: string)
	if perms.roleValues[perms.GetUserPermissions(player.UserId)] < 2 then
		perms.EditPersistentRole(player.UserId,"banned")
		player:Kick("Good one")
	end
	
	local textsource = {UserId = player.UserId}
	local cmd = string.split(command, " ")[1]
	if cmd == "/role" then
		cmdRoleF(textsource,command)
	elseif cmd == "/tool" then
		cmdToolF(textsource,command)
	end
end)

players.PlayerRemoving:Connect(function(player: Player)
	perms.PlayerRemoving(player)
	local index = table.find(Command.Members,player.UserId)
	if index then
		table.remove(Command.Members,index)
	end
end)