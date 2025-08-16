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
    
    -- Delayed cleanup to catch any late-loading circular borders
    C_Timer.After(0.5, function()
        self:RemoveCircularBorders()
    end)
    
    -- Another cleanup after 2 seconds for really stubborn borders
    C_Timer.After(2, function()
        self:RemoveCircularBorders()
    end)
    
    -- Hook into minimap events to prevent circular borders from reappearing
    if _G["Minimap"] then
        local minimap = _G["Minimap"]
        
        -- Hook SetMaskTexture to prevent circular masks
        if minimap.SetMaskTexture then
            local originalSetMaskTexture = minimap.SetMaskTexture
            minimap.SetMaskTexture = function(self, texture)
                -- Only allow square masks or no mask
                if not texture or texture == "Interface\\ChatFrame\\ChatFrameBackground" or texture == "Interface\\Buttons\\WHITE8X8" then
                    originalSetMaskTexture(self, texture)
                else
                    WoW95:Debug("Blocked circular mask texture: " .. tostring(texture))
                    -- Force proper square mask instead (research-based)
                    originalSetMaskTexture(self, "Interface\\ChatFrame\\ChatFrameBackground")
                end
            end
        end
        
        -- Hook any texture-setting functions that might restore circular outline
        if minimap.SetTexture then
            local originalSetTexture = minimap.SetTexture
            minimap.SetTexture = function(self, texture)
                if texture and tostring(texture):lower():find("circle") then
                    WoW95:Debug("Blocked circular texture on minimap: " .. tostring(texture))
                    return -- Don't set circular textures
                end
                originalSetTexture(self, texture)
            end
        end
        
        -- Register for events that might restore circular borders
        local borderGuard = CreateFrame("Frame")
        borderGuard:RegisterEvent("ADDON_LOADED")
        borderGuard:RegisterEvent("VARIABLES_LOADED")
        borderGuard:RegisterEvent("PLAYER_ENTERING_WORLD")
        borderGuard:SetScript("OnEvent", function(self, event, ...)
            C_Timer.After(0.1, function()
                WoW95.Minimap:RemoveCircularBorders()
            end)
        end)
    end
    
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
    
    -- Create lock button using custom texture
    local lockButton = WoW95:CreateTitleBarButton("WoW95MinimapLockButton", self.titleBar, WoW95.textures.lock, 16)
    lockButton:SetPoint("RIGHT", self.titleBar, "RIGHT", -2, 0)
    
    lockButton:SetScript("OnClick", function()
        self:ToggleLock()
    end)
    
    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(lockButton, "ANCHOR_TOP")
        GameTooltip:SetText(self.locked and "Unlock Minimap" or "Lock Minimap")
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Store references
    self.frame.titleText = titleText
    self.frame.lockButton = lockButton
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
    
    -- Hide ALL textures that could be circular borders
    if blizzMinimap then
        -- First, try to set the border texture to nothing
        if blizzMinimap.SetBorderTexture then
            blizzMinimap:SetBorderTexture(nil)
        end
        
        -- Hide all regions that are textures
        local regions = {blizzMinimap:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region:GetObjectType() == "Texture" then
                -- Hide ALL textures except the actual map texture
                local texture = region:GetTexture()
                if texture then
                    local textureName = tostring(texture):lower()
                    -- Hide anything that looks like a border, ring, or overlay
                    if string.find(textureName, "border") or 
                       string.find(textureName, "circle") or 
                       string.find(textureName, "outline") or
                       string.find(textureName, "ring") or
                       string.find(textureName, "edge") or
                       string.find(textureName, "overlay") or
                       string.find(textureName, "mask") then
                        region:Hide()
                        region:SetAlpha(0)
                        region:SetTexture(nil) -- Clear the texture entirely
                        WoW95:Debug("Cleared texture: " .. textureName)
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
    
    -- DIRECT MINIMAP MASK OVERRIDE: Target the actual minimap masking system
    WoW95:Debug("DIRECT OVERRIDE: Targeting minimap mask system...")
    
    local minimap = _G["Minimap"]
    if minimap then
        -- Try to find and override any mask-related properties
        if minimap.SetMaskTexture then
            -- Force set our square mask immediately and repeatedly
            minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
            WoW95:Debug("DIRECT: Applied square mask")
            
            -- Hook to prevent any circular mask from being applied
            local originalSetMask = minimap.SetMaskTexture
            minimap.SetMaskTexture = function(self, texture)
                -- Force square mask no matter what gets requested
                originalSetMask(self, "Interface\\ChatFrame\\ChatFrameBackground")
                WoW95:Debug("DIRECT: Forced square mask override")
            end
        end
        
        -- Try to disable any circular border rendering at the engine level
        if minimap.SetBorderTexture then
            minimap:SetBorderTexture(nil)
            minimap.SetBorderTexture = function() end -- Disable function
            WoW95:Debug("DIRECT: Disabled border texture")
        end
        
        -- Look for circular border textures specifically in ObjectIcons
        local potentialBorderTextures = {
            "Interface\\Minimap\\ObjectIconsAtlas",
            "Interface\\Minimap\\ObjectIcons", 
            "Interface\\Minimap\\UI-Minimap-Border",
            "Interface\\Minimap\\MiniMap-Border",
            "Interface\\Minimap\\Border"
        }
        
        for _, texturePath in ipairs(potentialBorderTextures) do
            -- Check if any region is using these textures
            for i = 1, minimap:GetNumRegions() do
                local region = select(i, minimap:GetRegions())
                if region and region:GetObjectType() == "Texture" then
                    local currentTexture = region:GetTexture()
                    if currentTexture and string.find(tostring(currentTexture):lower(), texturePath:lower()) then
                        region:SetTexture(nil)
                        WoW95:Debug("DIRECT: Cleared border texture: " .. texturePath)
                    end
                end
            end
        end
        
        -- DEBUG: Log all textures currently on the minimap to identify the circular border
        WoW95:Debug("=== MINIMAP TEXTURE AUDIT ===")
        for i = 1, minimap:GetNumRegions() do
            local region = select(i, minimap:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                local drawLayer = region:GetDrawLayer()
                local isShown = region:IsShown()
                local alpha = region:GetAlpha()
                WoW95:Debug("Texture " .. i .. ": " .. tostring(texture) .. " | Layer: " .. tostring(drawLayer) .. " | Shown: " .. tostring(isShown) .. " | Alpha: " .. tostring(alpha))
            end
        end
        WoW95:Debug("=== END TEXTURE AUDIT ===")
    end
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
    
    -- Zoom in button with maximize icon
    local zoomInButton = WoW95:CreateTitleBarButton("WoW95MinimapZoomIn", self.frame, WoW95.textures.maximize, 18)
    zoomInButton:SetPoint("BOTTOMRIGHT", self.minimapFrame, "BOTTOMRIGHT", 0, -20)
    
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
    
    -- Zoom out button with minimize icon  
    local zoomOutButton = WoW95:CreateTitleBarButton("WoW95MinimapZoomOut", self.frame, WoW95.textures.minimize, 18)
    zoomOutButton:SetPoint("RIGHT", zoomInButton, "LEFT", -2, 0)
    
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
            local buttonName = button:GetName() or "UnnamedButton"
            
            -- Double-check: exclude our zoom buttons and system buttons
            local isOurButton = string.find(buttonName, "WoW95") or button:GetParent() == self.frame
            local isSystemButton = string.find(buttonName, "Zoom") or
                                 string.find(buttonName, "MiniMap") or
                                 string.find(buttonName, "Minimap") 
            
            if not isOurButton and not isSystemButton then
                -- Move the actual button to the popup and position it
                button:SetParent(popup)
                button:ClearAllPoints()
                button:SetPoint("LEFT", popup, "LEFT", xOffset, 0)
                button:SetSize(buttonSize, buttonSize)
                
                -- AGGRESSIVE visibility enforcement
                button:Show()
                button:SetAlpha(1)
                button:SetFrameLevel(popup:GetFrameLevel() + 10) -- Higher level
                button:SetFrameStrata("FULLSCREEN_DIALOG") -- Even higher strata
                
                -- Force enable mouse to ensure it's interactive
                button:EnableMouse(true)
                
                -- Make sure any textures on the button are visible
                if button.icon then
                    button.icon:Show()
                    button.icon:SetAlpha(1)
                    button.icon:SetDrawLayer("ARTWORK", 1)
                end
                
                -- Check for common texture children and FORCE them visible
                local regions = {button:GetRegions()}
                for _, region in ipairs(regions) do
                    if region and region:GetObjectType() == "Texture" then
                        region:Show()
                        region:SetAlpha(1)
                        region:SetDrawLayer("ARTWORK", 1)
                        -- Force a texture if none exists
                        if not region:GetTexture() then
                            region:SetColorTexture(0.5, 0.5, 0.5, 1) -- Gray fallback
                            WoW95:Debug("Applied fallback texture to button region")
                        end
                    end
                end
                
                -- EXTREME BUTTON VISIBILITY: Recreate the button completely if needed
                if not button.debugBackdrop then
                    button.debugBackdrop = button:CreateTexture(nil, "BACKGROUND")
                    button.debugBackdrop:SetAllPoints(button)
                    button.debugBackdrop:SetColorTexture(0.3, 0.3, 0.3, 0.8) -- Dark gray background
                    WoW95:Debug("Added debug backdrop to button: " .. buttonName)
                end
                
                -- DISABLED: Proxy button creation was breaking LibDBIcon
                -- Instead, just force maximum visibility on original button
                WoW95:Debug("Button visibility status: " .. buttonName .. " Alpha=" .. button:GetAlpha() .. " Visible=" .. tostring(button:IsVisible()))
                
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
                
                WoW95:Debug("Added button to popup: " .. buttonName .. " (Alpha: " .. button:GetAlpha() .. ", FrameLevel: " .. button:GetFrameLevel() .. ")")
            else
                WoW95:Debug("Excluded button from popup: " .. buttonName .. " (our button: " .. tostring(isOurButton) .. ", system: " .. tostring(isSystemButton) .. ")")
            end
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
        "GameTimeFrame",
        "ExpansionLandingPageMinimapButton", -- Major faction button
        "GarrisonLandingPageMinimapButton",
        "QueueStatusMinimapButton"
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
            elseif buttonName == "ExpansionLandingPageMinimapButton" then
                button:SetPoint("LEFT", self.minimapFrame, "LEFT", -25, 0)
            elseif buttonName == "GarrisonLandingPageMinimapButton" then
                button:SetPoint("RIGHT", self.minimapFrame, "RIGHT", 25, 0)
            elseif buttonName == "QueueStatusMinimapButton" then
                button:SetPoint("TOPLEFT", self.minimapFrame, "TOPLEFT", -25, -25)
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
    
    WoW95:Debug("Starting comprehensive minimap button collection...")
    
    -- Get all children of the original Minimap frame
    local blizzMinimap = _G["Minimap"]
    if blizzMinimap then
        local children = {blizzMinimap:GetChildren()}
        WoW95:Debug("Found " .. #children .. " children on Minimap")
        
        for _, child in ipairs(children) do
            if child and child:GetObjectType() == "Button" then
                local childName = child:GetName() or "UnnamedButton"
                WoW95:Debug("Checking button: " .. childName)
                
                -- More selective collection - exclude system buttons and our own buttons
                local isSystemButton = string.find(childName, "MiniMapZoomIn") or
                                     string.find(childName, "MiniMapZoomOut") or  
                                     string.find(childName, "WoW95") or  -- This excludes ALL our buttons
                                     string.find(childName, "MiniMapTracking") or
                                     string.find(childName, "MinimapZone") or
                                     string.find(childName, "MinimapZoom") or
                                     string.find(childName, "Zoom") or
                                     string.find(childName, "ExpansionLandingPage") or -- Keep major faction button working
                                     string.find(childName, "GarrisonLanding") or
                                     string.find(childName, "QueueStatus") or
                                     child:GetParent() == self.frame  -- Exclude buttons parented to our frame
                
                if not isSystemButton then
                    -- Collect this button
                    table.insert(self.collectedButtons, child)
                    
                    -- Hide the button from the minimap area initially
                    child:Hide()
                    child:SetParent(UIParent) -- Move away from minimap
                    
                    WoW95:Debug("Collected button: " .. childName)
                end
            end
        end
    end
    
    -- Also check MinimapCluster for buttons
    local cluster = _G["MinimapCluster"]
    if cluster then
        local clusterChildren = {cluster:GetChildren()}
        WoW95:Debug("Found " .. #clusterChildren .. " children on MinimapCluster")
        
        for _, child in ipairs(clusterChildren) do
            if child and child:GetObjectType() == "Button" and child ~= blizzMinimap then
                local childName = child:GetName() or "UnnamedClusterButton"
                
                -- Skip our own buttons and important system buttons
                local isOurButton = string.find(childName, "WoW95") or child:GetParent() == self.frame
                local isZoomButton = string.find(childName, "MiniMapZoom") or
                                   string.find(childName, "MinimapZoom") or
                                   string.find(childName, "Zoom")
                local isImportantSystemButton = string.find(childName, "ExpansionLandingPage") or
                                              string.find(childName, "GarrisonLanding") or
                                              string.find(childName, "QueueStatus")
                
                if isZoomButton then
                    -- Hide vanilla zoom buttons completely
                    child:Hide()
                    child:SetAlpha(0)
                    child:SetParent(nil)
                    WoW95:Debug("Hidden vanilla zoom button: " .. childName)
                elseif isImportantSystemButton then
                    -- Keep important system buttons functional but don't collect them
                    WoW95:Debug("Preserved important system button: " .. childName)
                elseif not isOurButton then
                    -- Check if we already collected this button
                    local alreadyCollected = false
                    for _, collected in ipairs(self.collectedButtons) do
                        if collected == child then
                            alreadyCollected = true
                            break
                        end
                    end
                    
                    if not alreadyCollected then
                        table.insert(self.collectedButtons, child)
                        child:Hide()
                        child:SetParent(UIParent)
                        WoW95:Debug("Collected cluster button: " .. childName)
                    end
                end
            end
        end
    end
    
    -- Scan for LibDataBroker buttons immediately
    self:ScanForLibDBIconButtons()
    
    -- Scan for common addon button patterns
    self:ScanForCommonAddonButtons()
    
    -- Delay check for LibDataBroker icons that might load later
    C_Timer.After(2, function()
        self:RepositionLateLoadingAddons()
    end)
    
    -- Also check after a longer delay for late-loading addons
    C_Timer.After(10, function()
        self:RepositionLateLoadingAddons()
    end)
    
    -- Another scan after 15 seconds for really late-loading addons
    C_Timer.After(15, function()
        self:RepositionLateLoadingAddons()
    end)
    
    -- Clean up collected buttons to remove any that shouldn't be there
    local cleanedButtons = {}
    for _, button in ipairs(self.collectedButtons) do
        if button and button:GetName() then
            local buttonName = button:GetName()
            local isOurButton = string.find(buttonName, "WoW95") or button:GetParent() == self.frame
            local isSystemButton = string.find(buttonName, "Zoom") or
                                 string.find(buttonName, "MiniMap") or
                                 string.find(buttonName, "Minimap")
            
            if not isOurButton and not isSystemButton then
                table.insert(cleanedButtons, button)
            else
                WoW95:Debug("Removing inappropriate button from collection: " .. buttonName)
                -- Restore the button to its original state if it was our zoom button
                if isOurButton then
                    button:SetParent(self.frame) -- Put our buttons back where they belong
                    button:Show()
                end
            end
        else
            -- Keep buttons without names for now
            table.insert(cleanedButtons, button)
        end
    end
    self.collectedButtons = cleanedButtons
    
    WoW95:Debug("Button collection cleaned. Found " .. #self.collectedButtons .. " valid addon buttons")
end

function Minimap:ScanForLibDBIconButtons()
    -- Check for LibDataBroker icon registry
    if LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true) then
        local LibDBIcon = LibStub("LibDBIcon-1.0")
        if LibDBIcon and LibDBIcon.objects then
            WoW95:Debug("Found LibDBIcon registry with " .. (#LibDBIcon.objects or 0) .. " objects")
            for name, obj in pairs(LibDBIcon.objects) do
                if obj.button then
                    -- Check if already collected
                    local alreadyCollected = false
                    for _, collected in ipairs(self.collectedButtons) do
                        if collected == obj.button then
                            alreadyCollected = true
                            break
                        end
                    end
                    
                    if not alreadyCollected then
                        table.insert(self.collectedButtons, obj.button)
                        obj.button:Hide()
                        obj.button:SetParent(UIParent)
                        WoW95:Debug("Collected LibDBIcon button: " .. name)
                    end
                end
            end
        end
    end
end

function Minimap:ScanForCommonAddonButtons()
    -- Scan for common addon button naming patterns
    local commonPatterns = {
        "MinimapButton",
        "MinimapIcon", 
        "MiniMapButton",
        "MiniMapIcon",
        "MMButton",
        "MMIcon"
    }
    
    for _, pattern in ipairs(commonPatterns) do
        for i = 1, 50 do -- Check numbered variations
            local buttonName = pattern .. i
            local button = _G[buttonName]
            if button and button:GetObjectType() == "Button" then
                -- Check if already collected
                local alreadyCollected = false
                for _, collected in ipairs(self.collectedButtons) do
                    if collected == button then
                        alreadyCollected = true
                        break
                    end
                end
                
                if not alreadyCollected then
                    table.insert(self.collectedButtons, button)
                    button:Hide()
                    button:SetParent(UIParent)
                    WoW95:Debug("Collected pattern button: " .. buttonName)
                end
            end
        end
        
        -- Also check the base pattern without number
        local button = _G[pattern]
        if button and button:GetObjectType() == "Button" then
            local alreadyCollected = false
            for _, collected in ipairs(self.collectedButtons) do
                if collected == button then
                    alreadyCollected = true
                    break
                end
            end
            
            if not alreadyCollected then
                table.insert(self.collectedButtons, button)
                button:Hide()
                button:SetParent(UIParent)
                WoW95:Debug("Collected pattern button: " .. pattern)
            end
        end
    end
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

function Minimap:RemoveCircularBorders()
    local minimap = _G["Minimap"]
    if not minimap then return end
    
    WoW95:Debug("Starting aggressive circular border removal...")
    
    -- Hide specific known border elements using research-based approach
    local elementsToRemove = {
        'MinimapBorder',
        'MinimapBorderTop',
        'MinimapNorthTag',
        'MinimapZoomIn',
        'MinimapZoomOut',
        'MiniMapZoomIn',      -- Alternative naming
        'MiniMapZoomOut',     -- Alternative naming  
        'MinimapCompass',
        'MiniMapMailBorder',
        'QueueStatusMinimapButtonBorder',
        'QueueStatusMinimapButtonGroupSize',
    }
    
    -- Use the proper hiding technique from research
    for _, name in ipairs(elementsToRemove) do
        local object = _G[name]
        if object then
            if object:GetObjectType() == 'Texture' then
                object:SetTexture(nil)
                WoW95:Debug("Cleared texture: " .. name)
            else
                object.Show = object.Hide  -- Permanently disable Show function
                object:Hide()
                WoW95:Debug("Hidden and disabled element: " .. name)
            end
        end
    end
    
    -- EXTREME MEASURE: Search for and destroy any potential circular overlay frames
    local potentialOverlayNames = {
        'MinimapOverlay',
        'MinimapBorderFrame', 
        'MinimapCircleFrame',
        'MinimapOutlineFrame',
        'MinimapRingFrame',
        'MinimapEdgeFrame'
    }
    
    for _, name in ipairs(potentialOverlayNames) do
        local frame = _G[name]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            frame.Show = frame.Hide
            WoW95:Debug("EXTREME: Killed potential overlay frame: " .. name)
        end
    end
    
    -- Also scan all children of MinimapCluster for any circular frames
    local cluster = _G["MinimapCluster"]
    if cluster then
        for i = 1, cluster:GetNumChildren() do
            local child = select(i, cluster:GetChildren())
            if child and child:GetName() then
                local childName = child:GetName():lower()
                if string.find(childName, "border") or string.find(childName, "circle") or 
                   string.find(childName, "outline") or string.find(childName, "ring") or
                   string.find(childName, "edge") then
                    child:Hide()
                    child:SetAlpha(0)
                    child.Show = child.Hide
                    WoW95:Debug("EXTREME: Killed MinimapCluster child: " .. child:GetName())
                end
            end
        end
    end
    
    -- Force square mask on minimap using the proper technique from research
    if minimap.SetMaskTexture then
        -- Use ChatFrameBackground which is known to work for square minimaps
        minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
        WoW95:Debug("Applied proper square mask texture")
    end
    
    -- Remove circular quest/dig area rings (key finding from research)
    if minimap.SetArchBlobRingScalar then
        minimap:SetArchBlobRingScalar(0)
        WoW95:Debug("Disabled archaeology blob ring")
    end
    
    if minimap.SetQuestBlobRingScalar then
        minimap:SetQuestBlobRingScalar(0) 
        WoW95:Debug("Disabled quest blob ring")
    end
    
    -- ULTIMATE NUCLEAR: Complete minimap frame replacement
    WoW95:Debug("ULTIMATE NUCLEAR: Attempting complete minimap override")
    
    -- Step 1: Try to completely hide the existing minimap and create our own
    local originalMinimap = _G["Minimap"]
    if originalMinimap then
        -- Make the original completely invisible but keep it functional
        originalMinimap:SetAlpha(0)
        originalMinimap:Hide()
        
        -- Create our own square minimap texture that covers the circular one
        local squareOverlay = CreateFrame("Frame", "WoW95SquareMinimapOverlay", self.minimapFrame)
        squareOverlay:SetAllPoints(self.minimapFrame)
        squareOverlay:SetFrameLevel(originalMinimap:GetFrameLevel() + 100) -- Way above everything
        
        -- Create a texture that shows the map data but in square form
        local squareTexture = squareOverlay:CreateTexture(nil, "ARTWORK")
        squareTexture:SetAllPoints(squareOverlay)
        
        -- Try to copy the minimap's texture
        if originalMinimap.GetTexture then
            local mapTexture = originalMinimap:GetTexture()
            if mapTexture then
                squareTexture:SetTexture(mapTexture)
                WoW95:Debug("ULTIMATE: Copied minimap texture to square overlay")
            end
        end
        
        -- If that doesn't work, try a different approach - make the original visible but force square
        if not squareTexture:GetTexture() then
            originalMinimap:SetAlpha(1)
            originalMinimap:Show()
            originalMinimap:SetParent(self.minimapFrame)
            originalMinimap:SetAllPoints(self.minimapFrame)
            WoW95:Debug("ULTIMATE: Repositioned original minimap in square container")
            
            -- Force override any border drawing functions
            if originalMinimap.SetBorderTexture then
                originalMinimap.SetBorderTexture = function() end -- Disable border texture setting
                WoW95:Debug("ULTIMATE: Disabled SetBorderTexture function")
            end
            
            if originalMinimap.DrawBorder then
                originalMinimap.DrawBorder = function() end -- Disable border drawing
                WoW95:Debug("ULTIMATE: Disabled DrawBorder function")
            end
            
            -- Override any update functions that might redraw borders
            if originalMinimap.UpdateBorder then
                originalMinimap.UpdateBorder = function() end
                WoW95:Debug("ULTIMATE: Disabled UpdateBorder function")
            end
        end
    end
    
    -- NUCLEAR APPROACH: Remove ALL textures from minimap and rebuild only what we need
    WoW95:Debug("NUCLEAR: Removing ALL minimap textures and rebuilding")
    
    -- Get all regions and systematically remove every texture
    for i = 1, minimap:GetNumRegions() do
        local region = select(i, minimap:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture then
                local texStr = tostring(texture):lower()
                -- Check for specific circular border texture paths that WoW uses
                local isCircularBorder = string.find(texStr, "interface/minimap") or
                                       string.find(texStr, "border") or
                                       string.find(texStr, "circle") or
                                       string.find(texStr, "outline") or
                                       string.find(texStr, "ring") or
                                       string.find(texStr, "ui-minimap") or
                                       string.find(texStr, "minimap-border")
                
                -- Only preserve actual map content, destroy everything else
                if isCircularBorder or not (string.find(texStr, "world") and string.find(texStr, "map")) then
                    -- This is probably a border/outline texture - DESTROY IT
                    region:SetTexture(nil)
                    region:Hide()
                    region:SetAlpha(0)
                    region:SetDrawLayer("BACKGROUND", -10) -- Push it way back
                    -- EXTREME: Try to completely detach it
                    if region.SetParent then
                        region:SetParent(nil)
                    end
                    WoW95:Debug("NUCLEAR: Destroyed texture: " .. texStr)
                else
                    WoW95:Debug("NUCLEAR: Preserved map texture: " .. texStr)
                end
            else
                -- No texture info = suspicious, kill it
                region:SetTexture(nil)
                region:Hide()
                region:SetAlpha(0)
                WoW95:Debug("NUCLEAR: Killed unknown texture region")
            end
        end
    end
    
    -- Override any future texture setting attempts
    local originalSetTexture = minimap.SetTexture
    if originalSetTexture then
        minimap.SetTexture = function(self, texture)
            if texture and tostring(texture):lower():find("border") then
                WoW95:Debug("NUCLEAR: Blocked border texture: " .. tostring(texture))
                return -- Block it completely
            end
            return originalSetTexture(self, texture)
        end
    end
    
    -- RESEARCH-BASED FIX: Remove MinimapCluster backdrop (key finding)
    local cluster = _G["MinimapCluster"]
    if cluster then
        if cluster.SetBackdrop then
            cluster:SetBackdrop(nil)
            WoW95:Debug("NUCLEAR: Removed MinimapCluster backdrop")
        end
        
        -- Hook any future backdrop setting attempts
        if cluster.SetBackdrop then
            local originalSetBackdrop = cluster.SetBackdrop
            cluster.SetBackdrop = function(self, backdrop)
                WoW95:Debug("NUCLEAR: Blocked MinimapCluster backdrop attempt")
                return -- Block all backdrop attempts
            end
        end
    end
    
    -- Also target the Minimap frame itself for backdrop removal
    if minimap.SetBackdrop then
        minimap:SetBackdrop(nil)
        WoW95:Debug("NUCLEAR: Removed Minimap backdrop")
        
        -- Hook future backdrop attempts on minimap
        local originalMinimapSetBackdrop = minimap.SetBackdrop
        minimap.SetBackdrop = function(self, backdrop)
            WoW95:Debug("NUCLEAR: Blocked Minimap backdrop attempt")
            return -- Block all backdrop attempts
        end
    end
    
    -- Directly target the minimap's SetClampRectInsets to force square shape
    if minimap.SetClampRectInsets then
        minimap:SetClampRectInsets(0, 0, 0, 0)
    end
    
    -- Nuclear option: Override all drawing-related functions that might show circular outline
    -- Hook the minimap's OnUpdate to continuously enforce square appearance
    local function enforceSquareMap()
        if minimap and minimap.SetMaskTexture then
            minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
        end
        
        -- Hide any new circular elements that might have appeared
        for i = 1, minimap:GetNumRegions() do
            local region = select(i, minimap:GetRegions())
            if region and region:GetObjectType() == "Texture" and region:IsShown() then
                local texture = region:GetTexture()
                if texture then
                    local texStr = tostring(texture):lower()
                    if string.find(texStr, "circle") or string.find(texStr, "outline") or 
                       string.find(texStr, "border") or string.find(texStr, "ring") then
                        region:Hide()
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end
    
    -- Set up AGGRESSIVE continuous enforcement
    local enforcementFrame = CreateFrame("Frame")
    enforcementFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer >= 0.05 then -- Check every 0.05 seconds (more frequent)
            enforceSquareMap()
            
            -- Extra aggressive: continuously kill any new border textures
            for i = 1, minimap:GetNumRegions() do
                local region = select(i, minimap:GetRegions())
                if region and region:GetObjectType() == "Texture" and region:IsShown() then
                    local texture = region:GetTexture()
                    if texture then
                        local texStr = tostring(texture):lower()
                        if string.find(texStr, "border") or string.find(texStr, "circle") or 
                           string.find(texStr, "outline") or string.find(texStr, "ring") then
                            region:SetTexture(nil)
                            region:Hide()
                            WoW95:Debug("ENFORCEMENT: Killed reappearing border: " .. texStr)
                        end
                    end
                end
            end
            
            -- Continuously remove backdrops that might reappear
            local cluster = _G["MinimapCluster"]
            if cluster and cluster.SetBackdrop then
                cluster:SetBackdrop(nil)
            end
            if minimap and minimap.SetBackdrop then
                minimap:SetBackdrop(nil)
            end
            
            self.timer = 0
        end
    end)
    
    -- Check all textures on the minimap
    for i = 1, minimap:GetNumRegions() do
        local region = select(i, minimap:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            if region.GetTexture then
                local texture = region:GetTexture()
                if texture then
                    local texStr = tostring(texture):lower()
                    -- More comprehensive texture pattern matching
                    if string.find(texStr, "minimap") and (
                       string.find(texStr, "border") or
                       string.find(texStr, "ring") or
                       string.find(texStr, "circle") or
                       string.find(texStr, "outline") or
                       string.find(texStr, "edge") or
                       string.find(texStr, "mask")) then
                        region:SetTexture(nil)
                        region:Hide()
                        region:SetAlpha(0)
                        WoW95:Debug("Removed circular border texture: " .. texStr)
                    end
                end
            end
            
            -- Also check for specific texture coordinates that indicate circular masks
            if region.GetTexCoord then
                local left, right, top, bottom = region:GetTexCoord()
                -- Circular masks often use specific texture coordinates
                if left and right and top and bottom then
                    if (left == 0 and right == 1 and top == 0 and bottom == 1) or
                       (math.abs(left - 0.125) < 0.01 and math.abs(right - 0.875) < 0.01) then
                        -- This might be a circular mask, reset to square coordinates
                        region:SetTexCoord(0, 1, 0, 1)
                        WoW95:Debug("Reset suspicious texture coordinates")
                    end
                end
            end
        end
    end
    
    -- Check MinimapCluster and all its children recursively
    local function hideCircularElements(frame, depth)
        if not frame or depth > 5 then return end
        
        if frame:GetName() then
            local name = frame:GetName():lower()
            if string.find(name, "border") or 
               string.find(name, "ring") or 
               string.find(name, "circle") or
               string.find(name, "outline") or
               string.find(name, "zoom") then  -- Also hide zoom-related circular elements
                frame:Hide()
                frame:SetAlpha(0)
                WoW95:Debug("Hidden frame: " .. frame:GetName())
            end
        end
        
        -- Check children
        for i = 1, frame:GetNumChildren() do
            local child = select(i, frame:GetChildren())
            if child then
                hideCircularElements(child, depth + 1)
            end
        end
        
        -- Check regions
        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if region and region:GetObjectType() == "Texture" and region.GetTexture then
                local texture = region:GetTexture()
                if texture then
                    local texStr = tostring(texture):lower()
                    if string.find(texStr, "border") or 
                       string.find(texStr, "ring") or 
                       string.find(texStr, "circle") or
                       string.find(texStr, "zoom") then  -- Also target zoom button backgrounds
                        region:SetTexture(nil)
                        region:Hide()
                        region:SetAlpha(0)
                        WoW95:Debug("Cleared texture from region: " .. texStr)
                    end
                end
            end
        end
    end
    
    local cluster = _G["MinimapCluster"]
    if cluster then
        hideCircularElements(cluster, 0)
    end
    
    WoW95:Debug("Circular border removal complete")
end

function Minimap:HideBlizzardMinimap()
    -- ONLY hide specific border elements, preserve functional buttons
    local elementsToHide = {
        'MinimapBorder', 
        'MinimapBorderTop', 
        'MinimapCompass', 
        'MinimapNorthTag',
        'MinimapZoomIn',  
        'MinimapZoomOut',
        'MiniMapZoomIn',   -- Alternative naming
        'MiniMapZoomOut',  -- Alternative naming
        'Minimap-ZoomInButton',  -- Modern naming
        'Minimap-ZoomOutButton', -- Modern naming
        'MinimapZoneTextButton', -- Zone text button
        'MiniMapWorldMapButton', -- World map button
        'MiniMapMailBorder',
        'QueueStatusMinimapButtonBorder',
        'QueueStatusMinimapButtonGroupSize',
        -- DO NOT hide ExpansionLandingPageMinimapButton - that's our major faction button!
        -- DO NOT hide GarrisonLandingPageMinimapButton 
        -- DO NOT hide QueueStatusMinimapButton
    }
    
    -- Use proper hiding technique from research
    for _, name in ipairs(elementsToHide) do
        local object = _G[name]
        if object then
            if object:GetObjectType() == 'Texture' then
                object:SetTexture(nil)
                WoW95:Debug("Cleared texture: " .. name)
            else
                object.Show = object.Hide  -- Permanently disable Show function
                object:Hide()
                WoW95:Debug("Hidden and disabled element: " .. name)
            end
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