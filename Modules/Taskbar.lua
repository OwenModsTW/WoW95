-- WoW95 Taskbar Module
-- Creates the Windows 95 style taskbar at the bottom of the screen

local addonName, WoW95 = ...

local Taskbar = {}
WoW95.Taskbar = Taskbar

-- Taskbar settings
local TASKBAR_HEIGHT = 30
local START_BUTTON_WIDTH = 60
local SYSTEM_TRAY_WIDTH = 100
local WINDOW_BUTTON_WIDTH = 150
local WINDOW_BUTTON_MAX_WIDTH = 200

-- Taskbar state
Taskbar.frame = nil
Taskbar.startButton = nil
Taskbar.windowButtons = {}
Taskbar.systemTray = nil
Taskbar.timeDisplay = nil
Taskbar.windowArea = nil

function Taskbar:Init()
    WoW95:Debug("Initializing Taskbar module...")
    
    -- Register for window events
    WoW95:RegisterEvent("WINDOW_OPENED", function(frame) self:OnWindowOpened(frame) end)
    WoW95:RegisterEvent("WINDOW_CLOSED", function(frame) self:OnWindowClosed(frame) end)
    
    self:CreateTaskbar()
    self:CreateStartButton()
    self:CreateWindowArea()
    self:CreateSystemTray()
    self:CreateTimeDisplay()
    
    -- Hide Blizzard UI elements we're replacing
    if WoW95.settings.hideBlizzardFrames then
        self:HideBlizzardElements()
    end
    
    WoW95:Debug("Taskbar initialized successfully!")
end

function Taskbar:CreateTaskbar()
    -- Main taskbar frame
    self.frame = CreateFrame("Frame", "WoW95Taskbar", UIParent, "BackdropTemplate")
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    self.frame:SetHeight(TASKBAR_HEIGHT)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(100)
    
    -- Taskbar backdrop (solid gray)
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    self.frame:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Solid Windows 95 gray
    self.frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Top highlight line for 3D effect
    local topHighlight = self.frame:CreateTexture(nil, "OVERLAY")
    topHighlight:SetColorTexture(1, 1, 1, 0.8)
    topHighlight:SetHeight(1)
    topHighlight:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
    topHighlight:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
    
    -- Left highlight line
    local leftHighlight = self.frame:CreateTexture(nil, "OVERLAY")
    leftHighlight:SetColorTexture(1, 1, 1, 0.8)
    leftHighlight:SetWidth(1)
    leftHighlight:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
    leftHighlight:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 2, 2)
end

function Taskbar:CreateStartButton()
    self.startButton = CreateFrame("Button", "WoW95StartButton", self.frame, "BackdropTemplate")
    self.startButton:SetSize(START_BUTTON_WIDTH, TASKBAR_HEIGHT - 4)
    self.startButton:SetPoint("LEFT", self.frame, "LEFT", 2, 0)
    
    -- Start button backdrop (solid gray)
    self.startButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.startButton:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Solid Windows 95 gray
    self.startButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Windows logo (custom start button texture)
    local logo = self.startButton:CreateTexture(nil, "ARTWORK")
    logo:SetSize(16, 16)
    logo:SetPoint("LEFT", self.startButton, "LEFT", 4, 0)
    logo:SetTexture(WoW95.textures.startButton)
    
    -- Start button text - UPDATED for readability
    local startText = self.startButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    startText:SetPoint("LEFT", logo, "RIGHT", 4, 0)
    startText:SetText("Start")
    startText:SetTextColor(0, 0, 0, 1) -- Black text for better contrast
    startText:SetFont("Fonts\\FRIZQT__.TTF", 11, "") -- Remove OUTLINE flag
    startText:SetShadowOffset(0, 0) -- Remove shadow
    
    -- Start button functionality
    self.startButton:SetScript("OnClick", function()
        self:ToggleStartMenu()
    end)
    
    -- Button effects
    self.startButton:SetScript("OnEnter", function()
        self.startButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
    end)
    self.startButton:SetScript("OnLeave", function()
        self.startButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    end)
    self.startButton:SetScript("OnMouseDown", function()
        self.startButton:SetBackdropColor(0.6, 0.6, 0.6, 1)
        startText:SetPoint("LEFT", logo, "RIGHT", 5, -1)
    end)
    self.startButton:SetScript("OnMouseUp", function()
        self.startButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        startText:SetPoint("LEFT", logo, "RIGHT", 4, 0)
    end)
end

function Taskbar:CreateWindowArea()
    -- Area between start button and system tray for window buttons
    self.windowArea = CreateFrame("Frame", "WoW95WindowArea", self.frame)
    self.windowArea:SetPoint("LEFT", self.startButton, "RIGHT", 4, 0)
    self.windowArea:SetPoint("RIGHT", self.frame, "RIGHT", -SYSTEM_TRAY_WIDTH - 4, 0)
    self.windowArea:SetHeight(TASKBAR_HEIGHT - 4)
    
    -- Separator line after start button
    local separator1 = self.frame:CreateTexture(nil, "OVERLAY")
    separator1:SetColorTexture(0.5, 0.5, 0.5, 1)
    separator1:SetSize(1, TASKBAR_HEIGHT - 8)
    separator1:SetPoint("LEFT", self.startButton, "RIGHT", 2, 0)
    
    -- Separator line before system tray
    local separator2 = self.frame:CreateTexture(nil, "OVERLAY")
    separator2:SetColorTexture(0.5, 0.5, 0.5, 1)
    separator2:SetSize(1, TASKBAR_HEIGHT - 8)
    separator2:SetPoint("RIGHT", self.windowArea, "RIGHT", 2, 0)
end

function Taskbar:CreateSystemTray()
    -- System tray area (right side of taskbar)
    self.systemTray = CreateFrame("Frame", "WoW95SystemTray", self.frame, "BackdropTemplate")
    self.systemTray:SetSize(SYSTEM_TRAY_WIDTH, TASKBAR_HEIGHT - 4)
    self.systemTray:SetPoint("RIGHT", self.frame, "RIGHT", -2, 0)
    
    -- System tray solid gray background
    self.systemTray:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    self.systemTray:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Solid Windows 95 gray
    self.systemTray:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

function Taskbar:CreateTimeDisplay()
    -- Time and date display in system tray - UPDATED for readability
    self.timeDisplay = self.systemTray:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.timeDisplay:SetPoint("CENTER", self.systemTray, "CENTER", 0, 0)
    self.timeDisplay:SetFont("Fonts\\FRIZQT__.TTF", 10, "") -- Remove outline
    self.timeDisplay:SetTextColor(0, 0, 0, 1) -- Black text for better contrast
    self.timeDisplay:SetShadowOffset(0, 0) -- Remove shadow
    
    -- Update time every second
    local timeFrame = CreateFrame("Frame")
    timeFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
        if self.timeSinceLastUpdate >= 1 then
            Taskbar:UpdateTimeDisplay()
            self.timeSinceLastUpdate = 0
        end
    end)
end

function Taskbar:UpdateTimeDisplay()
    local currentTime = date("%I:%M %p")
    local currentDate = date("%m/%d/%Y")
    self.timeDisplay:SetText(currentTime .. "\n" .. currentDate)
end

function Taskbar:CreateWindowButton(frame)
    local windowName = frame:GetName() or "Unknown"
    local title = ""
    local isProgramWindow = false
    local iconTexture = nil
    
    -- Handle program windows from Windows module
    if frame.programName and frame.frameName then
        -- This is a program window from the Windows module
        title = frame.programName -- Use the program name (e.g., "Character Sheet")
        windowName = frame.frameName -- Use the original frame name for unique identification
        isProgramWindow = true
        
        -- Get icon from program definition
        if WoW95.PROGRAMS and WoW95.PROGRAMS[frame.frameName] then
            iconTexture = WoW95.PROGRAMS[frame.frameName].iconTexture
        end
        
        WoW95:Debug("Creating taskbar button for program: " .. title .. " (frame: " .. windowName .. ")")
    else
        -- Regular WoW95 window
        title = frame.titleText and frame.titleText:GetText() or windowName
        WoW95:Debug("Creating taskbar button for window: " .. title)
    end
    
    -- Don't create buttons for our own UI elements (except program windows)
    if string.find(windowName, "WoW95") and not frame.programName then
        WoW95:Debug("Skipping taskbar button for internal WoW95 window: " .. windowName)
        return
    end
    
    -- Don't create duplicate buttons
    if self.windowButtons[windowName] then
        WoW95:Debug("Taskbar button already exists for: " .. windowName)
        return
    end
    
    local button = CreateFrame("Button", "WoW95TaskbarButton_" .. windowName, self.windowArea, "BackdropTemplate")
    button:SetHeight(TASKBAR_HEIGHT - 6)
    
    -- Calculate button width based on number of open windows
    local numButtons = 0
    for _ in pairs(self.windowButtons) do
        numButtons = numButtons + 1
    end
    
    local availableWidth = self.windowArea:GetWidth() - 8
    local buttonWidth = math.min(WINDOW_BUTTON_MAX_WIDTH, math.max(80, availableWidth / (numButtons + 1)))
    button:SetWidth(buttonWidth)
    
    -- Enhanced button backdrop for program windows
    if isProgramWindow then
        -- Program windows get a more distinctive look
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        button:SetBackdropColor(0.8, 0.8, 0.9, 1) -- Slightly blue tint for programs
        button:SetBackdropBorderColor(0.4, 0.4, 0.6, 1) -- Blue-tinted border
    else
        -- Regular windows
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        button:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Standard gray
        button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    
    -- Create icon for program windows
    local buttonIcon = nil
    if isProgramWindow and iconTexture then
        buttonIcon = button:CreateTexture(nil, "ARTWORK")
        buttonIcon:SetSize(16, 16)
        buttonIcon:SetPoint("LEFT", button, "LEFT", 4, 0)
        buttonIcon:SetTexture(iconTexture)
        buttonIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Crop the icon nicely
    end
    
    -- Button text - UPDATED for readability and icon spacing
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if buttonIcon then
        buttonText:SetPoint("LEFT", buttonIcon, "RIGHT", 4, 0)
        buttonText:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    else
        buttonText:SetPoint("LEFT", button, "LEFT", 6, 0)
        buttonText:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    end
    buttonText:SetJustifyH("LEFT")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 10, "") -- Remove outline
    buttonText:SetTextColor(0, 0, 0, 1) -- Black text for better contrast
    buttonText:SetShadowOffset(0, 0) -- Remove shadow
    
    -- Truncate long titles and set text
    local truncatedTitle = title
    local maxLength = buttonIcon and 12 or 18 -- Shorter text if there's an icon
    if string.len(title) > maxLength then
        truncatedTitle = string.sub(title, 1, maxLength - 3) .. "..."
    end
    buttonText:SetText(truncatedTitle)
    
    -- Button functionality - handle program windows differently
    button:SetScript("OnClick", function()
        if frame.programName and frame.frameName then
            WoW95:Debug("Clicking program window button: " .. frame.programName .. " (" .. frame.frameName .. ")")
            -- This is a program window - use proper toggle method
            if WoW95.Windows and WoW95.Windows.ToggleProgramWindow then
                WoW95.Windows:ToggleProgramWindow(frame.frameName)
            else
                -- Fallback to direct toggle if Windows module not available
                local originalFrame = _G[frame.frameName]
                if originalFrame then
                    if originalFrame:IsShown() then
                        originalFrame:Hide()
                    else
                        originalFrame:Show()
                    end
                end
            end
        else
            WoW95:Debug("Clicking regular window button: " .. title)
            -- Regular window behavior
            if frame:IsShown() then
                frame:Hide()
                button:SetBackdropColor(0.75, 0.75, 0.75, 1)
            else
                frame:Show()
                frame:Raise()
                button:SetBackdropColor(0.8, 0.8, 1, 1) -- Highlighted when active
            end
        end
    end)
    
    -- Enhanced button effects for program windows
    button:SetScript("OnEnter", function()
        if frame:IsShown() then
            if isProgramWindow then
                button:SetBackdropColor(1, 1, 1, 1) -- Bright white when hovered and active
            else
                button:SetBackdropColor(0.9, 0.9, 1, 1)
            end
        else
            if isProgramWindow then
                button:SetBackdropColor(0.9, 0.9, 0.95, 1) -- Light blue when hovered
            else
                button:SetBackdropColor(0.85, 0.85, 0.85, 1)
            end
        end
        
        -- Show tooltip with full program name
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(frame.programName or title)
        if isProgramWindow then
            GameTooltip:AddLine("Program Window", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        if frame:IsShown() then
            if isProgramWindow then
                button:SetBackdropColor(0.9, 0.9, 1, 1) -- Active blue
            else
                button:SetBackdropColor(0.8, 0.8, 1, 1)
            end
        else
            if isProgramWindow then
                button:SetBackdropColor(0.8, 0.8, 0.9, 1) -- Inactive blue
            else
                button:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
        end
        GameTooltip:Hide()
    end)
    
    -- Store references
    button.targetFrame = frame
    button.buttonText = buttonText
    button.buttonIcon = buttonIcon
    button.isProgramWindow = isProgramWindow
    self.windowButtons[windowName] = button
    
    -- Position buttons after creating
    self:ArrangeWindowButtons()
    
    WoW95:Debug("Created taskbar button: " .. truncatedTitle .. " (" .. windowName .. ")")
    
    return button
end

function Taskbar:ArrangeWindowButtons()
    local buttons = {}
    for _, button in pairs(self.windowButtons) do
        table.insert(buttons, button)
    end
    
    if #buttons == 0 then return end
    
    -- Calculate button width
    local availableWidth = self.windowArea:GetWidth() - 8
    local buttonWidth = math.min(WINDOW_BUTTON_MAX_WIDTH, math.max(80, availableWidth / #buttons))
    
    -- Position buttons
    for i, button in ipairs(buttons) do
        button:SetWidth(buttonWidth)
        button:ClearAllPoints()
        if i == 1 then
            button:SetPoint("LEFT", self.windowArea, "LEFT", 4, 0)
        else
            button:SetPoint("LEFT", buttons[i-1], "RIGHT", 2, 0)
        end
    end
end

function Taskbar:OnWindowOpened(frame)
    WoW95:Debug("Taskbar received window opened event for: " .. (frame:GetName() or "Unknown"))
    
    -- Check if it's a WoW95 window
    if not frame or not frame.isWoW95Window then 
        WoW95:Debug("Frame is not a WoW95 window, ignoring")
        return 
    end
    
    -- Log frame properties for debugging
    WoW95:Debug("Frame properties - Name: " .. (frame:GetName() or "nil") .. 
                ", ProgramName: " .. (frame.programName or "nil") .. 
                ", FrameName: " .. (frame.frameName or "nil") ..
                ", IsProgramWindow: " .. tostring(frame.isProgramWindow or false))
    
    self:CreateWindowButton(frame)
end

function Taskbar:OnWindowClosed(frame)
    if not frame then return end
    
    local windowName = frame:GetName()
    if frame.frameName then
        windowName = frame.frameName -- Use the Blizzard frame name for program windows
    end
    
    WoW95:Debug("Taskbar received window closed event for: " .. (windowName or "Unknown"))
    
    if windowName and self.windowButtons[windowName] then
        self.windowButtons[windowName]:Hide()
        self.windowButtons[windowName] = nil
        self:ArrangeWindowButtons()
        WoW95:Debug("Removed taskbar button for: " .. windowName)
    end
end

function Taskbar:ToggleStartMenu()
    -- Use the StartMenu module if available
    if WoW95.StartMenu then
        WoW95.StartMenu:Toggle()
    else
        -- Fallback for testing if StartMenu isn't loaded yet
        WoW95:Print("Start Menu module not loaded!")
        
        -- Create a test window for testing taskbar functionality
        local testWindow = WoW95:CreateWindow("WoW95TestWindow" .. GetTime(), UIParent, 350, 250, "Test Window " .. math.random(1, 100))
        testWindow:SetPoint("CENTER", UIParent, "CENTER", math.random(-200, 200), math.random(-100, 100))
        testWindow:Show()
        WoW95:OnWindowOpened(testWindow)
    end
end

function Taskbar:HideBlizzardElements()
    -- Hide various Blizzard UI elements that conflict with our taskbar
    if MainMenuBar then
        MainMenuBar:SetAlpha(0)
        MainMenuBar:EnableMouse(false)
    end
    
    if MainMenuBarArtFrame then
        MainMenuBarArtFrame:Hide()
    end
    
    if StatusTrackingBarManager then
        StatusTrackingBarManager:Hide()
    end
    
    -- We'll add more elements to hide as we develop
end

function Taskbar:Show()
    if self.frame then
        self.frame:Show()
    end
end

function Taskbar:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Register the module
WoW95:RegisterModule("Taskbar", Taskbar)