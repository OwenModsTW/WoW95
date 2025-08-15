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
    
    -- Give it a moment to load, then style it
    C_Timer.After(0.1, function()
        if WorldMapFrame and WorldMapFrame:IsShown() then
            self:StyleAndRegisterMap(frameName, program)
        else
            WoW95:Print("Failed to open map")
        end
    end)
    
    return WorldMapFrame
end

function MapWindow:CreateWorldMapWindow(frameName, program)
    WoW95:Debug("Creating World Map window: " .. frameName)
    
    -- Create main window
    local mapWindow = WoW95:CreateWindow(frameName, UIParent, 1000, 700, program.title or "World Map")
    mapWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mapWindow:Show()
    
    -- Create map display area (main central area)
    self:CreateMapDisplay(mapWindow)
    
    -- Create zone selection panel (left side)
    self:CreateZoneSelection(mapWindow)
    
    -- Create map controls (top toolbar)
    self:CreateMapControls(mapWindow)
    
    -- Create quest panel (right side)
    self:CreateCustomQuestPanel(mapWindow)
    
    -- Create coordinate display (bottom status bar)
    self:CreateCoordinateDisplay(mapWindow)
    
    -- Initialize map system
    self:InitializeMapSystem(mapWindow)
    
    -- Set properties for taskbar recognition
    mapWindow.programName = program.name
    mapWindow.frameName = frameName
    mapWindow.isWoW95Window = true
    mapWindow.isProgramWindow = true
    
    -- Store reference
    WoW95.WindowsCore:StoreProgramWindow(frameName, mapWindow)
    
    WoW95:Debug("World Map window created successfully")
    return mapWindow
end

-- World Map Reskinning System (EXACT original code)
function MapWindow:ReskinWorldMapFrame(frameName, program)
    WoW95:Debug("=== RESKIN WORLD MAP CALLED ===")
    WoW95:Debug("Frame Name: " .. tostring(frameName))
    WoW95:Debug("Program: " .. tostring(program and program.name or "nil"))
    
    if not WorldMapFrame then
        WoW95:Debug("ERROR: WorldMapFrame not found, cannot reskin")
        WoW95:Print("ERROR: WorldMapFrame not available")
        return nil
    end
    
    WoW95:Debug("WorldMapFrame exists, proceeding with styling...")
    
    -- If already styled and showing, just register it
    if WorldMapFrame:IsShown() and not WoW95.WindowsCore:GetProgramWindow(frameName) then
        WoW95:Debug("Map already showing, just registering...")
        local success, err = pcall(function()
            self:StyleAndRegisterMap(frameName, program)
        end)
        if not success then
            WoW95:Debug("ERROR in StyleAndRegisterMap: " .. tostring(err))
            WoW95:Print("Map styling error: " .. tostring(err))
        end
        return WorldMapFrame
    end
    
    -- If already registered but hidden, just show it
    if WoW95.WindowsCore:GetProgramWindow(frameName) and not WorldMapFrame:IsShown() then
        WoW95:Debug("Map registered but hidden, showing it...")
        WorldMapFrame:Show()
        return WorldMapFrame
    end
    
    -- Style and register the map
    WoW95:Debug("Calling StyleAndRegisterMap...")
    local success, err = pcall(function()
        self:StyleAndRegisterMap(frameName, program)
    end)
    if not success then
        WoW95:Debug("ERROR in StyleAndRegisterMap: " .. tostring(err))
        WoW95:Print("Map styling error: " .. tostring(err))
        return nil
    end
    
    WoW95:Debug("ReskinWorldMapFrame completed successfully")
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
    -- Add just a simple title bar to make it look like Windows 95
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
    end
    
    -- Add zone breadcrumb navigation bar (only spans the map area, not the quest panel)
    if not WorldMapFrame.wow95ZoneBreadcrumb then
        local breadcrumbBar = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
        breadcrumbBar:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 8, -30)
        breadcrumbBar:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -258, -30) -- Stop before quest panel (250px + 8px margin)
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
        
        -- Create zone hierarchy update function
        self:UpdateZoneBreadcrumb(breadcrumbBar)
    end
    
    -- Add quest panel on the right side (beside the map, not overlapping)
    if not WorldMapFrame.wow95QuestPanel then
        local questPanel = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
        questPanel:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -8, -55) -- Start below zone breadcrumbs
        questPanel:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -8, 8)
        questPanel:SetWidth(235) -- 250 - margins
        questPanel:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 50)
        
        questPanel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        questPanel:SetBackdropColor(unpack(WoW95.colors.window))
        questPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        -- Quest panel title
        local questTitle = questPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        questTitle:SetPoint("TOP", questPanel, "TOP", 0, -8)
        questTitle:SetText("Zone Quests")
        questTitle:SetTextColor(0, 0, 0, 1)
        questTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        questTitle:SetShadowOffset(0, 0)
        
        -- Create scrollable quest list
        local questScroll = CreateFrame("ScrollFrame", nil, questPanel, "UIPanelScrollFrameTemplate")
        questScroll:SetPoint("TOPLEFT", questPanel, "TOPLEFT", 8, -30)
        questScroll:SetPoint("BOTTOMRIGHT", questPanel, "BOTTOMRIGHT", -25, 8)
        
        local questContent = CreateFrame("Frame", nil, questScroll)
        questContent:SetSize(200, 500)
        questScroll:SetScrollChild(questContent)
        
        WorldMapFrame.wow95QuestPanel = questPanel
        WorldMapFrame.wow95QuestScroll = questScroll
        WorldMapFrame.wow95QuestContent = questContent
        
        -- Update quest list when zone changes
        self:UpdateQuestList(questContent)
    end
end

function MapWindow:CleanupWorldMapReskin(frameName)
    WoW95:Debug("Cleaning up WorldMapFrame reskin")
    
    -- Get reference to our program window before clearing it
    local programWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
    
    -- Remove our reference to allow reopening
    WoW95.WindowsCore:RemoveProgramWindow(frameName)
    
    -- Clean up our custom title bar
    if WorldMapFrame and WorldMapFrame.wow95Title then
        WorldMapFrame.wow95Title:Hide()
        WorldMapFrame.wow95Title = nil
    end
    
    -- Clean up any other custom UI elements we added
    if WorldMapFrame then
        self:CleanupExistingMapUI()
    end
    
    -- Reset frame properties
    if WorldMapFrame then
        WorldMapFrame.programName = nil
        WorldMapFrame.frameName = nil
        WorldMapFrame.isWoW95Window = nil
        WorldMapFrame.isProgramWindow = nil
    end
    
    -- Notify taskbar
    if programWindow then
        WoW95:OnWindowClosed(programWindow)
    elseif WorldMapFrame then
        WoW95:OnWindowClosed(WorldMapFrame)
    end
    
    WoW95:Debug("WorldMapFrame cleanup completed - can reopen now")
end

-- Additional comprehensive map creation functions (from original Windows.lua)
function MapWindow:CreateMapDisplay(mapWindow)
    -- Create the main map display area (center)
    local mapDisplay = CreateFrame("Frame", "WoW95MapDisplay", mapWindow, "BackdropTemplate")
    mapDisplay:SetPoint("TOPLEFT", mapWindow, "TOPLEFT", 200, -50) -- Leave space for zone panel and toolbar
    mapDisplay:SetPoint("BOTTOMRIGHT", mapWindow, "BOTTOMRIGHT", -200, 25) -- Leave space for filters and status
    
    -- Map display background
    mapDisplay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    mapDisplay:SetBackdropColor(0.1, 0.1, 0.1, 1) -- Dark background for map
    mapDisplay:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Embed the real WorldMapFrame into our display
    C_Timer.After(0.1, function()
        self:EmbedWorldMapIntoContainer(mapDisplay)
    end)
    
    -- Store references
    mapWindow.mapDisplay = mapDisplay
    
    WoW95:Debug("Map display area created")
end

function MapWindow:CreateZoneSelection(mapWindow)
    -- Create zone selection panel (left side)
    local zonePanel = CreateFrame("Frame", "WoW95MapZonePanel", mapWindow, "BackdropTemplate")
    zonePanel:SetPoint("TOPLEFT", mapWindow, "TOPLEFT", 15, -25)
    zonePanel:SetSize(180, mapWindow:GetHeight() - 65)
    
    -- Zone panel background
    zonePanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    zonePanel:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    zonePanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Zone panel title
    local zoneTitle = zonePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneTitle:SetPoint("TOP", zonePanel, "TOP", 0, -8)
    zoneTitle:SetText("Zone Navigation")
    zoneTitle:SetTextColor(0, 0, 0, 1)
    zoneTitle:SetShadowOffset(0, 0)
    zoneTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    zoneTitle:SetShadowColor(0, 0, 0, 0)
    
    -- Create scrollable zone list
    local zoneScroll = CreateFrame("ScrollFrame", "WoW95MapZoneScroll", zonePanel)
    zoneScroll:SetPoint("TOPLEFT", zonePanel, "TOPLEFT", 5, -25)
    zoneScroll:SetPoint("BOTTOMRIGHT", zonePanel, "BOTTOMRIGHT", -5, 5)
    
    local zoneContent = CreateFrame("Frame", "WoW95MapZoneContent", zoneScroll)
    zoneContent:SetSize(165, 500)
    zoneScroll:SetScrollChild(zoneContent)
    
    -- Current zone display
    local currentZoneFrame = CreateFrame("Frame", nil, zoneContent, "BackdropTemplate")
    currentZoneFrame:SetPoint("TOPLEFT", zoneContent, "TOPLEFT", 5, -5)
    currentZoneFrame:SetSize(150, 60)
    currentZoneFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    currentZoneFrame:SetBackdropColor(unpack(WoW95.colors.selection))
    currentZoneFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    local currentZoneText = currentZoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentZoneText:SetPoint("CENTER")
    currentZoneText:SetText("Current Zone:\\nStormwind City")
    currentZoneText:SetTextColor(1, 1, 1, 1)
    currentZoneText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    currentZoneText:SetJustifyH("CENTER")
    currentZoneText:SetShadowColor(0, 0, 0, 0)
    
    -- Store references
    mapWindow.zonePanel = zonePanel
    mapWindow.zoneScroll = zoneScroll
    mapWindow.zoneContent = zoneContent
    mapWindow.currentZoneText = currentZoneText
    
    WoW95:Debug("Zone selection panel created")
end

function MapWindow:CreateMapControls(mapWindow)
    -- Create toolbar (top)
    local toolbar = CreateFrame("Frame", "WoW95MapToolbar", mapWindow, "BackdropTemplate")
    toolbar:SetPoint("TOPLEFT", mapWindow, "TOPLEFT", 200, -25)
    toolbar:SetPoint("TOPRIGHT", mapWindow, "TOPRIGHT", -200, -25)
    toolbar:SetHeight(22)
    
    -- Toolbar background
    toolbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    toolbar:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    toolbar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Zoom controls
    local zoomOutBtn = WoW95:CreateButton("WoW95MapZoomOut", toolbar, 40, 18, "Zoom -")
    zoomOutBtn:SetPoint("LEFT", toolbar, "LEFT", 5, 0)
    
    local zoomInBtn = WoW95:CreateButton("WoW95MapZoomIn", toolbar, 40, 18, "Zoom +")
    zoomInBtn:SetPoint("LEFT", zoomOutBtn, "RIGHT", 2, 0)
    
    -- Center on player button
    local centerBtn = WoW95:CreateButton("WoW95MapCenter", toolbar, 80, 18, "Center Player")
    centerBtn:SetPoint("LEFT", zoomInBtn, "RIGHT", 10, 0)
    
    -- Store references
    mapWindow.toolbar = toolbar
    mapWindow.zoomOutBtn = zoomOutBtn
    mapWindow.zoomInBtn = zoomInBtn
    mapWindow.centerBtn = centerBtn
    
    WoW95:Debug("Map controls created")
end

function MapWindow:CreateCustomQuestPanel(mapWindow)
    -- Create quest panel (right side) - placeholder
    local questPanel = CreateFrame("Frame", "WoW95MapQuestPanel", mapWindow, "BackdropTemplate")
    questPanel:SetPoint("TOPRIGHT", mapWindow, "TOPRIGHT", -15, -25)
    questPanel:SetSize(180, mapWindow:GetHeight() - 65)
    
    -- Quest panel background
    questPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    questPanel:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    questPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Quest panel title
    local questTitle = questPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    questTitle:SetPoint("TOP", questPanel, "TOP", 0, -8)
    questTitle:SetText("Quest Information")
    questTitle:SetTextColor(0, 0, 0, 1)
    questTitle:SetShadowOffset(0, 0)
    questTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Store reference
    mapWindow.questPanel = questPanel
    
    WoW95:Debug("Quest panel created")
end

function MapWindow:CreateCoordinateDisplay(mapWindow)
    -- Create coordinate status bar (bottom)
    local statusBar = CreateFrame("Frame", "WoW95MapStatusBar", mapWindow, "BackdropTemplate")
    statusBar:SetPoint("BOTTOMLEFT", mapWindow, "BOTTOMLEFT", 200, 8)
    statusBar:SetPoint("BOTTOMRIGHT", mapWindow, "BOTTOMRIGHT", -200, 8)
    statusBar:SetHeight(15)
    
    -- Status bar background
    statusBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    statusBar:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    statusBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Coordinate text
    local coordText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    coordText:SetPoint("LEFT", statusBar, "LEFT", 5, 0)
    coordText:SetText("Coordinates: 50.0, 50.0")
    coordText:SetTextColor(0, 0, 0, 1)
    coordText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
    -- Store reference
    mapWindow.statusBar = statusBar
    mapWindow.coordText = coordText
    
    WoW95:Debug("Coordinate display created")
end

function MapWindow:InitializeMapSystem(mapWindow)
    -- Initialize map system and load current zone
    WoW95:Debug("Initializing map system...")
    
    -- Setup coordinate updates
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        self:UpdateCoordinates(mapWindow)
    end)
    
    mapWindow.updateFrame = updateFrame
    WoW95:Debug("Map system initialized")
end

function MapWindow:UpdateCoordinates(mapWindow)
    if not mapWindow.coordText then return end
    
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            local x, y = position:GetXY()
            x, y = x * 100, y * 100
            mapWindow.coordText:SetText(string.format("Coordinates: %.1f, %.1f", x, y))
        end
    end
end

-- Embed WorldMapFrame with proper zoom initialization (EXACT original code)
function MapWindow:EmbedWorldMapIntoContainer(container)
    WoW95:Debug("Embedding WorldMapFrame with proper zoom handling...")
    
    -- Ensure WorldMapFrame exists
    if not WorldMapFrame then
        WoW95:Debug("WorldMapFrame not available")
        return
    end
    
    -- Wait for WorldMapFrame to be fully loaded before embedding
    local function EmbedWhenReady()
        if not WorldMapFrame.ScrollContainer then
            C_Timer.After(0.1, EmbedWhenReady)
            return
        end
        
        -- Store original settings
        if not container.originalMapParent then
            container.originalMapParent = WorldMapFrame:GetParent()
            container.originalMapShown = WorldMapFrame:IsShown()
        end
        
        -- Show WorldMapFrame first to ensure proper initialization
        if not WorldMapFrame:IsShown() then
            WorldMapFrame:Show()
        end
        
        -- Wait a frame for initialization, then embed
        C_Timer.After(0.1, function()
            -- Now parent it to our container
            WorldMapFrame:SetParent(container)
            WorldMapFrame:ClearAllPoints()
            WorldMapFrame:SetAllPoints(container)
            WorldMapFrame:SetAlpha(1)
            
            -- Hide Blizzard UI elements we don't want
            self:HideBlizzardMapElements()
            
            -- Ensure ScrollContainer is properly initialized
            if WorldMapFrame.ScrollContainer then
                local sc = WorldMapFrame.ScrollContainer
                
                -- Only initialize if values are actually nil
                if sc.currentZoomLevel == nil then
                    sc.currentZoomLevel = 1
                end
                
                WoW95:Debug("Map embedded successfully into container")
            end
        end)
    end
    
    EmbedWhenReady()
end

function MapWindow:HideBlizzardMapElements()
    -- Hide unnecessary Blizzard UI elements
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

-- Helper function to update zone breadcrumb navigation
function MapWindow:UpdateZoneBreadcrumb(breadcrumbBar)
    -- Clear existing buttons
    for i = 1, breadcrumbBar:GetNumChildren() do
        local child = select(i, breadcrumbBar:GetChildren())
        if child and child.isZoneButton then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Get current map info
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    
    local breadcrumbs = {}
    local currentMapID = mapID
    
    -- Build hierarchy from current zone up to continent
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
    
    -- Create buttons for each level
    local xOffset = 5
    for i, crumb in ipairs(breadcrumbs) do
        local button = WoW95:CreateButton("ZoneCrumb" .. i, breadcrumbBar, 100, 18, crumb.name)
        button:SetPoint("LEFT", breadcrumbBar, "LEFT", xOffset, 0)
        button.isZoneButton = true
        button.mapID = crumb.mapID
        
        -- Adjust button width based on text
        if button.text then
            button.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            local textWidth = button.text:GetStringWidth()
            button:SetWidth(math.min(textWidth + 15, 120))
        end
        
        button:SetScript("OnClick", function()
            -- Navigate to this map
            WorldMapFrame:SetMapID(button.mapID)
            self:UpdateZoneBreadcrumb(breadcrumbBar)
            self:UpdateQuestList(WorldMapFrame.wow95QuestContent)
        end)
        
        -- Add separator arrow
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
    end
end

-- Helper function to update quest list for current zone
function MapWindow:UpdateQuestList(questContent)
    if not questContent then return end
    
    -- Clear existing quest buttons
    for i = 1, questContent:GetNumChildren() do
        local child = select(i, questContent:GetChildren())
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Get current map ID
    local mapID = WorldMapFrame:GetMapID() or C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    
    -- Get quests for this zone
    local questsOnMap = C_QuestLog.GetQuestsOnMap(mapID)
    if not questsOnMap or #questsOnMap == 0 then
        -- Show "No quests" message
        local noQuestsText = questContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noQuestsText:SetPoint("TOP", questContent, "TOP", 0, -10)
        noQuestsText:SetText("No quests in this zone")
        noQuestsText:SetTextColor(0.5, 0.5, 0.5, 1)
        noQuestsText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        return
    end
    
    -- Create quest entries
    local yOffset = -5
    for i, questInfo in ipairs(questsOnMap) do
        local questFrame = CreateFrame("Frame", nil, questContent, "BackdropTemplate")
        questFrame:SetPoint("TOPLEFT", questContent, "TOPLEFT", 5, yOffset)
        questFrame:SetPoint("RIGHT", questContent, "RIGHT", -5, 0)
        questFrame:SetHeight(30)
        
        questFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        questFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
        questFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        
        -- Quest name
        local questName = questFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        questName:SetPoint("TOPLEFT", questFrame, "TOPLEFT", 5, -5)
        questName:SetPoint("RIGHT", questFrame, "RIGHT", -5, 0)
        questName:SetJustifyH("LEFT")
        
        local questTitle = C_QuestLog.GetTitleForQuestID(questInfo.questID) or "Quest " .. questInfo.questID
        questName:SetText(questTitle)
        questName:SetTextColor(0, 0, 0, 1)
        questName:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        
        -- Make clickable to focus on map
        questFrame:EnableMouse(true)
        questFrame:SetScript("OnEnter", function()
            questFrame:SetBackdropColor(unpack(WoW95.colors.selection))
            GameTooltip:SetOwner(questFrame, "ANCHOR_LEFT")
            GameTooltip:SetText(questTitle)
            GameTooltip:AddLine("Click to focus on map", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        
        questFrame:SetScript("OnLeave", function()
            questFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
            GameTooltip:Hide()
        end)
        
        questFrame:SetScript("OnMouseDown", function()
            -- Focus quest on map
            if questInfo.x and questInfo.y then
                WorldMapFrame:SetMapID(mapID)
                -- TODO: Add map pin highlighting
            end
        end)
        
        yOffset = yOffset - 35
    end
    
    -- Update content frame height
    questContent:SetHeight(math.max(500, math.abs(yOffset) + 20))
end

-- Hook map events to update our custom UI
function MapWindow:HookMapEvents()
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function()
            if WorldMapFrame.wow95ZoneBreadcrumb then
                self:UpdateZoneBreadcrumb(WorldMapFrame.wow95ZoneBreadcrumb)
            end
            if WorldMapFrame.wow95QuestContent then
                self:UpdateQuestList(WorldMapFrame.wow95QuestContent)
            end
            -- Stabilize map position
            self:StabilizeMapPosition()
        end)
        
        -- Hook map change events
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            if WorldMapFrame.wow95ZoneBreadcrumb then
                self:UpdateZoneBreadcrumb(WorldMapFrame.wow95ZoneBreadcrumb)
            end
            if WorldMapFrame.wow95QuestContent then
                self:UpdateQuestList(WorldMapFrame.wow95QuestContent)
            end
            -- Stabilize map position after zone change
            C_Timer.After(0.1, function()
                self:StabilizeMapPosition()
            end)
        end)
    end
end

-- Helper function to prevent map jumping by stabilizing position
function MapWindow:StabilizeMapPosition()
    if WorldMapFrame and WorldMapFrame.ScrollContainer then
        local canvas = WorldMapFrame.ScrollContainer
        -- Reset map position to center and prevent jumping
        if canvas.SetPanTarget then
            canvas:SetPanTarget(0.5, 0.5)
        end
        -- Ensure canvas stays in bounds
        canvas:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 8, -55)
        canvas:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -250, 5)
    end
end

-- Initialize hooks when module loads
C_Timer.After(1, function()
    MapWindow:HookMapEvents()
end)

-- Register the module
WoW95:RegisterModule("MapWindow", MapWindow)