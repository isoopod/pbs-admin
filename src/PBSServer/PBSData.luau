--!strict
-- API compatibility with rewrite's PBSData module for the commands that integrate with it.
-- Testing should be done in actual rewrite, this only serves for typechecking

-- Services
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
--local zone = require(game:GetService("ReplicatedStorage"):WaitForChild("Utils"):WaitForChild("Zone"))

local data = {}

-- Primitives
--export type PlotTable = { zone.Zone }
export type HistoryEntry = {
	timestamp: number,
	action: string,
	message: string,
	metadata: any?,
}

-- Player data prototype
export type PlayerData = {
	history: { HistoryEntry }, -- The history table, containing paths to the objects.
	-- The history table will remain so the latest entries are at the end of the table. Entries older than the LogDuration config will be cleared.

	--TODO: use HistoryEntry metadata for an undo feature

	whitelist: { number }, -- userids of players allowed to build in this player's plots
	--plots: PlotTable, -- The plot table consisting of zones.
	lastLocation: CFrame?, -- The place they logged off at
}

type player = Player | number

function data.InsertOrReplacePlayerData(_player: player, _data: PlayerData?) end

function data.GetPlayerData(_player: player): (PlayerData, boolean)
	return nil :: any, nil :: any
end

function data.EditPlayerData(_player: player, _datatype: number, _newdata) end

function data.PushPlayerData(_player: player, _datatype, _newdata, _index: number?) end

function data.PopPlayerData(_player: player, _datatype, _index: number?) end

function data.RemovePlayerData(_player: player) end

function data.AddHistory(_player: player, _action: string, _message: string, _metadata: any?) end

function data.RemoveOldHistory(_player: player) end

function data.AddWhitelist(_player: player, _userid: number) end

function data.RemoveWhitelist(_player: player, _userid: number) end

return data
