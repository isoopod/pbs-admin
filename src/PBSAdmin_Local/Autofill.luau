local ClientCommands = require(script.Parent.ClientCommands)
local Utils = require(script.Parent.Utils)

local Bytenet = Utils.Bytenet

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
	local autofillTable = {}

	task.defer(function()
		Bytenet.GetAutofill.send(true)
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
		autofillTable[k] = {}
		autofillTable[k].syntax = newEntry
	end
	for k, v in result.help do
		autofillTable[k].help = v
	end

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
