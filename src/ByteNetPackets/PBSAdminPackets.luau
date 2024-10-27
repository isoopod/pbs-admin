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
			value = ByteNet.map(
				ByteNet.string,
				ByteNet.struct({
					sets = ByteNet.map(ByteNet.uint8, ByteNet.array(ByteNet.string)),
					singletons = ByteNet.map(ByteNet.uint8, ByteNet.string),
				})
			),
			reliabilityType = "reliable",
		}),
	}
end)
