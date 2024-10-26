-- To allow for voice chat mutes, you need to insert VoiceChatService through the service window in Model>Advanced in the ribbon.
-- Set UseAudioApi to enabled
-- You may be able to skip this if the feature gets enabled globally, in which case tell me to remove these comments.
-- TextChatService must be enabled too (ChatVersion = TextChatService and not LegacyChatService)
local TextChatService = game:GetService("TextChatService")

-- This doubles as unarchiving the text chat service channels
task.spawn(function()
	local channels = TextChatService:WaitForChild("TextChannels", 3)
	local commands = TextChatService:WaitForChild("TextChatCommands", 3)
	if channels and commands then
		channels.Archivable = false
		commands.Archivable = false
	else
		warn("Please set TextChatService.ChatService to TextChatService")
	end
end)

local command = require(script.Parent)

local cmd: command.cmd = {} :: command.cmd

cmd.minRank = 3
cmd.aliases = { unmute = false }
cmd.syntax = { "<player>" }

cmd.help = [[Prevents a player from talking in chat and using their microphone.]]
cmd.aliasHelp = { unmute = [[Unmutes the player, allowing them to talk in chat and use their microphone.]] }

local mutedUserIds = {}
TextChatService.DescendantAdded:Connect(function(desc: Instance)
	if desc:IsA("TextSource") then
		if table.find(mutedUserIds, desc.UserId) then
			desc:SetAttribute("canSend", desc.CanSend)
			desc.CanSend = false
		end
	end
end)

local function toggleMute(player: Player, muted: boolean): ()
	for _, v in TextChatService:GetDescendants() do
		if v:IsA("TextSource") and v.UserId == player.UserId then
			if not muted then
				v.CanSend = v:GetAttribute("canSend")
			else
				v:SetAttribute("canSend", v.CanSend)
				v.CanSend = false
			end
		end
	end
	if muted and not table.find(mutedUserIds, player.UserId) then
		table.insert(mutedUserIds, player.UserId)
	elseif not muted then
		local index = table.find(mutedUserIds, player.UserId)
		if index then
			table.remove(mutedUserIds, index)
		end
	end
end

function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local plr = args[1]
	if plr then
		local target = self:GetPlayer(player, plr)
		if target then
			-- See if they have a AudioDeviceInput instance
			task.spawn(function()
				local Microphone: AudioDeviceInput? = target:WaitForChild("AudioDeviceInput", 10)
				if Microphone then
					Microphone.Muted = if aliasData == false then false else true
				else
					warn("Enable VoiceChatService.UseAudioApi")
				end
			end)
			toggleMute(player, if aliasData == false then false else true)
			return self.Responses.Success, `{self:FormatUsername(target)} has been {aliasData == false and "un" or ""}muted.`
		else
			return self.Responses.Error, "No player found"
		end
	end
	return self.Responses.Error, "Invalid Parameters"
end

return cmd
