-- To allow for voice chat mutes, you need to insert VoiceChatService through the service window in Model>Advanced in the ribbon.
-- Set UseAudioApi to enabled
-- You may be able to skip this if the feature gets enabled globally, in which case tell me to remove these comments.
-- TextChatService must be enabled too (ChatVersion = TextChatService and not LegacyChatService)
local TextChatService = game:GetService("TextChatService")
local VoiceChatService = game:GetService("VoiceChatService")

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
cmd.syntax = { "<player(s)>", "<boolean>" }

cmd.help = [[Prevents a player from talking in chat and using their microphone. 
If the second argument is true, it will shadow mute the player (not tell them if they are muted)]]
cmd.aliasHelp = { unmute = [[Unmutes the player, allowing them to talk in chat and use their microphone. Second argument does nothing]] }

local mutedUserIds = {}
TextChatService.DescendantAdded:Connect(function(desc: Instance)
	if desc:IsA("TextSource") then
		if table.find(mutedUserIds, desc.UserId) then
			desc:SetAttribute("canSend", desc.CanSend)
			desc.CanSend = false
		end
	end
end)

local function toggleMute(player: Player, muted: boolean, shadow: boolean?): ()
	for _, v in TextChatService:GetDescendants() do
		if v:IsA("TextSource") and v.UserId == player.UserId then
			if not muted then
				v.CanSend = v:GetAttribute("canSend")
				v:SetAttribute("ShadowMuted")
			else
				v:SetAttribute("canSend", v.CanSend)
				v:SetAttribute("ShadowMuted", shadow)
				v.CanSend = false
			end
		end
	end
	if muted and not table.find(mutedUserIds, player.UserId) then
		table.insert(mutedUserIds, player.UserId)
	elseif not muted then
		local index = table.find(mutedUserIds, player.UserId)
		if index then table.remove(mutedUserIds, index) end
	end
end

local VoiceEnabled, Queries = nil, 0
function cmd.__call(self: command.Command, player: Player, _, aliasData: any?, ...: string?): (number, string)
	local args = { ... }
	local plr = args[1]
	local shadow = string.lower(args[2] or "") == "true"
	if plr then
		local targets = self:GetBulkPlayers(player, plr)

		local filteredTargets = {}
		-- Filter out targets we cannot effect
		for _, v in targets do
			if self:CanUserModifyOther(player, v) then table.insert(filteredTargets, v) end
		end
		targets = filteredTargets

		if #targets == 0 then return self.Responses.Error, "Affected 0 players" end

		local logs = {}
		for _, target in targets do
			-- See if they have a AudioDeviceInput instance
			task.spawn(function()
				local Microphone: AudioDeviceInput? = target:WaitForChild("AudioDeviceInput", 10)
				if Microphone then
					Microphone.Muted = if aliasData == false then false else true
				else
					-- Cache if voicechat is enabled to stop useless http calls
					if VoiceEnabled == nil then
						Queries += 1

						local s, enabled = pcall(VoiceChatService.IsVoiceEnabledForUserIdAsync, VoiceChatService, target.UserId)
						if s and enabled == true then VoiceEnabled = true end

						-- It might just be this user has voice off, so we should check at least five times
						if Queries >= 5 then VoiceEnabled = false end
					end
					if VoiceEnabled == true then warn("Enable VoiceChatService.UseAudioApi to be able to mute a players microphone") end
				end
			end)
			toggleMute(target, if aliasData == false then false else true, shadow)
			table.insert(logs, `{aliasData == false and "un" or ""}muted {self:FormatUsername(target)}`)
		end
		return self.Responses.Success, table.concat(logs, "\n")
	end
	return self.Responses.Error, "Invalid Parameters"
end

return cmd
