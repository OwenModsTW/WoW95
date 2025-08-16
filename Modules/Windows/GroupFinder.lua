-- WoW95 Group Finder Module
-- Complete retail-accurate Group Finder replacement with Windows 95 styling

local addonName, WoW95 = ...

local GroupFinder = {}
WoW95.GroupFinder = GroupFinder

-- Group Finder state
GroupFinder.CURRENT_TAB = "dungeons_raids"
GroupFinder.CURRENT_SECTION = "dungeon_finder" -- dungeon_finder, raid_finder, or premade_groups
GroupFinder.SELECTED_ROLE = {
    tank = false,
    healer = false,
    damage = true  -- Default to DPS
}
GroupFinder.SELECTED_DUNGEON = nil
GroupFinder.SELECTED_RAID = nil
GroupFinder.PREMADE_CATEGORY = "dungeons" -- questing, delves, dungeons, raids_current, raids_legacy, custom
GroupFinder.IN_QUEUE = false

function GroupFinder:CreateWindow(frameName, program)
    WoW95:Debug("=== GroupFinder:CreateWindow called ===")
    
    -- Check if window already exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    -- Create the main window
    local window = WoW95:CreateWindow(
        "WoW95GroupFinderWindow", 
        UIParent, 
        program.window.width or 850, 
        program.window.height or 600, 
        program.window.title or "Group Finder - World of Warcraft"
    )
    
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create content area FIRST
    local contentArea = CreateFrame("Frame", nil, window, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -60)
    contentArea:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -10, 10)
    contentArea:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    contentArea:SetBackdropColor(1, 1, 1, 1)
    contentArea:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    window.contentArea = contentArea
    
    -- Create main tabs (like retail) AFTER contentArea exists
    self:CreateMainTabs(window)
    
    -- Initialize with Dungeons & Raids tab
    self:ShowDungeonsAndRaidsTab(window)
    
    -- Register window
    WoW95.WindowsCore:StoreProgramWindow(frameName, window)
    
    window:SetScript("OnHide", function()
        WoW95:OnWindowClosed(window)
    end)
    
    return window
end

function GroupFinder:CreateMainTabs(window)
    -- Main tab bar
    local tabBar = CreateFrame("Frame", nil, window, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -25)
    tabBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -25)
    tabBar:SetHeight(30)
    
    tabBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    tabBar:SetBackdropColor(0.85, 0.85, 0.85, 1)
    tabBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    window.tabs = {}
    
    -- Define main tabs
    local mainTabs = {
        {id = "dungeons_raids", name = "Dungeons & Raids"},
        {id = "pvp", name = "Player vs Player"},
        {id = "mythic_plus", name = "Mythic+"},
        {id = "delves", name = "Delves"}
    }
    
    local tabWidth = 150
    local xOffset = 10
    
    for i, tabData in ipairs(mainTabs) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tab:SetSize(tabWidth, 25)
        tab:SetPoint("LEFT", tabBar, "LEFT", xOffset + ((i-1) * (tabWidth + 5)), 0)
        
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER")
        tabText:SetText(tabData.name)
        tabText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        tab.text = tabText
        
        tab:SetScript("OnClick", function()
            self:SelectMainTab(window, tabData.id)
        end)
        
        window.tabs[tabData.id] = tab
    end
    
    -- Select first tab by default
    self:SelectMainTab(window, "dungeons_raids")
end

function GroupFinder:SelectMainTab(window, tabId)
    self.CURRENT_TAB = tabId
    
    -- Update tab appearance
    for id, tab in pairs(window.tabs) do
        if id == tabId then
            tab:SetBackdropColor(1, 1, 1, 1)
            tab.text:SetTextColor(0, 0, 0, 1)
        else
            tab:SetBackdropColor(0.75, 0.75, 0.75, 1)
            tab.text:SetTextColor(0.3, 0.3, 0.3, 1)
        end
    end
    
    -- Clear content area
    for _, child in ipairs({window.contentArea:GetChildren()}) do
        child:Hide()
    end
    
    -- Show appropriate content
    if tabId == "dungeons_raids" then
        self:ShowDungeonsAndRaidsTab(window)
    elseif tabId == "pvp" then
        self:ShowPvPTab(window)
    elseif tabId == "mythic_plus" then
        self:ShowMythicPlusTab(window)
    elseif tabId == "delves" then
        self:ShowDelvesTab(window)
    end
end

function GroupFinder:ShowDungeonsAndRaidsTab(window)
    local content = window.contentArea
    
    -- Create section selector buttons (3 buttons like retail)
    local sectionFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    sectionFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    sectionFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
    sectionFrame:SetHeight(80)
    sectionFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    sectionFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
    sectionFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    sectionFrame:Show()
    
    window.sectionFrame = sectionFrame
    
    -- Dungeon Finder button
    local dungeonBtn = self:CreateSectionButton(sectionFrame, 
        "Dungeon Finder", 
        "Queue for dungeons",
        10, -10,
        function() self:ShowDungeonFinderSection(window) end)
    
    -- Raid Finder button
    local raidBtn = self:CreateSectionButton(sectionFrame,
        "Raid Finder",
        "Queue for raids",
        240, -10,
        function() self:ShowRaidFinderSection(window) end)
    
    -- Premade Groups button
    local premadeBtn = self:CreateSectionButton(sectionFrame,
        "Premade Groups",
        "Find/create groups",
        470, -10,
        function() self:ShowPremadeGroupsSection(window) end)
    
    window.dungeonBtn = dungeonBtn
    window.raidBtn = raidBtn
    window.premadeBtn = premadeBtn
    
    -- Create main content area below section buttons
    local mainContent = CreateFrame("Frame", nil, content)
    mainContent:SetPoint("TOPLEFT", sectionFrame, "BOTTOMLEFT", 0, -10)
    mainContent:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    mainContent:Show()
    
    window.mainContent = mainContent
    
    -- Show default section (Dungeon Finder)
    self:ShowDungeonFinderSection(window)
end

function GroupFinder:CreateSectionButton(parent, title, description, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetSize(220, 60)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    button:SetBackdropColor(0.85, 0.85, 0.85, 1)
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title
    local titleText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -10)
    titleText:SetText(title)
    titleText:SetTextColor(0, 0, 0, 1)
    titleText:SetShadowColor(0, 0, 0, 0)
    
    -- Description
    local descText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -5)
    descText:SetText(description)
    descText:SetTextColor(0.3, 0.3, 0.3, 1)
    descText:SetShadowColor(0, 0, 0, 0)
    
    button:SetScript("OnClick", onClick)
    
    button:SetScript("OnEnter", function()
        button:SetBackdropColor(0.95, 0.95, 0.95, 1)
    end)
    
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(0.85, 0.85, 0.85, 1)
    end)
    
    return button
end

function GroupFinder:ShowDungeonFinderSection(window)
    self.CURRENT_SECTION = "dungeon_finder"
    
    -- Clear main content properly
    for _, child in ipairs({window.mainContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Create left panel for spec selection
    local specPanel = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    specPanel:SetPoint("TOPLEFT", window.mainContent, "TOPLEFT", 0, 0)
    specPanel:SetSize(200, 400)
    specPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    specPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    specPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    specPanel:Show()
    
    -- Spec selection title
    local specTitle = specPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    specTitle:SetPoint("TOP", specPanel, "TOP", 0, -10)
    specTitle:SetText("Select Specialization")
    specTitle:SetTextColor(0, 0, 0, 1)
    specTitle:SetShadowColor(0, 0, 0, 0)
    
    -- Role checkboxes
    local tankCheck = CreateFrame("CheckButton", nil, specPanel, "UICheckButtonTemplate")
    tankCheck:SetPoint("TOPLEFT", specPanel, "TOPLEFT", 20, -40)
    tankCheck:SetSize(24, 24)
    local tankLabel = tankCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tankLabel:SetPoint("LEFT", tankCheck, "RIGHT", 5, 0)
    tankLabel:SetText("Tank")
    tankLabel:SetTextColor(0, 0, 0, 1)
    tankLabel:SetShadowColor(0, 0, 0, 0)
    
    tankCheck:SetScript("OnClick", function(self)
        GroupFinder.SELECTED_ROLE.tank = self:GetChecked()
    end)
    
    local healerCheck = CreateFrame("CheckButton", nil, specPanel, "UICheckButtonTemplate")
    healerCheck:SetPoint("TOPLEFT", tankCheck, "BOTTOMLEFT", 0, -10)
    healerCheck:SetSize(24, 24)
    local healerLabel = healerCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healerLabel:SetPoint("LEFT", healerCheck, "RIGHT", 5, 0)
    healerLabel:SetText("Healer")
    healerLabel:SetTextColor(0, 0, 0, 1)
    healerLabel:SetShadowColor(0, 0, 0, 0)
    
    healerCheck:SetScript("OnClick", function(self)
        GroupFinder.SELECTED_ROLE.healer = self:GetChecked()
    end)
    
    local damageCheck = CreateFrame("CheckButton", nil, specPanel, "UICheckButtonTemplate")
    damageCheck:SetPoint("TOPLEFT", healerCheck, "BOTTOMLEFT", 0, -10)
    damageCheck:SetSize(24, 24)
    damageCheck:SetChecked(true)
    local damageLabel = damageCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    damageLabel:SetPoint("LEFT", damageCheck, "RIGHT", 5, 0)
    damageLabel:SetText("Damage")
    damageLabel:SetTextColor(0, 0, 0, 1)
    damageLabel:SetShadowColor(0, 0, 0, 0)
    
    damageCheck:SetScript("OnClick", function(self)
        GroupFinder.SELECTED_ROLE.damage = self:GetChecked()
    end)
    
    -- Create middle panel for dungeon selection
    local dungeonPanel = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    dungeonPanel:SetPoint("TOPLEFT", specPanel, "TOPRIGHT", 10, 0)
    dungeonPanel:SetSize(300, 400)
    dungeonPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    dungeonPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    dungeonPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    dungeonPanel:Show()
    
    -- Dungeon type dropdown
    local typeLabel = dungeonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", dungeonPanel, "TOPLEFT", 10, -10)
    typeLabel:SetText("Type:")
    typeLabel:SetTextColor(0, 0, 0, 1)
    typeLabel:SetShadowColor(0, 0, 0, 0)
    
    local typeDropdown = CreateFrame("Frame", "WoW95DungeonTypeDropdown", dungeonPanel, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(typeDropdown, 250)
    UIDropDownMenu_SetText(typeDropdown, "Select Dungeon Type")
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(typeDropdown, function(self, level)
        local dungeonTypes = {
            "Random Heroic",
            "Random Normal",
            "Random Timewalking",
            "Specific Dungeons"
        }
        
        for _, dungeonType in ipairs(dungeonTypes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = dungeonType
            info.func = function()
                UIDropDownMenu_SetText(typeDropdown, dungeonType)
                GroupFinder.SELECTED_DUNGEON = dungeonType
                GroupFinder:UpdateDungeonList(dungeonPanel, dungeonType)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Dungeon list area
    local dungeonScroll = CreateFrame("ScrollFrame", nil, dungeonPanel, "UIPanelScrollFrameTemplate")
    dungeonScroll:SetPoint("TOPLEFT", typeDropdown, "BOTTOMLEFT", 15, -10)
    dungeonScroll:SetPoint("BOTTOMRIGHT", dungeonPanel, "BOTTOMRIGHT", -25, 10)
    
    local dungeonContent = CreateFrame("Frame", nil, dungeonScroll)
    dungeonContent:SetSize(250, 500)
    dungeonScroll:SetScrollChild(dungeonContent)
    
    dungeonPanel.dungeonContent = dungeonContent
    
    -- Create right panel for rewards info
    local rewardPanel = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    rewardPanel:SetPoint("TOPLEFT", dungeonPanel, "TOPRIGHT", 10, 0)
    rewardPanel:SetPoint("BOTTOMRIGHT", window.mainContent, "BOTTOMRIGHT", 0, 40)
    rewardPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    rewardPanel:SetBackdropColor(0.95, 0.95, 0.95, 1)
    rewardPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    rewardPanel:Show()
    
    -- Rewards title
    local rewardsTitle = rewardPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rewardsTitle:SetPoint("TOP", rewardPanel, "TOP", 0, -10)
    rewardsTitle:SetText("Rewards")
    rewardsTitle:SetTextColor(0, 0, 0, 1)
    
    -- Reward info
    local rewardInfo = rewardPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rewardInfo:SetPoint("TOPLEFT", rewardPanel, "TOPLEFT", 10, -40)
    rewardInfo:SetPoint("RIGHT", rewardPanel, "RIGHT", -10, 0)
    rewardInfo:SetJustifyH("LEFT")
    rewardInfo:SetText("Select a dungeon to see rewards\n\nPossible rewards:\n- Experience\n- Gold\n- Gear appropriate to your level\n- Valor Points (if eligible)")
    rewardInfo:SetTextColor(0, 0, 0, 1)
    
    -- Find Group button
    local findGroupBtn = WoW95:CreateButton("WoW95DungeonFindGroup", window.mainContent, 150, 30, "Find Group")
    findGroupBtn:SetPoint("BOTTOM", window.mainContent, "BOTTOM", 0, 5)
    findGroupBtn:Show()
    
    -- Store reference to button
    window.findGroupBtn = findGroupBtn
    
    findGroupBtn:SetScript("OnClick", function()
        self:QueueForDungeon(window)
    end)
end

function GroupFinder:UpdateDungeonList(panel, dungeonType)
    local content = panel.dungeonContent
    
    -- Clear existing content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end
    
    local dungeons = {}
    
    if dungeonType == "Specific Dungeons" then
        dungeons = {
            "The Stonevault",
            "Ara-Kara, City of Echoes",
            "City of Threads",
            "The Dawnbreaker",
            "Cinderbrew Meadery",
            "Darkflame Cleft",
            "Priory of the Sacred Flame",
            "The Rookery"
        }
    end
    
    local yOffset = -5
    for _, dungeonName in ipairs(dungeons) do
        local dungeonCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        dungeonCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
        dungeonCheck:SetSize(20, 20)
        
        local dungeonLabel = dungeonCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dungeonLabel:SetPoint("LEFT", dungeonCheck, "RIGHT", 5, 0)
        dungeonLabel:SetText(dungeonName)
        dungeonLabel:SetTextColor(0, 0, 0, 1)
        
        dungeonCheck:SetScript("OnClick", function(self)
            GroupFinder.SELECTED_DUNGEON = self:GetChecked() and dungeonName or nil
        end)
        
        yOffset = yOffset - 25
    end
end

function GroupFinder:ShowRaidFinderSection(window)
    self.CURRENT_SECTION = "raid_finder"
    
    -- Clear main content properly
    for _, child in ipairs({window.mainContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Similar to dungeon finder but with raid content
    local specPanel = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    specPanel:SetPoint("TOPLEFT", window.mainContent, "TOPLEFT", 0, 0)
    specPanel:SetSize(200, 400)
    specPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    specPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    specPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    specPanel:Show()
    
    -- Spec selection (same as dungeon finder)
    local specTitle = specPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    specTitle:SetPoint("TOP", specPanel, "TOP", 0, -10)
    specTitle:SetText("Select Specialization")
    specTitle:SetTextColor(0, 0, 0, 1)
    
    -- Create raid selection panel
    local raidPanel = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    raidPanel:SetPoint("TOPLEFT", specPanel, "TOPRIGHT", 10, 0)
    raidPanel:SetSize(300, 400)
    raidPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    raidPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    raidPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    raidPanel:Show()
    
    -- Raid dropdown
    local raidLabel = raidPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidLabel:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 10, -10)
    raidLabel:SetText("Select Raid:")
    raidLabel:SetTextColor(0, 0, 0, 1)
    
    local raidDropdown = CreateFrame("Frame", "WoW95RaidDropdown", raidPanel, "UIDropDownMenuTemplate")
    raidDropdown:SetPoint("TOPLEFT", raidLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(raidDropdown, 250)
    UIDropDownMenu_SetText(raidDropdown, "Select Raid")
    
    UIDropDownMenu_Initialize(raidDropdown, function(self, level)
        local raids = {
            "Nerub-ar Palace",
            "Amirdrassil, the Dream's Hope",
            "Aberrus, the Shadowed Crucible",
            "Vault of the Incarnates"
        }
        
        for _, raid in ipairs(raids) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = raid
            info.func = function()
                UIDropDownMenu_SetText(raidDropdown, raid)
                GroupFinder:UpdateRaidWings(raidPanel, raid)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Find Group button for raids
    local findGroupBtn = WoW95:CreateButton("WoW95RaidFindGroup", window.mainContent, 150, 30, "Find Group")
    findGroupBtn:SetPoint("BOTTOM", window.mainContent, "BOTTOM", 0, 5)
    findGroupBtn:Show()
end

function GroupFinder:UpdateRaidWings(panel, raidName)
    -- Would update the wing selection based on selected raid
end

function GroupFinder:ShowPremadeGroupsSection(window)
    self.CURRENT_SECTION = "premade_groups"
    
    -- Clear main content properly
    for _, child in ipairs({window.mainContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Create category buttons
    local categoryFrame = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    categoryFrame:SetPoint("TOPLEFT", window.mainContent, "TOPLEFT", 0, 0)
    categoryFrame:SetPoint("TOPRIGHT", window.mainContent, "TOPRIGHT", 0, 0)
    categoryFrame:SetHeight(100)
    categoryFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    categoryFrame:SetBackdropColor(0.9, 0.9, 0.9, 1)
    categoryFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    categoryFrame:Show()
    
    -- Category buttons
    local categories = {
        {id = "questing", name = "Questing"},
        {id = "delves", name = "Delves"},
        {id = "dungeons", name = "Dungeons"},
        {id = "raids_current", name = "Raids (Current)"},
        {id = "raids_legacy", name = "Raids (Legacy)"},
        {id = "custom", name = "Custom"}
    }
    
    local btnWidth = 120
    local xOffset = 10
    local yOffset = -10
    
    for i, cat in ipairs(categories) do
        local btn = WoW95:CreateButton(nil, categoryFrame, btnWidth, 30, cat.name)
        
        if i <= 3 then
            btn:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", xOffset + ((i-1) * (btnWidth + 10)), yOffset)
        else
            btn:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", xOffset + ((i-4) * (btnWidth + 10)), yOffset - 40)
        end
        
        btn:SetScript("OnClick", function()
            self.PREMADE_CATEGORY = cat.id
            self:UpdatePremadeGroupList(window, cat.id)
        end)
    end
    
    -- Group list area
    local listFrame = CreateFrame("Frame", nil, window.mainContent, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", categoryFrame, "BOTTOMLEFT", 0, -10)
    listFrame:SetPoint("BOTTOMRIGHT", window.mainContent, "BOTTOMRIGHT", 0, 50)
    listFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    listFrame:SetBackdropColor(1, 1, 1, 1)
    listFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    listFrame:Show()
    
    window.premadeListFrame = listFrame
    
    -- Action buttons
    local startGroupBtn = WoW95:CreateButton("WoW95StartGroup", window.mainContent, 150, 30, "Start a Group")
    startGroupBtn:SetPoint("BOTTOMLEFT", window.mainContent, "BOTTOMLEFT", 10, 10)
    startGroupBtn:Show()
    
    startGroupBtn:SetScript("OnClick", function()
        self:ShowStartGroupDialog(window)
    end)
    
    local findGroupBtn = WoW95:CreateButton("WoW95FindPremadeGroup", window.mainContent, 150, 30, "Find a Group")
    findGroupBtn:SetPoint("BOTTOMRIGHT", window.mainContent, "BOTTOMRIGHT", -10, 10)
    findGroupBtn:Show()
    
    findGroupBtn:SetScript("OnClick", function()
        self:SearchPremadeGroups(window)
    end)
    
    -- Show default category
    self:UpdatePremadeGroupList(window, "dungeons")
end

function GroupFinder:UpdatePremadeGroupList(window, category)
    local listFrame = window.premadeListFrame
    if not listFrame then return end
    
    -- Clear existing content
    for _, child in ipairs({listFrame:GetChildren()}) do
        child:Hide()
    end
    
    -- Sample groups based on category
    local groups = {}
    
    if category == "dungeons" then
        groups = {
            {name = "M+15 Push Group", leader = "Tankmaster", members = "3/5", ilvl = "480+"},
            {name = "Weekly Key", leader = "Healpro", members = "4/5", ilvl = "460+"},
            {name = "Learning M+ Chill", leader = "Newbie", members = "2/5", ilvl = "440+"}
        }
    elseif category == "raids_current" then
        groups = {
            {name = "Nerub HC Fresh", leader = "RaidLead", members = "18/20", ilvl = "470+"},
            {name = "Last 2 bosses Heroic", leader = "Experienced", members = "15/20", ilvl = "480+"}
        }
    end
    
    -- Create group entries
    local yOffset = -10
    for _, group in ipairs(groups) do
        local groupFrame = CreateFrame("Button", nil, listFrame, "BackdropTemplate")
        groupFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 10, yOffset)
        groupFrame:SetPoint("RIGHT", listFrame, "RIGHT", -10, 0)
        groupFrame:SetHeight(50)
        groupFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        groupFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
        groupFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        -- Group name
        local nameText = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 10, -8)
        nameText:SetText(group.name)
        nameText:SetTextColor(0, 0, 0, 1)
        
        -- Leader and iLvl
        local infoText = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
        infoText:SetText("Leader: " .. group.leader .. " | " .. group.ilvl)
        infoText:SetTextColor(0.4, 0.4, 0.4, 1)
        
        -- Members
        local membersText = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        membersText:SetPoint("RIGHT", groupFrame, "RIGHT", -10, 0)
        membersText:SetText(group.members)
        membersText:SetTextColor(0, 0.5, 0, 1)
        
        groupFrame:SetScript("OnEnter", function()
            groupFrame:SetBackdropColor(0.85, 0.85, 1, 1)
        end)
        
        groupFrame:SetScript("OnLeave", function()
            groupFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
        end)
        
        yOffset = yOffset - 55
    end
end

function GroupFinder:ShowStartGroupDialog(window)
    -- Would show a dialog to create a new group listing
    WoW95:Print("Start a Group dialog would appear here")
end

function GroupFinder:SearchPremadeGroups(window)
    -- Would refresh the group list
    WoW95:Print("Searching for groups...")
    self:UpdatePremadeGroupList(window, self.PREMADE_CATEGORY)
end

function GroupFinder:QueueForDungeon(window)
    -- Check if roles are selected
    local hasRole = self.SELECTED_ROLE.tank or self.SELECTED_ROLE.healer or self.SELECTED_ROLE.damage
    
    if not hasRole then
        WoW95:Print("You must select at least one role")
        return
    end
    
    -- Check if dungeon is selected
    if not self.SELECTED_DUNGEON then
        WoW95:Print("Please select a dungeon type first")
        return
    end
    
    -- Start queue simulation
    self.IN_QUEUE = true
    WoW95:Print("Queuing for " .. self.SELECTED_DUNGEON .. "...")
    
    -- Update button to show queue status
    if window.findGroupBtn then
        window.findGroupBtn:SetText("Leave Queue")
        window.findGroupBtn:SetScript("OnClick", function()
            self:LeaveQueue(window)
        end)
    end
    
    -- Simulate finding a group after a delay
    C_Timer.After(5, function()
        if self.IN_QUEUE then
            WoW95:Print("Group found! Ready check initiated.")
            self:LeaveQueue(window)
        end
    end)
end

function GroupFinder:LeaveQueue(window)
    self.IN_QUEUE = false
    WoW95:Print("Left the queue")
    
    -- Reset button
    if window.findGroupBtn then
        window.findGroupBtn:SetText("Find Group")
        window.findGroupBtn:SetScript("OnClick", function()
            self:QueueForDungeon(window)
        end)
    end
end

function GroupFinder:ShowPvPTab(window)
    -- Clear content
    for _, child in ipairs({window.contentArea:GetChildren()}) do
        child:Hide()
    end
    
    local text = window.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("PvP Content\n\nComing Soon")
    text:SetTextColor(0, 0, 0, 1)
    text:Show()
end

function GroupFinder:ShowMythicPlusTab(window)
    -- Clear content
    for _, child in ipairs({window.contentArea:GetChildren()}) do
        child:Hide()
    end
    
    local text = window.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Mythic+ Content\n\nComing Soon")
    text:SetTextColor(0, 0, 0, 1)
    text:Show()
end

function GroupFinder:ShowDelvesTab(window)
    -- Clear content
    for _, child in ipairs({window.contentArea:GetChildren()}) do
        child:Hide()
    end
    
    local text = window.contentArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Delves Content\n\nComing Soon")
    text:SetTextColor(0, 0, 0, 1)
    text:Show()
end

-- Register module
WoW95:RegisterModule("GroupFinder", GroupFinder)