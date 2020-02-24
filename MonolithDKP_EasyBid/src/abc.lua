EasyBid = LibStub("AceAddon-3.0"):NewAddon("EasyBid", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
AceGUI = LibStub("AceGUI-3.0")
local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

EasyBid.var = {
    gui = {
        frame = nil,
        editBox = nil,
        slider = nil,
        currentItem = nil,
        highestBidder = nil,
        isVisible = false,
    },
    minimumBid = 10,
--    minimumBid = nil,
    myBid = 10,
--    myBid = nil,
    bidOfficer = "Karthay",
--    bidOfficer = nil,
    currentItem = "16908",
--    currentItem = nil,
    bidders = {},
    maxBidder = nil,
    maxBidValue = nil,
    nextMinimum = 10,
--    nextMinimum = nil,
}

function EasyBid:OnInitialize()
    if not MonDKP_DKPTable then MonDKP_DKPTable = {} end;

    EasyBid:Print("EASY BID INITIALIZED")
end

function EasyBid:OnEnable()
--    EasyBid:RegisterEvent("CHAT_MSG_SAY", "OnMessage")
    EasyBid:RegisterEvent("CHAT_MSG_RAID", "OnMessage")
    EasyBid:RegisterEvent("CHAT_MSG_RAID_WARNING", "OnMessage")

    EasyBid:RegisterEvent("GET_ITEM_INFO_RECEIVED", "OnItemInfoReceived")

    EasyBid:RegisterComm("MonDKPDelUsers", EasyBid:OnCommReceived())      -- Broadcasts deleted users (archived users not on the DKP table)
    EasyBid:RegisterComm("MonDKPMerge", EasyBid:OnCommReceived())      -- Broadcasts 2 weeks of data from officers (for merging)
    -- Normal broadcast Prefixs
    EasyBid:RegisterComm("MonDKPDecay", EasyBid:OnCommReceived())        -- Broadcasts a weekly decay adjustment
    EasyBid:RegisterComm("MonDKPBCastMsg", EasyBid:OnCommReceived())      -- broadcasts a message that is printed as is
    EasyBid:RegisterComm("MonDKPCommand", EasyBid:OnCommReceived())      -- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
    EasyBid:RegisterComm("MonDKPLootDist", EasyBid:OnCommReceived())      -- broadcasts individual loot award to loot table
    EasyBid:RegisterComm("MonDKPDelLoot", EasyBid:OnCommReceived())      -- broadcasts deleted loot award entries
    EasyBid:RegisterComm("MonDKPDelSync", EasyBid:OnCommReceived())      -- broadcasts deleated DKP history entries
    EasyBid:RegisterComm("MonDKPDKPDist", EasyBid:OnCommReceived())      -- broadcasts individual DKP award to DKP history table
    EasyBid:RegisterComm("MonDKPMinBid", EasyBid:OnCommReceived())      -- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
    EasyBid:RegisterComm("MonDKPMaxBid", EasyBid:OnCommReceived())      -- broadcasts maximum dkp values (set in Options tab or custom values in bid window)
    EasyBid:RegisterComm("MonDKPWhitelist", EasyBid:OnCommReceived())      -- broadcasts whitelist
    EasyBid:RegisterComm("MonDKPDKPModes", EasyBid:OnCommReceived())      -- broadcasts DKP Mode settings
    EasyBid:RegisterComm("MonDKPStand", EasyBid:OnCommReceived())        -- broadcasts standby list
    EasyBid:RegisterComm("MonDKPRaidTime", EasyBid:OnCommReceived())      -- broadcasts Raid Timer Commands
    EasyBid:RegisterComm("MonDKPZSumBank", EasyBid:OnCommReceived())    -- broadcasts ZeroSum Bank
    EasyBid:RegisterComm("MonDKPQuery", EasyBid:OnCommReceived())        -- Querys guild for spec/role data
    EasyBid:RegisterComm("MonDKPBuild", EasyBid:OnCommReceived())        -- broadcasts Addon build number to inform others an update is available.
    EasyBid:RegisterComm("MonDKPBossLoot", EasyBid:OnCommReceived())      -- broadcast current loot table
    EasyBid:RegisterComm("MonDKPBidShare", EasyBid:OnCommReceived())      -- broadcast accepted bids
    EasyBid:RegisterComm("MonDKPBidder", EasyBid:OnCommReceived())      -- Submit bids
    EasyBid:RegisterComm("MonDKPAllTabs", EasyBid:OnCommReceived())      -- Full table broadcast

    --    EasyBid:SendCommMessage("MonDKPQuery", "start", "GUILD")

    EasyBid:RegisterChatCommand("ebid", "ShowBiddingFrame", true)

    GuildRoster()

end

function EasyBid:OnDisable()
--    EasyBid:UnregisterEvent("CHAT_MSG_SAY")
    EasyBid:UnregisterEvent("CHAT_MSG_RAID")
    EasyBid:UnregisterEvent("CHAT_MSG_RAID_WARNING")

    EasyBid:UnregisterChatCommand("ebid")

    --    EasyBid.StopGUI()
end

function EasyBid:ShowBiddingFrame()
    if (not EasyBid.var.gui.isVisible) then
        if (EasyBid.var.currentItem ~= nil) then
            EasyBid:StartGUI()
            EasyBid.var.gui.isVisible = true
        else
            EasyBid:Print("No bidding in progress")
        end
    end
end

function EasyBid:HideBiddingFrame()
    if (EasyBid.var.gui.isVisible) then
        EasyBid:StopGUI()
        EasyBid.var.gui.isVisible = false
    end
end

function EasyBid:FillCurrentItem()
    local _,itemLink,itemRarity,_,_,_,_,_,_,itemIcon = GetItemInfo(EasyBid.var.currentItem)

    if (EasyBid.var.gui.currentItem ~= nil) then
        local tooltip = AceGUI.tooltip;

        EasyBid.var.gui.currentItem:SetText(itemLink)
        EasyBid.var.gui.currentItem:SetImage(itemIcon)
        EasyBid.var.gui.currentItem:SetCallback("OnEnter", function(widget)
            if (tooltip ~= nil) then
                tooltip:SetOwner(EasyBid.var.gui.currentItem.frame, "ANCHOR_NONE")
                tooltip:ClearAllPoints()
                tooltip:SetPoint("LEFT", EasyBid.var.gui.currentItem.frame, "RIGHT")
                tooltip:SetHyperlink(itemLink);
                tooltip:Show();
            end
        end);
        EasyBid.var.gui.currentItem:SetCallback("OnLeave", function()
            if (tooltip ~= nil) then
                tooltip:Hide()
            end
        end);
    end
end


function EasyBid:FillBidders()
    EasyBid.var.maxBidder = nil;
    EasyBid.var.maxBidValue = 0

    if (EasyBid.var.gui.scroll ~= nil) then
        EasyBid.var.gui.scroll:ReleaseChildren();
    end

    for index, value in ipairs(EasyBid.var.bidders) do
        if (EasyBid.var.gui.scroll ~= nil) then
            local className, classFilename = UnitClass(value.player)
            print(value.player, className, classFilename)
            local a = AceGUI:Create("Label")
            a:SetText(value.bid .. " - " .. value.player)
            EasyBid.var.gui.scroll:AddChild(a)
        end

        if (value.bid > EasyBid.var.maxBidValue) then
            EasyBid.var.maxBidder = value
            EasyBid.var.maxBidValue = value.bid
        end
    end

    if (EasyBid.var.gui.highestBidder ~= nil) then
        local highestBidderText
        if (EasyBid.var.maxBidder ~= nil and EasyBid.var.maxBidder.bid > 0 and EasyBid.var.maxBidder.player ~= nil) then
            highestBidderText = EasyBid.var.maxBidder.bid .. " - " .. EasyBid.var.maxBidder.player
        else
            highestBidderText = "NO BIDDER"
        end
        EasyBid.var.gui.highestBidder:SetText(highestBidderText)
    end

    EasyBid:SetNextMinimum()
end


function EasyBid:OnItemInfoReceived(self, itemId, success)
    if (success == true and EasyBid.var.currentItem == tostring(itemId)) then
        EasyBid:FillCurrentItem();
    end
end

local Bids_Submitted = {};

-- ebid start 16908 10
-- ebid bid Killufast 50
function EasyBid:OnMessage(self, message, author)
    if(string.find(message, "ebid") ~= nil) then
        local t = {}
        for i in string.gmatch(message, "[^%s]+") do
            t[#t + 1] = i
        end

        if (t[2] == "start") then
            local itemId = t[3];
            local minBid = t[4];
            EasyBid:SendData("MonDKPCommand", "BidInfo,"..itemId..","..minBid..","..",")
        elseif(t[2] == "bid") then
            local player = t[3];
            local dkp = tonumber(t[4]);
            table.insert(Bids_Submitted, {player=player, dkp=dkp})
            EasyBid:SendData("MonDKPBidShare", Bids_Submitted)
        elseif(t[2] == "stop") then
            EasyBid:SendData("MonDKPCommand", "StopBidTimer")
        end
    elseif(string.find(message, "Bidding closed!") ~= nil) then
        EasyBid:HideBiddingFrame()

        EasyBid.var.minimumBid = nil;
        EasyBid.var.myBid = nil;
        EasyBid.var.bidOfficer = nil;
        EasyBid.var.currentItem = nil;
        EasyBid.var.bidders = {};
        EasyBid.var.nextMinimum = nil
    end
end

function EasyBid:normalizeBid(value)
    if (value ~= nil) then
        local parsed = tonumber(value)
        parsed = parsed - (parsed % EasyBid.var.minimumBid)
        return parsed
    end

    return nil
end

function EasyBid:setMyBid(value, change)
    if (value ~= nil) then
        EasyBid.var.myBid = EasyBid:normalizeBid(value)
    elseif (change ~= nil) then
        EasyBid.var.myBid = EasyBid.var.myBid + change
    end

    EasyBid.var.myBid = math.max(EasyBid.var.myBid, EasyBid.var.nextMinimum);
    EasyBid.var.myBid = math.min(EasyBid.var.myBid, EasyBid:normalizeBid(EasyBid.var.myMax));

    EasyBid.var.gui.editBox:SetText(tostring(EasyBid.var.myBid))
    EasyBid.var.gui.slider:SetValue(EasyBid.var.myBid)
end

function EasyBid:SetNextMinimum()
    local minimum = EasyBid.var.minimumBid
    if (EasyBid.var.maxBidder ~= nil) then
        minimum = minimum + EasyBid.var.maxBidder.bid
    end
    EasyBid.var.nextMinimum = minimum

    if (EasyBid.var.myBid ~= nil and minimum ~= nil and EasyBid.var.gui.editBox ~= nil and EasyBid.var.myBid < minimum) then
        EasyBid:setMyBid(minimum, null)
    end
end

function EasyBid:StartGUI()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Monolith DKP Easy Bid")
    frame:SetWidth(500)
    frame:SetHeight(500)
    frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 100, -100);
    frame:SetLayout("Flow");

    local scrollcontainer = AceGUI:Create("InlineGroup")
    scrollcontainer:SetTitle("bid history")
    scrollcontainer:SetWidth(150)
    scrollcontainer:SetHeight(100) -- probably?
    scrollcontainer:SetLayout("Fill") -- important!

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollcontainer:AddChild(scroll)

    local name,_ = UnitName("player")
    local search = EasyBid:Table_Search(MonDKP_DKPTable, name)
    local max = MonDKP_DKPTable[search[1][1]].dkp
    EasyBid.var.myMax = max

    local currentItem = AceGUI:Create("InteractiveLabel")
    currentItem:SetWidth(350)
    currentItem:SetHeight(50)

    local highestBidder = AceGUI:Create("Label")
    highestBidder:SetWidth(350)
    highestBidder:SetHeight(50)

    local editbox = AceGUI:Create("EditBox")
    editbox:SetText(tostring(EasyBid.var.minimumBid))
    editbox:SetLabel("Insert text:")
    editbox:SetWidth(200)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) EasyBid:setMyBid(text, nil) end)

    local btnBid = AceGUI:Create("Button")
    btnBid:SetText("submit")
    btnBid:SetWidth(265)
    btnBid:SetHeight(50)
    btnBid:SetCallback("OnClick", function()
        if (EasyBid.var.bidOfficer ~= nil) then
            SendChatMessage("!bid " .. tostring(EasyBid.var.myBid), "WHISPER", nil, EasyBid.var.bidOfficer);
        else
            SendChatMessage("!bid " .. tostring(EasyBid.var.myBid), "RAID");
        end
    end)

    local btnAdd10 = AceGUI:Create("Button")
    btnAdd10:SetText("+"..EasyBid.var.minimumBid)
    btnAdd10:SetWidth(80)
    btnAdd10:SetHeight(30)
    btnAdd10:SetCallback("OnClick", function() EasyBid:setMyBid(nil, EasyBid.var.minimumBid) end)

    local btnAdd50 = AceGUI:Create("Button")
    btnAdd50:SetText("+"..(5 * EasyBid.var.minimumBid))
    btnAdd50:SetWidth(80)
    btnAdd50:SetHeight(30)
    btnAdd50:SetCallback("OnClick", function() EasyBid:setMyBid(nil, 5 * EasyBid.var.minimumBid) end)

    local btnAdd100 = AceGUI:Create("Button")
    btnAdd100:SetText("+"..(10 * EasyBid.var.minimumBid))
    btnAdd100:SetWidth(80)
    btnAdd100:SetHeight(30)
    btnAdd100:SetCallback("OnClick", function() EasyBid:setMyBid(nil, 10 * EasyBid.var.minimumBid) end)

    local btnMinus10 = AceGUI:Create("Button")
    btnMinus10:SetText("-"..EasyBid.var.minimumBid)
    btnMinus10:SetWidth(80)
    btnMinus10:SetHeight(30)
    btnMinus10:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -EasyBid.var.minimumBid) end)

    local btnMinus50 = AceGUI:Create("Button")
    btnMinus50:SetText("-"..(5 * EasyBid.var.minimumBid))
    btnMinus50:SetWidth(80)
    btnMinus50:SetHeight(30)
    btnMinus50:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -5 * EasyBid.var.minimumBid) end)

    local btnMinus100 = AceGUI:Create("Button")
    btnMinus100:SetText("-"..(10 * EasyBid.var.minimumBid))
    btnMinus100:SetWidth(80)
    btnMinus100:SetHeight(30)
    btnMinus100:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -10 * EasyBid.var.minimumBid) end)

    local minBidSlider = AceGUI:Create("Slider")
    minBidSlider:SetLabel("Bid Increase")
    minBidSlider:SetSliderValues(EasyBid.var.minimumBid, EasyBid:normalizeBid(max), EasyBid.var.minimumBid)
    minBidSlider:SetValue(EasyBid.var.myBid)
    minBidSlider:SetCallback("OnValueChanged", function(widget, name, value) EasyBid:setMyBid(value, nil) end)

    local btnSetMinimum = AceGUI:Create("Button")
    btnSetMinimum:SetText("MIN")
    btnSetMinimum:SetWidth(80)
    btnSetMinimum:SetHeight(30)
    btnSetMinimum:SetCallback("OnClick", function() EasyBid:setMyBid(EasyBid.var.minimumBid, nil) end)

    local btnSetHalf = AceGUI:Create("Button")
    btnSetHalf:SetText("HALF")
    btnSetHalf:SetWidth(80)
    btnSetHalf:SetHeight(30)
    btnSetHalf:SetCallback("OnClick", function() EasyBid:setMyBid(max / 2, nil) end)

    local btnSetMaximum = AceGUI:Create("Button")
    btnSetMaximum:SetText("MAX")
    btnSetMaximum:SetWidth(80)
    btnSetMaximum:SetHeight(30)
    btnSetMaximum:SetCallback("OnClick", function() EasyBid:setMyBid(max, nil) end)

    frame:AddChild(scrollcontainer)
    frame:AddChild(currentItem)
    frame:AddChild(highestBidder)
    frame:AddChild(editbox)
    frame:AddChild(btnBid)
    frame:AddChild(btnAdd10)
    frame:AddChild(btnAdd50)
    frame:AddChild(btnAdd100)
    frame:AddChild(btnMinus10)
    frame:AddChild(btnMinus50)
    frame:AddChild(btnMinus100)
    frame:AddChild(minBidSlider)
    frame:AddChild(minBidSlider)
    frame:AddChild(btnSetMinimum)
    frame:AddChild(btnSetHalf)
    frame:AddChild(btnSetMaximum)


    EasyBid.var.gui.frame = frame
    EasyBid.var.gui.editBox = editbox
    EasyBid.var.gui.slider = minBidSlider
    EasyBid.var.gui.currentItem = currentItem
    EasyBid.var.gui.scroll = scroll;
    EasyBid.var.gui.highestBidder = highestBidder;

    EasyBid:FillCurrentItem();
    EasyBid:FillBidders();

    EasyBid.var.gui.frame:Show();

end

function EasyBid:StopGUI()
    if (EasyBid.var.gui.frame ~= nil) then
        EasyBid.var.gui.frame:Hide();
    end
end




function EasyBid:GetGuildRankIndex(player)
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

function EasyBid:ValidateSender(sender)                -- returns true if "sender" has permission to write officer notes. false if not or not found.
    local rankIndex = EasyBid:GetGuildRankIndex(sender);

    if rankIndex == 1 then             -- automatically gives permissions above all settings if player is guild leader
        return true;
    end
    if rankIndex then
        return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]    -- returns true/false if player can write to officer notes
    else
        return false;
    end
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: MonDKP_DKPTable, "Roeshambo", "player" would only search for Roeshambo in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, MonDKP_DKPTable[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be MonDKP_DKPTable[search[1][1]][search[1][2]][search[1][3]].  MonDKP_DKPTable[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function EasyBid:Table_Search(tar, val, field)
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

-- MonDKPCommand, StartBidTimer,20,[ItemLink] Min Bid: 10, 133768, RAID, Zeusovaneter
-- MonDKPCommand, BidInfo,20,[ItemLink],10,133768, RAID, Zeusovaneter -- dloouhy ID je id ikony
-- MonDKPCommand, BidInfo,[ItemLink2],10,133143, RAID, Zeusovaneter
-- RW: "Taking bids on [ItemLink] (10 DKP Minimum bid)"
-- MonDKPBidder, !bid 10, RAID, Migas -- neudela nic, pokud neprehodil
-- RAID: "New highest bidder is Migas (10 DKP)"
-- MonDKPBidShare, ?qeqwewq, RAID, Zeusovaneter
-- MonDKPBidder, pass, RAID, Popletka
-- MonDKPBossLoot, wqewqeh
-- RAID: "Bidding Closed!"
-- MonDKPLootDist, qwewqejqweh, GUILD, Zeusovaneter
-- GUILD: "Congrats Uada on [ItemLink] @ 260 DKP
-- MonDKPCommand, StopBidTimer, RAID, Zeusovaneter

--table.insert(Bids_Submitted, {player=name, dkp=dkp})
function EasyBid:OnCommReceived(prefix, message, distribution, sender)
    EasyBid:Print("COMM: " .. tostring(prefix) .. ", " .. tostring(message) .. ", " .. tostring(distribution) .. ", " .. tostring(sender))

    if prefix then
        --        if prefix == "MonDKPBidder" then
        --            if core.BidInProgress and core.IsOfficer then
        --                if message == "pass" then
        --                    MonDKP:Print(sender.." has passed.")
        --                    return
        --                else
        --                    MonDKP_CHAT_MSG_WHISPER(message, sender)
        --                    return
        --                end
        --            else
        --                return
        --        end
        if EasyBid:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
            if (prefix == "MonDKPCommand") then
                local command, arg1, arg2, arg3, arg4 = strsplit(",", message);
                if sender ~= UnitName("player") then
                    if command == "StartTimer" then
                        --                        MonDKP:StartTimer(arg1, arg2)
                    elseif command == "StartBidTimer" then
                        --                        MonDKP:StartBidTimer(arg1, arg2, arg3)
                        --                        core.BiddingInProgress = true;
                        --                        if strfind(arg1, "{") then
                        --                            MonDKP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
                        --                        end
                    elseif command == "StopBidTimer" then
                        EasyBid:HideBiddingFrame()

                        EasyBid.var.minimumBid = nil;
                        EasyBid.var.myBid = nil;
                        EasyBid.var.bidOfficer = nil;
                        EasyBid.var.currentItem = nil;
                        EasyBid.var.bidders = {};
                        EasyBid.var.nextMinimum = nil
                    elseif command == "BidInfo" then
                        EasyBid.var.currentItem = arg1
                        EasyBid.var.minimumBid = tonumber(arg2)
                        EasyBid.var.bidOfficer = sender
                        EasyBid.var.myBid = EasyBid.var.minimumBid
                        EasyBid.var.nextMinimum = EasyBid.var.minimumBid

                        EasyBid:ShowBiddingFrame()
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

                            MonDKP_DKPTable = deserialized.DKPTable
                            return
                        elseif prefix == "MonDKPBidShare" then
                            local bidders = deserialized
                            table.sort(bidders, function (k1, k2) return k1.bid > k2.bid end)
                            EasyBid.var.bidders = bidders
                            EasyBid:FillBidders()
                            return
                        elseif prefix == "MonDKPLootDist" then
                            local search = EasyBid:Table_Search(MonDKP_DKPTable, deserialized.player, "player")
                            if search then
                                local DKPTable = MonDKP_DKPTable[search[1][1]]
                                DKPTable.dkp = DKPTable.dkp + deserialized.cost
                                DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
                            end
                        elseif prefix == "MonDKPDKPDist" then
                            local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                            local dkp = deserialized.dkp

                            for i=1, #players do
                                local search = EasyBid:Table_Search(MonDKP_DKPTable, players[i], "player")

                                if search then
                                    MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + tonumber(dkp)
                                    if tonumber(dkp) > 0 then
                                        MonDKP_DKPTable[search[1][1]].lifetime_gained = MonDKP_DKPTable[search[1][1]].lifetime_gained + tonumber(dkp)
                                    end
                                end
                            end
                        elseif prefix == "MonDKPDecay" then
                            local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                            local dkp = {strsplit(",", deserialized.dkp)}

                            for i=1, #players do
                                local search = EasyBid:Table_Search(MonDKP_DKPTable, players[i], "player")

                                if search then
                                    MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + tonumber(dkp[i])
                                end
                            end
                        elseif prefix == "MonDKPDelLoot" then
                            local search = EasyBid:Table_Search(MonDKP_Loot, deserialized.deletes, "index")

                            if search then
                                MonDKP_Loot[search[1][1]].deletedby = deserialized.index
                            end

                            local search_player = EasyBid:Table_Search(MonDKP_DKPTable, deserialized.player, "player")

                            if search_player then
                                MonDKP_DKPTable[search_player[1][1]].dkp = MonDKP_DKPTable[search_player[1][1]].dkp + deserialized.cost                  -- refund previous looter
                                MonDKP_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_DKPTable[search_player[1][1]].lifetime_spent + deserialized.cost       -- remove from lifetime_spent
                            end
                        elseif prefix == "MonDKPDelSync" then
                            local players = {strsplit(",", strsub(deserialized.players, 1, -2))}   -- cuts off last "," from string to avoid creating an empty value
                            local dkp, mod;

                            if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then     -- determines if it's a mass decay
                                dkp = {strsplit(",", deserialized.dkp)}
                                mod = "perc";
                            else
                                dkp = deserialized.dkp
                                mod = "whole"
                            end

                            for i=1, #players do
                                if mod == "perc" then
                                    local search2 = EasyBid:Table_Search(MonDKP_DKPTable, players[i], "player")

                                    if search2 then
                                        MonDKP_DKPTable[search2[1][1]].dkp = MonDKP_DKPTable[search2[1][1]].dkp + tonumber(dkp[i])
                                    end
                                else
                                    local search2 = EasyBid:Table_Search(MonDKP_DKPTable, players[i], "player")

                                    if search2 then
                                        MonDKP_DKPTable[search2[1][1]].dkp = MonDKP_DKPTable[search2[1][1]].dkp + tonumber(dkp)

                                        if tonumber(dkp) < 0 then
                                            MonDKP_DKPTable[search2[1][1]].lifetime_gained = MonDKP_DKPTable[search2[1][1]].lifetime_gained + tonumber(dkp)
                                        end
                                    end
                                end
                            end
                        elseif prefix == "MonDKPMerge" then
                            for i=1, #MonDKP_DKPTable do
                                if MonDKP_DKPTable[i].class == "NONE" then
                                    local search = EasyBid:Table_Search(deserialized.Profiles, MonDKP_DKPTable[i].player, "player")

                                    if search then
                                        MonDKP_DKPTable[i].class = deserialized.Profiles[search[1][1]].class
                                    end
                                end
                            end

                            return
                        end
                    end
                end
            end
        end
    end
end

function EasyBid:SendData(prefix, data, target)
    --if prefix ~= "MDKPProfile" then print("|cff00ff00Sent: "..prefix.."|r") end
    if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

    -- non officers / not encoded
    if IsInGuild() then
        if prefix == "MonDKPQuery" or prefix == "MonDKPBuild" or prefix == "MonDKPTalents" or prefix == "MonDKPRoles" then
            EasyBid:SendCommMessage(prefix, data, "SAY")
            return;
        elseif prefix == "MonDKPBidder" then    -- bid submissions. Keep to raid.
            EasyBid:SendCommMessage(prefix, data, "SAY")
            return;
        end
    end

    -- officers
    if IsInGuild() then
        local serialized = nil;
        local packet = nil;

        if prefix == "MonDKPCommand" or prefix == "MonDKPRaidTime" then
            EasyBid:SendCommMessage(prefix, data, "SAY")
            return;
        end

        if prefix == "MonDKPBCastMsg" then
            EasyBid:SendCommMessage(prefix, data, "SAY")
            return;
        end

        if data then
            serialized = LibAceSerializer:Serialize(data);  -- serializes tables to a string
        end

        local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
        if compressed then
            packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
        end

        -- encoded
        if (prefix == "MonDKPZSumBank" or prefix == "MonDKPBossLoot" or prefix == "MonDKPBidShare") then    -- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
            EasyBid:SendCommMessage(prefix, packet, "SAY")
            return;
        end
    end
end

