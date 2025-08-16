-- WoW95 Map Window Module
-- EXACTLY extracted from original Windows.lua - ALL original code preserved

local addonName, WoW95 = ...

local MapWindow = {}
WoW95.MapWindow = MapWindow

-- World Map Creation Functions (from original Windows.lua)
function MapWindow:CreateWindow(frameName, program)
    WoW95:Debug("=== MapWindow:CreateWindow called ===")
    WoW95:Debug("Frame Name: " .. tostring(frameName))
    WoW95:Debug("Program: " .. tostring(program and program.name or "nil"))
    
    -- Check if window already exists and just show it
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug("Map window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    -- Simple approach: just show the Blizzard map and register it
    if not WorldMapFrame then
        WoW95:Print("ERROR: WorldMapFrame not available")
        return nil
    end
    
    -- Simple map opening
    if not WorldMapFrame:IsShown() then
        WoW95:Debug("Opening map...")
        ToggleWorldMap()
    end
    
    -- ALWAYS style it when opened, even if it was styled before
    C_Timer.After(0.1, function()
        if WorldMapFrame and WorldMapFrame:IsShown() then
            self:StyleAndRegisterMap(frameName, program)
        else
            WoW95:Print("Failed to open map")
        end
    end)
    
    return WorldMapFrame
end

function MapWindow:StyleAndRegisterMap(frameName, program)
    WoW95:Debug("Styling and registering map")
    
    -- Apply compact Windows 95 styling
    WoW95:Debug("Applying compact map style...")
    local success, err = pcall(function()
        self:ApplyCompactMapStyle()
    end)
    if not success then
        WoW95:Debug("ERROR in ApplyCompactMapStyle: " .. tostring(err))
        WoW95:Print("Map styling error in ApplyCompactMapStyle: " .. tostring(err))
        return
    end
    
    -- Set tighter size - reduce height to prevent map jumping
    WoW95:Debug("Setting map size and position...")
    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    WorldMapFrame:SetSize(900, 500)  -- Reduced height from 600 to 500 for tighter UI
    
    -- Ensure map is visible and interactive
    WoW95:Debug("Making map visible...")
    WorldMapFrame:SetAlpha(1)
    WorldMapFrame:EnableMouse(true)
    WorldMapFrame:Show()
    
    -- Store reference for taskbar
    WoW95:Debug("Storing map reference...")
    WoW95.WindowsCore:StoreProgramWindow(frameName, WorldMapFrame)
    WorldMapFrame.programName = program.name
    WorldMapFrame.frameName = frameName
    WorldMapFrame.isWoW95Window = true
    WorldMapFrame.isProgramWindow = true
    
    -- Notify taskbar
    WoW95:Debug("Notifying taskbar...")
    WoW95:OnWindowOpened(WorldMapFrame)
    
    WoW95:Debug("Map styled and registered successfully")
end

function MapWindow:ApplyCompactMapStyle()
    if not WorldMapFrame then return end
    
    WoW95:Debug("Applying compact map style focused on map display...")
    
    -- Clear any existing custom UI
    self:CleanupExistingMapUI()
    
    -- Hide unnecessary Blizzard UI elements but keep the map
    self:HideNonEssentialMapElements()
    
    -- Ensure the map canvas is visible and properly sized
    self:SetupMapCanvas()
    
    -- Add minimal Windows 95 styling
    self:AddMinimalMapStyling()
    
    WoW95:Debug("Compact map style applied")
end

function MapWindow:CleanupExistingMapUI()
    if WorldMapFrame.wow95MapUI then
        WorldMapFrame.wow95MapUI:Hide()
        WorldMapFrame.wow95MapUI = nil
    end
    if WorldMapFrame.wow95MapBG then
        WorldMapFrame.wow95MapBG:Hide()
        WorldMapFrame.wow95MapBG = nil
    end
end

function MapWindow:HideNonEssentialMapElements()
    -- Hide side panel, borders, but keep the actual map
    local elementsToHide = {
        "BorderFrame", "NavBar", "SidePanelToggle", 
        "TitleContainer", "BlackoutFrame"
    }
    
    for _, elementName in ipairs(elementsToHide) do
        if WorldMapFrame[elementName] then
            WorldMapFrame[elementName]:Hide()
        end
    end
end

function MapWindow:SetupMapCanvas()
    if not WorldMapFrame.ScrollContainer then
        WoW95:Debug("ScrollContainer not found - map may not display properly")
        return
    end
    
    local canvas = WorldMapFrame.ScrollContainer
    
    -- Position map canvas tightly - minimize vertical space
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 8, -55) -- 30px for zone buttons + 25px title bar
    canvas:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -250, 5) -- Reduced bottom margin from 8 to 5
    canvas:SetScale(1)
    canvas:Show()
    canvas:SetAlpha(1)
    canvas:EnableMouse(true)
    
    -- Lock the map position to prevent jumping when changing zones
    if canvas.SetPanTarget then
        canvas:SetPanTarget(0.5, 0.5) -- Center the map
    end
    
    WoW95:Debug("Map canvas positioned tightly to prevent jumping")
end

function MapWindow:AddMinimalMapStyling()
    -- Add title bar (create if doesn't exist, show if hidden)
    if not WorldMapFrame.wow95Title then
        local titleBar = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
        titleBar:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 0, 0)
        titleBar:SetHeight(25)
        titleBar:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
        
        titleBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1
        })
        titleBar:SetBackdropColor(unpack(WoW95.colors.titleBar))
        titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
        titleText:SetText("World Map - WoW95")
        titleText:SetTextColor(1, 1, 1, 1)
        titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        titleText:SetShadowOffset(1, -1)
        
        -- Add close button using custom texture
        local closeButton = WoW95:CreateTitleBarButton("MapCloseBtn", titleBar, WoW95.textures.close, 16)
        closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
        closeButton:SetScript("OnClick", function()
            WorldMapFrame:Hide()
        end)
        
        -- Make title bar draggable
        titleBar:EnableMouse(true)
        titleBar:RegisterForDrag("LeftButton")
        titleBar:SetScript("OnDragStart", function()
            WorldMapFrame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            WorldMapFrame:StopMovingOrSizing()
        end)
        
        -- Enable moving
        WorldMapFrame:SetMovable(true)
        WorldMapFrame:SetClampedToScreen(true)
        
        WorldMapFrame.wow95Title = titleBar
        titleBar.titleText = titleText
        titleBar.closeButton = closeButton
        
        -- Hook the OnHide to clean up properly
        if not WorldMapFrame.wow95HideHooked then
            WorldMapFrame:HookScript("OnHide", function()
                self:CleanupWorldMapReskin("WorldMapFrame")
            end)
            WorldMapFrame.wow95HideHooked = true
        end
        
        -- Hook map navigation to update breadcrumb
        if not WorldMapFrame.wow95NavigationHooked then
            -- Hook the OnMapChanged event to update breadcrumb when map changes
            if WorldMapFrame.OnMapChanged then
                hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
                    if WorldMapFrame.wow95ZoneBreadcrumb then
                        C_Timer.After(0.1, function()
                            self:UpdateZoneBreadcrumb(WorldMapFrame.wow95ZoneBreadcrumb)
                        end)
                    end
                end)
            end
            WorldMapFrame.wow95NavigationHooked = true
        end
    else
        -- Title bar exists but might be hidden, show it
        WorldMapFrame.wow95Title:Show()
        WorldMapFrame.wow95Title:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
    end
    
    -- Add zone breadcrumb navigation bar (create if doesn't exist, show and update if hidden)
    if not WorldMapFrame.wow95ZoneBreadcrumb then
        local breadcrumbBar = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
        breadcrumbBar:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 8, -30)
        breadcrumbBar:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -8, -30)
        breadcrumbBar:SetHeight(22)
        breadcrumbBar:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 50)
        
        breadcrumbBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        breadcrumbBar:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        breadcrumbBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        WorldMapFrame.wow95ZoneBreadcrumb = breadcrumbBar
    else
        -- Breadcrumb exists but might be hidden, show it
        WorldMapFrame.wow95ZoneBreadcrumb:Show()
        WorldMapFrame.wow95ZoneBreadcrumb:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 50)
    end
    
    -- Always update the zone breadcrumb when styling
    self:UpdateZoneBreadcrumb(WorldMapFrame.wow95ZoneBreadcrumb)
end

function MapWindow:UpdateZoneBreadcrumb(breadcrumbBar)
    if not breadcrumbBar then return end
    
    -- Clear existing buttons
    for i = 1, breadcrumbBar:GetNumChildren() do
        local child = select(i, breadcrumbBar:GetChildren())
        if child and child.isZoneButton then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Get current map info
    local mapID = WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    
    local breadcrumbs = {}
    local currentMapID = mapID
    
    -- Build hierarchy from current zone up to continent (like Russian dolls)
    while currentMapID do
        local mapInfo = C_Map.GetMapInfo(currentMapID)
        if mapInfo then
            table.insert(breadcrumbs, 1, {
                mapID = currentMapID,
                name = mapInfo.name,
                mapType = mapInfo.mapType
            })
        end
        currentMapID = mapInfo and mapInfo.parentMapID
    end
    
    -- Create clickable buttons for each level of the hierarchy
    local xOffset = 5
    for i, crumb in ipairs(breadcrumbs) do
        local button = WoW95:CreateButton("ZoneCrumb" .. i, breadcrumbBar, 100, 18, crumb.name)
        button:SetPoint("LEFT", breadcrumbBar, "LEFT", xOffset, 0)
        button.isZoneButton = true
        button.mapID = crumb.mapID
        
        -- Adjust button width based on text length
        if button.text then
            button.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            local textWidth = button.text:GetStringWidth()
            button:SetWidth(math.min(textWidth + 15, 120))
        end
        
        -- Make button clickable to navigate to that map level
        button:SetScript("OnClick", function()
            if WorldMapFrame.SetMapID then
                WorldMapFrame:SetMapID(button.mapID)
                -- Update breadcrumb after navigation
                C_Timer.After(0.1, function()
                    self:UpdateZoneBreadcrumb(breadcrumbBar)
                end)
            end
        end)
        
        -- Add separator arrow between levels (except for the last one)
        if i < #breadcrumbs then
            local arrow = breadcrumbBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            arrow:SetPoint("LEFT", button, "RIGHT", 2, 0)
            arrow:SetText(">")
            arrow:SetTextColor(0, 0, 0, 1)
            arrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            xOffset = xOffset + button:GetWidth() + 20
        else
            xOffset = xOffset + button:GetWidth() + 5
        end
        
        button:Show()
    end
end

function MapWindow:CleanupWorldMapReskin(frameName)
    WoW95:Debug("Cleaning up WorldMapFrame reskin")
    
    -- Get reference to our program window before clearing it
    local programWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
    
    -- Remove our reference to allow reopening
    WoW95.WindowsCore:RemoveProgramWindow(frameName)
    
    -- Hide our custom elements but DON'T destroy them
    if WorldMapFrame and WorldMapFrame.wow95Title then
        WorldMapFrame.wow95Title:Hide()
    end
    
    if WorldMapFrame and WorldMapFrame.wow95ZoneBreadcrumb then
        WorldMapFrame.wow95ZoneBreadcrumb:Hide()
    end
    
    -- Reset frame properties for cleanup (but keep the styling elements)
    if WorldMapFrame then
        WorldMapFrame.programName = nil
        WorldMapFrame.frameName = nil
        WorldMapFrame.isWoW95Window = nil
        WorldMapFrame.isProgramWindow = nil
        -- Keep wow95Title and wow95ZoneBreadcrumb for reuse
    end
    
    -- Notify taskbar
    if programWindow then
        WoW95:OnWindowClosed(programWindow)
    elseif WorldMapFrame then
        WoW95:OnWindowClosed(WorldMapFrame)
    end
    
    WoW95:Debug("WorldMapFrame cleanup completed - elements preserved for reuse")
end

-- Register the module
WoW95:RegisterModule("MapWindow", MapWindow)