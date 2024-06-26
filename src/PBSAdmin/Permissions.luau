--!strict

-- to manually add a user permission
-- create a new attribute for this module
-- set the name to the players userid
-- set type to string
-- set value to your role name (e.g member / admin / owner)

local httpService = game:GetService("HttpService")
local _,roverKey = pcall(httpService.GetSecret, httpService, "GET_Trusted")

local untrustedRole = ""

local trustedID = "698282317382418581" -- trusted role in server
local trustedDefualtRole = "member"

local url = "https://registry.rover.link/api/guilds/698282035327795260/"
local rblx_disc_method = "roblox-to-discord/"

local headers = {
	["Authorization"] = typeof(roverKey) == "Secret" and roverKey:AddPrefix("Bearer ") 
}

--[[ IMPORTANT
AS PER ROVER API AGREEMENT, INFO PULLED FROM THE REQUEST IS NOT TO BE SAVED FOR OVER 30 DAYS. 
THIS MEANS ANY DATA SHOULD NOT BE AUTOMATICALLY PUT INTO THE PLACESAVE AS THIS CAN BE STORED 
INDEFINITELY
]]

local verif = {}

-- You can add your roles here and give them a value then use this to check if a uses is privileged enough to do something
verif.roleValues = {
	["banned"] = -1,
	[""] = 0, -- no role assigned / no permissions
	["member"] = 1,
	["admin"] = 2,
	["owner"] = 3,
}

verif._CachedPermissions = {}

function verif.GetUserPermissions(UserId: number): string
	-- if user permissions are already stored use those
	local saved = script:GetAttribute(tostring(UserId))
	if saved then
		return saved
	end
	
	-- For testing, local tests set the UserId to -1 so this poses no risk in-game
	if UserId == -1 then return "owner" end

	if verif._CachedPermissions[UserId] then
		return trustedDefualtRole
	end
	
	if typeof(roverKey) == "Secret" then
		-- Query the RoVer API for our roblox user's connected discord accounts that are in the PBS server
		local s,userServerData = pcall(
			httpService.RequestAsync,
			httpService,
			{
				Url =`{url}{rblx_disc_method}{UserId}`,
				Method = "GET",
				Headers = headers,
			}
		)
		
		if s and userServerData.Success then
			local data = httpService:JSONDecode(userServerData.Body)
			
			-- a roblox account can be linked to multiple discord accounts
			for _, user in data["discordUsers"] do
				for _, role in user["roles"] do
					if role == trustedID then
						verif._CachedPermissions[UserId] = true
						return trustedDefualtRole
					end
				end
			end
		elseif userServerData and userServerData.StatusMessage ~= "user_not_found" then
			warn(`GetUserPermissions Request Failed: {userServerData.StatusCode}: {userServerData.StatusMessage}`)	
		end
	end
	
	return untrustedRole
end

function verif.EditPersistentRole(UserId: number, role: string?): ()
	-- role can be set to nil or omitted to remove the attribute
	-- setting to the untrusted role has the same effect except the attribute remains
	-- keep in mind this has to be manually removed if the user submits a right to erasure request
	script:SetAttribute(tostring(UserId),role)
end

-- Connect to players.PlayerRemoving somewhere else
function verif.PlayerRemoving(player: Player): ()
	verif._CachedPermissions[player.UserId] = nil
end

return verif
