local data = {}

-- Type compatibility with rewrite

export type ObjectPathTable = {string}
export type WhitelistTable = {string}

export type PlotTable = {any}

export type PlayerData =  
{ 
		character : Model, 
		history : ObjectPathTable, 
		plots : PlotTable, 
		whitelist : WhitelistTable 
}

function data.InsertOrReplacePlayerDataFake(player : string, data : PlayerData)

end

function data.InsertOrReplacePlayerData(player : Player, data : PlayerData)

end
function data.EditPlayerData(player: Player,datatype: number, newdata) 

end
function data.AddPlayerData(player: Player, datatype, newdata) 

end
function data.RemovePlayerData(player : Player)

end
function data.GetPlayerDataFake(player : string) : PlayerData
    return nil::any
end
function data.GetPlayerData(player : Player) : PlayerData
    return nil::any
end

function data.AddHistory(player: Player, newdata: string, overwriteIfLast : boolean?)	

end

function data.AddWhitelist(player, newdata) 

end
function data.RemoveWhitelist(player, newdata) 

end

return data