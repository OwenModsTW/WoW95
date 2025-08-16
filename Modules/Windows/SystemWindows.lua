-- WoW95 System Windows Module
-- GameMenu, Interface Options, and other system windows with Windows 95 styling

local addonName, WoW95 = ...

local SystemWindows = {}
WoW95.SystemWindows = SystemWindows

-- Supported system frames
local SYSTEM_FRAMES = {
    -- ["GameMenuFrame"] = "CreateGameMenuWindow",  -- DISABLED - Keep vanilla game menu for logout/exit
    ["InterfaceOptionsFrame"] = "CreateInterfaceOptionsWindow",
    ["EncounterJournal"] = "CreateEncounterJournalWindow"
}

function SystemWindows:CreateWindow(frameName, program)
    -- Check if we handle this frame type
    local createMethod = SYSTEM_FRAMES[frameName]
    if not createMethod or not self[createMethod] then
        WoW95:Debug("Unsupported system frame: " .. frameName)
        return nil
    end
    
    -- Don't create duplicate windows - show existing one if it exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug(frameName .. " window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    -- Call the appropriate creation method
    return self[createMethod](self, frameName, program)
end

function SystemWindows:CreateGameMenuWindow(frameName, program)
    WoW95:Debug("Creating Game Menu window: " .. frameName)
    
    -- Create the main game menu window using the core window creation
    local gameMenuWindow = WoW95:CreateWindow(
        "WoW95GameMenu", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    gameMenuWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(gameMenuWindow)
    
    -- Create game menu content
    self:CreateGameMenuContent(gameMenuWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(gameMenuWindow, frameName, program, contentArea)
end

function SystemWindows:CreateInterfaceOptionsWindow(frameName, program)
    WoW95:Debug("Creating Interface Options window: " .. frameName)
    
    -- Create the main interface options window using the core window creation
    local optionsWindow = WoW95:CreateWindow(
        "WoW95InterfaceOptions", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    optionsWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(optionsWindow)
    
    -- Create interface options content
    self:CreateInterfaceOptionsContent(optionsWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(optionsWindow, frameName, program, contentArea)
end

function SystemWindows:CreateEncounterJournalWindow(frameName, program)
    WoW95:Debug("Creating Encounter Journal window: " .. frameName)
    
    -- Create the main encounter journal window using the core window creation
    local journalWindow = WoW95:CreateWindow(
        "WoW95EncounterJournal", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    journalWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(journalWindow)
    
    -- Create encounter journal content
    self:CreateEncounterJournalContent(journalWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(journalWindow, frameName, program, contentArea)
end

function SystemWindows:CreateContentArea(window)
    -- Create main content area with Windows 95 styling
    local contentArea = CreateFrame("Frame", nil, window, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -30)
    contentArea:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -8, 8)
    
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
    
    return contentArea
end

function SystemWindows:CreateGameMenuContent(gameMenuWindow, contentArea)
    -- Game menu title
    local title = contentArea:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", contentArea, "TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetText("Game Menu")
    title:SetTextColor(0, 0, 0, 1)
    
    -- Create menu buttons
    local buttonHeight = 30
    local buttonSpacing = 5
    local yOffset = 50
    
    -- Menu button data
    local menuButtons = {
        {text = "Continue Game", onClick = function() gameMenuWindow:Hide() end},
        {text = "Settings", onClick = function() WoW95:Print("Settings (placeholder)") end},
        {text = "System", onClick = function() WoW95:Print("System (placeholder)") end},
        {text = "Help", onClick = function() WoW95:Print("Help (placeholder)") end},
        {text = "Logout", onClick = function() Logout() end},
        {text = "Exit Game", onClick = function() Quit() end}
    }
    
    -- Create each menu button
    for i, buttonData in ipairs(menuButtons) do
        local button = WoW95:CreateButton(
            "GameMenuBtn" .. i, 
            contentArea, 
            200, 
            buttonHeight, 
            buttonData.text
        )
        button:SetPoint("TOP", contentArea, "TOP", 0, -yOffset)
        button:SetScript("OnClick", buttonData.onClick)
        
        yOffset = yOffset + buttonHeight + buttonSpacing
    end
    
    -- Game info panel
    local infoPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    infoPanel:SetPoint("BOTTOM", contentArea, "BOTTOM", 0, 20)
    infoPanel:SetSize(contentArea:GetWidth() - 20, 40)
    
    infoPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    infoPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    infoPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Character info
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    local charClass = UnitClass("player")
    local realm = GetRealmName()
    
    local charInfo = infoPanel:CreateFontString(nil, "OVERLAY")
    charInfo:SetPoint("LEFT", infoPanel, "LEFT", 10, 5)
    charInfo:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    charInfo:SetText(string.format("%s - Level %d %s", charName, charLevel, charClass))
    charInfo:SetTextColor(0, 0, 0, 1)
    
    local realmInfo = infoPanel:CreateFontString(nil, "OVERLAY")
    realmInfo:SetPoint("LEFT", infoPanel, "LEFT", 10, -5)
    realmInfo:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    realmInfo:SetText("Realm: " .. realm)
    realmInfo:SetTextColor(0, 0, 0, 1)
    
    -- Store references
    gameMenuWindow.infoPanel = infoPanel
    
    WoW95:Debug("Created game menu content")
end

function SystemWindows:CreateInterfaceOptionsContent(optionsWindow, contentArea)
    -- Options title
    local title = contentArea:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", contentArea, "TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetText("Interface Options")
    title:SetTextColor(0, 0, 0, 1)
    
    -- Categories panel (left side)
    local categoriesPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    categoriesPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -40)
    categoriesPanel:SetSize(150, contentArea:GetHeight() - 100)
    
    categoriesPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    categoriesPanel:SetBackdropColor(0.95, 0.95, 0.95, 1)
    categoriesPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Categories title
    local catTitle = categoriesPanel:CreateFontString(nil, "OVERLAY")
    catTitle:SetPoint("TOP", categoriesPanel, "TOP", 0, -10)
    catTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    catTitle:SetText("Categories")
    catTitle:SetTextColor(0, 0, 0, 1)
    
    -- Settings panel (right side)
    local settingsPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    settingsPanel:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", -10, -40)
    settingsPanel:SetSize(contentArea:GetWidth() - 180, contentArea:GetHeight() - 100)
    
    settingsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    settingsPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    settingsPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Settings placeholder
    local settingsTitle = settingsPanel:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetPoint("TOP", settingsPanel, "TOP", 0, -10)
    settingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    settingsTitle:SetText("Settings")
    settingsTitle:SetTextColor(0, 0, 0, 1)
    
    local placeholderText = settingsPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", settingsPanel, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("Interface Options\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Control buttons at bottom
    local buttonPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    buttonPanel:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 10, 10)
    buttonPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 10)
    buttonPanel:SetHeight(30)
    
    buttonPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    buttonPanel:SetBackdropColor(0.75, 0.75, 0.75, 1)
    buttonPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- OK button
    local okBtn = WoW95:CreateButton("OptionsOKBtn", buttonPanel, 60, 22, "OK")
    okBtn:SetPoint("RIGHT", buttonPanel, "RIGHT", -70, 0)
    okBtn:SetScript("OnClick", function()
        optionsWindow:Hide()
    end)
    
    -- Cancel button
    local cancelBtn = WoW95:CreateButton("OptionsCancelBtn", buttonPanel, 60, 22, "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -5, 0)
    cancelBtn:SetScript("OnClick", function()
        optionsWindow:Hide()
    end)
    
    -- Store references
    optionsWindow.categoriesPanel = categoriesPanel
    optionsWindow.settingsPanel = settingsPanel
    optionsWindow.buttonPanel = buttonPanel
    
    WoW95:Debug("Created interface options content")
end

function SystemWindows:CreateEncounterJournalContent(journalWindow, contentArea)
    -- Journal title
    local title = contentArea:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", contentArea, "TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetText("Dungeon Journal")
    title:SetTextColor(0, 0, 0, 1)
    
    -- Dungeon/Raid selection panel (left side)
    local dungeonPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    dungeonPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -40)
    dungeonPanel:SetSize(180, contentArea:GetHeight() - 50)
    
    dungeonPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    dungeonPanel:SetBackdropColor(0.95, 0.95, 0.95, 1)
    dungeonPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Dungeon list title
    local dungeonTitle = dungeonPanel:CreateFontString(nil, "OVERLAY")
    dungeonTitle:SetPoint("TOP", dungeonPanel, "TOP", 0, -10)
    dungeonTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    dungeonTitle:SetText("Dungeons & Raids")
    dungeonTitle:SetTextColor(0, 0, 0, 1)
    
    -- Encounter details panel (right side)
    local detailsPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    detailsPanel:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", -10, -40)
    detailsPanel:SetSize(contentArea:GetWidth() - 210, contentArea:GetHeight() - 50)
    
    detailsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    detailsPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    detailsPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Details placeholder
    local detailsTitle = detailsPanel:CreateFontString(nil, "OVERLAY")
    detailsTitle:SetPoint("TOP", detailsPanel, "TOP", 0, -10)
    detailsTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    detailsTitle:SetText("Encounter Details")
    detailsTitle:SetTextColor(0, 0, 0, 1)
    
    local placeholderText = detailsPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", detailsPanel, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("Dungeon Journal\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Store references
    journalWindow.dungeonPanel = dungeonPanel
    journalWindow.detailsPanel = detailsPanel
    
    WoW95:Debug("Created encounter journal content")
end

function SystemWindows:FinalizeWindow(window, frameName, program, contentArea)
    -- Store references
    window.contentArea = contentArea
    window.programName = program.name
    window.frameName = frameName
    window.isWoW95Window = true
    window.isProgramWindow = true
    
    -- Store reference in WindowsCore
    WoW95.WindowsCore:StoreProgramWindow(frameName, window)
    
    -- Add a custom hide script to ensure proper cleanup when closed by other means
    window:HookScript("OnHide", function()
        WoW95:Debug(frameName .. " window hidden, cleaning up tracking")
        WoW95.WindowsCore:RemoveProgramWindow(frameName)
        -- Ensure the Blizzard frame is also hidden to prevent state mismatch
        local blizzardFrame = _G[frameName]
        if blizzardFrame and blizzardFrame:IsShown() then
            blizzardFrame:Hide()
        end
    end)
    
    -- Show the window
    window:Show()
    
    -- Notify taskbar
    WoW95:OnWindowOpened(window)
    
    WoW95:Print(program.name .. " window created successfully!")
    return window
end

-- Register the module
WoW95:RegisterModule("SystemWindows", SystemWindows)