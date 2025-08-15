-- WoW95 MicroMenu Module
-- Windows 95 styled micro menu buttons

local addonName, WoW95 = ...

local MicroMenu = {}
WoW95.MicroMenu = MicroMenu

-- MicroMenu settings
local BUTTON_SIZE = 24  -- Slightly larger for better visibility
local BUTTON_SPACING = 2  -- More spacing between buttons
local PANEL_PADDING = 4   -- More padding around panel
local PANEL_HEIGHT = BUTTON_SIZE + (PANEL_PADDING * 2)

-- MicroMenu state
MicroMenu.frame = nil
MicroMenu.buttons = {}
MicroMenu.toggleButton = nil
MicroMenu.isVisible = true
MicroMenu.isMinimized = false

-- Micro menu button definitions
local MICRO_BUTTONS = {
    {
        name = "Character",
        texture = "Interface\\Icons\\INV_Misc_Note_01",
        onClick = function() ToggleCharacter("PaperDollFrame") end,
        tooltip = "Character Info",
        shortcut = "C"
    },
    {
        name = "SpellsTalents",
        texture = "Interface\\Icons\\INV_Misc_Book_09",
        onClick = function() 
            -- Use our custom spellbook module
            if WoW95.Spellbook then
                WoW95.Spellbook:ToggleSpellbook()
            else
                -- Fallback to Blizzard frame
                if SpellBookFrame then
                    if SpellBookFrame:IsVisible() then
                        SpellBookFrame:Hide()
                    else
                        ShowUIPanel(SpellBookFrame)
                    end
                end
            end
        end,
        tooltip = "Spells & Talents",
        shortcut = "P"
    },
    {
        name = "Achievements",
        texture = "Interface\\Icons\\Achievement_General_StayClassy",
        onClick = function() ToggleAchievementFrame() end,
        tooltip = "Achievements",
        shortcut = "Y"
    },
    {
        name = "Quest",
        texture = "Interface\\Icons\\INV_Misc_Note_04",
        onClick = function() ToggleQuestLog() end,
        tooltip = "Quest Log",
        shortcut = "L"
    },
    {
        name = "Guild",
        texture = "Interface\\Icons\\INV_Banner_02",
        onClick = function() ToggleGuildFrame() end,
        tooltip = "Guild & Communities",
        shortcut = "J"
    },
    {
        name = "LFD",
        texture = "Interface\\Icons\\INV_Helmet_08",
        onClick = function() PVEFrame_ToggleFrame() end,
        tooltip = "Group Finder",
        shortcut = "I"
    },
    {
        name = "Collections",
        texture = "Interface\\Icons\\Ability_Mount_RidingHorse",
        onClick = function() ToggleCollectionsJournal() end,
        tooltip = "Collections",
        shortcut = "Shift+P"
    },
    {
        name = "Adventure",
        texture = "Interface\\Icons\\INV_Misc_Map02",
        onClick = function() ToggleEncounterJournal() end,
        tooltip = "Adventure Guide",
        shortcut = "Shift+J"
    },
    {
        name = "MainMenu",
        texture = "Interface\\Icons\\INV_Gizmo_02",
        onClick = function() ToggleGameMenu() end,
        tooltip = "Main Menu",
        shortcut = "Esc"
    },
    {
        name = "Help",
        texture = "Interface\\Icons\\INV_Misc_QuestionMark",
        onClick = function() ToggleHelpFrame() end,
        tooltip = "Help",
        shortcut = ""
    }
}

function MicroMenu:Init()
    WoW95:Debug("Initializing MicroMenu module...")
    
    -- Hide default Blizzard micro menu
    self:HideBlizzardMicroMenu()
    
    -- Create our Windows 95 micro menu
    self:CreateMicroMenuFrame()
    
    -- Position it above the time
    self:PositionMicroMenu()
    
    WoW95:Debug("MicroMenu module initialized successfully!")
end

function MicroMenu:CreateMicroMenuFrame()
    -- Main micro menu panel
    self.frame = CreateFrame("Frame", "WoW95MicroMenuFrame", UIParent, "BackdropTemplate")
    
    -- Calculate panel width based on number of buttons
    local panelWidth = (#MICRO_BUTTONS * BUTTON_SIZE) + ((#MICRO_BUTTONS - 1) * BUTTON_SPACING) + (PANEL_PADDING * 2)
    
    self.frame:SetSize(panelWidth, PANEL_HEIGHT)
    self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -35, 35) -- Move further left to accommodate toggle
    self.frame:SetFrameStrata("LOW")
    self.frame:SetFrameLevel(1)
    
    -- Windows 95 panel backdrop
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.frame:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Create micro menu buttons
    self:CreateMicroButtons()
    
    -- Create minimize/maximize toggle button
    self:CreateToggleButton()
end

function MicroMenu:CreateMicroButtons()
    for i, buttonData in ipairs(MICRO_BUTTONS) do
        local button = CreateFrame("Button", "WoW95MicroButton" .. buttonData.name, self.frame, "BackdropTemplate")
        button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        
        -- Position button in the panel
        local xOffset = PANEL_PADDING + ((i - 1) * (BUTTON_SIZE + BUTTON_SPACING))
        button:SetPoint("LEFT", self.frame, "LEFT", xOffset, 0)
        
        -- Windows 95 button backdrop
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        button:SetBackdropColor(0.75, 0.75, 0.75, 1)
        button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        -- Button icon
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        icon:SetSize(BUTTON_SIZE, BUTTON_SIZE)  -- Full button size for better fill
        icon:SetTexture(buttonData.texture)
        icon:SetTexCoord(0, 1, 0, 1)  -- No cropping - use full texture
        
        -- Store references
        button.icon = icon
        button.buttonData = buttonData
        
        -- Click handling
        button:RegisterForClicks("AnyUp")
        button:SetScript("OnClick", function(self, buttonPressed, down)
            if InCombatLockdown() and buttonData.name == "Talents" then 
                WoW95:Debug("Cannot open talents in combat")
                return 
            end
            
            -- Windows 95 button press effect
            if buttonPressed == "LeftButton" then
                self:SetBackdropColor(0.6, 0.6, 0.6, 1)
                C_Timer.After(0.1, function()
                    if self then
                        self:SetBackdropColor(0.75, 0.75, 0.75, 1)
                    end
                end)
                
                -- Execute button function
                if buttonData.onClick then
                    buttonData.onClick()
                end
            end
        end)
        
        -- Hover effects
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.9, 0.9, 0.9, 1)
            self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
            
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(buttonData.tooltip)
            if buttonData.shortcut and buttonData.shortcut ~= "" then
                GameTooltip:AddLine("Shortcut: " .. buttonData.shortcut, 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.75, 0.75, 0.75, 1)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            GameTooltip:Hide()
        end)
        
        -- Store button reference
        self.buttons[buttonData.name] = button
    end
end

function MicroMenu:CreateToggleButton()
    -- Create toggle button to the right of the micro menu
    self.toggleButton = CreateFrame("Button", "WoW95MicroMenuToggle", UIParent, "BackdropTemplate")
    self.toggleButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    self.toggleButton:SetPoint("LEFT", self.frame, "RIGHT", 2, 0)
    
    -- Windows 95 button backdrop
    self.toggleButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.toggleButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.toggleButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Toggle button icon (minimize symbol)
    local toggleIcon = self.toggleButton:CreateTexture(nil, "ARTWORK")
    toggleIcon:SetPoint("CENTER", self.toggleButton, "CENTER", 0, 0)
    toggleIcon:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    toggleIcon:SetTexture("Interface\\Icons\\INV_Misc_ArrowLeft")
    toggleIcon:SetTexCoord(0, 1, 0, 1)
    
    -- Store icon reference
    self.toggleButton.icon = toggleIcon
    
    -- Click handling
    self.toggleButton:RegisterForClicks("AnyUp")
    self.toggleButton:SetScript("OnClick", function(self, buttonPressed, down)
        if buttonPressed == "LeftButton" then
            -- Windows 95 button press effect
            self:SetBackdropColor(0.5, 0.5, 0.5, 1)
            self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
            C_Timer.After(0.15, function()
                if self then
                    self:SetBackdropColor(0.75, 0.75, 0.75, 1)
                    self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                end
            end)
            
            -- Toggle minimize/maximize
            MicroMenu:ToggleMinimize()
        end
    end)
    
    -- Hover effects
    self.toggleButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.9, 0.9, 0.9, 1)
        self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        
        -- Show tooltip
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if MicroMenu.isMinimized then
            GameTooltip:SetText("Show Micro Menu")
        else
            GameTooltip:SetText("Hide Micro Menu")
        end
        GameTooltip:Show()
    end)
    
    self.toggleButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.75, 0.75, 0.75, 1)
        self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        GameTooltip:Hide()
    end)
end

function MicroMenu:ToggleMinimize()
    self.isMinimized = not self.isMinimized
    
    if self.isMinimized then
        -- Hide all micro buttons
        for _, button in pairs(self.buttons) do
            button:Hide()
        end
        
        -- Hide the main panel completely when minimized
        self.frame:Hide()
        
        -- Position toggle button independently when minimized
        self.toggleButton:ClearAllPoints()
        if WoW95.Time and WoW95.Time.frame then
            self.toggleButton:SetPoint("BOTTOMRIGHT", WoW95.Time.frame, "TOPRIGHT", 0, 2)
        else
            self.toggleButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 35)
        end
        
        -- Change toggle icon to show (right arrow)
        self.toggleButton.icon:SetTexture("Interface\\Icons\\INV_Misc_ArrowRight")
        
        WoW95:Debug("Minimized micro menu")
    else
        -- Show the main panel
        self.frame:Show()
        
        -- Reposition toggle button back to the right of the panel
        self.toggleButton:ClearAllPoints()
        self.toggleButton:SetPoint("LEFT", self.frame, "RIGHT", 2, 0)
        
        -- Show all micro buttons
        for _, button in pairs(self.buttons) do
            button:Show()
        end
        
        -- Change toggle icon to hide (left arrow)
        self.toggleButton.icon:SetTexture("Interface\\Icons\\INV_Misc_ArrowLeft")
        
        WoW95:Debug("Maximized micro menu")
    end
end

function MicroMenu:PositionMicroMenu()
    -- Position above the time display (if WoW95 time module exists)
    if WoW95.Time and WoW95.Time.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOMRIGHT", WoW95.Time.frame, "TOPRIGHT", -25, 2)  -- Account for toggle button
    else
        -- Fallback position
        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -35, 35)  -- Account for toggle button
    end
end

function MicroMenu:HideBlizzardMicroMenu()
    -- Hide default Blizzard micro menu buttons safely
    local blizzardMicroButtons = {
        "CharacterMicroButton",
        "SpellbookMicroButton", 
        "TalentMicroButton",
        "AchievementMicroButton",
        "QuestLogMicroButton",
        "GuildMicroButton",
        "LFDMicroButton",
        "CollectionsMicroButton",
        "EJMicroButton",
        "StoreMicroButton",
        "MainMenuMicroButton",
        "HelpMicroButton"
    }
    
    for _, buttonName in ipairs(blizzardMicroButtons) do
        local button = _G[buttonName]
        if button and type(button) == "table" then
            -- Use pcall to safely hide buttons that might have positioning issues
            local success, err = pcall(function()
                if button.Hide then button:Hide() end
            end)
            if not success then
                WoW95:Debug("Failed to hide " .. buttonName .. ": " .. tostring(err))
                -- Fallback - just make it invisible
                if button.SetAlpha then button:SetAlpha(0) end
            end
            
            if button.SetAlpha then button:SetAlpha(0) end
            if button.SetScript then 
                button:SetScript("OnShow", function() 
                    pcall(function() button:Hide() end)
                    button:SetAlpha(0) 
                end)
                button:SetScript("OnEvent", nil)
            end
            if button.UnregisterAllEvents then button:UnregisterAllEvents() end
        end
    end
    
    -- Handle micro menu containers more carefully
    local containers = {
        "MicroButtonAndBagsBar",
        "MicroMenuContainer", -- This is likely the problematic one
        "MicroMenu",
        "MicroButton",
        "MainMenuBarMicroButton"
    }
    
    for _, containerName in ipairs(containers) do
        local container = _G[containerName]
        if container and type(container) == "table" then
            WoW95:Debug("Attempting to hide container: " .. containerName)
            
            -- Use pcall to safely hide containers that might have positioning issues
            local success, err = pcall(function()
                if container.Hide then 
                    container:Hide() 
                end
            end)
            
            if not success then
                WoW95:Debug("Failed to hide " .. containerName .. ": " .. tostring(err))
                -- Instead of hiding, just make it completely invisible and unusable
                if container.SetAlpha then container:SetAlpha(0) end
                if container.SetScale then container:SetScale(0.01) end -- Make it tiny
            end
            
            -- Always make it invisible regardless of hide success
            if container.SetAlpha then container:SetAlpha(0) end
            
            -- Prevent it from showing again
            if container.SetScript then 
                container:SetScript("OnShow", function() 
                    container:SetAlpha(0)
                    if container.SetScale then container:SetScale(0.01) end
                end)
            end
        end
    end
    
    -- Also try to hide any remaining micro buttons by checking globals more safely
    for name, obj in pairs(_G) do
        if type(obj) == "table" and obj.GetObjectType and type(obj.GetObjectType) == "function" then
            local success, objType = pcall(obj.GetObjectType, obj)
            if success and objType == "Button" then
                if name:find("MicroButton") or (name:find("Micro") and name:find("Button")) then
                    if obj ~= self.frame and not name:find("WoW95") then
                        -- Use pcall for safe hiding
                        pcall(function()
                            if obj.Hide then obj:Hide() end
                        end)
                        if obj.SetAlpha then obj:SetAlpha(0) end
                        if obj.SetScript then 
                            obj:SetScript("OnShow", function() 
                                obj:SetAlpha(0) 
                                pcall(function() obj:Hide() end)
                            end) 
                        end
                    end
                end
            end
        end
    end
    
    WoW95:Debug("Hidden Blizzard micro menu")
end

function MicroMenu:Show()
    if self.frame then
        self.frame:Show()
        self.isVisible = true
        WoW95:Debug("Showed micro menu")
    end
end

function MicroMenu:Hide()
    if self.frame then
        self.frame:Hide()
        self.isVisible = false
        WoW95:Debug("Hidden micro menu")
    end
end

function MicroMenu:Toggle()
    if self.isVisible then
        self:Hide()
    else
        self:Show()
    end
end

function MicroMenu:UpdateButtonStates()
    -- Update button states based on current UI state
    for buttonName, button in pairs(self.buttons) do
        local buttonData = button.buttonData
        
        -- Special handling for certain buttons
        if buttonName == "Character" then
            if CharacterFrame and CharacterFrame:IsShown() then
                button:SetBackdropColor(0.6, 0.6, 0.6, 1) -- Pressed state
            else
                button:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Normal state
            end
        elseif buttonName == "Spellbook" then
            if SpellBookFrame and SpellBookFrame:IsShown() then
                button:SetBackdropColor(0.6, 0.6, 0.6, 1)
            else
                button:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
        elseif buttonName == "Quest" then
            if QuestLogFrame and QuestLogFrame:IsShown() then
                button:SetBackdropColor(0.6, 0.6, 0.6, 1)
            else
                button:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
        end
    end
end

-- Hook into UI events to update button states
function MicroMenu:HookUIEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "Blizzard_AchievementUI" or 
               addonName == "Blizzard_TalentUI" or 
               addonName == "Blizzard_Collections" then
                MicroMenu:UpdateButtonStates()
            end
        elseif event == "PLAYER_LOGIN" then
            MicroMenu:UpdateButtonStates()
        end
    end)
    
    -- Update button states periodically
    C_Timer.NewTicker(1, function()
        MicroMenu:UpdateButtonStates()
    end)
end

-- Register the module
WoW95:RegisterModule("MicroMenu", MicroMenu)