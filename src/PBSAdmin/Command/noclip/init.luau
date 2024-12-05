local PhysicsService = game:GetService("PhysicsService")

-- If the noclip collision group is not created yet, then create it
if not PhysicsService:IsCollisionGroupRegistered("PlayerNoclip") then PhysicsService:RegisterCollisionGroup("PlayerNoclip") end

-- Each runtime make noclip not collide with any other collision groups
-- This is needed incase another script generates a collision group at any point
for _, v in PhysicsService:GetRegisteredCollisionGroups() do
	if v.name ~= "PlayerNoclip" then PhysicsService:CollisionGroupSetCollidable("PlayerNoclip", v.name, false) end
end

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { unnoclip = false }
cmd.syntax = { "<player(s)>" }

cmd.help = [[Toggles noclip for a player.]]
cmd.aliasHelp = { unnoclip = [[Removes flight for a player.]] }

function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local other = args[1] or "me"
	if player and other then
		-- Try to disable flight
		if aliasData ~= false then print(pcall(function()
			local fly = command.new("fly")
			if fly then fly(player, nil, false, other) end
		end)) end

		local targets = self:GetBulkPlayers(player, other)

		local filteredTargets = {}
		-- Filter out targets we cannot effect
		for _, v in targets do
			if self:CanUserModifyOther(player, v) then table.insert(filteredTargets, v) end
		end
		targets = filteredTargets

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		local logs = {}

		for _, target in targets do
			-- Toggle the flight script for this palyer
			-- If they already have flight, disable it
			-- Alternatively, if the command was unnoclip, then dont give noclip
			local noclip = target.Character and target.Character:FindFirstChild("PBSADMIN_NoClip")
			if noclip then
				noclip:Destroy()
				local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
				local hroot = humanoid and humanoid.RootPart
				if hroot then hroot.Anchored = true end

				task.defer(function()
					local pivot = target.Character:GetPivot()
					local _, ry = pivot:ToOrientation()
					target.Character:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, ry, 0))

					if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
					task.wait()
					if hroot then hroot.Anchored = false end
				end)

				table.insert(logs, `Noclip removed for '{self:FormatUsername(target)}'`)
				continue
			elseif target.Character and aliasData ~= false then
				script.PBSADMIN_NoClip:Clone().Parent = target.Character
				table.insert(logs, `Noclip activated for '{self:FormatUsername(target)}'`)
				continue
			end

			if aliasData == false then
				table.insert(logs, `<font color="#fbdc27">'{self:FormatUsername(target)}' does not have noclip enabled</font>`)
				continue
			end
			table.insert(logs, `<font color="#fbdc27">'{self:FormatUsername(target)}' currently does not have a character, try again later.</font>`)
		end

		return self.Responses.Success, table.concat(logs, "\n")
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
