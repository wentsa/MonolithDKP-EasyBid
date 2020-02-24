MonDKPBidHook = LibStub("AceAddon-3.0"):NewAddon("MonDKPBidHook", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
MonDKPBidHook.var = {
    bidStartMessage = "Taking bids on",
    bidEndMessage = "Bidding Closed!",
    bidMessage = '!bid ',
    bidCurrentItem = nil,
    bidStart = 1,
    bidResetDelay = 20,
    bidMinimumIncrease = 2,
    gui = {
        frame = nil,
        btnBid = bil
    },
    bidItems = {}

}

AceGUI = LibStub("AceGUI-3.0")

function MonDKPBidHook:OnEnable()
    MonDKPBidHook:RegisterEvent("CHAT_MSG_RAID", "OnRaidMessage")
    MonDKPBidHook:RegisterEvent("CHAT_MSG_RAID_WARNING", "OnRaidMessage")
   
    --MonDKPBidHook:RegisterEvent("CHAT_MSG_WHISPER", "OnRaidMessage")
    --MonDKPBidHook:RegisterEvent("CHAT_MSG_GUILD", "OnRaidMessage")
    MonDKPBidHook.StartGUI()
end

function MonDKPBidHook:OnInitialize() 
end

function MonDKPBidHook:GetItemFromMessage(message)
    local itemLink = string.match(message,"|%x+|Hitem:.-|h.-|h|r")
    if (itemLink == nil) then
        return nil, nil
    end
    itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
    return itemName, itemLink
end

function MonDKPBidHook:OnRaidMessage(self, message, author)

    if(string.find(message, MonDKPBidHook.var.bidStartMessage) ~= nil) then
        -- Bid message
        
        
        -- Check if item is in the message, if not its invalid. Quit
        local item, itemLink = MonDKPBidHook:GetItemFromMessage(message)
        if(item == nil) then
            return
        end
        
        -- Check if item is in the bid list
        if(MonDKPBidHook.var.bidItems[item] == nil) then
            -- Create record of the new item
            MonDKPBidHook.var.bidItems[item] = {
                bidCurrent = MonDKPBidHook.var.bidStart,
                bidCount = 0,
                bidHolder = nil,
                closed=false
            }
        end
        
        -- Retrieve item from bid list
        local bidItem = MonDKPBidHook.var.bidItems[item]
        
        -- Set this item to current
        MonDKPBidHook.var.bidCurrentItem = item
        
        -- Update GUI
        MonDKPBidHook.var.gui.frame:SetStatusText(itemLink)
        MonDKPBidHook.var.gui.frame:Show()
        MonDKPBidHook.var.gui.btnBid:SetDisabled(false)
        MonDKPBidHook:UpdateBidButton()
        
    elseif(string.find(message, MonDKPBidHook.var.bidMessage) ~= nil) then
        number = string.match(message, "%d+")
                
        local playerName = UnitName("player");
        local realmName = GetRealmName()
        local isSelf = (playerName .. "-" .. realmName == author)
 
        
        -- No number found in bid string
        if(number == nil) then
            return
        end
        
        -- Convert to number
        number = tonumber(number)
        
        -- Get item
        local bidItem = MonDKPBidHook.var.bidItems[MonDKPBidHook.var.bidCurrentItem]
        if(bidItem == nil) then
            -- There is no bidding ongoing for any item. return
            MonDKPBidHook:Print("No biditem")
            return 
        end
        
        -- Current bid is already by this author
        if(bidItem.bidHolder == author) then
        --    return -- Dont this we need this. because we disable frames. 
        end
        
        
        -- If its the first bid, we dont add minimum increase. else we do.
        if(bidItem.bidCount == 0 and isSelf) then
           minBid = bidItem.bidCurrent
        else
           minBid = bidItem.bidCurrent +  MonDKPBidHook.var.bidMinimumIncrease
        end
        
        
      
        -- Bid is not high enough
        if(number < minBid) then
                MonDKPBidHook:Print("number")
            return 
        end
           
        -- Update item data
        bidItem.bidCurrent = number
        bidItem.bidCount = bidItem.bidCount + 1
        bidItem.bidHolder = author

        if(playerName .. "-" .. realmName == author) then
            MonDKPBidHook.var.gui.btnBid:SetDisabled(true)
        else
            MonDKPBidHook.var.gui.btnBid:SetDisabled(false)
        end
        
        MonDKPBidHook:UpdateBidButton()
        
    elseif(string.find(message, MonDKPBidHook.var.bidEndMessage) ~= nil) then
        MonDKPBidHook.var.bidItems[MonDKPBidHook.var.bidCurrentItem].closed = true
        local function ClearClosed()
            MonDKPBidHook:ClearClosedItem(MonDKPBidHook.var.bidCurrentItem)
        end
        MonDKPBidHook:ScheduleTimer(ClearClosed, MonDKPBidHook.var.bidResetDelay)
        MonDKPBidHook.var.gui.frame:Hide()
    end

    
end

function MonDKPBidHook:ClearClosedItem(bidCurrentItem)
    if(MonDKPBidHook.var.bidItems[bidCurrentItem] ~= nil) then
        if(MonDKPBidHook.var.bidItems[bidCurrentItem].closed == true) then
             MonDKPBidHook.var.bidItems[bidCurrentItem] = nil
             MonDKPBidHook.var.bidCurrentItem = nil
        end
       
    end
    

end

function MonDKPBidHook:GetNextBidValue()
    local bidItem = MonDKPBidHook.var.bidItems[MonDKPBidHook.var.bidCurrentItem]
        if(bidItem ~= nil) then
            
            if(bidItem.bidCount == 0) then
                -- No bids yet, the bid should be without increase
                bidValue = bidItem.bidCurrent
            else
                -- There are previous bids. We increase with minimum increase.
                bidValue = bidItem.bidCurrent + MonDKPBidHook.var.bidMinimumIncrease
            end
        else
            bidValue = MonDKPBidHook.var.bidStart
        end
    return bidValue
end

function MonDKPBidHook:UpdateBidButton()
    MonDKPBidHook.var.gui.btnBid:SetText("Bid " .. MonDKPBidHook:GetNextBidValue())
end

function MonDKPBidHook:StartGUI()

    frame = AceGUI:Create("Frame")
    frame:SetTitle("Monolith DKP Bidframe")
    frame:SetWidth(300)
    frame:SetHeight(170)
    frame:SetPoint("CENTER", "UIParent", "CENTER", 500, 0);
    frame:Hide()
    --frame:Show()
    btnBid = AceGUI:Create("Button")
    btnBid:SetWidth(265)
    btnBid:SetHeight(50)
    btnBid:SetDisabled(true)
    btnBid:SetCallback("OnClick", function()
        -- write in raid here with bid value
      
        msg = "!bid " .. tostring(MonDKPBidHook:GetNextBidValue())
        --SendChatMessage(msg, "WHISPER", nil, "Driiper")
        SendChatMessage(msg, "RAID")
        -- MonDKPBidHook:OnRaidMessage(self, msg)
      
    end)
    
    
    --btnClose = AceGUI:Create("Button")
    --btnClose:SetText("Close")
    --btnClose:SetCallback("OnClick", function()
    --    frame:Hide()
    --end)
    
    
    minBidSlider = AceGUI:Create("Slider")
    minBidSlider:SetLabel("Bid Increase")
    minBidSlider:SetSliderValues(1, 20, 1)
    minBidSlider:SetValue(MonDKPBidHook.var.bidMinimumIncrease)
    minBidSlider:SetCallback("OnValueChanged", function(widget, name, value) 
        MonDKPBidHook.var.bidMinimumIncrease = value 
    end)
    
    
    --MonDKPBidHook.vars.gui.frame:Show()
    frame:AddChild(btnBid)
    frame:AddChild(minBidSlider)


    MonDKPBidHook.var.gui.btnBid = btnBid
    MonDKPBidHook.var.gui.frame = frame
    MonDKPBidHook:UpdateBidButton()

end











