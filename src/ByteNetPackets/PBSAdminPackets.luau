local ByteNet = require(game:GetService("ReplicatedStorage"):WaitForChild("Utils"):WaitForChild("ByteNet"))

return ByteNet.defineNamespace("PBSAdmin", function()
	return {
		-- Attempt to execute a command --
		ExecuteCommand = ByteNet.definePacket({
			value = ByteNet.string,
			reliabilityType = "reliable",
		}),

		-- Return information for the command --
		CommandReturn = ByteNet.definePacket({
			value = ByteNet.struct({
				response = ByteNet.uint8,
				body = ByteNet.string,
			}),
			reliabilityType = "reliable",
		}),

		-- Ask the server for autofill information --
		GetAutofill = ByteNet.definePacket({
			value = ByteNet.bool,
			reliabilityType = "reliable",
		}),

		-- Recieve autofill information --
		-- The full table will have to be assembled by merging sets and singletons
		AutofillReturn = ByteNet.definePacket({
			value = ByteNet.struct({
				syntax = ByteNet.map(
					ByteNet.string,
					ByteNet.struct({
						sets = ByteNet.map(ByteNet.uint8, ByteNet.array(ByteNet.string)),
						singletons = ByteNet.map(ByteNet.uint8, ByteNet.string),
					})
				),
				help = ByteNet.optional(ByteNet.map(ByteNet.string, ByteNet.string)),
			}),
			reliabilityType = "reliable",
		}),

		-- Integration for default commands --
		-- Note: custom commands wanting to integrate with Bytenet will need their own packets module

		-- Message command --
		MSG = ByteNet.definePacket({
			value = ByteNet.struct({
				title = ByteNet.string,
				message = ByteNet.string,
				typewrite = ByteNet.bool,
				duration = ByteNet.optional(ByteNet.float64),
			}),
			reliabilityType = "reliable", -- unreliable remotes cannot send very much data
		}),

		-- Logs command --
		LOGS = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.string),
			reliabilityType = "reliable",
		}),

		-- Hint command --
		HINT = ByteNet.definePacket({
			value = ByteNet.struct({
				message = ByteNet.string,
				duration = ByteNet.optional(ByteNet.float64),
			}),
			reliabilityType = "reliable",
		}),

		-- History command --
		HISTORY = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.struct({
				userid = ByteNet.float64, -- Roblox has more userids than can fit in a u32, using a f64 should be good up to 9.7 quadrillion users.
				timestamp = ByteNet.uint32, -- This will become an issue on the 7th of February, 2106 at 06:28:15 UTC
				action = ByteNet.string,
				message = ByteNet.string,
				metadata = ByteNet.unknown,
			})),
			reliabilityType = "reliable",
		}),
	}
end)
