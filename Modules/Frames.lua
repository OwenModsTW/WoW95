-- WoW95 Frames Module
-- Replacement for PlayerFrame and TargetFrame with Windows 95 styling
-- Supports all class-specific resources and modern WoW features

local addonName, WoW95 = ...

local Frames = {}
WoW95.Frames = Frames

-- Frame settings and constants
local FRAME_WIDTH = 232
local FRAME_HEIGHT = 100
local PORTRAIT_SIZE = 60
local HEALTH_BAR_HEIGHT = 18
local POWER_BAR_HEIGHT = 12
local CASTBAR_HEIGHT = 16

-- Power type mappings for all classes
Frames.POWER_TYPES = {
    [0] = {name = "MANA", color = {0.0, 0.0, 1.0}},      -- Mana (blue)
    [1] = {name = "RAGE", color = {1.0, 0.0, 0.0}},      -- Rage (red)
    [2] = {name = "FOCUS", color = {1.0, 0.5, 0.25}},    -- Focus (orange)
    [3] = {name = "ENERGY", color = {1.0, 1.0, 0.0}},    -- Energy (yellow)
    [4] = {name = "COMBO_POINTS", color = {1.0, 0.96, 0.41}}, -- Combo Points
    [5] = {name = "RUNES", color = {0.5, 0.5, 0.5}},     -- Runes (gray)
    [6] = {name = "RUNIC_POWER", color = {0.0, 0.8, 1.0}}, -- Runic Power (cyan)
    [7] = {name = "SOUL_SHARDS", color = {0.5, 0.32, 0.55}}, -- Soul Shards (purple)
    [8] = {name = "LUNAR_POWER", color = {0.3, 0.52, 0.9}}, -- Lunar Power (blue)
    [9] = {name = "HOLY_POWER", color = {0.95, 0.9, 0.6}}, -- Holy Power (light yellow)
    [10] = {name = "ALTERNATE_POWER", color = {0.7, 0.7, 0.6}}, -- Alternate Power
    [11] = {name = "MAELSTROM", color = {0.0, 0.5, 1.0}}, -- Maelstrom (blue)
    [12] = {name = "CHI", color = {0.71, 1.0, 0.92}},    -- Chi (light green)
    [13] = {name = "INSANITY", color = {0.4, 0.0, 0.8}}, -- Insanity (purple)
    [16] = {name = "ARCANE_CHARGES", color = {0.1, 0.1, 0.98}}, -- Arcane Charges
    [17] = {name = "FURY", color = {0.788, 0.259, 0.992}}, -- Fury (purple)
    [18] = {name = "PAIN", color = {1.0, 0.61, 0.0}},    -- Pain (orange)
}

-- Class icon coordinates for the class selection texture
Frames.CLASS_ICON_COORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"] = {0.25, 0.49609375, 0, 0.25},
    ["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
    ["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
    ["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
    ["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75},
    ["DEATHKNIGHT"] = {0.25, 0.49609375, 0.5, 0.75},
    ["MONK"] = {0.49609375, 0.7421875, 0.5, 0.75},
    ["DEMONHUNTER"] = {0.7421875, 0.98828125, 0.5, 0.75},
    ["EVOKER"] = {0, 0.25, 0.75, 1.0},
}

-- Class color mappings
Frames.CLASS_COLORS = {
    ["WARRIOR"] = {0.78, 0.61, 0.43},
    ["PALADIN"] = {0.96, 0.55, 0.73},
    ["HUNTER"] = {0.67, 0.83, 0.45},
    ["ROGUE"] = {1.00, 0.96, 0.41},
    ["PRIEST"] = {1.00, 1.00, 1.00},
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["SHAMAN"] = {0.0, 0.44, 0.87},
    ["MAGE"] = {0.25, 0.78, 0.92},
    ["WARLOCK"] = {0.53, 0.53, 0.93},
    ["MONK"] = {0.0, 1.00, 0.59},
    ["DRUID"] = {1.00, 0.49, 0.04},
    ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
    ["EVOKER"] = {0.20, 0.58, 0.50},
}

function Frames:Init()
    WoW95:Debug("Initializing Frames module...")
    
    -- Initialize frame tracking
    self.playerFrame = nil
    self.targetFrame = nil
    self.focusFrame = nil
    
    -- Hide default Blizzard frames
    self:HideBlizzardFrames()
    
    -- Create our custom frames
    self:CreatePlayerFrame()
    self:CreateTargetFrame()
    self:CreateFocusFrame()
    
    -- Register events for updates
    self:RegisterEvents()
    
    WoW95:Debug("Frames module initialized successfully!")
end

function Frames:HideBlizzardFrames()
    WoW95:Debug("Hiding default Blizzard unit frames...")
    
    -- Hide player frame elements
    if PlayerFrame then
        PlayerFrame:Hide()
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame.Show = function() end -- Prevent it from showing again
    end
    
    -- Hide target frame elements
    if TargetFrame then
        TargetFrame:Hide()
        TargetFrame:UnregisterAllEvents()
        TargetFrame.Show = function() end
    end
    
    -- Hide focus frame if it exists
    if FocusFrame then
        FocusFrame:Hide()
        FocusFrame:UnregisterAllEvents()
        FocusFrame.Show = function() end
    end
    
    -- Hide pet frame
    if PetFrame then
        PetFrame:Hide()
        PetFrame:UnregisterAllEvents()
        PetFrame.Show = function() end
    end
    
    WoW95:Debug("Blizzard unit frames hidden")
end

function Frames:CreatePlayerFrame()
    WoW95:Debug("Creating Windows 95 player frame...")
    
    -- Create main player frame
    self.playerFrame = self:CreateUnitFrame("WoW95PlayerFrame", UIParent, "player")
    
    -- Position the player frame (left side of screen)
    self.playerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
    
    -- Set up player-specific features
    self:SetupPlayerSpecific(self.playerFrame)
    
    self.playerFrame:Show()
    WoW95:Debug("Player frame created successfully")
end

function Frames:CreateTargetFrame()
    WoW95:Debug("Creating Windows 95 target frame...")
    
    -- Create main target frame
    self.targetFrame = self:CreateUnitFrame("WoW95TargetFrame", UIParent, "target")
    
    -- Position the target frame (right side, mirrored)
    self.targetFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
    
    -- Set up target-specific features
    self:SetupTargetSpecific(self.targetFrame)
    
    -- Initially hidden until there's a target
    self.targetFrame:Hide()
    WoW95:Debug("Target frame created successfully")
end

function Frames:CreateFocusFrame()
    WoW95:Debug("Creating Windows 95 focus frame...")
    
    -- Create main focus frame
    self.focusFrame = self:CreateUnitFrame("WoW95FocusFrame", UIParent, "focus")
    
    -- Position the focus frame (below target frame)
    self.focusFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -130)
    
    -- Set up focus-specific features (no target-of-target)
    self:SetupFocusSpecific(self.focusFrame)
    
    -- Initially hidden until there's a focus
    self.focusFrame:Hide()
    WoW95:Debug("Focus frame created successfully")
end

function Frames:CreateUnitFrame(name, parent, unit)
    -- Create main frame container with Windows 95 styling
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Create invisible button for right-click menu using proper secure template
    local menuButton = CreateFrame("Button", name .. "MenuButton", frame, "SecureUnitButtonTemplate")
    menuButton:SetAllPoints(frame)
    menuButton:SetFrameLevel(frame:GetFrameLevel() + 10) -- High frame level to catch all clicks
    
    -- Set up secure attributes exactly like Blizzard frames
    menuButton:SetAttribute("unit", unit)
    menuButton:SetAttribute("type1", "target") -- Left click to target
    menuButton:SetAttribute("type2", "togglemenu") -- Try togglemenu instead of menu
    
    -- Enable mouse and register for clicks (let secure template handle everything)
    menuButton:EnableMouse(true)
    menuButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Clean secure template - no debug overlays
    
    -- Windows 95 frame backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    frame:SetBackdropColor(unpack(WoW95.colors.window))
    frame:SetBackdropBorderColor(unpack(WoW95.colors.windowFrame))
    
    -- Store unit reference
    frame.unit = unit
    
    -- Create title bar
    local titleBar = CreateFrame("Frame", name .. "TitleBar", frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(18)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8
    })
    titleBar:SetBackdropColor(unpack(WoW95.colors.titleBar))
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    local titleName = "Target"
    if unit == "player" then
        titleName = "Player"
    elseif unit == "focus" then
        titleName = "Focus"
    end
    titleText:SetText(titleName)
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Make title bar draggable but allow right-clicks to pass through
    titleBar:EnableMouse(true)
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 15) -- Higher than menuButton
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() 
        frame:StartMoving() 
    end)
    titleBar:SetScript("OnDragStop", function() 
        frame:StopMovingOrSizing() 
    end)
    
    -- Portrait (class icon like vanilla) - now just visual, targeting handled by menuButton
    local portrait = CreateFrame("Frame", name .. "Portrait", frame, "BackdropTemplate")
    portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -25)
    portrait:SetFrameLevel(frame:GetFrameLevel() + 2) -- Lower than menuButton so clicks pass through
    
    -- Portrait background
    local portraitBg = portrait:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetAllPoints(portrait)
    portraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    portraitBg:SetVertexColor(0.3, 0.3, 0.3, 1)
    
    -- Portrait texture (will be set to class icon)
    local portraitTexture = portrait:CreateTexture(nil, "ARTWORK")
    portraitTexture:SetPoint("CENTER", portrait, "CENTER")
    portraitTexture:SetSize(PORTRAIT_SIZE - 4, PORTRAIT_SIZE - 4) -- Slight inset
    portraitTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    
    -- Simple border frame
    local portraitBorder = CreateFrame("Frame", nil, portrait, "BackdropTemplate")
    portraitBorder:SetAllPoints(portrait)
    portraitBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 2,
    })
    portraitBorder:SetBackdropBorderColor(unpack(WoW95.colors.windowFrame))
    
    portrait.texture = portraitTexture
    portrait.border = portraitBorder
    
    -- Health bar
    local healthBar = CreateFrame("StatusBar", name .. "HealthBar", frame)
    healthBar:SetSize(FRAME_WIDTH - PORTRAIT_SIZE - 20, HEALTH_BAR_HEIGHT)
    healthBar:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 8, -10)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthBar:SetStatusBarColor(0.0, 1.0, 0.0) -- Green
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    
    -- Health bar background
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(healthBar)
    healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    healthBg:SetVertexColor(0.5, 0.0, 0.0, 0.8) -- Dark red background
    
    -- Health text
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER")
    healthText:SetTextColor(1, 1, 1)
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Power bar (mana/energy/rage/etc)
    local powerBar = CreateFrame("StatusBar", name .. "PowerBar", frame)
    powerBar:SetSize(FRAME_WIDTH - PORTRAIT_SIZE - 20, POWER_BAR_HEIGHT)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
    powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    powerBar:SetMinMaxValues(0, 100)
    powerBar:SetValue(100)
    
    -- Power bar background
    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(powerBar)
    powerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    powerBg:SetVertexColor(0.2, 0.2, 0.2, 0.8) -- Dark background
    
    -- Power text
    local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    powerText:SetPoint("CENTER", powerBar, "CENTER")
    powerText:SetTextColor(1, 1, 1)
    powerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 2)
    nameText:SetTextColor(1, 1, 1)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Level text
    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -2, 2)
    levelText:SetTextColor(1, 1, 1)
    levelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
    -- Cast bar (for spell casting)
    local castBar = CreateFrame("StatusBar", name .. "CastBar", frame)
    castBar:SetSize(FRAME_WIDTH - PORTRAIT_SIZE - 20, CASTBAR_HEIGHT)
    castBar:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, -2)
    castBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    castBar:SetStatusBarColor(1.0, 0.7, 0.0) -- Orange
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBar:Hide()
    
    -- Cast bar background
    local castBg = castBar:CreateTexture(nil, "BACKGROUND")
    castBg:SetAllPoints(castBar)
    castBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    castBg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    
    -- Cast text
    local castText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castText:SetPoint("CENTER", castBar, "CENTER")
    castText:SetTextColor(1, 1, 1)
    castText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
    -- Class power bar (for combo points, holy power, chi, etc.)
    local classPowerBar = CreateFrame("Frame", name .. "ClassPowerBar", frame)
    classPowerBar:SetSize(FRAME_WIDTH - PORTRAIT_SIZE - 20, 8)
    classPowerBar:SetPoint("TOPLEFT", castBar, "BOTTOMLEFT", 0, -2)
    classPowerBar:Hide()
    
    -- Create individual class power points (up to 6 for most classes)
    classPowerBar.points = {}
    for i = 1, 6 do
        local point = CreateFrame("StatusBar", name .. "ClassPowerPoint" .. i, classPowerBar)
        point:SetSize(20, 8)
        point:SetPoint("LEFT", classPowerBar, "LEFT", (i-1) * 22, 0)
        point:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        point:SetMinMaxValues(0, 1)
        point:SetValue(0)
        
        -- Background for each point
        local pointBg = point:CreateTexture(nil, "BACKGROUND")
        pointBg:SetAllPoints(point)
        pointBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        pointBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
        
        classPowerBar.points[i] = point
    end
    
    -- Buffs container (above frame) - smaller since buffs are 20x20
    local buffsContainer = CreateFrame("Frame", name .. "BuffsContainer", frame)
    buffsContainer:SetSize(FRAME_WIDTH, 24) -- Reduced height
    buffsContainer:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
    buffsContainer.buffs = {}
    
    -- Debuffs container (above buffs) - smaller since debuffs are 20x20
    local debuffsContainer = CreateFrame("Frame", name .. "DebuffsContainer", frame)
    debuffsContainer:SetSize(FRAME_WIDTH, 24) -- Reduced height
    debuffsContainer:SetPoint("BOTTOMLEFT", buffsContainer, "TOPLEFT", 0, 2)
    debuffsContainer.debuffs = {}
    
    -- Test button removed
    
    -- Store references
    frame.titleBar = titleBar
    frame.titleText = titleText
    frame.portrait = portrait
    frame.healthBar = healthBar
    frame.healthText = healthText
    frame.powerBar = powerBar
    frame.powerText = powerText
    frame.nameText = nameText
    frame.levelText = levelText
    frame.castBar = castBar
    frame.castText = castText
    frame.classPowerBar = classPowerBar
    frame.menuButton = menuButton
    frame.buffsContainer = buffsContainer
    frame.debuffsContainer = debuffsContainer
    
    return frame
end

function Frames:SetupPlayerSpecific(frame)
    -- Player frame shows resting state, etc.
    -- Add resting indicator
    local restingIcon = frame:CreateTexture(nil, "OVERLAY")
    restingIcon:SetSize(16, 16)
    restingIcon:SetPoint("TOPLEFT", frame.portrait, "TOPLEFT", -2, 2)
    restingIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    restingIcon:SetTexCoord(0, 0.5, 0, 0.5) -- Resting zzz icon
    restingIcon:Hide()
    frame.restingIcon = restingIcon
    
    -- Player-specific status indicators can be added here
end

function Frames:SetupTargetSpecific(frame)
    -- Target frame shows classification (elite, rare, etc.)
    -- Add target classification
    local classificationIcon = frame:CreateTexture(nil, "OVERLAY")
    classificationIcon:SetSize(16, 16)
    classificationIcon:SetPoint("TOPRIGHT", frame.portrait, "TOPRIGHT", 2, 2)
    classificationIcon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    classificationIcon:Hide()
    frame.classificationIcon = classificationIcon
    
    -- Target-of-target frame (mini frame)
    local totFrame = CreateFrame("Frame", frame:GetName() .. "ToT", frame, "BackdropTemplate")
    totFrame:SetSize(80, 40)
    totFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
    totFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 4,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    totFrame:SetBackdropColor(unpack(WoW95.colors.window))
    totFrame:SetBackdropBorderColor(unpack(WoW95.colors.windowFrame))
    totFrame:Hide()
    
    -- ToT portrait (smaller class icon)
    local totPortrait = CreateFrame("Frame", frame:GetName() .. "ToTPortrait", totFrame)
    totPortrait:SetSize(30, 30)
    totPortrait:SetPoint("LEFT", totFrame, "LEFT", 2, 0)
    
    local totPortraitTexture = totPortrait:CreateTexture(nil, "ARTWORK")
    totPortraitTexture:SetAllPoints(totPortrait)
    totPortraitTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    
    totPortrait.texture = totPortraitTexture
    
    -- ToT health bar
    local totHealthBar = CreateFrame("StatusBar", frame:GetName() .. "ToTHealthBar", totFrame)
    totHealthBar:SetSize(40, 8)
    totHealthBar:SetPoint("TOPLEFT", totPortrait, "TOPRIGHT", 2, -2)
    totHealthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    totHealthBar:SetStatusBarColor(0.0, 1.0, 0.0)
    
    -- ToT name
    local totName = totFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totName:SetPoint("TOPLEFT", totHealthBar, "BOTTOMLEFT", 0, -2)
    totName:SetTextColor(1, 1, 1)
    totName:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    
    frame.totFrame = totFrame
    frame.totPortrait = totPortrait
    frame.totHealthBar = totHealthBar
    frame.totName = totName
end

function Frames:SetupFocusSpecific(frame)
    -- Focus frame shows classification but no target-of-target
    local classificationIcon = frame:CreateTexture(nil, "OVERLAY")
    classificationIcon:SetSize(16, 16)
    classificationIcon:SetPoint("TOPRIGHT", frame.portrait, "TOPRIGHT", 2, 2)
    classificationIcon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    classificationIcon:Hide()
    frame.classificationIcon = classificationIcon
    
    -- Focus frames don't have target-of-target, so no totFrame needed
end

function Frames:RegisterEvents()
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    self.eventFrame = eventFrame
    
    -- Register all necessary events
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    eventFrame:RegisterEvent("UNIT_LEVEL")
    eventFrame:RegisterEvent("UNIT_TARGET")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    eventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
    eventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
    eventFrame:RegisterEvent("UNIT_AURA")
    
    -- Set event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        Frames:OnEvent(event, ...)
    end)
    
    -- Start update timer for smooth updates
    self:StartUpdateTimer()
end

function Frames:OnEvent(event, ...)
    local unit = ...
    
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        self:UpdatePlayerFrame()
        self:UpdateTargetFrame()
        self:UpdateFocusFrame()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:UpdateTargetFrame()
    elseif event == "PLAYER_FOCUS_CHANGED" then
        self:UpdateFocusFrame()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit == "player" then
            self:UpdateHealth(self.playerFrame)
        elseif unit == "target" then
            self:UpdateHealth(self.targetFrame)
        elseif unit == "focus" then
            self:UpdateHealth(self.focusFrame)
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        if unit == "player" then
            self:UpdatePower(self.playerFrame)
            self:UpdateClassPower(self.playerFrame)
        elseif unit == "target" then
            self:UpdatePower(self.targetFrame)
            self:UpdateClassPower(self.targetFrame)
        elseif unit == "focus" then
            self:UpdatePower(self.focusFrame)
            self:UpdateClassPower(self.focusFrame)
        end
    elseif event == "UNIT_POWER_FREQUENT" then
        if unit == "player" then
            self:UpdateClassPower(self.playerFrame)
        elseif unit == "target" then
            self:UpdateClassPower(self.targetFrame)
        elseif unit == "focus" then
            self:UpdateClassPower(self.focusFrame)
        end
    elseif event == "UNIT_NAME_UPDATE" then
        if unit == "player" then
            self:UpdateName(self.playerFrame)
        elseif unit == "target" then
            self:UpdateName(self.targetFrame)
        elseif unit == "focus" then
            self:UpdateName(self.focusFrame)
        end
    elseif event == "UNIT_LEVEL" then
        if unit == "player" then
            self:UpdateLevel(self.playerFrame)
        elseif unit == "target" then
            self:UpdateLevel(self.targetFrame)
        elseif unit == "focus" then
            self:UpdateLevel(self.focusFrame)
        end
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
        if unit == "player" then
            self:UpdatePortrait(self.playerFrame)
        elseif unit == "target" then
            self:UpdatePortrait(self.targetFrame)
        end
    elseif event:find("SPELLCAST") then
        if unit == "player" then
            self:UpdateCastBar(self.playerFrame, event)
        elseif unit == "target" then
            self:UpdateCastBar(self.targetFrame, event)
        end
    elseif event == "UNIT_AURA" then
        if unit == "target" then
            self:UpdateAuras(self.targetFrame)
        elseif unit == "focus" then
            self:UpdateAuras(self.focusFrame)
        end
    end
end

function Frames:StartUpdateTimer()
    -- Create update ticker for smooth animations and frequent updates
    self.updateTicker = C_Timer.NewTicker(0.1, function()
        if self.playerFrame then
            self:UpdatePlayerFrame()
        end
        if self.targetFrame and UnitExists("target") then
            self:UpdateTargetFrame()
        end
    end)
end

function Frames:UpdatePlayerFrame()
    if not self.playerFrame then return end
    
    self:UpdateHealth(self.playerFrame)
    self:UpdatePower(self.playerFrame)
    self:UpdateName(self.playerFrame)
    self:UpdateLevel(self.playerFrame)
    self:UpdatePortrait(self.playerFrame)
    self:UpdatePlayerResting(self.playerFrame)
    self:UpdateClassPower(self.playerFrame)
    -- No auras for player frame
end

function Frames:UpdateTargetFrame()
    if not self.targetFrame then return end
    
    if UnitExists("target") then
        self.targetFrame:Show()
        self:UpdateHealth(self.targetFrame)
        self:UpdatePower(self.targetFrame)
        self:UpdateName(self.targetFrame)
        self:UpdateLevel(self.targetFrame)
        self:UpdatePortrait(self.targetFrame)
        self:UpdateTargetClassification(self.targetFrame)
        self:UpdateTargetOfTarget(self.targetFrame)
        self:UpdateClassPower(self.targetFrame)
        self:UpdateAuras(self.targetFrame)
    else
        self.targetFrame:Hide()
    end
end

function Frames:UpdateFocusFrame()
    if not self.focusFrame then return end
    
    if UnitExists("focus") then
        self.focusFrame:Show()
        self:UpdateHealth(self.focusFrame)
        self:UpdatePower(self.focusFrame)
        self:UpdateName(self.focusFrame)
        self:UpdateLevel(self.focusFrame)
        self:UpdatePortrait(self.focusFrame)
        self:UpdateTargetClassification(self.focusFrame)
        -- Note: Focus doesn't have target of target, only targets do
        self:UpdateClassPower(self.focusFrame)
    else
        self.focusFrame:Hide()
    end
end

function Frames:UpdateHealth(frame)
    if not frame or not frame.healthBar then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    frame.healthBar:SetMinMaxValues(0, maxHealth)
    frame.healthBar:SetValue(health)
    
    -- Update health text
    if health == maxHealth then
        frame.healthText:SetText(health)
    else
        frame.healthText:SetText(health .. " / " .. maxHealth)
    end
    
    -- Color health bar based on percentage
    local healthPercent = health / maxHealth
    if healthPercent > 0.5 then
        frame.healthBar:SetStatusBarColor(0.0, 1.0, 0.0) -- Green
    elseif healthPercent > 0.25 then
        frame.healthBar:SetStatusBarColor(1.0, 1.0, 0.0) -- Yellow
    else
        frame.healthBar:SetStatusBarColor(1.0, 0.0, 0.0) -- Red
    end
end

function Frames:UpdatePower(frame)
    if not frame or not frame.powerBar then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    
    frame.powerBar:SetMinMaxValues(0, maxPower)
    frame.powerBar:SetValue(power)
    
    -- Set power bar color based on type
    local powerInfo = self.POWER_TYPES[powerType]
    if powerInfo then
        frame.powerBar:SetStatusBarColor(unpack(powerInfo.color))
        
        -- Update power text
        if maxPower > 0 then
            frame.powerText:SetText(power .. " / " .. maxPower)
        else
            frame.powerText:SetText("")
        end
    else
        -- Unknown power type, hide the bar
        frame.powerBar:Hide()
        frame.powerText:SetText("")
    end
end

function Frames:UpdateName(frame)
    if not frame or not frame.nameText then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    local name = UnitName(unit)
    frame.nameText:SetText(name or "Unknown")
    
    -- Color name by class if it's a player
    if UnitIsPlayer(unit) then
        local _, englishClass = UnitClass(unit)
        local classColor = self.CLASS_COLORS[englishClass]
        if classColor then
            frame.nameText:SetTextColor(unpack(classColor))
        else
            frame.nameText:SetTextColor(1, 1, 1) -- White default
        end
    else
        -- Color by reaction for NPCs
        local reaction = UnitReaction(unit, "player")
        if reaction then
            if reaction >= 5 then
                frame.nameText:SetTextColor(0.0, 1.0, 0.0) -- Green (friendly)
            elseif reaction == 4 then
                frame.nameText:SetTextColor(1.0, 1.0, 0.0) -- Yellow (neutral)
            else
                frame.nameText:SetTextColor(1.0, 0.0, 0.0) -- Red (hostile)
            end
        else
            frame.nameText:SetTextColor(1, 1, 1) -- White default
        end
    end
end

function Frames:UpdateLevel(frame)
    if not frame or not frame.levelText then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    local level = UnitLevel(unit)
    if level and level > 0 then
        frame.levelText:SetText("Level " .. level)
    else
        frame.levelText:SetText("??")
    end
end

function Frames:UpdatePortrait(frame)
    if not frame or not frame.portrait or not frame.portrait.texture then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    if UnitIsPlayer(unit) then
        -- Show class icon for players
        local _, englishClass = UnitClass(unit)
        local coords = self.CLASS_ICON_COORDS[englishClass]
        if coords then
            frame.portrait.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            frame.portrait.texture:SetTexCoord(unpack(coords))
        else
            -- Default player icon if class not found
            frame.portrait.texture:SetTexture("Interface\\Icons\\Achievement_Character_Human_Male")
            frame.portrait.texture:SetTexCoord(0, 1, 0, 1)
        end
    else
        -- Show creature type icon for NPCs
        frame.portrait.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        frame.portrait.texture:SetTexCoord(0, 1, 0, 1)
    end
end

function Frames:UpdatePlayerResting(frame)
    if not frame or not frame.restingIcon then return end
    
    if IsResting() then
        frame.restingIcon:Show()
    else
        frame.restingIcon:Hide()
    end
end

function Frames:UpdateTargetClassification(frame)
    if not frame or not frame.classificationIcon then return end
    
    local classification = UnitClassification("target")
    if classification == "elite" or classification == "rareelite" then
        frame.classificationIcon:SetTexture("Interface\\Tooltips\\EliteNameplateIcon")
        frame.classificationIcon:Show()
    elseif classification == "rare" then
        frame.classificationIcon:SetTexture("Interface\\Tooltips\\RareNameplateIcon")
        frame.classificationIcon:Show()
    else
        frame.classificationIcon:Hide()
    end
end

function Frames:UpdateTargetOfTarget(frame)
    if not frame or not frame.totFrame then return end
    
    if UnitExists("targettarget") then
        frame.totFrame:Show()
        
        -- Update ToT portrait (need to handle manually since it's not a full frame)
        if frame.totPortrait and frame.totPortrait.texture then
            if UnitIsPlayer("targettarget") then
                local _, englishClass = UnitClass("targettarget")
                local coords = self.CLASS_ICON_COORDS[englishClass]
                if coords then
                    frame.totPortrait.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                    frame.totPortrait.texture:SetTexCoord(unpack(coords))
                else
                    frame.totPortrait.texture:SetTexture("Interface\\Icons\\Achievement_Character_Human_Male")
                    frame.totPortrait.texture:SetTexCoord(0, 1, 0, 1)
                end
            else
                frame.totPortrait.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                frame.totPortrait.texture:SetTexCoord(0, 1, 0, 1)
            end
        end
        
        -- Update ToT health
        local health = UnitHealth("targettarget")
        local maxHealth = UnitHealthMax("targettarget")
        frame.totHealthBar:SetMinMaxValues(0, maxHealth)
        frame.totHealthBar:SetValue(health)
        
        -- Update ToT name
        local name = UnitName("targettarget")
        frame.totName:SetText(name or "")
    else
        frame.totFrame:Hide()
    end
end

function Frames:UpdateClassPower(frame)
    if not frame or not frame.classPowerBar then return end
    
    local unit = frame.unit
    if not UnitExists(unit) then return end
    
    -- Check if unit has class power (combo points, holy power, etc.)
    local powerType = UnitPowerType(unit)
    local classPowerType = nil
    local maxClassPower = 0
    local currentClassPower = 0
    
    -- Check for class-specific power types
    if UnitIsPlayer(unit) then
        local _, englishClass = UnitClass(unit)
        
        if englishClass == "PALADIN" then
            classPowerType = Enum.PowerType.HolyPower
        elseif englishClass == "ROGUE" or englishClass == "DRUID" then
            classPowerType = Enum.PowerType.ComboPoints
        elseif englishClass == "MONK" then
            classPowerType = Enum.PowerType.Chi
        elseif englishClass == "WARLOCK" then
            classPowerType = Enum.PowerType.SoulShards
        elseif englishClass == "MAGE" then
            classPowerType = Enum.PowerType.ArcaneCharges
        elseif englishClass == "DEATHKNIGHT" then
            classPowerType = Enum.PowerType.Runes
        end
        
        if classPowerType then
            maxClassPower = UnitPowerMax(unit, classPowerType)
            currentClassPower = UnitPower(unit, classPowerType)
        end
    end
    
    -- Show/hide class power bar based on whether the unit has class power
    if classPowerType and maxClassPower > 0 then
        frame.classPowerBar:Show()
        
        -- Get the power info for coloring
        local powerInfo = self.POWER_TYPES[classPowerType]
        local color = powerInfo and powerInfo.color or {1, 1, 1}
        
        -- Update each power point
        for i = 1, maxClassPower do
            if frame.classPowerBar.points[i] then
                frame.classPowerBar.points[i]:Show()
                if i <= currentClassPower then
                    frame.classPowerBar.points[i]:SetValue(1)
                    frame.classPowerBar.points[i]:SetStatusBarColor(unpack(color))
                else
                    frame.classPowerBar.points[i]:SetValue(0)
                end
            end
        end
        
        -- Hide unused points
        for i = maxClassPower + 1, 6 do
            if frame.classPowerBar.points[i] then
                frame.classPowerBar.points[i]:Hide()
            end
        end
    else
        frame.classPowerBar:Hide()
    end
end

function Frames:UpdateCastBar(frame, event)
    if not frame or not frame.castBar then return end
    
    local unit = frame.unit
    
    if event == "UNIT_SPELLCAST_START" then
        local name, text, texture, startTime, endTime = UnitCastingInfo(unit)
        if name then
            frame.castBar:SetMinMaxValues(startTime, endTime)
            frame.castBar:SetValue(startTime)
            frame.castText:SetText(name)
            frame.castBar:Show()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED" or 
           event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        frame.castBar:Hide()
    end
end

-- Buff/Debuff Management Functions
function Frames:CreateAuraButton(parent, index, isDebuff)
    local button = CreateFrame("Button", parent:GetName() .. (isDebuff and "Debuff" or "Buff") .. index, parent, "BackdropTemplate")
    button:SetSize(20, 20) -- Smaller size
    
    -- Position buffs/debuffs in rows (closer together)
    local col = ((index - 1) % 10) + 1 -- More per row since they're smaller
    local row = math.floor((index - 1) / 10) + 1
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", (col - 1) * 22, -(row - 1) * 22)
    
    -- Simple border without dark background
    button:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    -- No background color - transparent
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Icon texture
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.icon = icon
    
    -- Stack count text (smaller for 20x20 icons)
    local count = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    count:SetTextColor(1, 1, 1, 1)
    count:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    button.count = count
    
    -- Duration text (optional, small)
    local duration = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    duration:SetPoint("BOTTOM", button, "BOTTOM", 0, -10)
    duration:SetTextColor(1, 1, 1, 1)
    duration:SetFont("Fonts\\FRIZQT__.TTF", 6, "OUTLINE")
    button.duration = duration
    
    -- Tooltip on hover
    button:SetScript("OnEnter", function(self)
        if self.spellId and self.spellId > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellId)
            GameTooltip:Show()
        elseif self.auraName then
            -- Fallback tooltip with just the name
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.auraName)
            GameTooltip:Show()
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Right-click to cancel (player only)
    if not isDebuff then
        button:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.spellId and UnitIsUnit(parent:GetParent().unit, "player") then
                CancelUnitBuff("player", self.index)
            end
        end)
        button:RegisterForClicks("RightButtonUp")
    end
    
    return button
end

function Frames:UpdateAuras(frame)
    if not frame or not frame.buffsContainer or not frame.debuffsContainer then 
        return 
    end
    
    local unit = frame.unit
    if not UnitExists(unit) then 
        return 
    end
    
    -- Update buffs
    self:UpdateAuraContainer(frame.buffsContainer, unit, false)
    
    -- Update debuffs  
    self:UpdateAuraContainer(frame.debuffsContainer, unit, true)
end

function Frames:UpdateAuraContainer(container, unit, isDebuff)
    local filter = isDebuff and "HARMFUL" or "HELPFUL"
    local auras = container[isDebuff and "debuffs" or "buffs"]
    
    -- Hide all existing aura buttons first
    for i = 1, #auras do
        auras[i]:Hide()
    end
    
    local auraIndex = 1
    
    -- Direct UnitAura iteration (using C_UnitAuras for modern WoW)
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId
        
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            -- Modern API
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if auraData then
                name = auraData.name
                icon = auraData.icon
                count = auraData.applications
                debuffType = auraData.dispelName
                duration = auraData.duration
                expirationTime = auraData.expirationTime
                source = auraData.sourceUnit
                isStealable = auraData.isStealable
                spellId = auraData.spellId
            end
        else
            -- Fallback for older API
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                  nameplateShowPersonal, spellId = _G.UnitAura(unit, i, filter)
        end
        
        if not name then break end
        
        if auraIndex <= 16 then -- Limit to 16 auras max
            -- Create button if it doesn't exist
            if not auras[auraIndex] then
                auras[auraIndex] = self:CreateAuraButton(container, auraIndex, isDebuff)
            end
            
            local button = auras[auraIndex]
            
            -- Set aura data
            button.spellId = spellId
            button.auraName = name
            button.index = i
            button.icon:SetTexture(icon)
            
            -- Make sure the icon is visible
            if not icon then
                button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Set stack count
            if count and count > 1 then
                button.count:SetText(count)
                button.count:Show()
            else
                button.count:Hide()
            end
            
            -- Set duration (show remaining time if less than 60 seconds)
            if expirationTime and expirationTime > 0 then
                local timeLeft = expirationTime - GetTime()
                if timeLeft > 0 and timeLeft < 60 then
                    button.duration:SetText(string.format("%.0f", timeLeft))
                    button.duration:Show()
                else
                    button.duration:Hide()
                end
            else
                button.duration:Hide()
            end
            
            -- Color border based on aura type
            if isDebuff then
                local dispelType = debuffType or "none"
                if dispelType == "Magic" then
                    button:SetBackdropBorderColor(0.2, 0.6, 1, 1) -- Blue
                elseif dispelType == "Disease" then
                    button:SetBackdropBorderColor(0.6, 0.4, 0, 1) -- Brown
                elseif dispelType == "Poison" then
                    button:SetBackdropBorderColor(0, 0.6, 0, 1) -- Green
                elseif dispelType == "Curse" then
                    button:SetBackdropBorderColor(0.6, 0, 0.6, 1) -- Purple
                else
                    button:SetBackdropBorderColor(0.8, 0, 0, 1) -- Red for undispellable
                end
            else
                button:SetBackdropBorderColor(0, 0.8, 0, 1) -- Green for buffs
            end
            
            button:Show()
            auraIndex = auraIndex + 1
        end
    end
end

-- Debug command
SLASH_WOW95FRAMES1 = "/wow95frames"
SlashCmdList["WOW95FRAMES"] = function(msg)
    if msg == "reset" then
        if Frames.playerFrame then
            Frames.playerFrame:ClearAllPoints()
            Frames.playerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
        end
        if Frames.targetFrame then
            Frames.targetFrame:ClearAllPoints()
            Frames.targetFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
        end
        WoW95:Print("Frames reset to default positions")
    elseif msg == "debug" then
        WoW95:Print("=== WoW95 Frames Debug ===")
        WoW95:Print("Player frame exists: " .. tostring(Frames.playerFrame ~= nil))
        WoW95:Print("Target frame exists: " .. tostring(Frames.targetFrame ~= nil))
        WoW95:Print("Target exists: " .. tostring(UnitExists("target")))
        if UnitExists("player") then
            local powerType = UnitPowerType("player")
            local powerInfo = Frames.POWER_TYPES[powerType]
            WoW95:Print("Player power type: " .. (powerInfo and powerInfo.name or "Unknown"))
        end
    elseif msg == "menu" then
        WoW95:Print("=== Right-Click Menu Debug ===")
        if Frames.playerFrame and Frames.playerFrame.menuButton then
            local menuButton = Frames.playerFrame.menuButton
            WoW95:Print("Menu button exists: " .. tostring(menuButton ~= nil))
            WoW95:Print("Menu button unit: " .. tostring(menuButton:GetAttribute("unit")))
            WoW95:Print("Menu button *type2: " .. tostring(menuButton:GetAttribute("*type2")))
            WoW95:Print("Menu button mouse enabled: " .. tostring(menuButton:IsMouseEnabled()))
            WoW95:Print("Menu button frame level: " .. tostring(menuButton:GetFrameLevel()))
            WoW95:Print("Player frame level: " .. tostring(Frames.playerFrame:GetFrameLevel()))
            WoW95:Print("Portrait frame level: " .. tostring(Frames.playerFrame.portrait:GetFrameLevel()))
            WoW95:Print("Title bar frame level: " .. tostring(Frames.playerFrame.titleBar:GetFrameLevel()))
        else
            WoW95:Print("Menu button not found!")
        end
    elseif msg == "testaura" then
        print("|cFFFFFF00=== WoW95 Aura Test ===|r")
        
        -- First ensure target frame exists
        if not Frames.targetFrame then
            print("|cFFFF0000ERROR: Target frame doesn't exist|r")
            return
        end
        
        if not Frames.targetFrame.buffsContainer then
            print("|cFFFF0000ERROR: Buffs container doesn't exist|r")
            return
        end
        
        -- Make containers visible with colored backgrounds for debugging
        local buffsC = Frames.targetFrame.buffsContainer
        local debuffsC = Frames.targetFrame.debuffsContainer
        
        if not buffsC.SetBackdrop then
            Mixin(buffsC, BackdropTemplateMixin)
        end
        buffsC:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        buffsC:SetBackdropColor(0, 1, 0, 0.5) -- Green
        
        if debuffsC and not debuffsC.SetBackdrop then
            Mixin(debuffsC, BackdropTemplateMixin)
        end
        if debuffsC then
            debuffsC:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            debuffsC:SetBackdropColor(1, 0, 0, 0.5) -- Red
        end
        
        print("|cFF00FF00Container backgrounds visible (green=buffs, red=debuffs)|r")
        print("Container size: " .. buffsC:GetWidth() .. "x" .. buffsC:GetHeight())
        print("Container visible: " .. tostring(buffsC:IsShown()))
        
        -- Create multiple test auras to show layout
        print("|cFF00FF00Creating test auras...|r")
        for i = 1, 5 do
            if not Frames.targetFrame.buffsContainer.buffs[i] then
                Frames.targetFrame.buffsContainer.buffs[i] = Frames:CreateAuraButton(Frames.targetFrame.buffsContainer, i, false)
            end
            local btn = Frames.targetFrame.buffsContainer.buffs[i]
            local icons = {
                "Interface\\Icons\\Spell_Holy_PowerWordShield",
                "Interface\\Icons\\Spell_Holy_Renew", 
                "Interface\\Icons\\Spell_Holy_FlashHeal",
                "Interface\\Icons\\Ability_Paladin_BeaconofLight",
                "Interface\\Icons\\Spell_Holy_GreaterHeal"
            }
            btn.icon:SetTexture(icons[i])
            btn.isTestButton = true -- Mark as test button so it doesn't get hidden
            btn:Show()
            
            -- Debug button info
            if i == 1 then
                print("Button 1 size: " .. btn:GetWidth() .. "x" .. btn:GetHeight())
                print("Button 1 visible: " .. tostring(btn:IsShown()))
                local point, relativeTo, relativePoint, x, y = btn:GetPoint()
                print("Button 1 position: " .. (point or "nil") .. " " .. (x or 0) .. "," .. (y or 0))
            end
        end
        print("|cFF00FF00✓ Test auras should be visible above target frame|r")
        
        -- Check real target auras
        if UnitExists("target") then
            print("|cFFFFFF00Checking real target auras:|r")
            
            -- Test player buffs
            local playerBuffs = 0
            for i = 1, 40 do
                local name = UnitAura("player", i, "HELPFUL")
                if name then playerBuffs = playerBuffs + 1 end
            end
            print("  Your buffs: " .. playerBuffs)
            
            -- Test target buffs/debuffs
            local targetBuffs = 0
            local targetDebuffs = 0
            for i = 1, 40 do
                local name = UnitAura("target", i, "HELPFUL")
                if name then 
                    targetBuffs = targetBuffs + 1
                    if targetBuffs <= 3 then -- Only show first 3
                        print("  Target buff: " .. name)
                    end
                end
            end
            for i = 1, 40 do
                local name = UnitAura("target", i, "HARMFUL")
                if name then 
                    targetDebuffs = targetDebuffs + 1
                    if targetDebuffs <= 3 then -- Only show first 3
                        print("  Target debuff: " .. name)
                    end
                end
            end
            print("|cFF00FF00Target has " .. targetBuffs .. " buffs, " .. targetDebuffs .. " debuffs|r")
            
            -- Force update
            Frames:UpdateAuras(Frames.targetFrame)
        else
            print("|cFFFF0000No target - select a target and try again|r")
        end
    else
        WoW95:Print("WoW95 Frames commands:")
        WoW95:Print("/wow95frames reset - Reset frame positions")
        WoW95:Print("/wow95frames debug - Show debug information")
        WoW95:Print("/wow95frames menu - Test right-click menu functionality")
        WoW95:Print("/wow95frames testaura - Test aura display system")
    end
end

-- Register the module
WoW95:RegisterModule("Frames", Frames)