-- WoW95 - Windows 95 Style UI for World of Warcraft
-- Core Framework and Initialization

local addonName, WoW95 = ...

-- Addon metadata
WoW95.version = "1.0.0"
WoW95.name = "WoW95"

-- Core tables
WoW95.modules = {}
WoW95.frames = {}
WoW95.settings = {}
WoW95.events = {}

-- Windows 95 Color Palette
WoW95.colors = {
    -- System colors
    window = {0.75, 0.75, 0.75, 1},          -- Standard window background
    windowFrame = {0.5, 0.5, 0.5, 1},        -- Window frame/border
    titleBar = {0.0, 0.0, 0.5, 1},           -- Title bar blue
    titleBarText = {1, 1, 1, 1},             -- White text on title bar
    buttonFace = {0.75, 0.75, 0.75, 1},      -- Button face color
    buttonHighlight = {1, 1, 1, 1},          -- Button highlight
    buttonShadow = {0.5, 0.5, 0.5, 1},       -- Button shadow
    buttonText = {0, 0, 0, 1},               -- Button text
    menuBar = {0.75, 0.75, 0.75, 1},         -- Menu bar
    desktop = {0.0, 0.5, 0.5, 1},            -- Teal desktop color
    scrollBar = {0.75, 0.75, 0.75, 1},       -- Scrollbar
    text = {0, 0, 0, 1},                     -- Standard black text
    selectedText = {1, 1, 1, 1},             -- White selected text
    selection = {0.0, 0.0, 0.5, 1},          -- Blue selection
}

-- Custom button textures
WoW95.textures = {
    close = "Interface\\AddOns\\WoW95\\Media\\xclose",
    minimize = "Interface\\AddOns\\WoW95\\Media\\minimise", 
    maximize = "Interface\\AddOns\\WoW95\\Media\\maximise",
    startButton = "Interface\\AddOns\\WoW95\\Media\\startbutton",
    lock = "Interface\\AddOns\\WoW95\\Media\\lock",
    add = "Interface\\AddOns\\WoW95\\Media\\add",
    arrow = "Interface\\AddOns\\WoW95\\Media\\arrow"
}

-- Core utility functions
function WoW95:Debug(message)
    if self.settings.debug then
        print("|cFF00AAFF[WoW95]|r " .. tostring(message))
    end
end

function WoW95:Print(message)
    print("|cFF00AAFF[WoW95]|r " .. tostring(message))
end

-- Create Windows 95 style frame with title bar
function WoW95:CreateWindow(name, parent, width, height, title)
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
    
    -- Title bar backdrop
    titleBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(unpack(self.colors.titleBar))
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    WoW95:Debug("Standard window title bar color set to: " .. table.concat(self.colors.titleBar, ", "))
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText(title or "Window")
    titleText:SetTextColor(unpack(self.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Lock button using custom texture
    local lockButton = self:CreateTitleBarButton(name .. "LockButton", titleBar, self.textures.lock, 16)
    lockButton:SetPoint("RIGHT", titleBar, "RIGHT", -20, 0)
    
    -- Close button using custom texture
    local closeButton = self:CreateTitleBarButton(name .. "CloseButton", titleBar, self.textures.close, 16)
    closeButton:SetPoint("RIGHT", lockButton, "LEFT", -2, 0)
    
    -- Lock button functionality
    lockButton:SetScript("OnClick", function()
        WoW95:ToggleWindowLock(frame)
    end)
    
    -- Lock button hover effects
    lockButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if frame.isLocked then
            GameTooltip:SetText("Unlock Window")
            GameTooltip:AddLine("Click to enable window movement", 0.7, 0.7, 0.7)
        else
            GameTooltip:SetText("Lock Window")
            GameTooltip:AddLine("Click to prevent window movement", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Close button functionality
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        WoW95:OnWindowClosed(frame)
    end)
    
    -- Make frame movable (required for StartMoving to work)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Make title bar draggable
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Store references
    frame.titleBar = titleBar
    frame.titleText = titleText
    frame.closeButton = closeButton
    frame.lockButton = lockButton
    frame.isWoW95Window = true
    frame.isLocked = false
    
    -- Add to our frame registry
    self.frames[name] = frame
    
    return frame
end

-- Create Windows 95 style button
function WoW95:CreateButton(name, parent, width, height, text)
    local button = CreateFrame("Button", name, parent, "BackdropTemplate")
    button:SetSize(width or 100, height or 24)
    
    -- Button backdrop (solid gray)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    button:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Solid Windows 95 gray
    button:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text or "Button")
    buttonText:SetTextColor(unpack(self.colors.buttonText))
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Button effects
    button:SetScript("OnEnter", function()
        button:SetBackdropColor(0.85, 0.85, 0.85, 1)
    end)
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    end)
    button:SetScript("OnMouseDown", function()
        button:SetBackdropColor(0.6, 0.6, 0.6, 1)
        buttonText:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function()
        button:SetBackdropColor(0.85, 0.85, 0.85, 1)
        buttonText:SetPoint("CENTER", 0, 0)
    end)
    
    button.text = buttonText
    return button
end

-- Create Windows 95 style title bar button with custom texture
function WoW95:CreateTitleBarButton(name, parent, texture, size)
    local button = CreateFrame("Button", name, parent, "BackdropTemplate")
    button:SetSize(size or 16, size or 14)
    
    -- Button backdrop
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    button:SetBackdropColor(unpack(self.colors.buttonFace))
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create texture for the button icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize((size or 16) - 4, (size or 14) - 4)
    icon:SetTexture(texture)
    
    -- Store reference
    button.icon = icon
    
    -- Button effects
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.85, 0.85, 0.85, 1)
    end)
    button:SetScript("OnLeave", function(self)
        if WoW95 and WoW95.colors and WoW95.colors.buttonFace then
            self:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        else
            self:SetBackdropColor(0.75, 0.75, 0.75, 1)
        end
    end)
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.6, 0.6, 0.6, 1)
        self.icon:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.85, 0.85, 0.85, 1)
        self.icon:SetPoint("CENTER", 0, 0)
    end)
    
    return button
end

-- Module registration system
function WoW95:RegisterModule(name, module)
    self.modules[name] = module
    self:Debug("Registered module: " .. name)
    
    -- Initialize module if it has an Init function
    if module.Init then
        module:Init()
    end
end

-- Event handling
function WoW95:RegisterEvent(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
end

function WoW95:FireEvent(event, ...)
    if self.events[event] then
        for _, callback in ipairs(self.events[event]) do
            callback(...)
        end
    end
end

-- Window management for taskbar
function WoW95:OnWindowOpened(frame)
    self:FireEvent("WINDOW_OPENED", frame)
end

function WoW95:OnWindowClosed(frame)
    self:FireEvent("WINDOW_CLOSED", frame)
end

-- Initialize default settings
function WoW95:InitializeSettings()
    local defaults = {
        debug = true,  -- Enable debug for initial testing
        hideBlizzardFrames = true,
        taskbarEnabled = true,
        startMenuEnabled = true,
        windowsTheme = true,
    }
    
    -- Load saved settings or use defaults
    if not WoW95DB then
        WoW95DB = {}
    end
    
    for key, value in pairs(defaults) do
        if WoW95DB[key] == nil then
            WoW95DB[key] = value
        end
        self.settings[key] = WoW95DB[key]
    end
end

-- Save settings
function WoW95:SaveSettings()
    for key, value in pairs(self.settings) do
        WoW95DB[key] = value
    end
end

-- Toggle window lock/unlock functionality
function WoW95:ToggleWindowLock(frame)
    if not frame then return end
    
    frame.isLocked = not frame.isLocked
    
    if frame.isLocked then
        -- Lock the window - disable movement
        frame:SetMovable(false)
        if frame.titleBar then
            frame.titleBar:SetScript("OnDragStart", nil)
            frame.titleBar:SetScript("OnDragStop", nil)
        end
        
        -- Visual feedback - darken the lock button
        if frame.lockButton and frame.lockButton.icon then
            frame.lockButton:SetBackdropColor(0.6, 0.6, 0.6, 1)
        end
        
        self:Debug("Window locked: " .. (frame:GetName() or "Unknown"))
    else
        -- Unlock the window - enable movement
        frame:SetMovable(true)
        if frame.titleBar then
            frame.titleBar:SetScript("OnDragStart", function()
                frame:StartMoving()
            end)
            frame.titleBar:SetScript("OnDragStop", function()
                frame:StopMovingOrSizing()
            end)
        end
        
        -- Visual feedback - restore lock button color
        if frame.lockButton and frame.lockButton.icon then
            frame.lockButton:SetBackdropColor(unpack(self.colors.buttonFace))
        end
        
        self:Debug("Window unlocked: " .. (frame:GetName() or "Unknown"))
    end
end

-- Main initialization
function WoW95:Initialize()
    self:Debug("Initializing WoW95...")
    
    -- Initialize settings
    self:InitializeSettings()
    
    self:Print("Windows 95 UI loaded! Welcome to the past!")
    
    -- Create test slash command
    SLASH_WOW95TEST1 = "/wow95test"
    SlashCmdList["WOW95TEST"] = function(msg)
        local count = 0
        for _ in pairs(WoW95.modules) do count = count + 1 end
        WoW95:Print("WoW95 is working! Modules registered: " .. count)
        for name, module in pairs(WoW95.modules) do
            WoW95:Print("- " .. name)
        end
        
        -- Test window creation
        if msg == "window" then
            WoW95:Print("Creating test window...")
            local testWindow = WoW95:CreateWindow("WoW95TestWindow", UIParent, 300, 200, "Test Window")
            if testWindow then
                testWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                testWindow:Show()
                WoW95:Print("Test window created successfully!")
            else
                WoW95:Print("ERROR: Failed to create test window")
            end
        end
    end
end

-- Event handler
function WoW95:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            self:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        -- Delay initialization of UI elements until player is fully loaded
        C_Timer.After(1, function()
            self:InitializeUI()
        end)
    end
end

-- UI initialization (called after player login)
function WoW95:InitializeUI()
    self:Debug("Initializing UI components...")
    
    -- UI components are now initialized by their respective modules
    -- No test window needed
end

-- Slash commands
SLASH_WOW95PARTYTEST1 = "/partytest"
SLASH_WOW95PARTYTEST2 = "/wow95partytest"
SlashCmdList["WOW95PARTYTEST"] = function(msg)
    local command = string.lower(msg or "")
    
    -- Debug what we have
    print("Debug: WoW95 exists:", WoW95 ~= nil)
    if WoW95 then
        print("Debug: WoW95.PartyRaid exists:", WoW95.PartyRaid ~= nil)
        print("Debug: WoW95.PartyRaidTest exists:", WoW95.PartyRaidTest ~= nil)
        print("Debug: Available modules:")
        for name, module in pairs(WoW95.modules or {}) do
            print("  -", name, type(module))
        end
    end
    
    if not WoW95 then
        print("WoW95 not loaded!")
        return
    end
    
    -- Direct party test implementation
    if command == "on" or command == "" then
        print("Creating test party window...")
        
        -- Create realistic party window with example players
        if not _G.WoW95TestPartyWindow then
            -- Create main party window container (no background)
            local testWindow = CreateFrame("Frame", "WoW95TestPartyWindow", UIParent)
            testWindow:SetSize(200, 250)
            testWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -120)
            
            -- Example party members with realistic data
            local partyMembers = {
                {name = UnitName("player") or "You", class = "PLAYER", health = 100, maxHealth = 100, power = 85, maxPower = 100, role = "TANK"},
                {name = "Shadowmend", class = "PRIEST", health = 65, maxHealth = 90, power = 40, maxPower = 100, role = "HEALER"},
                {name = "Frostboltz", class = "MAGE", health = 30, maxHealth = 75, power = 20, maxPower = 95, role = "DAMAGER"},
                {name = "Backstabby", class = "ROGUE", health = 95, maxHealth = 80, power = 60, maxPower = 100, role = "DAMAGER"}
            }
            
            -- Class colors matching WoW
            local classColors = {
                PLAYER = {0.78, 0.61, 0.43}, -- Assuming player is a Paladin
                PRIEST = {1.0, 1.0, 1.0},
                MAGE = {0.25, 0.78, 0.92},
                ROGUE = {1.0, 0.96, 0.41}
            }
            
            for i, memberData in ipairs(partyMembers) do
                -- Create member frame with secure template for mouseover casting
                local memberFrame = CreateFrame("Button", "WoW95TestMember" .. i, testWindow, "SecureUnitButtonTemplate")
                memberFrame:SetSize(190, 40)
                memberFrame:SetPoint("TOPLEFT", testWindow, "TOPLEFT", 0, -(i-1) * 45)
                
                -- Set up secure attributes for mouseover casting
                local unitId = (i == 1) and "player" or ("party" .. (i-1))
                memberFrame:SetAttribute("unit", unitId)
                memberFrame:SetAttribute("type1", "target") -- Left click to target
                memberFrame:SetAttribute("type2", "togglemenu") -- Right click for menu
                
                -- Enable mouseover casting - spells will automatically work
                memberFrame:EnableMouse(true)
                memberFrame:RegisterForClicks("AnyUp")
                
                -- Add mouseover highlight
                memberFrame:SetScript("OnEnter", function(self)
                    print("Mouseover: " .. memberData.name .. " (Unit: " .. unitId .. ") - Ready for spell casting!")
                end)
                memberFrame:SetScript("OnLeave", function(self)
                    -- Could add highlight removal here
                end)
                
                -- Name text with class color
                local nameText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameText:SetPoint("TOPLEFT", memberFrame, "TOPLEFT", 2, -2)
                nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                local classColor = classColors[memberData.class]
                nameText:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
                nameText:SetText(memberData.name)
                
                -- Health bar
                local healthBar = CreateFrame("StatusBar", nil, memberFrame)
                healthBar:SetSize(180, 12)
                healthBar:SetPoint("TOPLEFT", memberFrame, "TOPLEFT", 2, -16)
                healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                
                -- Health bar color based on percentage
                local healthPercent = memberData.health / memberData.maxHealth
                if healthPercent > 0.6 then
                    healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
                elseif healthPercent > 0.3 then
                    healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
                else
                    healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
                end
                
                healthBar:SetMinMaxValues(0, memberData.maxHealth)
                healthBar:SetValue(memberData.health)
                
                -- Health bar background
                local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
                healthBg:SetAllPoints(healthBar)
                healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
                healthBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
                
                -- Health text
                local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                healthText:SetPoint("CENTER", healthBar, "CENTER")
                healthText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                healthText:SetTextColor(1, 1, 1, 1)
                healthText:SetText(memberData.health .. "/" .. memberData.maxHealth)
                
                -- Power/Mana bar
                local powerBar = CreateFrame("StatusBar", nil, memberFrame)
                powerBar:SetSize(180, 8)
                powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
                powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
                
                -- Power color based on class
                if memberData.class == "PRIEST" or memberData.class == "MAGE" then
                    powerBar:SetStatusBarColor(0, 0, 1, 1) -- Blue mana
                elseif memberData.class == "ROGUE" then
                    powerBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow energy
                else
                    powerBar:SetStatusBarColor(0, 0, 1, 1) -- Default mana
                end
                
                powerBar:SetMinMaxValues(0, memberData.maxPower)
                powerBar:SetValue(memberData.power)
                
                -- Power bar background
                local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
                powerBg:SetAllPoints(powerBar)
                powerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
                powerBg:SetVertexColor(0.1, 0.1, 0.2, 0.8)
                
                -- Role icon
                if memberData.role then
                    local roleIcon = memberFrame:CreateTexture(nil, "OVERLAY")
                    roleIcon:SetSize(12, 12)
                    roleIcon:SetPoint("TOPRIGHT", memberFrame, "TOPRIGHT", -2, -2)
                    
                    if memberData.role == "TANK" then
                        roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                        roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
                    elseif memberData.role == "HEALER" then
                        roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                        roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
                    elseif memberData.role == "DAMAGER" then
                        roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                        roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
                    end
                end
            end
        end
        
        _G.WoW95TestPartyWindow:Show()
        print("Test party window created and shown!")
        
    elseif command == "off" then
        if _G.WoW95TestPartyWindow then
            _G.WoW95TestPartyWindow:Hide()
            print("Test party window hidden")
        else
            print("No test window to hide")
        end
    elseif command == "hide" then
        print("Manually hiding Blizzard party frames...")
        if WoW95.PartyRaid then
            WoW95.PartyRaid:HideBlizzardPartyFrames()
        else
            -- Manual hiding if module not loaded
            if PartyFrame then PartyFrame:Hide() end
            if CompactPartyFrame then CompactPartyFrame:Hide() end
            for i = 1, 4 do
                local frame = _G["PartyMemberFrame" .. i]
                if frame then frame:Hide() end
            end
            print("Manual hide attempted")
        end
    elseif command == "debug" then
        print("=== PartyRaid Module Debug Info ===")
        print("- WoW95.PartyRaid exists:", WoW95.PartyRaid ~= nil)
        print("- Group type:", IsInRaid() and "raid" or (IsInGroup() and "party" or "solo"))
        print("- Group members:", GetNumGroupMembers())
        
        -- Check mouseover casting settings
        print("- Mouseover casting enabled:", GetCVar("enableMouseoverCast") == "1")
        print("- Auto self cast enabled:", GetCVar("autoSelfCast") == "1")
        print("- Self cast key modifier:", GetCVar("autoSelfCastKey") or "none")
        print("- Party member in range:", UnitExists("party1") and UnitInRange("party1") or "no party1")
        if UnitExists("party1") then
            print("- Party1 name:", UnitName("party1"))
            print("- Party1 can assist:", UnitCanAssist("player", "party1"))
            print("- Party1 is connected:", UnitIsConnected("party1"))
        end
        
        -- List all registered modules
        local moduleNames = {}
        for name, _ in pairs(WoW95.modules or {}) do
            table.insert(moduleNames, name)
        end
        print("- Modules registered:", table.concat(moduleNames, ", "))
        
        if WoW95.PartyRaid then
            print("- Current group type:", WoW95.PartyRaid.currentGroupType)
            print("- Party container exists:", WoW95.PartyRaid.partyContainer ~= nil)
            if WoW95.PartyRaid.partyContainer then
                print("- Container visible:", WoW95.PartyRaid.partyContainer:IsShown())
                print("- Container size:", WoW95.PartyRaid.partyContainer:GetSize())
            end
            print("- Party frames count:", #(WoW95.PartyRaid.partyFrames or {}))
            print("- Module loaded and ready!")
        else
            print("ERROR: Module not loaded! Use /reload and check for lua errors.")
        end
        print("=====================================")
    elseif command == "fixmouseover" then
        print("Fixing mouseover casting settings...")
        SetCVar("autoSelfCast", "0")
        SetCVar("enableMouseoverCast", "1") 
        print("Settings updated:")
        print("- Auto self cast: DISABLED (was causing spells to target yourself)")
        print("- Mouseover casting: ENABLED")
        print("Try mouseover casting now!")
    elseif command == "testcast" then
        print("Testing spell casting on party member...")
        if UnitExists("party1") then
            print("Attempting to cast on party1: " .. UnitName("party1"))
            
            -- Try different targeting methods
            print("Method 1: Direct spell with unit parameter")
            if IsSpellKnown(2061) then -- Flash Heal
                CastSpellByName("Flash Heal", "party1")
                print("Attempted Flash Heal on party1")
            end
            
            print("Method 2: Target first, then cast")
            TargetUnit("party1")
            if UnitName("target") == UnitName("party1") then
                print("Successfully targeted party1, now casting...")
                if IsSpellKnown(2061) then
                    CastSpellByName("Flash Heal")
                    print("Cast Flash Heal on target")
                end
            else
                print("Failed to target party1")
            end
            
        else
            print("No party1 member found")
        end
    elseif command == "showblizzard" then
        print("Temporarily showing Blizzard party frames for testing...")
        if PartyFrame then 
            PartyFrame:Show() 
            PartyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
            print("PartyFrame shown")
        end
        if CompactPartyFrame then 
            CompactPartyFrame:Show()
            CompactPartyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
            print("CompactPartyFrame shown")
        end
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame then 
                frame:Show()
                frame:RegisterEvent("UNIT_HEALTH")
                print("PartyMemberFrame" .. i .. " shown")
            end
        end
        print("Test mouseover casting on Blizzard frames, then use 'hideblizzard' command")
    elseif command == "hideblizzard" then
        print("Hiding Blizzard party frames again...")
        if WoW95.PartyRaid then
            WoW95.PartyRaid:HideBlizzardPartyFrames()
            print("Blizzard frames hidden")
        end
    elseif command == "testspell" then
        print("=== Spell Casting Diagnostic ===")
        if UnitExists("party1") then
            local name = UnitName("party1")
            print("Testing spell casting on: " .. name)
            print("- Unit exists: " .. tostring(UnitExists("party1")))
            print("- Unit is connected: " .. tostring(UnitIsConnected("party1")))
            print("- Unit can assist: " .. tostring(UnitCanAssist("player", "party1")))
            print("- Unit in range: " .. tostring(UnitInRange("party1")))
            print("- Unit is friendly: " .. tostring(UnitIsFriend("player", "party1")))
            print("- Player can attack: " .. tostring(UnitCanAttack("player", "party1")))
            print("- Unit is same faction: " .. tostring(UnitFactionGroup("player") == UnitFactionGroup("party1")))
            
            local distance = C_MapAndQuestLog and C_MapAndQuestLog.GetDistanceSqToQuest and "unknown" or "N/A"
            print("- Approximate distance: " .. tostring(distance))
            
            -- Check spell availability
            print("- Flash of Light known: " .. tostring(IsSpellKnown(19750) or IsSpellKnown(82326)))
            print("- In combat: " .. tostring(InCombatLockdown()))
            
        else
            print("No party1 member to test with")
        end
        print("================================")
    else
        print("Usage: /partytest [on|off|debug|fixmouseover|showblizzard|hideblizzard|testspell]")
        print("  on           - Enable test mode with fake party members")
        print("  off          - Disable test mode")
        print("  debug        - Show module status")
        print("  fixmouseover - Fix mouseover casting settings")
        print("  showblizzard - Show Blizzard frames to test mouseover")
        print("  hideblizzard - Hide Blizzard frames again")
        print("  testspell    - Test spell casting mechanics")
    end
end

-- Create main event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    WoW95:OnEvent(event, ...)
end)