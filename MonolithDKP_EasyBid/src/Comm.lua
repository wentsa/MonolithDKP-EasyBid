EasyBidComm = LibStub("AceAddon-3.0"):NewAddon("EasyBidComm")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

function EasyBidComm:ValidateSender(sender)                -- returns true if "sender" has permission to write officer notes. false if not or not found.
    local rankIndex = EasyBidUtils:GetGuildRankIndex(sender);

    if rankIndex == 1 then             -- automatically gives permissions above all settings if player is guild leader
        return true;
    end
    if rankIndex then
        return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]    -- returns true/false if player can write to officer notes
    else
        return false;
    end
end

function EasyBidComm:SortLootTable()             -- sorts the Loot History Table by date
    table.sort(MonDKP_EasyBid_Loot, function(a, b)
        return a["date"] > b["date"]
    end)
end

function EasyBidComm:OnComm(prefix, message, distribution, sender, onStopCallback, onBidInfo, onDkpBidShare)
    if prefix and EasyBidComm:ValidateSender(sender) then		-- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
        if (prefix == "MonDKPCommand") then
            local command, arg1, arg2, arg3 = strsplit(",", message);
            if sender ~= UnitName("player") then
                if command == "StopBidTimer" then
                    onStopCallback()
                elseif command == "BidInfo" then
                    onBidInfo(arg1, arg2, sender)
                end
            end
        end
        if (sender ~= UnitName("player")) then
            if prefix == "MonDKPLootDist" or prefix == "MonDKPDKPDist" or prefix == "MonDKPDelLoot" or prefix == "MonDKPDelSync" or prefix == "MonDKPMinBid" or prefix == "MonDKPWhitelist"
                    or prefix == "MonDKPDKPModes" or prefix == "MonDKPStand" or prefix == "MonDKPZSumBank" or prefix == "MonDKPBossLoot" or prefix == "MonDKPDecay" or prefix == "MonDKPDelUsers" or
                    prefix == "MonDKPAllTabs" or prefix == "MonDKPBidShare" or prefix == "MonDKPMerge" then
                decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
                local success, deserialized = LibAceSerializer:Deserialize(decoded);
                if success then
                    if prefix == "MonDKPAllTabs" then   -- receives full table broadcast
                        table.sort(deserialized.Loot, function(a, b)
                            return a["date"] > b["date"]
                        end)
                        table.sort(deserialized.DKP, function(a, b)
                            return a["date"] > b["date"]
                        end)

                        if (#MonDKP_EasyBid_DKPHistory > 0 and #MonDKP_EasyBid_Loot > 0) and (deserialized.DKP[1].date < MonDKP_EasyBid_DKPHistory[1].date or deserialized.Loot[1].date < MonDKP_EasyBid_Loot[1].date) then

                        else
                            MonDKP_EasyBid_DKPTable = deserialized.DKPTable
                            MonDKP_EasyBid_DKPHistory = deserialized.DKP
                            MonDKP_EasyBid_Loot = deserialized.Loot

                            MonDKP_EasyBid_Archive = deserialized.Archive
                        end
                        return
                    elseif prefix == "MonDKPBidShare" then
                        onDkpBidShare(deserialized)
                        return
                    elseif prefix == "MonDKPMerge" then
                        for i=1, #deserialized.DKP do
                            local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPHistory, deserialized.DKP[i].index, "index")

                            if not search and ((MonDKP_EasyBid_Archive.DKPMeta and MonDKP_EasyBid_Archive.DKPMeta < deserialized.DKP[i].date) or (not MonDKP_EasyBid_Archive.DKPMeta)) then   -- prevents adding entry if this entry has already been archived
                                local players = {strsplit(",", strsub(deserialized.DKP[i].players, 1, -2))}
                                local dkp

                                if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then
                                    dkp = {strsplit(",", deserialized.DKP[i].dkp)}
                                end

                                if deserialized.DKP[i].deletes then  		-- adds deletedby field to entry if the received table is a delete entry
                                    local search_del = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPHistory, deserialized.DKP[i].deletes, "index")

                                    if search_del then
                                        MonDKP_EasyBid_DKPHistory[search_del[1][1]].deletedby = deserialized.DKP[i].index
                                    end
                                end

                                if not deserialized.DKP[i].deletedby then
                                    local search_del = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPHistory, deserialized.DKP[i].index, "deletes")

                                    if search_del then
                                        deserialized.DKP[i].deletedby = MonDKP_EasyBid_DKPHistory[search_del[1][1]].index
                                    end
                                end

                                table.insert(MonDKP_EasyBid_DKPHistory, deserialized.DKP[i])

                                for j=1, #players do
                                    if players[j] then
                                        local findEntry = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, players[j], "player")

                                        if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then 		-- handles decay entries
                                            if findEntry then
                                                MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp = MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp + tonumber(dkp[j])
                                            else
                                                if not MonDKP_EasyBid_Archive[players[j]] or (MonDKP_EasyBid_Archive[players[j]] and MonDKP_EasyBid_Archive[players[j]].deleted ~= true) then
                                                    EasyBidUtils:Profile_Create(players[j], tonumber(dkp[j]))
                                                end
                                            end
                                        else
                                            if findEntry then
                                                MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp = MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp + tonumber(deserialized.DKP[i].dkp)
                                                if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain
                                                    MonDKP_EasyBid_DKPTable[findEntry[1][1]].lifetime_gained = MonDKP_EasyBid_DKPTable[findEntry[1][1]].lifetime_gained + deserialized.DKP[i].dkp 	-- NOT if it's a DKP penalty or deleteing a DKP penalty
                                                end
                                            else
                                                if not MonDKP_EasyBid_Archive[players[j]] or (MonDKP_EasyBid_Archive[players[j]] and MonDKP_EasyBid_Archive[players[j]].deleted ~= true) then
                                                    local class

                                                    if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then
                                                        EasyBidUtils:Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp), tonumber(deserialized.DKP[i].dkp))
                                                    else
                                                        EasyBidUtils:Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp))
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        for i=1, #deserialized.Loot do
                            local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_Loot, deserialized.Loot[i].index, "index")

                            if not search and ((MonDKP_EasyBid_Archive.LootMeta and MonDKP_EasyBid_Archive.LootMeta < deserialized.DKP[i].date) or (not MonDKP_EasyBid_Archive.LootMeta)) then -- prevents adding entry if this entry has already been archived
                                if deserialized.Loot[i].deletes then
                                    local search_del = EasyBidUtils:Table_Search(MonDKP_EasyBid_Loot, deserialized.Loot[i].deletes, "index")

                                    if search_del and not MonDKP_EasyBid_Loot[search_del[1][1]].deletedby then
                                        MonDKP_EasyBid_Loot[search_del[1][1]].deletedby = deserialized.Loot[i].index
                                    end
                                end

                                if not deserialized.Loot[i].deletedby then
                                    local search_del = EasyBidUtils:Table_Search(MonDKP_EasyBid_Loot, deserialized.Loot[i].index, "deletes")

                                    if search_del then
                                        deserialized.Loot[i].deletedby = MonDKP_EasyBid_Loot[search_del[1][1]].index
                                    end
                                end

                                table.insert(MonDKP_EasyBid_Loot, deserialized.Loot[i])

                                local findEntry = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, deserialized.Loot[i].player, "player")

                                if findEntry then
                                    MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp = MonDKP_EasyBid_DKPTable[findEntry[1][1]].dkp + deserialized.Loot[i].cost
                                    MonDKP_EasyBid_DKPTable[findEntry[1][1]].lifetime_spent = MonDKP_EasyBid_DKPTable[findEntry[1][1]].lifetime_spent + deserialized.Loot[i].cost
                                else
                                    if not MonDKP_EasyBid_Archive[deserialized.Loot[i].player] or (MonDKP_EasyBid_Archive[deserialized.Loot[i].player] and MonDKP_EasyBid_Archive[deserialized.Loot[i].player].deleted ~= true) then
                                        EasyBidUtils:Profile_Create(deserialized.Loot[i].player, deserialized.Loot[i].cost, 0, deserialized.Loot[i].cost)
                                    end
                                end
                            end
                        end

                        return
                    elseif prefix == "MonDKPLootDist" then
                        local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, deserialized.player, "player")
                        if search then
                            local DKPTable = MonDKP_EasyBid_DKPTable[search[1][1]]
                            DKPTable.dkp = DKPTable.dkp + deserialized.cost
                            DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
                        else
                            if not MonDKP_EasyBid_Archive[deserialized.player] or (MonDKP_EasyBid_Archive[deserialized.player] and MonDKP_EasyBid_Archive[deserialized.player].deleted ~= true) then
                                EasyBidUtils:Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);
                            end
                        end
                        tinsert(MonDKP_EasyBid_Loot, 1, deserialized)

                    elseif prefix == "MonDKPDKPDist" then
                        local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                        local dkp = deserialized.dkp

                        tinsert(MonDKP_EasyBid_DKPHistory, 1, deserialized)

                        for i=1, #players do
                            local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                            if search then
                                MonDKP_EasyBid_DKPTable[search[1][1]].dkp = MonDKP_EasyBid_DKPTable[search[1][1]].dkp + tonumber(dkp)
                                if tonumber(dkp) > 0 then
                                    MonDKP_EasyBid_DKPTable[search[1][1]].lifetime_gained = MonDKP_EasyBid_DKPTable[search[1][1]].lifetime_gained + tonumber(dkp)
                                end
                            else
                                if not MonDKP_EasyBid_Archive[players[i]] or (MonDKP_EasyBid_Archive[players[i]] and MonDKP_EasyBid_Archive[players[i]].deleted ~= true) then
                                    EasyBidUtils:Profile_Create(players[i], tonumber(dkp), tonumber(dkp));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                end
                            end
                        end
                    elseif prefix == "MonDKPDecay" then
                        local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                        local dkp = {strsplit(",", deserialized.dkp)}

                        tinsert(MonDKP_EasyBid_DKPHistory, 1, deserialized)

                        for i=1, #players do
                            local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                            if search then
                                MonDKP_EasyBid_DKPTable[search[1][1]].dkp = MonDKP_EasyBid_DKPTable[search[1][1]].dkp + tonumber(dkp[i])
                            else
                                if not MonDKP_EasyBid_Archive[players[i]] or (MonDKP_EasyBid_Archive[players[i]] and MonDKP_EasyBid_Archive[players[i]].deleted ~= true) then
                                    EasyBidUtils:Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                end
                            end
                        end
                    elseif prefix == "MonDKPDelUsers" and UnitName("player") ~= sender then
                        for i=1, #deserialized do
                            local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, deserialized[i].player, "player")

                            if search and deserialized[i].deleted and deserialized[i].deleted ~= "Recovered" then
                                if (MonDKP_EasyBid_Archive[deserialized[i].player] and MonDKP_EasyBid_Archive[deserialized[i].player].edited < deserialized[i].edited) or not MonDKP_EasyBid_Archive[deserialized[i].player] then
                                    --delete user, archive data
                                    if not MonDKP_EasyBid_Archive[deserialized[i].player] then		-- creates/adds to archive entry for user
                                        MonDKP_EasyBid_Archive[deserialized[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=deserialized[i].deleted, edited=deserialized[i].edited }
                                    else
                                        MonDKP_EasyBid_Archive[deserialized[i].player].deleted = deserialized[i].deleted
                                        MonDKP_EasyBid_Archive[deserialized[i].player].edited = deserialized[i].edited
                                    end

                                    tremove(MonDKP_EasyBid_DKPTable, search[1][1])
                                end
                            elseif not search and deserialized[i].deleted == "Recovered" then
                                if MonDKP_EasyBid_Archive[deserialized[i].player] and (MonDKP_EasyBid_Archive[deserialized[i].player].edited == nil or MonDKP_EasyBid_Archive[deserialized[i].player].edited < deserialized[i].edited) then
                                    EasyBidUtils:Profile_Create(deserialized[i].player);	-- User was recovered, create/request profile as needed
                                    MonDKP_EasyBid_Archive[deserialized[i].player].deleted = "Recovered"
                                    MonDKP_EasyBid_Archive[deserialized[i].player].edited = deserialized[i].edited
                                end
                            end
                        end
                        return
                    elseif prefix == "MonDKPDelLoot" then
                        local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_Loot, deserialized.deletes, "index")

                        if search then
                            MonDKP_EasyBid_Loot[search[1][1]].deletedby = deserialized.index
                        end

                        local search_player = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, deserialized.player, "player")

                        if search_player then
                            MonDKP_EasyBid_DKPTable[search_player[1][1]].dkp = MonDKP_EasyBid_DKPTable[search_player[1][1]].dkp + deserialized.cost 			 					-- refund previous looter
                            MonDKP_EasyBid_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_EasyBid_DKPTable[search_player[1][1]].lifetime_spent + deserialized.cost 			-- remove from lifetime_spent
                        else
                            if not MonDKP_EasyBid_Archive[deserialized.player] or (MonDKP_EasyBid_Archive[deserialized.player] and MonDKP_EasyBid_Archive[deserialized.player].deleted ~= true) then
                                EasyBidUtils:Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                            end
                        end

                        table.insert(MonDKP_EasyBid_Loot, 1, deserialized)
                        EasyBidComm:SortLootTable()
                    elseif prefix == "MonDKPDelSync" then
                        local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPHistory, deserialized.deletes, "index")
                        local players = {strsplit(",", strsub(deserialized.players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
                        local dkp, mod;

                        if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
                            dkp = {strsplit(",", deserialized.dkp)}
                            mod = "perc";
                        else
                            dkp = deserialized.dkp
                            mod = "whole"
                        end

                        for i=1, #players do
                            if mod == "perc" then
                                local search2 = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                if search2 then
                                    MonDKP_EasyBid_DKPTable[search2[1][1]].dkp = MonDKP_EasyBid_DKPTable[search2[1][1]].dkp + tonumber(dkp[i])
                                else
                                    if not MonDKP_EasyBid_Archive[players[i]] or (MonDKP_EasyBid_Archive[players[i]] and MonDKP_EasyBid_Archive[players[i]].deleted ~= true) then
                                        EasyBidUtils:Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                    end
                                end
                            else
                                local search2 = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                if search2 then
                                    MonDKP_EasyBid_DKPTable[search2[1][1]].dkp = MonDKP_EasyBid_DKPTable[search2[1][1]].dkp + tonumber(dkp)

                                    if tonumber(dkp) < 0 then
                                        MonDKP_EasyBid_DKPTable[search2[1][1]].lifetime_gained = MonDKP_EasyBid_DKPTable[search2[1][1]].lifetime_gained + tonumber(dkp)
                                    end
                                else
                                    if not MonDKP_EasyBid_Archive[players[i]] or (MonDKP_EasyBid_Archive[players[i]] and MonDKP_EasyBid_Archive[players[i]].deleted ~= true) then
                                        local gained;
                                        if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

                                        EasyBidUtils:Profile_Create(players[i], tonumber(dkp), gained);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                    end
                                end
                            end
                        end

                        if search then
                            MonDKP_EasyBid_DKPHistory[search[1][1]].deletedby = deserialized.index;  	-- adds deletedby field if the entry exists
                        end

                        table.insert(MonDKP_EasyBid_DKPHistory, 1, deserialized)
                    end
                end
            end
        end
    end
end