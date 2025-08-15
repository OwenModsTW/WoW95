-- WoW95 Social Windows Module
-- Guild, Friends, Group Finder, and PvP windows with Windows 95 styling

local addonName, WoW95 = ...

local SocialWindows = {}
WoW95.SocialWindows = SocialWindows

-- Supported social frames
local SOCIAL_FRAMES = {
    ["GuildFrame"] = "CreateGuildWindow",
    ["CommunitiesFrame"] = "CreateGuildWindow",  -- Modern retail guild UI
    ["FriendsFrame"] = "CreateFriendsWindow", 
    ["LFGParentFrame"] = "CreateGroupFinderWindow",
    ["PVPUIFrame"] = "CreatePvPWindow"
}

function SocialWindows:CreateWindow(frameName, program)
    -- Check if we handle this frame type
    local createMethod = SOCIAL_FRAMES[frameName]
    if not createMethod or not self[createMethod] then
        WoW95:Debug("Unsupported social frame: " .. frameName)
        return nil
    end
    
    -- Don't create duplicate windows - show existing one if it exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug(frameName .. " window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    -- Call the appropriate creation method
    return self[createMethod](self, frameName, program)
end

function SocialWindows:CreateGuildWindow(frameName, program)
    WoW95:Debug("=== SocialWindows:CreateGuildWindow called ===")
    WoW95:Debug("Frame: " .. tostring(frameName))
    WoW95:Debug("Program: " .. tostring(program and program.name or "nil"))
    WoW95:Debug("GuildWindow module exists: " .. tostring(WoW95.GuildWindow ~= nil))
    WoW95:Debug("GuildWindow.CreateWindow exists: " .. tostring(WoW95.GuildWindow and WoW95.GuildWindow.CreateWindow ~= nil))
    
    -- Delegate to the comprehensive GuildWindow module
    if WoW95.GuildWindow and WoW95.GuildWindow.CreateWindow then
        WoW95:Debug("DELEGATING to GuildWindow module...")
        return WoW95.GuildWindow:CreateWindow(frameName, program)
    else
        WoW95:Debug("GuildWindow module not available, falling back to basic implementation")
        
        -- Fallback to basic implementation with blue title bar
        WoW95:Debug("Creating fallback guild window with WoW95:CreateWindow (should have blue title bar)")
        local guildWindow = WoW95:CreateWindow(
            "WoW95Guild", 
            UIParent, 
            program.window.width, 
            program.window.height, 
            program.window.title
        )
        WoW95:Debug("Fallback guild window created, checking title bar color...")
        
        -- Position window
        guildWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        
        -- Create main content area
        local contentArea = self:CreateContentArea(guildWindow)
        
        -- Create guild-specific content
        self:CreateGuildContent(guildWindow, contentArea)
        
        -- Finalize window setup
        return self:FinalizeWindow(guildWindow, frameName, program, contentArea)
    end
end

function SocialWindows:CreateFriendsWindow(frameName, program)
    WoW95:Debug("Creating Friends window: " .. frameName)
    
    -- Create the main friends window using the core window creation
    local friendsWindow = WoW95:CreateWindow(
        "WoW95Friends", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    friendsWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(friendsWindow)
    
    -- Create friends-specific content
    self:CreateFriendsContent(friendsWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(friendsWindow, frameName, program, contentArea)
end

function SocialWindows:CreateGroupFinderWindow(frameName, program)
    WoW95:Debug("Creating Group Finder window: " .. frameName)
    
    -- Create the main group finder window using the core window creation
    local groupFinderWindow = WoW95:CreateWindow(
        "WoW95GroupFinder", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    groupFinderWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(groupFinderWindow)
    
    -- Create group finder-specific content
    self:CreateGroupFinderContent(groupFinderWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(groupFinderWindow, frameName, program, contentArea)
end

function SocialWindows:CreatePvPWindow(frameName, program)
    WoW95:Debug("Creating PvP window: " .. frameName)
    
    -- Create the main PvP window using the core window creation
    local pvpWindow = WoW95:CreateWindow(
        "WoW95PvP", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    pvpWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area
    local contentArea = self:CreateContentArea(pvpWindow)
    
    -- Create PvP-specific content
    self:CreatePvPContent(pvpWindow, contentArea)
    
    -- Finalize window setup
    return self:FinalizeWindow(pvpWindow, frameName, program, contentArea)
end

function SocialWindows:CreateContentArea(window)
    -- Create main content area with Windows 95 styling
    local contentArea = CreateFrame("Frame", nil, window, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -30)
    contentArea:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -8, 8)
    
    -- Content area background
    contentArea:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    contentArea:SetBackdropColor(1, 1, 1, 1) -- White background
    contentArea:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    return contentArea
end

function SocialWindows:CreateGuildContent(guildWindow, contentArea)
    -- Guild info panel
    local guildInfoPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    guildInfoPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -10)
    guildInfoPanel:SetSize(contentArea:GetWidth() - 20, 80)
    
    guildInfoPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    guildInfoPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    guildInfoPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Guild name
    local guildName = guildInfoPanel:CreateFontString(nil, "OVERLAY")
    guildName:SetPoint("TOPLEFT", guildInfoPanel, "TOPLEFT", 10, -10)
    guildName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    guildName:SetText(GetGuildInfo("player") or "No Guild")
    guildName:SetTextColor(0, 0, 0, 1)
    
    -- Member count
    local numMembers = GetNumGuildMembers()
    local memberText = guildInfoPanel:CreateFontString(nil, "OVERLAY")
    memberText:SetPoint("TOPLEFT", guildName, "BOTTOMLEFT", 0, -5)
    memberText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    memberText:SetText("Members: " .. (numMembers or 0))
    memberText:SetTextColor(0, 0, 0, 1)
    
    -- Guild member list
    local memberListPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    memberListPanel:SetPoint("TOPLEFT", guildInfoPanel, "BOTTOMLEFT", 0, -10)
    memberListPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 10)
    
    memberListPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    memberListPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    memberListPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Member list title
    local listTitle = memberListPanel:CreateFontString(nil, "OVERLAY")
    listTitle:SetPoint("TOP", memberListPanel, "TOP", 0, -10)
    listTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    listTitle:SetText("Guild Members")
    listTitle:SetTextColor(0, 0, 0, 1)
    
    -- Placeholder for member list (would need proper guild API implementation)
    local placeholderText = memberListPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", memberListPanel, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("Guild member list\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Store references
    guildWindow.guildInfoPanel = guildInfoPanel
    guildWindow.memberListPanel = memberListPanel
    
    WoW95:Debug("Created guild content")
end

function SocialWindows:CreateFriendsContent(friendsWindow, contentArea)
    -- Friends list panel
    local friendsListPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    friendsListPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -10)
    friendsListPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 50)
    
    friendsListPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    friendsListPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    friendsListPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Friends list title
    local listTitle = friendsListPanel:CreateFontString(nil, "OVERLAY")
    listTitle:SetPoint("TOP", friendsListPanel, "TOP", 0, -10)
    listTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    listTitle:SetText("Friends & Contacts")
    listTitle:SetTextColor(0, 0, 0, 1)
    
    -- Get friends info
    local numFriends = C_FriendList.GetNumFriends()
    local friendsText = friendsListPanel:CreateFontString(nil, "OVERLAY")
    friendsText:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", -50, -10)
    friendsText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    friendsText:SetText("Friends Online: " .. numFriends)
    friendsText:SetTextColor(0, 0, 0, 1)
    
    -- Placeholder for friends list
    local placeholderText = friendsListPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", friendsListPanel, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("Friends list\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Control buttons
    local buttonPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    buttonPanel:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 10, 10)
    buttonPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 10)
    buttonPanel:SetHeight(35)
    
    buttonPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    buttonPanel:SetBackdropColor(0.75, 0.75, 0.75, 1)
    buttonPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Add Friend button
    local addFriendBtn = WoW95:CreateButton("AddFriendBtn", buttonPanel, 80, 25, "Add Friend")
    addFriendBtn:SetPoint("LEFT", buttonPanel, "LEFT", 10, 0)
    addFriendBtn:SetScript("OnClick", function()
        WoW95:Print("Add Friend functionality (placeholder)")
    end)
    
    -- Store references
    friendsWindow.friendsListPanel = friendsListPanel
    friendsWindow.buttonPanel = buttonPanel
    
    WoW95:Debug("Created friends content")
end

function SocialWindows:CreateGroupFinderContent(groupFinderWindow, contentArea)
    -- Group finder main panel
    local finderPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    finderPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -10)
    finderPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 10)
    
    finderPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    finderPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    finderPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Group finder title
    local title = finderPanel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", finderPanel, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetText("Group Finder")
    title:SetTextColor(0, 0, 0, 1)
    
    -- Placeholder content
    local placeholderText = finderPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", finderPanel, "CENTER", 0, 0)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("Group Finder\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Store references
    groupFinderWindow.finderPanel = finderPanel
    
    WoW95:Debug("Created group finder content")
end

function SocialWindows:CreatePvPContent(pvpWindow, contentArea)
    -- PvP main panel
    local pvpPanel = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    pvpPanel:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 10, -10)
    pvpPanel:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -10, 10)
    
    pvpPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    pvpPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    pvpPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- PvP title
    local title = pvpPanel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", pvpPanel, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetText("Player vs Player")
    title:SetTextColor(0, 0, 0, 1)
    
    -- Honor info
    local honorPanel = CreateFrame("Frame", nil, pvpPanel, "BackdropTemplate")
    honorPanel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -100, -20)
    honorPanel:SetSize(200, 60)
    
    honorPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    honorPanel:SetBackdropColor(0.9, 0.9, 0.9, 1)
    honorPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Honor text
    local honorText = honorPanel:CreateFontString(nil, "OVERLAY")
    honorText:SetPoint("TOP", honorPanel, "TOP", 0, -5)
    honorText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    honorText:SetText("Honor Points")
    honorText:SetTextColor(0, 0, 0, 1)
    
    local honorValue = honorPanel:CreateFontString(nil, "OVERLAY")
    honorValue:SetPoint("CENTER", honorPanel, "CENTER", 0, -5)
    honorValue:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    honorValue:SetText("0") -- Placeholder
    honorValue:SetTextColor(0.8, 0, 0, 1)
    
    -- Placeholder for PvP content
    local placeholderText = pvpPanel:CreateFontString(nil, "OVERLAY")
    placeholderText:SetPoint("CENTER", pvpPanel, "CENTER", 0, -50)
    placeholderText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    placeholderText:SetText("PvP Interface\n(Implementation in progress)")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    
    -- Store references
    pvpWindow.pvpPanel = pvpPanel
    pvpWindow.honorPanel = honorPanel
    
    WoW95:Debug("Created PvP content")
end

function SocialWindows:FinalizeWindow(window, frameName, program, contentArea)
    -- Store references
    window.contentArea = contentArea
    window.programName = program.name
    window.frameName = frameName
    window.isWoW95Window = true
    window.isProgramWindow = true
    
    -- Store reference in WindowsCore
    WoW95.WindowsCore:StoreProgramWindow(frameName, window)
    
    -- Add a custom hide script to ensure proper cleanup when closed by other means
    window:HookScript("OnHide", function()
        WoW95:Debug(frameName .. " window hidden, cleaning up tracking")
        WoW95.WindowsCore:RemoveProgramWindow(frameName)
        -- Ensure the Blizzard frame is also hidden to prevent state mismatch
        local blizzardFrame = _G[frameName]
        if blizzardFrame and blizzardFrame:IsShown() then
            blizzardFrame:Hide()
        end
    end)
    
    -- Show the window
    window:Show()
    
    -- Notify taskbar
    WoW95:OnWindowOpened(window)
    
    WoW95:Print(program.name .. " window created successfully!")
    return window
end

-- Register the module
WoW95:RegisterModule("SocialWindows", SocialWindows)