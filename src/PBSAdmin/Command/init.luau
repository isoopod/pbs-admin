--!strict 

--[[ Command
	Handles organising and generating commands to make a really simple API when using them, also contains some util methods for commands
	
	call Command.generateCommands to automatically generate all commands, then when you need to index a specific command call .new with the command name
	Aliases are also generated, sharing a reference to the main command object in the .Commands dictionary

	TODO: find a convenient way to pass all the command syntax over to the console gui
--]]

--local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local offlinePlayer = require(script.Parent.offlinePlayer)
local permissions = require(script.Parent.Permissions)

--local messagePlayer = replicatedStorage:WaitForChild("PBSAdminRemote")

export type cmd = {
	minRank: number; -- the min rank (see permissions module) to call the command
	aliases: {[string]: any};
	syntax: {string | {string}};
	help: string;

	__call: (self: Command, player: Player, verified: boolean, aliasData: any?, ...string?) -> (number, string);
}

local Command = {};
local CommandClass = {metatable = {__index = Command}};
export type Command = {
	ClassName: "Command";
	Responses: {Error: number, Success: number, Verify: number};
	
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
Command.Responses = {
	Error = 1;
	Success = 2;
	Verify = 3; --Y/N to verify the command
}

-- may return an 'offline player' which just contains essential information, check for a real player by calling FindFirstChild on something that should be there or checking the character exists
function Command.GetPlayer(self: _Command, player: Player, other: string, useUserid: string?): Player? | offlinePlayer.OfflinePlayer?
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

function Command.UserHasPermissionsForCommand(self: _Command, player: Player): boolean
	local rank = permissions.GetUserPermissions(player.UserId)
	if permissions.roleValues[rank] >= self._behaviour.minRank then
		return true
	end
	
	return false
end

function Command.CanUserModifyOther(self: _Command, player: Player, other: Player): boolean
	if permissions.roleValues[permissions.GetUserPermissions(player.UserId)] < permissions.roleValues[permissions.GetUserPermissions(other.UserId)] and permissions.GetUserPermissions(player.UserId) ~= "owner" then
		return false
	end
	return true
end

-- when isVerified_Only is enabled then check if the user has phone or government id attached to their account, otherwise returns true
function Command.IsUserVerified(self: _Command, player: Player, other: Player): boolean
	if script.Parent:GetAttribute("isVerified_Only") and permissions.GetUserPermissions(player.UserId) ~= "owner" then
		if not other:IsVerified() then
			return false
		end
	end
	return true
end

function Command.GiveToolsForRole(self: _Command, player: Player&{Backpack: Backpack, StarterGear: StarterGear, PlayerGui: PlayerGui}, role: string): ()
	CommandClass.PublicUtils.GiveToolsForRole(player, role)
end

function Command:Destroy(): ()
	self = self :: _Command
	--TODO: Implement me
end

-- stores all commands in a dictionary
CommandClass.Commands = {}

-- Generate a new command object from the selected behaviour module
function CommandClass.new(commandName: string): Command?
	-- dont create a new command if one already exists, instead return the one thats already been created
	if CommandClass.Commands[commandName] then return CommandClass.Commands[commandName] end
	
	local component:ModuleScript = script:WaitForChild(commandName,1)
	local success,behaviour:cmd = pcall(require, component)
	
	if not success then return end

	local metatable = table.clone(CommandClass.metatable)
	metatable.__call = behaviour.__call
	
	local self: _Command = setmetatable({}, metatable) :: any
	
	self._behaviour = behaviour
	
	CommandClass.Commands[commandName] = self
	-- generate aliases with reference to the main object
	for i,v in self._behaviour.aliases do
		CommandClass.Commands[i] = CommandClass.Commands[commandName]
	end
	
	return self
end

-- Generate commands from within the commands folder which can be accessed from the .Commands dictionary
-- or by using command.new with the name of the command
function CommandClass.generateCommands(): ()
	for _,cmd:ModuleScript in script:GetChildren() do
		CommandClass.new(cmd.Name)
	end
end

function CommandClass.getAutofillForRank(rank: string): {[string]: {string | {string}}}
	-- Iterate over all commands and if they are usable by rank then add their syntax for all their aliases
	local autofill = {}
	local rankValue = permissions.roleValues[rank]
	-- aliases are already generated in the commands table
	for name,v: _Command in CommandClass.Commands do
		if rankValue >= v._behaviour.minRank then
			autofill[name] = v._behaviour.syntax
		end
	end

	return autofill
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