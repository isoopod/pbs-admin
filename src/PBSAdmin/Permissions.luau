--!strict

-- to manually add a user permission
-- create a new attribute for this module
-- set the name to the players userid
-- set type to string
-- set value to your role name (e.g member / admin / owner)

-- when using datastores, you can use a datastore editor plugin

local DataStoreService = game:GetService("DataStoreService")
local GroupService = game:GetService("GroupService")

local datastore
if script.Parent:GetAttribute("permsUsesDatastore") then datastore = DataStoreService:GetDataStore("PBSADMIN_PERMS") end

-- Role to give to users with no role set who dont have succient rank in the group
local untrustedRole = ""

-- Role to hand out to users with no role set if they have sufficient rank in the group
local trustedDefualtRole = "member"

-- The group to check for trusted users
local Group = 14631975
local RankForTrusted = 25 -- >= this rank in the group will give trusted
-- Remember that rank is the numeric value for a role in a group (you can see it in configure group)

local verif = {}

-- You can add your roles here and give them a value then use this to check if a uses is privileged enough to do something
-- Think of the number as rank in a group and the string name as role in a group
verif.roleValues = {
	[""] = 0, -- no role assigned / no permissions
	["member"] = 1,
	["trusted"] = 2,
	["admin"] = 3,
	["owner"] = 4,
}

verif._CachedPermissions = {}

function verif.GetUserPermissions(UserId: number): string
	-- For testing, local tests set the UserId to -1 so this poses no risk in-game
	if UserId == -1 then return "owner" end
	-- Private server owner gets admin permissions, for the rewrite public beta (may be undesirable for other use cases)
	if UserId == game.PrivateServerOwnerId then return "admin" end

	-- if user permissions are already stored use those
	if verif._CachedPermissions[UserId] then return verif._CachedPermissions[UserId] end

	if datastore then
		local s, saved = pcall(datastore.GetAsync, datastore, tostring(UserId))
		if s then
			verif._CachedPermissions[UserId] = saved
			return saved
		end
	else
		local saved = script:GetAttribute(tostring(UserId))
		if saved then return saved end
	end

	-- If no saved entry, check if they have a high enough rank in the group
	for _, v in GroupService:GetGroupsAsync(UserId) do
		if v.Id ~= Group then continue end
		if v.Rank >= RankForTrusted then
			verif._CachedPermissions[UserId] = trustedDefualtRole
			return trustedDefualtRole
		end
	end

	return untrustedRole
end

function verif.EditPersistentRole(UserId: number, role: string?): ()
	-- role can be set to nil or omitted to remove the attribute
	-- setting to the untrusted role has the same effect except the attribute remains
	-- keep in mind this has to be manually removed if the user submits a right to erasure request
	if datastore then
		pcall(datastore.SetAsync, datastore, tostring(UserId), role, { UserId })
		verif._CachedPermissions[UserId] = role
	else
		script:SetAttribute(tostring(UserId), role)
	end
end

-- Connect to players.PlayerRemoving somewhere else
function verif.PlayerRemoving(player: Player): ()
	verif._CachedPermissions[player.UserId] = nil
end

return verif
