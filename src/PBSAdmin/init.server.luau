--[[ 
See comments at start of the Permissions module for details on how to add permissions in studio
Use this to give yourself owner

See the GitHub (https://github.com/isoopod/pbs-admin) for further instructions and documentation
]]

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")

local Command = require(script.Command)
local Permissions = require(script.Permissions)

local cloud_bans = script:GetAttribute("cloud_banlist") == true
local banlist: banlist
if cloud_bans then
	-- The banlist only works in saving places right now.
	assert(not script:GetAttribute("permsUsesDatastore"), "Cloud banlist cannot be used when permissions datastore is enabled")
	banlist = require(127735485924111) -- Using assetid requires to sync the banlist between universes

	local s, latestVersion = pcall(InsertService.GetLatestAssetVersionAsync(InsertService, 127735485924111))
	local loadedVersion = script:GetAttribute("__loadedBanlistVersion__")
	if s and loadedVersion ~= latestVersion then
		script:SetAttribute("__loadedBanlistVersion__", latestVersion)

		local function banUser(user: number)
			pcall(Players.BanAsync, Players, {
				UserIds = { user },
				ApplyToUniverse = true,
				Duration = -1,
				DisplayReason = "You have been permanently banned from this PBS.",
				PrivateReason = "CLOUD_BAN",
				ExcludeAltAccounts = false,
			})
		end

		if loadedVersion then
			-- Create a diff between the two versions, and use that to ban/unban additions/removals to the ban list
			-- Load the previous version
			local last: Model = InsertService:LoadAssetVersion(loadedVersion)
			local module = last:FindFirstChild("MainModule", true)
			if module then
				local s2, lastBanlist: { [number]: boolean } = pcall(require, module)
				if s2 then
					local added: banlist, removed: banlist = {}, {}

					-- Users added in the new ban list (present as true in new and not in old)
					for user in banlist do
						if not lastBanlist[user] then added[user] = true end
					end

					-- Users removed from the old ban list (present as true in old and not in new)
					for user in lastBanlist do
						if not banlist[user] then removed[user] = true end
					end

					for user in added do
						banUser(user)
					end

					for user in removed do
						pcall(Players.UnbanAsync, Players, {
							UserIds = { user },
							ApplyToUniverse = true,
						})
					end
				end
			end

			return
		else
			for user in banlist do
				banUser(user)
			end
		end
	end
end
type banlist = { [number]: boolean }

-- Bytenet integration
-- If you are not using PBS Admin with rewrite, you may have to change the path the ByteNet in the Command module,
-- as well as in the client Utils module. (should be at the bottom of both modules)
local Bytenet = Command.PublicUtils.Bytenet

-- Initialize the commands
Command.generateCommands()

local cacheLeaderstats
local function PlayerAdded(player: Player)
	-- Timeout thread if player quits before character loads
	local thread
	task.delay(60, function()
		if thread and ({ running = true, suspended = true })[coroutine.status(thread)] then task.cancel(thread) end
	end)

	local rank = Permissions.GetUserPermissions(player.UserId)
	if cloud_bans and banlist[player.UserId] then
		rank = "visitor"
		player:Kick("Unexpected error when joining.") -- Not actually an error or anything, they just managed to get in before their ban applied
	end

	if script:GetAttribute("leaderstats") then
		local leaderstats = if cacheLeaderstats then nil else player:WaitForChild("LeaderStats", 5)
		cacheLeaderstats = leaderstats == nil
		-- if no leaderstats is created anywhere else within 5 seconds then create our own
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		local role = Instance.new("StringValue")
		role.Name = "Role"
		role.Value = rank:gsub("^%l", string.upper) -- makes first character uppercase
		role.Parent = leaderstats
	end

	thread = task.spawn(function()
		if not player.Character then player.CharacterAdded:Wait() end
		Command.PublicUtils.GiveToolsForRole(player :: any, rank)
	end)

	player.CharacterAdded:Connect(function(character: any)
		-- If the player has a forced rig type apply it each time they respawn
		if player:GetAttribute("ForcedRigtype") then
			local rt: "R15" | "R6" = player:GetAttribute("ForcedRigtype") :: any
			local rigtype = Enum.HumanoidRigType[rt] :: Enum.HumanoidRigType
			local humanoid: Humanoid? = character:WaitForChild("Humanoid", 3)
			local current = humanoid and humanoid.RigType
			if rigtype and rigtype ~= current then
				local desc = Players:GetHumanoidDescriptionFromUserId(player.CharacterAppearanceId)
				local morph = Players:CreateHumanoidModelFromDescription(desc, rigtype)
				morph:PivotTo(character:GetPivot())
				morph.Name = player.Name
				local oldChar = player.Character
				player.Character = morph
				morph.Parent = workspace
				oldChar:Destroy()
			end
		end

		if script:GetAttribute("resetAssetsOnDeath") then Command.PublicUtils.GiveToolsForRole(player :: any, rank) end
	end)
end

Players.PlayerAdded:Connect(PlayerAdded)
for _, v in Players:GetPlayers() do
	task.spawn(PlayerAdded, v)
end

if not script:GetAttribute("resetAssetsOnDeath") then
	local gui: ScreenGui? = script.RoleAssets:FindFirstChild("PBSAdmin_Local", true) :: any
	if gui then gui.ResetOnSpawn = false end
end

local cachedCommands = {}

local function handleCommand(player: Player, command: string)
	local function commandReturn(response: number, body: string)
		Bytenet.CommandReturn.sendTo({ response = response, body = body }, player)

		-- Log commands
		if body ~= "Invalid command" and body ~= "You do not have permissions to execute this command." then table.insert(Command.logs, 1, `[{player}]: {command}`) end
	end

	local rank = Permissions.roleValues[Permissions.GetUserPermissions(player.UserId)]
	-- Check if the user is using the -help command
	local splitCommand = string.split(command, " ")
	if splitCommand[2] == "-help" then
		local cmd = Command.new(splitCommand[1])
		if cmd then
			commandReturn(2, cmd._behaviour.help)
		else
			commandReturn(1, "Invalid command")
		end
		return
	end
	-- Handle verification of previous command if applicable
	if command:lower() == "n" then
		commandReturn(2, "")
		cachedCommands[player] = nil
		return
	end
	if cachedCommands[player] and command:lower() == "y" then
		-- cached commands will definitely have a valid command
		local content = string.split(cachedCommands[player], " ")
		local cmd = Command.new(content[1])
		-- you dont have to worry minRank on cached commands either
		local aliasData = cmd._behaviour.aliases and cmd._behaviour.aliases[content[1]]
		local response, body = cmd(player, true, aliasData, unpack(content, 2))
		commandReturn(response, body)
		cachedCommands[player] = nil
	else
		cachedCommands[player] = nil
		local cmd = Command.new(splitCommand[1])
		if cmd then
			if cmd._behaviour.minRank > rank then
				commandReturn(1, "You do not have permissions to execute this command.")
				return
			end

			local aliasData = cmd._behaviour.aliases and cmd._behaviour.aliases[splitCommand[1]]
			local response, body = cmd(player, false, aliasData, unpack(splitCommand, 2))
			commandReturn(response, body)
			if response == 3 then -- cache for verification
				cachedCommands[player] = command
			end
		else
			commandReturn(1, "Invalid command")
		end
	end
end

Bytenet.ExecuteCommand.listen(function(data, player)
	if not player then return end
	handleCommand(player, data)
end)

local function handleAutofill(player: Player, fullInfo: boolean?): { syntax: { [string]: { string | { string } } }, help: { [string]: string }? }
	local rank = Permissions.GetUserPermissions(player.UserId)
	if fullInfo then return Command.getCmdInformationForRank(rank) end
	return { syntax = Command.getAutofillForRank(rank) }
end

Bytenet.GetAutofill.listen(function(data, player)
	if not player then return end
	local autofill = handleAutofill(player, data)

	-- process the packet
	-- bytenet cant deal with string | {stirng} so we have to send string and {string} as seperate maps per command to retain order
	local sendable = { syntax = {} }
	if data then sendable.help = {} end
	for k, v in autofill.syntax do
		local sets, singletons = {}, {}
		for i, syntax in v do
			if type(syntax) == "table" then
				sets[i] = syntax
			else
				singletons[i] = syntax
			end
		end
		sendable.syntax[k] = { sets = sets, singletons = singletons }
	end
	if data then
		for k, v in autofill.help do
			sendable.help[k] = v
		end
	end

	Bytenet.AutofillReturn.sendTo(sendable, player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	Permissions.PlayerRemoving(player)
end)
