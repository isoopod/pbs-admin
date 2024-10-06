local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = {}
cmd.syntax = {}

cmd.help = [[Counts all the BaseParts and Stamper Parts in workspace]]

cmd.__call = function(self: command.Command, player: Player, verified: boolean, aliasData: any?, ...: string?): (number, string)
	if player then
		if self:UserHasPermissionsForCommand(player) then
			local c = 0
			local s = 0
			for _, v in workspace:GetDescendants() do
				if v:IsA("BasePart") then
					c += 1
				end
				if v:FindFirstChild("RobloxStamper") then
					s += 1
				end
			end
			return self.Responses.Success, `{c} BaseParts found in workspace. \n {s} Stamper Parts found in workspace.`
		else
			return self.Responses.Error, "You do not have permissions to run this command"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
