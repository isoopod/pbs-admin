local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local command = require(script.Parent)

local datastore = DataStoreService:GetDataStore("PBSADMIN_WARNS")

local Bytenet = command.PublicUtils.Bytenet
local remote: RemoteEvent?
if not Bytenet then task.spawn(function()
	remote = ReplicatedStorage:WaitForChild("PBSADMIN_MSG")
end) end

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player / #userid>", "<...reason>" }

cmd.help = [[Gives a player a warning. Warnings are saved and can be viewd through the getwarns command.]]

function cmd.__call(self: command.Command, player: Player, verified: boolean, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local reason = table.concat(args, " ", 2)
	if player and other and reason then
		local target = self:GetPlayer(player, other, true)
		if target then
			local filteredText = self:FilterText(player, reason)
			if not verified and filteredText ~= reason then
				local msg = `Your warning for {self:FormatUsername(target)} was filtered (result: "<font color='#ff0000'>{filteredText}</font>"). Send anyway? Y/N`
				return self.Responses.Verify, msg
			end

			if verified then
				-- If dealing with a real player
				if target.ClassName == "Player" then
					if Bytenet then
						Bytenet.MSG.sendTo({ title = "<font color='#f00'>Warning</font>", message = filteredText }, target)
					elseif remote then
						remote:FireClient(target, "<font color='#f00'>Warning</font>", filteredText)
					end
				end

				local s, e = pcall(datastore.UpdateAsync, datastore, tostring(target.UserId), function(current: string)
					local tbl = HttpService:JSONDecode(current or "[]")
					table.insert(tbl, 1, reason)
					return HttpService:JSONEncode(tbl), { target.UserId }
				end)

				if not s then return self.Responses.Warning, `Warning not saved due to error: {e}` end

				return self.Responses.Success, `{self:FormatUsername(target)} has been given a warning`
			else
				return self.Responses.Verify, `Are you sure you want to warn {self:FormatUsername(target)}?`
			end
		else
			return self.Responses.Error, "Player could not be found"
		end
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
