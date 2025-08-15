-- WoW95 Bags Module
-- Windows 95 styled bag interface

local addonName, WoW95 = ...

local Bags = {}
WoW95.Bags = Bags

-- Bag settings
local BAG_WINDOW_WIDTH = 400
local BAG_WINDOW_HEIGHT = 300
local TITLE_BAR_HEIGHT = 18
local SLOT_SIZE = 32
local SLOT_SPACING = 2
local BORDER_SIZE = 4

-- Bag state
Bags.frame = nil
Bags.bagFrames = {}
Bags.bagSlotButtons = {}
Bags.isOpen = false
Bags.locked = false

function Bags:Init()
    WoW95:Debug("Initializing Bags module...")
    
    -- Hide default Blizzard bag frames
    self:HideBlizzardBags()
    
    -- Create our Windows 95 bag container
    self:CreateBagFrame()
    
    -- Hook bag events
    self:HookBagEvents()
    
    -- Hook bag button opening
    self:HookBagButton()
    
    -- Add debug command
    SLASH_WOW95BAGS1 = "/bagdebug"
    SlashCmdList["WOW95BAGS"] = function()
        self:DebugBagSlots()
    end
    
    WoW95:Debug("Bags module initialized successfully!")
end

function Bags:DebugBagSlots()
    print("=== WoW95 Bag Debug ===")
    
    -- Check all possible inventory slots
    print("--- Checking ALL Inventory Slots ---")
    for i = 1, 30 do
        local itemID = GetInventoryItemID("player", i)
        local texture = GetInventoryItemTexture("player", i)
        local link = GetInventoryItemLink("player", i)
        if itemID then
            local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
            print("Slot " .. i .. ": " .. (itemName or "Unknown") .. " (Type: " .. (itemType or "?") .. ", SubType: " .. (itemSubType or "?") .. ")")
            if link then print("  Link: " .. link) end
            if texture then print("  Texture: " .. texture) end
        end
    end
    
    -- Check container API
    print("--- Checking Container API ---")
    for bagSlot = 0, 5 do
        local bagName = C_Container.GetBagName(bagSlot)
        local numSlots = C_Container.GetContainerNumSlots(bagSlot)
        print("Bag " .. bagSlot .. ": " .. (bagName or "Empty") .. " (" .. (numSlots or 0) .. " slots)")
    end
    
    -- Check equipped items specifically for bags/containers
    print("--- Checking for Container Items ---")
    for i = 1, 30 do
        local itemID = GetInventoryItemID("player", i)
        if itemID then
            local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
            if itemType == "Container" or (itemSubType and (itemSubType:find("Bag") or itemSubType:find("Container"))) then
                local link = GetInventoryItemLink("player", i)
                local texture = GetInventoryItemTexture("player", i)
                print("CONTAINER FOUND - Slot " .. i .. ": " .. (itemName or "Unknown"))
                print("  SubType: " .. (itemSubType or "Unknown"))
                print("  Link: " .. (link or "None"))
                print("  Texture: " .. (texture or "None"))
            end
        end
    end
    
    -- Try to directly test bag operations
    print("--- Testing Bag Operations ---")
    for bagSlot = 1, 4 do
        local bagName = C_Container.GetBagName(bagSlot)
        if bagName and bagName ~= "" then
            print("Trying to find inventory slot for bag: " .. bagName)
            
            -- Test multiple possible inventory slot mappings
            local testSlots = {
                bagSlot + 19,  -- 20-23
                bagSlot + 18,  -- 19-22  
                bagSlot + 20,  -- 21-24
                bagSlot + 17,  -- 18-21
                bagSlot + 16,  -- 17-20
                bagSlot + 15,  -- 16-19
            }
            
            for _, testSlot in ipairs(testSlots) do
                local testItemID = GetInventoryItemID("player", testSlot)
                if testItemID then
                    local testName = GetItemInfo(testItemID)
                    if testName == bagName then
                        print("  MATCH FOUND: " .. bagName .. " is in inventory slot " .. testSlot)
                        local texture = GetInventoryItemTexture("player", testSlot)
                        print("  Texture: " .. (texture or "None"))
                    end
                end
            end
        end
    end
    
    print("=== End Debug ===")
end

function Bags:CreateBagFrame()
    -- Main bag container window
    self.frame = CreateFrame("Frame", "WoW95BagFrame", UIParent, "BackdropTemplate")
    self.frame:SetSize(BAG_WINDOW_WIDTH, BAG_WINDOW_HEIGHT)
    self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -100)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetMovable(true)
    self.frame:SetClampedToScreen(true)
    self.frame:Hide() -- Hidden by default
    
    -- Main frame backdrop
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.frame:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Windows 95 blue title bar
    local titleBar = CreateFrame("Frame", "WoW95BagTitleBar", self.frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(TITLE_BAR_HEIGHT)
    
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- Windows 95 blue
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText("Bags")
    titleText:SetTextColor(1, 1, 1, 1) -- White text on blue
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    titleText:SetShadowOffset(1, -1)
    titleText:SetShadowColor(0, 0, 0, 0.8)
    
    -- Make title bar draggable
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not self.locked then
            self.frame:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", "WoW95BagCloseButton", titleBar, "BackdropTemplate")
    closeButton:SetSize(16, 14)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    
    closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    closeButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    closeButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0, 0, 0, 1)
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    closeButton:SetScript("OnClick", function()
        self:CloseBags()
    end)
    
    closeButton:SetScript("OnEnter", function()
        closeButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(closeButton, "ANCHOR_TOP")
        GameTooltip:SetText("Close Bags")
        GameTooltip:Show()
    end)
    
    closeButton:SetScript("OnLeave", function()
        closeButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Lock button
    local lockButton = CreateFrame("Button", "WoW95BagLockButton", titleBar, "BackdropTemplate")
    lockButton:SetSize(16, 14)
    lockButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    
    lockButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    lockButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local lockText = lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockText:SetPoint("CENTER")
    lockText:SetText("🔓") -- Unlocked by default
    lockText:SetTextColor(0, 0, 0, 1)
    lockText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    
    lockButton:SetScript("OnClick", function()
        self:ToggleLock()
    end)
    
    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(lockButton, "ANCHOR_TOP")
        GameTooltip:SetText(self.locked and "Unlock Bags" or "Lock Bags")
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Create bag slots area (top section)
    local bagSlotsArea = CreateFrame("Frame", "WoW95BagSlotsArea", self.frame)
    bagSlotsArea:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", BORDER_SIZE, -BORDER_SIZE)
    bagSlotsArea:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -BORDER_SIZE, -BORDER_SIZE)
    bagSlotsArea:SetHeight(SLOT_SIZE + BORDER_SIZE * 2)
    
    -- Content area for item slots (below bag slots)
    local contentArea = CreateFrame("Frame", "WoW95BagContent", self.frame)
    contentArea:SetPoint("TOPLEFT", bagSlotsArea, "BOTTOMLEFT", 0, -BORDER_SIZE)
    contentArea:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -BORDER_SIZE, 30) -- Leave space for currency
    
    -- Currency area (bottom section)
    local currencyArea = CreateFrame("Frame", "WoW95CurrencyArea", self.frame)
    currencyArea:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", BORDER_SIZE, BORDER_SIZE)
    currencyArea:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
    currencyArea:SetHeight(25)
    
    -- Store references
    self.frame.titleBar = titleBar
    self.frame.titleText = titleText
    self.frame.bagSlotsArea = bagSlotsArea
    self.frame.contentArea = contentArea
    self.frame.currencyArea = currencyArea
    self.frame.closeButton = closeButton
    self.frame.lockButton = lockButton
    self.frame.lockText = lockText
    
    -- Create bag slots, currency display, and item slots
    self:CreateBagSlotButtons()
    self:CreateCurrencyDisplay()
    self:CreateBagSlots()
end

function Bags:CreateBagSlotButtons()
    local bagSlotsArea = self.frame.bagSlotsArea
    self.bagSlotButtons = {}
    
    -- Create bag slot buttons (bags 1-4 + reagent bag slot 5)
    for bagSlot = 1, 5 do
        local bagButton = CreateFrame("Button", "WoW95BagSlot" .. bagSlot, bagSlotsArea, "BackdropTemplate")
        bagButton:SetSize(SLOT_SIZE, SLOT_SIZE)
        bagButton:SetPoint("LEFT", bagSlotsArea, "LEFT", (bagSlot - 1) * (SLOT_SIZE + SLOT_SPACING), 0)
        
        -- Slot backdrop
        bagButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        bagButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        bagButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        
        -- Bag icon
        local bagIcon = bagButton:CreateTexture(nil, "ARTWORK")
        bagIcon:SetPoint("TOPLEFT", bagButton, "TOPLEFT", 3, -3)
        bagIcon:SetPoint("BOTTOMRIGHT", bagButton, "BOTTOMRIGHT", -3, 3)
        bagIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        -- Store references
        bagButton.bagSlot = bagSlot
        bagButton.bagIcon = bagIcon
        
        -- Click handling for bag slots
        bagButton:RegisterForClicks("AnyUp")
        bagButton:RegisterForDrag("LeftButton")
        
        bagButton:SetScript("OnClick", function(self, button, down)
            if InCombatLockdown() then return end
            
            if button == "RightButton" then
                -- Right-click to remove bag
                if bagButton.actualInvSlot then
                    PickupInventoryItem(bagButton.actualInvSlot)
                end
            else
                -- Left-click to use bag or handle cursor item
                local cursorType, cursorID = GetCursorInfo()
                if cursorType == "item" then
                    -- Player has an item on cursor, try to equip it
                    if bagButton.actualInvSlot then
                        PickupInventoryItem(bagButton.actualInvSlot)
                    end
                else
                    -- No item on cursor, use the bag if equipped (open/close individual bag)
                    if bagButton.actualInvSlot then
                        UseInventoryItem(bagButton.actualInvSlot)
                    end
                end
            end
        end)
        
        bagButton:SetScript("OnDragStart", function()
            if InCombatLockdown() then return end
            if bagButton.actualInvSlot then
                PickupInventoryItem(bagButton.actualInvSlot)
            end
        end)
        
        bagButton:SetScript("OnReceiveDrag", function()
            if InCombatLockdown() then return end
            if bagButton.actualInvSlot then
                PickupInventoryItem(bagButton.actualInvSlot)
            end
        end)
        
        -- Tooltip
        bagButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(bagButton, "ANCHOR_RIGHT")
            
            if bagButton.bagLink then
                -- Show the actual bag tooltip
                GameTooltip:SetHyperlink(bagButton.bagLink)
            elseif bagButton.bagName then
                -- Show bag name and info
                GameTooltip:SetText(bagButton.bagName)
                GameTooltip:AddLine("Left-click to open/close bag", 1, 1, 1)
                GameTooltip:AddLine("Right-click to remove bag", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Drag to move bag", 0.8, 0.8, 0.8)
            else
                -- Empty slot
                if bagSlot == 5 then
                    GameTooltip:SetText("Reagent Bag Slot")
                    GameTooltip:AddLine("Drag a reagent bag here", 1, 1, 1)
                else
                    GameTooltip:SetText("Bag Slot " .. bagSlot)
                    GameTooltip:AddLine("Drag a bag here to equip it", 1, 1, 1)
                end
            end
            
            GameTooltip:Show()
            bagButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        end)
        
        bagButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
            bagButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        end)
        
        self.bagSlotButtons[bagSlot] = bagButton
    end
end

function Bags:CreateCurrencyDisplay()
    local currencyArea = self.frame.currencyArea
    
    -- Gold display with better visibility
    local goldText = currencyArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldText:SetPoint("RIGHT", currencyArea, "RIGHT", -40, 0)
    goldText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    goldText:SetTextColor(1, 1, 1, 1) -- White text
    goldText:SetShadowOffset(1, -1)
    goldText:SetShadowColor(0, 0, 0, 1) -- Black shadow for readability
    
    -- Currency button (opens currency frame)
    local currencyButton = CreateFrame("Button", "WoW95CurrencyButton", currencyArea, "BackdropTemplate")
    currencyButton:SetSize(30, 20)
    currencyButton:SetPoint("RIGHT", currencyArea, "RIGHT", -5, 0)
    
    currencyButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    currencyButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    currencyButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local currencyIcon = currencyButton:CreateTexture(nil, "ARTWORK")
    currencyIcon:SetAllPoints(currencyButton)
    currencyIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    currencyIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    currencyButton:SetScript("OnClick", function()
        ToggleCharacter("TokenFrame")
    end)
    
    currencyButton:SetScript("OnEnter", function()
        currencyButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(currencyButton, "ANCHOR_TOP")
        GameTooltip:SetText("Currency")
        GameTooltip:AddLine("Click to open currency window", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    currencyButton:SetScript("OnLeave", function()
        currencyButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Store references
    self.frame.goldText = goldText
    self.frame.currencyButton = currencyButton
end

function Bags:UpdateBagSlots()
    for bagSlot = 1, 5 do
        local bagButton = self.bagSlotButtons[bagSlot]
        if bagButton then
            local bagIcon = bagButton.bagIcon
            local bagFound = false
            local bagTexture = nil
            local bagLink = nil
            local actualInvSlot = nil
            
            if bagSlot <= 4 then
                -- Get bag name from container API (this works)
                local bagName = C_Container.GetBagName(bagSlot)
                local numSlots = C_Container.GetContainerNumSlots(bagSlot)
                
                if bagName and bagName ~= "" and numSlots and numSlots > 0 then
                    bagFound = true
                    
                    -- Simple search through likely inventory slots only
                    local testSlots = {20, 21, 22, 23, 19, 24}
                    
                    for _, invSlot in ipairs(testSlots) do
                        local itemLink = GetInventoryItemLink("player", invSlot)
                        if itemLink then
                            local itemName = GetItemInfo(itemLink)
                            if itemName == bagName then
                                local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
                                bagTexture = texture
                                bagLink = itemLink
                                actualInvSlot = invSlot
                                break
                            end
                        end
                    end
                    
                    -- Simple fallback based on bag name only
                    if not bagTexture then
                        if bagName:lower():find("duskweave") then
                            bagTexture = "Interface\\Icons\\INV_Misc_Bag_10"
                        else
                            bagTexture = "Interface\\Icons\\INV_Misc_Bag_08"
                        end
                    end
                end
                
            else
                -- Bag slot 5 - simple reagent bag check
                for invSlot = 20, 25 do
                    local itemLink = GetInventoryItemLink("player", invSlot)
                    if itemLink then
                        local _, _, _, _, _, _, itemSubType, _, _, texture = GetItemInfo(itemLink)
                        if itemSubType and itemSubType:lower():find("reagent") then
                            bagFound = true
                            bagTexture = texture
                            bagLink = itemLink
                            actualInvSlot = invSlot
                            break
                        end
                    end
                end
            end
            
            -- Store references
            bagButton.actualInvSlot = actualInvSlot
            bagButton.bagLink = bagLink
            bagButton.bagName = bagFound and C_Container.GetBagName(bagSlot <= 4 and bagSlot or 0) or nil
            
            if bagFound and bagTexture then
                bagIcon:SetTexture(bagTexture)
                bagIcon:SetDesaturated(false)
                bagIcon:SetAlpha(1)
                bagIcon:Show()
            else
                if bagSlot == 5 then
                    bagIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_ReagentBag")
                else
                    bagIcon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                end
                bagIcon:SetDesaturated(true)
                bagIcon:SetAlpha(0.4)
                bagIcon:Show()
                bagButton.actualInvSlot = nil
                bagButton.bagLink = nil
                bagButton.bagName = nil
            end
        end
    end
end

function Bags:UpdateCurrency()
    if self.frame.goldText then
        local money = GetMoney()
        local goldAmount = math.floor(money / 10000)
        local silverAmount = math.floor((money % 10000) / 100)
        local copperAmount = money % 100
        
        local moneyString = ""
        if goldAmount > 0 then
            moneyString = goldAmount .. "g"
        end
        if silverAmount > 0 then
            if moneyString ~= "" then moneyString = moneyString .. " " end
            moneyString = moneyString .. silverAmount .. "s"
        end
        if copperAmount > 0 or moneyString == "" then
            if moneyString ~= "" then moneyString = moneyString .. " " end
            moneyString = moneyString .. copperAmount .. "c"
        end
        
        self.frame.goldText:SetText(moneyString)
    end
end

function Bags:CreateBagSlots()
    local contentArea = self.frame.contentArea
    local slotsPerRow = math.floor((contentArea:GetWidth() - BORDER_SIZE * 2) / (SLOT_SIZE + SLOT_SPACING))
    
    self.bagFrames = {}
    
    -- Process all bags (0-4: backpack + 4 bag slots)
    for bagID = 0, 4 do
        local bagSlots = C_Container.GetContainerNumSlots(bagID)
        
        if bagSlots and bagSlots > 0 then
            WoW95:Debug("Creating slots for bag " .. bagID .. " with " .. bagSlots .. " slots")
            
            for slotID = 1, bagSlots do
                local slotButton = self:CreateBagSlot(bagID, slotID, contentArea)
                
                if not self.bagFrames[bagID] then
                    self.bagFrames[bagID] = {}
                end
                self.bagFrames[bagID][slotID] = slotButton
            end
        end
    end
    
    -- Arrange all slots in a grid
    self:ArrangeSlots()
end

function Bags:CreateBagSlot(bagID, slotID, parent)
    local slotName = "WoW95BagSlot" .. bagID .. "_" .. slotID
    local slotButton = CreateFrame("Button", slotName, parent, "BackdropTemplate")
    slotButton:SetSize(SLOT_SIZE, SLOT_SIZE)
    
    -- Slot backdrop (Windows 95 button style)
    slotButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slotButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    slotButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Item icon
    local icon = slotButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", slotButton, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", slotButton, "BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Item count text
    local count = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    count:SetPoint("BOTTOMRIGHT", slotButton, "BOTTOMRIGHT", -2, 2)
    count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    count:SetTextColor(1, 1, 1, 1)
    
    -- Item level text (for equipment)
    local itemLevel = slotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLevel:SetPoint("TOPLEFT", slotButton, "TOPLEFT", 2, -2)
    itemLevel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    itemLevel:SetTextColor(1, 1, 0, 1) -- Yellow text
    
    -- Cooldown frame
    local cooldown = CreateFrame("Cooldown", slotName .. "Cooldown", slotButton, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetHideCountdownNumbers(false)
    
    -- Quality border (thin outline only) - using a different approach
    local qualityBorder = CreateFrame("Frame", nil, slotButton)
    qualityBorder:SetAllPoints(icon) -- Match the icon size, not the slot
    qualityBorder:SetFrameLevel(slotButton:GetFrameLevel() + 2)
    
    -- Create 4 thin lines for the border
    local borderTop = qualityBorder:CreateTexture(nil, "OVERLAY")
    borderTop:SetHeight(2)
    borderTop:SetPoint("TOPLEFT", qualityBorder, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", qualityBorder, "TOPRIGHT", 0, 0)
    
    local borderBottom = qualityBorder:CreateTexture(nil, "OVERLAY")
    borderBottom:SetHeight(2)
    borderBottom:SetPoint("BOTTOMLEFT", qualityBorder, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", qualityBorder, "BOTTOMRIGHT", 0, 0)
    
    local borderLeft = qualityBorder:CreateTexture(nil, "OVERLAY")
    borderLeft:SetWidth(2)
    borderLeft:SetPoint("TOPLEFT", qualityBorder, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", qualityBorder, "BOTTOMLEFT", 0, 0)
    
    local borderRight = qualityBorder:CreateTexture(nil, "OVERLAY")
    borderRight:SetWidth(2)
    borderRight:SetPoint("TOPRIGHT", qualityBorder, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", qualityBorder, "BOTTOMRIGHT", 0, 0)
    
    -- Store border elements
    qualityBorder.top = borderTop
    qualityBorder.bottom = borderBottom
    qualityBorder.left = borderLeft
    qualityBorder.right = borderRight
    qualityBorder:Hide()
    
    -- Store bag and slot info
    slotButton.bagID = bagID
    slotButton.slotID = slotID
    slotButton.icon = icon
    slotButton.count = count
    slotButton.itemLevel = itemLevel
    slotButton.cooldown = cooldown
    slotButton.qualityBorder = qualityBorder
    
    -- Click handling
    slotButton:RegisterForClicks("AnyUp")
    slotButton:RegisterForDrag("LeftButton")
    
    slotButton:SetScript("OnClick", function(self, button, down)
        if InCombatLockdown() then return end
        
        -- Check if player has an item on cursor first
        local cursorType, cursorInfo = GetCursorInfo()
        if cursorType == "item" then
            -- Player has an item on cursor - place it in this bag slot
            C_Container.PickupContainerItem(bagID, slotID)
        else
            -- No item on cursor - use the item in this slot
            C_Container.UseContainerItem(bagID, slotID)
        end
    end)
    
    slotButton:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        C_Container.PickupContainerItem(bagID, slotID)
    end)
    
    slotButton:SetScript("OnReceiveDrag", function()
        if InCombatLockdown() then return end
        C_Container.PickupContainerItem(bagID, slotID)
    end)
    
    -- Tooltip
    slotButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(slotButton, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(bagID, slotID)
        GameTooltip:Show()
        
        -- Highlight effect
        slotButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
    end)
    
    slotButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
        slotButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    end)
    
    -- Update the slot
    self:UpdateSlot(slotButton)
    
    return slotButton
end

function Bags:ArrangeSlots()
    local contentArea = self.frame.contentArea
    local availableWidth = contentArea:GetWidth() - (BORDER_SIZE * 2)
    local slotsPerRow = math.floor(availableWidth / (SLOT_SIZE + SLOT_SPACING))
    
    local currentRow = 0
    local currentCol = 0
    local totalSlots = 0
    
    -- Count total slots first
    for bagID = 0, 4 do
        if self.bagFrames[bagID] then
            for slotID, slotButton in pairs(self.bagFrames[bagID]) do
                totalSlots = totalSlots + 1
            end
        end
    end
    
    WoW95:Debug("Arranging " .. totalSlots .. " slots in rows of " .. slotsPerRow)
    
    -- Arrange slots in grid
    for bagID = 0, 4 do
        if self.bagFrames[bagID] then
            for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
                local slotButton = self.bagFrames[bagID][slotID]
                if slotButton then
                    local x = BORDER_SIZE + (currentCol * (SLOT_SIZE + SLOT_SPACING))
                    local y = -BORDER_SIZE - (currentRow * (SLOT_SIZE + SLOT_SPACING))
                    
                    slotButton:SetPoint("TOPLEFT", contentArea, "TOPLEFT", x, y)
                    slotButton:Show()
                    
                    currentCol = currentCol + 1
                    if currentCol >= slotsPerRow then
                        currentCol = 0
                        currentRow = currentRow + 1
                    end
                end
            end
        end
    end
    
    -- Adjust window height based on number of rows
    local neededRows = math.ceil(totalSlots / slotsPerRow)
    local neededHeight = TITLE_BAR_HEIGHT + (SLOT_SIZE + BORDER_SIZE * 2) + (neededRows * (SLOT_SIZE + SLOT_SPACING)) + (BORDER_SIZE * 4) + 35 -- Extra space for currency
    self.frame:SetHeight(neededHeight)
    
    WoW95:Debug("Set bag window height to " .. neededHeight .. " for " .. neededRows .. " rows")
end

function Bags:UpdateSlot(slotButton)
    local bagID = slotButton.bagID
    local slotID = slotButton.slotID
    
    local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
    
    if itemInfo and itemInfo.iconFileID then
        -- Item exists
        slotButton.icon:SetTexture(itemInfo.iconFileID)
        slotButton.icon:Show()
        
        -- Update count
        if itemInfo.stackCount and itemInfo.stackCount > 1 then
            slotButton.count:SetText(itemInfo.stackCount)
            slotButton.count:Show()
        else
            slotButton.count:Hide()
        end
        
        -- Update item level for equipment
        local itemLink = C_Container.GetContainerItemLink(bagID, slotID)
        if itemLink then
            local itemLevel = GetDetailedItemLevelInfo(itemLink)
            if itemLevel and itemLevel > 1 then
                -- Only show item level for equipment/weapons (not consumables, etc.)
                local itemID = GetItemInfoFromHyperlink(itemLink)
                local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemID)
                if equipSlot and equipSlot ~= "" and equipSlot ~= "INVTYPE_BAG" and equipSlot ~= "INVTYPE_REAGENTBAG" then
                    slotButton.itemLevel:SetText(itemLevel)
                    slotButton.itemLevel:Show()
                else
                    slotButton.itemLevel:Hide()
                end
            else
                slotButton.itemLevel:Hide()
            end
        else
            slotButton.itemLevel:Hide()
        end
        
        -- Update quality border (thin outline only)
        if itemInfo.quality and itemInfo.quality > 1 then
            local color = ITEM_QUALITY_COLORS[itemInfo.quality]
            if color then
                slotButton.qualityBorder.top:SetColorTexture(color.r, color.g, color.b, 1)
                slotButton.qualityBorder.bottom:SetColorTexture(color.r, color.g, color.b, 1)
                slotButton.qualityBorder.left:SetColorTexture(color.r, color.g, color.b, 1)
                slotButton.qualityBorder.right:SetColorTexture(color.r, color.g, color.b, 1)
                slotButton.qualityBorder:Show()
            end
        else
            slotButton.qualityBorder:Hide()
        end
        
        -- Update cooldown
        local startTime, duration = C_Container.GetContainerItemCooldown(bagID, slotID)
        if startTime and duration and duration > 0 then
            slotButton.cooldown:SetCooldown(startTime, duration)
        else
            slotButton.cooldown:Clear()
        end
        
    else
        -- Empty slot
        slotButton.icon:Hide()
        slotButton.count:Hide()
        slotButton.itemLevel:Hide()
        slotButton.qualityBorder:Hide()
        slotButton.cooldown:Clear()
    end
end

function Bags:UpdateAllSlots()
    -- Update bag slots
    self:UpdateBagSlots()
    
    -- Update currency
    self:UpdateCurrency()
    
    -- Update item slots
    for bagID = 0, 4 do
        if self.bagFrames[bagID] then
            for slotID, slotButton in pairs(self.bagFrames[bagID]) do
                self:UpdateSlot(slotButton)
            end
        end
    end
end

function Bags:OpenBags()
    if not self.frame then return end
    
    self.isOpen = true
    self.frame:Show()
    self:UpdateAllSlots()
    WoW95:Debug("Opened WoW95 bags")
end

function Bags:CloseBags()
    if not self.frame then return end
    
    self.isOpen = false
    self.frame:Hide()
    WoW95:Debug("Closed WoW95 bags")
end

function Bags:ToggleBags()
    if self.isOpen then
        self:CloseBags()
    else
        self:OpenBags()
    end
end

function Bags:ToggleLock()
    self.locked = not self.locked
    
    if self.frame.lockText then
        self.frame.lockText:SetText(self.locked and "🔒" or "🔓")
    end
    
    WoW95:Debug("Bags " .. (self.locked and "locked" or "unlocked"))
end

function Bags:HideBlizzardBags()
    -- Hide default bag frames
    local blizzardBags = {
        "ContainerFrame1",
        "ContainerFrame2", 
        "ContainerFrame3",
        "ContainerFrame4",
        "ContainerFrame5",
        "BackpackFrame"
    }
    
    for _, frameName in ipairs(blizzardBags) do
        local frame = _G[frameName]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            -- Prevent them from showing
            frame:SetScript("OnShow", function() frame:Hide() end)
        end
    end
    
    WoW95:Debug("Hidden Blizzard bag frames")
end

function Bags:HookBagEvents()
    -- Hook bag update events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
    eventFrame:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    eventFrame:RegisterEvent("PLAYER_MONEY") -- For currency updates
    eventFrame:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") -- For bag slot updates
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "BAG_UPDATE" then
            local bagID = ...
            if bagID and bagID <= 4 then
                Bags:UpdateAllSlots()
            end
        elseif event == "PLAYER_MONEY" then
            Bags:UpdateCurrency()
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            -- Update bag slots when equipment changes
            Bags:UpdateBagSlots()
        elseif event == "BAG_UPDATE_COOLDOWN" or 
               event == "ITEM_LOCK_CHANGED" or
               event == "BAG_NEW_ITEMS_UPDATED" or
               event == "BAG_SLOT_FLAGS_UPDATED" then
            Bags:UpdateAllSlots()
        end
    end)
end

function Bags:HookBagButton()
    -- Hook the main bag button to open our bags instead
    local mainMenuBarBackpackButton = _G["MainMenuBarBackpackButton"]
    if mainMenuBarBackpackButton then
        mainMenuBarBackpackButton:SetScript("OnClick", function()
            Bags:ToggleBags()
        end)
        WoW95:Debug("Hooked main bag button")
    end
    
    -- Also hook the 'B' key
    local function ToggleBagsBinding()
        Bags:ToggleBags()
    end
    
    -- Override the default bag toggle
    _G["ToggleAllBags"] = ToggleBagsBinding
    _G["ToggleBag"] = ToggleBagsBinding
end

-- Register the module
WoW95:RegisterModule("Bags", Bags)