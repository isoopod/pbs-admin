local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 4
cmd.aliases = {}
cmd.syntax = { "<number>", "<string>" }

cmd.help = [[imports a model to a set, first argument is assetid, second is the set name it should be added to]]

function insert(assetId, name, ModelParent): Model?
	local InsertService = game:GetService("InsertService")
	local success, model = pcall(InsertService.LoadAsset, InsertService, assetId)
	if success and model then
		local AssetName = game:GetService("MarketplaceService"):GetProductInfo(assetId).Name
		print(ModelParent)
		print(assetId)
		print(AssetName)
		model.Parent = ModelParent
		model.Name = name
		model:SetAttribute("AssetID", assetId)

		local realModel = model:GetChildren()[1]

		realModel:SetAttribute("ID", assetId)
		realModel:SetAttribute("Order", #ModelParent:GetChildren() + 1)
		realModel.Name = AssetName
		realModel.Parent = ModelParent
		return model
	end
	return nil
end

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local asset = args[1]
	local set = args[2]
	if player and asset and set and game:GetService("ReplicatedStorage").PBSTools.Sets:FindFirstChild(set) then
		if self:UserHasPermissionsForCommand(player) then
			local Model = insert(set, "SetTemp", game:GetService("ReplicatedStorage").PBSTools.Sets:FindFirstChild(set))

			if Model then Model:Destroy() end

			return self.Responses.Success, "Set Imported"
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
