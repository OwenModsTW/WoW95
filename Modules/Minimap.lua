-- WoW95 Minimap Module
-- Windows 95 styled square minimap

local addonName, WoW95 = ...

local Minimap = {}
WoW95.Minimap = Minimap

-- Minimap settings
local MINIMAP_SIZE = 200
local TITLE_BAR_HEIGHT = 18
local BORDER_SIZE = 4

-- Minimap state
Minimap.frame = nil
Minimap.minimapFrame = nil
Minimap.titleBar = nil
Minimap.locked = false

function Minimap:Init()
    WoW95:Debug("Initializing Minimap module...")
    
    -- Hide default Blizzard minimap elements FIRST
    self:HideBlizzardMinimap()
    
    -- Create our Windows 95 minimap container
    self:CreateMinimapFrame()
    
    -- Setup the actual minimap display
    self:SetupMinimapDisplay()
    
    -- Create minimap buttons and controls
    self:CreateMinimapControls()
    
    -- Position minimap elements
    self:PositionMinimapElements()
    
    WoW95:Debug("Minimap module initialized successfully!")
end

function Minimap:CreateMinimapFrame()
    -- Main minimap container
    self.frame = CreateFrame("Frame", "WoW95MinimapFrame", UIParent, "BackdropTemplate")
    self.frame:SetSize(MINIMAP_SIZE + (BORDER_SIZE * 2), MINIMAP_SIZE + TITLE_BAR_HEIGHT + (BORDER_SIZE * 2))
    self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetMovable(true)
    self.frame:SetClampedToScreen(true)
    
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
    self.titleBar = CreateFrame("Frame", "WoW95MinimapTitleBar", self.frame, "BackdropTemplate")
    self.titleBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
    self.titleBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
    self.titleBar:SetHeight(TITLE_BAR_HEIGHT)
    
    self.titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    self.titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- Windows 95 blue
    self.titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = self.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", self.titleBar, "LEFT", 5, 0)
    titleText:SetText("Map")
    titleText:SetTextColor(1, 1, 1, 1) -- White text on blue
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    titleText:SetShadowOffset(1, -1)
    titleText:SetShadowColor(0, 0, 0, 0.8)
    
    -- Make title bar draggable
    self.titleBar:EnableMouse(true)
    self.titleBar:RegisterForDrag("LeftButton")
    self.titleBar:SetScript("OnDragStart", function()
        if not self.locked then
            self.frame:StartMoving()
        end
    end)
    self.titleBar:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
    end)
    
    -- No minimize button - keep minimap always visible
    
    -- Create lock button
    local lockButton = CreateFrame("Button", "WoW95MinimapLockButton", self.titleBar, "BackdropTemplate")
    lockButton:SetSize(16, 14)
    lockButton:SetPoint("RIGHT", self.titleBar, "RIGHT", -2, 0)
    
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
    lockText:SetShadowOffset(0, 0)
    lockText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    
    lockButton:SetScript("OnClick", function()
        self:ToggleLock()
    end)
    
    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(lockButton, "ANCHOR_TOP")
        GameTooltip:SetText(self.locked and "Unlock Map" or "Lock Map")
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Store references
    self.frame.titleText = titleText
    self.frame.lockButton = lockButton
    self.frame.lockText = lockText
end

function Minimap:SetupMinimapDisplay()
    -- Create container for the actual minimap
    self.minimapFrame = CreateFrame("Frame", "WoW95MinimapContainer", self.frame)
    self.minimapFrame:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", BORDER_SIZE, -BORDER_SIZE)
    self.minimapFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
    
    -- Get the Blizzard minimap
    local blizzMinimap = _G["Minimap"]
    if blizzMinimap then
        -- Store original settings
        self.originalMinimapParent = blizzMinimap:GetParent()
        
        -- Move to our container and make it square by using a square mask texture
        blizzMinimap:SetParent(self.minimapFrame)
        blizzMinimap:ClearAllPoints()
        blizzMinimap:SetAllPoints(self.minimapFrame)
        blizzMinimap:Show()
        blizzMinimap:SetAlpha(1)
        
        -- Try to apply square mask texture
        if blizzMinimap.SetMaskTexture then
            blizzMinimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
        end
        
        -- Create a square clipping frame over the minimap
        local clipFrame = CreateFrame("Frame", nil, self.minimapFrame)
        clipFrame:SetAllPoints(self.minimapFrame)
        clipFrame:SetClipsChildren(true)
        
        -- Move minimap to the clipping frame
        blizzMinimap:SetParent(clipFrame)
        
        WoW95:Debug("Applied square masking to minimap")
    else
        WoW95:Debug("ERROR: Could not find Blizzard Minimap!")
    end
    
    -- Hide ALL circular border elements more aggressively
    local borderElements = {
        "MinimapBorder",
        "MinimapBorderTop",
        "MinimapCompass"
    }
    
    for _, elementName in ipairs(borderElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            element:SetAlpha(0)
            element:SetParent(CreateFrame("Frame")) -- Move to nowhere
        end
    end
    
    -- Hide the golden outline texture that's showing
    if blizzMinimap then
        local regions = {blizzMinimap:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture then
                    local textureName = texture:lower()
                    -- Hide golden border, circular border, and outline textures
                    if string.find(textureName, "border") or 
                       string.find(textureName, "circle") or 
                       string.find(textureName, "outline") or
                       string.find(textureName, "ring") or
                       string.find(textureName, "edge") then
                        region:Hide()
                        region:SetAlpha(0)
                        WoW95:Debug("Hidden texture: " .. (texture or "unknown"))
                    end
                end
            end
        end
        
        -- Also check children for border textures
        local children = {blizzMinimap:GetChildren()}
        for _, child in ipairs(children) do
            if child and child:GetObjectType() == "Texture" then
                if child.GetTexture then
                    local texture = child:GetTexture()
                    if texture then
                        local textureName = texture:lower()
                        if string.find(textureName, "border") or 
                           string.find(textureName, "outline") or
                           string.find(textureName, "ring") then
                            child:Hide()
                            child:SetAlpha(0)
                            WoW95:Debug("Hidden child texture: " .. (texture or "unknown"))
                        end
                    end
                end
            end
        end
    end
    
    -- Create our own square border around the minimap
    local mapBorder = CreateFrame("Frame", "WoW95MinimapBorder", self.minimapFrame, "BackdropTemplate")
    mapBorder:SetAllPoints(self.minimapFrame)
    mapBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 2,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    mapBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    mapBorder:SetFrameLevel(self.minimapFrame:GetFrameLevel() + 10)
end

function Minimap:CreateMinimapControls()
    -- Create minimap button collector (like the addon you showed)
    local buttonCollector = CreateFrame("Button", "WoW95MinimapButtonCollector", self.frame, "BackdropTemplate")
    buttonCollector:SetSize(20, 20)
    buttonCollector:SetPoint("TOPLEFT", self.minimapFrame, "TOPLEFT", -25, 25)
    
    buttonCollector:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    buttonCollector:SetBackdropColor(0.75, 0.75, 0.75, 1)
    buttonCollector:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create icon for button collector (grid icon)
    local collectorIcon = buttonCollector:CreateTexture(nil, "ARTWORK")
    collectorIcon:SetAllPoints(buttonCollector)
    collectorIcon:SetTexture("Interface\\Icons\\Ability_Spy") -- Grid-like spy icon
    collectorIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Create the popup frame for collected buttons
    local buttonPopup = CreateFrame("Frame", "WoW95MinimapButtonPopup", UIParent, "BackdropTemplate")
    buttonPopup:SetSize(400, 60)
    buttonPopup:SetPoint("TOPLEFT", buttonCollector, "BOTTOMLEFT", 0, -5)
    buttonPopup:SetFrameStrata("TOOLTIP")
    buttonPopup:SetFrameLevel(1000)
    buttonPopup:Hide()
    
    buttonPopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    buttonPopup:SetBackdropColor(0.75, 0.75, 0.75, 1)
    buttonPopup:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Button collector click handler
    buttonCollector:SetScript("OnClick", function()
        if buttonPopup:IsShown() then
            buttonPopup:Hide()
        else
            self:PopulateButtonPopup(buttonPopup)
            buttonPopup:Show()
        end
    end)
    
    buttonCollector:SetScript("OnEnter", function()
        buttonCollector:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(buttonCollector, "ANCHOR_TOP")
        GameTooltip:SetText("Minimap Button Collection")
        GameTooltip:AddLine("Click to show/hide addon buttons", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    buttonCollector:SetScript("OnLeave", function()
        buttonCollector:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Create Renown/Major Factions button
    local renownButton = CreateFrame("Button", "WoW95RenownButton", self.frame, "BackdropTemplate")
    renownButton:SetSize(20, 20)
    renownButton:SetPoint("BOTTOMLEFT", self.minimapFrame, "BOTTOMLEFT", -25, -25)
    
    renownButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    renownButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    renownButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create icon for renown button
    local renownIcon = renownButton:CreateTexture(nil, "ARTWORK")
    renownIcon:SetAllPoints(renownButton)
    renownIcon:SetTexture("Interface\\Icons\\Achievement_Reputation_01") -- Better renown-like icon
    renownIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    renownButton:SetScript("OnClick", function()
        -- Toggle Major Factions frame (equivalent to the amber renown button)
        if ExpansionLandingPage and ExpansionLandingPage:IsShown() then
            HideUIPanel(ExpansionLandingPage)
        else
            ShowUIPanel(ExpansionLandingPage)
        end
    end)
    
    renownButton:SetScript("OnEnter", function()
        renownButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(renownButton, "ANCHOR_TOP")
        GameTooltip:SetText("Major Factions")
        GameTooltip:AddLine("Click to open faction renown", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    renownButton:SetScript("OnLeave", function()
        renownButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Zoom in button
    local zoomInButton = CreateFrame("Button", "WoW95MinimapZoomIn", self.frame, "BackdropTemplate")
    zoomInButton:SetSize(20, 15)
    zoomInButton:SetPoint("BOTTOMRIGHT", self.minimapFrame, "BOTTOMRIGHT", 0, -20)
    
    zoomInButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    zoomInButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    zoomInButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local zoomInText = zoomInButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoomInText:SetPoint("CENTER")
    zoomInText:SetText("+")
    zoomInText:SetTextColor(0, 0, 0, 1)
    zoomInText:SetShadowOffset(0, 0)
    zoomInText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    zoomInButton:SetScript("OnClick", function()
        -- Use the global Minimap zoom methods properly
        if _G["Minimap"] and _G["Minimap"].ZoomIn then
            _G["Minimap"].ZoomIn:Click()
        end
    end)
    
    zoomInButton:SetScript("OnEnter", function()
        zoomInButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(zoomInButton, "ANCHOR_TOP")
        GameTooltip:SetText("Zoom In")
        GameTooltip:Show()
    end)
    
    zoomInButton:SetScript("OnLeave", function()
        zoomInButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Zoom out button
    local zoomOutButton = CreateFrame("Button", "WoW95MinimapZoomOut", self.frame, "BackdropTemplate")
    zoomOutButton:SetSize(20, 15)
    zoomOutButton:SetPoint("RIGHT", zoomInButton, "LEFT", -2, 0)
    
    zoomOutButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    zoomOutButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    zoomOutButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local zoomOutText = zoomOutButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoomOutText:SetPoint("CENTER")
    zoomOutText:SetText("-")
    zoomOutText:SetTextColor(0, 0, 0, 1)
    zoomOutText:SetShadowOffset(0, 0)
    zoomOutText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    zoomOutButton:SetScript("OnClick", function()
        -- Use the global Minimap zoom methods properly
        if _G["Minimap"] and _G["Minimap"].ZoomOut then
            _G["Minimap"].ZoomOut:Click()
        end
    end)
    
    zoomOutButton:SetScript("OnEnter", function()
        zoomOutButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(zoomOutButton, "ANCHOR_TOP")
        GameTooltip:SetText("Zoom Out")
        GameTooltip:Show()
    end)
    
    zoomOutButton:SetScript("OnLeave", function()
        zoomOutButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Store references
    self.frame.zoomInButton = zoomInButton
    self.frame.zoomOutButton = zoomOutButton
    self.frame.buttonCollector = buttonCollector
    self.frame.buttonPopup = buttonPopup
    self.frame.renownButton = renownButton
    self.collectedButtons = {}
end

function Minimap:PopulateButtonPopup(popup)
    -- Clear existing content in popup
    for _, child in ipairs({popup:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local xOffset = 5
    local buttonSize = 24
    local spacing = 2
    local buttonCount = 0
    
    -- Show the actual collected buttons in the popup
    for _, button in ipairs(self.collectedButtons) do
        if button and button:IsObjectType("Button") then
            -- Move the actual button to the popup and position it
            button:SetParent(popup)
            button:ClearAllPoints()
            button:SetPoint("LEFT", popup, "LEFT", xOffset, 0)
            button:SetSize(buttonSize, buttonSize)
            button:Show()
            
            -- Ensure click handler hides popup
            local originalOnClick = button:GetScript("OnClick")
            button:SetScript("OnClick", function(self, mouseButton, ...)
                if originalOnClick then
                    originalOnClick(self, mouseButton, ...)
                end
                popup:Hide() -- Hide popup after clicking
            end)
            
            xOffset = xOffset + buttonSize + spacing
            buttonCount = buttonCount + 1
        end
    end
    
    -- Adjust popup width based on number of buttons
    popup:SetWidth(math.max(100, xOffset + 5))
    
    -- Debug message
    WoW95:Debug("Populated button popup with " .. buttonCount .. " actual addon buttons")
    
    -- If no buttons were added, show a message
    if buttonCount == 0 then
        local noButtonsText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noButtonsText:SetPoint("CENTER", popup, "CENTER", 0, 0)
        noButtonsText:SetText("No addon buttons collected")
        noButtonsText:SetTextColor(1, 1, 1, 1) -- White text
    end
end

function Minimap:PositionMinimapElements()
    -- Move minimap buttons and elements to our frame with better positioning
    local minimapButtons = {
        "MiniMapTrackingButton",
        "MiniMapMailFrame", 
        "MiniMapBattlefieldFrame",
        "MiniMapLFGFrame",
        "MinimapZoneTextButton",
        "GameTimeFrame"
    }
    
    for _, buttonName in ipairs(minimapButtons) do
        local button = _G[buttonName]
        if button then
            button:SetParent(self.frame)
            button:ClearAllPoints()
            button:Show() -- Make sure button is visible
            button:SetFrameStrata("HIGH") -- Ensure visibility above minimap
            
            -- Position buttons around our square minimap with better spacing
            if buttonName == "MiniMapTrackingButton" then
                button:SetPoint("TOPLEFT", self.minimapFrame, "TOPLEFT", -20, 20)
            elseif buttonName == "MiniMapMailFrame" then
                button:SetPoint("TOPRIGHT", self.minimapFrame, "TOPRIGHT", 20, 20)
            elseif buttonName == "MiniMapBattlefieldFrame" then
                button:SetPoint("BOTTOMLEFT", self.minimapFrame, "BOTTOMLEFT", -20, -20)
            elseif buttonName == "MiniMapLFGFrame" then
                button:SetPoint("BOTTOMRIGHT", self.minimapFrame, "BOTTOMRIGHT", 20, -20)
            elseif buttonName == "MinimapZoneTextButton" then
                button:SetPoint("TOP", self.minimapFrame, "TOP", 0, 25)
            elseif buttonName == "GameTimeFrame" then
                button:SetPoint("BOTTOM", self.minimapFrame, "BOTTOM", 0, -30)
            end
            
            WoW95:Debug("Positioned minimap button: " .. buttonName)
        end
    end
    
    -- Handle addon minimap buttons
    self:HandleAddonButtons()
end

function Minimap:HandleAddonButtons()
    -- Collect all addon buttons attached to minimap
    self.collectedButtons = {}
    
    -- Get all children of the original Minimap frame
    local blizzMinimap = _G["Minimap"]
    if blizzMinimap then
        local children = {blizzMinimap:GetChildren()}
        for _, child in ipairs(children) do
            if child and child:IsShown() and child:GetName() then
                local childName = child:GetName()
                -- Check if it's likely an addon button (excluding system buttons)
                if (string.find(childName, "LibDBIcon") or 
                   string.find(childName, "Button")) and
                   not string.find(childName, "MiniMap") and  -- Exclude system minimap buttons
                   not string.find(childName, "WoW95") then   -- Exclude our own buttons
                    
                    -- Collect addon buttons for the button collector popup
                    table.insert(self.collectedButtons, child)
                    
                    -- Hide the button from the minimap area initially
                    child:Hide()
                    
                    WoW95:Debug("Collected addon button: " .. childName)
                end
            end
        end
    end
    
    -- Delay check for LibDataBroker icons that might load later
    C_Timer.After(2, function()
        self:RepositionLateLoadingAddons()
    end)
    
    -- Also check after a longer delay for late-loading addons
    C_Timer.After(10, function()
        self:RepositionLateLoadingAddons()
    end)
end

function Minimap:RepositionLateLoadingAddons()
    -- Check for LibDataBroker icon registry
    if LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true) then
        local LibDBIcon = LibStub("LibDBIcon-1.0")
        if LibDBIcon and LibDBIcon.objects then
            for name, obj in pairs(LibDBIcon.objects) do
                if obj.button then
                    -- Add to collected buttons if not already there
                    local alreadyCollected = false
                    for _, collectedButton in ipairs(self.collectedButtons) do
                        if collectedButton == obj.button then
                            alreadyCollected = true
                            break
                        end
                    end
                    
                    if not alreadyCollected then
                        table.insert(self.collectedButtons, obj.button)
                        WoW95:Debug("Late-collected LibDBIcon button: " .. name)
                    end
                    
                    -- Hide the button initially - will be shown in popup
                    obj.button:Hide()
                end
            end
        end
    end
    
    -- Also scan for any new buttons that appeared on the minimap
    local blizzMinimap = _G["Minimap"]
    if blizzMinimap then
        local children = {blizzMinimap:GetChildren()}
        for _, child in ipairs(children) do
            if child and child:GetName() then
                local childName = child:GetName()
                if (string.find(childName, "LibDBIcon") or 
                   string.find(childName, "Button")) and
                   not string.find(childName, "MiniMap") and
                   not string.find(childName, "WoW95") then
                    
                    -- Check if already collected
                    local alreadyCollected = false
                    for _, collectedButton in ipairs(self.collectedButtons) do
                        if collectedButton == child then
                            alreadyCollected = true
                            break
                        end
                    end
                    
                    if not alreadyCollected then
                        table.insert(self.collectedButtons, child)
                        child:Hide() -- Hide from minimap area
                        WoW95:Debug("Late-collected addon button: " .. childName)
                    end
                end
            end
        end
    end
end

-- Removed minimize functionality - minimap stays always visible

function Minimap:ToggleLock()
    self.locked = not self.locked
    
    if self.frame.lockText then
        self.frame.lockText:SetText(self.locked and "🔒" or "🔓")
    end
    
    WoW95:Debug("Minimap " .. (self.locked and "locked" or "unlocked"))
end

function Minimap:HideBlizzardMinimap()
    -- ONLY hide specific elements, NOT the entire MinimapCluster or Minimap
    local elementsToHide = {
        "MinimapBorder", 
        "MinimapBorderTop", 
        "MinimapCompass", 
        "MinimapNorthTag",
        "MinimapZoomIn",  
        "MinimapZoomOut",
        "ExpansionLandingPageMinimapButton", -- This is the old major factions button
        "GarrisonLandingPageMinimapButton",
        "QueueStatusMinimapButton",
        "MinimapZoneTextButton", -- Zone text button
        "MiniMapWorldMapButton" -- World map button
    }
    
    for _, elementName in ipairs(elementsToHide) do
        local element = _G[elementName]
        if element then
            element:Hide()
            element:SetAlpha(0)
            WoW95:Debug("Hidden element: " .. elementName)
        end
    end
    
    -- Make sure the actual Minimap frame stays visible and functional
    local minimap = _G["Minimap"]
    if minimap then
        minimap:Show()
        minimap:SetAlpha(1)
        WoW95:Debug("Ensured Minimap visibility")
    end
    
    -- Make sure MinimapCluster is visible (we need it for the minimap to work)
    local minimapCluster = _G["MinimapCluster"]
    if minimapCluster then
        minimapCluster:Show()
        minimapCluster:SetAlpha(1)
        WoW95:Debug("Ensured MinimapCluster visibility")
    end
    
    WoW95:Debug("Blizzard minimap border elements hidden, map kept visible")
end

function Minimap:Show()
    if self.frame then
        self.frame:Show()
    end
end

function Minimap:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Register the module
WoW95:RegisterModule("Minimap", Minimap)