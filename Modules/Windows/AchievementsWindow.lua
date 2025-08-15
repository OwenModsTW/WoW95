-- WoW95 Achievements Window Module
-- EXACTLY extracted from original Windows.lua - ALL original code preserved

local addonName, WoW95 = ...

local AchievementsWindow = {}
WoW95.AchievementsWindow = AchievementsWindow

function AchievementsWindow:CreateWindow(frameName, program)
    -- Don't create duplicate windows - show existing one if it exists
    if WoW95.WindowsCore:GetProgramWindow(frameName) then 
        WoW95:Debug("Achievements window already exists, showing it")
        local existingWindow = WoW95.WindowsCore:GetProgramWindow(frameName)
        if not existingWindow:IsShown() then
            existingWindow:Show()
            WoW95:OnWindowOpened(existingWindow)
        end
        return existingWindow
    end
    
    WoW95:Debug("Creating custom Achievements window")
    
    -- Create the main achievements window
    local achievementsWindow = self:CreateCharacterWindow(
        "WoW95Achievements", 
        UIParent, 
        800, 
        600, 
        "Achievements - World of Warcraft"
    )
    
    -- Position window
    achievementsWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Achievement window specific data
    achievementsWindow.currentCategory = nil
    achievementsWindow.categoryButtons = {}
    achievementsWindow.achievementButtons = {}
    
    -- Create summary header
    self:CreateAchievementsSummary(achievementsWindow)
    
    -- Create category panel (left side)
    self:CreateCategoriesPanel(achievementsWindow)
    
    -- Create achievement content panel (right side)
    self:CreateAchievementsPanel(achievementsWindow)
    
    -- Load initial categories
    self:LoadAchievementCategories(achievementsWindow)
    
    -- Set properties for taskbar recognition
    achievementsWindow.programName = program.name
    achievementsWindow.frameName = frameName
    achievementsWindow.isWoW95Window = true
    achievementsWindow.isProgramWindow = true
    
    -- Store reference in WindowsCore
    WoW95.WindowsCore:StoreProgramWindow(frameName, achievementsWindow)
    
    -- Add cleanup hook
    achievementsWindow:HookScript("OnHide", function()
        WoW95:Debug("Achievements window hidden, cleaning up tracking")
        WoW95.WindowsCore:RemoveProgramWindow(frameName)
        -- Ensure the Blizzard frame is also hidden to prevent state mismatch
        local blizzardFrame = _G[frameName]
        if blizzardFrame and blizzardFrame:IsShown() then
            blizzardFrame:Hide()
        end
    end)
    
    -- Show the window
    achievementsWindow:Show()
    
    -- Notify taskbar
    WoW95:OnWindowOpened(achievementsWindow)
    
    return achievementsWindow
end

function AchievementsWindow:CreateCharacterWindow(name, parent, width, height, title)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    
    -- Set size
    frame:SetSize(width or 300, height or 200)
    
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
    
    -- Create title bar
    local titleBar = CreateFrame("Frame", name .. "TitleBar", frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    
    -- Title bar backdrop with our blue color
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- Direct blue color
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText(title or "Window")
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    
    -- Only close button (no lock button)
    local closeButton = WoW95:CreateTitleBarButton(name .. "CloseButton", titleBar, WoW95.textures.close, 16)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    
    -- Close button functionality
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Make window movable
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
    
    return frame
end

function AchievementsWindow:CreateAchievementsSummary(achievementsWindow)
    -- Create summary section at top - ensure it doesn't overlap categories
    local summaryFrame = CreateFrame("Frame", "WoW95AchievementsSummary", achievementsWindow, "BackdropTemplate")
    summaryFrame:SetPoint("TOPLEFT", achievementsWindow, "TOPLEFT", 15, -30)
    summaryFrame:SetPoint("TOPRIGHT", achievementsWindow, "TOPRIGHT", -15, -30)
    summaryFrame:SetHeight(60)
    summaryFrame:SetFrameLevel(achievementsWindow:GetFrameLevel() + 1) -- Lower than buttons
    
    -- Summary background
    summaryFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    summaryFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
    summaryFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Achievement points
    local pointsLabel = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pointsLabel:SetPoint("TOPLEFT", summaryFrame, "TOPLEFT", 10, -10)
    pointsLabel:SetText("Achievement Points:")
    pointsLabel:SetTextColor(0, 0, 0, 1)
    pointsLabel:SetShadowOffset(0, 0)
    
    local totalPoints = GetTotalAchievementPoints()
    local pointsValue = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pointsValue:SetPoint("LEFT", pointsLabel, "RIGHT", 10, 0)
    pointsValue:SetText(totalPoints or 0)
    pointsValue:SetTextColor(0.2, 0.4, 0.8, 1)
    
    -- Recent achievements text
    local recentLabel = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recentLabel:SetPoint("TOPLEFT", pointsLabel, "BOTTOMLEFT", 0, -10)
    recentLabel:SetText("Recent Achievements: Select a category to view achievements")
    recentLabel:SetTextColor(0.3, 0.3, 0.3, 1)
    
    -- Store references
    achievementsWindow.summaryFrame = summaryFrame
    achievementsWindow.pointsValue = pointsValue
end

function AchievementsWindow:CreateCategoriesPanel(achievementsWindow)
    -- Create category list panel (left side)
    local categoryPanel = CreateFrame("Frame", "WoW95AchievementCategories", achievementsWindow, "BackdropTemplate")
    categoryPanel:SetPoint("TOPLEFT", achievementsWindow.summaryFrame, "BOTTOMLEFT", 0, -10)
    categoryPanel:SetPoint("BOTTOMLEFT", achievementsWindow, "BOTTOMLEFT", 15, 15)
    categoryPanel:SetWidth(200)
    categoryPanel:SetFrameLevel(achievementsWindow:GetFrameLevel() + 1)
    
    -- Category panel background
    categoryPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    categoryPanel:SetBackdropColor(1, 1, 1, 1)
    categoryPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Category title
    local categoryTitle = categoryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryTitle:SetPoint("TOP", categoryPanel, "TOP", 0, -8)
    categoryTitle:SetText("Categories")
    categoryTitle:SetTextColor(0, 0, 0, 1)
    categoryTitle:SetShadowOffset(0, 0)
    categoryTitle:SetShadowColor(0, 0, 0, 0)
    
    -- Create simple scrollable category list without template
    local categoryScroll = CreateFrame("ScrollFrame", "WoW95AchievementCategoryScroll", categoryPanel)
    categoryScroll:SetPoint("TOPLEFT", categoryPanel, "TOPLEFT", 5, -25)
    categoryScroll:SetPoint("BOTTOMRIGHT", categoryPanel, "BOTTOMRIGHT", -5, 5)
    categoryScroll:SetFrameLevel(categoryPanel:GetFrameLevel() + 1)
    
    local categoryContent = CreateFrame("Frame", "WoW95AchievementCategoryContent", categoryScroll)
    categoryContent:SetSize(165, 400)
    categoryContent:SetFrameLevel(categoryScroll:GetFrameLevel() + 1)
    categoryScroll:SetScrollChild(categoryContent)
    
    -- Disable mouse events on scroll frame but allow them on content
    categoryScroll:EnableMouse(false)
    categoryScroll:SetMouseClickEnabled(false)
    categoryContent:EnableMouse(true) -- Must allow mouse events for buttons
    
    -- Add simple mouse wheel scrolling
    categoryPanel:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = categoryScroll:GetVerticalScroll()
        local maxScroll = math.max(0, categoryContent:GetHeight() - categoryScroll:GetHeight())
        local newScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * 20)))
        categoryScroll:SetVerticalScroll(newScroll)
    end)
    categoryPanel:EnableMouseWheel(true)
    
    achievementsWindow.categoryPanel = categoryPanel
    achievementsWindow.categoryScroll = categoryScroll
    achievementsWindow.categoryContent = categoryContent
end

function AchievementsWindow:CreateAchievementsPanel(achievementsWindow)
    -- Create achievement display panel (right side) - ensure it doesn't overlap category buttons
    local achievementPanel = CreateFrame("Frame", "WoW95AchievementDisplay", achievementsWindow, "BackdropTemplate")
    achievementPanel:SetPoint("TOPLEFT", achievementsWindow.categoryPanel, "TOPRIGHT", 10, 0)
    achievementPanel:SetPoint("BOTTOMRIGHT", achievementsWindow, "BOTTOMRIGHT", -15, 15)
    
    -- Ensure this panel doesn't block mouse events for category buttons
    achievementPanel:SetFrameLevel(achievementsWindow:GetFrameLevel() + 1) -- Lower than buttons
    
    -- Achievement panel background
    achievementPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    achievementPanel:SetBackdropColor(1, 1, 1, 1)
    achievementPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Search box
    local searchFrame = CreateFrame("Frame", nil, achievementPanel, "BackdropTemplate")
    searchFrame:SetPoint("TOPLEFT", achievementPanel, "TOPLEFT", 10, -10)
    searchFrame:SetPoint("TOPRIGHT", achievementPanel, "TOPRIGHT", -10, -10)
    searchFrame:SetHeight(25)
    searchFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    searchFrame:SetBackdropColor(0.95, 0.95, 0.95, 1)
    searchFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Search label
    local searchLabel = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("LEFT", searchFrame, "LEFT", 5, 0)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(0, 0, 0, 1)
    searchLabel:SetShadowOffset(0, 0)
    
    -- Search edit box
    local searchBox = CreateFrame("EditBox", "WoW95AchievementSearchBox", searchFrame, "BackdropTemplate")
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetPoint("RIGHT", searchFrame, "RIGHT", -80, 0)
    searchBox:SetHeight(18)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    searchBox:SetTextColor(0, 0, 0, 1)
    searchBox:SetShadowOffset(0, 0)
    searchBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    searchBox:SetBackdropColor(1, 1, 1, 1)
    searchBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Search button
    local searchButton = WoW95:CreateButton("WoW95SearchBtn", searchFrame, 60, 18, "Search")
    searchButton:SetPoint("RIGHT", searchFrame, "RIGHT", -5, 0)
    
    -- Clear button
    local clearButton = WoW95:CreateButton("WoW95ClearBtn", searchFrame, 50, 18, "Clear")
    clearButton:SetPoint("RIGHT", searchButton, "LEFT", -5, 0)
    
    -- Category title
    local categoryTitle = achievementPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    categoryTitle:SetPoint("TOPLEFT", searchFrame, "BOTTOMLEFT", 0, -10)
    categoryTitle:SetText("Select a category")
    categoryTitle:SetTextColor(0, 0, 0, 1)
    categoryTitle:SetShadowOffset(0, 0)
    
    -- Create scrollable achievement list
    local achievementScroll = CreateFrame("ScrollFrame", "WoW95AchievementScroll", achievementPanel, "UIPanelScrollFrameTemplate")
    achievementScroll:SetPoint("TOPLEFT", categoryTitle, "BOTTOMLEFT", 0, -10)
    achievementScroll:SetPoint("BOTTOMRIGHT", achievementPanel, "BOTTOMRIGHT", -25, 5)
    
    local achievementContent = CreateFrame("Frame", "WoW95AchievementContent", achievementScroll)
    achievementContent:SetWidth(achievementPanel:GetWidth() - 35)
    achievementContent:SetHeight(400)
    achievementScroll:SetScrollChild(achievementContent)
    
    -- Search functionality
    searchButton:SetScript("OnClick", function()
        local searchTerm = searchBox:GetText()
        if searchTerm and searchTerm:len() > 0 then
            self:SearchAchievements(achievementsWindow, searchTerm)
        end
    end)
    
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        -- Return to category view
        if achievementsWindow.currentCategory then
            self:LoadCategoryAchievements(achievementsWindow, achievementsWindow.currentCategory)
        end
    end)
    
    -- Enter key to search
    searchBox:SetScript("OnEnterPressed", function()
        local searchTerm = searchBox:GetText()
        if searchTerm and searchTerm:len() > 0 then
            self:SearchAchievements(achievementsWindow, searchTerm)
        end
    end)
    
    achievementsWindow.achievementPanel = achievementPanel
    achievementsWindow.achievementScroll = achievementScroll
    achievementsWindow.achievementContent = achievementContent
    achievementsWindow.categoryTitle = categoryTitle
    achievementsWindow.searchBox = searchBox
end

function AchievementsWindow:LoadAchievementCategories(achievementsWindow)
    WoW95:Debug("Loading achievement categories...")
    
    -- Clear existing category buttons
    for _, button in pairs(achievementsWindow.categoryButtons) do
        button:Hide()
    end
    achievementsWindow.categoryButtons = {}
    achievementsWindow.expandedCategories = achievementsWindow.expandedCategories or {}
    
    -- Get category list
    local categories = GetCategoryList()
    if not categories then
        WoW95:Debug("No categories found")
        return
    end
    
    local yOffset = 0
    local buttonIndex = 0
    
    -- Function to create subcategory buttons
    local function CreateSubcategoryButtons(parentID, parentName, startY)
        local subY = startY
        local subcategoryCount = 0
        
        for _, subCategoryID in ipairs(categories) do
            local subCategoryName, subParentID, flags = GetCategoryInfo(subCategoryID)
            if subCategoryName and subParentID == parentID then
                local subButton = self:CreateCategoryButton(achievementsWindow, subCategoryID, "  " .. subCategoryName, subY)
                subButton.isSubcategory = true
                subButton.parentCategory = parentID
                
                -- Apply grey styling for subcategories after creation
                self:ApplyCategoryButtonStyling(subButton)
                table.insert(achievementsWindow.categoryButtons, subButton)
                subY = subY + 35
                subcategoryCount = subcategoryCount + 1
            end
        end
        
        return subY, subcategoryCount
    end
    
    for i, categoryID in ipairs(categories) do
        local categoryName, parentID, flags = GetCategoryInfo(categoryID)
        
        if categoryName and parentID == -1 then -- Only show top-level categories
            buttonIndex = buttonIndex + 1
            WoW95:Debug("Creating button #" .. buttonIndex .. ": " .. categoryName .. " at yOffset " .. yOffset .. " (categoryID: " .. categoryID .. ")")
            
            -- Check if category has subcategories
            local hasSubcategories = false
            for _, subCategoryID in ipairs(categories) do
                local subCategoryName, subParentID, flags = GetCategoryInfo(subCategoryID)
                if subCategoryName and subParentID == categoryID then
                    hasSubcategories = true
                    break
                end
            end
            
            local buttonText = categoryName
            if hasSubcategories then
                buttonText = (achievementsWindow.expandedCategories[categoryID] and "- " or "+ ") .. categoryName
            end
            
            local button = self:CreateCategoryButton(achievementsWindow, categoryID, buttonText, yOffset)
            button.hasSubcategories = hasSubcategories
            button.originalName = categoryName
            button.isMainCategory = true -- Mark as main category for styling
            button.buttonIndex = buttonIndex -- For debugging
            
            -- Apply blue styling for main categories after creation
            self:ApplyCategoryButtonStyling(button)
            
            -- Special click handler for expandable categories
            if hasSubcategories then
                button:SetScript("OnClick", function(buttonSelf, mouseButton)
                    WoW95:Debug("Expandable category button clicked: " .. categoryName)
                    
                    -- Toggle expansion
                    achievementsWindow.expandedCategories[categoryID] = not achievementsWindow.expandedCategories[categoryID]
                    
                    -- Reload categories to show/hide subcategories
                    self:LoadAchievementCategories(achievementsWindow)
                end)
            end
            
            table.insert(achievementsWindow.categoryButtons, button)
            yOffset = yOffset + 35
            
            -- Add subcategories if expanded
            if hasSubcategories and achievementsWindow.expandedCategories[categoryID] then
                local newY, subCount = CreateSubcategoryButtons(categoryID, categoryName, yOffset)
                yOffset = newY
            end
        end
    end
    
    -- Update content height
    achievementsWindow.categoryContent:SetHeight(math.max(400, yOffset + 20))
    
    WoW95:Debug("Loaded " .. #achievementsWindow.categoryButtons .. " categories")
end

function AchievementsWindow:CreateCategoryButton(achievementsWindow, categoryID, categoryName, yOffset)
    -- Create button inside the category content frame where it belongs
    local button = CreateFrame("Button", "WoW95CategoryBtn" .. categoryID .. "_" .. math.random(10000), achievementsWindow.categoryContent, "BackdropTemplate")
    button:SetSize(160, 25) -- Proper size to fit in category panel
    
    -- Position within the category content frame
    button:SetPoint("TOPLEFT", achievementsWindow.categoryContent, "TOPLEFT", 5, -yOffset)
    
    -- Ensure proper frame level for clicking
    button:SetFrameLevel(achievementsWindow.categoryContent:GetFrameLevel() + 10)
    
    -- Explicitly enable mouse events
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    
    WoW95:Debug("Created button: " .. categoryName .. " in category content at position (5, " .. (-yOffset) .. ") size 160x25")
    
    -- Set button backdrop (default grey - will be overridden for main categories)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    button:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    button:SetBackdropBorderColor(unpack(WoW95.colors.buttonShadow))
    
    -- Create button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    buttonText:SetText(categoryName)
    buttonText:SetTextColor(0, 0, 0, 1)
    buttonText:SetShadowOffset(0, 0)
    buttonText:SetShadowColor(0, 0, 0, 0)
    button.text = buttonText
    
    -- Store category ID
    button.categoryID = categoryID
    
    -- Set default click handler (will be overridden for expandable categories)
    button:SetScript("OnClick", function(buttonSelf, mouseButton)
        WoW95:Debug("=== CATEGORY BUTTON CLICK DEBUG ===")
        WoW95:Debug("Button: " .. categoryName)
        WoW95:Debug("Category ID: " .. categoryID)
        WoW95:Debug("Mouse Button: " .. tostring(mouseButton))
        WoW95:Debug("Has Subcategories: " .. tostring(button.hasSubcategories))
        WoW95:Debug("Is Subcategory: " .. tostring(button.isSubcategory))
        
        -- Only load achievements if this isn't an expandable category or is a subcategory
        if not button.hasSubcategories or button.isSubcategory then
            WoW95:Debug("Loading achievements for category: " .. categoryName)
            -- Use 'self' which refers to the AchievementsWindow object, not the button
            local success, err = pcall(self.SelectAchievementCategory, self, achievementsWindow, categoryID, categoryName)
            if not success then
                WoW95:Debug("ERROR in SelectAchievementCategory: " .. tostring(err))
                print("WoW95 Error: " .. tostring(err))
            end
            
            -- Visual feedback - highlight selected button
            for _, btn in pairs(achievementsWindow.categoryButtons) do
                if btn.highlight then
                    btn.highlight:Hide()
                end
            end
            
            if not button.highlight then
                button.highlight = button:CreateTexture(nil, "OVERLAY")
                button.highlight:SetAllPoints()
                button.highlight:SetColorTexture(0.3, 0.3, 0.7, 0.3)
            end
            button.highlight:Show()
        else
            WoW95:Debug("This is an expandable category, not loading achievements")
        end
    end)
    
    -- Add hover effects for better feedback
    button:SetScript("OnEnter", function(self)
        if not self.highlight or not self.highlight:IsShown() then
            if not self.hoverHighlight then
                self.hoverHighlight = self:CreateTexture(nil, "HIGHLIGHT")
                self.hoverHighlight:SetAllPoints()
                self.hoverHighlight:SetColorTexture(0.7, 0.7, 0.9, 0.3)
            end
            self.hoverHighlight:Show()
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        if self.hoverHighlight then
            self.hoverHighlight:Hide()
        end
    end)
    
    return button
end

function AchievementsWindow:ApplyCategoryButtonStyling(button)
    if button.isMainCategory then
        -- Main category headers: Windows 95 blue background with white text
        button:SetBackdropColor(unpack(WoW95.colors.titleBar))
        button:SetBackdropBorderColor(0.2, 0.2, 0.4, 1)
        
        -- Style button text to white
        if button.text then
            button.text:SetTextColor(1, 1, 1, 1) -- White text
            button.text:SetShadowColor(0, 0, 0, 0) -- No shadow
        end
    else
        -- Subcategory buttons: Keep default grey styling
        -- Default grey background is already set in CreateCategoryButton
        
        -- Ensure text is black for subcategories
        if button.text then
            button.text:SetTextColor(0, 0, 0, 1) -- Black text
            button.text:SetShadowOffset(0, 0)
            button.text:SetShadowColor(0, 0, 0, 0) -- No shadow
        end
    end
end

function AchievementsWindow:SelectAchievementCategory(achievementsWindow, categoryID, categoryName)
    WoW95:Debug("Selected category: " .. categoryName .. " (" .. categoryID .. ")")
    
    achievementsWindow.currentCategory = categoryID
    achievementsWindow.categoryTitle:SetText(categoryName)
    
    -- Load achievements for this category
    self:LoadCategoryAchievements(achievementsWindow, categoryID)
end

function AchievementsWindow:LoadCategoryAchievements(achievementsWindow, categoryID)
    WoW95:Debug("Loading achievements for category: " .. categoryID)
    
    -- Add error handling for problematic categories
    local categoryName = GetCategoryInfo(categoryID)
    if categoryName then
        WoW95:Debug("Category name: " .. categoryName)
    else
        WoW95:Debug("ERROR: Could not get category name for ID: " .. categoryID)
        return
    end
    
    -- Clear existing achievement buttons
    for _, button in pairs(achievementsWindow.achievementButtons) do
        button:Hide()
    end
    achievementsWindow.achievementButtons = {}
    
    local yOffset = 10
    local achievementCount = 0
    
    -- Function to load achievements from a category (including ALL nested subcategories)
    local function LoadAchievementsFromCategory(catID, depth)
        depth = depth or 0
        local indent = string.rep("  ", depth)
        
        local numAchievements = GetCategoryNumAchievements(catID)
        if not numAchievements then
            WoW95:Debug(indent .. "ERROR: GetCategoryNumAchievements returned nil for category " .. catID)
            return
        end
        WoW95:Debug(indent .. "Category " .. catID .. " has " .. numAchievements .. " direct achievements")
        
        -- Load direct achievements from this category
        if numAchievements and numAchievements > 0 then
            for i = 1, numAchievements do
                local success, achievementID, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = pcall(GetAchievementInfo, catID, i)
                
                if success and achievementID and name then
                    WoW95:Debug(indent .. "  - Found achievement: " .. name .. " (ID: " .. achievementID .. ")")
                    local button = self:CreateAchievementButton(achievementsWindow, achievementID, name, points, completed, description, icon, yOffset)
                    table.insert(achievementsWindow.achievementButtons, button)
                    yOffset = yOffset + 80
                    achievementCount = achievementCount + 1
                end
            end
        end
        
        -- Recursively load from ALL subcategories (this ensures we get everything)
        local categories = GetCategoryList()
        if categories then
            for _, subCategoryID in ipairs(categories) do
                local subCategoryName, parentID, flags = GetCategoryInfo(subCategoryID)
                if parentID == catID then
                    WoW95:Debug(indent .. "Found subcategory: " .. (subCategoryName or "Unknown") .. " (ID: " .. subCategoryID .. ")")
                    LoadAchievementsFromCategory(subCategoryID, depth + 1)
                end
            end
        end
    end
    
    -- Load achievements from main category and subcategories
    LoadAchievementsFromCategory(categoryID)
    
    -- If no achievements found, show a message
    if achievementCount == 0 then
        local noAchievements = CreateFrame("Frame", nil, achievementsWindow.achievementContent, "BackdropTemplate")
        noAchievements:SetSize(achievementsWindow.achievementContent:GetWidth() - 20, 60)
        noAchievements:SetPoint("TOPLEFT", achievementsWindow.achievementContent, "TOPLEFT", 10, -yOffset)
        noAchievements:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        noAchievements:SetBackdropColor(0.95, 0.95, 0.95, 1)
        noAchievements:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        local noAchievementsText = noAchievements:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noAchievementsText:SetPoint("CENTER", noAchievements, "CENTER", 0, 0)
        noAchievementsText:SetText("No achievements found in this category")
        noAchievementsText:SetTextColor(0.5, 0.5, 0.5, 1)
        
        table.insert(achievementsWindow.achievementButtons, noAchievements)
        yOffset = yOffset + 80
    end
    
    -- Update content height
    achievementsWindow.achievementContent:SetHeight(math.max(400, yOffset + 20))
    
    WoW95:Debug("Loaded " .. achievementCount .. " achievements from category and subcategories")
end

function AchievementsWindow:CreateAchievementButton(achievementsWindow, achievementID, name, points, completed, description, icon, yOffset)
    -- Create achievement button frame
    local button = CreateFrame("Frame", "WoW95Achievement" .. achievementID, achievementsWindow.achievementContent, "BackdropTemplate")
    button:SetSize(achievementsWindow.achievementContent:GetWidth() - 20, 70)
    button:SetPoint("TOPLEFT", achievementsWindow.achievementContent, "TOPLEFT", 10, -yOffset)
    
    -- Achievement background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    
    -- Different colors for completed/incomplete
    if completed then
        button:SetBackdropColor(0.9, 0.95, 0.8, 1) -- Light green for completed
    else
        button:SetBackdropColor(0.95, 0.95, 0.95, 1) -- Light gray for incomplete
    end
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Achievement icon
    local iconTexture = button:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(48, 48)
    iconTexture:SetPoint("LEFT", button, "LEFT", 8, 0)
    if icon then
        iconTexture:SetTexture(icon)
    end
    
    -- Achievement name
    local nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", iconTexture, "TOPRIGHT", 8, -2)
    nameText:SetPoint("TOPRIGHT", button, "TOPRIGHT", -80, -2)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(name)
    nameText:SetTextColor(0, 0, 0, 1)
    nameText:SetShadowOffset(0, 0)
    nameText:SetShadowColor(0, 0, 0, 0)
    
    -- Achievement points
    local pointsText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pointsText:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -5)
    pointsText:SetText(points .. " points")
    pointsText:SetTextColor(0.2, 0.4, 0.8, 1)
    pointsText:SetShadowColor(0, 0, 0, 0)
    
    -- Achievement description
    local descText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
    descText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 8)
    descText:SetJustifyH("LEFT")
    descText:SetJustifyV("TOP")
    descText:SetText(description or "")
    descText:SetTextColor(0.3, 0.3, 0.3, 1)
    descText:SetShadowColor(0, 0, 0, 0)
    
    -- Completed checkmark
    if completed then
        local checkmark = button:CreateTexture(nil, "OVERLAY")
        checkmark:SetSize(24, 24)
        checkmark:SetPoint("TOPRIGHT", pointsText, "BOTTOMRIGHT", 0, -2)
        checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    end
    
    return button
end

function AchievementsWindow:SearchAchievements(achievementsWindow, searchTerm)
    WoW95:Debug("Searching achievements for: " .. searchTerm)
    
    -- Clear existing achievement buttons
    for _, button in pairs(achievementsWindow.achievementButtons) do
        button:Hide()
    end
    achievementsWindow.achievementButtons = {}
    
    -- Update title to show search mode
    achievementsWindow.categoryTitle:SetText("Search Results: \"" .. searchTerm .. "\"")
    
    local yOffset = 10
    local resultCount = 0
    searchTerm = searchTerm:lower()
    
    -- Search through all achievements across all categories
    local categories = GetCategoryList()
    if categories then
        for _, categoryID in ipairs(categories) do
            local numAchievements = GetCategoryNumAchievements(categoryID)
            if numAchievements and numAchievements > 0 then
                for i = 1, numAchievements do
                    local success, achievementID, name, points, completed, month, day, year, description, flags, icon = pcall(GetAchievementInfo, categoryID, i)
                    
                    if success and achievementID and name then
                        -- Check if search term matches name or description
                        local nameMatch = name:lower():find(searchTerm, 1, true)
                        local descMatch = description and description:lower():find(searchTerm, 1, true)
                        
                        if nameMatch or descMatch then
                            local button = self:CreateAchievementButton(achievementsWindow, achievementID, name, points, completed, description, icon, yOffset)
                            table.insert(achievementsWindow.achievementButtons, button)
                            yOffset = yOffset + 80
                            resultCount = resultCount + 1
                        end
                    end
                end
            end
        end
    end
    
    -- If no results found, show message
    if resultCount == 0 then
        local noResults = CreateFrame("Frame", nil, achievementsWindow.achievementContent, "BackdropTemplate")
        noResults:SetSize(achievementsWindow.achievementContent:GetWidth() - 20, 60)
        noResults:SetPoint("TOPLEFT", achievementsWindow.achievementContent, "TOPLEFT", 10, -yOffset)
        noResults:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        noResults:SetBackdropColor(0.95, 0.95, 0.95, 1)
        noResults:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        local noResultsText = noResults:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noResultsText:SetPoint("CENTER", noResults, "CENTER", 0, 0)
        noResultsText:SetText("No achievements found matching: \"" .. searchTerm .. "\"")
        noResultsText:SetTextColor(0.5, 0.5, 0.5, 1)
        
        table.insert(achievementsWindow.achievementButtons, noResults)
        yOffset = yOffset + 80
    end
    
    -- Update content height
    achievementsWindow.achievementContent:SetHeight(math.max(400, yOffset + 20))
    
    WoW95:Debug("Search completed: " .. resultCount .. " results found")
end

-- Register the module
WoW95:RegisterModule("AchievementsWindow", AchievementsWindow)