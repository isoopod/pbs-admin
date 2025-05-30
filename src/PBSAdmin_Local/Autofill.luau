local ClientCommands = require(script.Parent.ClientCommands)
local Utils = require(script.Parent.Utils)

local PakNet = Utils.PakNet

local api = {}

api.autofill = {}

function api.buildAutofill()
	api.autofill = {
		-- Y/N confirmation 'commands'
		["Y"] = {},
		["N"] = {},
	}

	-- Get autofill
	local autofillTable = PakNet.GetAutofill:InvokeServer(false)

	for name, syntax in autofillTable do
		api.autofill[name] = syntax
	end

	for k, v in ClientCommands.cmdData do
		api.autofill[k] = v.syntax
	end
end

-- For cmds list
local cache
function api.getVerboseAutofill()
	if cache then return cache end
	-- Get autofill
	local autofillTable = PakNet.GetAutofill:InvokeServer(true)
	print(autofillTable)

	for k, v in ClientCommands.cmdData do
		local help = `[No role+] {v.help}`
		autofillTable[k] = { syntax = v.syntax, help = help }
	end

	cache = autofillTable
	return autofillTable
end

return api :: {
	autofill: { [string]: { string | { string } } },

	buildAutofill: () -> (),
	getVerboseAutofill: () -> { [string]: { syntax: { string | { string } }, help: string } },
}
