local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 4
cmd.aliases = {}
cmd.syntax = { "<number>" }

cmd.help = [[Inserts a set from Pizzaboxers set archive, first argument is a set id from pizzaboxer
]]

function insert(assetId, name, ModelParent)
	local InsertService = game:GetService("InsertService")
	local success, model = pcall(InsertService.LoadAsset, InsertService, assetId)
	if success and model then
		print(assetId)
		model.Parent = ModelParent
		model.Name = name
		model:SetAttribute("Image", assetId)
	end
end

cmd.__call = function(
	self: command.Command,
	player: Player,
	verified: boolean,
	aliasData: any?,
	...: string?
): (number, string)
	local args = { ... }
	local other = args[1]

	if player and other then
		if self:UserHasPermissionsForCommand(player) then
			local target = self:GetPlayer(player, other, true)
			if other then
				local HTTPS = game:GetService("HttpService")
				if HTTPS then
					local URL_ASTROS = "https://sets.pizzaboxer.xyz/api/sets/" .. other .. "/assets?page=1"
					local URL_1 = "https://sets.pizzaboxer.xyz/api/sets/" .. other
					-- Make the request to our endpoint URL
					local response = HTTPS:GetAsync(URL_ASTROS)
					local response2 = HTTPS:GetAsync(URL_1)
					-- Parse the JSON response
					local data = HTTPS:JSONDecode(response)
					local set = HTTPS:JSONDecode(response2)
					local setn = set.name
					local ModelParent = Instance.new("Folder")
					ModelParent.Name = setn
					ModelParent.Parent = game.ReplicatedStorage.PBSTools.Sets
					-- Information in the data table is dependent on the response JSON
					print(data.items[1].assetId)
					if data then
						for i = 1, data.itemCount do
							insert(data.items[i].assetId, data.items[i].assetName, ModelParent)
						end
						return self.Responses.Success, "Set Imported"
					else
						return self.Responses.Error, "Invalid"
					end
				else
					return self.Responses.Error, "Enable HTTP Service"
				end
			else
				return self.Responses.Error,
					`Other player matching '{target}' not found, make sure they aren't the only person with that approximate name, or you put a '#' in front for a UserId`
			end
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
