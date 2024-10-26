local Debris = game:GetService("Debris")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = {
	"<player / #userid>",
	"<number>",
	{ "seconds", "minutes", "hours", "days", "weeks", "months", "years", "eons" },
}

cmd.help = [[Deletes all stamps created by the player.
The third argument specifies the time unit to determine how far back to delete stamps (e.g., seconds, days, years, etc.).
The second argument sets the quantity of the chosen unit to define how far back to delete stamps.]]

local function convertUnit(number: number, unit: string): number
	local unitsInSeconds = {
		seconds = 1,
		minutes = 60,
		hours = 3600,
		days = 86400,
		weeks = 604800,
		months = 2592000, -- Assuming 30 days in a month
		years = 31536000, -- Assuming 365 days in a year
		eons = 3.1536e16,
	}

	local converted = number * unitsInSeconds[unit]
	if converted == 0 then
		converted = 1
	end
	return math.clamp(converted, 0, tick())
end

function cmd.__call(self: command.Command, player: Player, verified: boolean, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local duration = args[2] and tonumber(args[2])
	local unit = args[3] and args[3]:lower()
	if other and duration and unit then
		local target = self:GetPlayer(player, other, true)
		if target then
			if table.find(cmd.syntax[3] :: { string }, unit) then
				if verified then
					local length = convertUnit(duration, unit)
					local timeFrom = tick() - length

					local counter = 0

					local function search(group: { Instance })
						for _, v in group do
							if v.Parent and v:HasTag("StamperPart") then
								local creator = v:GetAttribute("Creator")
								if creator and type(creator) == "string" then
									local userid = tonumber(string.split(creator, ":")[1])
									if userid == target.UserId then
										local timestamp = v:GetAttribute("Timestamp")
										if timestamp and type(timestamp) == "number" and timeFrom <= timestamp then
											counter += 1
											Debris:AddItem(v, 0)
										end
									end
								end
							end
						end
					end

					local container = workspace:FindFirstChild(`{target}Models`)
					if container then
						search(container:GetChildren())
						-- Clean the container if it becomes orphaned
						if #container:GetChildren() == 0 then
							container:Destroy()
						end
					else
						-- The feature to group stamps by player may be disabled
						search(workspace:GetDescendants())
					end

					return self.Responses.Success, `Removed {counter} stamps.`
				else
					return self.Responses.Verify, `Do you really want to erase all of {target}'s builds from the past {duration} {unit}?`
				end
			else
				return self.Responses.Error, "Invalid unit"
			end
		else
			return self.Responses.Error, "Invalid player"
		end
	end
	return self.Responses.Error, "Invalid parameters"
end

return cmd
