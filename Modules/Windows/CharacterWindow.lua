-- WoW95 Character Window Module
-- EXACTLY extracted from original Windows.lua - ALL original code preserved

local addonName, WoW95 = ...

local CharacterWindow = {}
WoW95.CharacterWindow = CharacterWindow

function CharacterWindow:CreateWindow(frameName, program)
    -- Don't create duplicate windows - show existing one if it exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug("Character Info window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    WoW95:Debug("Creating custom Character Info window")
    
    -- Create the main character info window (custom without lock button)
    local programWindow = self:CreateCharacterWindow(
        "WoW95CharacterInfo", 
        UIParent, 
        750, 
        530, 
        "Character Information - World of Warcraft"
    )
    
    -- Position window
    programWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Character Info specific data
    programWindow.currentTab = "equipment"
    programWindow.tabs = {}
    programWindow.tabContent = {}
    programWindow.equipmentSlots = {}
    
    -- Tab definitions
    local TABS = {
        {id = "equipment", name = "Equipment", icon = "Interface\\Icons\\INV_Chest_Cloth_17"},
        {id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_01"},
        {id = "currency", name = "Currency", icon = "Interface\\Icons\\INV_Misc_Coin_01"}
    }
    
    -- Equipment slot data (positioned to surround the 3D model in center)
    local EQUIPMENT_SLOTS = {
        -- Left side slots (moved up to start right after tabs)
        {slot = 1, name = "Head", pos = {x = 15, y = -15}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head"},
        {slot = 2, name = "Neck", pos = {x = 15, y = -60}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck"},
        {slot = 3, name = "Shoulder", pos = {x = 15, y = -105}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder"},
        {slot = 15, name = "Back", pos = {x = 15, y = -150}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"},
        {slot = 5, name = "Chest", pos = {x = 15, y = -195}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"},
        {slot = 4, name = "Shirt", pos = {x = 15, y = -240}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt"},
        {slot = 19, name = "Tabard", pos = {x = 15, y = -285}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard"},
        {slot = 9, name = "Wrist", pos = {x = 15, y = -330}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists"},
        
        -- Right side slots (moved up to start right after tabs)
        {slot = 10, name = "Hands", pos = {x = 365, y = -15}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands"},
        {slot = 6, name = "Waist", pos = {x = 365, y = -60}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist"},
        {slot = 7, name = "Legs", pos = {x = 365, y = -105}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs"},
        {slot = 8, name = "Feet", pos = {x = 365, y = -150}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet"},
        {slot = 11, name = "Finger 1", pos = {x = 365, y = -195}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger"},
        {slot = 12, name = "Finger 2", pos = {x = 365, y = -240}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger"},
        {slot = 13, name = "Trinket 1", pos = {x = 365, y = -285}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket"},
        {slot = 14, name = "Trinket 2", pos = {x = 365, y = -330}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket"},
        
        -- Weapons (center bottom, positioned to fit within window with proper spacing)
        {slot = 16, name = "Main Hand", pos = {x = 150, y = -350}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand"},
        {slot = 17, name = "Off Hand", pos = {x = 250, y = -350}, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand"}
    }
    
    -- Create tab bar
    local tabBar = CreateFrame("Frame", nil, programWindow, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT", programWindow, "TOPLEFT", 8, -50)
    tabBar:SetPoint("TOPRIGHT", programWindow, "TOPRIGHT", -8, -50)
    tabBar:SetHeight(30)
    
    -- Tab bar background
    tabBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    tabBar:SetBackdropColor(0.7, 0.7, 0.7, 1)
    tabBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create tabs
    local tabWidth = 120
    for i, tabData in ipairs(TABS) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tab:SetSize(tabWidth, 25)
        tab:SetPoint("LEFT", tabBar, "LEFT", (i-1) * tabWidth + 5, 0)
        
        -- Tab backdrop
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        tab:SetBackdropColor(0.75, 0.75, 0.75, 1)
        tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        -- Tab text
        local tabText = tab:CreateFontString(nil, "OVERLAY")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        tabText:SetText(tabData.name)
        tabText:SetTextColor(0, 0, 0, 1)
        tabText:SetShadowOffset(0, 0)
        
        -- Tab click handler
        tab:SetScript("OnClick", function()
            self:ShowCharacterTab(programWindow, tabData.id)
        end)
        
        -- Tab hover effects
        tab:SetScript("OnEnter", function(self)
            if tabData.id ~= programWindow.currentTab then
                self:SetBackdropColor(0.85, 0.85, 0.85, 1)
            end
        end)
        
        tab:SetScript("OnLeave", function(self)
            if tabData.id ~= programWindow.currentTab then
                self:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
        end)
        
        tab.tabData = tabData
        tab.text = tabText
        programWindow.tabs[tabData.id] = tab
    end
    
    -- Create content area
    local contentArea = CreateFrame("Frame", nil, programWindow, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
    contentArea:SetPoint("BOTTOMRIGHT", programWindow, "BOTTOMRIGHT", -8, 8)
    
    -- Content area background
    contentArea:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    contentArea:SetBackdropColor(1, 1, 1, 1) -- White background
    contentArea:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create content frames for each tab
    for _, tabData in ipairs(TABS) do
        local content = CreateFrame("Frame", nil, contentArea)
        content:SetAllPoints(contentArea)
        content:Hide() -- Initially hidden
        programWindow.tabContent[tabData.id] = content
    end
    
    programWindow.contentArea = contentArea
    programWindow.tabBar = tabBar
    programWindow.EQUIPMENT_SLOTS = EQUIPMENT_SLOTS
    
    -- Show initial tab (Equipment)
    self:ShowCharacterTab(programWindow, "equipment")
    
    -- Set properties for taskbar recognition
    programWindow.programName = program.name
    programWindow.frameName = frameName
    programWindow.isWoW95Window = true
    programWindow.isProgramWindow = true
    
    -- Store reference
    WoW95.WindowsCore:StoreProgramWindow(frameName, programWindow)
    
    -- Add a custom hide script to ensure proper cleanup when closed by other means
    programWindow:HookScript("OnHide", function()
        -- Only clean up if we still have a reference (avoid double cleanup)
        if WoW95.WindowsCore:GetProgramWindow(frameName) == programWindow then
            WoW95:Debug("Character window hidden, cleaning up tracking")
            WoW95.WindowsCore:RemoveProgramWindow(frameName)
            -- Ensure the Blizzard frame is also hidden to prevent state mismatch
            local blizzardFrame = _G[frameName]
            if blizzardFrame and blizzardFrame:IsShown() then
                blizzardFrame:Hide()
            end
        end
    end)
    
    -- Show the window
    programWindow:Show()
    
    -- Notify taskbar
    WoW95:OnWindowOpened(programWindow)
    
    return programWindow
end

-- Custom CreateCharacterWindow function (with blue title bar, no lock button)
function CharacterWindow:CreateCharacterWindow(name, parent, width, height, title)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    
    -- Set size
    frame:SetSize(width or 300, height or 200)
    
    -- Create the main window backdrop (solid gray)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    frame:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Solid Windows 95 gray
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create title bar
    local titleBar = CreateFrame("Frame", name .. "TitleBar", frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    
    -- Title bar backdrop with our blue color
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- Direct blue color
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText(title or "Window")
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Only close button (no lock button)
    local closeButton = WoW95:CreateTitleBarButton(name .. "CloseButton", titleBar, WoW95.textures.close, 16)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    
    -- Close button functionality
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        -- Notify window closed through the Windows module
        if CharacterWindow.OnCharacterWindowClosed then
            CharacterWindow:OnCharacterWindowClosed(frame)
        end
    end)
    
    -- Enable mouse for title bar (for dragging)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Set frame properties
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    
    -- Store references
    frame.titleBar = titleBar
    frame.titleText = titleText
    frame.closeButton = closeButton
    
    return frame
end

function CharacterWindow:OnCharacterWindowClosed(frame)
    -- Clear the character frame from programWindows when closed
    if WoW95.WindowsCore:GetProgramWindow("CharacterFrame") == frame then
        WoW95.WindowsCore:RemoveProgramWindow("CharacterFrame")
        WoW95:OnWindowClosed(frame)
    end
end

function CharacterWindow:ShowCharacterTab(programWindow, tabId)
    -- Hide all tab content and disable mouse interaction
    for id, content in pairs(programWindow.tabContent) do
        content:Hide()
        -- Recursively disable mouse events for all child frames
        local function DisableMouseForChildren(frame)
            if frame.EnableMouse then
                frame:EnableMouse(false)
            end
            for _, child in pairs({frame:GetChildren()}) do
                DisableMouseForChildren(child)
            end
        end
        DisableMouseForChildren(content)
    end
    
    -- Update tab appearances
    for id, tab in pairs(programWindow.tabs) do
        if id == tabId then
            tab:SetBackdropColor(1, 1, 1, 1) -- White for active tab
            tab:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        else
            tab:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Gray for inactive tabs
            tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end
    
    -- Show selected tab content and enable mouse interaction
    if programWindow.tabContent[tabId] then
        local activeContent = programWindow.tabContent[tabId]
        activeContent:Show()
        programWindow.currentTab = tabId
        
        -- Re-enable mouse events for the active tab content
        local function EnableMouseForChildren(frame)
            if frame.EnableMouse then
                -- Enable mouse if explicitly marked as needing mouse, or if not explicitly disabled
                if frame.WoW95ShouldHaveMouse == true or frame.WoW95ShouldHaveMouse == nil then
                    frame:EnableMouse(true)
                end
            end
            for _, child in pairs({frame:GetChildren()}) do
                EnableMouseForChildren(child)
            end
        end
        EnableMouseForChildren(activeContent)
        
        -- Create content if not already created
        if tabId == "equipment" and not activeContent.contentCreated then
            self:CreateEquipmentTab(programWindow)
        elseif tabId == "reputation" and not activeContent.contentCreated then
            self:CreateReputationTab(programWindow)
        elseif tabId == "currency" and not activeContent.contentCreated then
            self:CreateCurrencyTab(programWindow)
        end
    end
    
    WoW95:Debug("Switched to character tab: " .. tabId)
end

function CharacterWindow:CreateEquipmentTab(programWindow)
    local content = programWindow.tabContent["equipment"]
    if not content then return end
    
    WoW95:Debug("Creating Equipment tab content")
    
    -- Character model area (positioned between equipment columns in the white content area)
    -- No backdrop - blends with white background
    local modelFrame = CreateFrame("Frame", nil, content)
    modelFrame:SetSize(200, 330)
    -- Left column items at x=15, with 40px wide slots, so right edge = 15+40 = 55
    -- Right column items at x=365, so gap is from 55 to 365 = 310px wide
    -- Center of gap = 55 + (310/2) = 55 + 155 = 210
    -- Model is 200px wide, so position at 210 - 100 = 110 to center it
    -- Position in the white content area below the tabs
    modelFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 110, -20)
    
    -- Player model (3D character view)
    local playerModel = CreateFrame("PlayerModel", nil, modelFrame)
    playerModel:SetAllPoints(modelFrame)
    
    -- Set the model to show the player character
    playerModel:SetUnit("player")
    playerModel:SetRotation(0.6) -- Slight rotation for better view
    
    -- Camera position adjustment (zoom out more and center better to prevent clipping)
    playerModel:SetCamDistanceScale(0.9)
    playerModel:SetPosition(0, 0, -0.1)
    
    -- Enable model interaction for spinning
    playerModel:EnableMouse(true)
    playerModel:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isRotating = true
            self.lastCursorX = GetCursorPosition()
        end
    end)
    
    playerModel:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.isRotating = false
        end
    end)
    
    playerModel:SetScript("OnUpdate", function(self)
        if self.isRotating then
            local cursorX = GetCursorPosition()
            local diff = (cursorX - self.lastCursorX) * 0.01
            self:SetRotation(self:GetRotation() + diff)
            self.lastCursorX = cursorX
        end
    end)
    
    -- Store reference
    programWindow.playerModel = playerModel
    
    -- Create the equipment slot frames
    self:CreateEquipmentSlots(programWindow, content)
    
    -- Create stats panel
    self:CreateStatsPanel(content)
    
    -- Mark content as created
    content.contentCreated = true
    
    WoW95:Debug("Equipment tab content created")
end

function CharacterWindow:CreateEquipmentSlots(programWindow, parent)
    -- Create each equipment slot positioned around the model
    for _, slotData in ipairs(programWindow.EQUIPMENT_SLOTS) do
        -- Create slot frame
        local slotFrame = CreateFrame("Button", nil, parent, "BackdropTemplate")
        slotFrame:SetSize(40, 40)
        slotFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", slotData.pos.x, slotData.pos.y)
        
        -- Slot backdrop (sunken border effect)
        slotFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        slotFrame:SetBackdropColor(0.8, 0.8, 0.8, 1)
        slotFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        -- Item icon
        local itemIcon = slotFrame:CreateTexture(nil, "ARTWORK")
        itemIcon:SetAllPoints(slotFrame)
        itemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        -- Get equipped item
        local itemID = GetInventoryItemID("player", slotData.slot)
        if itemID then
            local itemTexture = GetInventoryItemTexture("player", slotData.slot)
            itemIcon:SetTexture(itemTexture)
        else
            -- Show empty slot icon
            itemIcon:SetTexture(slotData.icon)
            itemIcon:SetAlpha(0.3)
        end
        
        -- Slot label
        local slotLabel = slotFrame:CreateFontString(nil, "OVERLAY")
        slotLabel:SetPoint("BOTTOM", slotFrame, "TOP", 0, 2)
        slotLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
        slotLabel:SetText(slotData.name)
        slotLabel:SetTextColor(0, 0, 0, 1)
        slotLabel:SetShadowOffset(0, 0)
        
        -- Item level text (positioned inside the slot to prevent cutoff)
        local ilvlText = slotFrame:CreateFontString(nil, "OVERLAY")
        ilvlText:SetPoint("BOTTOM", slotFrame, "BOTTOM", 0, 2)
        ilvlText:SetFont("Fonts\\FRIZQT__.TTF", 7, "")
        ilvlText:SetTextColor(1, 1, 1, 1) -- White text for visibility on item background
        ilvlText:SetShadowOffset(1, -1)
        ilvlText:SetShadowColor(0, 0, 0, 1) -- Black shadow for readability
        
        -- Update item level if item exists
        if itemID then
            local itemLink = GetInventoryItemLink("player", slotData.slot)
            if itemLink then
                local _, _, _, ilvl = GetItemInfo(itemLink)
                if ilvl then
                    ilvlText:SetText("iLvl " .. ilvl)
                end
            end
        end
        
        -- Make slots interactive
        slotFrame:EnableMouse(true)
        slotFrame:SetScript("OnEnter", function(self)
            -- Highlight on hover
            self:SetBackdropBorderColor(0.6, 0.6, 0.9, 1)
            
            -- Show item tooltip
            if GetInventoryItemID("player", slotData.slot) then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetInventoryItem("player", slotData.slot)
                GameTooltip:Show()
            else
                -- Show empty slot tooltip
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(slotData.name .. " Slot")
                GameTooltip:AddLine("Drag an item here to equip it", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)
        
        slotFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        programWindow.equipmentSlots[slotData.slot] = {
            frame = slotFrame,
            icon = itemIcon,
            label = slotLabel,
            ilvl = ilvlText
        }
    end
end

function CharacterWindow:CreateStatsPanel(parent)
    -- Stats panel (moved further right to accommodate new layout)
    local statsPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    statsPanel:SetSize(180, 350)
    statsPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    statsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    statsPanel:SetBackdropColor(0.95, 0.95, 0.95, 1)
    statsPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Stats title
    local statsTitle = statsPanel:CreateFontString(nil, "OVERLAY")
    statsTitle:SetPoint("TOP", statsPanel, "TOP", 0, -8)
    statsTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    statsTitle:SetText("Character Stats")
    statsTitle:SetTextColor(0, 0, 0, 1)
    statsTitle:SetShadowOffset(0, 0)
    statsTitle:SetShadowColor(0, 0, 0, 0) -- Remove drop shadow
    
    -- Get player stats
    local level = UnitLevel("player")
    local class = UnitClass("player")
    local race = UnitRace("player")
    
    -- Get class color
    local _, englishClass = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[englishClass] or {r=1, g=1, b=1}
    
    -- Create colored stat lines
    local yOffset = -30
    local function CreateColoredStatLine(label, value, labelColor, valueColor)
        labelColor = labelColor or {0.2, 0.4, 0.8, 1} -- Default blue for labels
        valueColor = valueColor or {0, 0, 0, 1} -- Default black for values
        
        -- Create label
        local labelText = statsPanel:CreateFontString(nil, "OVERLAY")
        labelText:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 8, yOffset)
        labelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        labelText:SetText(label .. ":")
        labelText:SetTextColor(unpack(labelColor))
        labelText:SetShadowColor(0, 0, 0, 0)
        labelText:SetJustifyH("LEFT")
        
        -- Create value
        local valueText = statsPanel:CreateFontString(nil, "OVERLAY")
        valueText:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
        valueText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        valueText:SetText(tostring(value))
        valueText:SetTextColor(unpack(valueColor))
        valueText:SetShadowColor(0, 0, 0, 0)
        valueText:SetJustifyH("LEFT")
        
        yOffset = yOffset - 16
        return labelText, valueText
    end
    
    CreateColoredStatLine("Level", level)
    CreateColoredStatLine("Class", class, {0.2, 0.4, 0.8, 1}, {classColor.r, classColor.g, classColor.b, 1})
    CreateColoredStatLine("Race", race)
    
    yOffset = yOffset - 10 -- Add some spacing
    
    -- Primary stats with colored labels
    CreateColoredStatLine("Strength", UnitStat("player", 1), {0.8, 0.2, 0.2, 1}) -- Red
    CreateColoredStatLine("Agility", UnitStat("player", 2), {0.2, 0.8, 0.2, 1}) -- Green
    CreateColoredStatLine("Stamina", UnitStat("player", 3), {0.8, 0.6, 0.2, 1}) -- Orange
    CreateColoredStatLine("Intellect", UnitStat("player", 4), {0.2, 0.4, 0.8, 1}) -- Blue
    
    yOffset = yOffset - 10
    
    -- Secondary stats with colored labels
    CreateColoredStatLine("Critical Strike", string.format("%.1f", GetCritChance()) .. "%", {0.6, 0.2, 0.6, 1}) -- Purple
    CreateColoredStatLine("Haste", string.format("%.1f", GetHaste()) .. "%", {0.8, 0.4, 0.2, 1}) -- Orange-red
    CreateColoredStatLine("Mastery", string.format("%.1f", GetMastery()) .. "%", {0.2, 0.6, 0.8, 1}) -- Light blue
    local versatilityRating = GetCombatRating(29) or 0
    local versatilityPercent = GetCombatRatingBonus(29) or 0
    CreateColoredStatLine("Versatility", versatilityRating .. " (" .. string.format("%.1f", versatilityPercent) .. "%)", {0.4, 0.8, 0.4, 1}) -- Light green
    
    yOffset = yOffset - 10
    
    -- Item level with colored label
    local avgItemLevel, equippedItemLevel = GetAverageItemLevel()
    CreateColoredStatLine("Item Level", string.format("%.1f", avgItemLevel or 0), {0.6, 0.4, 0.2, 1}) -- Brown/gold
    
    WoW95:Debug("Created stats panel with character information")
end

function CharacterWindow:CreateReputationTab(programWindow)
    local content = programWindow.tabContent["reputation"]
    if not content then return end
    
    WoW95:Debug("Creating Reputation tab content")
    
    -- Create scrollable reputation list
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "BackdropTemplate")
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 10)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    scrollFrame:SetBackdropColor(0.98, 0.98, 0.98, 1)
    scrollFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 4, 1) -- Height will be set dynamically
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", scrollChild, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Faction Standings")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    title:SetShadowColor(0, 0, 0, 0)
    
    -- Get reputation data
    local yOffset = -35
    local factionCount = 0
    
    -- Get all factions using modern API
    local numFactions = C_Reputation.GetNumFactions() or 0
    for i = 1, numFactions do
        local factionData = C_Reputation.GetFactionDataByIndex(i)
        
        if factionData then
            local name = factionData.name
            local standingID = factionData.reaction
            local barMin = factionData.currentReactionThreshold or 0
            local barMax = factionData.nextReactionThreshold or 0
            local barValue = factionData.currentStanding or 0
            local isHeader = factionData.isHeader
            local isCollapsed = factionData.isCollapsed
            local factionID = factionData.factionID
            
            -- Check if this is a major faction (renown system)
            local isMajorFaction = false
            local majorFactionData = nil
            if factionID and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
                isMajorFaction = majorFactionData ~= nil
            end
            
            if isHeader then
                -- Create expandable header
                factionCount = factionCount + 1
                
                local headerFrame = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
                headerFrame:SetSize(scrollFrame:GetWidth() - 30, 20)
                headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
                headerFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 8,
                    edgeSize = 1,
                    insets = {left = 1, right = 1, top = 1, bottom = 1}
                })
                headerFrame:SetBackdropColor(0.8, 0.8, 0.9, 1)
                headerFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                
                -- Expand/collapse icon
                local expandIcon = headerFrame:CreateFontString(nil, "OVERLAY")
                expandIcon:SetPoint("LEFT", headerFrame, "LEFT", 5, 0)
                expandIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                expandIcon:SetText(isCollapsed and "+" or "-")
                expandIcon:SetTextColor(0, 0, 0, 1)
                expandIcon:SetShadowOffset(0, 0)
                expandIcon:SetShadowColor(0, 0, 0, 0)
                
                -- Header name
                local headerName = headerFrame:CreateFontString(nil, "OVERLAY")
                headerName:SetPoint("LEFT", expandIcon, "RIGHT", 5, 0)
                headerName:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                headerName:SetText(name)
                headerName:SetTextColor(0.1, 0.1, 0.5, 1)
                headerName:SetShadowColor(0, 0, 0, 0)
                
                -- Click to expand/collapse
                headerFrame:SetScript("OnClick", function()
                    if not InCombatLockdown() then
                        if isCollapsed then
                            -- First collapse all other headers to prevent clipping
                            local totalFactions = C_Reputation.GetNumFactions() or 0
                            for j = 1, totalFactions do
                                local otherFactionData = C_Reputation.GetFactionDataByIndex(j)
                                if otherFactionData and otherFactionData.isHeader and j ~= i and not otherFactionData.isCollapsed then
                                    C_Reputation.CollapseFactionHeader(j)
                                end
                            end
                            -- Then expand this one
                            C_Reputation.ExpandFactionHeader(i)
                        else
                            C_Reputation.CollapseFactionHeader(i)
                        end
                        -- Refresh the reputation tab after a short delay
                        C_Timer.After(0.2, function()
                            if programWindow.tabContent["reputation"] then
                                -- Clear all content first
                                for _, child in pairs({programWindow.tabContent["reputation"]:GetChildren()}) do
                                    child:Hide()
                                    child:SetParent(nil)
                                end
                                programWindow.tabContent["reputation"].contentCreated = nil
                                self:ShowCharacterTab(programWindow, "reputation")
                            end
                        end)
                    end
                end)
                
                -- Hover effect
                headerFrame:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.9, 0.9, 1, 1)
                end)
                headerFrame:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.8, 0.8, 0.9, 1)
                end)
                
                yOffset = yOffset - 25
                
            elseif name then
                factionCount = factionCount + 1
                
                -- Faction name (indented under headers)  
                local factionName = scrollChild:CreateFontString(nil, "OVERLAY")
                factionName:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 25, yOffset) -- Indented more than headers
                factionName:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                factionName:SetText(name)
                factionName:SetTextColor(0, 0, 0, 1)
                factionName:SetShadowOffset(0, 0)
                factionName:SetShadowColor(0, 0, 0, 0)
                factionName:SetJustifyH("LEFT")
                
                local standingText, standingColors, displayText
                
                if isMajorFaction and majorFactionData then
                    -- Handle major factions (renown system)
                    local renownLevel = majorFactionData.renownLevel or 1
                    displayText = "Renown " .. renownLevel
                    standingText = {displayText}
                    standingColors = {{0.0, 0.8, 1.0, 1}} -- Bright blue for renown
                    
                    -- Use renown progress for bar
                    barValue = majorFactionData.renownReputationEarned or 0
                    barMax = majorFactionData.renownLevelThreshold or 1
                    barMin = 0
                else
                    -- Handle regular factions
                    standingText = {"Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"}
                    standingColors = {
                        {0.8, 0.1, 0.1, 1}, -- Hated - Red
                        {0.9, 0.2, 0.1, 1}, -- Hostile - Orange-red  
                        {0.8, 0.4, 0.1, 1}, -- Unfriendly - Orange
                        {0.8, 0.8, 0.1, 1}, -- Neutral - Yellow
                        {0.1, 0.8, 0.1, 1}, -- Friendly - Green
                        {0.1, 0.6, 0.8, 1}, -- Honored - Light blue
                        {0.4, 0.2, 0.8, 1}, -- Revered - Purple
                        {0.8, 0.4, 0.8, 1}  -- Exalted - Pink
                    }
                    displayText = standingText[standingID] or "Unknown"
                end
                
                local standing = scrollChild:CreateFontString(nil, "OVERLAY")
                standing:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -15, yOffset)
                standing:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                standing:SetText(displayText)
                standing:SetTextColor(unpack(standingColors[1] or {0.5, 0.5, 0.5, 1}))
                standing:SetShadowColor(0, 0, 0, 0)
                standing:SetJustifyH("RIGHT")
                
                -- Progress bar (show for major factions or regular non-exalted)
                local showProgressBar = (isMajorFaction and majorFactionData) or (standingID < 8 and barMax > barMin)
                if showProgressBar and barMax > barMin then
                    local progressBG = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                    progressBG:SetSize(180, 8)
                    progressBG:SetPoint("TOPLEFT", factionName, "BOTTOMLEFT", 0, -3)
                    progressBG:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true,
                        tileSize = 1,
                        edgeSize = 1,
                        insets = {left = 1, right = 1, top = 1, bottom = 1}
                    })
                    progressBG:SetBackdropColor(0.2, 0.2, 0.2, 1)
                    progressBG:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                    
                    local progressBar = CreateFrame("Frame", nil, progressBG, "BackdropTemplate")
                    local progress = math.max(0, math.min(1, (barValue - barMin) / (barMax - barMin)))
                    progressBar:SetSize(178 * progress, 6)
                    progressBar:SetPoint("LEFT", progressBG, "LEFT", 1, 0)
                    progressBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                    
                    -- Use appropriate color for progress bar
                    if isMajorFaction then
                        progressBar:SetBackdropColor(unpack(standingColors[1])) -- Blue for renown
                    else
                        progressBar:SetBackdropColor(unpack(standingColors[standingID] or {0.5, 0.5, 0.5, 1}))
                    end
                    
                    -- Progress text
                    local progressText = scrollChild:CreateFontString(nil, "OVERLAY")
                    progressText:SetPoint("CENTER", progressBG, "CENTER", 0, 0)
                    progressText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                    
                    if isMajorFaction then
                        -- Show renown progress
                        progressText:SetText(barValue .. "/" .. barMax)
                    else
                        -- Show regular reputation progress
                        progressText:SetText((barValue - barMin) .. "/" .. (barMax - barMin))
                    end
                    
                    progressText:SetTextColor(1, 1, 1, 1)
                    progressText:SetShadowColor(0, 0, 0, 1)
                    
                    yOffset = yOffset - 35
                else
                    yOffset = yOffset - 20
                end
                
                -- Limit to prevent too many factions
                if factionCount >= 30 then break end
            end
        end
    end
    
    -- Set scroll child height dynamically
    local contentHeight = math.abs(yOffset) + 50  -- Extra padding
    scrollChild:SetHeight(contentHeight)
    
    -- Update scroll frame settings
    scrollFrame:SetVerticalScroll(0)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
        local currentScroll = self:GetVerticalScroll()
        local newScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * 20)))
        self:SetVerticalScroll(newScroll)
    end)
    
    content.contentCreated = true
    
    WoW95:Debug("Reputation tab content created")
end

function CharacterWindow:CreateCurrencyTab(programWindow)
    local content = programWindow.tabContent["currency"]
    if not content then return end
    
    WoW95:Debug("Creating Currency tab content")
    
    -- Create scrollable currency list
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "BackdropTemplate")
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 10)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    scrollFrame:SetBackdropColor(0.98, 0.98, 0.98, 1)
    scrollFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Disable mouse on scroll frame so child buttons can receive clicks
    scrollFrame:EnableMouse(false)
    
    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 4, 1)
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", scrollChild, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Currencies & Tokens")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    title:SetShadowColor(0, 0, 0, 0)
    
    local yOffset = -35
    local currencyCount = 0
    
    -- Get money first
    local money = GetMoney()
    if money > 0 then
        currencyCount = currencyCount + 1
        
        -- Gold icon
        local goldIcon = scrollChild:CreateTexture(nil, "ARTWORK")
        goldIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
        goldIcon:SetSize(16, 16)
        goldIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        
        -- Gold name
        local goldName = scrollChild:CreateFontString(nil, "OVERLAY")
        goldName:SetPoint("LEFT", goldIcon, "RIGHT", 5, 0)
        goldName:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        goldName:SetText("Gold")
        goldName:SetTextColor(0, 0, 0, 1)
        goldName:SetShadowOffset(0, 0)
        goldName:SetShadowColor(0, 0, 0, 0)
        
        -- Gold amount
        local goldAmount = scrollChild:CreateFontString(nil, "OVERLAY")
        goldAmount:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -15, yOffset)
        goldAmount:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        
        local moneyText = ""
        if gold > 0 then
            moneyText = gold .. "g "
        end
        if silver > 0 or gold > 0 then
            moneyText = moneyText .. silver .. "s "
        end
        moneyText = moneyText .. copper .. "c"
        
        goldAmount:SetText(moneyText)
        goldAmount:SetTextColor(1, 0.8, 0, 1) -- Gold color
        goldAmount:SetShadowColor(0, 0, 0, 0)
        
        yOffset = yOffset - 25
    end
    
    -- Get currency data - show ALL currencies that are discovered/tracked, not just those with quantity > 0
    for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
        local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
        
        -- Show currency if it's not a header and either has quantity OR is discovered/watched
        if currencyInfo and not currencyInfo.isHeader and (currencyInfo.quantity > 0 or currencyInfo.discovered or currencyInfo.isWatched) then
            currencyCount = currencyCount + 1
            
            -- Currency icon
            local currencyIcon = scrollChild:CreateTexture(nil, "ARTWORK")
            currencyIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
            currencyIcon:SetSize(16, 16)
            if currencyInfo.iconFileID and currencyInfo.iconFileID > 0 then
                currencyIcon:SetTexture(currencyInfo.iconFileID)
            else
                currencyIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Currency name
            local currencyName = scrollChild:CreateFontString(nil, "OVERLAY")
            currencyName:SetPoint("LEFT", currencyIcon, "RIGHT", 5, 0)
            currencyName:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            currencyName:SetText(currencyInfo.name or "Unknown")
            currencyName:SetTextColor(0, 0, 0, 1)
            currencyName:SetShadowOffset(0, 0)
            currencyName:SetShadowColor(0, 0, 0, 0)
            
            -- Check if currency is transferable
            local isTransferable = false
            local transferInfo = nil
            if C_CurrencyInfo.IsCurrencyAccountTransferable and currencyInfo.currencyTypesID then
                local success, result = pcall(C_CurrencyInfo.IsCurrencyAccountTransferable, currencyInfo.currencyTypesID)
                isTransferable = success and result
                WoW95:Debug("Currency " .. (currencyInfo.name or "Unknown") .. " transferable: " .. tostring(isTransferable))
                
                if isTransferable and C_CurrencyInfo.GetCurrencyTransferInfo then
                    local success2, result2 = pcall(C_CurrencyInfo.GetCurrencyTransferInfo, currencyInfo.currencyTypesID)
                    if success2 then
                        transferInfo = result2
                    end
                end
            end
            
            -- Currency amount (adjust position if transfer button exists)
            local currencyAmount = scrollChild:CreateFontString(nil, "OVERLAY")
            if isTransferable then
                currencyAmount:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -80, yOffset) -- Make room for transfer button
            else
                currencyAmount:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -15, yOffset)
            end
            currencyAmount:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            
            local amountText = tostring(currencyInfo.quantity or 0)
            if currencyInfo.maxQuantity and currencyInfo.maxQuantity > 0 then
                amountText = amountText .. "/" .. currencyInfo.maxQuantity
            end
            
            currencyAmount:SetText(amountText)
            
            -- Color based on currency type
            local currencyColor = {0.2, 0.2, 0.8, 1} -- Default blue
            if currencyInfo.name then
                if currencyInfo.name:find("Honor") then
                    currencyColor = {0.8, 0.2, 0.2, 1} -- Red for Honor
                elseif currencyInfo.name:find("Conquest") then
                    currencyColor = {0.8, 0.4, 0.1, 1} -- Orange for Conquest  
                elseif currencyInfo.name:find("Justice") or currencyInfo.name:find("Valor") then
                    currencyColor = {0.1, 0.8, 0.1, 1} -- Green for PvE currencies
                elseif currencyInfo.name:find("Badge") or currencyInfo.name:find("Mark") then
                    currencyColor = {0.6, 0.2, 0.8, 1} -- Purple for badges
                end
            end
            
            currencyAmount:SetTextColor(unpack(currencyColor))
            currencyAmount:SetShadowColor(0, 0, 0, 0)
            
            -- Add transfer button if currency is transferable
            if isTransferable then
                WoW95:Debug("Creating transfer button for currency: " .. (currencyInfo.name or "Unknown"))
                
                -- Create a simple button frame instead of using WoW95:CreateButton
                local transferButton = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
                transferButton:SetSize(60, 16)
                transferButton:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, yOffset - 1)
                
                -- Button backdrop
                transferButton:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 8,
                    edgeSize = 1,
                    insets = {left = 1, right = 1, top = 1, bottom = 1}
                })
                transferButton:SetBackdropColor(0.7, 0.7, 0.9, 1)
                transferButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                
                -- Button text
                local buttonText = transferButton:CreateFontString(nil, "OVERLAY")
                buttonText:SetPoint("CENTER", transferButton, "CENTER", 0, 0)
                buttonText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                buttonText:SetText("Transfer")
                buttonText:SetTextColor(0, 0, 0, 1)
                buttonText:SetShadowOffset(0, 0)
                buttonText:SetShadowColor(0, 0, 0, 0)
                
                -- Make sure it's mouse enabled and on top
                transferButton:EnableMouse(true)
                transferButton:SetFrameLevel(scrollFrame:GetFrameLevel() + 10)  -- Higher frame level
                transferButton:RegisterForClicks("LeftButtonUp")
                
                -- Mark this button as needing mouse interaction
                transferButton.WoW95ShouldHaveMouse = true
                
                -- Store currency ID for the callback
                local currencyID = currencyInfo.currencyTypesID
                WoW95:Debug("Stored currency ID for transfer: " .. tostring(currencyID))
                
                transferButton:SetScript("OnClick", function(self, button)
                    WoW95:Debug("=== TRANSFER BUTTON CLICKED ===")
                    WoW95:Debug("Button: " .. tostring(button))
                    WoW95:Debug("Currency ID: " .. tostring(currencyID))
                    WoW95:Debug("Combat: " .. tostring(InCombatLockdown()))
                    
                    if not InCombatLockdown() then
                        if C_CurrencyInfo.RequestCurrencyTransfer then
                            WoW95:Debug("Calling RequestCurrencyTransfer for ID: " .. tostring(currencyID))
                            local success, error = pcall(C_CurrencyInfo.RequestCurrencyTransfer, currencyID)
                            if success then
                                WoW95:Debug("Transfer request sent successfully!")
                                UIErrorsFrame:AddMessage("Currency transfer requested!", 0.1, 1.0, 0.1, 1.0)
                            else
                                WoW95:Debug("Transfer failed with error: " .. tostring(error))
                                UIErrorsFrame:AddMessage("Transfer failed: " .. tostring(error), 1.0, 0.1, 0.1, 1.0)
                            end
                        else
                            WoW95:Debug("RequestCurrencyTransfer function not available")
                            UIErrorsFrame:AddMessage("Currency transfer not available!", 1.0, 0.1, 0.1, 1.0)
                        end
                    else
                        WoW95:Debug("Cannot transfer - in combat")
                        UIErrorsFrame:AddMessage("Cannot transfer currency in combat!", 1.0, 0.1, 0.1, 1.0)
                    end
                end)
                
                -- Button effects and tooltip combined
                transferButton:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.8, 0.8, 1.0, 1)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:SetText("Transfer Currency")
                    GameTooltip:AddLine("Transfer this currency between characters on your account", 0.7, 0.7, 0.7)
                    if transferInfo then
                        GameTooltip:AddLine("Available on: " .. (transferInfo.numOtherCharacters or 0) .. " characters", 0.5, 0.5, 0.8)
                    end
                    GameTooltip:Show()
                end)
                
                transferButton:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.7, 0.7, 0.9, 1)
                    GameTooltip:Hide()
                end)
                
                transferButton:SetScript("OnMouseDown", function(self, button)
                    WoW95:Debug("Transfer button mouse down: " .. tostring(button))
                    self:SetBackdropColor(0.5, 0.5, 0.7, 1)
                end)
                
                transferButton:SetScript("OnMouseUp", function(self, button)
                    WoW95:Debug("Transfer button mouse up: " .. tostring(button))
                    self:SetBackdropColor(0.8, 0.8, 1.0, 1)
                end)
            end
            
            yOffset = yOffset - 25
            
            -- Limit display
            if currencyCount >= 25 then break end
        end
    end
    
    -- If no currencies, show a message
    if currencyCount <= 1 then -- Only gold
        local noCurrency = scrollChild:CreateFontString(nil, "OVERLAY")
        noCurrency:SetPoint("CENTER", scrollChild, "CENTER", 0, -50)
        noCurrency:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        noCurrency:SetText("No special currencies found.\n\nEarn currencies through dungeons,\nPvP, raids, and special events.")
        noCurrency:SetTextColor(0.5, 0.5, 0.5, 1)
        noCurrency:SetShadowColor(0, 0, 0, 0)
        noCurrency:SetJustifyH("CENTER")
        yOffset = yOffset - 80
    end
    
    -- Set scroll child height dynamically
    local contentHeight = math.abs(yOffset) + 50  -- Extra padding
    scrollChild:SetHeight(contentHeight)
    
    -- Update scroll frame settings
    scrollFrame:SetVerticalScroll(0)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
        local currentScroll = self:GetVerticalScroll()
        local newScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * 20)))
        self:SetVerticalScroll(newScroll)
    end)
    
    -- Make sure scroll frame doesn't block mouse events for child elements
    scrollFrame:SetHitRectInsets(0, 0, 0, 0)
    
    -- Simple scrollbar
    local scrollbar = CreateFrame("Slider", nil, scrollFrame, "BackdropTemplate")
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -5)
    scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -5, 5)
    scrollbar:SetWidth(15)
    scrollbar:SetOrientation("VERTICAL")
    local maxScrollValue = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollbar:SetMinMaxValues(0, maxScrollValue)
    scrollbar:SetValue(0)
    scrollbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    scrollbar:SetBackdropColor(0.7, 0.7, 0.7, 1)
    scrollbar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    -- Enable mouse wheel scrolling on the content frame instead of scroll frame to allow button clicks
    content:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local newValue = math.max(min, math.min(max, current - (delta * 20)))
        scrollbar:SetValue(newValue)
    end)
    content:EnableMouseWheel(true)
    
    -- Mark content as created
    content.contentCreated = true
    
    WoW95:Debug("Currency tab content created with EXACT original implementation")
end

-- Register the module
WoW95:RegisterModule("CharacterWindow", CharacterWindow)