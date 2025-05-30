local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PakNet = require(ReplicatedStorage.Packages.PakNet)

return PakNet:Mount(script, {
	-- Attempt to execute a command --
	ExecuteCommand = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.String16),
		remoteType = "r",
		rateLimit = {
			limit = 30,
			window = 1,
		},
	}),

	-- Return information for a command
	CommandReturn = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.UInt8, PakNet.String16), -- response, body
		remoteType = "r",
		rateLimit = {
			limit = 0,
			window = 1,
		},
	}),

	-- Get autofill information from the server --
	-- The full table will have to be assembled by merging sets and singletons
	GetAutofill = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.Boolean),
		returns = PakNet:Schema(PakNet.Transformer(
			PakNet.Dictionary({
				syntax = PakNet.Map(
					PakNet.String16,
					PakNet.Dictionary({
						sets = PakNet.Map(PakNet.UInt8, PakNet.Array(PakNet.String16)),
						singletons = PakNet.Map(PakNet.UInt8, PakNet.String16),
					})
				),
				help = PakNet.Nullable(PakNet.Map(PakNet.String16, PakNet.String16)),
			}),
			function(autofill: { syntax: { [string]: { string | { string } } }, help: { [string]: string }? })
				local sendable = { syntax = {} }

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
				if autofill.help then
					sendable.help = {}
					for k, v in autofill.help do
						sendable.help[k] = v
					end
				end

				return sendable
			end,
			function(result)
				local autofillTable = {}

				for k, v in result.syntax do
					local newEntry = {}
					for _, source in v do
						for i: number, syntax: string | { string } in source do
							newEntry[i] = syntax
						end
					end
					if result.help then
						autofillTable[k] = { syntax = newEntry }
					else
						autofillTable[k] = newEntry
					end
				end
				if result.help then
					for k, v in result.help do
						autofillTable[k].help = v
					end
				end

				return autofillTable
			end
		)),

		remoteType = "f",
		timeout = 15,
		rateLimit = {
			limit = 1,
			window = 1,
		},
	}),

	-- Integrations for default commands --
	-- Note: custom commands wanting to make use of PakNet will need their own network module

	-- Message command --
	MSG = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.Dictionary({
			title = PakNet.String16,
			message = PakNet.String16,
			typewrite = PakNet.Boolean,
			duration = PakNet.Nullable(PakNet.Double),
		})),
		remoteType = "r",
		rateLimit = {
			limit = 20,
			window = 1,
		},
	}),

	-- Logs command --
	LOGS = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.Array(PakNet.String16)),
		remoteType = "r",
		rateLimit = {
			limit = 5,
			window = 1,
		},
	}),

	-- Hint command --
	HINT = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.Dictionary({
			message = PakNet.String16,
			duration = PakNet.Nullable(PakNet.Double),
		})),
		remoteType = "r",
		rateLimit = {
			limit = 5,
			window = 1,
		},
	}),

	-- History command --
	HISTORY = PakNet:DefineRemote({
		params = PakNet:Schema(PakNet.Array(PakNet.Dictionary({
			userid = PakNet.Double, -- Roblox has more userids than can fit in a u32, using a f64 should be good up to 9.7 quadrillion users.
			timestamp = PakNet.UInt32, -- This will become an issue on the 7th of February, 2106 at 06:28:15 UTC
			action = PakNet.String16,
			message = PakNet.String16,
			metadata = PakNet.Ref,
		}))),
		remoteType = "r",
		rateLimit = {
			limit = 5,
			window = 1,
		},
	}),
})
