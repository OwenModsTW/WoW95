-- WoW95 Action Bars Module
-- Dynamic container system with custom icon placement

local addonName, WoW95 = ...

local ActionBars = {}
WoW95.ActionBars = ActionBars

-- Action Bar settings
local ACTIONBAR_WIDTH = 498  -- 12 buttons * 36px + padding
local ACTIONBAR_ROW_HEIGHT = 40  -- Height per row of buttons
local TITLE_BAR_HEIGHT = 18
local BUTTON_SIZE = 36
local BUTTON_SPACING = 3
local CONTAINER_PADDING = 6

-- Action Bar state
ActionBars.mainContainer = nil
ActionBars.bars = {}
ActionBars.enabledBars = {"third", "second", "main"}  -- Reverse order: third on top, main on bottom
ActionBars.separateBars = {}  -- Bars 4+ as separate windows
ActionBars.currentPage = 1
ActionBars.maxPage = 6
ActionBars.locked = false  -- Lock state for movement

-- Bar configurations (WoW has 8 action bars total)
ActionBars.barConfigs = {
    {id = "main", blizzardButtons = "ActionButton", title = "Action Bar 1", cvar = nil}, -- Always visible
    {id = "second", blizzardButtons = "MultiBarBottomLeftButton", title = "Action Bar 2", cvar = "multiBarBottomLeft"},
    {id = "third", blizzardButtons = "MultiBarBottomRightButton", title = "Action Bar 3", cvar = "multiBarBottomRight"},
    {id = "fourth", blizzardButtons = "MultiBarRightButton", title = "Action Bar 4", cvar = "multiBarRight"},
    {id = "fifth", blizzardButtons = "MultiBarLeftButton", title = "Action Bar 5", cvar = "multiBarLeft"},
    {id = "sixth", blizzardButtons = "MultiBar5Button", title = "Action Bar 6", cvar = "multiBar5"},
    {id = "seventh", blizzardButtons = "MultiBar6Button", title = "Action Bar 7", cvar = "multiBar6"},
    {id = "eighth", blizzardButtons = "MultiBar7Button", title = "Action Bar 8", cvar = "multiBar7"},
}

function ActionBars:Init()
    WoW95:Debug("Initializing Action Bars module...")
    
    -- IMMEDIATELY hook Edit Mode before doing anything else
    self:HookEditModeImmediate()
    
    -- DETECT enabled bars BEFORE hiding Blizzard frames
    local function IsBarEnabled(cvarName, frameName)
        -- Method 1: Try CVar first
        local cvarValue = C_CVar and C_CVar.GetCVar(cvarName) or GetCVar(cvarName)
        if cvarValue and cvarValue ~= "" then
            WoW95:Debug("CVar " .. cvarName .. " = " .. tostring(cvarValue))
            return cvarValue == "1"
        end
        
        -- Method 2: Check if the frame is shown (before we hide it)
        local frame = _G[frameName]
        if frame then
            local isShown = frame:IsShown()
            WoW95:Debug("Frame " .. frameName .. " shown = " .. tostring(isShown))
            if isShown then return true end
        end
        
        -- Method 3: Check if individual buttons exist and are shown
        local button1 = _G[frameName .. "Button1"]
        if button1 then
            local buttonShown = button1:IsShown()
            WoW95:Debug("Button " .. frameName .. "Button1 shown = " .. tostring(buttonShown))
            if buttonShown then return true end
        end
        
        -- Method 4: Assume enabled if we can't determine (safer default for bars 2&3)
        if cvarName == "multiBarBottomLeft" or cvarName == "multiBarBottomRight" then
            WoW95:Debug("Assuming " .. cvarName .. " is enabled (default)")
            return true
        end
        
        return false
    end
    
    local bar3Enabled = IsBarEnabled("multiBarBottomRight", "MultiBarBottomRight")
    local bar2Enabled = IsBarEnabled("multiBarBottomLeft", "MultiBarBottomLeft")
    
    WoW95:Debug("Final detection - Bar 2 enabled: " .. tostring(bar2Enabled))
    WoW95:Debug("Final detection - Bar 3 enabled: " .. tostring(bar3Enabled))
    
    -- NOW hide all Blizzard action bars after detection
    self:HideBlizzardActionBars()
    
    -- Create the main dynamic container
    self:CreateMainContainer()
    
    -- Enable and create the bars that are actually enabled
    -- Build enabledBars in visual order: top to bottom (third, second, main)
    self.enabledBars = {}
    local barsToCreate = {}
    
    if bar3Enabled then
        table.insert(self.enabledBars, "third")
        table.insert(barsToCreate, {id = "third", config = self:GetBarConfig("third")})
    end
    
    if bar2Enabled then
        table.insert(self.enabledBars, "second") 
        table.insert(barsToCreate, {id = "second", config = self:GetBarConfig("second")})
    end
    
    -- Main bar is always last (bottom)
    table.insert(self.enabledBars, "main")
    table.insert(barsToCreate, {id = "main", config = self:GetBarConfig("main")})
    
    -- Create all the bars
    for _, barInfo in ipairs(barsToCreate) do
        self:CreateActionBarRow(barInfo.id, barInfo.config)
    end
    
    -- Check for additional enabled bars and create separate windows
    self:CheckForAdditionalBars()
    
    -- Update container size
    self:UpdateContainerSize()
    
    -- Create page switcher
    self:CreatePageSwitcher()
    
    -- Hook action bar events
    self:HookActionBarEvents()
    
    -- Hook CVar changes to dynamically update bars
    self:HookCVarChanges()
    
    -- Ensure Edit Mode compatibility
    C_Timer.After(1, function()
        self:EnsureEditModeCompatibility()
    end)
    
    -- Delayed check for bars 2 and 3 since CVars might not be available immediately
    C_Timer.After(0.5, function()
        self:CheckAndEnableMissingBars()
    end)
    
    -- Additional rebuild checks at increasing intervals to catch late-loading bars
    C_Timer.After(2, function()
        local visibleBars = 0
        for barId, row in pairs(self.bars) do
            if row and row:IsShown() then
                visibleBars = visibleBars + 1
            end
        end
        
        if visibleBars < 3 then -- If we're missing bars that should be enabled
            WoW95:Print("Action bars incomplete - performing rebuild...")
            self:RebuildMainContainer()
        end
    end)
    
    -- Final check after UI is fully stabilized
    C_Timer.After(5, function()
        self:RebuildMainContainer()
        WoW95:Debug("Final action bar rebuild completed")
    end)
    
    WoW95:Debug("Action Bars initialized successfully!")
end

-- Try multiple methods to get CVar value
function ActionBars:GetCVarValue(cvarName)
    -- Method 1: C_CVar API
    if C_CVar and C_CVar.GetCVar then
        local value = C_CVar.GetCVar(cvarName)
        if value ~= nil and value ~= "" then
            return value
        end
    end
    
    -- Method 2: Legacy GetCVar
    if GetCVar then
        local value = GetCVar(cvarName)
        if value ~= nil and value ~= "" then
            return value
        end
    end
    
    -- Method 3: Try GetCVarBool for boolean CVars
    if GetCVarBool then
        local success, value = pcall(GetCVarBool, cvarName)
        if success then
            return value and "1" or "0"
        end
    end
    
    -- Method 4: Try to access Settings API
    if Settings and Settings.GetValue then
        local success, value = pcall(Settings.GetValue, cvarName)
        if success and value ~= nil then
            return tostring(value)
        end
    end
    
    return nil
end

-- Robust bar detection method used by periodic checker
function ActionBars:IsBarEnabled(cvarName, frameName)
    -- Method 1: Try all CVar methods
    local cvarValue = self:GetCVarValue(cvarName)
    if cvarValue ~= nil then
        return cvarValue == "1" or cvarValue == true or cvarValue == "true"
    end
    
    -- Method 2: Check if the Blizzard frame exists and has been configured
    local frame = _G[frameName]
    if frame then
        -- Some frames have a special "ShouldShow" method
        if frame.ShouldShow then
            local success, shouldShow = pcall(frame.ShouldShow, frame)
            if success then
                return shouldShow
            end
        end
        
        -- Check if the frame is marked as visible (before we hide it)
        if frame.IsShown and frame:IsShown() then
            return true
        end
    end
    
    -- Method 3: Check individual action buttons
    local button1 = _G[frameName .. "Button1"]
    if button1 then
        -- If the button exists and is configured, the bar is probably enabled
        if button1:IsShown() then
            return true
        end
        
        -- Check if the button has actions assigned (indicates the bar is in use)
        if button1.action and HasAction(button1.action) then
            return true
        end
    end
    
    -- Method 4: For these specific bars, try some heuristics
    if cvarName == "multiBarBottomLeft" or cvarName == "multiBarBottomRight" then
        -- Check if our own bars think they should be enabled
        for _, barId in ipairs(self.enabledBars or {}) do
            if (barId == "second" and cvarName == "multiBarBottomLeft") or
               (barId == "third" and cvarName == "multiBarBottomRight") then
                return true
            end
        end
    end
    
    -- Default to false if we can't determine
    return false
end

function ActionBars:CheckAndEnableMissingBars()
    WoW95:Debug("Checking for missing bars 2 and 3...")
    
    -- Check if bars 2 and 3 should be enabled but aren't in our list
    local hasBar2 = tContains(self.enabledBars, "second")
    local hasBar3 = tContains(self.enabledBars, "third")
    
    local needsRebuild = false
    
    -- Check bar 2 - use the same simple detection method that works for separate bars
    if not hasBar2 then
        local bar2Enabled = false
        local cvar2 = C_CVar and C_CVar.GetCVar("multiBarBottomLeft") or GetCVar("multiBarBottomLeft")
        if cvar2 and cvar2 ~= "" then
            bar2Enabled = (cvar2 == "1")
        else
            -- Fallback: Check if frame is shown
            local frame2 = _G["MultiBarBottomLeft"]
            if frame2 then
                bar2Enabled = frame2:IsShown()
            end
        end
        
        if bar2Enabled then
            WoW95:Debug("Bar 2 is enabled but missing - adding it")
            needsRebuild = true
        end
    end
    
    -- Check bar 3 - use the same simple detection method that works for separate bars
    if not hasBar3 then
        local bar3Enabled = false
        local cvar3 = C_CVar and C_CVar.GetCVar("multiBarBottomRight") or GetCVar("multiBarBottomRight")
        if cvar3 and cvar3 ~= "" then
            bar3Enabled = (cvar3 == "1")
        else
            -- Fallback: Check if frame is shown
            local frame3 = _G["MultiBarBottomRight"]
            if frame3 then
                bar3Enabled = frame3:IsShown()
            end
        end
        
        if bar3Enabled then
            WoW95:Debug("Bar 3 is enabled but missing - adding it")
            needsRebuild = true
        end
    end
    
    -- If we need to rebuild, do it
    if needsRebuild then
        self:RebuildMainContainer()
    end
end

function ActionBars:RebuildMainContainer()
    WoW95:Debug("Rebuilding main container with all enabled bars...")
    
    -- Clear existing bars
    for barId, bar in pairs(self.bars) do
        if bar and bar.iconSlots then
            for _, slot in pairs(bar.iconSlots) do
                if slot then
                    slot:Hide()
                    if slot.updateFrame then
                        slot.updateFrame:SetScript("OnUpdate", nil)
                    end
                end
            end
        end
        if bar then
            bar:Hide()
        end
    end
    self.bars = {}
    
    -- Rebuild enabledBars list properly
    self.enabledBars = {}
    local barsToCreate = {}
    
    -- Use the same simple detection method that works for separate bars
    local bar2Enabled = false
    local bar3Enabled = false
    
    -- Bar 2 detection
    local cvar2 = C_CVar and C_CVar.GetCVar("multiBarBottomLeft") or GetCVar("multiBarBottomLeft")
    if cvar2 and cvar2 ~= "" then
        bar2Enabled = (cvar2 == "1")
    else
        -- Fallback: Check if frame is shown
        local frame2 = _G["MultiBarBottomLeft"]
        if frame2 then
            bar2Enabled = frame2:IsShown()
        end
    end
    
    -- Bar 3 detection  
    local cvar3 = C_CVar and C_CVar.GetCVar("multiBarBottomRight") or GetCVar("multiBarBottomRight")
    if cvar3 and cvar3 ~= "" then
        bar3Enabled = (cvar3 == "1")
    else
        -- Fallback: Check if frame is shown
        local frame3 = _G["MultiBarBottomRight"]
        if frame3 then
            bar3Enabled = frame3:IsShown()
        end
    end
    
    WoW95:Debug("Rebuild detection - Bar 2: " .. tostring(bar2Enabled) .. ", Bar 3: " .. tostring(bar3Enabled))
    
    -- Build in correct visual order
    if bar3Enabled then
        table.insert(self.enabledBars, "third")
        table.insert(barsToCreate, {id = "third", config = self:GetBarConfig("third")})
    end
    
    if bar2Enabled then
        table.insert(self.enabledBars, "second")
        table.insert(barsToCreate, {id = "second", config = self:GetBarConfig("second")})
    end
    
    -- Main bar always last
    table.insert(self.enabledBars, "main")
    table.insert(barsToCreate, {id = "main", config = self:GetBarConfig("main")})
    
    -- Create all bars
    for _, barInfo in ipairs(barsToCreate) do
        self:CreateActionBarRow(barInfo.id, barInfo.config)
    end
    
    -- Update container size
    self:UpdateContainerSize()
    
    WoW95:Debug("Main container rebuilt with bars: " .. table.concat(self.enabledBars, ", "))
end

function ActionBars:CreateMainContainer()
    -- Main container window that grows dynamically
    self.mainContainer = CreateFrame("Frame", "WoW95ActionBarContainer", UIParent, "BackdropTemplate")
    self.mainContainer:SetFrameStrata("MEDIUM")
    self.mainContainer:SetMovable(true)
    self.mainContainer:SetClampedToScreen(true)
    
    -- Load saved position or use default
    if WoW95DB and WoW95DB.actionBarPositions and WoW95DB.actionBarPositions.main then
        local pos = WoW95DB.actionBarPositions.main
        self.mainContainer:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position above taskbar
        local taskbarFrame = WoW95.Taskbar and WoW95.Taskbar.frame
        if taskbarFrame then
            self.mainContainer:SetPoint("BOTTOM", taskbarFrame, "TOP", 0, 2)
        else
            self.mainContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 32)
        end
    end
    
    -- Container backdrop (translucent)
    self.mainContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.mainContainer:SetBackdropColor(0.75, 0.75, 0.75, 0.3) -- Very translucent
    self.mainContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8) -- Slightly visible border
    
    -- Shared title bar for bars 1-3
    local titleBar = CreateFrame("Frame", "WoW95ActionBarContainerTitle", self.mainContainer, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", self.mainContainer, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", self.mainContainer, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(TITLE_BAR_HEIGHT)
    
    -- Make title bar draggable (only if not locked)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not self.locked then
            self.mainContainer:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        self.mainContainer:StopMovingOrSizing()
        self:SavePosition("main", self.mainContainer)
    end)
    
    -- Title bar backdrop (Windows 95 blue)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(unpack(WoW95.colors.titleBar))
    titleBar:SetBackdropBorderColor(unpack(WoW95.colors.windowFrame))
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText("Action Bars - Page " .. self.currentPage)
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Content area for action bars
    local contentArea = CreateFrame("Frame", "WoW95ActionBarContent", self.mainContainer)
    contentArea:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -2)
    contentArea:SetPoint("BOTTOMRIGHT", self.mainContainer, "BOTTOMRIGHT", -2, 2)
    
    -- Store references
    self.mainContainer.titleBar = titleBar
    self.mainContainer.titleText = titleText
    self.mainContainer.contentArea = contentArea
end

function ActionBars:EnableActionBar(barId)
    local config = self:GetBarConfig(barId)
    if not config then return end
    
    -- Enable the corresponding Blizzard CVar if needed (only out of combat)
    if config.cvar and not InCombatLockdown() then
        SetCVar(config.cvar, 1)
    end
    
    -- Create the bar in the main container
    self:CreateActionBarRow(barId, config)
    
    -- Add to enabled bars if not already present
    if not tContains(self.enabledBars, barId) then
        table.insert(self.enabledBars, barId)
    end
    
    WoW95:Debug("Enabled action bar: " .. barId)
end

function ActionBars:CreateActionBarRow(barId, config)
    local container = self.mainContainer.contentArea
    local rowIndex = self:GetRowIndex(barId)
    
    -- Create row frame
    local row = CreateFrame("Frame", "WoW95ActionBarRow" .. barId, container)
    row:SetSize(ACTIONBAR_WIDTH - (CONTAINER_PADDING * 2), ACTIONBAR_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", container, "TOPLEFT", CONTAINER_PADDING, -(rowIndex - 1) * ACTIONBAR_ROW_HEIGHT - CONTAINER_PADDING)
    
    -- Create custom icon slots instead of using Blizzard positioning
    row.iconSlots = {}
    for i = 1, 12 do
        local slot = CreateFrame("Button", row:GetName() .. "Slot" .. i, row, "BackdropTemplate")
        slot:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        slot:SetPoint("LEFT", row, "LEFT", (i-1) * (BUTTON_SIZE + BUTTON_SPACING), 0)
        
        -- Slot backdrop (Windows 95 style button frame)
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        slot:SetBackdropColor(unpack(WoW95.colors.buttonFace)) -- Use consistent button color
        slot:SetBackdropBorderColor(unpack(WoW95.colors.buttonShadow))
        
        -- Get the corresponding Blizzard button
        local blizzButton = _G[config.blizzardButtons .. i]
        if blizzButton then
            -- Hide the Blizzard button visually but keep it in hierarchy for Edit Mode
            blizzButton:Hide()
            blizzButton:SetAlpha(0)
            blizzButton:EnableMouse(false)  -- Disable mouse interaction to prevent invisible clicks
            -- DON'T reparent the button - Edit Mode may need to reference it
            
            -- Extract just the icon and place it in our slot
            self:SetupCustomIconSlot(slot, blizzButton, i)
        end
        
        row.iconSlots[i] = slot
    end
    
    -- Store the row
    self.bars[barId] = row
    
    -- Show the row and all its slots
    row:Show()
    
    -- Force all icon slots to be visible
    for i = 1, 12 do
        if row.iconSlots[i] then
            row.iconSlots[i]:Show()
        end
    end
    
    WoW95:Debug("Created and showing action bar row: " .. barId .. " with " .. #row.iconSlots .. " visible slots")
end

function ActionBars:SetupCustomIconSlot(slot, blizzButton, buttonIndex)
    -- Create our own icon display
    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Create hotkey text
    local hotkey = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hotkey:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -2, -2)
    hotkey:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    hotkey:SetTextColor(1, 1, 1, 1)
    
    -- Create count text
    local count = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    count:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    count:SetTextColor(1, 1, 1, 1)
    
    -- Create cooldown frame
    local cooldown = CreateFrame("Cooldown", slot:GetName() .. "Cooldown", slot, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetHideCountdownNumbers(false)
    
    -- Create spell activation overlay (for procs/empowered abilities)
    local spellActivationAlert = slot:CreateTexture(nil, "OVERLAY")
    spellActivationAlert:SetAllPoints(slot)
    spellActivationAlert:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    spellActivationAlert:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    spellActivationAlert:SetBlendMode("ADD")
    spellActivationAlert:Hide()
    
    -- Create animation group for pulsing glow
    local animGroup = spellActivationAlert:CreateAnimationGroup()
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.3)
    fadeOut:SetDuration(0.6)
    fadeOut:SetOrder(1)
    
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.3)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.6)
    fadeIn:SetOrder(2)
    
    animGroup:SetLooping("REPEAT")
    
    -- Make slot clickable and forward to Blizzard button
    slot:RegisterForClicks("AnyUp")
    slot:RegisterForDrag("LeftButton")
    
    slot:SetScript("OnClick", function(self, button, down)
        if InCombatLockdown() then
            -- In combat, just simulate the click without calling protected functions
            if blizzButton:IsEnabled() then
                local onClickScript = blizzButton:GetScript("OnClick")
                if onClickScript then
                    onClickScript(blizzButton, button, down)
                end
            end
        else
            -- Out of combat, we can safely click the button
            blizzButton:Click(button, down)
        end
    end)
    
    slot:SetScript("OnDragStart", function()
        if not InCombatLockdown() then
            local onDragStartScript = blizzButton:GetScript("OnDragStart")
            if onDragStartScript then
                onDragStartScript(blizzButton)
            end
        end
    end)
    
    slot:SetScript("OnReceiveDrag", function()
        if not InCombatLockdown() then
            local onReceiveDragScript = blizzButton:GetScript("OnReceiveDrag")
            if onReceiveDragScript then
                onReceiveDragScript(blizzButton)
            end
        end
    end)
    
    -- Determine the correct keybinding name based on the button type
    local function GetCorrectKeybinding()
        local buttonName = blizzButton:GetName()
        if buttonName then
            if string.find(buttonName, "ActionButton") then
                return "ACTIONBUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBarBottomLeftButton") then
                return "MULTIACTIONBAR1BUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBarBottomRightButton") then
                return "MULTIACTIONBAR2BUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBarRightButton") then
                return "MULTIACTIONBAR3BUTTON" .. buttonIndex  -- Bar 4 uses MULTIACTIONBAR3
            elseif string.find(buttonName, "MultiBarLeftButton") then
                return "MULTIACTIONBAR4BUTTON" .. buttonIndex  -- Bar 5 uses MULTIACTIONBAR4
            elseif string.find(buttonName, "MultiBar5Button") then
                return "MULTIACTIONBAR5BUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBar6Button") then
                return "MULTIACTIONBAR6BUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBar7Button") then
                return "MULTIACTIONBAR7BUTTON" .. buttonIndex
            end
        end
        return "ACTIONBUTTON" .. buttonIndex -- fallback
    end
    
    -- Update display based on Blizzard button state
    local function UpdateSlot()
        if not blizzButton or not blizzButton.action then return end
        
        -- Get action info
        local actionType, actionID = GetActionInfo(blizzButton.action)
        
        if actionType then
            local texture = GetActionTexture(blizzButton.action)
            if texture then
                icon:SetTexture(texture)
                icon:Show()
                
                -- Check if ability is usable and apply desaturation
                local isUsable, notEnoughMana = IsUsableAction(blizzButton.action)
                if isUsable then
                    icon:SetDesaturated(false)
                    icon:SetVertexColor(1.0, 1.0, 1.0) -- Normal color
                elseif notEnoughMana then
                    icon:SetDesaturated(false)
                    icon:SetVertexColor(0.5, 0.5, 1.0) -- Blue tint for mana issues
                else
                    icon:SetDesaturated(true)
                    icon:SetVertexColor(0.4, 0.4, 0.4) -- Gray for unusable
                end
            else
                icon:Hide()
            end
            
            -- Update count
            local actionCount = GetActionCount(blizzButton.action)
            if actionCount and actionCount > 1 then
                count:SetText(actionCount)
                count:Show()
            else
                count:Hide()
            end
            
            -- Update hotkey with correct binding
            local bindingName = GetCorrectKeybinding()
            local hotkeyText = GetBindingKey(bindingName)
            if hotkeyText and hotkeyText ~= "" then
                local displayText = GetBindingText(hotkeyText, "KEY_")
                if displayText and displayText ~= "" then
                    hotkey:SetText(displayText)
                    hotkey:Show()
                    -- Debug all keybinding detection (disabled - too spammy)
                    -- WoW95:Debug("Keybinding: " .. blizzButton:GetName() .. " -> " .. bindingName .. " -> " .. displayText)
                else
                    hotkey:Hide()
                end
            else
                -- Try alternative keybinding detection
                local altBinding = GetBindingKey(blizzButton:GetName())
                if altBinding and altBinding ~= "" then
                    local displayText = GetBindingText(altBinding, "KEY_")
                    if displayText and displayText ~= "" then
                        hotkey:SetText(displayText)
                        hotkey:Show()
                        -- WoW95:Debug("Alt keybinding: " .. blizzButton:GetName() .. " -> " .. displayText)
                    else
                        hotkey:Hide()
                    end
                else
                    hotkey:Hide()
                end
            end
            
            -- Update cooldown
            local start, duration = GetActionCooldown(blizzButton.action)
            if start and duration and duration > 0 then
                cooldown:SetCooldown(start, duration)
            else
                cooldown:Clear()
            end
            
            -- Check for spell activation (procs/empowered abilities)
            local spellID = 0
            if actionType == "spell" then
                spellID = actionID
            elseif actionType == "item" then
                -- For items that trigger spell procs
                spellID = select(2, GetItemSpell(actionID)) or 0
            end
            
            -- Show spell activation overlay if there's an active proc
            if spellID and spellID > 0 and IsSpellOverlayed(spellID) then
                spellActivationAlert:Show()
                if not animGroup:IsPlaying() then
                    animGroup:Play()
                end
            else
                spellActivationAlert:Hide()
                if animGroup:IsPlaying() then
                    animGroup:Stop()
                end
            end
            
        else
            -- Empty slot
            icon:Hide()
            count:Hide()
            hotkey:Hide()
            cooldown:Clear()
            spellActivationAlert:Hide()
            if animGroup:IsPlaying() then
                animGroup:Stop()
            end
        end
    end
    
    -- Button hover effects
    slot:SetScript("OnEnter", function()
        slot:SetBackdropColor(unpack(WoW95.colors.buttonHighlight))
        -- Show Blizzard tooltip safely
        if blizzButton then
            local onEnterScript = blizzButton:GetScript("OnEnter")
            if onEnterScript then
                local success, err = pcall(onEnterScript, blizzButton)
                if not success then
                    -- Fallback: show basic tooltip
                    if blizzButton.action and HasAction(blizzButton.action) then
                        GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
                        GameTooltip:SetAction(blizzButton.action)
                        GameTooltip:Show()
                    end
                end
            end
        end
    end)
    
    slot:SetScript("OnLeave", function()
        slot:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        GameTooltip:Hide()
    end)
    
    -- Button press effects (Windows 95 style)
    slot:SetScript("OnMouseDown", function()
        slot:SetBackdropColor(unpack(WoW95.colors.buttonShadow))
        icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 5, -5)
        icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
    end)
    
    slot:SetScript("OnMouseUp", function()
        slot:SetBackdropColor(unpack(WoW95.colors.buttonHighlight))
        icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -4, 4)
    end)
    
    -- Store references and update function
    slot.icon = icon
    slot.hotkey = hotkey
    slot.count = count
    slot.cooldown = cooldown
    slot.spellActivationAlert = spellActivationAlert
    slot.animGroup = animGroup
    slot.blizzButton = blizzButton
    slot.UpdateSlot = UpdateSlot
    
    -- Initial update
    UpdateSlot()
    
    -- Set up regular updates
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed
        if self.timeSinceUpdate >= 0.1 then -- Update 10 times per second
            UpdateSlot()
            self.timeSinceUpdate = 0
        end
    end)
    
    slot.updateFrame = updateFrame
end

function ActionBars:GetBarConfig(barId)
    for _, config in ipairs(self.barConfigs) do
        if config.id == barId then
            return config
        end
    end
    return nil
end

function ActionBars:GetRowIndex(barId)
    for i, enabledBarId in ipairs(self.enabledBars) do
        if enabledBarId == barId then
            return i
        end
    end
    return #self.enabledBars + 1
end

function ActionBars:UpdateContainerSize()
    local numEnabledBars = math.min(3, #self.enabledBars) -- Max 3 in main container
    local containerHeight = TITLE_BAR_HEIGHT + (numEnabledBars * ACTIONBAR_ROW_HEIGHT) + (CONTAINER_PADDING * 2) + 4
    
    self.mainContainer:SetSize(ACTIONBAR_WIDTH, containerHeight)
    
    WoW95:Debug("Updated container size for " .. numEnabledBars .. " bars")
end

function ActionBars:HookCVarChanges()
    -- Create frame to listen for various bar change events
    local cvarFrame = CreateFrame("Frame")
    cvarFrame:RegisterEvent("CVAR_UPDATE")
    cvarFrame:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
    cvarFrame:RegisterEvent("VARIABLES_LOADED")
    cvarFrame:RegisterEvent("SETTINGS_LOADED")
    cvarFrame:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
    cvarFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
    cvarFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
    
    -- Also hook into the settings frame if it exists
    local hookSettings = function()
        if SettingsPanel and SettingsPanel:GetScript("OnHide") then
            SettingsPanel:HookScript("OnHide", function()
                WoW95:Print("Settings closed - checking for action bar changes...")
                C_Timer.After(0.1, function()
                    ActionBars:RebuildMainContainer()
                    ActionBars:CheckForAdditionalBars()
                end)
            end)
        end
    end
    
    -- Store current bar states for comparison
    self.lastBarStates = {
        bar2 = self:IsBarEnabled("multiBarBottomLeft", "MultiBarBottomLeft"),
        bar3 = self:IsBarEnabled("multiBarBottomRight", "MultiBarBottomRight")
    }
    
    WoW95:Debug("Initial bar states for monitoring - Bar 2: " .. tostring(self.lastBarStates.bar2) .. ", Bar 3: " .. tostring(self.lastBarStates.bar3))
    
    -- Set up periodic checking as backup - more frequent checks
    local checkFrame = CreateFrame("Frame")
    checkFrame.timeSinceLastCheck = 0
    checkFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastCheck = (self.timeSinceLastCheck or 0) + elapsed
        if self.timeSinceLastCheck >= 0.5 then -- Check every half second for faster response
            local currentStates = {
                bar2 = ActionBars:IsBarEnabled("multiBarBottomLeft", "MultiBarBottomLeft"),
                bar3 = ActionBars:IsBarEnabled("multiBarBottomRight", "MultiBarBottomRight")
            }
            
            -- Debug every 10th check (every 5 seconds) to see current state
            self.debugCounter = (self.debugCounter or 0) + 1
            if self.debugCounter >= 10 then
                WoW95:Debug("Periodic check - Bar 2: " .. tostring(currentStates.bar2) .. " (was " .. tostring(ActionBars.lastBarStates.bar2) .. "), Bar 3: " .. tostring(currentStates.bar3) .. " (was " .. tostring(ActionBars.lastBarStates.bar3) .. ")")
                self.debugCounter = 0
            end
            
            -- Check if any state changed
            if currentStates.bar2 ~= ActionBars.lastBarStates.bar2 or 
               currentStates.bar3 ~= ActionBars.lastBarStates.bar3 then
                WoW95:Print("Action bar state change detected - rebuilding...")
                WoW95:Print("Bar 2: " .. tostring(ActionBars.lastBarStates.bar2) .. " -> " .. tostring(currentStates.bar2))
                WoW95:Print("Bar 3: " .. tostring(ActionBars.lastBarStates.bar3) .. " -> " .. tostring(currentStates.bar3))
                ActionBars:RebuildMainContainer()
                ActionBars:CheckForAdditionalBars()
                ActionBars.lastBarStates = currentStates
            end
            
            self.timeSinceLastCheck = 0
        end
    end)
    
    cvarFrame:SetScript("OnEvent", function(self, event, cvarName)
        if event == "CVAR_UPDATE" then
            -- Check if it's an action bar related CVar
            local actionBarCVars = {
                "multiBarBottomLeft", "multiBarBottomRight", 
                "multiBarRight", "multiBarLeft",
                "multiBar5", "multiBar6", "multiBar7"
            }
            
            if cvarName and tContains(actionBarCVars, cvarName) then
                WoW95:Print("Action bar CVar changed: " .. cvarName .. " - rebuilding bars...")
                -- Delay the update to allow WoW to process the change
                C_Timer.After(0.2, function()
                    ActionBars:RebuildActionBars()
                end)
            end
        elseif event == "UPDATE_EXTRA_ACTIONBAR" or event == "UPDATE_MULTI_CAST_ACTIONBAR" or 
               event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
            WoW95:Debug("Action bar visibility event: " .. event)
            -- These events fire when bars are toggled
            C_Timer.After(0.2, function()
                ActionBars:RebuildMainContainer()
                ActionBars:CheckForAdditionalBars()
            end)
        elseif event == "SETTINGS_LOADED" or event == "VARIABLES_LOADED" then
            -- Try to hook settings panel when it's ready
            C_Timer.After(1, hookSettings)
        end
    end)
    
    -- Try to hook settings immediately if available
    hookSettings()
end

function ActionBars:RebuildActionBars()
    WoW95:Debug("Rebuilding action bars due to CVar change...")
    
    -- Just call our improved rebuild function
    self:RebuildMainContainer()
    
    -- Also re-check additional bars for bars 4-8
    self:CheckForAdditionalBars()
    
    WoW95:Debug("Action bars rebuilt successfully - enabled bars: " .. table.concat(self.enabledBars, ", "))
end

function ActionBars:CreatePageSwitcher()
    -- Page switching controls with Windows 95 style buttons
    local switcher = CreateFrame("Frame", "WoW95PageSwitcher", self.mainContainer, "BackdropTemplate")
    switcher:SetSize(100, 16)
    switcher:SetPoint("TOPRIGHT", self.mainContainer.titleBar, "TOPRIGHT", -25, -1)
    
    -- Previous page button
    local prevButton = WoW95:CreateTitleBarButton("WoW95PagePrev", switcher, nil, 16)
    prevButton:SetSize(16, 14)
    prevButton:SetPoint("LEFT", switcher, "LEFT", 0, 0)
    
    -- Create left arrow texture
    local prevArrow = prevButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    prevArrow:SetPoint("CENTER")
    prevArrow:SetText("◀")
    prevArrow:SetTextColor(0, 0, 0, 1)
    prevArrow:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    prevButton.arrow = prevArrow
    
    -- Page display
    local pageDisplay = CreateFrame("Frame", nil, switcher, "BackdropTemplate")
    pageDisplay:SetSize(50, 14)
    pageDisplay:SetPoint("LEFT", prevButton, "RIGHT", 2, 0)
    pageDisplay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    pageDisplay:SetBackdropColor(1, 1, 1, 1) -- White background
    pageDisplay:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local pageText = pageDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("CENTER", pageDisplay, "CENTER", 0, 0)
    pageText:SetText("Page " .. self.currentPage)
    pageText:SetTextColor(0, 0, 0, 1) -- Black text on white background
    pageText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
    -- Next page button
    local nextButton = WoW95:CreateTitleBarButton("WoW95PageNext", switcher, nil, 16)
    nextButton:SetSize(16, 14)
    nextButton:SetPoint("LEFT", pageDisplay, "RIGHT", 2, 0)
    
    -- Create right arrow texture
    local nextArrow = nextButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nextArrow:SetPoint("CENTER")
    nextArrow:SetText("▶")
    nextArrow:SetTextColor(0, 0, 0, 1)
    nextArrow:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    nextButton.arrow = nextArrow
    
    -- Button functionality
    prevButton:SetScript("OnClick", function()
        if not InCombatLockdown() then
            local currentPage = GetActionBarPage()
            if currentPage > 1 then
                ChangeActionBarPage(currentPage - 1)
            end
        end
    end)
    
    nextButton:SetScript("OnClick", function()
        if not InCombatLockdown() then
            local currentPage = GetActionBarPage()
            if currentPage < NUM_ACTIONBAR_PAGES then
                ChangeActionBarPage(currentPage + 1)
            end
        end
    end)
    
    -- Hover effects for arrows
    prevButton:SetScript("OnEnter", function()
        prevButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(prevButton, "ANCHOR_TOP")
        GameTooltip:SetText("Previous Page")
        GameTooltip:Show()
    end)
    
    prevButton:SetScript("OnLeave", function()
        prevButton:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        GameTooltip:Hide()
    end)
    
    nextButton:SetScript("OnEnter", function()
        nextButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(nextButton, "ANCHOR_TOP")
        GameTooltip:SetText("Next Page")
        GameTooltip:Show()
    end)
    
    nextButton:SetScript("OnLeave", function()
        nextButton:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        GameTooltip:Hide()
    end)
    
    -- Lock button
    local lockButton = CreateFrame("Button", "WoW95LockButton", self.mainContainer.titleBar, "BackdropTemplate")
    lockButton:SetSize(16, 14)
    lockButton:SetPoint("RIGHT", self.mainContainer.titleBar, "RIGHT", -4, 0)
    
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
    
    local lockIcon = lockButton:CreateTexture(nil, "ARTWORK")
    lockIcon:SetPoint("CENTER")
    lockIcon:SetSize(12, 10)
    lockIcon:SetTexture(WoW95.textures.lock) -- Use custom lock texture
    
    lockButton:SetScript("OnClick", function()
        self:ToggleLock()
    end)
    
    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(lockButton, "ANCHOR_TOP")
        GameTooltip:SetText(self.locked and "Unlock Action Bars" or "Lock Action Bars")
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    self.lockButton = lockButton
    self.lockIcon = lockIcon
    self.pageSwitcher = switcher
    self.pageSwitcher.pageText = pageText
    self.pageSwitcher.pageDisplay = pageDisplay
    self.pageSwitcher.prevButton = prevButton
    self.pageSwitcher.nextButton = nextButton
end

function ActionBars:CheckForAdditionalBars()
    -- Check for enabled action bars beyond the first 3 using CVars
    local additionalBars = {
        {id = "fourth", cvar = "multiBarRight", frame = "MultiBarRight", buttons = "MultiBarRightButton"},
        {id = "fifth", cvar = "multiBarLeft", frame = "MultiBarLeft", buttons = "MultiBarLeftButton"},
        {id = "sixth", cvar = "multiBar5", frame = "MultiBar5", buttons = "MultiBar5Button"},
        {id = "seventh", cvar = "multiBar6", frame = "MultiBar6", buttons = "MultiBar6Button"},
        {id = "eighth", cvar = "multiBar7", frame = "MultiBar7", buttons = "MultiBar7Button"},
    }
    
    -- WoW95:Debug("Checking for additional action bars...") -- Too spammy
    
    for _, barInfo in ipairs(additionalBars) do
        local config = self:GetBarConfig(barInfo.id)
        
        -- Try multiple methods to detect if bar is enabled
        local isEnabled = false
        
        -- Method 1: Try CVar
        local cvarValue = C_CVar and C_CVar.GetCVar(barInfo.cvar) or GetCVar(barInfo.cvar)
        if cvarValue and cvarValue ~= "" then
            isEnabled = (cvarValue == "1")
        else
            -- Method 2: Check if frame is shown
            local frame = _G[barInfo.frame]
            if frame then
                isEnabled = frame:IsShown()
            end
        end
        
        -- WoW95:Debug("Bar " .. barInfo.id .. ": CVar=" .. tostring(cvarValue) .. ", Enabled=" .. tostring(isEnabled))
        -- WoW95:Debug("Config found: " .. tostring(config ~= nil))
        
        if config and isEnabled then
            -- Don't create duplicate windows
            if not self.separateBars[barInfo.id] then
                WoW95:Debug("Creating separate action bar: " .. barInfo.id)
                self:CreateSeparateActionBar(barInfo.id, config)
            -- else
                -- WoW95:Debug("Separate bar " .. barInfo.id .. " already exists") -- Too spammy
            end
        else
            -- If bar exists but is no longer enabled, hide it
            if self.separateBars[barInfo.id] then
                self.separateBars[barInfo.id]:Hide()
                self.separateBars[barInfo.id] = nil
                WoW95:Debug("Removed disabled bar: " .. barInfo.id)
            end
        end
    end
end

function ActionBars:CreateSeparateActionBar(barId, config)
    WoW95:Debug("=== Creating separate action bar: " .. barId .. " ===")
    -- Create separate action bar with minimal controls
    local isVertical = false -- Default to horizontal
    local controlHeight = 20
    local window = CreateFrame("Frame", "WoW95SeparateActionBar" .. barId, UIParent, "BackdropTemplate")
    
    -- Set initial size (horizontal by default)
    window:SetSize(ACTIONBAR_WIDTH + 30, ACTIONBAR_ROW_HEIGHT + 8) -- Extra width for controls
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:SetAlpha(1)
    
    -- Store bar configuration
    window.barId = barId
    window.isVertical = isVertical
    window.isLocked = false
    
    -- Simple backdrop
    window:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    window:SetBackdropColor(0.75, 0.75, 0.75, 0.3) -- Translucent
    window:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    
    -- Create control buttons container on the left
    local controlPanel = CreateFrame("Frame", nil, window)
    controlPanel:SetSize(25, ACTIONBAR_ROW_HEIGHT)
    controlPanel:SetPoint("LEFT", window, "LEFT", 2, 0)
    
    -- Lock button
    local lockBtn = CreateFrame("Button", nil, controlPanel, "BackdropTemplate")
    lockBtn:SetSize(20, 16)
    lockBtn:SetPoint("TOP", controlPanel, "TOP", 0, -2)
    lockBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    lockBtn:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    lockBtn:SetBackdropBorderColor(unpack(WoW95.colors.buttonShadow))
    
    -- Lock icon
    local lockIcon = lockBtn:CreateTexture(nil, "ARTWORK")
    lockIcon:SetPoint("CENTER")
    lockIcon:SetSize(12, 10)
    lockIcon:SetTexture(WoW95.textures.lock)
    lockBtn.icon = lockIcon
    
    -- Orientation button (horizontal/vertical toggle)
    local orientBtn = CreateFrame("Button", nil, controlPanel, "BackdropTemplate")
    orientBtn:SetSize(20, 16)
    orientBtn:SetPoint("TOP", lockBtn, "BOTTOM", 0, -2)
    orientBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    orientBtn:SetBackdropColor(unpack(WoW95.colors.buttonFace))
    orientBtn:SetBackdropBorderColor(unpack(WoW95.colors.buttonShadow))
    
    -- Orientation icon (arrow showing current direction)
    local orientIcon = orientBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientIcon:SetPoint("CENTER")
    orientIcon:SetText("↔") -- Horizontal arrow
    orientIcon:SetTextColor(0, 0, 0, 1)
    orientIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    orientBtn.icon = orientIcon
    
    -- Load saved position or use default
    if WoW95DB and WoW95DB.actionBarPositions and WoW95DB.actionBarPositions[barId] then
        local pos = WoW95DB.actionBarPositions[barId]
        window:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position - stack vertically
        local yOffset = 0
        local existingBarsCount = 0
        
        -- Count existing separate bars
        for _, _ in pairs(self.separateBars) do
            existingBarsCount = existingBarsCount + 1
        end
        
        -- Calculate vertical offset based on how many bars already exist
        yOffset = existingBarsCount * (ACTIONBAR_ROW_HEIGHT + 10)
        
        -- Position to the right of main container, stacked vertically
        if self.mainContainer then
            window:SetPoint("BOTTOMLEFT", self.mainContainer, "BOTTOMRIGHT", 10, yOffset)
        else
            window:SetPoint("CENTER", UIParent, "CENTER", 200, -200 + yOffset)
        end
    end
    
    -- Make draggable without title bar
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function()
        if not self.locked then
            window:StartMoving()
        end
    end)
    window:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        ActionBars:SavePosition(barId, window)
    end)
    
    -- Lock button functionality
    lockBtn:SetScript("OnClick", function()
        window.isLocked = not window.isLocked
        if window.isLocked then
            lockIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Darker when locked
            window:SetScript("OnDragStart", nil)
        else
            lockIcon:SetVertexColor(1, 1, 1, 1) -- Normal when unlocked
            window:SetScript("OnDragStart", function() window:StartMoving() end)
        end
    end)
    
    lockBtn:SetScript("OnEnter", function()
        lockBtn:SetBackdropColor(unpack(WoW95.colors.buttonHighlight))
        GameTooltip:SetOwner(lockBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(window.isLocked and "Unlock Bar" or "Lock Bar")
        GameTooltip:Show()
    end)
    
    lockBtn:SetScript("OnLeave", function()
        lockBtn:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        GameTooltip:Hide()
    end)
    
    -- Orientation button functionality
    orientBtn:SetScript("OnClick", function()
        self:ToggleBarOrientation(window)
    end)
    
    orientBtn:SetScript("OnEnter", function()
        orientBtn:SetBackdropColor(unpack(WoW95.colors.buttonHighlight))
        GameTooltip:SetOwner(orientBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle Orientation")
        GameTooltip:AddLine("Click to switch between horizontal and vertical layout", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    orientBtn:SetScript("OnLeave", function()
        orientBtn:SetBackdropColor(unpack(WoW95.colors.buttonFace))
        GameTooltip:Hide()
    end)
    
    -- Create the action bar row inside the window
    local row = CreateFrame("Frame", "WoW95SeparateActionBarRow" .. barId, window)
    row:SetSize(ACTIONBAR_WIDTH - (CONTAINER_PADDING * 2), ACTIONBAR_ROW_HEIGHT)
    row:SetPoint("LEFT", controlPanel, "RIGHT", 2, 0) -- Position after control panel
    row:SetAlpha(1)
    row:Show()
    
    -- Store references
    window.controlPanel = controlPanel
    window.lockBtn = lockBtn
    window.orientBtn = orientBtn
    
    -- Enable the corresponding CVar
    if config.cvar then
        SetCVar(config.cvar, 1)
    end
    
    -- Create icon slots
    row.iconSlots = {}
    for i = 1, 12 do
        local slot = CreateFrame("Button", row:GetName() .. "Slot" .. i, row, "BackdropTemplate")
        slot:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        slot:SetPoint("LEFT", row, "LEFT", (i-1) * (BUTTON_SIZE + BUTTON_SPACING), 0)
        
        -- Slot backdrop (Windows 95 style button frame)
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        slot:SetBackdropColor(unpack(WoW95.colors.buttonFace)) -- Use consistent button color
        slot:SetBackdropBorderColor(unpack(WoW95.colors.buttonShadow))
        
        -- Get the corresponding Blizzard button
        local blizzButton = _G[config.blizzardButtons .. i]
        if blizzButton then
            -- Hide the Blizzard button visually but keep it in hierarchy for Edit Mode
            blizzButton:Hide()
            blizzButton:SetAlpha(0)
            blizzButton:EnableMouse(false)  -- Disable mouse interaction to prevent invisible clicks
            -- DON'T reparent the button - Edit Mode may need to reference it
            self:SetupCustomIconSlot(slot, blizzButton, i)
        end
        
        slot:Show() -- Ensure slot is visible
        row.iconSlots[i] = slot
    end
    
    -- Store the separate bar
    window.actionBarRow = row
    self.separateBars[barId] = window
    
    window:Show()
    window:SetFrameStrata("MEDIUM") -- Ensure it's visible
    window:SetFrameLevel(10)
    row:Show() -- Ensure the row is visible
    
    -- Force all slots to be visible
    for i = 1, 12 do
        if row.iconSlots[i] then
            row.iconSlots[i]:Show()
            -- Force update the slot
            if row.iconSlots[i].UpdateSlot then
                row.iconSlots[i]:UpdateSlot()
            end
        end
    end
    
    WoW95:Debug("Created separate action bar: " .. barId .. " at position " .. tostring(window:GetPoint()))
    WoW95:Debug("Window visible: " .. tostring(window:IsVisible()) .. ", Alpha: " .. window:GetAlpha())
end

function ActionBars:ToggleLock()
    self.locked = not self.locked
    
    if self.lockIcon then
        -- Visual feedback - darken the lock icon when locked
        if self.locked then
            self.lockIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Darker when locked
        else
            self.lockIcon:SetVertexColor(1, 1, 1, 1) -- Normal when unlocked
        end
    end
    
    -- Update all separate bars' lock state
    for _, window in pairs(self.separateBars) do
        -- Separate bars don't have title bars, update drag directly on window
        if self.locked then
            window:SetScript("OnDragStart", nil)
        else
            window:SetScript("OnDragStart", function()
                window:StartMoving()
            end)
        end
    end
    
    WoW95:Debug("Action bars " .. (self.locked and "locked" or "unlocked"))
end

function ActionBars:HideBlizzardActionBars()
    -- Hide Blizzard action bar frames while preserving Edit Mode compatibility
    if InCombatLockdown() then
        -- Schedule hiding after combat
        local combatFrame = CreateFrame("Frame")
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatFrame:SetScript("OnEvent", function()
            self:HideBlizzardActionBars()
            combatFrame:UnregisterAllEvents()
        end)
        return
    end
    
    -- Only hide visual elements for bars 1-3 which we replace in the main container
    -- Keep bars 4-8 visible but hidden (we overlay them with our frames)
    local framesToHide = {
        "MainMenuBar", "MainMenuBarArtFrame", 
        "StanceBarFrame", "PossessBarFrame", "MainMenuExpBar", "ReputationWatchBar"
    }
    
    for _, frameName in ipairs(framesToHide) do
        local frame = _G[frameName]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            -- DON'T reparent frames - Edit Mode needs them in their original hierarchy
            -- if frame.SetParent then
            --     frame:SetParent(CreateFrame("Frame"))
            -- end
        end
    end
    
    -- Preserve Edit Mode critical frames by ensuring they stay in their proper hierarchy
    -- MicroButtonAndBagsBar is NOT hidden to prevent Edit Mode errors
    local editModeCriticalFrames = {
        "MainMenuBarArtFrame", "MultiBarBottomLeft", 
        "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft"
    }
    
    for _, frameName in ipairs(editModeCriticalFrames) do
        local frame = _G[frameName]
        if frame then
            -- Keep them invisible but in proper hierarchy for Edit Mode
            frame:SetAlpha(0)
            frame:Hide()
            -- Ensure they maintain their original parent relationships
            if frame.SetIgnoreParentAlpha then
                frame:SetIgnoreParentAlpha(true)
            end
        end
    end
    
    -- Special handling for MicroButtonAndBagsBar - keep it functional for Edit Mode
    local microBar = _G["MicroButtonAndBagsBar"]
    if microBar then
        -- Instead of moving off-screen, just make it invisible but keep proper positioning
        microBar:SetAlpha(0) -- Completely invisible
        microBar:Show() -- Keep it shown for Edit Mode
        -- Keep it in its normal position so Edit Mode calculations work
        -- Don't move it off-screen as that causes arithmetic issues
        WoW95:Debug("MicroButtonAndBagsBar kept invisible for Edit Mode compatibility")
    end
    
    WoW95:Debug("Blizzard action bars hidden (Edit Mode compatible)")
end

function ActionBars:EnsureEditModeCompatibility()
    -- Comprehensive Edit Mode protection (MicroButtonAndBagsBar is left alone - positioned off-screen)
    local criticalFrames = {
        "MainMenuBarArtFrame", "MultiBarBottomLeft", 
        "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MainMenuBar"
    }
    
    for _, frameName in ipairs(criticalFrames) do
        local frame = _G[frameName]
        if frame then
            -- Ensure frame has proper size and position data for Edit Mode
            local width = frame:GetWidth()
            local height = frame:GetHeight()
            
            if not width or width == 0 or width ~= width then -- NaN check
                frame:SetWidth(100) -- Set reasonable default
            end
            if not height or height == 0 or height ~= height then -- NaN check  
                frame:SetHeight(20) -- Set reasonable default
            end
            
            -- Ensure frame is properly anchored
            if frame:GetNumPoints() == 0 then
                frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
            end
        end
    end
    
    -- Verify MicroButtonAndBagsBar has proper dimensions for Edit Mode
    local microBar = _G["MicroButtonAndBagsBar"]
    if microBar then
        WoW95:Debug("MicroButtonAndBagsBar found - ensuring Edit Mode compatibility")
        -- Make sure it has proper dimensions for Edit Mode calculations
        local width = microBar:GetWidth()
        local height = microBar:GetHeight()
        
        if not width or width == 0 or width ~= width then -- nil or NaN check
            microBar:SetWidth(200)
            WoW95:Debug("Set MicroButtonAndBagsBar width to 200")
        end
        if not height or height == 0 or height ~= height then -- nil or NaN check
            microBar:SetHeight(20)
            WoW95:Debug("Set MicroButtonAndBagsBar height to 20")
        end
        
        -- Ensure it has valid anchor points
        if microBar:GetNumPoints() == 0 then
            microBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 4)
            WoW95:Debug("Set MicroButtonAndBagsBar anchor point")
        end
    end
    
    WoW95:Debug("Edit Mode compatibility ensured - MicroButtonAndBagsBar kept in normal position")
    
    -- Hook Edit Mode to provide safe fallbacks
    self:HookEditMode()
end

function ActionBars:HookEditModeImmediate()
    -- Create event hook to catch when Edit Mode loads
    local editModeHookFrame = CreateFrame("Frame")
    
    local function TryHookEditMode()
        if EditModeManagerFrame and EditModeManagerFrame.UpdateRightActionBarPositions then
            local originalFunction = EditModeManagerFrame.UpdateRightActionBarPositions
            
            EditModeManagerFrame.UpdateRightActionBarPositions = function(self, barsToUpdate)
                WoW95:Debug("Edit Mode UpdateRightActionBarPositions intercepted - preventing errors")
                
                -- Instead of calling the problematic function, just skip it entirely
                -- Edit Mode is trying to calculate positions for bars we've hidden anyway
                return -- Do nothing - this prevents the arithmetic error
            end
            
            WoW95:Debug("Edit Mode UpdateRightActionBarPositions successfully hooked and disabled")
            editModeHookFrame:UnregisterAllEvents()
            return true
        end
        return false
    end
    
    -- Try hooking immediately
    if TryHookEditMode() then
        return
    end
    
    -- If immediate hook failed, set up event listener
    editModeHookFrame:RegisterEvent("ADDON_LOADED")
    editModeHookFrame:RegisterEvent("PLAYER_LOGIN") 
    editModeHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    editModeHookFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and (addonName == "Blizzard_EditMode" or addonName == "WoW95") then
            TryHookEditMode()
        elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            TryHookEditMode()
        end
    end)
    
    -- Also try with a timer as backup
    local attempts = 0
    local function TimerTryHook()
        attempts = attempts + 1
        if TryHookEditMode() or attempts >= 10 then
            return -- Stop trying after success or 10 attempts
        end
        C_Timer.After(1, TimerTryHook)
    end
    C_Timer.After(1, TimerTryHook)
    
    WoW95:Debug("Edit Mode hook scheduled - will try when Edit Mode loads")
end

function ActionBars:HookEditMode()
    -- Secondary hook with more detailed handling (legacy function)
    C_Timer.After(2, function()
        if not EditModeManagerFrame then
            WoW95:Debug("EditModeManagerFrame not found - Edit Mode hook skipped")
            return
        end
        
        WoW95:Debug("Edit Mode already hooked immediately - secondary hook skipped")
    end)
end

function ActionBars:HookActionBarEvents()
    -- Hook action bar update events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("CVAR_UPDATE")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ACTIONBAR_PAGE_CHANGED" then
            local newPage = GetActionBarPage()
            ActionBars.currentPage = newPage
            if ActionBars.mainContainer and ActionBars.mainContainer.titleText then
                ActionBars.mainContainer.titleText:SetText("Action Bars - Page " .. newPage)
            end
            if ActionBars.pageSwitcher and ActionBars.pageSwitcher.pageText then
                ActionBars.pageSwitcher.pageText:SetText("Page " .. newPage)
            end
        elseif event == "CVAR_UPDATE" then
            -- Check if additional action bars were enabled/disabled
            C_Timer.After(0.1, function()
                ActionBars:CheckForAdditionalBars()
            end)
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or 
               event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" or
               event == "SPELL_UPDATE_USABLE" or
               event == "SPELL_UPDATE_COOLDOWN" or
               event == "PLAYER_TARGET_CHANGED" or
               event == "UPDATE_SHAPESHIFT_FORM" then
            -- Force update all action button displays
            ActionBars:UpdateAllSlots()
        end
    end)
end

function ActionBars:UpdateAllSlots()
    -- Update all slots in main container
    for _, bar in pairs(self.bars) do
        if bar and bar.iconSlots then
            for _, slot in pairs(bar.iconSlots) do
                if slot and slot.UpdateSlot then
                    slot:UpdateSlot()
                end
            end
        end
    end
    
    -- Update all slots in separate bars
    for _, window in pairs(self.separateBars) do
        if window and window.actionBarRow and window.actionBarRow.iconSlots then
            for _, slot in pairs(window.actionBarRow.iconSlots) do
                if slot and slot.UpdateSlot then
                    slot:UpdateSlot()
                end
            end
        end
    end
end

-- Debug command to check action bar states
SLASH_WOW95BARDEBUG1 = "/wow95bars"
SlashCmdList["WOW95BARDEBUG"] = function()
    WoW95:Print("=== WoW95 Action Bars Debug ===")
    WoW95:Print("Main container visible: " .. tostring(ActionBars.mainContainer and ActionBars.mainContainer:IsVisible()))
    
    for barId, window in pairs(ActionBars.separateBars) do
        if window then
            WoW95:Print("Bar " .. barId .. ":")
            WoW95:Print("  - Visible: " .. tostring(window:IsVisible()))
            WoW95:Print("  - Alpha: " .. window:GetAlpha())
            WoW95:Print("  - Width: " .. window:GetWidth() .. ", Height: " .. window:GetHeight())
            local point, relativeTo, relativePoint, xOfs, yOfs = window:GetPoint()
            WoW95:Print("  - Position: " .. (point or "nil") .. " " .. (xOfs or 0) .. ", " .. (yOfs or 0))
            
            if window.actionBarRow then
                local row = window.actionBarRow
                WoW95:Print("  - Row visible: " .. tostring(row:IsVisible()))
                WoW95:Print("  - Row alpha: " .. row:GetAlpha())
                
                local visibleSlots = 0
                for i = 1, 12 do
                    if row.iconSlots and row.iconSlots[i] and row.iconSlots[i]:IsVisible() then
                        visibleSlots = visibleSlots + 1
                    end
                end
                WoW95:Print("  - Visible slots: " .. visibleSlots .. "/12")
            end
        end
    end
end

function ActionBars:SavePosition(barId, frame)
    if not frame then return end
    
    -- Initialize saved variables if needed
    if not WoW95DB then WoW95DB = {} end
    if not WoW95DB.actionBarPositions then WoW95DB.actionBarPositions = {} end
    
    -- Get current position
    local point, _, relativePoint, x, y = frame:GetPoint()
    if point then
        WoW95DB.actionBarPositions[barId] = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
        WoW95:Debug("Saved position for bar " .. barId)
    end
end

function ActionBars:ToggleBarOrientation(window)
    if not window or not window.actionBarRow then return end
    
    window.isVertical = not window.isVertical
    local row = window.actionBarRow
    
    if window.isVertical then
        -- Switch to vertical layout (12 buttons stacked)
        window:SetSize(BUTTON_SIZE + 35, (BUTTON_SIZE + BUTTON_SPACING) * 12 + 8)
        window.controlPanel:SetSize(25, (BUTTON_SIZE + BUTTON_SPACING) * 12)
        row:SetSize(BUTTON_SIZE, (BUTTON_SIZE + BUTTON_SPACING) * 12)
        
        -- Reposition buttons vertically
        for i = 1, 12 do
            if row.iconSlots[i] then
                row.iconSlots[i]:ClearAllPoints()
                row.iconSlots[i]:SetPoint("TOP", row, "TOP", 0, -(i-1) * (BUTTON_SIZE + BUTTON_SPACING))
            end
        end
        
        -- Update orientation icon
        window.orientBtn.icon:SetText("↕") -- Vertical arrow
    else
        -- Switch to horizontal layout (12 buttons in a row)
        window:SetSize(ACTIONBAR_WIDTH + 30, ACTIONBAR_ROW_HEIGHT + 8)
        window.controlPanel:SetSize(25, ACTIONBAR_ROW_HEIGHT)
        row:SetSize(ACTIONBAR_WIDTH - (CONTAINER_PADDING * 2), ACTIONBAR_ROW_HEIGHT)
        
        -- Reposition buttons horizontally
        for i = 1, 12 do
            if row.iconSlots[i] then
                row.iconSlots[i]:ClearAllPoints()
                row.iconSlots[i]:SetPoint("LEFT", row, "LEFT", (i-1) * (BUTTON_SIZE + BUTTON_SPACING), 0)
            end
        end
        
        -- Update orientation icon
        window.orientBtn.icon:SetText("↔") -- Horizontal arrow
    end
end

-- Command to manually refresh action bars
SLASH_WOW95ACTIONREFRESH1 = "/wow95actionrefresh"
SlashCmdList["WOW95ACTIONREFRESH"] = function(msg)
    WoW95:Print("Manually refreshing action bars...")
    ActionBars:RebuildMainContainer()
    ActionBars:CheckForAdditionalBars()
    WoW95:Print("Action bars refreshed!")
end

-- Test toggle detection command
SLASH_WOW95ACTIONTEST1 = "/wow95actiontest"
SlashCmdList["WOW95ACTIONTEST"] = function(msg)
    WoW95:Print("=== Testing Action Bar Toggle Detection ===")
    
    local current2 = ActionBars:IsBarEnabled("multiBarBottomLeft", "MultiBarBottomLeft")
    local current3 = ActionBars:IsBarEnabled("multiBarBottomRight", "MultiBarBottomRight")
    local last2 = ActionBars.lastBarStates and ActionBars.lastBarStates.bar2 or "unknown"
    local last3 = ActionBars.lastBarStates and ActionBars.lastBarStates.bar3 or "unknown"
    
    WoW95:Print("Current Bar 2: " .. tostring(current2) .. " (last: " .. tostring(last2) .. ")")
    WoW95:Print("Current Bar 3: " .. tostring(current3) .. " (last: " .. tostring(last3) .. ")")
    
    -- Force a state change check
    if current2 ~= last2 or current3 ~= last3 then
        WoW95:Print("Change detected - triggering rebuild...")
        ActionBars:RebuildMainContainer()
        ActionBars.lastBarStates = {bar2 = current2, bar3 = current3}
    else
        WoW95:Print("No change detected")
    end
    
    -- Also check the actual CVar values using all methods
    local cvar2 = ActionBars:GetCVarValue("multiBarBottomLeft")
    local cvar3 = ActionBars:GetCVarValue("multiBarBottomRight")
    WoW95:Print("Enhanced CVars - Bar 2: " .. tostring(cvar2) .. ", Bar 3: " .. tostring(cvar3))
    
    -- Check button visibility
    local button2 = _G["MultiBarBottomLeftButton1"]
    local button3 = _G["MultiBarBottomRightButton1"]
    WoW95:Print("Button states - Bar 2 Button1: " .. tostring(button2 and button2:IsShown()) .. ", Bar 3 Button1: " .. tostring(button3 and button3:IsShown()))
end

-- Debug command to check current state
SLASH_WOW95ACTIONDEBUG1 = "/wow95actiondebug"
SlashCmdList["WOW95ACTIONDEBUG"] = function(msg)
    WoW95:Print("=== Action Bars Debug ===")
    WoW95:Print("Main container enabled bars: " .. table.concat(ActionBars.enabledBars, ", "))
    
    local cvars = {
        {"multiBarBottomLeft", "Bar 2"},
        {"multiBarBottomRight", "Bar 3"}, 
        {"multiBarRight", "Bar 4"},
        {"multiBarLeft", "Bar 5"},
        {"multiBar5", "Bar 6"},
        {"multiBar6", "Bar 7"},
        {"multiBar7", "Bar 8"},
    }
    
    for _, cvarInfo in ipairs(cvars) do
        local value = C_CVar and C_CVar.GetCVar(cvarInfo[1]) or GetCVar(cvarInfo[1])
        WoW95:Print(cvarInfo[2] .. " (" .. cvarInfo[1] .. "): " .. tostring(value))
    end
    
    -- Check visual state of main container bars
    WoW95:Print("=== Main Container Visual State ===")
    for barId, row in pairs(ActionBars.bars) do
        if row then
            local isShown = row:IsShown() and "VISIBLE" or "HIDDEN"
            local slotCount = row.iconSlots and #row.iconSlots or 0
            local visibleSlots = 0
            if row.iconSlots then
                for i = 1, #row.iconSlots do
                    if row.iconSlots[i] and row.iconSlots[i]:IsShown() then
                        visibleSlots = visibleSlots + 1
                    end
                end
            end
            WoW95:Print("Main bar " .. barId .. ": " .. isShown .. " (" .. visibleSlots .. "/" .. slotCount .. " slots visible)")
        else
            WoW95:Print("Main bar " .. barId .. ": MISSING")
        end
    end
    
    -- Check container state
    if ActionBars.mainContainer then
        local containerShown = ActionBars.mainContainer:IsShown() and "VISIBLE" or "HIDDEN"
        local containerSize = ActionBars.mainContainer:GetWidth() .. "x" .. ActionBars.mainContainer:GetHeight()
        WoW95:Print("Main container: " .. containerShown .. " (size: " .. containerSize .. ")")
    else
        WoW95:Print("Main container: MISSING")
    end
    
    WoW95:Print("Separate bars count: " .. #ActionBars.separateBars)
    for barId, window in pairs(ActionBars.separateBars) do
        local shown = window:IsShown() and "SHOWN" or "HIDDEN"
        WoW95:Print("  " .. barId .. ": " .. shown)
    end
end

-- Register the module
WoW95:RegisterModule("ActionBars", ActionBars)