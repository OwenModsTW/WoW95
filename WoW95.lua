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
    add = "Interface\\AddOns\\WoW95\\Media\\add"
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
        self:ToggleWindowLock(frame)
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
        self:OnWindowClosed(frame)
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
        button:SetBackdropColor(unpack(self.colors.buttonFace))
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
        self:SetBackdropColor(unpack(WoW95.colors.buttonFace))
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

-- Create main event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    WoW95:OnEvent(event, ...)
end)