local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd
local permissions = require(script.Parent.Parent.Permissions)

cmd.minRank = 3
cmd.syntax = {
	"<player / #userid>",
	"<number>",
	{ "seconds", "minutes", "hours", "days", "weeks", "months", "years", "eons" },
	"<reason?>",
}

cmd.help = [[Bans a player for a specified amount of time. Will also remove any permission the user may have had. Alt detection is enabled.
The third argument is the unit used for the length of the ban (seconds, days, years ect)
The second argument is how many of that unit the user should be banned for.
]]

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
	return math.clamp(converted, -1, math.huge)
end

function cmd.__call(self: command.Command, player: Player, verified: boolean, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local duration = tonumber(args[2])
	local units = args[3]
	local reason = args[4]
	if player and other and duration and units then
		units = units:lower()
		local target = self:GetPlayer(player, other, true)
		if target then
			if table.find(cmd.syntax[3] :: { string }, units) then
				if verified then
					local length = convertUnit(duration, units)
					--local unbanDate = DateTime.fromUnixTimestamp(os.time() + length)
					local displayReason = "You have been banned from this PBS."--[[\nYour ban expires on {unbanDate:FormatUniversalTime(
							"LLLL",
							"en-us"
						)}{if reason then `\nAn additional reason has been attached: {reason}` else ""}` This part comes with the ban notice]]
					local s, e = pcall(Players.BanAsync, Players, {
						UserIds = { target.UserId },
						ApplyToUniverse = true,
						Duration = length,
						DisplayReason = displayReason,
						PrivateReason = reason,
						ExcludeAltAccounts = false,
					})
					if not s then
						return self.Responses.Error, `BanAsync error: {e}`
					end
					permissions.EditPersistentRole(target.UserId)
					return self.Responses.Success, `{self:FormatUsername(target)} has been banned for {duration} {units}`
				else
					return self.Responses.Verify, `Are you sure you want to ban {self:FormatUsername(target)}?`
				end
			else
				return self.Responses.Error, `{units} is not a valid unit.`
			end
		else
			return self.Responses.Error, "Player could not be found"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
