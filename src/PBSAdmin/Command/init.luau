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

--[=[
	@prop minRank number
	@within Handler
	Minimum rank needed to call the command.   
	The default commands all have minRank set to 3 or 4 by default, and it is up to you to change these how you want.   
	Rank maps to role so that:
	- 0 = no role
	- 1 = member
	- 2 = trusted
	- 3 = admin
	- 4 = owner  
]=]

--- @prop aliases {[string]: any}?
--- @within Handler
--- @tag Optional
--- Aliases are extra names aside from the module name that can be used to execute the command.
--- Aliases may have additional alias data to distinguish what alias called the command (see __call aliasData argument)
--- The main command has nil for aliasData, and it is up to you how to organize the alias data for your command (hence the any type)

--[=[
	@prop syntax {string | {string}}
	@within Handler
	This is used for the autocomplete, and should be an array of strings / arrays of strings.
	When an array of strings is used, each item from that will be used for that auto complete entry.   
	Single strings surrounded by angled brackets will show up in the command bar as a hint but do not autofill with tab.   
	Additionally, there are some special psuedo-alias syntax members that can be used:
	- `<player>` turns into the name and display names of each player, plus 'me'
	- `<player(s)>` shows as <player> and adds 'all' 'others' and 'team' for bulk operations
	- `<player / #userid>` identical to <player> but indicates to the user they can use userids for this argument
	- `<boolean>` turns into 'true' and 'false'
	- `<number>` will show an error if the argument does not turn into a number
]=]

--- @prop help string
--- @within Handler
--- String that will be returned when the command is fired with the first argument as --help

--- @prop aliasHelp {[string]: string}?
--- @within Handler
--- @tag Optional
--- Overwrites the help string for aliases, for when functionality may change

--[=[
	@function __call
	@within Handler
	
	@param self Command
	@param player Player -- The player who called the command
	@param verified boolean -- If the command has been verified for commands that use the verify response type
	@param aliasData any? -- Data assigned to the alias that was called. Main command will always be nil
	@param ... ...string? -- Variadic containing the arguments passed to the command.

	@return number -- This should be a value from Command.Responses
	@return string -- Message to be displayed in the console

	This is the function that will be called when the command is executed. 
	Although this is called Handler(), it is really the __call metamethod. 
	It should be declared as:
	```lua
	function cmd.__call(self, player, verified, aliasData, ...): (number, string)
	-- OR with explicit types
	function cmd.__call(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	```
	
	:::danger
	The function MUST return a Response number and output text no matter what. Yeilding for extended periods of time is not recommended, unless in a seperate thread
	that does not slow down return value.
	:::

	Since the command arguments are passed in as a variadic, you can get them as a table
	```lua
		local args = {...}
		local arg1 = args[1]
		local arg2 = args[2]
	```
	:::note
	You need to make sure that each argument is not nil, as the command may be executed without all arguments.
	The arguments passed in the variadic will all be strings, even when using psuedo-alias syntax such as `<number` or `<boolean>`. 
	You will have to convert them to the respective values yourself
	:::

	You will want to use the utilities provided from self (see Command)
]=]

--[=[
	Handles the data and execution of a command. Should be placed under the Command module in the PBSAdmin script.  
	The name of the module will be the main name for your command, in other words what you type in to execute it.
	Because of this, you should make sure you dont have any commands with the same names/aliases

	When writing handlers, the standard name for the return table is cmd. This is not neccessary but the docs assume this name is used.
	Handlers are declared as:
	```lua
	local command = require(script.Parent)

	local cmd: command.cmd = {} :: command.cmd
	```

	@class Handler
]=]

export type cmd = {
	minRank: number, -- the min rank (see permissions module) to call the command
	aliases: { [string]: any }?,
	syntax: { string | { string } },
	help: string,
	aliasHelp: { [string]: string }?, -- Replaces the help info for specific aliases of the command

	__call: (self: Command, player: Player, verified: boolean, aliasData: any?, ...string?) -> (number, string),
}

--[=[
	Enum used to indicate the return status of the command. Must be specified in each return from the call function.
	@interface Responses
	@tag Enum
	@within Command
	.Error 1 -- Something went wrong when executing the command, output is red
	.Success 2 -- The command executed correctly, output is normal
	.Verify 3 -- For sensitive commands, verify something with the user before completing the command
	.Minimize 4 -- If the return status is not particularly important, you can use Minimize to grey it out
	.Warning 5 -- Indicate something has gone slightly wrong, output is yellow
]=]

--- @prop ClassName string
--- @within Command
--- @readonly

--- @prop Responses Responses
--- @within Command
--- @readonly
--- @tag Enum
--- Access the `Responses` EnumItems through this member.

--- @prop _Behavior unknown
--- @within Command
--- @private
--- Points to the Command Handler

--[=[
	Standard library for commands.
	Contains collection of common methods and enums for use in commands
	@class Command
	@__index Command
]=]
local Command = {}
local CommandClass = { metatable = { __index = Command } }
export type Command = {
	ClassName: "Command",
	Responses: { Error: number, Success: number, Verify: number },

	GetPlayer: (self: Command, player: Player, name: string, canUseUserId: boolean?) -> Player?,
	GetBulkPlayers: (self: Command, player: Player, name: string) -> { Player },
	FormatUsername: (self: Command, player: Player) -> string,
	--UserHasPermissionsForCommand: (self: Command, player: Player) -> boolean, DEPRECATED, REMOVING IN FUTURE VERSION
	CanUserModifyOther: (self: Command, player: Player, other: Player) -> boolean,
	IsUserVerified: (self: Command, player: Player, other: Player) -> boolean,
	GiveToolsForRole: (self: Command, player: Player, role: string) -> (),
	Destroy: (self: Command) -> (),
}
type _Command = Command & {
	_behaviour: cmd,
}

Command.ClassName = "Command"
Command.Responses = {
	Error = 1,
	Success = 2,
	Verify = 3, --Y/N to verify the command
	Minimize = 4, --Greyed out response
	Warning = 5,
}

local function fuzzySearch(query: string, target: string): (number, boolean)
	-- Convert both query and target to lowercase for case-insensitive matching
	query = query:lower()
	target = target:lower()

	local queryLen = #query
	local targetLen = #target

	-- Early exit if query is longer than target
	if queryLen > targetLen then
		return 0, false
	end

	local queryIndex = 1
	local matchCount = 0

	-- Loop through each character of the target string
	for targetIndex = 1, targetLen do
		if queryIndex <= queryLen and query:sub(queryIndex, queryIndex) == target:sub(targetIndex, targetIndex) then
			-- Character match found, move to the next query character
			queryIndex += 1
			matchCount += 1
		end
	end

	-- Check if all characters in the query were matched
	local matched = (queryIndex > queryLen)

	-- Similarity score based on number of matches and length of the target
	local score = matchCount / targetLen

	return score, matched
end

-- may return an 'offline player' which just contains essential information, check for a real player by calling FindFirstChild on something that should be there or checking the character exists
--[=[
	Gets the closest matching player whose username or display name matches the `other` arg. Can be used with canUseUserId to get players that are offline.

	:::caution
	If using UserId, the return value may be an `OfflinePlayer`, which is a basic stand in for a player, and was only implemented with commands that dont affect
	characters in mind. You may have to filter out offline players which you can see examples for how to do here TODO: ADD LINK
	:::

	:::caution
	Since this works with both usernames and display names, if your command is sensitive you may want to verify with the user that the correct user was matched.
	:::
	
	@method GetPlayer
	@within Command
	@tag Command Handler
	@param player Player -- the player who called the command will be returned if other == "me"
	@param other string -- the string that will be fuzzy matched against each player to get the closest
	@param canUseUserId boolean? -- if we should be able to search for players by username by placing a # in front of the query
	@return Player -- May be `OfflinePlayer` if canUseUserId is true
]=]
function Command.GetPlayer(_self: _Command, player: Player, other: string, canUseUserId: boolean?): (Player | offlinePlayer.OfflinePlayer)?
	if not other then
		return nil
	end
	local useUserid = other:sub(1, 1) == "#"
	if not canUseUserId then
		useUserid = false
	end

	if useUserid == false then
		-- just match a player in the server
		-- OR if the other is 'me' then return the player
		if other == "me" then
			return player
		end

		local nameMap = {}
		for _, p in players:GetPlayers() do
			nameMap[p.Name] = p
			nameMap[p.DisplayName] = p
		end

		local closest
		local bestScore = 0

		for name in nameMap do
			local score, matched = fuzzySearch(name, other)
			if matched and score > bestScore then
				bestScore = score
				closest = name
			end
		end

		return nameMap[closest]
	else
		-- match a user by their exact userid and return an offlineplayer to stand in
		local userId = tonumber(other:sub(2))
		if typeof(userId) ~= "number" then
			return nil
		end
		local s, user: string = pcall(players.GetNameFromUserIdAsync, players, userId)
		if s then
			local offlineUser = offlinePlayer.new(user, userId)
			return offlineUser
		end
	end

	return nil
end

--[=[
	Functions like `GetPlayers` but enables the `all` `others` and `team` keywords which allows for affecting mutliple players at once.

	@method GetBulkPlayers
	@within Command
	@tag Command Handler
	@param player Player
	@param other string
	@return {Player}
]=]
function Command.GetBulkPlayers(self: _Command, player: Player, other: string): { Player }
	if other == "all" then
		return players:GetPlayers()
	end
	if other == "others" then
		local plrs = {}
		for _, v in players:GetPlayers() do
			if v ~= player then
				table.insert(plrs, v)
			end
		end
		return plrs
	end
	if other == "team" then
		local plrs = {}
		for _, v in players:GetPlayers() do
			if v.Team == player.Team then
				table.insert(plrs, v)
			end
		end
		return plrs
	end

	return { self:GetPlayer(player, other) :: Player }
end

--[=[
	Simple util to format usernames in the case the display name and username are different.
	Will be formatted as ***DisplayName (Username)*** when different or just ***Username*** when the same.

	:::danger
	Does not support OfflinePlayers
	:::

	@methid FormatUsername
	@within Command
	@tag Command Handler
	@param player Player
	@return string
]=]
function Command.FormatUsername(_self: _Command, player: Player): string
	return player.DisplayName == player.Name and player.Name or `{player.DisplayName} ({player.Name})`
end

--[=[
	Checks if the player calling the command actually has permisions to use it. You should probably include this one.

	@method UserHasPermissionsForCommand
	@within Command
	@tag Command Handler
	@deprecated v2.2.0 -- this is now checked before __call is called.
	@param player Player
	@return boolean 
]=]
function Command.UserHasPermissionsForCommand(_self: _Command, _player: Player): boolean
	warn(debug.traceback("UserHasPermissionsForCommand is deprecated and will be removed in a future release."))
	return true
end

--[=[
	Checks if the player has permissions to modify another user. If `player`'s rank is greater than `other`'s, and `other` is not an owner, then it will return true.

	@method UserHasPermissions
	@within Command
	@tag Command Handler
	@param player Player -- Player calling the command
	@param other Player -- Player we are checking if we can modify
	@return boolean
]=]
function Command.CanUserModifyOther(_self: _Command, player: Player, other: Player): boolean
	if
		permissions.roleValues[permissions.GetUserPermissions(player.UserId)] < permissions.roleValues[permissions.GetUserPermissions(other.UserId)]
		and permissions.GetUserPermissions(player.UserId) ~= "owner"
	then
		return false
	end
	return true
end

-- when isVerified_Only is enabled then check if the user has phone or government id attached to their account, otherwise returns true
--[=[
	Returns true if the other player has government id or a phone number verified to their roblox account. If `player` is an owner, will always return true.

	:::note
	This will only do anything if the isVerified_Only attribute is enabled on the PBSAdmin server script.
	:::

	@method IsUserVerified
	@within Command
	@tag Command Handler
	@param player Player -- The player calling the command
	@param player Player -- The player we are checking if has phone/id verification
	@return boolean
]=]
function Command.IsUserVerified(_self: _Command, player: Player, other: Player): boolean
	if script.Parent:GetAttribute("isVerified_Only") and permissions.GetUserPermissions(player.UserId) ~= "owner" and not other:IsVerified() then
		return false
	end
	return true
end

--[=[

]=]
function Command.GiveToolsForRole(_self: _Command, player: Player & { Backpack: Backpack, StarterGear: StarterGear, PlayerGui: PlayerGui }, role: string): ()
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
	if CommandClass.Commands[commandName] then
		return CommandClass.Commands[commandName]
	end

	local component: ModuleScript = script:WaitForChild(commandName, 1)
	local success, behaviour: cmd = pcall(require, component)

	if not success then
		return
	end

	local metatable = table.clone(CommandClass.metatable)
	metatable.__call = behaviour.__call

	local self: _Command = setmetatable({}, metatable) :: any

	self._behaviour = behaviour

	if CommandClass.Commands[commandName] then
		warn(`Multiple command handlers with the name or alias {commandName} detected! module: {component:GetFullName()}`)
	end
	CommandClass.Commands[commandName] = self
	-- generate aliases with reference to the main object
	if self._behaviour.aliases then
		for i in self._behaviour.aliases do
			if CommandClass.Commands[i] then
				warn(`Multiple command handlers with the name or alias {commandName} detected! module: {component:GetFullName()} alias: {i}`)
			end
			CommandClass.Commands[i] = CommandClass.Commands[commandName]
		end
	end

	return self
end

-- Generate commands from within the commands folder which can be accessed from the .Commands dictionary
-- or by using command.new with the name of the command
function CommandClass.generateCommands(): ()
	for _, cmd: ModuleScript in script:GetChildren() do
		CommandClass.new(cmd.Name)
	end
end

function CommandClass.getAutofillForRank(rank: string)
	-- Iterate over all commands and if they are usable by rank then add their syntax for all their aliases
	local autofill = {}
	local rankValue = permissions.roleValues[rank]
	-- aliases are already generated in the commands table
	for name, v: _Command in CommandClass.Commands do
		if rankValue >= v._behaviour.minRank then
			autofill[name] = v._behaviour.syntax
		end
	end

	return autofill
end

-- Same as autofill but returns as an array where key 1 is the syntax and key 2 is the help string
function CommandClass.getCmdInformationForRank(rank: string)
	-- Iterate over all commands and if they are usable by rank then add their syntax for all their aliases
	local autofill: { [string]: { any } } = {}
	local rankValue = permissions.roleValues[rank]
	-- aliases are already generated in the commands table
	for name, v: _Command in CommandClass.Commands do
		if rankValue >= v._behaviour.minRank then
			local help = v._behaviour.aliasHelp and v._behaviour.aliasHelp[name] or v._behaviour.help
			autofill[name] = { v._behaviour.syntax, help }
		end
	end

	return autofill
end

CommandClass.PublicUtils = {}

local assets = {}
for _, i in script.Parent.RoleAssets:GetChildren() do
	for _, j in i:GetChildren() do
		table.insert(assets, j)
	end
end
-- Does not accept offlinePlayers
-- If called each time the character resets, you can use GUIs that reset on spawn
function CommandClass.PublicUtils.GiveToolsForRole(
	player: Player & {
		Backpack: Backpack,
		StarterGear: StarterGear,
		PlayerGui: PlayerGui,
	},
	role: string
): ()
	if role == "" then
		role = "none"
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

	-- Build a list of assets to give to the player
	-- where most assets from lower ranks may be shared with higher ranks
	local toClone = {}
	for _, v in assets do
		local rank = v.Parent.Name
		if rank ~= role and v:HasTag("DontShareWithHigherRank") then
			continue
		end
		if permissions.roleValues[if role == "none" then "" else role] >= permissions.roleValues[if rank == "none" then "" else rank] then
			table.insert(toClone, v)
		end
	end

	-- Cleanup existing assets
	if humanoid then
		humanoid:UnequipTools()
	end
	for _, v in assets do
		local item = player.Backpack:FindFirstChild(v.Name)
		local item2 = player.StarterGear:FindFirstChild(v.Name)
		if item then
			item:Destroy()
		end
		if item2 then
			item2:Destroy()
		end

		local guiItem = player.PlayerGui:FindFirstChild(v.Name)
		if guiItem then
			guiItem:Destroy()
		end
	end

	-- Apply assets for the player
	for _, v in toClone do
		if v:IsA("ObjectValue") then
			v = v.Value
		end

		if v:IsA("Tool") then
			v:Clone().Parent = player.StarterGear
			v:Clone().Parent = player.Backpack
		else
			v:Clone().Parent = player.PlayerGui
		end
	end
end

return CommandClass
