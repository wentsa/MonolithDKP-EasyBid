EasyBid = LibStub("AceAddon-3.0"):NewAddon("EasyBid", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceHook-3.0")
AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

local MAXIMUM = 99999;
local bidStepDefault = 10;

EasyBid.var = {
    gui = {
        isVisible = false,
        frame = nil,
        editBox = nil,
        slider = nil,
        currentItem = nil,
        groupBidder = nil,
        scrollContainer = nil,
        whisp = nil,
        btnBid = nil,
        scroll = nil,
        btnSetHalf = nil,
        btnSetMaximum = nil,
        isBidMax = nil,
    },
    minimumBid = nil,
    myBid = nil,
    bidOfficer = nil,
    currentItem = nil,
    nextMinimum = nil,
    bidders = {},
    maxBidder = nil,
    maxBidValue = nil,
    lastOfficerWhisper = nil,
    isEditing = false,
}

local weaponItemType = 2;
local weaponTypes = {
    [0] = "One-Handed Axes",
    [1] = "Two-Handed Axes",
    [2] = "Bows",
    [3] = "Guns",
    [4] = "One-Handed Maces",
    [5] = "Two-Handed Maces",
    [6] = "Polearms",
    [7] = "One-Handed Swords",
    [8] = "Two-Handed Swords",
--    [9] = "Warglaives",
    [10] = "Staves",
--    [11] = "Bear Claws",
--    [12] = "CatClaws",
    [13] = "Fist Weapons",
    [14] = "Miscellaneous",
    [15] = "Daggers",
    [16] = "Thrown",
--    [17] = "Spears",
    [18] = "Crossbows",
    [19] = "Wands",
    [20] = "Fishing Poles",
}

local armorItemType = 4;
local armorTypes = {
    [-8] = "Shirts",
    [-6] = "Cloaks",
    [-5] = "Off-hand",
    [-3] = "Amulet",
    [0] = "Miscellaneous",
    [1] = "Cloth",
    [2] = "Leather",
    [3] = "Mail",
    [4] = "Plate",
--    [5] = "Cosmetic",
    [6] = "Shields",
    [7] = "Librams", -- paladin
    [8] = "Idols", -- druid
    [9] = "Totems", -- shaman
--    [10] = "Sigils", -- DK
    [11] = "Relic", -- druid, pala, shamy
}
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

EasyBid.Options = {
    type = "group",
    name = "Monolith DKP Easy Bid",
    args = {
        general = {
            type = "group",
            name = "General",
            order = 0,
            args = {
                bidStep = {
                    type = "input",
                    name = "Bid step",
                    desc = "Minimum step between two consecutive bids",
                    width = "half",
                    get = function() return tostring(EasyBidSettings.bidStep) end,
                    set = function(_, value) EasyBidSettings.bidStep = tonumber(value) end,
                    validate = function(_, value)
                        return strmatch(value, "^%d+$") and tonumber(value) ~= nil and tonumber(value) > 0
                    end
                },
                resetPosition = {
                    type = "execute",
                    name = "Reset frame position",
                    desc = "Resets bidding frame position to default",
                    func = function()
                        EasyBidSettings.position = nil
                        if (EasyBid.var.gui.isVisible) then
                            EasyBid:PositionFrame()
                        end
                        EasyBid:Print("----------------------------------------")
                        EasyBid:Print("Bidding window position reset succesful.")
                        EasyBid:Print("----------------------------------------")
                    end
                }
            }
        },
        armor = {
            type = "group",
            name = "Armor",
            desc = "Set armor types for which the bidding window will be opened automatically",
            get = function(info) return not EasyBidSettings.armor[info.arg] end,
            set = function(info, value) EasyBidSettings.armor[info.arg] = not value end,
        },
        weapons = {
            type = "group",
            name = "Weapons",
            desc = "Set weapon types for which the bidding window will be opened automatically",
            get = function(info) return not EasyBidSettings.weapons[info.arg] end,
            set = function(info, value) EasyBidSettings.weapons[info.arg] = not value end,
        },
    }
}

function EasyBid:OnInitialize()
    if not MonDKP_EasyBid_DKPTable then MonDKP_EasyBid_DKPTable = {} end;
    if not EasyBidSettings then EasyBidSettings = {
        armor = {},
        weapons = {},
        initialized = false,
        position = nil,
        useMyMax = true,
        bidStep = bidStepDefault,
    } end;

    if (EasyBidSettings.bidStep == nil) then
        EasyBidSettings.bidStep = bidStepDefault;
    end

    local myName = UnitName("player")
    local cls = EasyBid:GetClass(myName)

    -- Fill options table armor
    local armor = {}
    for index, value in pairs(armorTypes) do
        armor[tostring(index)] = { type = "toggle", name = value, arg = index }
        if (not EasyBidSettings.initialized) then
            EasyBidSettings.armor[index] = not EasyBid:CanEquip(cls, armorItemType, index)
        end
    end
    EasyBid.Options.args.armor.args = armor;

    -- Fill options weapon
    local weapons = {}
    for index, value in pairs(weaponTypes) do
        weapons[tostring(index)] = { type = "toggle", name = value, arg = index }
        if (not EasyBidSettings.initialized) then
            EasyBidSettings.weapons[index] = not EasyBid:CanEquip(cls, weaponItemType, index)
        end
    end
    EasyBid.Options.args.weapons.args = weapons;

    AceConfig:RegisterOptionsTable("EasyBid", EasyBid.Options)
    AceConfigDialog:AddToBlizOptions("EasyBid", "MonDKP Easy Bid")

    GuildRoster();

    EasyBidSettings.initialized = true

    EasyBid:Print("EASY BID INITIALIZED")
end

function EasyBid:OnEnable()
--    EasyBid:RegisterEvent("CHAT_MSG_SAY", "OnMessage")
    EasyBid:RegisterEvent("CHAT_MSG_RAID", "OnMessage")
    EasyBid:RegisterEvent("CHAT_MSG_RAID_WARNING", "OnMessage")
    EasyBid:RegisterEvent("CHAT_MSG_WHISPER", "OnWhisperMessage")

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
    EasyBid:UnregisterEvent("CHAT_MSG_WHISPER")

    EasyBid:UnregisterChatCommand("ebid")

    --    EasyBid.StopGUI()
end

function EasyBid:ShowBiddingFrame()
    if (not EasyBid.var.gui.isVisible) then
        if (EasyBid.var.currentItem ~= nil) then
            EasyBid:StartGUI()
        else
            EasyBid:Print("----------------------------------------")
            EasyBid:Print("No bidding in progress")
            EasyBid:Print("----------------------------------------")
        end
    end
end

function EasyBid:HideBiddingFrame()
    if (EasyBid.var.gui.isVisible) then
        EasyBid:StopGUI(EasyBid.var.gui.frame)
    end
end

function EasyBid:GetClass(player)
    local cls = nil;
    local search = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, player)
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

function EasyBid:GetClassColor(player)
    local cls = EasyBid:GetClass(player);

    if (cls ~= nil and classes[cls] ~= nil) then
        return classes[cls].color.r, classes[cls].color.g, classes[cls].color.b
    end

    return 1, 1, 1
end

function EasyBid:GetPlayerDkp(player)
    local name = player
    if (name == nil) then
        name = UnitName("player")
    end

    if (name ~= nil) then
        local search = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, name)
        if (search) then
            return MonDKP_EasyBid_DKPTable[search[1][1]].dkp
        end
    end
    return MAXIMUM
end

function EasyBid:CanEquip(cls, itemType, itemSubtype)
    if (cls ~= nil and classes[cls] ~= nil) then
        local classTypeArr;
        if (itemType == armorItemType) then
            classTypeArr = classes[cls].armor
        elseif(itemType == weaponItemType) then
            classTypeArr = classes[cls].weapons
        else
            return true
        end

        for _,v in pairs(classTypeArr) do
            if v == itemSubtype then
                return true
            end
        end

        return false
    else
        return true
    end
end

function EasyBid:FillCurrentItemAndPossiblyShow()
    local _,itemLink,itemRarity,_,_,_,_,_,_,itemIcon,_,itemClassId,itemSubClassId = GetItemInfo(EasyBid.var.currentItem)

    if (EasyBid.var.gui.currentItem ~= nil) then
        local tooltip = GameTooltip;

        EasyBid.var.gui.currentItem:SetText(itemLink)
        EasyBid.var.gui.currentItem:SetImage(itemIcon)
        EasyBid.var.gui.currentItem:SetImageSize(25, 25)
        EasyBid.var.gui.currentItem:SetCallback("OnEnter", function(widget)
            if (tooltip ~= nil) then
                tooltip:ClearLines();
                tooltip:SetOwner(EasyBid.var.gui.currentItem.frame, "ANCHOR_NONE")
                tooltip:ClearAllPoints()
                -- tooltipu topleva jde na currentItem bottomlevou
                tooltip:SetPoint("TOPRIGHT", EasyBid.var.gui.currentItem.frame, "TOPLEFT")
                tooltip:SetHyperlink(itemLink);
                tooltip:Show();
            end
        end);
        EasyBid.var.gui.currentItem:SetCallback("OnLeave", function()
            if (tooltip ~= nil) then
                tooltip:Hide()
            end
        end);

        if(itemClassId ~= nil and itemSubClassId ~= nil) then
            local shouldShow = true
            local itemSubTypeName = nil
            if (itemClassId == armorItemType) then
                itemSubTypeName = armorTypes[itemSubClassId]
                shouldShow = not EasyBidSettings.armor[itemSubClassId]
            elseif(itemClassId == weaponItemType) then
                itemSubTypeName = weaponTypes[itemSubClassId]
                shouldShow = not EasyBidSettings.weapons[itemSubClassId]
            end

            if (not shouldShow) then
                EasyBid:Print("----------------------------------------")
                EasyBid:Print("Bidding frame not shown due to settings (" .. itemSubTypeName .. ")")
                EasyBid:Print("----------------------------------------")
            end

            return shouldShow
        end
    end

    return false
end

function EasyBid:GetGuildRank(player)
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


function EasyBid:FillBidders()
    EasyBid.var.maxBidder = nil;
    EasyBid.var.maxBidValue = 0

    if (EasyBid.var.gui.scroll ~= nil) then
        EasyBid.var.gui.scroll:ReleaseChildren();
    end

    local minMaxValue = MAXIMUM;
    local maxMaxValue = 0;
    for index, value in ipairs(EasyBid.var.bidders) do
        local playerDkp = EasyBid:GetPlayerDkp(value.player);
        if (playerDkp ~= MAXIMUM) then
            maxMaxValue = math.max(maxMaxValue, playerDkp)
            minMaxValue = math.min(minMaxValue, playerDkp)
        end
    end

    local playersAlreadyShown = {};
    local biddersNumber = 0;

    for index, value in ipairs(EasyBid.var.bidders) do
        if (EasyBid.var.gui.scroll ~= nil) then
            local bidLabel = AceGUI:Create("Label")
            bidLabel:SetWidth(45)
            bidLabel:SetText(value.bid .. "   ")
            bidLabel.label:SetJustifyH("RIGHT")

            local playerLabel = AceGUI:Create("InteractiveLabel")
            playerLabel:SetColor(EasyBid:GetClassColor(value.player))
            playerLabel:SetText(value.player)
            playerLabel:SetWidth(105)

            local playerDkp = EasyBid:GetPlayerDkp(value.player);
            local maxLabel = AceGUI:Create("Label")
            maxLabel:SetWidth(45)

            if (playersAlreadyShown[value.player]) then
                maxLabel:SetText("")
            else
                biddersNumber = biddersNumber + 1;
                if (playerDkp == MAXIMUM) then
                    maxLabel:SetText("(???)")
                    maxLabel:SetColor(EasyBid:HSVtoRGB(0, 1, 1))
                else
                    maxLabel:SetText("(" .. tostring(playerDkp) .. ")")
                    if (minMaxValue == maxMaxValue) then
                        maxLabel:SetColor(EasyBid:HSVtoRGB(120, 1, 1))
                    else
                        local dkpPercentage = (playerDkp - minMaxValue) / (maxMaxValue - minMaxValue);
                        maxLabel:SetColor(EasyBid:HSVtoRGB(120 * dkpPercentage, 1, 1))
                    end
                end
            end

            local groupHistory = AceGUI:Create("SimpleGroup")
            groupHistory:SetRelativeWidth(1)
            groupHistory:SetLayout("Flow")

            groupHistory:AddChild(bidLabel)
            groupHistory:AddChild(playerLabel)
            groupHistory:AddChild(maxLabel)

            playerLabel:ClearAllPoints()
            playerLabel:SetPoint("LEFT", bidLabel.frame, "RIGHT")

            maxLabel:ClearAllPoints()
            maxLabel:SetPoint("LEFT", playerLabel.frame, "RIGHT")

            local guildName, guildRankName, guildRankIndex = GetGuildInfo(value.player)
            if (guildName == nil) then
                local rank, rankIdx = EasyBid:GetGuildRank(value.player);
                if (rank ~= nil) then
                    guildName = GetGuildInfo("player")
                    guildRankName = rank
                    guildRankIndex = rankIdx
                end
            end


            local tooltip = GameTooltip;
            playerLabel:SetCallback("OnEnter", function(widget)
                if (tooltip ~= nil) then
                    tooltip:ClearLines();
                    tooltip:SetOwner(playerLabel.frame, "ANCHOR_NONE")
                    tooltip:ClearAllPoints()
                    tooltip:SetPoint("TOPLEFT", playerLabel.frame, "BOTTOMLEFT")
                    tooltip:AddLine(value.player, 1, 1, 1)
                    if (guildName ~= nil) then
                        tooltip:AddLine("<" .. guildName .. ">", 0.1, 0.8, 0.15, 0.5)
                        tooltip:AddLine(guildRankName .. " (" .. guildRankIndex .. ")")
                    end
                    tooltip:Show();
                end
            end);
            playerLabel:SetCallback("OnLeave", function()
                if (tooltip ~= nil) then
                    tooltip:Hide()
                end
            end);

            EasyBid.var.gui.scroll:AddChild(groupHistory)

            playersAlreadyShown[value.player] = true
        end

        if (value.bid > EasyBid.var.maxBidValue) then
            EasyBid.var.maxBidder = value
            EasyBid.var.maxBidValue = value.bid
        end
    end

    if (EasyBid.var.gui.scrollContainer ~= nil) then
        EasyBid.var.gui.scrollContainer:SetTitle("History (" .. tostring(biddersNumber) .. " bidders)")
    end

    if (EasyBid.var.gui.groupBidder ~= nil) then
        local highestBid = AceGUI:Create("Label")
        local Path, Size, Flags = highestBid.label:GetFont()
        highestBid.label:SetFont(Path, 28, Flags);
        highestBid:SetRelativeWidth(0.3)

        local highestBidder = AceGUI:Create("InteractiveLabel")
        Path, Size, Flags = highestBidder.label:GetFont()
        highestBidder.label:SetFont(Path, 28, Flags);
        highestBidder:SetRelativeWidth(0.7)

        local cancelBid = nil

        if (EasyBid.var.maxBidder ~= nil and EasyBid.var.maxBidder.bid > 0 and EasyBid.var.maxBidder.player ~= nil) then
            highestBid:SetText(EasyBid.var.maxBidder.bid)

            if (EasyBid.var.maxBidder.player == UnitName("player")) then
                cancelBid = AceGUI:Create("Button")
                cancelBid:SetWidth(40)
                cancelBid:SetText("X")
                cancelBid:SetCallback("OnClick", function()
                    if (EasyBid.var.bidOfficer ~= nil) then
                        SendChatMessage("!bid cancel", "WHISPER", nil, EasyBid.var.bidOfficer);
                    else
                        SendChatMessage("!bid cancel", "RAID");
                    end
                end)

                local tooltip = GameTooltip;
                cancelBid:SetCallback("OnEnter", function(widget)
                    if (tooltip ~= nil) then
                        tooltip:ClearLines();
                        tooltip:SetOwner(cancelBid.frame, "ANCHOR_NONE")
                        tooltip:ClearAllPoints()
                        tooltip:SetPoint("BOTTOMLEFT", cancelBid.frame, "TOPLEFT")
                        tooltip:SetText("Cancel bid");
                        tooltip:Show();
                    end
                end);
                cancelBid:SetCallback("OnLeave", function()
                    if (tooltip ~= nil) then
                        tooltip:Hide()
                    end
                end);


                highestBidder:SetRelativeWidth(0.5)

                highestBidder:SetText(" - YOU -")
                highestBidder:SetColor(1, 1, 1)
            else
                highestBidder:SetText(EasyBid.var.maxBidder.player)
                highestBidder:SetColor(EasyBid:GetClassColor(EasyBid.var.maxBidder.player))

                local guildName, guildRankName, guildRankIndex = GetGuildInfo(EasyBid.var.maxBidder.player)
                if (guildName == nil) then
                    local rank, rankIdx = EasyBid:GetGuildRank(EasyBid.var.maxBidder.player);
                    if (rank ~= nil) then
                        guildName = GetGuildInfo("player")
                        guildRankName = rank
                        guildRankIndex = rankIdx
                    end
                end

                local tooltip = GameTooltip;
                highestBidder:SetCallback("OnEnter", function(widget)
                    if (tooltip ~= nil) then
                        tooltip:ClearLines();
                        tooltip:SetOwner(highestBidder.frame, "ANCHOR_NONE")
                        tooltip:ClearAllPoints()
                        tooltip:SetPoint("TOPLEFT", highestBidder.frame, "BOTTOMLEFT")
                        tooltip:AddLine(EasyBid.var.maxBidder.player, 1, 1, 1)
                        if (guildName ~= nil) then
                            tooltip:AddLine("<" .. guildName .. ">", 0.1, 0.8, 0.15, 0.5)
                            tooltip:AddLine(guildRankName .. " (" .. guildRankIndex .. ")")
                        end
                        tooltip:Show();
                    end
                end);
                highestBidder:SetCallback("OnLeave", function()
                    if (tooltip ~= nil) then
                        tooltip:Hide()
                    end
                end);
            end

            local maxBidderDkp = EasyBid:GetPlayerDkp(EasyBid.var.maxBidder.player);
            local isHisMax = maxBidderDkp ~= MAXIMUM and maxBidderDkp == EasyBid.var.maxBidder.bid;

            if (isHisMax) then
                EasyBid.var.gui.isBidMax:SetText(" (MAXIMUM)")
            else
                EasyBid.var.gui.isBidMax:SetText("")
            end
        else
            highestBid:SetText("0")
            highestBidder:SetText("- NO BIDDER -")
            highestBidder:SetColor(0.7, 0.7, 0.7)
            EasyBid.var.gui.isBidMax:SetText("")
        end

        EasyBid.var.gui.groupBidder:ReleaseChildren();

        EasyBid.var.gui.groupBidder:AddChild(highestBid)
        if (cancelBid ~= nil) then
            EasyBid.var.gui.groupBidder:AddChild(cancelBid)
            cancelBid:ClearAllPoints()
            cancelBid:SetPoint("LEFT", highestBid.frame, "RIGHT")
        end
        EasyBid.var.gui.groupBidder:AddChild(highestBidder)

        highestBidder:ClearAllPoints()
        if (cancelBid ~= nil) then
            highestBidder:SetPoint("LEFT", cancelBid.frame, "RIGHT", 30, 0)
        else
            highestBidder:SetPoint("LEFT", highestBid.frame, "RIGHT")
        end
    end

    EasyBid:SetNextMinimum()
end


function EasyBid:OnItemInfoReceived(self, itemId, success)
    if (success == true and EasyBid.var.currentItem == tostring(itemId)) then
        EasyBid:ShowBiddingFrame();
    end
end

local Bids_Submitted = {};

function EasyBid:OnWhisperMessage(self, message, author)
    if (
        EasyBid.var.bidOfficer ~= nil and (
            EasyBid.var.bidOfficer == author or
            (EasyBid.var.bidOfficer .. "-" .. GetRealmName()) == author
        )
    ) then
        EasyBid.var.lastOfficerWhisper = message;
        if(EasyBid.var.gui.whisp ~= nil) then
            EasyBid.var.gui.whisp:SetText(EasyBid.var.lastOfficerWhisper)
        end
    end
end

function EasyBid:OnMessage(self, message, author)
    --if(string.find(message, "ebid") ~= nil) then
    --    local t = {}
    --    for i in string.gmatch(message, "[^%s]+") do
    --        t[#t + 1] = i
    --    end
    --
    --    if (t[2] == "start") then
    --        local itemId = t[3];
    --        local minBid = t[4];
    --        EasyBid:SendData("MonDKPCommand", "BidInfo,"..itemId..","..minBid..","..",")
    --        Bids_Submitted = {}
    --    elseif(t[2] == "bid") then
    --        local player = t[3];
    --        local dkp = tonumber(t[4]);
    --        table.insert(Bids_Submitted, {player=player, bid=dkp})
    --        EasyBid:SendData("MonDKPBidShare", Bids_Submitted)
    --    elseif(t[2] == "stop") then
    --        Bids_Submitted = {}
    --        EasyBid:SendData("MonDKPCommand", "StopBidTimer")
    --    end
    --else
    if(
        string.find(message, "Bidding Closed!") ~= nil and
        (
            EasyBid.var.bidOfficer ~= nil and (
                EasyBid.var.bidOfficer == author or
                (EasyBid.var.bidOfficer .. "-" .. GetRealmName()) == author
            )
        )
    ) then
        EasyBid:HideBiddingFrame()

        EasyBid.var.minimumBid = nil;
        EasyBid.var.myBid = nil;
        EasyBid.var.bidOfficer = nil;
        EasyBid.var.currentItem = nil;
        EasyBid.var.bidders = {};
        EasyBid.var.nextMinimum = nil;
        EasyBid.var.lastOfficerWhisper = nil;
    end
end

function EasyBid:normalizeBid(value)
    if (value ~= nil) then
        local parsed = tonumber(value)
        if (parsed ~= nil) then
            parsed = parsed - ((parsed - EasyBid.var.minimumBid) % EasyBidSettings.bidStep)
            return parsed
        end
    end

    return nil
end

function EasyBid:setMyBid(value, change, byNewBidder)
    if (not EasyBid.var.isEditing) then
        local newValue;
        if (value ~= nil) then
            newValue = value
        elseif (change ~= nil) then
            newValue = EasyBid.var.myBid + change
        end

        if (byNewBidder and newValue < EasyBid.var.myBid) then
            return
        end

        EasyBid.var.myBid = newValue;

        if (not byNewBidder) then
            local max = EasyBid:GetActualMax();
            EasyBid.var.myBid = EasyBid:normalizeBid(EasyBid.var.myBid)

            EasyBid.var.myBid = math.max(EasyBid.var.myBid, EasyBid.var.nextMinimum);
            EasyBid.var.myBid = math.min(EasyBid.var.myBid, EasyBid:normalizeBid(max));
        end

        EasyBid.var.gui.editBox:SetText(tostring(EasyBid.var.myBid))
        EasyBid.var.gui.slider:SetValue(EasyBid.var.myBid)

        EasyBid.var.gui.btnBid:SetDisabled(EasyBid.var.myBid < EasyBid.var.nextMinimum)
    end
end

function EasyBid:SetNextMinimum()
    local minimum = EasyBid.var.minimumBid
    local toSet;

    if (EasyBid.var.maxBidder ~= nil) then
        minimum = EasyBid:normalizeBid(EasyBid.var.maxBidder.bid + EasyBidSettings.bidStep);
        toSet = EasyBid.var.maxBidder.bid
    else
        toSet = minimum
    end

    EasyBid.var.nextMinimum = minimum

    if (EasyBid.var.myBid ~= nil and toSet ~= nil and EasyBid.var.gui.editBox ~= nil and EasyBid.var.myBid <= toSet) then
        EasyBid:setMyBid(toSet, null, true)
    end
end

function EasyBid:PositionFrame()
    if (EasyBid.var.gui.frame ~= nil) then
        EasyBid.var.gui.frame:ClearAllPoints()

        if (EasyBidSettings.position ~= nil) then
            EasyBid.var.gui.frame:SetPoint(
                EasyBidSettings.position.point,
                "UIParent",
                EasyBidSettings.position.relativePoint,
                EasyBidSettings.position.x,
                EasyBidSettings.position.y
            );
        else
            EasyBid.var.gui.frame:SetPoint("RIGHT", "UIParent", "RIGHT", 0, 0);
        end
    end
end

function EasyBid:GetActualMax()
    local max = EasyBid.var.myMax;
    if (max == nil or not EasyBidSettings.useMyMax) then
        max = MAXIMUM
    end
    return max;
end

function EasyBid:setMax()
    local max = EasyBid:GetActualMax()

    if (EasyBid.var.gui.slider ~= nil) then
        EasyBid.var.gui.slider:SetSliderValues(EasyBid.var.minimumBid, EasyBid:normalizeBid(max), EasyBidSettings.bidStep)
    end
    if(EasyBid.var.gui.btnSetHalf ~= nil) then
        EasyBid.var.gui.btnSetHalf:SetCallback("OnClick", function() EasyBid:setMyBid(max / 2, nil) end)
    end
    if(EasyBid.var.gui.btnSetMaximum ~= nil) then
        EasyBid.var.gui.btnSetMaximum:SetCallback("OnClick", function() EasyBid:setMyBid(max, nil) end)
    end

    EasyBid:setMyBid(EasyBid.var.myBid)
end

function EasyBid:StartGUI()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Monolith DKP Easy Bid")
    frame:SetWidth(600)
    frame:SetHeight(420)
    frame:SetLayout("Flow");
    frame:SetCallback("OnClose", function(widget) EasyBid:StopGUI(widget) end)
    frame:EnableResize(false);
    EasyBid:RawHookScript(frame.frame, "OnHide",
        function(f)
            local point, relativeTo, relativePoint, x, y = frame:GetPoint()
            EasyBidSettings.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y,
            };
            self.hooks[f].OnHide(f)
        end
    )
    frame.frame:SetFrameStrata("DIALOG")

    local scrollcontainer = AceGUI:Create("InlineGroup")
    scrollcontainer:SetTitle("History")
    scrollcontainer:SetWidth(240)
    scrollcontainer:SetHeight(325)
    scrollcontainer:SetLayout("Fill") -- important!

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollcontainer:AddChild(scroll)

    EasyBid.var.myMax = EasyBid:GetPlayerDkp(nil)

    local currentItem = AceGUI:Create("InteractiveLabel")
    currentItem:SetWidth(300)
    local Path, Size, Flags = currentItem.label:GetFont()
    currentItem.label:SetFont(Path, 20, Flags);

    local isBidMax = AceGUI:Create("Label")
    Path, Size, Flags = isBidMax.label:GetFont()
    isBidMax.label:SetFont(Path, 10, Flags);

    local editbox = AceGUI:Create("EditBox")
    editbox:SetText(tostring(EasyBid.var.minimumBid))

    editbox:SetWidth(100)
    Path, Size, Flags = editbox.editbox:GetFont()
    editbox.editbox:SetFont(Path, 20, Flags);

    editbox:SetCallback(
            "OnEnterPressed",
            function(widget, event, text)
                AceGUI:ClearFocus();
                if (text ~= nil and tonumber(text) ~= nil) then
                    EasyBid:setMyBid(text, nil)
                else
                    EasyBid:setMyBid(EasyBid.var.myBid, nil)
                end
            end
    )
    editbox.editbox:HookScript("OnEditFocusLost", function() EasyBid.var.isEditing = false end)
    editbox.editbox:HookScript("OnEditFocusGained", function() EasyBid.var.isEditing = true end)

    local btnBid = AceGUI:Create("Button")
    btnBid:SetText("BID")
    btnBid:SetWidth(200)
    btnBid:SetHeight(30)
    btnBid:SetCallback("OnClick", function()
        if (EasyBid.var.bidOfficer ~= nil) then
            SendChatMessage("!bid " .. tostring(EasyBid.var.myBid), "WHISPER", nil, EasyBid.var.bidOfficer);
        else
            SendChatMessage("!bid " .. tostring(EasyBid.var.myBid), "RAID");
        end
    end)

    local btnAdd10 = AceGUI:Create("Button")
    btnAdd10:SetText("+"..EasyBidSettings.bidStep)
    btnAdd10:SetWidth(100)
    btnAdd10:SetHeight(30)
    btnAdd10:SetCallback("OnClick", function() EasyBid:setMyBid(nil, EasyBidSettings.bidStep) end)

    local btnAdd50 = AceGUI:Create("Button")
    btnAdd50:SetText("+"..(5 * EasyBidSettings.bidStep))
    btnAdd50:SetWidth(100)
    btnAdd50:SetHeight(30)
    btnAdd50:SetCallback("OnClick", function() EasyBid:setMyBid(nil, 5 * EasyBidSettings.bidStep) end)

    local btnAdd100 = AceGUI:Create("Button")
    btnAdd100:SetText("+"..(10 * EasyBidSettings.bidStep))
    btnAdd100:SetWidth(100)
    btnAdd100:SetHeight(30)
    btnAdd100:SetCallback("OnClick", function() EasyBid:setMyBid(nil, 10 * EasyBidSettings.bidStep) end)

    local btnMinus10 = AceGUI:Create("Button")
    btnMinus10:SetText("-"..EasyBidSettings.bidStep)
    btnMinus10:SetWidth(100)
    btnMinus10:SetHeight(30)
    btnMinus10:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -EasyBidSettings.bidStep) end)

    local btnMinus50 = AceGUI:Create("Button")
    btnMinus50:SetText("-"..(5 * EasyBidSettings.bidStep))
    btnMinus50:SetWidth(100)
    btnMinus50:SetHeight(30)
    btnMinus50:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -5 * EasyBidSettings.bidStep) end)

    local btnMinus100 = AceGUI:Create("Button")
    btnMinus100:SetText("-"..(10 * EasyBidSettings.bidStep))
    btnMinus100:SetWidth(100)
    btnMinus100:SetHeight(30)
    btnMinus100:SetCallback("OnClick", function() EasyBid:setMyBid(nil, -10 * EasyBidSettings.bidStep) end)

    local minBidSlider = AceGUI:Create("Slider")
    minBidSlider:SetRelativeWidth(1)
    minBidSlider:SetValue(EasyBid.var.myBid)
    minBidSlider:SetLabel("")
    minBidSlider:SetCallback("OnValueChanged", function(widget, name, value) EasyBid:setMyBid(value, nil) end)

    local btnSetMinimum = AceGUI:Create("Button")
    btnSetMinimum:SetText("MIN")
    btnSetMinimum:SetWidth(100)
    btnSetMinimum:SetHeight(30)
    btnSetMinimum:SetCallback("OnClick", function() EasyBid:setMyBid(EasyBid.var.minimumBid, nil) end)

    local btnSetHalf = AceGUI:Create("Button")
    btnSetHalf:SetText("HALF")
    btnSetHalf:SetWidth(100)
    btnSetHalf:SetHeight(30)

    local btnSetMaximum = AceGUI:Create("Button")
    btnSetMaximum:SetText("MAX")
    btnSetMaximum:SetWidth(100)
    btnSetMaximum:SetHeight(30)

    local whisp = AceGUI:Create("Label");
    whisp:SetRelativeWidth(1)
    Path, Size, Flags = whisp.label:GetFont()
    whisp.label:SetFont(Path, 13, Flags);
    whisp:SetColor(0.4, 0.96, 0.26)

    if(EasyBid.var.lastOfficerWhisper ~= nil) then
        whisp:SetText(EasyBid.var.lastOfficerWhisper)
    else
        whisp:SetText("")
    end

    local checkMax = AceGUI:Create("CheckBox")
    checkMax:SetValue(EasyBidSettings.useMyMax)
    checkMax:SetLabel("Use my MAX")
    checkMax:SetCallback("OnValueChanged", function(widget, name, value) EasyBidSettings.useMyMax = value; EasyBid:setMax(); end)

    local tooltip = GameTooltip;
    checkMax:SetCallback("OnEnter", function(widget)
        if (tooltip ~= nil) then
            tooltip:ClearLines();
            tooltip:SetOwner(checkMax.frame, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            tooltip:SetPoint("TOPLEFT", checkMax.frame, "BOTTOMLEFT")
            tooltip:SetText("Value of your DKP maximum is fetched from the DKP table. You might need to disable this due to data inconsistency.");
            tooltip:Show();
        end
    end);
    checkMax:SetCallback("OnLeave", function()
        if (tooltip ~= nil) then
            tooltip:Hide()
        end
    end);

    local groupBidder = AceGUI:Create("SimpleGroup")
    groupBidder:SetRelativeWidth(1)
    groupBidder:SetLayout("Flow")

    local groupBid = AceGUI:Create("SimpleGroup")
    groupBid:SetRelativeWidth(1)
    groupBid:SetLayout("Flow")

    groupBid:AddChild(editbox)
    groupBid:AddChild(btnBid)

    local groupModify = AceGUI:Create("SimpleGroup")
    groupModify:SetRelativeWidth(1)
    groupModify:SetLayout("Flow")

    groupModify:AddChild(btnAdd10)
    groupModify:AddChild(btnAdd50)
    groupModify:AddChild(btnAdd100)
    groupModify:AddChild(btnMinus10)
    groupModify:AddChild(btnMinus50)
    groupModify:AddChild(btnMinus100)

    local groupSet = AceGUI:Create("SimpleGroup")
    groupSet:SetRelativeWidth(1)
    groupSet:SetLayout("Flow")

    groupSet:AddChild(btnSetMinimum)
    groupSet:AddChild(btnSetHalf)
    groupSet:AddChild(btnSetMaximum)

    local group = AceGUI:Create("SimpleGroup")
    group:SetWidth(300)
    group:SetHeight(380)
    group:SetLayout("List")

    frame:AddChild(scrollcontainer)
    frame:AddChild(group)
    frame:AddChild(checkMax)

    group:AddChild(currentItem)
    group:AddChild(groupBidder)
    group:AddChild(isBidMax)
    group:AddChild(groupBid)
    group:AddChild(groupModify)
    group:AddChild(minBidSlider)
    group:AddChild(groupSet)
    group:AddChild(whisp)

    EasyBid.var.gui.frame = frame
    EasyBid.var.gui.editBox = editbox
    EasyBid.var.gui.slider = minBidSlider
    EasyBid.var.gui.currentItem = currentItem
    EasyBid.var.gui.scroll = scroll;
    EasyBid.var.gui.groupBidder = groupBidder;
    EasyBid.var.gui.btnSetHalf = btnSetHalf
    EasyBid.var.gui.btnSetMaximum = btnSetMaximum
    EasyBid.var.gui.scrollContainer = scrollcontainer;
    EasyBid.var.gui.whisp = whisp;
    EasyBid.var.gui.btnBid = btnBid;
    EasyBid.var.gui.isBidMax = isBidMax;

    EasyBid:setMax();

    EasyBid:FillBidders();
    local shouldShow = EasyBid:FillCurrentItemAndPossiblyShow();

    EasyBid:PositionFrame()

    scrollcontainer:ClearAllPoints()
    scrollcontainer:SetPoint("TOPRIGHT", frame.frame, "TOPRIGHT", -20, -30)

    group:ClearAllPoints()
    group:SetPoint("TOPLEFT", frame.frame, "TOPLEFT", 20, -30)

    currentItem:ClearAllPoints()
    currentItem:SetPoint("TOPLEFT", group.frame, "TOPLEFT", 0, 0);

    groupBidder:ClearAllPoints()
    groupBidder:SetPoint("TOPLEFT", currentItem.frame, "BOTTOMLEFT", 0, -15);

    isBidMax:ClearAllPoints()
    isBidMax:SetPoint("TOPLEFT", groupBidder.frame, "BOTTOMLEFT", 0, -5);

    groupBid:ClearAllPoints()
    groupBid:SetPoint("TOPLEFT", isBidMax.frame, "BOTTOMLEFT", 0, -15);

    groupModify:ClearAllPoints()
    groupModify:SetPoint("TOPLEFT", groupBid.frame, "BOTTOMLEFT", 0, -5);

    whisp:ClearAllPoints()
    whisp:SetPoint("TOPLEFT", groupSet.frame, "BOTTOMLEFT", 0, -15);

    checkMax:ClearAllPoints()
    checkMax:SetPoint("BOTTOMLEFT", frame.frame, "BOTTOMLEFT", 20, 40)


    if (shouldShow) then
        EasyBid.var.gui.frame:Show();
        EasyBid.var.gui.isVisible = true
    else
        frame:Hide()
    end

end

function EasyBid:StopGUI(widget)
    if (widget ~= nil) then
        AceGUI:Release(widget)
        EasyBid:Unhook(widget.frame, "OnHide")
        EasyBid.var.gui = {
            isVisible = false,
            frame = nil,
            editBox = nil,
            slider = nil,
            currentItem = nil,
            groupBidder = nil,
            scrollContainer = nil,
            whisp = nil,
            btnBid = nil,
            scroll = nil,
            btnSetHalf = nil,
            btnSetMaximum = nil,
            isBidMax = nil,
        };
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
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: MonDKP_EasyBid_DKPTable, "Roeshambo", "player" would only search for Roeshambo in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, MonDKP_EasyBid_DKPTable[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be MonDKP_EasyBid_DKPTable[search[1][1]][search[1][2]][search[1][3]].  MonDKP_EasyBid_DKPTable[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
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

function MonDKP_Profile_Create(player, dkp, gained, spent)
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
			table.insert(MonDKP_EasyBid_DKPTable, { player=player, lifetime_spent=spent, lifetime_gained=gained, class=class, dkp=dkp, rank=10, spec="No Spec Reported", role="No Role Detected", rankName="None", previous_dkp=0, })

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
				if not EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, tempName, "player") then
					tinsert(MonDKP_EasyBid_DKPTable, { player=player, class=tempClass, dkp=dkp, previous_dkp=0, lifetime_gained=gained, lifetime_spent=spent, rank=10, rankName="None", spec="No Spec Reported", role="No Role Detected", })
					created = true
					break
				end
			end
		end
	end

	if not created then
		tinsert(MonDKP_EasyBid_DKPTable, { player=player, class=class, dkp=dkp, previous_dkp=0, lifetime_gained=gained, lifetime_spent=spent, rank=10, rankName="None", spec="No Spec Reported", role="No Role Detected", })
	end

	return created
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
    if prefix then
        if EasyBid:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
            if (prefix == "MonDKPCommand") then
                local command, arg1, arg2, arg3, arg4 = strsplit(",", message);
                if sender ~= UnitName("player") then
                    if command == "StopBidTimer" then
                        EasyBid:HideBiddingFrame()

                        EasyBid.var.minimumBid = nil;
                        EasyBid.var.myBid = nil;
                        EasyBid.var.bidOfficer = nil;
                        EasyBid.var.currentItem = nil;
                        EasyBid.var.bidders = {};
                        EasyBid.var.nextMinimum = nil;
                        EasyBid.var.lastOfficerWhisper = nil;
                    elseif command == "BidInfo" then
                        EasyBid.var.bidders = {};
                        EasyBid.var.lastOfficerWhisper = nil;
                        EasyBid.var.currentItem = arg1
                        EasyBid.var.minimumBid = tonumber(arg2) or EasyBidSettings.bidStep
                        EasyBid.var.bidOfficer = sender
                        EasyBid.var.myBid = EasyBid.var.minimumBid
                        EasyBid.var.nextMinimum = EasyBid.var.minimumBid

                        EasyBid:HideBiddingFrame()
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

                            MonDKP_EasyBid_DKPTable = deserialized.DKPTable
                            return
                        elseif prefix == "MonDKPBidShare" then
                            local bidders = deserialized
                            table.sort(bidders, function (k1, k2) return k1.bid > k2.bid end)
                            EasyBid.var.bidders = bidders

                            if (EasyBid.var.gui.isVisible) then
                                EasyBid:FillBidders()
                            end

                            return
                        elseif prefix == "MonDKPLootDist" then
                            local search = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, deserialized.player, "player")
                            if search then
                                local DKPTable = MonDKP_EasyBid_DKPTable[search[1][1]]
                                DKPTable.dkp = DKPTable.dkp + deserialized.cost
                                DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
                            else
                                MonDKP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);
                            end
                        elseif prefix == "MonDKPDKPDist" then
                            local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                            local dkp = deserialized.dkp

                            for i=1, #players do
                                local search = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                if search then
                                    MonDKP_EasyBid_DKPTable[search[1][1]].dkp = MonDKP_EasyBid_DKPTable[search[1][1]].dkp + tonumber(dkp)
                                    if tonumber(dkp) > 0 then
                                        MonDKP_EasyBid_DKPTable[search[1][1]].lifetime_gained = MonDKP_EasyBid_DKPTable[search[1][1]].lifetime_gained + tonumber(dkp)
                                    end
                                else
                                    MonDKP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                end
                            end
                        elseif prefix == "MonDKPDecay" then
                            local players = {strsplit(",", strsub(deserialized.players, 1, -2))}
                            local dkp = {strsplit(",", deserialized.dkp)}

                            for i=1, #players do
                                local search = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                if search then
                                    MonDKP_EasyBid_DKPTable[search[1][1]].dkp = MonDKP_EasyBid_DKPTable[search[1][1]].dkp + tonumber(dkp[i])
                                else
                                    MonDKP_Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                end
                            end
                        elseif prefix == "MonDKPDelLoot" then
                            local search = EasyBid:Table_Search(MonDKP_Loot, deserialized.deletes, "index")

                            if search then
                                MonDKP_Loot[search[1][1]].deletedby = deserialized.index
                            end

                            local search_player = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, deserialized.player, "player")

                            if search_player then
                                MonDKP_EasyBid_DKPTable[search_player[1][1]].dkp = MonDKP_EasyBid_DKPTable[search_player[1][1]].dkp + deserialized.cost                  -- refund previous looter
                                MonDKP_EasyBid_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_EasyBid_DKPTable[search_player[1][1]].lifetime_spent + deserialized.cost       -- remove from lifetime_spent
                            else
                                MonDKP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
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
                                    local search2 = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                    if search2 then
                                        MonDKP_EasyBid_DKPTable[search2[1][1]].dkp = MonDKP_EasyBid_DKPTable[search2[1][1]].dkp + tonumber(dkp[i])
                                    else
                                        MonDKP_Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                    end
                                else
                                    local search2 = EasyBid:Table_Search(MonDKP_EasyBid_DKPTable, players[i], "player")

                                    if search2 then
                                        MonDKP_EasyBid_DKPTable[search2[1][1]].dkp = MonDKP_EasyBid_DKPTable[search2[1][1]].dkp + tonumber(dkp)

                                        if tonumber(dkp) < 0 then
                                            MonDKP_EasyBid_DKPTable[search2[1][1]].lifetime_gained = MonDKP_EasyBid_DKPTable[search2[1][1]].lifetime_gained + tonumber(dkp)
                                        end
                                    else
                                        local gained;
                                        if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end
                                        MonDKP_Profile_Create(players[i], tonumber(dkp), gained);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
                                    end
                                end
                            end
                        elseif prefix == "MonDKPMerge" then
                            -- TODO mozna pridat MonDKP_DKPHistory, loot a archive
                            for i=1, #MonDKP_EasyBid_DKPTable do
                                if MonDKP_EasyBid_DKPTable[i].class == "NONE" then
                                    local search = EasyBid:Table_Search(deserialized.Profiles, MonDKP_EasyBid_DKPTable[i].player, "player")

                                    if search then
                                        MonDKP_EasyBid_DKPTable[i].class = deserialized.Profiles[search[1][1]].class
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

function EasyBid:HSVtoRGB(h, s, v)
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
