EasyBidUtils = LibStub("AceAddon-3.0"):NewAddon("EasyBidUtils")

local classes = {
    WARRIOR={
        weapons= {0,1,2,3,4,5,6,7,8,10,13,14,15,16,18,20},
        armor={-8,-6,-5,-3,0,1,2,3,4,6 },
        color={r=0.78,g=0.61,b=0.43},
    },
    ROGUE={
        weapons= {2,3,4,7,13,14,15,16,18,20},
        armor={-8,-6,-5,-3,0,1,2 },
        color={r=1,g=0.96,b=0.41},
    },
    MAGE={
        weapons= {7,10,14,15,19,20},
        armor={-8,-6,-5,-3,0,1 },
        color={r=0.25,g=0.78,b=0.92},
    },
    PRIEST={
        weapons= {4,10,14,15,19,20},
        armor={-8,-6,-5,-3,0,1 },
        color={r=1,g=1,b=1},
    },
    WARLOCK={
        weapons= {7,10,14,15,19,20},
        armor={-8,-6,-5,-3,0,1},
        color={r=0.53,g=0.53,b=0.93},
    },
    HUNTER={
        weapons= {0,1,2,3,6,7,8,10,13,14,15,16,18,20},
        armor={-8,-6,-5,-3,0,1,2,3 },
        color={r=0.67,g=0.83,b=0.45},
    },
    SHAMAN={
        weapons= {0,1,4,5,10,13,14,15,20},
        armor={-8,-6,-5,-3,0,1,2,3,6,9,11},
        color={r=0,g=0.44,b=0.87},
    },
    DRUID={
        weapons= {4,5,10,13,14,15,20},
        armor={-8,-6,-5,-3,0,1,2,8,11},
        color={r=1,g=0.49,b=0.04},
    },
    PALADIN={
        weapons= {0,1,4,5,6,7,8,14,20},
        armor={-8,-6,-5,-3,0,1,2,3,4,6,7,11},
        color={r=0.96,g=0.55,b=0.73},
    },
}


function EasyBidUtils:GetGuildRankIndex(player)
    local name, rank;
    local guildSize,_,_ = GetNumGuildMembers();

    if IsInGuild() then
        for i=1, tonumber(guildSize) do
            name,_,rank = GetGuildRosterInfo(i)
            name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
            if name == player then
                return rank+1;
            end
        end
        return false;
    end
end

function EasyBidUtils:GetGuildRank(player)
    local name, rank, rankIndex;
    local guildSize;

    if IsInGuild() then
        guildSize = GetNumGuildMembers();
        for i=1, guildSize do
            name, rank, rankIndex = GetGuildRosterInfo(i)
            name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
            if name == player then
                return rank, rankIndex;
            end
        end
    end
    return nil
end

function EasyBidUtils:GetClass(player)
    local cls = nil;
    local search = EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, player)
    if (search) then
        cls = MonDKP_EasyBid_DKPTable[search[1][1]].class
    end

    if (cls == nil) then
        local playerForClass = player;
        if (UnitName("player") == player) then
            playerForClass = "player";
        end

        local _, classFilename = UnitClass(playerForClass)
        cls = classFilename
    end

    return cls;
end

function EasyBidUtils:GetClassColor(player)
    local cls = EasyBidUtils:GetClass(player);

    if (cls ~= nil and classes[cls] ~= nil) then
        return classes[cls].color.r, classes[cls].color.g, classes[cls].color.b
    end

    return 1, 1, 1
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: MonDKP_EasyBid_DKPTable, "Roeshambo", "player" would only search for Roeshambo in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, MonDKP_EasyBid_DKPTable[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be MonDKP_EasyBid_DKPTable[search[1][1]][search[1][2]][search[1][3]].  MonDKP_EasyBid_DKPTable[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function EasyBidUtils:Table_Search(tar, val, field)
    local value = string.upper(tostring(val));
    local location = {}
    for k,v in pairs(tar) do
        if(type(v) == "table") then
            local temp1 = k
            for k,v in pairs(v) do
                if(type(v) == "table") then
                    local temp2 = k;
                    for k,v in pairs(v) do
                        if(type(v) == "table") then
                            local temp3 = k
                            for k,v in pairs(v) do
                                if string.upper(tostring(v)) == value then
                                    if field then
                                        if k == field then
                                            tinsert(location, {temp1, temp2, temp3, k} )
                                        end
                                    else
                                        tinsert(location, {temp1, temp2, temp3, k} )
                                    end
                                end;
                            end
                        end
                        if string.upper(tostring(v)) == value then
                            if field then
                                if k == field then
                                    tinsert(location, {temp1, temp2, k} )
                                end
                            else
                                tinsert(location, {temp1, temp2, k} )
                            end
                        end;
                    end
                end
                if string.upper(tostring(v)) == value then
                    if field then
                        if k == field then
                            tinsert(location, {temp1, k} )
                        end
                    else
                        tinsert(location, {temp1, k} )
                    end
                end;
            end
        end
        if string.upper(tostring(v)) == value then
            if field then
                if k == field then
                    tinsert(location, k)
                end
            else
                tinsert(location, k)
            end
        end;
    end
    if (#location > 0) then
        return location;
    else
        return false;
    end
end

function EasyBidUtils:HSVtoRGB(h, s, v)
    local i; -- int
    local f, p, q, t; -- float
    if( s == 0 ) then
        return v, v, v;
    end

    h = h / 60; --			// sector 0 to 5
    i = math.floor( h );
    f = h - i;		--	// factorial part of h
    p = v * ( 1 - s );
    q = v * ( 1 - s * f );
    t = v * ( 1 - s * ( 1 - f ) );

    if (i == 0) then
        return v, t, p;
    elseif(i == 1) then
        return q, v, p;
    elseif(i == 2) then
        return p, v, t;
    elseif(i == 3) then
        return p, q, v;
    elseif(i == 4) then
        return t, p, v;
    elseif(i == 5) then
        return v, p, q;
    end
end

function EasyBidUtils:Profile_Create(player, dkp, gained, spent)
    local tempName, tempClass
    local guildSize = GetNumGuildMembers();
    local class = "NONE"
    local dkp = dkp or 0
    local gained = gained or 0
    local spent = spent or 0
    local created = false

    for i=1, guildSize do
        tempName,_,_,_,_,_,_,_,_,_,tempClass = GetGuildRosterInfo(i)
        tempName = strsub(tempName, 1, string.find(tempName, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
        if tempName == player then
            class = tempClass
            table.insert(MonDKP_EasyBid_DKPTable, { player=player, lifetime_spent=spent, lifetime_gained=gained, class=class, dkp=dkp, rank=10, rankName="None", previous_dkp=0, })

            created = true
            break
        end
    end

    if not created and (IsInRaid() or IsInGroup()) then 	-- if player not found in guild, checks raid/party
        local GroupSize

        if IsInRaid() then
            GroupSize = 40
        elseif IsInGroup() then
            GroupSize = 5
        end

        for i=1, GroupSize do
            tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
            if tempName == player then
                if not EasyBidUtils:Table_Search(MonDKP_EasyBid_DKPTable, tempName, "player") then
                    tinsert(MonDKP_EasyBid_DKPTable, { player=player, class=tempClass, dkp=dkp, previous_dkp=0, lifetime_gained=gained, lifetime_spent=spent, rank=10, rankName="None", })
                    created = true
                    break
                end
            end
        end
    end

    if not created then
        tinsert(MonDKP_EasyBid_DKPTable, { player=player, class=class, dkp=dkp, previous_dkp=0, lifetime_gained=gained, lifetime_spent=spent, rank=10, rankName="None", })
    end

    return created
end

