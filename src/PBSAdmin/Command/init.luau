--!strict 

--[[ Command
	Handles organising and generating commands to make a really simple API when using them, also contains some util methods for commands
	
	call Command.generateCommands to automatically generate all commands, then when you need to index a specific command call .new with the command name
	Aliases are also generated, sharing a reference to the main command object in the .Commands dictionary
--]]

--local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local offlinePlayer = require(script.Parent.offlinePlayer)
local permissions = require(script.Parent.Permissions)

--local messagePlayer = replicatedStorage:WaitForChild("PBSAdminRemote")

type cmd = {
	config: {
		minRank: number; -- the min rank (see permissions module) to call the command
		aliases: {string};
		syntax: {string | {string}};
		
		__tostring: ()->string;
		__call: (...any)->string?;
	};
}

local Command = {};
local CommandClass = {metatable = {__index = Command}};
export type Command = {
	ClassName: "Command";
	
	GetPlayer: (self: Command, player: Player, name: string, useUserId : string?)->(Player?);
	UserHasPermissionsForCommand: (self: Command, player: Player)->boolean;
	CanUserModifyOther: (self: Command, player: Player, other: Player)->boolean;
	IsUserVerified: (self: Command, player: Player, other: Player)->boolean;
	GiveToolsForRole: (self: Command, player: Player, role: string)->();
	Destroy: (self: Command)->();
};
type _Command = Command & {
	_behaviour: cmd;
};

Command.ClassName = "Command";

-- may return an 'offline player' which just contains essential information, check for a real player by calling FindFirstChild on something that should be there or checking the character exists
function Command:GetPlayer(player: Player, other: string, useUserid: string?): Player? | offlinePlayer.OfflinePlayer?
	self = self :: _Command
	
	if not other then return nil end
	useUserid = useUserid and string.lower(useUserid) or "false"

	if useUserid == "false" then
		-- just match a player in the server
		-- OR if the other is 'me' then return the player
		if other == "me" then
			return player
		end
		
		local players = players:GetPlayers()

		for i = 1,#players do
			if (string.find(string.lower(players[i].Name), other) == 1) then
				return players[i]
			end
		end
	elseif useUserid == "true" then
		-- match a user by their exact userid and return an offlineplayer to stand in
		local userId = tonumber(other)
		if typeof(userId) ~= "number" then return nil end
		local s,user:string = pcall(players.GetNameFromUserIdAsync,players,userId)
		if s then
			local offlineUser = offlinePlayer.new(user,userId)
			return offlineUser
		end 
	end

	return nil
end

function Command:UserHasPermissionsForCommand(player: Player): boolean
	self = self :: _Command
	
	local rank = permissions.GetUserPermissions(player.UserId)
	if permissions.roleValues[rank] >= self._behaviour.config.minRank then
		return true
	end
	
	return false
end

function Command:CanUserModifyOther(player: Player, other: Player): boolean
	if permissions.roleValues[permissions.GetUserPermissions(player.UserId)] < permissions.roleValues[permissions.GetUserPermissions(other.UserId)] and permissions.GetUserPermissions(player.UserId) ~= "owner" then
		return false
	end
	return true
end

-- when isVerified_Only is enabled then check if the user has phone or government id attached to their account, otherwise returns true
function Command:IsUserVerified(player: Player, other: Player): boolean
	if script.Parent:GetAttribute("isVerified_Only") and permissions.GetUserPermissions(player.UserId) ~= "owner" then
		if not other:IsVerified() then
			return false
		end
	end
	return true
end

function Command:GiveToolsForRole(player: Player&{Backpack: Backpack, StarterGear: StarterGear, PlayerGui: PlayerGui}, role: string): ()
	CommandClass.PublicUtils.GiveToolsForRole(player, role)
end

function Command:Destroy(): ()
	self = self :: _Command
	--TODO: Implement me
end

-- stores all commands in a dictionary
CommandClass.Commands = {}

-- Generate a new command object from the selected behaviour module
function CommandClass.new(commandName: string): Command
	-- dont create a new command if one already exists, instead return the one thats already been created
	if CommandClass.Commands[commandName] then return CommandClass.Commands[commandName] end
	
	local component:ModuleScript = script:WaitForChild(commandName)
	local success,behaviour:cmd = pcall(require, component)
	assert(success, `{commandName} is not a valid command`)
	local metatable = CommandClass.metatable
	metatable.__tostring = behaviour.config.__tostring
	metatable.__call = behaviour.config.__call
	
	local self: _Command = setmetatable({}, metatable) :: any
	
	self._behaviour = behaviour
	
	CommandClass.Commands[commandName] = self
	-- generate aliases with reference to the main object
	for _,v in self._behaviour.config.aliases do
		CommandClass.Commands[v] = CommandClass.Commands[commandName]
	end
	
	return self
end

-- Generate commands from within the commands folder which can be accessed from the .Commands dictionary
function CommandClass.generateCommands(): ()
	for _,cmd:ModuleScript in script:GetChildren() do
		CommandClass.new(cmd.Name)
	end
end

CommandClass.PublicUtils = {}

local assets = {}
for _,i in script.Parent.RoleAssets:GetChildren() do
	for _,j in i:GetChildren() do
		table.insert(assets,j)
	end
end
-- Does not accept offlinePlayers
-- If called each time the character resets, you can use GUIs that reset on spawn
function CommandClass.PublicUtils.GiveToolsForRole(player: Player&{Backpack: Backpack, StarterGear: StarterGear, PlayerGui: PlayerGui}, role: string): ()
	if role == "" then role = "none" end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid") 
	
	-- Build a list of assets to give to the player
	-- where most assets from lower ranks may be shared with higher ranks
	local toClone = {}
	for _,v in assets do
		local rank = v.Parent.Name
		if rank ~= role and v:HasTag("DontShareWithHigherRank") then continue end
		if permissions.roleValues[if role == "none" then "" else role] >= permissions.roleValues[if rank == "none" then "" else rank]  then
			table.insert(toClone,v)
		end
	end

	-- Cleanup existing assets
	if humanoid then humanoid:UnequipTools() end
	for _,v in assets do
		local item = player.Backpack:FindFirstChild(v.Name)
		local item2 = player.StarterGear:FindFirstChild(v.Name)
		if item then item:Destroy() end
		if item2 then item2:Destroy() end

		local guiItem = player.PlayerGui:FindFirstChild(v.Name) 
		if guiItem then guiItem:Destroy() end
	end

	-- Apply assets for the player
	for _,v in toClone do
		if v:IsA("ObjectValue") then v = v.Value end

		if v:IsA("Tool") then
			v:Clone().Parent = player.StarterGear
			v:Clone().Parent = player.Backpack
		else
			v:Clone().Parent = player.PlayerGui
		end
	end
end

return CommandClass;