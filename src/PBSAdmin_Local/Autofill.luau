local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientCommands = require(script.Parent.ClientCommands)

-- bytenet integration
local Bytenet
if ReplicatedStorage:FindFirstChild("Utils") then
	if ReplicatedStorage.Utils:FindFirstChild("ByteNetPackets") then
		if ReplicatedStorage.Utils.ByteNetPackets:FindFirstChild("PBSAdminPackets") then
			Bytenet = require(ReplicatedStorage.Utils.ByteNetPackets.PBSAdminPackets)
		end
	end
end

local get: RemoteFunction?
if not Bytenet then
	get = ReplicatedStorage:WaitForChild("PBSAdminGetAutofill")
end

local api = {}

api.autofill = {}

function api.buildAutofill()
	api.autofill = {
		-- Y/N confirmation 'commands'
		["Y"] = {},
		["N"] = {},
	}

	-- Get autofill
	local autofillTable = {}
	if Bytenet then
		task.defer(function()
			Bytenet.GetAutofill.send(false)
		end)
		local result = Bytenet.AutofillReturn.wait()
		-- reconstruct table
		for k, v in result.syntax do
			local newEntry = {}
			for _, source in v do
				for i: number, syntax: string | { string } in source do
					newEntry[i] = syntax
				end
			end
			autofillTable[k] = newEntry
		end
	elseif get then
		autofillTable = get:InvokeServer()
	end

	for name, syntax in autofillTable do
		api.autofill[name] = syntax
	end

	for k, v in ClientCommands.cmdData do
		api.autofill[k] = v.syntax
	end
end

return api :: {
	autofill: { [string]: { string | { string } } },

	buildAutofill: () -> (),
}
