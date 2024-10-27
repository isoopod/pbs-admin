local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientCommands = require(script.Parent.ClientCommands)

local get: RemoteFunction = ReplicatedStorage:WaitForChild("PBSAdminGetAutofill")

local api = {}

api.autofill = {}

function api.buildAutofill()
	api.autofill = {
		-- Y/N confirmation 'commands'
		["Y"] = {},
		["N"] = {},
	}

	for name, syntax in get:InvokeServer() do
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
