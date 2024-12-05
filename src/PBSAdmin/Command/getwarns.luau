local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local command = require(script.Parent)

local datastore = DataStoreService:GetDataStore("PBSADMIN_WARNS")

local Bytenet = command.PublicUtils.Bytenet
local remote
if not Bytenet then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PBSADMIN_LOGS"
	remote.Archivable = false
	remote.Parent = ReplicatedStorage
end

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player / #userid>" }

cmd.help = [[Opens a list containing all the warnings for a player.]]

function cmd.__call(self: command.Command, player: Player, _, _, ...): (number, string)
	local args = { ... }
	local other = args[1]
	if other then
		local target = self:GetPlayer(player, other, true)
		if target then
			local s, warns = pcall(datastore.GetAsync, datastore, target.UserId)
			if s then
				local tbl = HttpService:JSONDecode(warns or "[]")
				if #tbl == 0 then return self.Responses.Error, `{target} had not recieved any warnings.` end

				if Bytenet then
					Bytenet.LOGS.sendTo(tbl, player)
				else
					remote:FireClient(player, tbl)
				end
				return self.Responses.Success, `Opened warnings for {target}`
			else
				return self.Responses.Error, `Datastore error: {warns}`
			end
		end
		return self.Responses.Error, "Could not find exactly one player with the given name or userid"
	end
	return self.Responses.Error, "Invalid parameters"
end

return cmd
