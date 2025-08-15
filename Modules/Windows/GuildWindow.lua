-- WoW95 Guild & Communities Window Module  
-- COMPLETE vanilla-style guild management with full utility
-- Extracted and enhanced from original Windows.lua

local addonName, WoW95 = ...

local GuildWindow = {}
WoW95.GuildWindow = GuildWindow

-- Guild window data
GuildWindow.GUILD_RANKS = {}
GuildWindow.GUILD_MEMBERS = {}
GuildWindow.SELECTED_MEMBER = nil
GuildWindow.FILTER_SETTINGS = {
    showOffline = true,
    classFilter = "ALL",
    rankFilter = "ALL",
    levelMin = 1,
    levelMax = 90
}

function GuildWindow:CreateWindow(frameName, program)
    WoW95:Debug("=== GuildWindow:CreateWindow called ===")
    WoW95:Debug("Frame name: " .. tostring(frameName))
    WoW95:Debug("Program: " .. tostring(program and program.name or "nil"))
    WoW95:Debug("About to create custom guild window with blue title bar...")
    
    -- Debug what frames actually exist
    WoW95:Debug("Checking guild-related frames:")
    WoW95:Debug("GuildFrame exists: " .. tostring(_G["GuildFrame"] ~= nil))
    WoW95:Debug("CommunitiesFrame exists: " .. tostring(_G["CommunitiesFrame"] ~= nil))
    WoW95:Debug("ClubFinderGuildFinderFrame exists: " .. tostring(_G["ClubFinderGuildFinderFrame"] ~= nil))
    
    -- Check if window already exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug("Guild & Communities window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    WoW95:Debug("Creating NEW Guild & Communities window with advanced features")
    
    -- Create the main guild window using standard WoW95 window creation (ensures blue title bar)
    local programWindow = WoW95:CreateWindow(
        "WoW95GuildWindow", 
        UIParent, 
        program.window.width or 800, 
        program.window.height or 600, 
        program.window.title or "Guild & Communities - World of Warcraft"
    )
    
    -- Position window
    programWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- MANUALLY FORCE BLUE TITLE BAR (copy exact code from working windows)
    if programWindow.titleBar then
        WoW95:Debug("Found titleBar, forcing blue color...")
        -- Apply the EXACT same title bar styling as other working windows
        programWindow.titleBar:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 16,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        programWindow.titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- DIRECT BLUE COLOR
        programWindow.titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        WoW95:Debug("MANUALLY forced guild window title bar to BLUE")
        
        -- Fix title text color too
        if programWindow.titleText then
            programWindow.titleText:SetTextColor(1, 1, 1, 1) -- White text
        end
    else
        WoW95:Debug("ERROR: No titleBar found on programWindow!")
    end
    
    
    -- Guild window specific data
    programWindow.currentTab = "roster"
    programWindow.tabs = {}
    programWindow.tabContent = {}
    
    -- Define comprehensive tabs matching retail Communities UI
    programWindow.GUILD_TABS = {
        {id = "roster", name = "Roster", icon = "Interface\\Icons\\Achievement_Guild_Classyorange"},
        {id = "info", name = "Guild Info", icon = "Interface\\Icons\\INV_Misc_Note_01"},
        {id = "news", name = "News", icon = "Interface\\Icons\\INV_Letter_18"},
        {id = "perks", name = "Perks", icon = "Interface\\Icons\\Achievement_Guild_CatchingUp"},
        {id = "communities", name = "Communities", icon = "Interface\\Icons\\Achievement_Guild_ProtectNPCs"}
    }
    
    -- Check guild permissions for officer features
    programWindow.isOfficer = false
    programWindow.canInvite = false
    programWindow.canRemove = false
    programWindow.canPromote = false
    
    if IsInGuild() then
        local guildName, guildRank = GetGuildInfo("player")
        programWindow.isOfficer = CanGuildInvite() or CanGuildRemove() or CanGuildPromote()
        programWindow.canInvite = CanGuildInvite()
        programWindow.canRemove = CanGuildRemove()
        programWindow.canPromote = CanGuildPromote()
        programWindow.playerRank = guildRank
        
        WoW95:Debug("Guild permissions - Officer: " .. tostring(programWindow.isOfficer) .. 
                   ", Invite: " .. tostring(programWindow.canInvite) .. 
                   ", Remove: " .. tostring(programWindow.canRemove) .. 
                   ", Promote: " .. tostring(programWindow.canPromote))
    end
    
    -- Create tab bar (positioned well below title bar)
    local tabBar = CreateFrame("Frame", nil, programWindow, "BackdropTemplate")
    tabBar:SetPoint("TOPLEFT", programWindow, "TOPLEFT", 8, -30)  -- Changed from -50 to -30 to be closer but not overlap
    tabBar:SetPoint("TOPRIGHT", programWindow, "TOPRIGHT", -8, -30)
    tabBar:SetHeight(25)  -- Slightly shorter
    
    tabBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    tabBar:SetBackdropColor(0.7, 0.7, 0.7, 1)
    tabBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create tab buttons
    local tabWidth = 140
    for i, tabData in ipairs(programWindow.GUILD_TABS) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tab:SetSize(tabWidth, 25)
        tab:SetPoint("LEFT", tabBar, "LEFT", (i-1) * tabWidth + 5, 0)
        
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        tab:SetBackdropColor(0.75, 0.75, 0.75, 1)
        tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        -- Tab text
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        tabText:SetText(tabData.name)
        tabText:SetTextColor(0, 0, 0, 1)
        tabText:SetShadowOffset(0, 0)
        
        -- Tab functionality
        tab.tabId = tabData.id
        tab:SetScript("OnClick", function()
            self:SwitchToTab(programWindow, tabData.id)
        end)
        
        -- Tab hover effects
        tab:SetScript("OnEnter", function(self)
            if programWindow.currentTab ~= tabData.id then
                self:SetBackdropColor(0.85, 0.85, 0.85, 1)
            end
        end)
        tab:SetScript("OnLeave", function(self)
            if programWindow.currentTab ~= tabData.id then
                self:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
        end)
        
        programWindow.tabs[tabData.id] = tab
    end
    
    -- Create content area
    local contentArea = CreateFrame("Frame", nil, programWindow, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
    contentArea:SetPoint("BOTTOMRIGHT", programWindow, "BOTTOMRIGHT", -8, 8)
    
    contentArea:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    contentArea:SetBackdropColor(1, 1, 1, 1) -- White background
    contentArea:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create content frames for each tab
    for _, tabData in ipairs(programWindow.GUILD_TABS) do
        local content = CreateFrame("Frame", nil, contentArea)
        content:SetAllPoints(contentArea)
        content:Hide()
        content.contentCreated = false
        programWindow.tabContent[tabData.id] = content
    end
    
    -- Set window properties for taskbar recognition
    programWindow.programName = program.name
    programWindow.frameName = frameName
    programWindow.isWoW95Window = true
    programWindow.isProgramWindow = true
    
    -- Store reference
    WoW95.WindowsCore:StoreProgramWindow(frameName, programWindow)
    
    -- Setup close handling
    programWindow:SetScript("OnHide", function()
        if WoW95.WindowsCore:GetProgramWindow(frameName) == programWindow then
            WoW95:Debug("Guild window hidden, cleaning up tracking")
            WoW95.WindowsCore:RemoveProgramWindow(frameName)
            WoW95:OnWindowClosed(programWindow)
        end
    end)
    
    -- Show the window and activate first tab
    programWindow:Show()
    self:SwitchToTab(programWindow, "roster")
    
    -- Notify taskbar
    WoW95:OnWindowOpened(programWindow)
    
    WoW95:Debug("Guild & Communities window created successfully")
    return programWindow
end

function GuildWindow:CreateGuildWindowFrame(name, parent, width, height, title)
    WoW95:Debug("=== CreateGuildWindowFrame called ===")
    WoW95:Debug("Creating guild window with BLUE title bar")
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    
    -- Set size
    frame:SetSize(width or 800, height or 600)
    
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
    
    -- Create title bar with BLUE background
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
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- BLUE title bar
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    WoW95:Debug("Applied BLUE title bar color (0.0, 0.0, 0.5, 1)")
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText(title or "Guild & Communities")
    titleText:SetTextColor(1, 1, 1, 1) -- White text
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    WoW95:Debug("Guild window title bar setup complete - should be blue with white text")
    
    -- Close button using custom texture
    local closeButton = WoW95:CreateTitleBarButton(name .. "CloseButton", titleBar, WoW95.textures.close, 16)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    
    -- Close button functionality
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        WoW95:OnWindowClosed(frame)
    end)
    
    -- Make frame movable
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
    frame.isWoW95Window = true
    
    return frame
end

-- Helper functions for guild roster management
function GuildWindow:RefreshMemberList()
    WoW95:Debug("Refreshing guild member list...")
    
    -- Find the member list scroll child and repopulate it
    local guildWindow = WoW95.WindowsCore:GetProgramWindow("GuildFrame") or WoW95.WindowsCore:GetProgramWindow("CommunitiesFrame")
    if guildWindow then
        -- Look for memberPanel in both possible structures
        local scrollChild = nil
        if guildWindow.memberPanel and guildWindow.memberPanel.scrollChild then
            scrollChild = guildWindow.memberPanel.scrollChild
        elseif guildWindow.tabContent and guildWindow.tabContent.roster then
            local rosterContent = guildWindow.tabContent.roster
            if rosterContent.memberPanel and rosterContent.memberPanel.scrollChild then
                scrollChild = rosterContent.memberPanel.scrollChild
            end
        end
        
        if scrollChild then
            WoW95:Debug("Found scroll child, repopulating member list")
            self:PopulateAdvancedMemberList(scrollChild)
        else
            WoW95:Debug("Could not find member list scroll child for refresh")
        end
    else
        WoW95:Debug("Could not find guild window for refresh")
    end
end

function GuildWindow:SelectMember(memberData)
    WoW95:Debug("Selected member: " .. tostring(memberData.name))
    self.SELECTED_MEMBER = memberData
    
    -- Update member details panel
    self:UpdateMemberDetails(memberData)
end

function GuildWindow:UpdateMemberSelection(selectedFrame)
    -- Clear previous selection
    if self.SELECTED_MEMBER_FRAME then
        if self.SELECTED_MEMBER_FRAME.originalBackdropColor then
            self.SELECTED_MEMBER_FRAME:SetBackdropColor(unpack(self.SELECTED_MEMBER_FRAME.originalBackdropColor))
        end
    end
    
    -- Set new selection
    self.SELECTED_MEMBER_FRAME = selectedFrame
    if selectedFrame then
        selectedFrame.originalBackdropColor = {selectedFrame:GetBackdropColor()}
        selectedFrame:SetBackdropColor(0.7, 0.8, 1.0, 1) -- Light blue selection
    end
end

function GuildWindow:UpdateMemberDetails(memberData)
    WoW95:Debug("Updating member details for: " .. tostring(memberData.name))
    
    -- Find the member details panel
    local guildWindow = WoW95.WindowsCore:GetProgramWindow("GuildFrame") or WoW95.WindowsCore:GetProgramWindow("CommunitiesFrame")
    if not guildWindow then return end
    
    local detailPanel = nil
    if guildWindow.detailPanel then
        detailPanel = guildWindow.detailPanel
    elseif guildWindow.tabContent and guildWindow.tabContent.roster and guildWindow.tabContent.roster.detailPanel then
        detailPanel = guildWindow.tabContent.roster.detailPanel
    end
    
    if not detailPanel then
        WoW95:Debug("Could not find member details panel")
        return
    end
    
    -- Clear existing content by removing all font strings and frames
    local regions = {detailPanel:GetRegions()}
    for _, region in pairs(regions) do
        if region.isMemberDetails then
            region:Hide()
            region:SetParent(nil)
        elseif region:GetObjectType() == "FontString" and region:GetParent() == detailPanel then
            -- Remove all existing font strings to prevent stacking
            region:Hide()
            region:SetParent(nil)
        end
    end
    
    local children = {detailPanel:GetChildren()}
    for _, child in pairs(children) do
        if child.isMemberDetails then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Create new member details content
    local yOffset = -10
    
    -- Member name and class
    local nameText = detailPanel:CreateFontString(nil, "OVERLAY")
    nameText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    nameText:SetText(memberData.name)
    nameText.isMemberDetails = true
    
    -- Get class color
    local classColor = RAID_CLASS_COLORS[memberData.class] or {r=0, g=0, b=0}
    nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
    yOffset = yOffset - 25
    
    -- Level and class
    local classText = detailPanel:CreateFontString(nil, "OVERLAY")
    classText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
    classText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    classText:SetText("Level " .. memberData.level .. " " .. memberData.class)
    classText:SetTextColor(0, 0, 0, 1)
    classText.isMemberDetails = true
    yOffset = yOffset - 20
    
    -- Guild rank
    local rankText = detailPanel:CreateFontString(nil, "OVERLAY")
    rankText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    rankText:SetText("Rank: " .. memberData.rank)
    rankText:SetTextColor(0.1, 0.1, 0.5, 1)
    rankText.isMemberDetails = true
    yOffset = yOffset - 20
    
    -- Online status
    local statusText = detailPanel:CreateFontString(nil, "OVERLAY")
    statusText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    if memberData.online then
        statusText:SetText("Status: Online")
        statusText:SetTextColor(0, 0.7, 0, 1)
    else
        statusText:SetText("Status: Offline")
        statusText:SetTextColor(0.7, 0, 0, 1)
    end
    statusText.isMemberDetails = true
    yOffset = yOffset - 25
    
    -- Public note
    if memberData.note and memberData.note ~= "" then
        local noteLabel = detailPanel:CreateFontString(nil, "OVERLAY")
        noteLabel:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
        noteLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        noteLabel:SetText("Note:")
        noteLabel:SetTextColor(0.1, 0.1, 0.5, 1)
        noteLabel.isMemberDetails = true
        yOffset = yOffset - 15
        
        local noteText = detailPanel:CreateFontString(nil, "OVERLAY")
        noteText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
        noteText:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -10, yOffset)
        noteText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        noteText:SetText(memberData.note)
        noteText:SetTextColor(0, 0, 0, 1)
        noteText:SetJustifyH("LEFT")
        noteText:SetWordWrap(true)
        noteText.isMemberDetails = true
        yOffset = yOffset - 30
    end
    
    -- Officer note (if available)
    if memberData.officerNote and memberData.officerNote ~= "" then
        local officerNoteLabel = detailPanel:CreateFontString(nil, "OVERLAY")
        officerNoteLabel:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
        officerNoteLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        officerNoteLabel:SetText("Officer Note:")
        officerNoteLabel:SetTextColor(0.5, 0.1, 0.1, 1)
        officerNoteLabel.isMemberDetails = true
        yOffset = yOffset - 15
        
        local officerNoteText = detailPanel:CreateFontString(nil, "OVERLAY")
        officerNoteText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, yOffset)
        officerNoteText:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -10, yOffset)
        officerNoteText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        officerNoteText:SetText(memberData.officerNote)
        officerNoteText:SetTextColor(0, 0, 0, 1)
        officerNoteText:SetJustifyH("LEFT")
        officerNoteText:SetWordWrap(true)
        officerNoteText.isMemberDetails = true
    end
    
    WoW95:Debug("Member details updated successfully")
end

function GuildWindow:PopulateAdvancedMemberList(scrollChild)
    WoW95:Debug("Populating advanced member list...")
    
    -- Debug class colors availability
    if RAID_CLASS_COLORS then
        WoW95:Debug("RAID_CLASS_COLORS is available")
        -- Test with a common class
        if RAID_CLASS_COLORS["WARRIOR"] then
            local testColor = RAID_CLASS_COLORS["WARRIOR"]
            WoW95:Debug("WARRIOR color test: r=" .. testColor.r .. " g=" .. testColor.g .. " b=" .. testColor.b)
        end
    else
        WoW95:Debug("ERROR: RAID_CLASS_COLORS is not available!")
    end
    
    -- Clear existing entries first
    local children = {scrollChild:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yOffset = -5
    local memberCount = 0
    
    -- Get guild member data
    if IsInGuild() then
        -- Debug available APIs
        WoW95:Debug("=== Guild API Debug ===")
        WoW95:Debug("C_GuildInfo exists: " .. tostring(C_GuildInfo ~= nil))
        if C_GuildInfo then
            WoW95:Debug("C_GuildInfo.GuildRoster exists: " .. tostring(C_GuildInfo.GuildRoster ~= nil))
        end
        WoW95:Debug("GuildRoster exists: " .. tostring(GuildRoster ~= nil))
        WoW95:Debug("GetNumGuildMembers exists: " .. tostring(GetNumGuildMembers ~= nil))
        WoW95:Debug("GetGuildRosterInfo exists: " .. tostring(GetGuildRosterInfo ~= nil))
        
        -- Request roster update - try multiple approaches
        local rosterSuccess = false
        
        -- Try C_GuildInfo first (modern retail)
        if C_GuildInfo and C_GuildInfo.GuildRoster then
            WoW95:Debug("Using C_GuildInfo.GuildRoster()")
            pcall(C_GuildInfo.GuildRoster)
            rosterSuccess = true
        end
        
        -- Try global GuildRoster function
        if not rosterSuccess and _G["GuildRoster"] then
            WoW95:Debug("Using global GuildRoster()")
            pcall(_G["GuildRoster"])
            rosterSuccess = true
        end
        
        -- Try alternative guild roster request
        if not rosterSuccess then
            WoW95:Debug("Trying alternative roster request methods...")
            -- Force a guild roster update by checking permissions
            pcall(CanGuildInvite)
        end
        
        local numMembers = GetNumGuildMembers() or 0
        WoW95:Debug("Found " .. numMembers .. " guild members")
        
        for i = 1, numMembers do
            local name, rank, _, level, class, _, note, officerNote, online, status = GetGuildRosterInfo(i)
            
            if name and (self.FILTER_SETTINGS.showOffline or online) then
                memberCount = memberCount + 1
                
                -- Create member entry frame
                local memberFrame = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
                memberFrame:SetSize(scrollChild:GetWidth() - 10, 20)
                memberFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
                
                memberFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 8,
                    edgeSize = 1,
                    insets = {left = 1, right = 1, top = 1, bottom = 1}
                })
                
                -- Color background based on class color
                -- Normalize class name (ensure uppercase) and handle Death Knight variations
                local normalizedClass = class and string.upper(class) or "UNKNOWN"
                
                -- Handle Death Knight variations
                if normalizedClass == "DEATH KNIGHT" or normalizedClass == "DEATHKNIGHT" then
                    normalizedClass = "DEATHKNIGHT"
                end
                
                local classColor = RAID_CLASS_COLORS[normalizedClass]
                
                -- Fallback for Death Knight if not found
                if not classColor and (class and string.upper(class):find("DEATH")) then
                    -- Manual Death Knight color (dark red/purple)
                    classColor = {r = 0.77, g = 0.12, b = 0.23}  -- Classic DK color
                    WoW95:Debug("Using manual Death Knight color for: " .. name)
                end
                
                WoW95:Debug("Member: " .. name .. ", Class: " .. tostring(class) .. ", Normalized: " .. normalizedClass .. ", Has Color: " .. tostring(classColor ~= nil))
                
                if classColor then
                    if online then
                        -- Light class color background for online members
                        local alpha = 0.3 -- Light transparency
                        memberFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        WoW95:Debug("Applied online class color: r=" .. classColor.r .. " g=" .. classColor.g .. " b=" .. classColor.b .. " a=" .. alpha)
                    else
                        -- Very light class color background for offline members
                        local alpha = 0.15 -- Very light transparency
                        memberFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        WoW95:Debug("Applied offline class color: r=" .. classColor.r .. " g=" .. classColor.g .. " b=" .. classColor.b .. " a=" .. alpha)
                    end
                else
                    WoW95:Debug("No class color found for " .. normalizedClass .. ", using fallback")
                    -- Fallback to original colors if class color not found
                    if online then
                        memberFrame:SetBackdropColor(0.95, 1, 0.95, 1) -- Light green for online
                    else
                        memberFrame:SetBackdropColor(0.95, 0.95, 0.95, 1) -- Gray for offline
                    end
                end
                memberFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                
                -- Member name with class color
                local nameText = memberFrame:CreateFontString(nil, "OVERLAY")
                nameText:SetPoint("LEFT", memberFrame, "LEFT", 5, 0)
                nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                nameText:SetText(name)
                
                -- Get class color - use actual WoW class colors
                local classColor = RAID_CLASS_COLORS[class]
                
                if classColor then
                    if online then
                        -- Use full class color for online members
                        nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                    else
                        -- Slightly dimmed for offline members but still recognizable
                        nameText:SetTextColor(classColor.r * 0.7, classColor.g * 0.7, classColor.b * 0.7, 1)
                    end
                else
                    -- Debug only if class color not found
                    WoW95:Debug("No class color found for class: " .. (class or "nil") .. " for player " .. name)
                    nameText:SetTextColor(0, 0, 0, 1) -- Black fallback
                end
                
                -- Level and class
                local levelText = memberFrame:CreateFontString(nil, "OVERLAY")
                levelText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
                levelText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                levelText:SetText("(" .. level .. " " .. class .. ")")
                levelText:SetTextColor(0.3, 0.3, 0.3, 1)
                
                -- Guild rank
                local rankText = memberFrame:CreateFontString(nil, "OVERLAY")
                rankText:SetPoint("RIGHT", memberFrame, "RIGHT", -5, 0)
                rankText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                rankText:SetText(rank)
                rankText:SetTextColor(0.1, 0.1, 0.5, 1)
                
                -- Member selection functionality
                memberFrame:EnableMouse(true)
                memberFrame:SetScript("OnClick", function()
                    self:SelectMember({
                        name = name,
                        rank = rank,
                        level = level,
                        class = class,
                        online = online,
                        note = note,
                        officerNote = officerNote
                    })
                    
                    -- Update selection visual
                    self:UpdateMemberSelection(memberFrame)
                end)
                
                -- Hover effects with class colors
                memberFrame:SetScript("OnEnter", function(self)
                    local classColor = RAID_CLASS_COLORS[normalizedClass]
                    if classColor then
                        if online then
                            -- Slightly more saturated class color on hover
                            local alpha = 0.5
                            self:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        else
                            -- Slightly more visible for offline members on hover
                            local alpha = 0.25
                            self:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        end
                    else
                        -- Fallback hover colors
                        if online then
                            self:SetBackdropColor(0.85, 0.95, 0.85, 1)
                        else
                            self:SetBackdropColor(0.85, 0.85, 0.85, 1)
                        end
                    end
                end)
                
                memberFrame:SetScript("OnLeave", function(self)
                    local classColor = RAID_CLASS_COLORS[normalizedClass]
                    if classColor then
                        if online then
                            -- Return to normal class color transparency
                            local alpha = 0.3
                            self:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        else
                            -- Return to normal offline transparency
                            local alpha = 0.15
                            self:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        end
                    else
                        -- Fallback to original colors
                        if online then
                            self:SetBackdropColor(0.95, 1, 0.95, 1)
                        else
                            self:SetBackdropColor(0.95, 0.95, 0.95, 1)
                        end
                    end
                end)
                
                yOffset = yOffset - 20
                
                -- Limit display to prevent performance issues
                if memberCount >= 50 then break end
            end
        end
    else
        -- Not in guild
        local noGuildText = scrollChild:CreateFontString(nil, "OVERLAY")
        noGuildText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        noGuildText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        noGuildText:SetText("Not in a guild")
        noGuildText:SetTextColor(0.5, 0.5, 0.5, 1)
        memberCount = 0
    end
    
    -- Set scroll child height
    local contentHeight = math.max(100, math.abs(yOffset) + 20)
    scrollChild:SetHeight(contentHeight)
    
    WoW95:Debug("Advanced member list populated with " .. memberCount .. " members")
end

function GuildWindow:CreateMemberDetailsPanel(parent)
    WoW95:Debug("Creating member details panel...")
    
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", parent, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    title:SetText("Member Details")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholder = parent:CreateFontString(nil, "OVERLAY")
    placeholder:SetPoint("CENTER", parent, "CENTER", 0, 0)
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholder:SetText("Select a member from the list\nto view their details")
    placeholder:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholder:SetJustifyH("CENTER")
end

function GuildWindow:SwitchToTab(programWindow, tabId)
    WoW95:Debug("Switching to guild tab: " .. tabId)
    
    -- Hide all content frames
    for _, content in pairs(programWindow.tabContent) do
        content:Hide()
    end
    
    -- Update tab appearance
    for id, tab in pairs(programWindow.tabs) do
        if id == tabId then
            tab:SetBackdropColor(1, 1, 1, 1) -- White for active tab
            tab:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        else
            tab:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Gray for inactive tabs
            tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end
    
    -- Show and create content for active tab
    local activeContent = programWindow.tabContent[tabId]
    if activeContent then
        activeContent:Show()
        programWindow.currentTab = tabId
        
        -- Create content if not already created
        if tabId == "roster" and not activeContent.contentCreated then
            self:CreateGuildRosterTab(programWindow)
        elseif tabId == "info" and not activeContent.contentCreated then
            self:CreateGuildInfoTab(programWindow)
        elseif tabId == "news" and not activeContent.contentCreated then
            self:CreateGuildNewsTab(programWindow)
        elseif tabId == "rewards" and not activeContent.contentCreated then
            self:CreateGuildRewardsTab(programWindow)
        elseif tabId == "perks" and not activeContent.contentCreated then
            self:CreateGuildPerksTab(programWindow)
        end
    end
    
    WoW95:Debug("Switched to guild tab: " .. tabId)
end

function GuildWindow:CreateGuildRosterTab(programWindow)
    local content = programWindow.tabContent["roster"]
    if not content then return end
    
    WoW95:Debug("Creating Guild Roster tab content")
    
    -- Check if player is in a guild
    local guildName = GetGuildInfo("player")
    
    if not guildName then
        -- Player is not in a guild - show recruitment message
        self:CreateNoGuildMessage(content)
    else
        -- Player is in a guild - show comprehensive roster
        self:CreateAdvancedGuildRoster(content)
    end
    
    -- Mark content as created
    content.contentCreated = true
    
    WoW95:Debug("Guild Roster tab content created")
end

function GuildWindow:CreateNoGuildMessage(parent)
    local noGuildFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    noGuildFrame:SetSize(600, 400)
    noGuildFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    
    noGuildFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    noGuildFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
    noGuildFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Guild recruitment title
    local title = noGuildFrame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", noGuildFrame, "TOP", 0, -20)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    title:SetText("Guild Management")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    -- Message
    local message = noGuildFrame:CreateFontString(nil, "OVERLAY")
    message:SetPoint("TOP", title, "BOTTOM", 0, -30)
    message:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    message:SetText("You are not currently in a guild.\n\nJoin a guild to access:\n• Member roster and management\n• Guild bank and permissions\n• Achievements and rewards\n• Event scheduling\n• Guild chat and communications")
    message:SetTextColor(0, 0, 0, 1)
    message:SetJustifyH("CENTER")
    
    -- Action buttons
    local findGuildBtn = WoW95:CreateButton("FindGuildBtn", noGuildFrame, 150, 30, "Find a Guild")
    findGuildBtn:SetPoint("TOP", message, "BOTTOM", -80, -40)
    findGuildBtn:SetScript("OnClick", function()
        if GuildFinderFrame then
            ShowUIPanel(GuildFinderFrame)
        else
            WoW95:Print("Guild Finder not available")
        end
    end)
    
    local createGuildBtn = WoW95:CreateButton("CreateGuildBtn", noGuildFrame, 150, 30, "Create Guild")
    createGuildBtn:SetPoint("TOP", message, "BOTTOM", 80, -40)
    createGuildBtn:SetScript("OnClick", function()
        if GuildRegistrarFrame then
            ShowUIPanel(GuildRegistrarFrame)
        else
            WoW95:Print("Visit a Guild Master NPC to create a guild")
        end
    end)
end

function GuildWindow:CreateAdvancedGuildRoster(parent)
    -- Create three-panel layout: filters/controls, member list, member details
    
    -- Control panel (top section)
    local controlPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    controlPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    controlPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -8)
    controlPanel:SetHeight(80)
    
    controlPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    controlPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    controlPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    self:CreateGuildControls(controlPanel)
    
    -- Member list panel (left side)
    local memberPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    memberPanel:SetPoint("TOPLEFT", controlPanel, "BOTTOMLEFT", 0, -5)
    memberPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
    memberPanel:SetWidth(400)
    
    memberPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    memberPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    memberPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    self:CreateAdvancedMemberList(memberPanel)
    
    -- Member details panel (right side)
    local detailPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    detailPanel:SetPoint("TOPLEFT", memberPanel, "TOPRIGHT", 5, 0)
    detailPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    
    detailPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    detailPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    detailPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    self:CreateMemberDetailsPanel(detailPanel)
    
    -- Store references
    parent.controlPanel = controlPanel
    parent.memberPanel = memberPanel
    parent.detailPanel = detailPanel
end

function GuildWindow:CreateGuildControls(parent)
    local xOffset = 8
    
    -- Always available: Refresh button
    local refreshBtn = WoW95:CreateButton("RefreshRosterBtn", parent, 80, 20, "Refresh")
    refreshBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
    refreshBtn:SetScript("OnClick", function()
        -- Request roster refresh using available APIs
        local refreshed = false
        
        if C_GuildInfo and C_GuildInfo.GuildRoster then
            pcall(C_GuildInfo.GuildRoster)
            refreshed = true
        elseif _G["GuildRoster"] then
            pcall(_G["GuildRoster"])
            refreshed = true
        end
        
        if refreshed then
            WoW95:Print("Guild roster refresh requested...")
        else
            WoW95:Print("Refreshing guild roster display...")
        end
        
        -- Delay refresh to allow API call to complete
        C_Timer.After(0.5, function()
            self:RefreshMemberList()
        end)
    end)
    xOffset = xOffset + 85
    
    -- Get current window to check permissions
    local guildWindow = parent:GetParent():GetParent() -- Navigate up to main window
    
    -- Officer-only buttons based on permissions
    if guildWindow.canInvite then
        local inviteBtn = WoW95:CreateButton("InviteBtn", parent, 80, 20, "Invite")
        inviteBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
        inviteBtn:SetScript("OnClick", function()
            StaticPopup_Show("GUILD_INVITE")
        end)
        xOffset = xOffset + 85
    end
    
    if guildWindow.canPromote then
        local promoteBtn = WoW95:CreateButton("PromoteBtn", parent, 80, 20, "Promote")
        promoteBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
        promoteBtn:SetScript("OnClick", function()
            if self.SELECTED_MEMBER and self.SELECTED_MEMBER.name then
                -- Use modern retail API for guild promotion
                if C_GuildInfo and C_GuildInfo.PromoteGuildMember then
                    C_GuildInfo.PromoteGuildMember(self.SELECTED_MEMBER.name)
                elseif GuildPromote then
                    GuildPromote(self.SELECTED_MEMBER.name)
                end
                WoW95:Print("Promoting " .. self.SELECTED_MEMBER.name)
                C_Timer.After(1, function() self:RefreshMemberList() end)
            else
                WoW95:Print("Please select a member to promote")
            end
        end)
        xOffset = xOffset + 85
        
        local demoteBtn = WoW95:CreateButton("DemoteBtn", parent, 80, 20, "Demote")
        demoteBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
        demoteBtn:SetScript("OnClick", function()
            if self.SELECTED_MEMBER and self.SELECTED_MEMBER.name then
                -- Use modern retail API for guild demotion
                if C_GuildInfo and C_GuildInfo.DemoteGuildMember then
                    C_GuildInfo.DemoteGuildMember(self.SELECTED_MEMBER.name)
                elseif GuildDemote then
                    GuildDemote(self.SELECTED_MEMBER.name)
                end
                WoW95:Print("Demoting " .. self.SELECTED_MEMBER.name)
                C_Timer.After(1, function() self:RefreshMemberList() end)
            else
                WoW95:Print("Please select a member to demote")
            end
        end)
        xOffset = xOffset + 85
    end
    
    if guildWindow.canRemove then
        local removeBtn = WoW95:CreateButton("RemoveBtn", parent, 80, 20, "Remove")
        removeBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
        removeBtn:SetScript("OnClick", function()
            if self.SELECTED_MEMBER and self.SELECTED_MEMBER.name then
                StaticPopup_Show("GUILD_UNINVITE", self.SELECTED_MEMBER.name, nil, self.SELECTED_MEMBER.name)
            else
                WoW95:Print("Please select a member to remove")
            end
        end)
        xOffset = xOffset + 85
    end
    
    -- Officer Notes button (for officers)
    if guildWindow.isOfficer then
        local notesBtn = WoW95:CreateButton("NotesBtn", parent, 80, 20, "Notes")
        notesBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
        notesBtn:SetScript("OnClick", function()
            if self.SELECTED_MEMBER and self.SELECTED_MEMBER.name then
                self:ShowOfficerNotesDialog(self.SELECTED_MEMBER.name)
            else
                WoW95:Print("Please select a member to edit notes")
            end
        end)
        xOffset = xOffset + 85
    end
    
    -- Filter row
    local filterLabel = parent:CreateFontString(nil, "OVERLAY")
    filterLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -35)
    filterLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    filterLabel:SetText("Filters:")
    filterLabel:SetTextColor(0, 0, 0, 1)
    
    -- Show offline checkbox
    local offlineCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    offlineCheck:SetSize(16, 16)
    offlineCheck:SetPoint("LEFT", filterLabel, "RIGHT", 10, 0)
    offlineCheck:SetChecked(self.FILTER_SETTINGS.showOffline)
    
    local offlineLabel = parent:CreateFontString(nil, "OVERLAY")
    offlineLabel:SetPoint("LEFT", offlineCheck, "RIGHT", 5, 0)
    offlineLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    offlineLabel:SetText("Show Offline")
    offlineLabel:SetTextColor(0, 0, 0, 1)
    
    offlineCheck:SetScript("OnClick", function()
        self.FILTER_SETTINGS.showOffline = offlineCheck:GetChecked()
        self:RefreshMemberList()
    end)
    
    -- Class filter dropdown placeholder (simplified for now)
    local classLabel = parent:CreateFontString(nil, "OVERLAY")
    classLabel:SetPoint("LEFT", offlineLabel, "RIGHT", 20, 0)
    classLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    classLabel:SetText("Class: All")
    classLabel:SetTextColor(0, 0, 0, 1)
    
    -- Member count display
    local countLabel = parent:CreateFontString(nil, "OVERLAY")
    countLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -35)
    countLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    countLabel:SetText("Members: 0/0")
    countLabel:SetTextColor(0.1, 0.1, 0.5, 1)
    
    parent.countLabel = countLabel
end

function GuildWindow:CreateAdvancedMemberList(parent)
    -- Member list title with sorting options
    local titleBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -5)
    titleBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -5)
    titleBar:SetHeight(25)
    
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.8, 0.8, 0.9, 1)
    titleBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Column headers (clickable for sorting)
    local nameHeader = titleBar:CreateFontString(nil, "OVERLAY")
    nameHeader:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    nameHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    nameHeader:SetText("Name")
    nameHeader:SetTextColor(0, 0, 0, 1)
    
    local levelHeader = titleBar:CreateFontString(nil, "OVERLAY")
    levelHeader:SetPoint("LEFT", nameHeader, "RIGHT", 120, 0)
    levelHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    levelHeader:SetText("Level")
    levelHeader:SetTextColor(0, 0, 0, 1)
    
    local classHeader = titleBar:CreateFontString(nil, "OVERLAY")
    classHeader:SetPoint("LEFT", levelHeader, "RIGHT", 40, 0)
    classHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    classHeader:SetText("Class")
    classHeader:SetTextColor(0, 0, 0, 1)
    
    local rankHeader = titleBar:CreateFontString(nil, "OVERLAY")
    rankHeader:SetPoint("LEFT", classHeader, "RIGHT", 60, 0)
    rankHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    rankHeader:SetText("Rank")
    rankHeader:SetTextColor(0, 0, 0, 1)
    
    -- Scrollable member list
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 5, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
        local currentScroll = self:GetVerticalScroll()
        local newScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * 20)))
        self:SetVerticalScroll(newScroll)
    end)
    
    parent.titleBar = titleBar
    parent.scrollFrame = scrollFrame
    parent.scrollChild = scrollChild
    
    -- Populate the list
    self:PopulateAdvancedMemberList(scrollChild)
end

function GuildWindow:CreateGuildMemberList(parent)
    -- Create guild member list panel
    local memberPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    memberPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    memberPanel:SetSize(450, parent:GetHeight() - 20)
    
    memberPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    memberPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    memberPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Guild member list title
    local memberTitle = memberPanel:CreateFontString(nil, "OVERLAY")
    memberTitle:SetPoint("TOP", memberPanel, "TOP", 0, -8)
    memberTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    memberTitle:SetText("Guild Members")
    memberTitle:SetTextColor(0.1, 0.1, 0.8, 1)
    
    -- Create scrollable member list
    local scrollFrame = CreateFrame("ScrollFrame", nil, memberPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", memberPanel, "TOPLEFT", 8, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", memberPanel, "BOTTOMRIGHT", -25, 8)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Populate guild member list
    self:PopulateGuildMemberList(scrollChild)
    
    parent.memberPanel = memberPanel
    parent.memberScrollFrame = scrollFrame
    parent.memberScrollChild = scrollChild
end

function GuildWindow:PopulateGuildMemberList(scrollChild)
    WoW95:Debug("Populating guild member list...")
    
    -- Clear existing entries
    local children = {scrollChild:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yOffset = -5
    local memberCount = 0
    
    -- Get guild member data
    if IsInGuild() then
        local numMembers = GetNumGuildMembers() or 0
        if GuildRoster then
            GuildRoster() -- Request updated roster  
        end
        
        for i = 1, numMembers do
            local name, rank, _, level, class, _, note, officerNote, online, status = GetGuildRosterInfo(i)
            
            if name then
                memberCount = memberCount + 1
                
                -- Create member entry frame
                local memberFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                memberFrame:SetSize(scrollChild:GetWidth() - 10, 20)
                memberFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
                
                memberFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 8,
                    edgeSize = 1,
                    insets = {left = 1, right = 1, top = 1, bottom = 1}
                })
                
                -- Color background based on class color
                -- Normalize class name (ensure uppercase) and handle Death Knight variations
                local normalizedClass = class and string.upper(class) or "UNKNOWN"
                
                -- Handle Death Knight variations
                if normalizedClass == "DEATH KNIGHT" or normalizedClass == "DEATHKNIGHT" then
                    normalizedClass = "DEATHKNIGHT"
                end
                
                local classColor = RAID_CLASS_COLORS[normalizedClass]
                
                -- Fallback for Death Knight if not found
                if not classColor and (class and string.upper(class):find("DEATH")) then
                    -- Manual Death Knight color (dark red/purple)
                    classColor = {r = 0.77, g = 0.12, b = 0.23}  -- Classic DK color
                    WoW95:Debug("Using manual Death Knight color for: " .. name)
                end
                
                WoW95:Debug("PopulateGuildMemberList - Member: " .. name .. ", Class: " .. tostring(class) .. ", Normalized: " .. normalizedClass .. ", Has Color: " .. tostring(classColor ~= nil))
                
                if classColor then
                    if online then
                        -- Light class color background for online members
                        local alpha = 0.3 -- Light transparency
                        memberFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        WoW95:Debug("PopulateGuildMemberList - Applied online class color: r=" .. classColor.r .. " g=" .. classColor.g .. " b=" .. classColor.b .. " a=" .. alpha)
                    else
                        -- Very light class color background for offline members
                        local alpha = 0.15 -- Very light transparency
                        memberFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, alpha)
                        WoW95:Debug("PopulateGuildMemberList - Applied offline class color: r=" .. classColor.r .. " g=" .. classColor.g .. " b=" .. classColor.b .. " a=" .. alpha)
                    end
                else
                    WoW95:Debug("PopulateGuildMemberList - No class color found for " .. normalizedClass .. ", using fallback")
                    -- Fallback to original colors if class color not found
                    if online then
                        memberFrame:SetBackdropColor(0.95, 1, 0.95, 1) -- Light green for online
                    else
                        memberFrame:SetBackdropColor(0.95, 0.95, 0.95, 1) -- Gray for offline
                    end
                end
                memberFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                
                -- Member name with class color
                local nameText = memberFrame:CreateFontString(nil, "OVERLAY")
                nameText:SetPoint("LEFT", memberFrame, "LEFT", 5, 0)
                nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                nameText:SetText(name)
                
                -- Get class color - use actual WoW class colors (secondary function)
                local classColor = RAID_CLASS_COLORS[class]
                
                if classColor then
                    if online then
                        -- Use full class color for online members
                        nameText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                    else
                        -- Slightly dimmed for offline members but still recognizable
                        nameText:SetTextColor(classColor.r * 0.7, classColor.g * 0.7, classColor.b * 0.7, 1)
                    end
                else
                    nameText:SetTextColor(0, 0, 0, 1) -- Black fallback
                end
                
                -- Level and class
                local levelText = memberFrame:CreateFontString(nil, "OVERLAY")
                levelText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
                levelText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                levelText:SetText("(" .. level .. " " .. class .. ")")
                levelText:SetTextColor(0.3, 0.3, 0.3, 1)
                
                -- Guild rank
                local rankText = memberFrame:CreateFontString(nil, "OVERLAY")
                rankText:SetPoint("RIGHT", memberFrame, "RIGHT", -5, 0)
                rankText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
                rankText:SetText(rank)
                rankText:SetTextColor(0.1, 0.1, 0.5, 1)
                
                yOffset = yOffset - 22
                
                -- Limit display to prevent performance issues
                if memberCount >= 50 then break end
            end
        end
    end
    
    -- Set scroll child height
    local contentHeight = math.abs(yOffset) + 20
    scrollChild:SetHeight(contentHeight)
    
    WoW95:Debug("Guild member list populated with " .. memberCount .. " members")
end

function GuildWindow:CreateGuildInfoPanel(parent)
    -- Create guild info panel on the right
    local infoPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    infoPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    infoPanel:SetSize(320, parent:GetHeight() - 20)
    
    infoPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    infoPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    infoPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Guild info title
    local infoTitle = infoPanel:CreateFontString(nil, "OVERLAY")
    infoTitle:SetPoint("TOP", infoPanel, "TOP", 0, -8)
    infoTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    infoTitle:SetText("Guild Information")
    infoTitle:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local yOffset = -35
    
    -- Guild name
    local guildName = GetGuildInfo("player")
    if guildName then
        local nameLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        nameLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, yOffset)
        nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        nameLabel:SetText("Guild: " .. guildName)
        nameLabel:SetTextColor(0.1, 0.1, 0.5, 1)
        yOffset = yOffset - 25
    end
    
    -- Member count
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        local memberLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        memberLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, yOffset)
        memberLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        memberLabel:SetText("Members: " .. numMembers)
        memberLabel:SetTextColor(0, 0, 0, 1)
        yOffset = yOffset - 20
    end
    
    -- Guild MOTD
    local motd = GetGuildRosterMOTD()
    if motd and motd ~= "" then
        yOffset = yOffset - 10
        local motdLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        motdLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, yOffset)
        motdLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        motdLabel:SetText("Message of the Day:")
        motdLabel:SetTextColor(0.1, 0.1, 0.5, 1)
        yOffset = yOffset - 18
        
        local motdText = infoPanel:CreateFontString(nil, "OVERLAY")
        motdText:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, yOffset)
        motdText:SetPoint("TOPRIGHT", infoPanel, "TOPRIGHT", -10, yOffset)
        motdText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        motdText:SetText(motd)
        motdText:SetTextColor(0, 0, 0, 1)
        motdText:SetJustifyH("LEFT")
        motdText:SetWordWrap(true)
    end
    
    parent.infoPanel = infoPanel
end

function GuildWindow:CreateCommunitiesTab(programWindow)
    local content = programWindow.tabContent["communities"]
    if not content then return end
    
    WoW95:Debug("Creating Communities tab content")
    
    -- Communities placeholder
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetPoint("CENTER", content, "CENTER", 0, 50)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Communities")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholderText = content:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", content, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholderText:SetText("Communities feature coming soon!\n\nJoin Battle.net communities to chat\nwith friends across multiple games.")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholderText:SetJustifyH("CENTER")
    
    -- Mark content as created
    content.contentCreated = true
    
    WoW95:Debug("Communities tab content created")
end

function GuildWindow:CreateCalendarTab(programWindow)
    local content = programWindow.tabContent["calendar"]
    if not content then return end
    
    WoW95:Debug("Creating Calendar tab content")
    
    -- Calendar placeholder
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetPoint("CENTER", content, "CENTER", 0, 50)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Guild Calendar")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholderText = content:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", content, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholderText:SetText("Guild calendar feature coming soon!\n\nSchedule raids, events, and activities\nwith your guild members.")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholderText:SetJustifyH("CENTER")
    
    -- Open Calendar button
    local calendarBtn = WoW95:CreateButton("OpenCalendarBtn", content, 120, 30, "Open Calendar")
    calendarBtn:SetPoint("TOP", placeholderText, "BOTTOM", 0, -30)
    calendarBtn:SetScript("OnClick", function()
        -- Open Blizzard calendar
        if Calendar_Toggle then
            Calendar_Toggle()
        end
    end)
    
    -- Mark content as created
    content.contentCreated = true
    
    WoW95:Debug("Calendar tab content created")
end

function GuildWindow:CreateGuildInfoTab(programWindow)
    local content = programWindow.tabContent["info"]
    if not content then return end
    
    WoW95:Debug("Creating Guild Info tab content")
    
    -- Guild Information Panel
    local infoPanel = CreateFrame("Frame", nil, content, "BackdropTemplate")
    infoPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    infoPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
    infoPanel:SetHeight(200)
    
    infoPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    infoPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    infoPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local yOffset = -15
    
    -- Guild Name
    local guildName = GetGuildInfo("player")
    if guildName then
        local nameLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        nameLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 15, yOffset)
        nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
        nameLabel:SetText("Guild: " .. guildName)
        nameLabel:SetTextColor(0.1, 0.1, 0.8, 1)
        yOffset = yOffset - 25
        
        -- Member Count
        local numMembers = GetNumGuildMembers() or 0
        local memberLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        memberLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 15, yOffset)
        memberLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        memberLabel:SetText("Total Members: " .. numMembers)
        memberLabel:SetTextColor(0, 0, 0, 1)
        yOffset = yOffset - 20
        
        -- Guild Master
        if IsInGuild() then
            for i = 1, numMembers do
                local name, rank = GetGuildRosterInfo(i)
                if rank and rank:lower():find("guild master") or rank and rank:lower():find("leader") then
                    local masterLabel = infoPanel:CreateFontString(nil, "OVERLAY")
                    masterLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 15, yOffset)
                    masterLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                    masterLabel:SetText("Guild Master: " .. (name or "Unknown"))
                    masterLabel:SetTextColor(0, 0, 0, 1)
                    yOffset = yOffset - 20
                    break
                end
            end
        end
        
        -- Guild MOTD
        local motd = GetGuildRosterMOTD()
        if motd and motd ~= "" then
            yOffset = yOffset - 10
            local motdLabel = infoPanel:CreateFontString(nil, "OVERLAY")
            motdLabel:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 15, yOffset)
            motdLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            motdLabel:SetText("Message of the Day:")
            motdLabel:SetTextColor(0.1, 0.1, 0.5, 1)
            yOffset = yOffset - 18
            
            local motdText = infoPanel:CreateFontString(nil, "OVERLAY")
            motdText:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 15, yOffset)
            motdText:SetPoint("TOPRIGHT", infoPanel, "TOPRIGHT", -15, yOffset)
            motdText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            motdText:SetText(motd)
            motdText:SetTextColor(0, 0, 0, 1)
            motdText:SetJustifyH("LEFT")
            motdText:SetWordWrap(true)
        end
    else
        local noGuildLabel = infoPanel:CreateFontString(nil, "OVERLAY")
        noGuildLabel:SetPoint("CENTER", infoPanel, "CENTER", 0, 0)
        noGuildLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noGuildLabel:SetText("You are not in a guild")
        noGuildLabel:SetTextColor(0.5, 0.5, 0.5, 1)
    end
    
    content.contentCreated = true
    WoW95:Debug("Guild Info tab content created")
end

function GuildWindow:CreateGuildNewsTab(programWindow)
    local content = programWindow.tabContent["news"]
    if not content then return end
    
    WoW95:Debug("Creating Guild News tab content")
    
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetPoint("CENTER", content, "CENTER", 0, 50)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Guild News")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholderText = content:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", content, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholderText:SetText("Recent guild activities,\nachievements, and news\nwill be displayed here.")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholderText:SetJustifyH("CENTER")
    
    content.contentCreated = true
    WoW95:Debug("Guild News tab content created")
end

function GuildWindow:CreateGuildRewardsTab(programWindow)
    local content = programWindow.tabContent["rewards"]
    if not content then return end
    
    WoW95:Debug("Creating Guild Rewards tab content")
    
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetPoint("CENTER", content, "CENTER", 0, 50)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Guild Rewards")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholderText = content:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", content, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholderText:SetText("Guild achievements,\nrewards, and unlocks\nwill be displayed here.")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholderText:SetJustifyH("CENTER")
    
    content.contentCreated = true
    WoW95:Debug("Guild Rewards tab content created")
end

function GuildWindow:CreateGuildPerksTab(programWindow)
    local content = programWindow.tabContent["perks"]
    if not content then return end
    
    WoW95:Debug("Creating Guild Perks tab content")
    
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetPoint("CENTER", content, "CENTER", 0, 50)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    title:SetText("Guild Perks & Benefits")
    title:SetTextColor(0.1, 0.1, 0.8, 1)
    
    local placeholderText = content:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", content, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholderText:SetText("Guild perks, benefits,\nand member privileges\nwill be displayed here.")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholderText:SetJustifyH("CENTER")
    
    content.contentCreated = true
    WoW95:Debug("Guild Perks tab content created")
end

-- Debug command to test class colors
SLASH_WOW95GUILDTEST1 = "/wow95guildtest"
SlashCmdList["WOW95GUILDTEST"] = function(msg)
    WoW95:Print("=== Guild Window Debug Test ===")
    
    -- Test RAID_CLASS_COLORS availability
    if RAID_CLASS_COLORS then
        WoW95:Print("RAID_CLASS_COLORS is available!")
        local testClasses = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT", "SHAMAN", "MONK", "DEMONHUNTER", "EVOKER"}
        for _, class in ipairs(testClasses) do
            local color = RAID_CLASS_COLORS[class]
            if color then
                WoW95:Print(class .. " color: r=" .. string.format("%.2f", color.r) .. " g=" .. string.format("%.2f", color.g) .. " b=" .. string.format("%.2f", color.b))
            else
                WoW95:Print(class .. " color: NOT FOUND")
            end
        end
    else
        WoW95:Print("ERROR: RAID_CLASS_COLORS is not available!")
    end
    
    -- Test titleBar color
    WoW95:Print("Title bar color should be: " .. table.concat(WoW95.colors.titleBar, ", "))
    
    -- Check guild window title bar specifically
    local guildWindow = WoW95.WindowsCore:GetProgramWindow("GuildFrame") or WoW95.WindowsCore:GetProgramWindow("CommunitiesFrame")
    if guildWindow then
        WoW95:Print("Guild window found!")
        if guildWindow.titleBar then
            local r, g, b, a = guildWindow.titleBar:GetBackdropColor()
            WoW95:Print("Guild window title bar ACTUAL color: r=" .. string.format("%.2f", r) .. " g=" .. string.format("%.2f", g) .. " b=" .. string.format("%.2f", b) .. " a=" .. string.format("%.2f", a))
        else
            WoW95:Print("ERROR: Guild window has no titleBar!")
        end
    else
        WoW95:Print("No guild window currently open")
    end
    
    -- Guild info
    if IsInGuild() then
        local guildName = GetGuildInfo("player")
        local numMembers = GetNumGuildMembers() or 0
        WoW95:Print("Guild: " .. (guildName or "Unknown") .. ", Members: " .. numMembers)
        
        if numMembers > 0 then
            WoW95:Print("First 3 members:")
            for i = 1, math.min(3, numMembers) do
                local name, rank, _, level, class, _, note, officerNote, online = GetGuildRosterInfo(i)
                if name then
                    WoW95:Print("  " .. name .. " (" .. (class or "unknown") .. ") - " .. (online and "Online" or "Offline"))
                end
            end
        end
    else
        WoW95:Print("Not in a guild")
    end
end

-- Register the module
WoW95:RegisterModule("GuildWindow", GuildWindow)