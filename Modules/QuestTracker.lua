-- WoW95 Quest Tracker Module
-- Windows 95 styled quest tracker interface

local addonName, WoW95 = ...

local QuestTracker = {}
WoW95.QuestTracker = QuestTracker

-- Quest tracker settings
local TITLE_BAR_HEIGHT = 18
local TITLE_BAR_WIDTH = 250
local BUTTON_SIZE = 16

-- Quest tracker state
QuestTracker.frames = {}
QuestTracker.contentFrames = {}
QuestTracker.isInitialized = false
QuestTracker.sectionsMinimized = {
    objectives = false,
    campaign = false,
    quests = false
}

function QuestTracker:Init()
    WoW95:Debug("Initializing Quest Tracker module...")
    
    -- Wait for Blizzard quest tracker to be loaded
    if not ObjectiveTrackerFrame then
        C_Timer.After(2, function() self:Init() end)
        return
    end
    
    -- Wait for tracker to be fully loaded
    C_Timer.After(2, function()
        -- Hide the entire default tracker
        self:HideBlizzardTracker()
        
        -- Create our own quest display system
        self:CreateQuestDisplaySystem()
        
        -- Hook events for updates
        self:HookQuestEvents()
        
        self.isInitialized = true
        WoW95:Debug("Quest Tracker module initialized successfully!")
        
        -- Create slash command for manual debug
        SLASH_WOW95DEBUG1 = "/wow95debug"
        SlashCmdList["WOW95DEBUG"] = function()
            WoW95.QuestTracker:ShowDebugInfo()
        end
        
        -- Create slash command to find campaign quests specifically
        SLASH_WOW95CAMPAIGN1 = "/wow95campaign"
        SlashCmdList["WOW95CAMPAIGN"] = function()
            WoW95.QuestTracker:ShowCampaignDebugInfo()
        end
        
        print("WoW95: Quest Tracker loaded. Type /wow95debug to see debug info.")
    end)
end

function QuestTracker:HideBlizzardTracker()
    if ObjectiveTrackerFrame then
        -- Hide the entire default quest tracker
        ObjectiveTrackerFrame:Hide()
        ObjectiveTrackerFrame:SetAlpha(0)
        ObjectiveTrackerFrame:SetScript("OnShow", function() ObjectiveTrackerFrame:Hide() end)
        
        WoW95:Debug("Hidden entire Blizzard quest tracker")
    end
end

function QuestTracker:CreateQuestDisplaySystem()
    -- Create main container frame positioned below minimap, tight to right edge
    local mainFrame = CreateFrame("Frame", "WoW95QuestTrackerMain", UIParent)
    mainFrame:SetSize(TITLE_BAR_WIDTH, 400)
    mainFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -280) -- Moved down more
    mainFrame:SetFrameStrata("MEDIUM")
    
    -- Create "All Objectives" header (master control)
    local objHeader = self:CreateTitleBar("objectives", "All Objectives", mainFrame, 0, true)
    
    -- Create Campaign section
    local campaignHeader = self:CreateTitleBar("campaign", "Campaign", mainFrame, -25, false)
    local campaignContent = self:CreateContentFrame("campaign", mainFrame, -43)
    
    -- Create Quests section  
    local questsHeader = self:CreateTitleBar("quests", "Quests", mainFrame, -100, false)
    local questsContent = self:CreateContentFrame("quests", mainFrame, -118)
    
    -- Store references
    self.mainFrame = mainFrame
    self.contentFrames.campaign = campaignContent
    self.contentFrames.quests = questsContent
    
    -- Populate with quest data
    self:UpdateQuestContent()
    
    WoW95:Debug("Created quest display system - positioned lower below minimap")
end

function QuestTracker:UpdateSectionPositions()
    if not self.mainFrame then return end
    
    local currentY = 0
    
    -- All Objectives header always at top
    if self.frames.objectives then
        self.frames.objectives:ClearAllPoints()
        self.frames.objectives:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, currentY)
        currentY = currentY - TITLE_BAR_HEIGHT - 2
    end
    
    -- Campaign section with dynamic sizing
    if self.frames.campaign then
        self.frames.campaign:ClearAllPoints()
        self.frames.campaign:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, currentY)
        
        -- Position campaign content only if not minimized
        if self.contentFrames.campaign then
            self.contentFrames.campaign:ClearAllPoints()
            self.contentFrames.campaign:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 5, currentY - TITLE_BAR_HEIGHT - 2)
            
            -- Show/hide based on minimized state
            if self.sectionsMinimized.campaign then
                self.contentFrames.campaign:Hide()
            else
                self.contentFrames.campaign:Show()
                self.contentFrames.campaign.scrollChild:Show()
            end
        end
        
        currentY = currentY - TITLE_BAR_HEIGHT - 2
        
        -- Add dynamic space for campaign content only if not minimized
        if not self.sectionsMinimized.campaign and self.contentFrames.campaign then
            -- Calculate actual content height based on scroll child
            local scrollChildHeight = self.contentFrames.campaign.scrollChild:GetHeight()
            local actualHeight = math.max(scrollChildHeight, 20) -- Minimum 20px height
            
            -- Resize the campaign content frame to fit content exactly
            self.contentFrames.campaign:SetHeight(actualHeight)
            
            currentY = currentY - actualHeight - 5
            WoW95:Debug("Campaign section dynamically sized to " .. actualHeight .. "px")
        end
    end
    
    -- Quests section - positioned dynamically based on campaign state
    if self.frames.quests then
        self.frames.quests:ClearAllPoints()
        self.frames.quests:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, currentY)
        
        -- Position quests content
        if self.contentFrames.quests then
            self.contentFrames.quests:ClearAllPoints()
            self.contentFrames.quests:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 5, currentY - TITLE_BAR_HEIGHT - 2)
            
            -- Show/hide based on minimized state
            if self.sectionsMinimized.quests then
                self.contentFrames.quests:Hide()
            else
                self.contentFrames.quests:Show()
                self.contentFrames.quests.scrollChild:Show()
            end
        end
    end
    
    -- Adjust main frame height to accommodate all content
    local totalHeight = math.abs(currentY) + 100 -- Add padding
    self.mainFrame:SetHeight(math.max(totalHeight, 200))
    
    WoW95:Debug("Updated section positions - current Y: " .. currentY .. ", main height: " .. totalHeight)
end

function QuestTracker:CreateTitleBar(sectionName, title, parent, yOffset, isMaster)
    local titleBar = CreateFrame("Frame", "WoW95QuestTracker" .. sectionName, parent, "BackdropTemplate")
    titleBar:SetSize(TITLE_BAR_WIDTH, TITLE_BAR_HEIGHT)
    titleBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    titleBar:SetFrameStrata("HIGH")
    
    -- Windows 95 blue title bar
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 0.9) -- Windows 95 blue
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText(title)
    titleText:SetTextColor(1, 1, 1, 1) -- White text
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    titleText:SetShadowOffset(1, -1)
    titleText:SetShadowColor(0, 0, 0, 0.8)
    
    -- Add button for adding quests (only on main objectives header)
    local addButton = nil
    if isMaster then
        addButton = WoW95:CreateTitleBarButton(titleBar:GetName() .. "AddButton", titleBar, WoW95.textures.add, BUTTON_SIZE)
        addButton:SetPoint("RIGHT", titleBar, "RIGHT", -20, 0)
    end
    
    -- Minimize/Maximize button using custom texture
    local minMaxButton = WoW95:CreateTitleBarButton(titleBar:GetName() .. "MinMaxButton", titleBar, WoW95.textures.minimize, BUTTON_SIZE)
    if addButton then
        minMaxButton:SetPoint("RIGHT", addButton, "LEFT", -2, 0)
    else
        minMaxButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    end
    
    -- Store references
    titleBar.titleText = titleText
    titleBar.minMaxButton = minMaxButton
    titleBar.addButton = addButton
    titleBar.sectionName = sectionName
    titleBar.isMaster = isMaster
    
    -- Add button functionality (only on master)
    if addButton then
        addButton:SetScript("OnClick", function()
            self:ShowAddQuestDialog()
        end)
        
        -- Add button hover effects
        addButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Add Quest to Tracker")
            GameTooltip:AddLine("Opens quest log to add quests", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        
        addButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Click handling
    minMaxButton:SetScript("OnClick", function()
        self:ToggleSection(sectionName, isMaster)
    end)
    
    -- Hover effects with tooltips
    minMaxButton:SetScript("OnEnter", function(self)
        -- Visual effects are handled by CreateTitleBarButton
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if QuestTracker.sectionsMinimized[sectionName] then
            GameTooltip:SetText("Maximize " .. title)
        else
            GameTooltip:SetText("Minimize " .. title)
        end
        GameTooltip:Show()
    end)
    
    minMaxButton:SetScript("OnLeave", function(self)
        -- Visual effects are handled by CreateTitleBarButton
        GameTooltip:Hide()
    end)
    
    -- Store the frame
    self.frames[sectionName] = titleBar
    return titleBar
end

function QuestTracker:CreateContentFrame(sectionName, parent, yOffset)
    local contentFrame = CreateFrame("ScrollFrame", "WoW95QuestContent" .. sectionName, parent, "BackdropTemplate")
    
    -- Set different initial sizes based on section type
    local initialHeight = 100 -- Smaller default for campaign, will be resized dynamically
    if sectionName == "quests" then
        initialHeight = 600 -- Larger for quests section
    end
    
    contentFrame:SetSize(TITLE_BAR_WIDTH - 10, initialHeight)
    contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    contentFrame:SetFrameStrata("MEDIUM")
    contentFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    
    -- Create scroll child for quest text
    local scrollChild = CreateFrame("Frame", nil, contentFrame)
    scrollChild:SetSize(TITLE_BAR_WIDTH - 10, 1) -- Height will be dynamic
    contentFrame:SetScrollChild(scrollChild)
    
    -- Make sure it's visible
    contentFrame:Show()
    scrollChild:Show()
    
    -- Store reference to scroll child for adding quest text
    contentFrame.scrollChild = scrollChild
    contentFrame.questTexts = {}
    
    -- Add a visible background for debugging
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = true,
        tileSize = 8,
        edgeSize = 0,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    contentFrame:SetBackdropColor(0, 0, 0, 0.1) -- Very subtle background to see the frame
    
    return contentFrame
end

function QuestTracker:UpdateQuestContent()
    -- Clear existing content
    self:ClearContentFrames()
    
    -- Get quest data from WoW's quest log
    local numQuests = C_QuestLog.GetNumQuestLogEntries()
    local campaignY = 0
    local questsY = 0
    
    -- Update our tracked quest list for the poller
    if not self.lastTrackedQuests then
        self.lastTrackedQuests = {}
    end
    local newTrackedList = {}
    
    -- Use the proper WoW API to get ALL tracked quests (regular + world/campaign quests)
    local watchedQuests = {}
    
    WoW95:Debug("Building watched quest list using proper WoW APIs...")
    
    -- Get regular tracked quests
    local numRegularWatched = 0
    local success, watchCount = pcall(C_QuestLog.GetNumQuestWatches)
    if success and watchCount then
        numRegularWatched = watchCount
        WoW95:Debug("Found " .. numRegularWatched .. " regular tracked quests via GetNumQuestWatches()")
        
        -- Iterate through all regular tracked quests
        for i = 1, numRegularWatched do
            local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
            if questIDSuccess and questID then
                watchedQuests[questID] = true
                
                -- Get quest title for debug
                local titleSuccess, questTitle = pcall(C_QuestLog.GetTitleForQuestID, questID)
                local title = (titleSuccess and questTitle) or ("ID:" .. questID)
                WoW95:Debug("Pre-scan: Regular quest " .. i .. ": " .. title .. " (ID:" .. questID .. ")")
            end
        end
    else
        WoW95:Debug("GetNumQuestWatches() failed or returned nil")
    end
    
    -- Get world/campaign tracked quests
    local numWorldWatched = 0
    local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
    if worldSuccess and worldWatchCount then
        numWorldWatched = worldWatchCount
        WoW95:Debug("Found " .. numWorldWatched .. " world/campaign tracked quests via GetNumWorldQuestWatches()")
        
        -- Iterate through all world quest watches
        for i = 1, numWorldWatched do
            local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
            if questIDSuccess and questID then
                watchedQuests[questID] = true
                
                -- Get quest title for debug
                local titleSuccess, questTitle = pcall(C_QuestLog.GetTitleForQuestID, questID)
                local title = (titleSuccess and questTitle) or ("World/Campaign ID:" .. questID)
                WoW95:Debug("Pre-scan: World/Campaign quest " .. i .. ": " .. title .. " (ID:" .. questID .. ")")
            end
        end
    else
        WoW95:Debug("GetNumWorldQuestWatches() failed or returned nil")
    end
    
    local watchedCount = 0
    for _ in pairs(watchedQuests) do watchedCount = watchedCount + 1 end
    WoW95:Debug("Pre-scan found " .. watchedCount .. " watched quests. Processing " .. numQuests .. " quest log entries...")
    
    for i = 1, numQuests do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and questInfo.questID and not questInfo.isHeader then
            local questID = questInfo.questID
            local questTitle = questInfo.title or "Unknown Quest"
            
            -- Check if quest should be shown
            local shouldShow = false
            local isWatched = C_QuestLog.IsOnMap(questID)
            local isComplete = C_QuestLog.IsComplete(questID)
            
            -- Check if this quest is in our watched quests list (from proper API)
            local isInWatchedList = watchedQuests[questID] ~= nil
            
            -- A quest is tracked if it's in our properly built watched quest list
            local isTracked = isInWatchedList
            
            -- Keep other methods for debug comparison
            local isOnMap = false
            local mapSuccess, onMap = pcall(C_QuestLog.IsOnMap, questID)
            if mapSuccess then isOnMap = onMap end
            
            local questWatchType = nil
            local watchSuccess, watchType = pcall(C_QuestLog.GetQuestWatchType, questID)
            if watchSuccess then questWatchType = watchType end
            
            -- Update our tracking list for the poller
            if isTracked then
                newTrackedList[questID] = true
            end
            
            -- Debug mode toggle (set to true to show all quests)
            local debugShowAll = false -- Normal mode: only show tracked quests
            
            if debugShowAll then
                -- Show all incomplete quests for debugging
                if questInfo.isHeader or questInfo.isHidden then
                    shouldShow = false
                elseif not isComplete then
                    shouldShow = true
                else
                    shouldShow = false
                end
            else
                -- Strict filtering - ONLY show tracked AND incomplete quests
                if questInfo.isHeader or questInfo.isHidden then
                    shouldShow = false
                -- Must be tracked AND either not complete OR a completed campaign quest
                elseif isTracked then
                    -- Always show tracked quests (will handle coloring later)
                    shouldShow = true
                else
                    shouldShow = false
                end
            end
            
            -- Debug output for ALL quests (not just tracked) to find the missing campaign quest
            if not questInfo.isHeader and not questInfo.isHidden then
                -- Check if this might be a campaign quest even if not detected as tracked
                local debugCampaignID = nil
                local debugSuccess, debugCampaign = pcall(C_CampaignInfo.GetCampaignID, questID)
                if debugSuccess then debugCampaignID = debugCampaign end
                
                -- Show debug for tracked quests OR potential campaign quests
                if isTracked or (debugCampaignID ~= nil and debugCampaignID > 0) or (questInfo.campaignID ~= nil and questInfo.campaignID > 0) then
                    WoW95:Debug("Quest: " .. questTitle .. " (ID:" .. questID .. ")" ..
                               " | InWatchList:" .. tostring(isInWatchedList) ..
                               " | IsOnMap:" .. tostring(isOnMap) .. 
                               " | WatchType:" .. tostring(questWatchType) ..
                               " | IsTracked:" .. tostring(isTracked) ..
                               " | IsComplete:" .. tostring(isComplete) ..
                               " | QuestInfo.CampaignID:" .. tostring(questInfo.campaignID) ..
                               " | API.CampaignID:" .. tostring(debugCampaignID) ..
                               " | ShouldShow:" .. tostring(shouldShow))
                end
            end
            
            if shouldShow then
                -- Determine if this is a campaign quest using proper API
                local questInfoCampaignID = questInfo.campaignID
                local apiCampaignID = nil
                local apiSuccess, campaignID = pcall(C_CampaignInfo.GetCampaignID, questID)
                if apiSuccess then apiCampaignID = campaignID end
                
                -- Check if this quest came from world quest watches (might be campaign quests)
                local isFromWorldWatch = false
                local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
                if worldSuccess and worldWatchCount then
                    for i = 1, worldWatchCount do
                        local questIDSuccess, worldQuestID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
                        if questIDSuccess and worldQuestID == questID then
                            isFromWorldWatch = true
                            break
                        end
                    end
                end
                
                -- A quest is a campaign quest if:
                -- 1. Either method returns a valid campaign ID, OR
                -- 2. It comes from the world quest watch API (many campaign quests are tracked this way)
                local isCampaign = (questInfoCampaignID ~= nil and questInfoCampaignID > 0) or 
                                 (apiCampaignID ~= nil and apiCampaignID > 0) or 
                                 isFromWorldWatch
                
                -- Debug campaign detection
                WoW95:Debug("Quest " .. questTitle .. " | QuestInfo.CampaignID: " .. tostring(questInfoCampaignID) .. 
                           " | API.CampaignID: " .. tostring(apiCampaignID) .. " | IsFromWorldWatch: " .. tostring(isFromWorldWatch) .. 
                           " | IsCampaign: " .. tostring(isCampaign))
                
                -- Determine which section this quest belongs to
                local targetFrame = isCampaign and self.contentFrames.campaign or self.contentFrames.quests
                local currentY = isCampaign and campaignY or questsY
                
                WoW95:Debug("Placing " .. questTitle .. " in " .. (isCampaign and "CAMPAIGN" or "QUESTS") .. " section")
                
                if targetFrame then
                    -- Create quest container frame for the entire quest
                    local questContainer = CreateFrame("Button", nil, targetFrame.scrollChild)
                    questContainer:SetSize(TITLE_BAR_WIDTH - 10, 20) -- Will adjust height later
                    questContainer:SetPoint("TOPLEFT", targetFrame.scrollChild, "TOPLEFT", 0, -currentY)
                    questContainer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    
                    -- Create quest activation icon (clickable)
                    local questIcon = CreateFrame("Button", nil, questContainer, "BackdropTemplate")
                    questIcon:SetSize(12, 12)
                    questIcon:SetPoint("TOPLEFT", questContainer, "TOPLEFT", 2, -2)
                    
                    -- Icon background
                    questIcon:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true,
                        tileSize = 8,
                        edgeSize = 1,
                        insets = {left = 1, right = 1, top = 1, bottom = 1}
                    })
                    
                    -- Check if this quest is currently being tracked/active
                    local isTracked = C_QuestLog.IsOnMap(questID)
                    local isActive = C_SuperTrack.GetSuperTrackedQuestID() == questID
                    
                    if isActive then
                        questIcon:SetBackdropColor(1, 1, 0, 1) -- Yellow for active quest
                        questIcon:SetBackdropBorderColor(0.8, 0.8, 0, 1)
                    elseif isTracked then
                        questIcon:SetBackdropColor(0.7, 0.7, 0.7, 1) -- Gray for tracked
                        questIcon:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                    else
                        questIcon:SetBackdropColor(0.3, 0.3, 0.3, 1) -- Dark gray for untracked
                        questIcon:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                    end
                    
                    -- Quest activation click handler
                    questIcon:SetScript("OnClick", function()
                        if C_SuperTrack.GetSuperTrackedQuestID() == questID then
                            -- If already active, deactivate supertracking
                            C_SuperTrack.SetSuperTrackedQuestID(0)
                            WoW95:Debug("Deactivated quest tracking for: " .. questTitle)
                        else
                            -- Set as active/supertracked quest
                            C_SuperTrack.SetSuperTrackedQuestID(questID)
                            WoW95:Debug("Activated quest tracking for: " .. questTitle)
                        end
                        
                        -- Refresh the tracker to update icon states
                        C_Timer.After(0.1, function()
                            QuestTracker:UpdateQuestContent()
                        end)
                    end)
                    
                    -- Hover effects and tooltip
                    questIcon:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        if isActive then
                            GameTooltip:SetText("Click to stop tracking this quest")
                        else
                            GameTooltip:SetText("Click to track this quest")
                        end
                        GameTooltip:Show()
                        
                        -- Highlight effect
                        if isActive then
                            self:SetBackdropColor(1, 1, 0.5, 1)
                        else
                            self:SetBackdropColor(0.5, 0.5, 0.5, 1)
                        end
                    end)
                    
                    questIcon:SetScript("OnLeave", function(self)
                        GameTooltip:Hide()
                        
                        -- Restore original color
                        if isActive then
                            self:SetBackdropColor(1, 1, 0, 1)
                        elseif isTracked then
                            self:SetBackdropColor(0.7, 0.7, 0.7, 1)
                        else
                            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
                        end
                    end)
                    
                    -- Create quest title text
                    local questText = questContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    questText:SetPoint("TOPLEFT", questContainer, "TOPLEFT", 20, -2) -- Offset for icon
                    
                    -- Color quest title based on status
                    local titleColor = {1, 1, 0.8, 1} -- Default yellow
                    if isComplete then
                        titleColor = {0.5, 1, 0.5, 1} -- Green for complete
                    elseif isWorldQuest then
                        titleColor = {0.5, 0.8, 1, 1} -- Blue for world quests
                    elseif isActive then
                        titleColor = {1, 1, 0.5, 1} -- Brighter yellow for active
                    end
                    
                    questText:SetText(questTitle)
                    questText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                    questText:SetTextColor(titleColor[1], titleColor[2], titleColor[3], titleColor[4])
                    questText:SetJustifyH("LEFT")
                    questText:SetWidth(TITLE_BAR_WIDTH - 30) -- Account for icon space
                    questText:SetWordWrap(true)
                    
                    -- Add right-click context menu functionality
                    questContainer:SetScript("OnClick", function(self, button)
                        if button == "RightButton" then
                            QuestTracker:ShowQuestContextMenu(questID, questTitle, self)
                        end
                    end)
                    
                    -- Store references
                    questContainer.questText = questText
                    questContainer.questIcon = questIcon
                    questContainer.questID = questID
                    questContainer.questTitle = questTitle
                    questContainer.isWatched = isWatched
                    
                    table.insert(targetFrame.questTexts, questContainer)
                    
                    local objCount = 0
                    
                    -- Try multiple methods to get quest objectives
                    local objectives = C_QuestLog.GetQuestObjectives(questID)
                    
                    if objectives and #objectives > 0 then
                        for j, objective in ipairs(objectives) do
                            local objText = objective.text or objective
                            if objText and objText ~= "" then
                                local objFrame = targetFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                                objFrame:SetPoint("TOPLEFT", questText, "BOTTOMLEFT", 10, -2 - (objCount * 12))
                                
                                -- Format objective text with progress if available
                                local objTextStr = "  - " .. objText
                                
                                -- Add progress numbers if available
                                if type(objective) == "table" then
                                    if objective.numFulfilled and objective.numRequired then
                                        objTextStr = objTextStr .. " (" .. objective.numFulfilled .. "/" .. objective.numRequired .. ")"
                                    elseif objective.finished then
                                        objTextStr = objTextStr .. " (Complete)"
                                    end
                                end
                                
                                objFrame:SetText(objTextStr)
                                objFrame:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                                
                                -- Color based on completion
                                if type(objective) == "table" and objective.finished then
                                    objFrame:SetTextColor(0.5, 1, 0.5, 1) -- Green for completed
                                else
                                    objFrame:SetTextColor(0.8, 0.8, 0.8, 1) -- Gray for incomplete
                                end
                                
                                objFrame:SetJustifyH("LEFT")
                                objFrame:SetWidth(TITLE_BAR_WIDTH - 30)
                                objFrame:SetWordWrap(true)
                                
                                table.insert(targetFrame.questTexts, objFrame)
                                objCount = objCount + 1
                            end
                        end
                    end
                    
                    -- If no objectives from modern API, try legacy method
                    if objCount == 0 then
                        local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
                        if questLogIndex then
                            local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
                            if numObjectives and numObjectives > 0 then
                                for k = 1, numObjectives do
                                    local objDesc, objType, finished = GetQuestLogLeaderBoard(k, questLogIndex)
                                    if objDesc then
                                        local objFrame = questContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                                        objFrame:SetPoint("TOPLEFT", questText, "BOTTOMLEFT", 10, -2 - (objCount * 12))
                                        objFrame:SetText("  - " .. objDesc)
                                        objFrame:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                                        
                                        if finished then
                                            objFrame:SetTextColor(0.5, 1, 0.5, 1) -- Green for completed
                                        else
                                            objFrame:SetTextColor(0.8, 0.8, 0.8, 1) -- Gray for incomplete
                                        end
                                        
                                        objFrame:SetJustifyH("LEFT")
                                        objFrame:SetWidth(TITLE_BAR_WIDTH - 30)
                                        objFrame:SetWordWrap(true)
                                        
                                        table.insert(targetFrame.questTexts, objFrame)
                                        objCount = objCount + 1
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Final fallback if no objectives found
                    if objCount == 0 then
                        local statusText = questContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        statusText:SetPoint("TOPLEFT", questText, "BOTTOMLEFT", 10, -2)
                        
                        if isComplete then
                            statusText:SetText("  - Ready to turn in")
                            statusText:SetTextColor(0.5, 1, 0.5, 1) -- Green
                        else
                            statusText:SetText("  - Quest in progress...")
                            statusText:SetTextColor(0.8, 0.8, 0.8, 1) -- Gray
                        end
                        
                        statusText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                        statusText:SetJustifyH("LEFT")
                        statusText:SetWidth(TITLE_BAR_WIDTH - 30)
                        statusText:SetWordWrap(true)
                        
                        table.insert(targetFrame.questTexts, statusText)
                        objCount = 1
                    end
                    
                    -- Update quest container height and Y position for next quest
                    local questHeight = 15 + (objCount * 12) + 5 -- Title + objectives + spacing
                    questContainer:SetHeight(questHeight)
                    
                    if isCampaign then
                        campaignY = campaignY + questHeight
                    else
                        questsY = questsY + questHeight
                    end
                    
                    WoW95:Debug("Added quest: " .. questTitle .. " (" .. (isCampaign and "Campaign" or "Regular") .. ") with " .. objCount .. " objectives")
                end
            end
        end
    end
    
    -- Process world quest watches that might not be in the regular quest log
    local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
    if worldSuccess and worldWatchCount then
        for i = 1, worldWatchCount do
            local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
            if questIDSuccess and questID then
                -- Check if this quest was already processed in the main loop
                local alreadyProcessed = false
                for j = 1, numQuests do
                    local questInfo = C_QuestLog.GetInfo(j)
                    if questInfo and questInfo.questID == questID then
                        alreadyProcessed = true
                        break
                    end
                end
                
                -- If not already processed, handle it separately
                if not alreadyProcessed then
                    local titleSuccess, questTitle = pcall(C_QuestLog.GetTitleForQuestID, questID)
                    local title = (titleSuccess and questTitle) or ("World Quest ID:" .. questID)
                    
                    -- Check if this is actually a quest and not an event
                    local worldQuestCampaignID = nil
                    local worldApiSuccess, worldCampaignID = pcall(C_CampaignInfo.GetCampaignID, questID)
                    if worldApiSuccess then worldQuestCampaignID = worldCampaignID end
                    
                    local isComplete = C_QuestLog.IsComplete(questID)
                    
                    -- Show if it's a campaign quest (complete or incomplete) to allow completed campaign quests to show in green
                    -- This helps filter out events that shouldn't be in the quest tracker
                    local isActualQuest = (worldQuestCampaignID ~= nil and worldQuestCampaignID > 0)
                    local shouldShow = isActualQuest -- Show campaign quests regardless of completion status
                    
                    WoW95:Debug("Processing world quest not in log: " .. title .. " (ID:" .. questID .. ") | IsComplete:" .. tostring(isComplete) .. " | ShouldShow:" .. tostring(shouldShow))
                    
                    if shouldShow then
                        -- Check if this world quest is actually a campaign quest
                        local worldQuestCampaignID = nil
                        local worldApiSuccess, worldCampaignID = pcall(C_CampaignInfo.GetCampaignID, questID)
                        if worldApiSuccess then worldQuestCampaignID = worldCampaignID end
                        
                        local isWorldQuestCampaign = (worldQuestCampaignID ~= nil and worldQuestCampaignID > 0)
                        
                        -- Place in appropriate section
                        local targetFrame = isWorldQuestCampaign and self.contentFrames.campaign or self.contentFrames.quests
                        local currentY = isWorldQuestCampaign and campaignY or questsY
                        
                        WoW95:Debug("World quest " .. title .. " | CampaignID: " .. tostring(worldQuestCampaignID) .. " | IsCampaign: " .. tostring(isWorldQuestCampaign))
                        WoW95:Debug("Placing world quest " .. title .. " in " .. (isWorldQuestCampaign and "CAMPAIGN" or "QUESTS") .. " section")
                        
                        if targetFrame then
                            -- Create quest container frame
                            local questContainer = CreateFrame("Button", nil, targetFrame.scrollChild)
                            questContainer:SetSize(TITLE_BAR_WIDTH - 10, 20)
                            questContainer:SetPoint("TOPLEFT", targetFrame.scrollChild, "TOPLEFT", 0, -currentY)
                            questContainer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                            
                            -- Create quest activation icon
                            local questIcon = CreateFrame("Button", nil, questContainer, "BackdropTemplate")
                            questIcon:SetSize(12, 12)
                            questIcon:SetPoint("TOPLEFT", questContainer, "TOPLEFT", 2, -2)
                            questIcon:SetBackdrop({
                                bgFile = "Interface\\Buttons\\WHITE8X8",
                                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                tile = true, tileSize = 8, edgeSize = 1,
                                insets = {left = 1, right = 1, top = 1, bottom = 1}
                            })
                            questIcon:SetBackdropColor(0.7, 0.7, 0.7, 1)
                            questIcon:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                            
                            -- Create quest title text
                            local questText = questContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                            questText:SetPoint("TOPLEFT", questContainer, "TOPLEFT", 20, -2)
                            questText:SetText(title)
                            questText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                            -- Color based on completion status for world/campaign quests
                            if isComplete then
                                questText:SetTextColor(0.5, 1, 0.5, 1) -- Green for completed campaign quests
                            else
                                questText:SetTextColor(0.5, 0.8, 1, 1) -- Blue color for incomplete world/campaign quests
                            end
                            questText:SetJustifyH("LEFT")
                            questText:SetWidth(TITLE_BAR_WIDTH - 30)
                            questText:SetWordWrap(true)
                            
                            -- Add right-click context menu
                            questContainer:SetScript("OnClick", function(self, button)
                                if button == "RightButton" then
                                    QuestTracker:ShowQuestContextMenu(questID, title, self)
                                end
                            end)
                            
                            -- Store references
                            questContainer.questText = questText
                            questContainer.questIcon = questIcon
                            questContainer.questID = questID
                            questContainer.questTitle = title
                            
                            table.insert(targetFrame.questTexts, questContainer)
                            
                            local questHeight = 20
                            questContainer:SetHeight(questHeight)
                            
                            if isWorldQuestCampaign then
                                campaignY = campaignY + questHeight
                                WoW95:Debug("Added world quest: " .. title .. " to Campaign section")
                            else
                                questsY = questsY + questHeight
                                WoW95:Debug("Added world quest: " .. title .. " to Quests section")
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Update scroll child heights
    if self.contentFrames.campaign then
        self.contentFrames.campaign.scrollChild:SetHeight(math.max(campaignY, 1))
    end
    if self.contentFrames.quests then
        self.contentFrames.quests.scrollChild:SetHeight(math.max(questsY, 1))
    end
    
    -- Update positioning after content changes
    self:UpdateSectionPositions()
    
    -- Update our tracked quest list for the poller
    self.lastTrackedQuests = newTrackedList
    
    WoW95:Debug("Updated quest content - Campaign: " .. campaignY .. "px, Quests: " .. questsY .. "px")
end

function QuestTracker:ClearContentFrames()
    for _, contentFrame in pairs(self.contentFrames) do
        if contentFrame and contentFrame.questTexts then
            for _, questElement in ipairs(contentFrame.questTexts) do
                if questElement then
                    -- Handle both old text elements and new container frames
                    if questElement.questText then
                        -- This is a quest container frame
                        questElement:Hide()
                        questElement:SetParent(nil)
                    else
                        -- This is a text element (objectives, status text)
                        questElement:Hide()
                        questElement:SetParent(nil)
                    end
                end
            end
            contentFrame.questTexts = {}
        end
    end
end

function QuestTracker:ToggleSection(sectionName, isMaster)
    if isMaster then
        -- Master control toggles both sections
        local newState = not self.sectionsMinimized[sectionName]
        self.sectionsMinimized[sectionName] = newState
        self.sectionsMinimized.campaign = newState
        self.sectionsMinimized.quests = newState
        
        -- Update all buttons and content
        self:UpdateMinMaxButton("objectives")
        self:UpdateMinMaxButton("campaign") 
        self:UpdateMinMaxButton("quests")
        self:UpdateContentVisibility("campaign")
        self:UpdateContentVisibility("quests")
        
        WoW95:Debug("Master toggle: " .. (newState and "minimized" or "maximized"))
    else
        -- Individual section toggle
        self.sectionsMinimized[sectionName] = not self.sectionsMinimized[sectionName]
        self:UpdateMinMaxButton(sectionName)
        self:UpdateContentVisibility(sectionName)
        
        WoW95:Debug(sectionName .. " toggle: " .. (self.sectionsMinimized[sectionName] and "minimized" or "maximized"))
    end
end

function QuestTracker:UpdateMinMaxButton(sectionName)
    local frame = self.frames[sectionName]
    if frame and frame.minMaxButton and frame.minMaxButton.icon then
        if self.sectionsMinimized[sectionName] then
            frame.minMaxButton.icon:SetTexture(WoW95.textures.maximize) -- Maximize texture
        else
            frame.minMaxButton.icon:SetTexture(WoW95.textures.minimize) -- Minimize texture
        end
    end
end

function QuestTracker:UpdateContentVisibility(sectionName)
    local contentFrame = self.contentFrames[sectionName]
    if contentFrame then
        if self.sectionsMinimized[sectionName] then
            contentFrame:Hide()
            -- Also hide the backdrop when minimized
            contentFrame:SetBackdrop(nil)
            WoW95:Debug(sectionName .. " content hidden and backdrop removed")
        else
            contentFrame:Show()
            contentFrame.scrollChild:Show()
            -- Restore the backdrop when shown
            contentFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = nil,
                tile = true,
                tileSize = 8,
                edgeSize = 0,
                insets = {left = 0, right = 0, top = 0, bottom = 0}
            })
            contentFrame:SetBackdropColor(0, 0, 0, 0.1)
            WoW95:Debug(sectionName .. " content shown and backdrop restored")
        end
    end
    
    -- Force immediate position update after visibility change
    C_Timer.After(0.1, function()
        self:UpdateSectionPositions()
    end)
end

function QuestTracker:HookQuestEvents()
    -- Store the event frame as part of the module
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    self.eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
    self.eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    self.eventFrame:RegisterEvent("QUEST_ACCEPTED")
    self.eventFrame:RegisterEvent("QUEST_REMOVED")
    self.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    self.eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Store the current tracked quest list for comparison
    self.lastTrackedQuests = {}
    
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        WoW95:Debug("Quest event fired: " .. event)
        -- Use shorter delay for watch updates for more responsive feel
        local delay = (event == "QUEST_WATCH_UPDATE" or event == "QUEST_WATCH_LIST_CHANGED") and 0.1 or 0.2
        C_Timer.After(delay, function()
            if QuestTracker.isInitialized then
                QuestTracker:UpdateQuestContent()
            end
        end)
    end)
    
    -- Also set up a polling mechanism to catch quest tracking changes
    -- This ensures we catch all changes even if events don't fire
    self:SetupTrackingPoller()
    
    WoW95:Debug("Hooked quest tracker events with polling backup")
end

function QuestTracker:SetupTrackingPoller()
    -- Check for tracking changes every 1 second
    C_Timer.NewTicker(1, function()
        if not self.isInitialized then return end
        
        -- Build current tracked quest list using the same logic as UpdateQuestContent
        local currentTracked = {}
        local hasChanges = false
        
        -- Get all watched quests using proper API (same method as UpdateQuestContent)
        local watchedQuests = {}
        
        -- Get regular tracked quests
        local success, watchCount = pcall(C_QuestLog.GetNumQuestWatches)
        if success and watchCount then
            for i = 1, watchCount do
                local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
                if questIDSuccess and questID then
                    watchedQuests[questID] = true
                end
            end
        end
        
        -- Get world/campaign tracked quests
        local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
        if worldSuccess and worldWatchCount then
            for i = 1, worldWatchCount do
                local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
                if questIDSuccess and questID then
                    watchedQuests[questID] = true
                end
            end
        end
        
        local numQuests = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, numQuests do
            local questInfo = C_QuestLog.GetInfo(i)
            if questInfo and questInfo.questID and not questInfo.isHeader then
                local questID = questInfo.questID
                -- Use the proper watched quest list
                local isTracked = watchedQuests[questID] ~= nil
                
                if isTracked then
                    currentTracked[questID] = true
                    -- Check if this is newly tracked
                    if not self.lastTrackedQuests[questID] then
                        hasChanges = true
                        WoW95:Debug("Detected newly tracked quest: " .. (questInfo.title or "Unknown"))
                    end
                end
            end
        end
        
        -- Check for untracked quests
        for questID, _ in pairs(self.lastTrackedQuests) do
            if not currentTracked[questID] then
                hasChanges = true
                WoW95:Debug("Detected untracked quest: ID " .. questID)
            end
        end
        
        -- Update if there were changes
        if hasChanges then
            self.lastTrackedQuests = currentTracked
            self:UpdateQuestContent()
            WoW95:Debug("Tracker updated due to tracking changes detected by poller")
        end
    end)
end

function QuestTracker:Show()
    if self.mainFrame then
        self.mainFrame:Show()
    end
end

function QuestTracker:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function QuestTracker:ShowQuestContextMenu(questID, questTitle, parentFrame)
    -- Remove any existing context menu
    if self.contextMenu then
        self.contextMenu:Hide()
        self.contextMenu = nil
    end
    
    -- Create context menu
    self.contextMenu = CreateFrame("Frame", "WoW95QuestContextMenu", UIParent, "BackdropTemplate")
    self.contextMenu:SetSize(120, 60)
    self.contextMenu:SetFrameStrata("TOOLTIP")
    self.contextMenu:SetFrameLevel(500)
    
    -- Position menu near the quest
    local x, y = GetCursorPosition()
    local scale = self.contextMenu:GetEffectiveScale()
    self.contextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    
    -- Menu backdrop
    self.contextMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.contextMenu:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.contextMenu:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Check if quest is currently tracked using proper API (check both regular and world quests)
    local isTracked = false
    
    -- Check regular quest watches
    local success, watchCount = pcall(C_QuestLog.GetNumQuestWatches)
    if success and watchCount then
        for i = 1, watchCount do
            local questIDSuccess, watchedQuestID = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
            if questIDSuccess and watchedQuestID == questID then
                isTracked = true
                break
            end
        end
    end
    
    -- Check world quest watches if not found in regular
    if not isTracked then
        local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
        if worldSuccess and worldWatchCount then
            for i = 1, worldWatchCount do
                local questIDSuccess, watchedQuestID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
                if questIDSuccess and watchedQuestID == questID then
                    isTracked = true
                    break
                end
            end
        end
    end
    
    -- Untrack option
    local untrackButton = CreateFrame("Button", nil, self.contextMenu, "BackdropTemplate")
    untrackButton:SetSize(116, 24)
    untrackButton:SetPoint("TOP", self.contextMenu, "TOP", 0, -4)
    
    untrackButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
    })
    untrackButton:SetBackdropColor(0, 0, 0, 0)
    
    local untrackText = untrackButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    untrackText:SetPoint("LEFT", untrackButton, "LEFT", 6, 0)
    untrackText:SetText(isTracked and "Untrack Quest" or "Track Quest")
    untrackText:SetTextColor(0, 0, 0, 1)
    untrackText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    untrackButton:SetScript("OnClick", function()
        -- Get the quest log index which is required for some tracking operations
        local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        
        if isTracked then
            -- Untrack the quest - use the quest info to properly untrack
            WoW95:Debug("Attempting to untrack quest: " .. questTitle .. " (ID: " .. questID .. ")")
            
            -- Get fresh quest info
            local questInfo = C_QuestLog.GetInfo(questLogIndex or 1)
            
            -- The correct way to untrack is to remove the quest watch
            -- Note: There is no SetQuestWatched function in modern WoW
            
            -- Method 2: Remove from map
            C_QuestLog.RemoveQuestWatch(questID)
            WoW95:Debug("Used RemoveQuestWatch(questID)")
            
            -- Method 3: Force update the quest log
            QuestMapFrame_UpdateAll()
        else
            -- Track the quest
            WoW95:Debug("Attempting to track quest: " .. questTitle .. " (ID: " .. questID .. ")")
            
            -- The correct way to track is to add the quest watch
            -- Note: There is no SetQuestWatched function in modern WoW
            
            -- Method 2: Add to map
            C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Manual)
            WoW95:Debug("Used AddQuestWatch(questID, Manual)")
            
            -- Method 3: Force update the quest log
            QuestMapFrame_UpdateAll()
        end
        
        -- Hide menu
        if QuestTracker.contextMenu then
            QuestTracker.contextMenu:Hide()
            QuestTracker.contextMenu = nil
        end
        
        -- Force immediate update with a small delay to ensure the tracking change has been processed
        C_Timer.After(0.1, function()
            -- Just do our own update directly
            QuestTracker:UpdateQuestContent()
            WoW95:Debug("Quest tracker updated after right-click track/untrack")
            
            -- Double-check the tracking status
            local newIsTracked = C_QuestLog.IsOnMap(questID) or C_QuestLog.GetQuestWatchType(questID) ~= nil
            WoW95:Debug("Quest " .. questTitle .. " tracking status after operation: " .. tostring(newIsTracked))
            
            -- If the status didn't change, try one more time with a longer delay
            if (isTracked and newIsTracked) or (not isTracked and not newIsTracked) then
                WoW95:Debug("Tracking status didn't change, scheduling another update")
                C_Timer.After(0.5, function()
                    QuestTracker:UpdateQuestContent()
                    WoW95:Debug("Second update attempt completed")
                end)
            end
        end)
    end)
    
    -- Hover effects
    untrackButton:SetScript("OnEnter", function()
        untrackButton:SetBackdropColor(unpack(WoW95.colors.selection))
        untrackText:SetTextColor(unpack(WoW95.colors.selectedText))
    end)
    untrackButton:SetScript("OnLeave", function()
        untrackButton:SetBackdropColor(0, 0, 0, 0)
        untrackText:SetTextColor(0, 0, 0, 1)
    end)
    
    -- Details option
    local detailsButton = CreateFrame("Button", nil, self.contextMenu, "BackdropTemplate")
    detailsButton:SetSize(116, 24)
    detailsButton:SetPoint("TOP", untrackButton, "BOTTOM", 0, -2)
    
    detailsButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
    })
    detailsButton:SetBackdropColor(0, 0, 0, 0)
    
    local detailsText = detailsButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailsText:SetPoint("LEFT", detailsButton, "LEFT", 6, 0)
    detailsText:SetText("View in Quest Log")
    detailsText:SetTextColor(0, 0, 0, 1)
    detailsText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    detailsButton:SetScript("OnClick", function()
        -- Open quest log to this quest
        if QuestLogFrame then
            ShowUIPanel(QuestLogFrame)
        else
            ToggleQuestLog()
        end
        
        -- Try to select the quest in the log
        local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        if questLogIndex then
            C_QuestLog.SetSelectedQuest(questID)
        end
        
        self.contextMenu:Hide()
        self.contextMenu = nil
    end)
    
    -- Hover effects
    detailsButton:SetScript("OnEnter", function()
        detailsButton:SetBackdropColor(unpack(WoW95.colors.selection))
        detailsText:SetTextColor(unpack(WoW95.colors.selectedText))
    end)
    detailsButton:SetScript("OnLeave", function()
        detailsButton:SetBackdropColor(0, 0, 0, 0)
        detailsText:SetTextColor(0, 0, 0, 1)
    end)
    
    -- Close menu when clicking elsewhere
    self.contextMenu:SetScript("OnShow", function()
        local closeFrame = CreateFrame("Frame", nil, UIParent)
        closeFrame:SetAllPoints(UIParent)
        closeFrame:SetFrameStrata("TOOLTIP")
        closeFrame:SetFrameLevel(499)
        closeFrame:EnableMouse(true)
        closeFrame:SetScript("OnMouseDown", function()
            if self.contextMenu then
                self.contextMenu:Hide()
                self.contextMenu = nil
            end
            closeFrame:Hide()
        end)
        self.contextMenu.closeFrame = closeFrame
    end)
    
    self.contextMenu:SetScript("OnHide", function()
        if self.contextMenu and self.contextMenu.closeFrame then
            self.contextMenu.closeFrame:Hide()
        end
    end)
    
    self.contextMenu:Show()
end

function QuestTracker:ShowAddQuestDialog()
    -- Simple implementation - just open the quest log
    if QuestLogFrame then
        ShowUIPanel(QuestLogFrame)
    else
        ToggleQuestLog()
    end
    
    -- Show a helpful message
    WoW95:Print("Quest Log opened - shift-click quests to track them!")
end

function QuestTracker:ShowDebugInfo()
    print("=== WoW95 Quest Tracker Debug Info ===")
    
    local numQuests = C_QuestLog.GetNumQuestLogEntries()
    print("Total quest log entries: " .. numQuests)
    
    -- Get watched quests using proper API (same method as UpdateQuestContent)
    local watchedQuests = {}
    
    -- Get regular tracked quests
    local success, watchCount = pcall(C_QuestLog.GetNumQuestWatches)
    if success and watchCount then
        print("GetNumQuestWatches() returned: " .. watchCount)
        for i = 1, watchCount do
            local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
            if questIDSuccess and questID then
                watchedQuests[questID] = true
                local titleSuccess, questTitle = pcall(C_QuestLog.GetTitleForQuestID, questID)
                local title = (titleSuccess and questTitle) or ("ID:" .. questID)
                print("Regular watch " .. i .. ": " .. title .. " (ID:" .. questID .. ")")
            end
        end
    else
        print("GetNumQuestWatches() failed or returned nil")
    end
    
    -- Get world/campaign tracked quests
    local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
    if worldSuccess and worldWatchCount then
        print("GetNumWorldQuestWatches() returned: " .. worldWatchCount)
        for i = 1, worldWatchCount do
            local questIDSuccess, questID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, i)
            if questIDSuccess and questID then
                watchedQuests[questID] = true
                local titleSuccess, questTitle = pcall(C_QuestLog.GetTitleForQuestID, questID)
                local title = (titleSuccess and questTitle) or ("World/Campaign ID:" .. questID)
                print("World/Campaign watch " .. i .. ": " .. title .. " (ID:" .. questID .. ")")
            end
        end
    else
        print("GetNumWorldQuestWatches() failed or returned nil")
    end
    
    local watchedCount = 0
    for _ in pairs(watchedQuests) do watchedCount = watchedCount + 1 end
    print("Pre-scan found " .. watchedCount .. " watched quests")
    
    local trackedCount = 0
    local shownCount = 0
    
    for i = 1, numQuests do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and questInfo.questID and not questInfo.isHeader then
            local questID = questInfo.questID
            local questTitle = questInfo.title or "Unknown Quest"
            local isComplete = C_QuestLog.IsComplete(questID)
            
            if not isComplete then
                -- Check tracking status using same logic as UpdateQuestContent
                local isInWatchedList = watchedQuests[questID] ~= nil
                local isTracked = isInWatchedList  -- Use proper API result
                
                -- Also check other methods for comparison
                local isOnMap = C_QuestLog.IsOnMap(questID)
                local questWatchType = C_QuestLog.GetQuestWatchType(questID)
                
                if isTracked then
                    trackedCount = trackedCount + 1
                    print("TRACKED: " .. questTitle .. " | InWatchList:" .. tostring(isInWatchedList) .. 
                          " | IsOnMap:" .. tostring(isOnMap) .. " | WatchType:" .. tostring(questWatchType))
                end
                
                -- Check if it would be shown in our tracker
                local shouldShow = isTracked and not isComplete
                if shouldShow then
                    shownCount = shownCount + 1
                end
            end
        end
    end
    
    print("Tracked quests found: " .. trackedCount)
    print("Quests that should show in tracker: " .. shownCount)
    print("Debug mode (shows all quests): false")
    print("=== End Debug Info ===")
end

function QuestTracker:ShowCampaignDebugInfo()
    print("=== WoW95 Campaign Quest Debug Info ===")
    
    local numQuests = C_QuestLog.GetNumQuestLogEntries()
    print("Scanning " .. numQuests .. " quest log entries for campaign quests...")
    
    local foundCampaignQuests = 0
    
    for i = 1, numQuests do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and questInfo.questID and not questInfo.isHeader then
            local questID = questInfo.questID
            local questTitle = questInfo.title or "Unknown Quest"
            local isComplete = C_QuestLog.IsComplete(questID)
            
            -- Check all campaign detection methods
            local questInfoCampaignID = questInfo.campaignID
            local apiCampaignID = nil
            local apiSuccess, campaignID = pcall(C_CampaignInfo.GetCampaignID, questID)
            if apiSuccess then apiCampaignID = campaignID end
            
            -- Check if it's tracked via world quest API
            local isFromWorldWatch = false
            local worldSuccess, worldWatchCount = pcall(C_QuestLog.GetNumWorldQuestWatches)
            if worldSuccess and worldWatchCount then
                for j = 1, worldWatchCount do
                    local questIDSuccess, worldQuestID = pcall(C_QuestLog.GetQuestIDForWorldQuestWatchIndex, j)
                    if questIDSuccess and worldQuestID == questID then
                        isFromWorldWatch = true
                        break
                    end
                end
            end
            
            -- Check if it's tracked via regular quest API
            local isFromRegularWatch = false
            local success, watchCount = pcall(C_QuestLog.GetNumQuestWatches)
            if success and watchCount then
                for j = 1, watchCount do
                    local questIDSuccess, regularQuestID = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, j)
                    if questIDSuccess and regularQuestID == questID then
                        isFromRegularWatch = true
                        break
                    end
                end
            end
            
            -- Show if it has any campaign indicators OR if it might be an active quest we're missing
            if (questInfoCampaignID ~= nil and questInfoCampaignID > 0) or 
               (apiCampaignID ~= nil and apiCampaignID > 0) or
               isFromWorldWatch or
               (not isComplete and (isFromRegularWatch or isFromWorldWatch)) then
                foundCampaignQuests = foundCampaignQuests + 1
                local questType = "UNKNOWN"
                if (questInfoCampaignID ~= nil and questInfoCampaignID > 0) or (apiCampaignID ~= nil and apiCampaignID > 0) then
                    questType = "CAMPAIGN QUEST"
                elseif isFromWorldWatch then
                    questType = "WORLD/EVENT QUEST"  
                elseif not isComplete and (isFromRegularWatch or isFromWorldWatch) then
                    questType = "ACTIVE TRACKED QUEST"
                end
                
                print(questType .. ": " .. questTitle .. " (ID:" .. questID .. ")")
                print("  QuestInfo.CampaignID: " .. tostring(questInfoCampaignID))
                print("  API.CampaignID: " .. tostring(apiCampaignID))
                print("  IsComplete: " .. tostring(isComplete))
                print("  TrackedViaRegularAPI: " .. tostring(isFromRegularWatch))
                print("  TrackedViaWorldAPI: " .. tostring(isFromWorldWatch))
                print("  WouldShowInTracker: " .. tostring((isFromRegularWatch or isFromWorldWatch) and not isComplete))
                print("  ---")
            end
        end
    end
    
    print("Found " .. foundCampaignQuests .. " campaign quests total")
    print("=== End Campaign Debug Info ===")
end

-- Register the module
WoW95:RegisterModule("QuestTracker", QuestTracker)