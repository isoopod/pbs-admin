--[[ 
See comments at start of the Permissions module for details on how to add permissions in studio
Use this to give yourself owner

See the GitHub (https://github.com/isoopod/pbs-admin) for further instructions and documentation
]]

local Players = game:GetService("Players")

local Command = require(script.Command)
local Permissions = require(script.Permissions)

-- PakNet integration
-- If you are not using PBS Admin with rewrite, you may have to change the path the PakNet in the Command module,
-- as well as in the client Utils module. (should be at the bottom of both modules)
local PakNet = Command.PublicUtils.PakNet

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
		PakNet.CommandReturn:Fire(player, response, body)
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

PakNet.ExecuteCommand.OnEvent:Connect(handleCommand)

PakNet.GetAutofill.OnInvoke = function(player, fullInfo): { syntax: { [string]: { string | { string } } }, help: { [string]: string }? }
	local rank = Permissions.GetUserPermissions(player.UserId)
	if fullInfo then return Command.getCmdInformationForRank(rank) end
	return { syntax = Command.getAutofillForRank(rank) }
end

Players.PlayerRemoving:Connect(function(player: Player)
	Permissions.PlayerRemoving(player)
end)
