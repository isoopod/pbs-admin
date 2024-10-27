-- Handles Psuedo-Aliases and command linting behaviour.

local Players = game:GetService("Players")

local api = {}

local PALookup = {}
PALookup = {
	["<player>"] = function()
		local a = {}
		for _, p in Players:GetPlayers() do
			table.insert(a, p.Name)
			if not table.find(a, p.DisplayName) then
				table.insert(a, p.DisplayName) -- display names are not unique, and duplicates arent helpful
			end
		end
		table.insert(a, "me")
		return a
	end,
	["<player(s)>"] = function()
		local a = PALookup["<player>"]()
		table.insert(a, "all")
		table.insert(a, "others")
		table.insert(a, "team")
		return a
	end,
	["<player / #userid>"] = function()
		return PALookup["<player>"]()
	end,
	["<boolean>"] = function()
		return { "true", "false" }
	end,
}

function api.processPsuedoAlias(alias: string | { string }, inp: string): string | { string }
	-- Show a (simplified) version of the psuedo-alias when the player starts typing the next value
	if alias == nil then
		return { "" }
	end
	if typeof(alias) == "table" then
		if inp == "" then
			return tostring(alias[1])
		end
		return alias
	end
	if inp == "" then
		return alias:gsub("<player%(s%)>", "<player>")
	end

	if PALookup[alias] then
		return PALookup[alias]()
	end

	return alias
end

return api
