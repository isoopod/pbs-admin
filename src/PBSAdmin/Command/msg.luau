local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Permissions = require(ServerScriptService.PBSServer.PBSAdmin.Permissions)
local command = require(script.Parent)

local Bytenet = command.PublicUtils.Bytenet
local remote
if not Bytenet then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PBSADMIN_MSG"
	remote.Archivable = false
	remote.Parent = ReplicatedStorage
end

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.syntax = { "<player(s)>", "<number>", "<...any>" }

cmd.help = [[Sends a message to another, or multiple, players in the server.
	Second parameter is the message duration in seconds. If 0, duration will be automatically calculated based on the length of the message.
	Anything after the duration paramteter is the message.
]]

function cmd.__call(self: command.Command, player: Player, verified, _, ...: string?): (number, string)
	local args = { ... }
	local other = args[1]
	local duration = tonumber(args[2])
	if duration == 0 then duration = nil end
	local text = table.concat(args, " ", 3)
	if player and other and text ~= "" then
		local targets = self:GetBulkPlayers(player, other)

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		local filteredText = self:FilterText(player, text)
		if not verified and filteredText ~= text then
			return self.Responses.Verify, `Your message was filtered (result: "<font color='#ff0000'>{filteredText}</font>"). Send anyway? Y/N`
		end

		local titlePrefix = (other ~= "all" and other ~= "others" and other ~= "team") and "Private message from" or "Message from"
		local title = `{titlePrefix} {self:ColorTextForRank(player.Name, Permissions.roleValues[Permissions.GetUserPermissions(player.UserId)])}`

		if Bytenet then
			Bytenet.MSG.sendToList({ title = title, message = filteredText, typewrite = true, duration = duration }, targets)
		else
			for _, p in targets do
				remote:FireClient(p, title, filteredText, true, duration)
			end
		end
		return self.Responses.Success, `Message sent to {if #targets == 1 then self:FormatUsername(targets[1]) else other} successfully.`
	else
		return self.Responses.Error, "Invalid Parameters"
	end
end

return cmd
