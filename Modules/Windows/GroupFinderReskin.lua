-- WoW95 Group Finder Reskin Module
-- Windows 95 styling applied to vanilla Group Finder UI

local addonName, WoW95 = ...

local GroupFinderReskin = {}
WoW95.GroupFinderReskin = GroupFinderReskin

-- Track if we've already applied styling
GroupFinderReskin.isStyled = false

function GroupFinderReskin:CreateWindow(frameName, program)
    WoW95:Debug("=== GroupFinderReskin:CreateWindow called ===")
    WoW95:Debug("Frame name: " .. tostring(frameName))
    
    -- Check if window already exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    -- Wait for PVEFrame to be available
    if not PVEFrame then
        WoW95:Debug("PVEFrame not yet available, waiting...")
        C_Timer.After(0.5, function()
            self:CreateWindow(frameName, program)
        end)
        return
    end
    
    -- Show the vanilla PVE frame first
    if not PVEFrame:IsShown() then
        WoW95:Debug("Opening vanilla PVE frame...")
        PVEFrame_ShowFrame()
    end
    
    -- Apply our Windows 95 styling
    C_Timer.After(0.1, function()
        if PVEFrame and PVEFrame:IsShown() then
            self:ApplyWindows95Styling(frameName, program)
        end
    end)
    
    return PVEFrame
end

function GroupFinderReskin:ApplyWindows95Styling(frameName, program)
    WoW95:Debug("Applying Windows 95 styling to PVEFrame")
    
    -- Always reset isStyled to allow re-styling
    self.isStyled = false
    
    -- Hide Blizzard's default styling elements
    self:HideBlizzardElements()
    
    -- Apply Windows 95 frame styling
    self:StyleMainFrame()
    
    -- Add Windows 95 title bar
    self:AddTitleBar()
    
    -- Create Windows 95 styled overlays for UI sections
    self:CreateWindows95Overlays()
    
    -- Register with WindowsCore
    self:RegisterFrame(frameName, program)
    
    -- Hook cleanup
    self:SetupCleanupHooks(frameName)
    
    self.isStyled = true
    WoW95:Debug("Windows 95 styling applied successfully")
end

function GroupFinderReskin:HideBlizzardElements()
    -- Only hide visual border elements, keep all content
    local elementsToHide = {
        "TitleContainer",  -- Hide the title but keep tabs
        "PortraitContainer", 
        "TopTileStreaks"
    }
    
    for _, elementName in ipairs(elementsToHide) do
        if PVEFrame[elementName] then
            PVEFrame[elementName]:Hide()
        end
    end
    
    -- Hide the NineSlice border but keep the background
    if PVEFrame.NineSlice then
        PVEFrame.NineSlice:Hide()
    end
    
    -- Ensure background and inset are visible
    if PVEFrame.Bg then
        PVEFrame.Bg:Show()
    end
    if PVEFrame.Inset then
        PVEFrame.Inset:Show()
    end
end

function GroupFinderReskin:StyleMainFrame()
    -- Add BackdropTemplate mixin if not already present
    if not PVEFrame.SetBackdrop then
        Mixin(PVEFrame, BackdropTemplateMixin)
    end
    
    -- Apply Windows 95 backdrop to the main frame
    PVEFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    PVEFrame:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Windows 95 gray
    PVEFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Ensure proper size and position
    PVEFrame:SetSize(850, 600)
    PVEFrame:ClearAllPoints()
    PVEFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function GroupFinderReskin:AddTitleBar()
    if PVEFrame.wow95TitleBar then
        PVEFrame.wow95TitleBar:Show()
        return
    end
    
    -- Create Windows 95 title bar
    local titleBar = CreateFrame("Frame", nil, PVEFrame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", PVEFrame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    titleBar:SetFrameLevel(PVEFrame:GetFrameLevel() + 100)
    
    -- Title bar backdrop
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1
    })
    titleBar:SetBackdropColor(unpack(WoW95.colors.titleBar))
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    WoW95:Debug("GroupFinder title bar color set to: " .. table.concat(WoW95.colors.titleBar, ", "))
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText("Group Finder - World of Warcraft")
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Close button
    local closeButton = WoW95:CreateTitleBarButton("PVECloseBtn", titleBar, WoW95.textures.close, 16)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    closeButton:SetScript("OnClick", function()
        PVEFrame:Hide()
    end)
    
    -- Make title bar draggable
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        PVEFrame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        PVEFrame:StopMovingOrSizing()
    end)
    
    -- Enable moving
    PVEFrame:SetMovable(true)
    PVEFrame:SetClampedToScreen(true)
    
    PVEFrame.wow95TitleBar = titleBar
end

function GroupFinderReskin:CreateWindows95Overlays()
    WoW95:Debug("Creating Windows 95 styled overlays for GroupFinder")
    
    -- Create left panel overlay (dungeon finder, raid finder, premade groups buttons)
    self:CreateLeftPanelOverlay()
    
    -- Create bottom tabs overlay (Dungeon & Raids, PvP, Mythic+, Delves)
    self:CreateBottomTabsOverlay()
    
    -- Ensure main content area displays properly on first load
    self:FixMainContentDisplay()
end

function GroupFinderReskin:CreateLeftPanelOverlay()
    if PVEFrame.wow95LeftPanel then
        PVEFrame.wow95LeftPanel:Show()
        return
    end
    
    -- Research showed Inset is 217x572 at TOPLEFT - overlay this exactly
    if not PVEFrame.Inset then
        WoW95:Debug("PVEFrame.Inset not found - cannot create left panel overlay")
        return
    end
    
    -- Create Windows 95 styled overlay that goes BEHIND the Inset, not on top
    local leftPanel = CreateFrame("Frame", nil, PVEFrame, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", PVEFrame.Inset, "TOPLEFT", 0, 0)
    leftPanel:SetPoint("BOTTOMRIGHT", PVEFrame.Inset, "BOTTOMRIGHT", 0, 0)
    leftPanel:SetFrameLevel(PVEFrame.Inset:GetFrameLevel() - 1) -- BEHIND the inset
    
    -- Windows 95 styling
    leftPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    leftPanel:SetBackdropColor(unpack(WoW95.colors.window))
    leftPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Make the Inset transparent so we can see our backdrop but keep buttons clickable
    if PVEFrame.Inset.Bg then
        PVEFrame.Inset.Bg:SetAlpha(0)
    end
    
    -- Style existing buttons while preserving their functionality
    self:StyleLeftPanelButtons()
    
    PVEFrame.wow95LeftPanel = leftPanel
    WoW95:Debug("Created left panel backdrop behind Inset area")
end

function GroupFinderReskin:StyleLeftPanelButtons()
    -- Find and style the actual vanilla buttons inside the Inset
    if not PVEFrame.Inset then return end
    
    -- Look for buttons within the Inset that we can style
    local function StyleChildButtons(parent)
        for i = 1, parent:GetNumChildren() do
            local child = select(i, parent:GetChildren())
            if child and child:IsObjectType("Button") and child:IsVisible() then
                -- Create backdrop behind button instead of modifying the button itself
                if not child.wow95Styled then
                    local backdrop = CreateFrame("Frame", nil, child, "BackdropTemplate")
                    backdrop:SetAllPoints(child)
                    backdrop:SetFrameLevel(child:GetFrameLevel() - 1) -- Behind the button
                    
                    backdrop:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = false,
                        tileSize = 8,
                        edgeSize = 1,
                        insets = {left = 1, right = 1, top = 1, bottom = 1}
                    })
                    backdrop:SetBackdropColor(unpack(WoW95.colors.buttonFace))
                    backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    
                    child.wow95Styled = true
                    child.wow95Backdrop = backdrop
                    WoW95:Debug("Created backdrop for button: " .. (child:GetName() or "unnamed"))
                end
            elseif child and child:GetNumChildren() > 0 then
                StyleChildButtons(child) -- Recursively style nested buttons
            end
        end
    end
    
    -- Delay styling to ensure buttons are loaded
    C_Timer.After(0.1, function()
        StyleChildButtons(PVEFrame.Inset)
    end)
end

function GroupFinderReskin:CreateBottomTabsOverlay()
    if PVEFrame.wow95BottomTabs then
        WoW95:Debug("Bottom tabs already styled, skipping")
        return
    end
    
    -- Style the existing tabs (tab1, tab2, tab3, tab4) instead of creating new ones
    self:StyleExistingTabs()
    
    -- Mark that we've styled the tabs
    PVEFrame.wow95BottomTabs = true
    WoW95:Debug("Styled existing bottom tabs")
end

function GroupFinderReskin:StyleExistingTabs()
    -- DON'T style the tabs directly - this breaks their functionality
    -- Instead, create overlays that preserve the original tab behavior
    
    local tabs = {"tab1", "tab2", "tab3", "tab4"}
    
    for _, tabName in ipairs(tabs) do
        local tab = PVEFrame[tabName]
        if tab and not tab.wow95Styled then
            -- Create a backdrop frame behind the tab instead of modifying the tab itself
            local backdrop = CreateFrame("Frame", nil, tab, "BackdropTemplate")
            backdrop:SetAllPoints(tab)
            backdrop:SetFrameLevel(tab:GetFrameLevel() - 1) -- Behind the original tab
            
            -- Apply Windows 95 styling to the backdrop
            backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false,
                tileSize = 8,
                edgeSize = 1,
                insets = {left = 1, right = 1, top = 1, bottom = 1}
            })
            backdrop:SetBackdropColor(unpack(WoW95.colors.buttonFace))
            backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            -- Style the tab text without breaking functionality
            if tab.Text then
                tab.Text:SetTextColor(unpack(WoW95.colors.buttonText))
                tab.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            end
            
            tab.wow95Styled = true
            tab.wow95Backdrop = backdrop
            WoW95:Debug("Created backdrop for tab: " .. tabName .. " - " .. (tab.Text and tab.Text:GetText() or "no text"))
        end
    end
end

function GroupFinderReskin:FixMainContentDisplay()
    -- Force show the default content on first load
    C_Timer.After(0.2, function()
        if PVEFrame:IsShown() and PVEFrame_ShowFrame then
            -- Default to showing Dungeon Finder
            PVEFrame_ShowFrame("GroupFinderFrame", LFDParentFrame)
        end
    end)
end

function GroupFinderReskin:StyleInternalElements()
    -- Style the content area
    if PVEFrame.shadows then
        PVEFrame.shadows:Hide()
    end
    
    -- Don't reposition content - let it show naturally
    -- The content should be visible with just the backdrop and title bar changes
    
    -- Don't style buttons - keep vanilla appearance to prevent cascading
    -- self:StyleButtons(PVEFrame)
    
    -- Don't style dropdown menus - keep vanilla functionality  
    -- self:StyleDropdowns()
end

function GroupFinderReskin:StyleButtons(parent)
    if not parent then return end
    
    -- Recursively find and style buttons
    for i = 1, parent:GetNumChildren() do
        local child = select(i, parent:GetChildren())
        if child then
            if child:IsObjectType("Button") and child:IsVisible() then
                -- Apply Windows 95 button styling
                if not child.wow95Styled then
                    -- Add BackdropTemplate mixin if not already present
                    if not child.SetBackdrop then
                        Mixin(child, BackdropTemplateMixin)
                    end
                    
                    child:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = false,
                        tileSize = 8,
                        edgeSize = 1,
                        insets = {left = 1, right = 1, top = 1, bottom = 1}
                    })
                    child:SetBackdropColor(unpack(WoW95.colors.buttonFace))
                    child:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    child.wow95Styled = true
                end
            elseif child:GetNumChildren() > 0 then
                -- Recursively style child frames
                self:StyleButtons(child)
            end
        end
    end
end

function GroupFinderReskin:StyleDropdowns()
    -- Hook the dropdown creation to style them when they appear
    local function StyleDropdownFrame(frame)
        if frame then
            -- Add BackdropTemplate mixin if not already present
            if not frame.SetBackdrop then
                Mixin(frame, BackdropTemplateMixin)
            end
            
            frame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 8,
                edgeSize = 1,
                insets = {left = 1, right = 1, top = 1, bottom = 1}
            })
            frame:SetBackdropColor(1, 1, 1, 1)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end
    
    -- Hook UIDropDownMenu functions to apply styling
    if not self.dropdownHooked then
        hooksecurefunc("UIDropDownMenu_CreateFrames", function()
            for i = 1, UIDROPDOWNMENU_MAXLEVELS do
                local menu = _G["DropDownList"..i]
                if menu then
                    StyleDropdownFrame(menu)
                end
            end
        end)
        self.dropdownHooked = true
    end
end

function GroupFinderReskin:RegisterFrame(frameName, program)
    -- Store reference for taskbar
    WoW95.WindowsCore:StoreProgramWindow(frameName, PVEFrame)
    PVEFrame.programName = program.name
    PVEFrame.frameName = frameName
    PVEFrame.isWoW95Window = true
    PVEFrame.isProgramWindow = true
    
    -- Notify taskbar
    WoW95:OnWindowOpened(PVEFrame)
end

function GroupFinderReskin:SetupCleanupHooks(frameName)
    if PVEFrame.wow95CleanupHooked then return end
    
    PVEFrame:HookScript("OnHide", function()
        self:CleanupReskin(frameName)
    end)
    
    PVEFrame.wow95CleanupHooked = true
end

function GroupFinderReskin:CleanupReskin(frameName)
    WoW95:Debug("Cleaning up Group Finder reskin")
    
    -- Get reference before clearing
    local programWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
    
    -- Remove registration to allow reopening
    WoW95.WindowsCore:RemoveProgramWindow(frameName)
    
    -- Hide our custom elements but don't destroy them
    if PVEFrame.wow95TitleBar then
        PVEFrame.wow95TitleBar:Hide()
    end
    if PVEFrame.wow95LeftPanel then
        PVEFrame.wow95LeftPanel:Hide()
    end
    -- wow95BottomTabs is a boolean flag, not a frame - no need to hide
    
    -- Reset frame properties
    if PVEFrame then
        PVEFrame.programName = nil
        PVEFrame.frameName = nil
        PVEFrame.isWoW95Window = nil
        PVEFrame.isProgramWindow = nil
        -- Reset styling flags
        PVEFrame.wow95BottomTabs = nil
    end
    
    -- Reset styling state to allow re-styling
    self.isStyled = false
    
    -- Notify taskbar
    if programWindow then
        WoW95:OnWindowClosed(programWindow)
    end
    
    WoW95:Debug("Group Finder reskin cleanup completed")
end

-- Debug command to research PVEFrame structure
SLASH_WOW95GFDEBUG1 = "/wow95gfdebug"
SlashCmdList["WOW95GFDEBUG"] = function(msg)
    if not PVEFrame then
        WoW95:Print("PVEFrame not found!")
        return
    end
    
    WoW95:Print("=== PVEFrame Structure Research ===")
    WoW95:Print("PVEFrame size: " .. PVEFrame:GetWidth() .. " x " .. PVEFrame:GetHeight())
    WoW95:Print("PVEFrame shown: " .. tostring(PVEFrame:IsShown()))
    
    -- List all major child frames
    WoW95:Print("--- Major Child Frames ---")
    local importantChildren = {
        "Inset", "Bg", "NineSlice", "TitleContainer", "PortraitContainer",
        "tab1", "tab2", "tab3", "tab4", "CloseButton", "shadows"
    }
    
    for _, childName in ipairs(importantChildren) do
        local child = PVEFrame[childName]
        if child then
            local shown = child:IsShown() and "SHOWN" or "HIDDEN"
            local size = child:GetWidth() .. "x" .. child:GetHeight()
            local point, relativeTo, relativePoint, x, y = child:GetPoint()
            WoW95:Print("  " .. childName .. ": " .. shown .. " (" .. size .. ") at " .. (point or "nil"))
        else
            WoW95:Print("  " .. childName .. ": NOT FOUND")
        end
    end
    
    -- Check current active tab and content
    WoW95:Print("--- Tab Information ---")
    WoW95:Print("Active tab index: " .. tostring(PVEFrame.activeTabIndex))
    WoW95:Print("Selected tab: " .. tostring(PVEFrame.selectedTab))
    WoW95:Print("Num tabs: " .. tostring(PVEFrame.numTabs))
    
    -- List tab frames
    for i = 1, 4 do
        local tab = PVEFrame["tab" .. i]
        if tab then
            local shown = tab:IsShown() and "SHOWN" or "HIDDEN" 
            local text = tab.Text and tab.Text:GetText() or "No text"
            WoW95:Print("  Tab " .. i .. ": " .. shown .. " - '" .. text .. "'")
        end
    end
    
    -- Research the actual content areas
    WoW95:Print("--- Content Areas ---")
    local contentFrames = {
        "GroupFinderFrame", "LFDParentFrame", "LFGListPVEStub", 
        "RaidFinderFrame", "PVPUIFrame", "ChallengesFrame"
    }
    
    for _, frameName in ipairs(contentFrames) do
        local frame = _G[frameName]
        if frame then
            local shown = frame:IsShown() and "SHOWN" or "HIDDEN"
            local parent = frame:GetParent() and frame:GetParent():GetName() or "nil"
            WoW95:Print("  " .. frameName .. ": " .. shown .. " (parent: " .. parent .. ")")
        else
            WoW95:Print("  " .. frameName .. ": NOT FOUND")
        end
    end
end

-- Register the module
WoW95:RegisterModule("GroupFinderReskin", GroupFinderReskin)