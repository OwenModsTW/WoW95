-- WoW95 Settings Module
-- User interface for toggling modules and configuring addon settings

local addonName, WoW95 = ...

local Settings = {}
WoW95.Settings = Settings

-- Default settings for all modules
Settings.defaultSettings = {
    -- Core modules
    questTracker = true,
    minimap = true,
    taskbar = true,
    startMenu = true,
    actionBars = true,
    
    -- Windows modules
    mapWindow = true,
    guildWindow = true,
    characterWindow = true,
    questWindow = true,
    achievementsWindow = true,
    socialWindows = true,
    systemWindows = true,
    
    -- Optional modules
    tooltip = true,
    microMenu = true,
    bags = true,
    spellbook = true,
    games = true,
    
    -- Disabled modules (for future releases)
    groupFinderReskin = false,
    chat = false,
    
    -- Debug settings
    debug = false
}

function Settings:Init()
    WoW95:Debug("Initializing Settings module...")
    
    -- Initialize WoW95DB if it doesn't exist (saved variables not loaded yet)
    if not WoW95DB then
        WoW95DB = {}
    end
    
    -- Initialize settings from saved variables or defaults
    if not WoW95DB.settings then
        WoW95DB.settings = {}
    end
    
    -- Merge defaults with saved settings
    for key, defaultValue in pairs(self.defaultSettings) do
        if WoW95DB.settings[key] == nil then
            WoW95DB.settings[key] = defaultValue
        end
    end
    
    -- Apply current settings to WoW95.settings
    WoW95.settings = WoW95DB.settings
    
    WoW95:Debug("Settings initialized successfully")
end

function Settings:CreateSettingsWindow()
    WoW95:Debug("Creating Settings window...")
    
    -- Check if window already exists
    if self.settingsWindow and self.settingsWindow:IsShown() then
        self.settingsWindow:Hide()
        return
    end
    
    -- Create main settings window
    local window = WoW95:CreateWindow("WoW95SettingsWindow", UIParent, 500, 600, "WoW95 Settings")
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:Show()
    
    -- Create content area
    local content = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 15, -40)
    content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -35, 50)
    
    -- Create scrollable content
    local scrollChild = CreateFrame("Frame", nil, content)
    scrollChild:SetSize(450, 800)
    content:SetScrollChild(scrollChild)
    
    -- Add title
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", scrollChild, "TOP", 0, -10)
    title:SetText("Module Settings")
    title:SetTextColor(unpack(WoW95.colors.titleBarText))
    
    -- Create module sections
    local yOffset = -50
    yOffset = self:CreateModuleSection(scrollChild, "Core Modules", {
        {key = "questTracker", name = "Quest Tracker", desc = "Windows 95 styled quest objective tracker"},
        {key = "minimap", name = "Minimap", desc = "Square minimap with Windows 95 styling"},
        {key = "taskbar", name = "Taskbar", desc = "Windows 95 taskbar with program buttons"},
        {key = "startMenu", name = "Start Menu", desc = "Classic Windows 95 start menu"},
        {key = "actionBars", name = "Action Bars", desc = "Windows 95 styled action bars"}
    }, yOffset)
    
    yOffset = yOffset - 40
    yOffset = self:CreateModuleSection(scrollChild, "Window Modules", {
        {key = "mapWindow", name = "Map Window", desc = "Windows 95 styled world map"},
        {key = "guildWindow", name = "Guild Window", desc = "Guild & Communities interface"},
        {key = "characterWindow", name = "Character Window", desc = "Character sheet interface"},
        {key = "questWindow", name = "Quest Log", desc = "Quest log interface"},
        {key = "achievementsWindow", name = "Achievements", desc = "Achievements interface"},
        {key = "socialWindows", name = "Social Windows", desc = "Friends and social interfaces"}
    }, yOffset)
    
    yOffset = yOffset - 40
    yOffset = self:CreateModuleSection(scrollChild, "Optional Modules", {
        {key = "tooltip", name = "Tooltips", desc = "Windows 95 styled tooltips"},
        {key = "microMenu", name = "Micro Menu", desc = "Windows 95 styled micro buttons"},
        {key = "bags", name = "Bags", desc = "Inventory bag styling"},
        {key = "games", name = "Games", desc = "Built-in mini-games (Solitaire, etc.)"},
        {key = "debug", name = "Debug Mode", desc = "Enable debug output in chat"}
    }, yOffset)
    
    -- Add save and reload buttons
    local saveButton = WoW95:CreateButton("SaveSettings", window, 150, 30, "Save & Reload UI")
    saveButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 15)
    saveButton:SetScript("OnClick", function()
        self:SaveAndReload()
    end)
    
    local cancelButton = WoW95:CreateButton("CancelSettings", window, 100, 30, "Cancel")
    cancelButton:SetPoint("BOTTOMRIGHT", saveButton, "BOTTOMLEFT", -10, 0)
    cancelButton:SetScript("OnClick", function()
        window:Hide()
    end)
    
    self.settingsWindow = window
    WoW95:Debug("Settings window created successfully")
    return window
end

function Settings:CreateModuleSection(parent, sectionTitle, modules, yOffset)
    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText(sectionTitle)
    header:SetTextColor(unpack(WoW95.colors.titleBar))
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    
    yOffset = yOffset - 25
    
    -- Create checkboxes for each module
    for _, module in ipairs(modules) do
        local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
        checkbox:SetSize(20, 20)
        
        -- Set initial state
        checkbox:SetChecked(WoW95.settings[module.key] or false)
        
        -- Store reference for saving
        checkbox.settingKey = module.key
        
        -- Module name
        local nameText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        nameText:SetText(module.name)
        nameText:SetTextColor(unpack(WoW95.colors.text))
        
        -- Module description
        local descText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
        descText:SetText(module.desc)
        descText:SetTextColor(0.7, 0.7, 0.7, 1)
        descText:SetWidth(350)
        descText:SetJustifyH("LEFT")
        
        -- Store checkbox for later reference
        if not self.checkboxes then
            self.checkboxes = {}
        end
        self.checkboxes[module.key] = checkbox
        
        yOffset = yOffset - 50
    end
    
    return yOffset
end

function Settings:SaveAndReload()
    WoW95:Debug("Saving settings and reloading UI...")
    
    -- Ensure WoW95DB exists
    if not WoW95DB then
        WoW95DB = {}
    end
    if not WoW95DB.settings then
        WoW95DB.settings = {}
    end
    
    -- Collect all checkbox states
    if self.checkboxes then
        for key, checkbox in pairs(self.checkboxes) do
            WoW95.settings[key] = checkbox:GetChecked()
            WoW95DB.settings[key] = checkbox:GetChecked()
        end
    end
    
    -- Show confirmation message
    WoW95:Print("Settings saved! Reloading UI...")
    
    -- Close settings window
    if self.settingsWindow then
        self.settingsWindow:Hide()
    end
    
    -- Reload the UI after a short delay
    C_Timer.After(1, function()
        ReloadUI()
    end)
end

function Settings:GetSetting(key)
    return WoW95.settings[key]
end

function Settings:SetSetting(key, value)
    WoW95.settings[key] = value
    
    -- Ensure WoW95DB exists
    if not WoW95DB then
        WoW95DB = {}
    end
    if not WoW95DB.settings then
        WoW95DB.settings = {}
    end
    
    WoW95DB.settings[key] = value
end

-- Slash command to open settings
SLASH_WOW95SETTINGS1 = "/wow95settings"
SLASH_WOW95SETTINGS2 = "/w95settings"
SlashCmdList["WOW95SETTINGS"] = function(msg)
    WoW95.Settings:CreateSettingsWindow()
end

-- Register the module
WoW95:RegisterModule("Settings", Settings)