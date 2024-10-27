--[[ 
See comments at start of the Permissions module for details on how to add permissions in studio
Use this to give yourself owner

See the GitHub (https://github.com/isoopod/pbs-admin) for further instructions and documentation
]]
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Command = require(script.Command)
local Permissions = require(script.Permissions)
local perms = require(script.Permissions)

-- Bytenet integration
local Bytenet
-- If you are using PBS Admin with ByteNet outside of PBS:Rewrite, you will probably need to change the paths here and in PBSAdmin_Local
if replicatedStorage:FindFirstChild("Utils") then
	if replicatedStorage.Utils:FindFirstChild("ByteNetPackets") then
		if replicatedStorage.Utils.ByteNetPackets:FindFirstChild("PBSAdminPackets") then
			Bytenet = require(replicatedStorage.Utils.ByteNetPackets.PBSAdminPackets)
		end
	end
end

local externalLeaderstatsDetected = nil

-- Initialize the commands
Command.generateCommands()

local function PlayerAdded(player: Player)
	-- Timeout thread if player quits before character loads
	local thread
	task.delay(60, function()
		if thread and ({ running = true, suspended = true })[coroutine.status(thread)] then
			task.cancel(thread)
		end
	end)

	local rank = perms.GetUserPermissions(player.UserId)

	if script:GetAttribute("leaderstats") then
		local leaderstats = player:WaitForChild("LeaderStats", externalLeaderstatsDetected == false and 0 or 5)
		externalLeaderstatsDetected = leaderstats ~= nil
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
		if not player.Character then
			player.CharacterAdded:Wait()
		end
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
				local desc = players:GetHumanoidDescriptionFromUserId(player.CharacterAppearanceId)
				local morph = players:CreateHumanoidModelFromDescription(desc, rigtype)
				morph:PivotTo(character:GetPivot())
				morph.Name = player.Name
				local oldChar = player.Character
				player.Character = morph
				morph.Parent = workspace
				oldChar:Destroy()
			end
		end

		if script:GetAttribute("resetAssetsOnDeath") then
			Command.PublicUtils.GiveToolsForRole(player :: any, rank)
		end
	end)
end

players.PlayerAdded:Connect(PlayerAdded)
for _, v in players:GetPlayers() do
	task.spawn(PlayerAdded, v)
end

if not script:GetAttribute("resetAssetsOnDeath") then
	local gui: ScreenGui? = script.RoleAssets:FindFirstChild("PBSAdmin_Local", true) :: any
	if gui then
		gui.ResetOnSpawn = false
	end
end

local messagePlayer, GetAutofill
if not Bytenet then
	messagePlayer = Instance.new("RemoteEvent")
	messagePlayer.Name = "PBSAdminRemote"
	messagePlayer.Archivable = false
	messagePlayer.Parent = replicatedStorage

	GetAutofill = Instance.new("RemoteFunction")
	GetAutofill.Name = "PBSAdminGetAutofill"
	GetAutofill.Archivable = false
	GetAutofill.Parent = replicatedStorage
end

local cachedCommands = {}

local function handleCommand(player: Player, command: string)
	local rank = Permissions.roleValues[Permissions.GetUserPermissions(player.UserId)]
	-- Check if the user is using the -help command
	local splitCommand = string.split(command, " ")
	if splitCommand[2] == "-help" then
		local cmd = Command.new(splitCommand[1])
		if cmd then
			messagePlayer:FireClient(player, 2, cmd._behaviour.help)
		else
			messagePlayer:FireClient(player, 1, "Invalid command")
		end
		return
	end
	-- Handle verification of previous command if applicable
	if command:lower() == "n" then
		messagePlayer:FireClient(player, 2, "")
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
		messagePlayer:FireClient(player, response, body)
		cachedCommands[player] = nil
	else
		cachedCommands[player] = nil
		local cmd = Command.new(splitCommand[1])
		if cmd then
			if cmd._behaviour.minRank > rank then
				messagePlayer:FireClient(player, 1, "You do not have permissions to execute this command.")
				return
			end

			local aliasData = cmd._behaviour.aliases and cmd._behaviour.aliases[splitCommand[1]]
			local response, body = cmd(player, false, aliasData, unpack(splitCommand, 2))
			messagePlayer:FireClient(player, response, body)
			if response == 3 then -- cache for verification
				cachedCommands[player] = command
			end
		else
			messagePlayer:FireClient(player, 1, "Invalid command")
		end
	end
end

if Bytenet then
	Bytenet.ExecuteCommand.listen(function(data, player)
		if not player then
			return
		end
		handleCommand(player, data)
	end)
elseif messagePlayer then
	messagePlayer.OnServerEvent:Connect(handleCommand)
end

local function handleAutofill(player: Player, fullInfo: boolean?): { [string]: { string | { string } } }
	local rank = perms.GetUserPermissions(player.UserId)
	if fullInfo then
		return Command.getCmdInformationForRank(rank)
	end
	return Command.getAutofillForRank(rank)
end

if Bytenet then
	Bytenet.GetAutofill.listen(function(data, player)
		if not player then
			return
		end
		local autofill = handleAutofill(player, data)
		-- split autofill into sets and singletons
		local sets, singletons = {}, {}
		for k, v in autofill do
			if type(v) == "string" then
				singletons[k] = v
			else
				sets[k] = v
			end
		end
		Bytenet.AutofillReturn.sendTo({ sets = sets, singletons = singletons }, player)
	end)
elseif GetAutofill then
	GetAutofill.OnServerInvoke = handleAutofill
end

players.PlayerRemoving:Connect(function(player: Player)
	perms.PlayerRemoving(player)
end)
