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

-- Bar configurations
ActionBars.barConfigs = {
    {id = "main", blizzardButtons = "ActionButton", title = "Action Bar", cvar = nil},
    {id = "second", blizzardButtons = "MultiBarBottomLeftButton", title = "Action Bar 2", cvar = "multiBarBottomLeft"},
    {id = "third", blizzardButtons = "MultiBarBottomRightButton", title = "Action Bar 3", cvar = "multiBarBottomRight"},
    {id = "fourth", blizzardButtons = "MultiBarRightButton", title = "Action Bar 4", cvar = "multiBarRight"},
    {id = "fifth", blizzardButtons = "MultiBarLeftButton", title = "Action Bar 5", cvar = "multiBarLeft"},
}

function ActionBars:Init()
    WoW95:Debug("Initializing Action Bars module...")
    
    -- IMMEDIATELY hook Edit Mode before doing anything else
    self:HookEditModeImmediate()
    
    -- Hide all Blizzard action bars
    self:HideBlizzardActionBars()
    
    -- Create the main dynamic container
    self:CreateMainContainer()
    
    -- Enable and create the bars in correct order (bottom to top)
    self:EnableActionBar("main")     -- Bottom row (ActionButton1-12)
    self:EnableActionBar("second")   -- Middle row (MultiBarBottomLeftButton1-12) 
    self:EnableActionBar("third")    -- Top row (MultiBarBottomRightButton1-12)
    
    -- Check for additional enabled bars and create separate windows
    self:CheckForAdditionalBars()
    
    -- Update container size
    self:UpdateContainerSize()
    
    -- Create page switcher
    self:CreatePageSwitcher()
    
    -- Hook action bar events
    self:HookActionBarEvents()
    
    -- Ensure Edit Mode compatibility
    C_Timer.After(1, function()
        self:EnsureEditModeCompatibility()
    end)
    
    WoW95:Debug("Action Bars initialized successfully!")
end

function ActionBars:CreateMainContainer()
    -- Main container window that grows dynamically
    self.mainContainer = CreateFrame("Frame", "WoW95ActionBarContainer", UIParent, "BackdropTemplate")
    self.mainContainer:SetFrameStrata("MEDIUM")
    self.mainContainer:SetMovable(true)
    self.mainContainer:SetClampedToScreen(true)
    
    -- Position above taskbar
    local taskbarFrame = WoW95.Taskbar and WoW95.Taskbar.frame
    if taskbarFrame then
        self.mainContainer:SetPoint("BOTTOM", taskbarFrame, "TOP", 0, 2)
    else
        self.mainContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 32)
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
    end)
    
    -- Title bar backdrop (blue)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    titleText:SetText("Action Bars - Page " .. self.currentPage)
    titleText:SetTextColor(1, 1, 1, 1)
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
        
        -- Slot backdrop (our custom button frame)
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        slot:SetBackdropColor(0.75, 0.75, 0.75, 1)
        slot:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        
        -- Get the corresponding Blizzard button
        local blizzButton = _G[config.blizzardButtons .. i]
        if blizzButton then
            -- Hide the Blizzard button visually but keep it in hierarchy for Edit Mode
            blizzButton:Hide()
            blizzButton:SetAlpha(0)
            -- DON'T reparent the button - Edit Mode may need to reference it
            
            -- Extract just the icon and place it in our slot
            self:SetupCustomIconSlot(slot, blizzButton, i)
        end
        
        row.iconSlots[i] = slot
    end
    
    -- Store the row
    self.bars[barId] = row
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
                return "MULTIACTIONBAR4BUTTON" .. buttonIndex
            elseif string.find(buttonName, "MultiBarLeftButton") then
                return "MULTIACTIONBAR3BUTTON" .. buttonIndex
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
            if hotkeyText then
                hotkey:SetText(GetBindingText(hotkeyText, "KEY_"))
                hotkey:Show()
            else
                hotkey:Hide()
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
        slot:SetBackdropColor(0.85, 0.85, 0.85, 1)
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
        slot:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    -- Button press effects
    slot:SetScript("OnMouseDown", function()
        slot:SetBackdropColor(0.6, 0.6, 0.6, 1)
        icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 5, -5)
        icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
    end)
    
    slot:SetScript("OnMouseUp", function()
        slot:SetBackdropColor(0.85, 0.85, 0.85, 1)
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

function ActionBars:CreatePageSwitcher()
    -- Page switching controls
    local switcher = CreateFrame("Frame", "WoW95PageSwitcher", self.mainContainer, "BackdropTemplate")
    switcher:SetSize(80, 20)
    switcher:SetPoint("TOPRIGHT", self.mainContainer.titleBar, "TOPRIGHT", -25, -1)
    
    -- Switcher backdrop
    switcher:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    switcher:SetBackdropColor(0.0, 0.0, 0.5, 1)
    switcher:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Page display
    local pageText = switcher:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("CENTER", switcher, "CENTER", 0, 0)
    pageText:SetText("Page " .. self.currentPage)
    pageText:SetTextColor(1, 1, 1, 1)
    pageText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    
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
    
    local lockIcon = lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockIcon:SetPoint("CENTER")
    lockIcon:SetText("🔓") -- Unlocked by default
    lockIcon:SetTextColor(0, 0, 0, 1)
    lockIcon:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
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
end

function ActionBars:CheckForAdditionalBars()
    -- Check CVars for enabled action bars beyond the first 3
    local additionalBars = {
        {id = "fourth", cvar = "multiBarRight"},
        {id = "fifth", cvar = "multiBarLeft"},
    }
    
    for _, barInfo in ipairs(additionalBars) do
        local config = self:GetBarConfig(barInfo.id)
        if config and GetCVar(barInfo.cvar) == "1" then
            self:CreateSeparateActionBar(barInfo.id, config)
        end
    end
end

function ActionBars:CreateSeparateActionBar(barId, config)
    -- Create separate moveable window for action bars 4+
    local window = WoW95:CreateWindow("WoW95SeparateActionBar" .. barId, UIParent, ACTIONBAR_WIDTH, ACTIONBAR_ROW_HEIGHT + TITLE_BAR_HEIGHT + 8, config.title)
    
    -- Position it to the right of main container
    if self.mainContainer then
        window:SetPoint("BOTTOMLEFT", self.mainContainer, "BOTTOMRIGHT", 10, 0)
    else
        window:SetPoint("CENTER", UIParent, "CENTER", 200, -200)
    end
    
    -- Create the action bar row inside the window
    local row = CreateFrame("Frame", "WoW95SeparateActionBarRow" .. barId, window)
    row:SetSize(ACTIONBAR_WIDTH - (CONTAINER_PADDING * 2), ACTIONBAR_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", window.titleBar, "BOTTOMLEFT", CONTAINER_PADDING, -4)
    
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
        
        -- Slot backdrop
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        slot:SetBackdropColor(0.75, 0.75, 0.75, 1)
        slot:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        
        -- Get the corresponding Blizzard button
        local blizzButton = _G[config.blizzardButtons .. i]
        if blizzButton then
            -- Hide the Blizzard button visually but keep it in hierarchy for Edit Mode
            blizzButton:Hide()
            blizzButton:SetAlpha(0)
            -- DON'T reparent the button - Edit Mode may need to reference it
            self:SetupCustomIconSlot(slot, blizzButton, i)
        end
        
        row.iconSlots[i] = slot
    end
    
    -- Store the separate bar
    window.actionBarRow = row
    self.separateBars[barId] = window
    
    window:Show()
    WoW95:Debug("Created separate action bar: " .. barId)
end

function ActionBars:ToggleLock()
    self.locked = not self.locked
    
    if self.lockIcon then
        self.lockIcon:SetText(self.locked and "🔒" or "🔓")
    end
    
    -- Update all separate bars' lock state
    for _, window in pairs(self.separateBars) do
        if window.titleBar then
            if self.locked then
                window.titleBar:SetScript("OnDragStart", nil)
            else
                window.titleBar:SetScript("OnDragStart", function()
                    window:StartMoving()
                end)
            end
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
    
    -- Only hide visual elements, don't reparent frames that Edit Mode needs
    -- IMPORTANT: Do NOT hide MicroButtonAndBagsBar - Edit Mode needs it
    local framesToHide = {
        "MainMenuBar", "MainMenuBarArtFrame", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
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

-- Register the module
WoW95:RegisterModule("ActionBars", ActionBars)