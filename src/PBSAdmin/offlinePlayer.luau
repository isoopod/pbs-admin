--!strict

--[[ Class OfflinePlayer
	Turns the UserId stored in the permissions module into a stand in for a player instance
	limited to userid and tostring for the name but means i dont have to write seperate logic within the admin script
]]

local OfflinePlayer = {}
OfflinePlayer.__index = OfflinePlayer
OfflinePlayer.__tostring = function(self: OfflinePlayer)
	return self.Name
end

export type OfflinePlayer = {
	Name: string;
	UserId: number;
	
	Charater: nil;
	FindFirstChild: () -> nil
}

function OfflinePlayer.new(name: string, UserId: number): OfflinePlayer
	local self = setmetatable({},OfflinePlayer) :: any
	
	self.Name = name
	self.UserId = UserId
	
	self.Character = nil --another option to seperate a real player
	
	return self
end

function OfflinePlayer:FindFirstChild(): nil
	-- trying to find a child of the player obviously will not work as the player is not in the game
	-- but some scripts may try to do so when working with either an actual player or an offlinePlayer
	return nil
end

return OfflinePlayer :: typeof(OfflinePlayer)
