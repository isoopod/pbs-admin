local Players = game:GetService("Players")

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player / #userid>" }

cmd.help = [[Returns info on all the current and previous bans a user has recieved]]

-- Reformat pages as tables

type BanHistoryPage = {
	DisplayReason: string,
	PrivateReason: string,
	StartTime: string, --ISO 8601
	Duration: number, -- length in seconds, perm = -1
	Ban: boolean, -- If ban or unban
	PlaceId: number,
}
local function pagesToTable(pages: BanHistoryPages): { BanHistoryPage }
	local items = {} :: BanHistoryPage
	while true do
		table.insert(items, pages:GetCurrentPage())
		if pages.IsFinished then break end
		pages:AdvanceToNextPageAsync()
	end
	return items
end

-- Page iterator function
local function page(p: BanHistoryPages): () -> (number, BanHistoryPage)
	local contents = pagesToTable(p)
	local n = 1
	local last = #contents

	return coroutine.wrap(function()
		while n <= last do
			for _, item in contents[n] do
				coroutine.yield(n, item)
			end
			n += 1
		end
	end)
end

-- Function to get time difference from now to future unix timestamp in descending units
local function timeUntil(futureTime: number): string
	-- Calculate the time difference in seconds
	local diff = math.max(futureTime - tick(), 0) -- Avoid negative diffs

	-- Define time units in seconds
	local units = {
		{ name = "eon", seconds = 3.1536e16 },
		{ name = "year", seconds = 31536000 },
		{ name = "month", seconds = 2592000 },
		{ name = "week", seconds = 604800 },
		{ name = "day", seconds = 86400 },
		{ name = "hour", seconds = 3600 },
		{ name = "minute", seconds = 60 },
		{ name = "second", seconds = 1 },
	}

	-- Prepare results and add up to 3 units
	local result = {}
	local count = 0

	for _, unit in units do
		if diff <= 0 or count >= 3 then break end

		-- Calculate the number of this unit in the remaining time
		local amount = diff // unit.seconds
		if amount > 0 then
			table.insert(result, string.format("%d %s%s", amount, unit.name, amount > 1 and "s" or ""))
			diff %= unit.seconds
			count += 1
		end
	end

	-- Return joined result
	return table.concat(result, ", ")
end

function cmd.__call(self: command.Command, player: Player, _, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	if player and other then
		local target = self:GetPlayer(player, other, true)
		if target then
			local lines = {}
			local bans = Players:GetBanHistoryAsync(target.UserId)

			local hasBans = false
			for _, item in page(bans) do
				if item.PlaceId ~= -1 and item.PlaceId ~= game.PlaceId then continue end

				hasBans = true

				local ban = {}

				table.insert(ban, `{item.Ban and "<font color='#ff0000'>Ban</font>" or "<font color='#00ff00'>Unban</font>"}`)

				if item.Duration == -1 then
					table.insert(ban, "<font color='#b369bd'>Permanent</font>")
				else
					local unbanDate = DateTime.fromIsoDate(item.StartTime).UnixTimestamp + item.Duration
					local date = timeUntil(unbanDate)
					if date == "" then
						table.insert(ban, "<font color='#00ff00'>Expired</font>")
					else
						table.insert(ban, `<font color='#ff0000'>Active for {date}</font>`)
					end
				end

				table.insert(ban, `Reason: {item.PrivateReason}`)

				table.insert(lines, table.concat(ban, "\n"))
			end

			if not hasBans then return self.Responses.Error, `{target.Name} has not been banned before` end

			return self.Responses.Success, table.concat(lines, "\n")
		else
			return self.Responses.Error, "Player could not be found"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
