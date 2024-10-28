local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 4
cmd.syntax = { "<number>", "<boolean>" }

cmd.help = [[Inserts a set from InsertService or Pizzaboxers set archive, first argument is a asset/set id, second if true means it looks for pizza sets]]

function insert(assetId, name, ModelParent)
	local InsertService = game:GetService("InsertService")
	local success, model = pcall(InsertService.LoadAsset, InsertService, assetId)
	if success and model then
		print(assetId)
		model.Parent = ModelParent
		model.Name = name
		model:SetAttribute("ID", assetId)
		return model
	end
	return nil
end

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local boolean1 = args[2] and args[2]:lower() or ""
	if player and other then
		local HTTPS = game:GetService("HttpService")
		if HTTPS and boolean1 == "false" then
			local URL_ASTROS = `https://sets.pizzaboxer.xyz/api/sets/{other}/assets?page=1`
			local URL_1 = `https://sets.pizzaboxer.xyz/api/sets/{other}`
			-- Make the request to our endpoint URL
			local response = HTTPS:GetAsync(URL_ASTROS)
			local response2 = HTTPS:GetAsync(URL_1)
			-- Parse the JSON response
			local data = HTTPS:JSONDecode(response)
			local set = HTTPS:JSONDecode(response2)
			local setn = set.name
			local ModelParent = Instance.new("Folder")
			ModelParent.Name = setn
			ModelParent.Parent = game:GetService("ReplicatedStorage").PBSTools.Sets
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
		elseif boolean1 == "true" then
			local Model = insert(other, "SetTemp", game:GetService("ReplicatedStorage").PBSTools.Sets)
			print(Model)
			for _, Child in pairs(Model:FindFirstChild("Sets"):GetChildren()) do
				Child:SetAttribute("AssetID", other)
				Child:SetAttribute("Order", #game:GetService("ReplicatedStorage").PBSTools.Sets:GetChildren() + 1)
				print(Child)
				Child.Parent = game:GetService("ReplicatedStorage").PBSTools.Sets --Move the children up one parent
			end
			Model:Destroy()
			return self.Responses.Success, "Set Imported"
		else
			return self.Responses.Error, "Nothing got done"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
