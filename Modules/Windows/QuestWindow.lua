-- WoW95 Quest Window Module
-- Complete quest log functionality with Windows 95 styling

local addonName, WoW95 = ...

local QuestWindow = {}
WoW95.QuestWindow = QuestWindow

function QuestWindow:CreateWindow(frameName, program)
    -- Don't create duplicate windows - show existing one if it exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug("Quest Log window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    WoW95:Debug("Creating Quest Log window: " .. frameName)
    
    -- Create the main quest log window using the core window creation
    local questLogWindow = WoW95:CreateWindow(
        "WoW95QuestLog", 
        UIParent, 
        program.window.width, 
        program.window.height, 
        program.window.title
    )
    
    -- Position window
    questLogWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create main content area with Windows 95 styling
    local contentArea = CreateFrame("Frame", nil, questLogWindow, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", questLogWindow, "TOPLEFT", 8, -30)
    contentArea:SetPoint("BOTTOMRIGHT", questLogWindow, "BOTTOMRIGHT", -8, 8)
    
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
    
    -- Create quest log components
    self:CreateQuestList(questLogWindow, contentArea)
    self:CreateQuestDetails(questLogWindow, contentArea)
    self:CreateQuestControls(questLogWindow, contentArea)
    
    -- Store references
    questLogWindow.contentArea = contentArea
    questLogWindow.programName = program.name
    questLogWindow.frameName = frameName
    questLogWindow.isWoW95Window = true
    questLogWindow.isProgramWindow = true
    questLogWindow.selectedQuest = nil
    
    -- Load initial quest data
    self:RefreshQuestList(questLogWindow)
    
    -- Store reference in WindowsCore
    WoW95.WindowsCore:StoreProgramWindow(frameName, questLogWindow)
    
    -- Add a custom hide script to ensure proper cleanup when closed by other means
    questLogWindow:HookScript("OnHide", function()
        WoW95:Debug("Quest Log window hidden, cleaning up tracking")
        WoW95.WindowsCore:RemoveProgramWindow(frameName)
        -- Ensure the Blizzard frame is also hidden to prevent state mismatch
        local blizzardFrame = _G[frameName]
        if blizzardFrame and blizzardFrame:IsShown() then
            blizzardFrame:Hide()
        end
    end)
    
    -- Show the window
    questLogWindow:Show()
    
    -- Notify taskbar
    WoW95:OnWindowOpened(questLogWindow)
    
    WoW95:Print("Quest Log window created successfully!")
    return questLogWindow
end

function QuestWindow:CreateQuestList(questLogWindow, parent)
    -- Create quest list panel (left side)
    local questListPanel = CreateFrame("Frame", "WoW95QuestList", parent, "BackdropTemplate")
    questListPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    questListPanel:SetSize(250, parent:GetHeight() - 50)
    
    -- Quest list background
    questListPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    questListPanel:SetBackdropColor(0.95, 0.95, 0.95, 1)
    questListPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Quest list title
    local listTitle = questListPanel:CreateFontString(nil, "OVERLAY")
    listTitle:SetPoint("TOP", questListPanel, "TOP", 0, -10)
    listTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    listTitle:SetText("Quest Log")
    listTitle:SetTextColor(0, 0, 0, 1)
    
    -- Create scrollable quest list
    local questScrollFrame = CreateFrame("ScrollFrame", "WoW95QuestScrollFrame", questListPanel, "UIPanelScrollFrameTemplate")
    questScrollFrame:SetPoint("TOPLEFT", questListPanel, "TOPLEFT", 5, -25)
    questScrollFrame:SetPoint("BOTTOMRIGHT", questListPanel, "BOTTOMRIGHT", -25, 5)
    
    local questScrollChild = CreateFrame("Frame", nil, questScrollFrame)
    questScrollChild:SetSize(questScrollFrame:GetWidth(), 1)
    questScrollFrame:SetScrollChild(questScrollChild)
    
    -- Store references
    questLogWindow.questListPanel = questListPanel
    questLogWindow.questScrollFrame = questScrollFrame
    questLogWindow.questScrollChild = questScrollChild
    questLogWindow.questButtons = {}
    
    WoW95:Debug("Created quest list panel")
end

function QuestWindow:CreateQuestDetails(questLogWindow, parent)
    -- Create quest details panel (right side)
    local questDetailsPanel = CreateFrame("Frame", "WoW95QuestDetails", parent, "BackdropTemplate")
    questDetailsPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    questDetailsPanel:SetSize(parent:GetWidth() - 280, parent:GetHeight() - 50)
    
    -- Quest details background
    questDetailsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    questDetailsPanel:SetBackdropColor(0.98, 0.98, 0.98, 1)
    questDetailsPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Quest details title
    local detailsTitle = questDetailsPanel:CreateFontString(nil, "OVERLAY")
    detailsTitle:SetPoint("TOP", questDetailsPanel, "TOP", 0, -10)
    detailsTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    detailsTitle:SetText("Select a Quest")
    detailsTitle:SetTextColor(0, 0, 0, 1)
    
    -- Create scrollable quest details
    local detailsScrollFrame = CreateFrame("ScrollFrame", "WoW95QuestDetailsScrollFrame", questDetailsPanel, "UIPanelScrollFrameTemplate")
    detailsScrollFrame:SetPoint("TOPLEFT", questDetailsPanel, "TOPLEFT", 5, -30)
    detailsScrollFrame:SetPoint("BOTTOMRIGHT", questDetailsPanel, "BOTTOMRIGHT", -25, 40)
    
    local detailsScrollChild = CreateFrame("Frame", nil, detailsScrollFrame)
    detailsScrollChild:SetSize(detailsScrollFrame:GetWidth(), 1)
    detailsScrollFrame:SetScrollChild(detailsScrollChild)
    
    -- Store references
    questLogWindow.questDetailsPanel = questDetailsPanel
    questLogWindow.detailsTitle = detailsTitle
    questLogWindow.detailsScrollFrame = detailsScrollFrame
    questLogWindow.detailsScrollChild = detailsScrollChild
    
    WoW95:Debug("Created quest details panel")
end

function QuestWindow:CreateQuestControls(questLogWindow, parent)
    -- Create control buttons (bottom)
    local controlPanel = CreateFrame("Frame", "WoW95QuestControls", parent, "BackdropTemplate")
    controlPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 5)
    controlPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 5)
    controlPanel:SetHeight(30)
    
    -- Control panel background
    controlPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    controlPanel:SetBackdropColor(0.75, 0.75, 0.75, 1)
    controlPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Track Quest button
    local trackBtn = WoW95:CreateButton("TrackQuestBtn", controlPanel, 100, 22, "Track Quest")
    trackBtn:SetPoint("LEFT", controlPanel, "LEFT", 10, 0)
    trackBtn:SetScript("OnClick", function()
        self:TrackSelectedQuest(questLogWindow)
    end)
    
    -- Abandon Quest button
    local abandonBtn = WoW95:CreateButton("AbandonQuestBtn", controlPanel, 100, 22, "Abandon Quest")
    abandonBtn:SetPoint("LEFT", trackBtn, "RIGHT", 10, 0)
    abandonBtn:SetScript("OnClick", function()
        self:AbandonSelectedQuest(questLogWindow)
    end)
    
    -- Share Quest button
    local shareBtn = WoW95:CreateButton("ShareQuestBtn", controlPanel, 100, 22, "Share Quest")
    shareBtn:SetPoint("LEFT", abandonBtn, "RIGHT", 10, 0)
    shareBtn:SetScript("OnClick", function()
        self:ShareSelectedQuest(questLogWindow)
    end)
    
    -- Refresh button
    local refreshBtn = WoW95:CreateButton("RefreshQuestBtn", controlPanel, 80, 22, "Refresh")
    refreshBtn:SetPoint("RIGHT", controlPanel, "RIGHT", -10, 0)
    refreshBtn:SetScript("OnClick", function()
        self:RefreshQuestList(questLogWindow)
    end)
    
    -- Store references
    questLogWindow.controlPanel = controlPanel
    questLogWindow.trackBtn = trackBtn
    questLogWindow.abandonBtn = abandonBtn
    questLogWindow.shareBtn = shareBtn
    questLogWindow.refreshBtn = refreshBtn
    
    WoW95:Debug("Created quest controls")
end

function QuestWindow:RefreshQuestList(questLogWindow)
    WoW95:Debug("Refreshing quest list")
    
    -- Clear existing quest buttons
    for _, button in pairs(questLogWindow.questButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    questLogWindow.questButtons = {}
    
    -- Get all quests
    local numEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
    local yOffset = 0
    
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader then
            self:CreateQuestButton(questLogWindow, info.questID, info.title, info.level, info.isComplete, yOffset)
            yOffset = yOffset + 25
        elseif info and info.isHeader then
            self:CreateQuestHeader(questLogWindow, info.title, yOffset)
            yOffset = yOffset + 20
        end
    end
    
    -- Update scroll child height
    questLogWindow.questScrollChild:SetHeight(math.max(yOffset, questLogWindow.questScrollFrame:GetHeight()))
    
    WoW95:Debug("Quest list refreshed with " .. numQuests .. " quests")
end

function QuestWindow:CreateQuestButton(questLogWindow, questID, title, level, isComplete, yOffset)
    local button = CreateFrame("Button", "WoW95Quest" .. questID, questLogWindow.questScrollChild, "BackdropTemplate")
    button:SetSize(questLogWindow.questScrollChild:GetWidth() - 5, 20)
    button:SetPoint("TOPLEFT", questLogWindow.questScrollChild, "TOPLEFT", 5, -yOffset)
    
    -- Button backdrop
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    button:SetBackdropColor(0.9, 0.9, 0.9, 1)
    button:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
    
    -- Quest text
    local questText = button:CreateFontString(nil, "OVERLAY")
    questText:SetPoint("LEFT", button, "LEFT", 5, 0)
    questText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    questText:SetText(string.format("[%d] %s", level or 0, title or "Unknown Quest"))
    
    if isComplete then
        questText:SetTextColor(0, 0.8, 0, 1) -- Green for complete
    else
        questText:SetTextColor(0, 0, 0, 1) -- Black for incomplete
    end
    
    -- Button click handler
    button:SetScript("OnClick", function()
        self:SelectQuest(questLogWindow, questID, button)
    end)
    
    -- Button hover effects
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.8, 0.8, 1, 1)
    end)
    
    button:SetScript("OnLeave", function(self)
        if questLogWindow.selectedQuest ~= questID then
            self:SetBackdropColor(0.9, 0.9, 0.9, 1)
        end
    end)
    
    button.questID = questID
    button.questText = questText
    table.insert(questLogWindow.questButtons, button)
    
    return button
end

function QuestWindow:CreateQuestHeader(questLogWindow, title, yOffset)
    local header = CreateFrame("Frame", nil, questLogWindow.questScrollChild, "BackdropTemplate")
    header:SetSize(questLogWindow.questScrollChild:GetWidth() - 5, 15)
    header:SetPoint("TOPLEFT", questLogWindow.questScrollChild, "TOPLEFT", 5, -yOffset)
    
    -- Header backdrop
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8
    })
    header:SetBackdropColor(unpack(WoW95.colors.titleBar))
    
    -- Header text
    local headerText = header:CreateFontString(nil, "OVERLAY")
    headerText:SetPoint("LEFT", header, "LEFT", 5, 0)
    headerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    headerText:SetText(title or "Quest Category")
    headerText:SetTextColor(unpack(WoW95.colors.titleBarText))
    
    table.insert(questLogWindow.questButtons, header)
    return header
end

function QuestWindow:SelectQuest(questLogWindow, questID, button)
    WoW95:Debug("Selected quest: " .. questID)
    
    -- Update button appearances
    for _, btn in pairs(questLogWindow.questButtons) do
        if btn.questID then
            btn:SetBackdropColor(0.9, 0.9, 0.9, 1)
        end
    end
    
    -- Highlight selected button
    button:SetBackdropColor(0.6, 0.6, 1, 1)
    questLogWindow.selectedQuest = questID
    
    -- Load quest details
    self:LoadQuestDetails(questLogWindow, questID)
end

function QuestWindow:LoadQuestDetails(questLogWindow, questID)
    -- Clear existing details
    local scrollChild = questLogWindow.detailsScrollChild
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Get quest info
    local title = C_QuestLog.GetTitleForQuestID(questID)
    local description = C_QuestLog.GetQuestDescription(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    
    -- Update title
    questLogWindow.detailsTitle:SetText(title or "Quest Details")
    
    -- Create quest description
    local yOffset = 10
    
    if description then
        local descText = scrollChild:CreateFontString(nil, "OVERLAY")
        descText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
        descText:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, -yOffset)
        descText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        descText:SetText(description)
        descText:SetTextColor(0, 0, 0, 1)
        descText:SetJustifyH("LEFT")
        descText:SetJustifyV("TOP")
        
        yOffset = yOffset + descText:GetStringHeight() + 20
    end
    
    -- Create objectives
    if objectives and #objectives > 0 then
        local objHeader = scrollChild:CreateFontString(nil, "OVERLAY")
        objHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
        objHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        objHeader:SetText("Objectives:")
        objHeader:SetTextColor(0, 0, 0, 1)
        
        yOffset = yOffset + 20
        
        for i, objective in ipairs(objectives) do
            local objText = scrollChild:CreateFontString(nil, "OVERLAY")
            objText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, -yOffset)
            objText:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, -yOffset)
            objText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            objText:SetText("• " .. objective.text)
            objText:SetTextColor(0, 0, 0, 1)
            objText:SetJustifyH("LEFT")
            
            yOffset = yOffset + objText:GetStringHeight() + 5
        end
    end
    
    -- Update scroll child height
    scrollChild:SetHeight(math.max(yOffset, questLogWindow.detailsScrollFrame:GetHeight()))
    
    WoW95:Debug("Loaded quest details for: " .. questID)
end

function QuestWindow:TrackSelectedQuest(questLogWindow)
    if questLogWindow.selectedQuest then
        C_QuestLog.AddQuestWatch(questLogWindow.selectedQuest)
        WoW95:Print("Tracking quest: " .. (C_QuestLog.GetTitleForQuestID(questLogWindow.selectedQuest) or "Unknown"))
    end
end

function QuestWindow:AbandonSelectedQuest(questLogWindow)
    if questLogWindow.selectedQuest then
        local title = C_QuestLog.GetTitleForQuestID(questLogWindow.selectedQuest) or "Unknown"
        -- Show confirmation dialog (simplified)
        WoW95:Print("Abandon quest: " .. title .. " (functionality placeholder)")
    end
end

function QuestWindow:ShareSelectedQuest(questLogWindow)
    if questLogWindow.selectedQuest then
        local title = C_QuestLog.GetTitleForQuestID(questLogWindow.selectedQuest) or "Unknown"
        WoW95:Print("Share quest: " .. title .. " (functionality placeholder)")
    end
end

-- Register the module
WoW95:RegisterModule("QuestWindow", QuestWindow)