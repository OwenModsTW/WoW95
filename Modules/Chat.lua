-- WoW95 Chat Module
-- Windows 95 styled chat frames with proper functionality

local addonName, WoW95 = ...

local Chat = {}
WoW95.Chat = Chat

-- Chat settings
local CHAT_WIDTH = 400
local CHAT_HEIGHT = 200
local TITLE_BAR_HEIGHT = 18
local CHAT_MIN_WIDTH = 250
local CHAT_MIN_HEIGHT = 150
local CHAT_MAX_WIDTH = 800
local CHAT_MAX_HEIGHT = 600

-- Chat state
Chat.frames = {}
Chat.currentFrame = nil
Chat.frameCount = 0
Chat.locked = false

-- Default chat frame configuration
Chat.defaultFrames = {
    {
        name = "General",
        channels = {"SAY", "EMOTE", "YELL", "WHISPER", "PARTY", "RAID", "GUILD", "OFFICER", "ACHIEVEMENT", "SYSTEM"},
        position = {x = 20, y = 20}, -- Bottom-left corner with small padding
        isMainFrame = true,
        defaultTabs = {
            {name = "General", channels = {"SAY", "EMOTE", "YELL", "WHISPER", "PARTY", "RAID", "GUILD", "OFFICER", "ACHIEVEMENT", "SYSTEM"}},
            {name = "Combat Log", channels = {"COMBAT_XP_GAIN", "COMBAT_HONOR_GAIN", "COMBAT_FACTION_CHANGE", "SPELL_DAMAGE", "SPELL_HEAL"}}
        }
    }
}

function Chat:Init()
    WoW95:Debug("Initializing Chat module...")
    
    -- Initialize saved variables if they don't exist (with safety checks)
    if not _G.WoW95DB then
        _G.WoW95DB = {}
    end
    if not WoW95DB.chatFrames then
        WoW95DB.chatFrames = {}
    end
    
    -- Hide default Blizzard chat frames first
    self:HideBlizzardChatFrames()
    
    -- Delay creation slightly to ensure Blizzard frames are hidden
    C_Timer.After(0.5, function()
        -- Get user's existing chat configuration from Blizzard frames
        self:ImportBlizzardChatConfiguration()
        
        -- Load saved chat configuration or use defaults
        self:LoadChatConfiguration()
        
        -- Create our Windows 95 chat frames
        self:CreateDefaultChatFrames()
        
        -- Hook chat events
        self:HookChatEvents()
        
        -- Hook enter key for chat activation
        self:HookEnterKey()
        
        WoW95:Debug("Chat module initialized successfully!")
    end)
end

function Chat:LoadChatConfiguration()
    -- Load saved chat frame positions and tabs (with safety checks)
    if not _G.WoW95DB then
        WoW95:Debug("WoW95DB not available, using defaults")
        return
    end
    
    if WoW95DB.chatFrames and WoW95DB.chatFrames[1] then
        local saved = WoW95DB.chatFrames[1]
        
        -- Update position if saved
        if saved.position then
            self.defaultFrames[1].position = saved.position
            WoW95:Debug("Loaded saved chat position: " .. saved.position.x .. ", " .. saved.position.y)
        end
        
        -- Update tabs if saved
        if saved.tabs and #saved.tabs > 0 then
            self.defaultFrames[1].defaultTabs = saved.tabs
            WoW95:Debug("Loaded " .. #saved.tabs .. " saved chat tabs")
        end
    else
        WoW95:Debug("No saved chat configuration found, using defaults")
    end
end

function Chat:SaveChatConfiguration()
    -- Save current chat configuration (with safety checks)
    if not _G.WoW95DB then
        WoW95:Debug("WoW95DB not available, cannot save chat configuration")
        return
    end
    
    if not WoW95DB.chatFrames then
        WoW95DB.chatFrames = {}
    end
    
    for frameName, frameData in pairs(self.frames) do
        if frameData.window.isMainFrame then
            -- Get current position
            local point, relativeTo, relativePoint, xOfs, yOfs = frameData.window:GetPoint()
            
            -- Save tabs configuration
            local tabs = {}
            for _, tabData in ipairs(frameData.tabs) do
                table.insert(tabs, {
                    name = tabData.name,
                    channels = tabData.channels,
                    isPermanent = tabData.isPermanent
                })
            end
            
            WoW95DB.chatFrames[1] = {
                position = {x = xOfs or 20, y = yOfs or 20},
                tabs = tabs
            }
            
            WoW95:Debug("Saved chat configuration - Position: " .. (xOfs or 20) .. ", " .. (yOfs or 20) .. " - Tabs: " .. #tabs)
            break
        end
    end
end

function Chat:ImportBlizzardChatConfiguration()
    -- Import existing chat configuration from Blizzard UI
    local importedTabs = {}
    
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame and frame:IsShown() then
            local name = frame.name or ("Chat " .. i)
            local messageTypes = {}
            
            -- Get message types for this frame
            for j = 1, #frame.messageTypeList do
                table.insert(messageTypes, frame.messageTypeList[j])
            end
            
            -- Only import if it has message types
            if #messageTypes > 0 then
                table.insert(importedTabs, {
                    name = name,
                    channels = messageTypes,
                    isPermanent = (i == 1) -- First tab is always permanent like Blizzard
                })
                WoW95:Debug("Imported tab: " .. name .. " with " .. #messageTypes .. " channels")
            end
        end
    end
    
    -- Update our default configuration with imported tabs
    if #importedTabs > 0 then
        self.defaultFrames[1].defaultTabs = importedTabs
        WoW95:Debug("Imported " .. #importedTabs .. " tabs from Blizzard chat")
    end
end

function Chat:CreateDefaultChatFrames()
    for i, config in ipairs(self.defaultFrames) do
        local frame = self:CreateChatFrame(config.name, config.channels, config.position.x, config.position.y, config.isMainFrame)
        
        -- Create additional tabs for main frame using imported config
        if config.defaultTabs and #config.defaultTabs > 1 then
            for j = 2, #config.defaultTabs do
                local tabConfig = config.defaultTabs[j]
                self:CreateChatTab(frame, tabConfig.name, tabConfig.channels, false, tabConfig.isPermanent or false)
            end
        end
    end
end

function Chat:CreateChatFrame(name, channels, x, y, isMainFrame)
    self.frameCount = self.frameCount + 1
    local frameName = "WoW95ChatFrame" .. self.frameCount
    
    -- Create main chat window
    local chatWindow = WoW95:CreateWindow(frameName, UIParent, CHAT_WIDTH, CHAT_HEIGHT, name)
    chatWindow:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x or 20, y or 20)
    
    -- Make window movable and add position saving
    chatWindow:SetMovable(true)
    chatWindow:EnableMouse(true)
    if chatWindow.titleBar then
        chatWindow.titleBar:EnableMouse(true)
        chatWindow.titleBar:SetScript("OnDragStart", function()
            chatWindow:StartMoving()
        end)
        chatWindow.titleBar:SetScript("OnDragStop", function()
            chatWindow:StopMovingOrSizing()
            -- Save position when moved
            if isMainFrame then
                self:SaveChatConfiguration()
            end
        end)
    end
    
    -- Disable close button for main frame
    if isMainFrame then
        chatWindow.closeButton:Hide()
        chatWindow.isMainFrame = true
    end
    
    -- Make the main window title bar blue (Windows 95 style) - FORCE IT
    if chatWindow.titleBar then
        -- Override any existing styling
        chatWindow.titleBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        chatWindow.titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1) -- Windows 95 blue
        chatWindow.titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        if chatWindow.titleText then
            chatWindow.titleText:SetTextColor(1, 1, 1, 1) -- White text on blue
            chatWindow.titleText:SetShadowOffset(1, -1)
            chatWindow.titleText:SetShadowColor(0, 0, 0, 0.8)
        end
        
        WoW95:Debug("Set title bar to blue for frame: " .. name)
    end
    
    -- Store resize limits manually
    chatWindow.minWidth = CHAT_MIN_WIDTH
    chatWindow.minHeight = CHAT_MIN_HEIGHT
    chatWindow.maxWidth = CHAT_MAX_WIDTH
    chatWindow.maxHeight = CHAT_MAX_HEIGHT
    
    -- Create tab container
    local tabContainer = CreateFrame("Frame", frameName .. "TabContainer", chatWindow, "BackdropTemplate")
    tabContainer:SetPoint("TOPLEFT", chatWindow.titleBar, "BOTTOMLEFT", 4, 0)
    tabContainer:SetPoint("TOPRIGHT", chatWindow.titleBar, "BOTTOMRIGHT", -4, 0)
    tabContainer:SetHeight(20)
    
    -- Tab container backdrop (keep gray, not blue)
    tabContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    tabContainer:SetBackdropColor(0.75, 0.75, 0.75, 1) -- Gray like Windows 95
    tabContainer:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", frameName .. "ScrollFrame", chatWindow, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", chatWindow, "BOTTOMRIGHT", -26, 44)
    
    -- Create chat display
    local chatDisplay = CreateFrame("Frame", frameName .. "Display", scrollFrame)
    chatDisplay:SetSize(CHAT_WIDTH - 34, CHAT_HEIGHT - 70)
    scrollFrame:SetScrollChild(chatDisplay)
    
    -- Create chat text (black text, no shadow - better readability)
    local chatText = chatDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatText:SetPoint("TOPLEFT", chatDisplay, "TOPLEFT", 4, -4)
    chatText:SetPoint("TOPRIGHT", chatDisplay, "TOPRIGHT", -4, -4)
    chatText:SetJustifyH("LEFT")
    chatText:SetJustifyV("TOP")
    chatText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    chatText:SetTextColor(0, 0, 0, 1)
    chatText:SetShadowOffset(0, 0)
    chatText:SetText("")
    
    -- Create input box
    local inputBox = CreateFrame("EditBox", frameName .. "InputBox", chatWindow, "InputBoxTemplate,BackdropTemplate")
    inputBox:SetSize(CHAT_WIDTH - 16, 20)
    inputBox:SetPoint("BOTTOMLEFT", chatWindow, "BOTTOMLEFT", 8, 4)
    inputBox:SetPoint("BOTTOMRIGHT", chatWindow, "BOTTOMRIGHT", -8, 4)
    inputBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    inputBox:SetTextColor(0, 0, 0, 1)
    inputBox:SetShadowOffset(0, 0)
    inputBox:SetAutoFocus(false)
    
    -- Input box styling
    if inputBox.SetBackdrop then
        inputBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        inputBox:SetBackdropColor(1, 1, 1, 1)
        inputBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    
    -- Create channel button
    local channelButton = WoW95:CreateButton(frameName .. "ChannelButton", chatWindow, 60, 18, "General")
    channelButton:SetPoint("BOTTOMLEFT", inputBox, "TOPLEFT", 0, 2)
    if channelButton.text then
        channelButton.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    end
    
    -- Create lock button
    local lockButton = CreateFrame("Button", frameName .. "LockButton", chatWindow.titleBar, "BackdropTemplate")
    lockButton:SetSize(16, 14)
    lockButton:SetPoint("RIGHT", chatWindow.closeButton, "LEFT", -20, 0)
    
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
    
    local lockText = lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockText:SetPoint("CENTER")
    lockText:SetText("🔓")
    lockText:SetTextColor(0, 0, 0, 1)
    lockText:SetShadowOffset(0, 0)
    lockText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    
    -- Create minimize button using custom texture
    local minimizeButton = WoW95:CreateTitleBarButton(frameName .. "MinimizeButton", chatWindow.titleBar, WoW95.textures.minimize, 16)
    minimizeButton:SetPoint("RIGHT", lockButton, "LEFT", -2, 0)
    
    -- Create new tab button
    local newTabButton = WoW95:CreateButton(frameName .. "NewTabButton", tabContainer, 20, 18, "+")
    newTabButton:SetPoint("RIGHT", tabContainer, "RIGHT", -2, 0)
    if newTabButton.text then
        newTabButton.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- Store frame data
    local frameData = {
        window = chatWindow,
        scrollFrame = scrollFrame,
        chatDisplay = chatDisplay,
        chatText = chatText,
        inputBox = inputBox,
        channelButton = channelButton,
        minimizeButton = minimizeButton,
        lockButton = lockButton,
        tabContainer = tabContainer,
        newTabButton = newTabButton,
        name = name,
        channels = channels or {},
        messages = {},
        currentChannel = "SAY",
        isMinimized = false,
        isLocked = false,
        tabs = {}
    }
    
    -- Set up event handlers
    inputBox:SetScript("OnEnterPressed", function()
        local text = inputBox:GetText()
        if text and text ~= "" then
            self:SendChatMessage(text, frameData)
            inputBox:SetText("")
        end
        inputBox:ClearFocus()
    end)
    
    inputBox:SetScript("OnEscapePressed", function()
        inputBox:SetText("")
        inputBox:ClearFocus()
    end)
    
    channelButton:SetScript("OnClick", function()
        self:ShowChannelMenu(frameData)
    end)
    
    channelButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(channelButton, "ANCHOR_TOP")
        GameTooltip:SetText("Current Channel: " .. (frameData.currentChannel or "SAY"))
        GameTooltip:AddLine("Click to change channel", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    channelButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    lockButton:SetScript("OnClick", function()
        self:ToggleLockFrame(frameData)
    end)
    
    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(lockButton, "ANCHOR_TOP")
        if frameData.isLocked then
            GameTooltip:SetText("Chat is LOCKED")
            GameTooltip:AddLine("Click to unlock", 1, 1, 1)
        else
            GameTooltip:SetText("Chat is UNLOCKED")
            GameTooltip:AddLine("Click to lock", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    
    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    minimizeButton:SetScript("OnClick", function()
        self:ToggleMinimize(frameData)
    end)
    
    minimizeButton:SetScript("OnEnter", function()
        minimizeButton:SetBackdropColor(0.85, 0.85, 0.85, 1)
        GameTooltip:SetOwner(minimizeButton, "ANCHOR_TOP")
        if frameData.isMinimized then
            GameTooltip:SetText("Chat is MINIMIZED")
            GameTooltip:AddLine("Click to restore", 1, 1, 1)
        else
            GameTooltip:SetText("Chat is RESTORED")
            GameTooltip:AddLine("Click to minimize", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    
    minimizeButton:SetScript("OnLeave", function()
        minimizeButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
        GameTooltip:Hide()
    end)
    
    newTabButton:SetScript("OnClick", function()
        self:ShowNewTabDialog(frameData)
    end)
    
    newTabButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(newTabButton, "ANCHOR_TOP")
        GameTooltip:SetText("Create New Chat Tab")
        GameTooltip:AddLine("Click to add a new tab", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    newTabButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Create default tab (permanent, cannot be deleted)
    self:CreateChatTab(frameData, name, channels, true, true)
    
    -- Hook window resize
    chatWindow:SetScript("OnSizeChanged", function()
        self:UpdateChatFrameSize(frameData)
    end)
    
    self.frames[frameName] = frameData
    chatWindow:Show()
    
    if not self.currentFrame then
        self.currentFrame = frameData
    end
    
    WoW95:Debug("Created chat frame: " .. name)
    return frameData
end

function Chat:UpdateChatFrameSize(frameData)
    local width, height = frameData.window:GetSize()
    frameData.chatDisplay:SetSize(width - 34, height - 90)
    frameData.inputBox:SetPoint("BOTTOMRIGHT", frameData.window, "BOTTOMRIGHT", -8, 4)
end

function Chat:CreateChatTab(frameData, tabName, channels, isActive, isPermanent)
    local tabContainer = frameData.tabContainer
    local tabButton = WoW95:CreateButton("ChatTab" .. #frameData.tabs + 1, tabContainer, 80, 18, tabName)
    
    -- Position tab
    local xOffset = 4
    for i, tab in ipairs(frameData.tabs) do
        xOffset = xOffset + tab.button:GetWidth() + 2
    end
    tabButton:SetPoint("LEFT", tabContainer, "LEFT", xOffset, 0)
    
    -- Tab data
    local tabData = {
        name = tabName,
        channels = channels or {},
        messages = {},
        button = tabButton,
        isActive = isActive or false,
        isPermanent = isPermanent or false
    }
    
    -- Enable mouse interactions on the tab button
    tabButton:EnableMouse(true)
    tabButton:SetFrameLevel(tabContainer:GetFrameLevel() + 2)
    tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Tab click functionality
    tabButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            Chat:SwitchToTab(frameData, tabData)
            WoW95:Debug("Left-clicked tab: " .. tabName)
        elseif button == "RightButton" then
            Chat:ShowTabSettingsMenu(frameData, tabData)
            WoW95:Debug("Right-clicked tab: " .. tabName)
        end
    end)
    
    -- Alternative mouse handlers for better compatibility
    tabButton:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            Chat:ShowTabSettingsMenu(frameData, tabData)
            WoW95:Debug("Right mouse up on tab: " .. tabName)
        end
    end)
    
    -- Tab tooltips
    tabButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tabButton, "ANCHOR_TOP")
        GameTooltip:SetText("Chat Tab: " .. tabName)
        GameTooltip:AddLine("Left-click to switch", 1, 1, 1)
        if not tabData.isPermanent then
            GameTooltip:AddLine("Right-click for settings", 1, 1, 1)
        else
            GameTooltip:AddLine("Right-click for settings (cannot delete)", 1, 0.8, 0.8)
        end
        GameTooltip:Show()
        WoW95:Debug("Showing tooltip for tab: " .. tabName)
    end)
    
    tabButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Set active appearance
    if isActive then
        tabButton:SetBackdropColor(1, 1, 1, 1)
        frameData.activeTab = tabData
        WoW95:Debug("Set tab as active: " .. tabName)
    else
        tabButton:SetBackdropColor(0.75, 0.75, 0.75, 1)
    end
    
    table.insert(frameData.tabs, tabData)
    WoW95:Debug("Created tab: " .. tabName .. " (Total tabs: " .. #frameData.tabs .. ", Permanent: " .. tostring(isPermanent) .. ")")
    return tabData
end

function Chat:SwitchToTab(frameData, tabData)
    WoW95:Debug("Switching to tab: " .. tabData.name)
    
    -- Update all tabs appearance
    for _, tab in ipairs(frameData.tabs) do
        if tab == tabData then
            if tab.button and tab.button.SetBackdropColor then
                tab.button:SetBackdropColor(1, 1, 1, 1)
            end
            tab.isActive = true
            frameData.activeTab = tab
            WoW95:Debug("Set tab active: " .. tab.name)
        else
            if tab.button and tab.button.SetBackdropColor then
                tab.button:SetBackdropColor(0.75, 0.75, 0.75, 1)
            end
            tab.isActive = false
        end
    end
    
    -- Update chat display with tab's messages
    local displayText = table.concat(tabData.messages, "\n")
    if frameData.chatText then
        frameData.chatText:SetText(displayText)
        WoW95:Debug("Updated chat display with " .. #tabData.messages .. " messages")
    end
    
    -- Update channels
    frameData.channels = tabData.channels
    
    -- Scroll to bottom
    C_Timer.After(0.1, function()
        if frameData.scrollFrame then
            frameData.scrollFrame:SetVerticalScroll(frameData.scrollFrame:GetVerticalScrollRange())
        end
    end)
end

function Chat:ShowNewTabDialog(frameData)
    local dialog = CreateFrame("Frame", "WoW95NewTabDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(300, 170)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("TOOLTIP")
    dialog:SetFrameLevel(400)
    
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    dialog:SetBackdropColor(0.75, 0.75, 0.75, 1)
    dialog:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create Windows 95 blue title bar
    local titleBar = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", dialog, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    title:SetText("Create New Chat Tab")
    title:SetTextColor(1, 1, 1, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 15, -25)
    nameLabel:SetText("Tab Name:")
    nameLabel:SetTextColor(0, 0, 0, 1)
    nameLabel:SetShadowOffset(0, 0)
    
    local nameInput = CreateFrame("EditBox", "NewTabNameInput", dialog, "InputBoxTemplate")
    nameInput:SetSize(150, 20)
    nameInput:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameInput:SetText("New Tab")
    nameInput:SetAutoFocus(true)
    
    local okButton = WoW95:CreateButton("NewTabOK", dialog, 60, 24, "OK")
    okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 15)
    okButton:SetScript("OnClick", function()
        local tabName = nameInput:GetText()
        if tabName and tabName ~= "" then
            self:CreateChatTab(frameData, tabName, {"SAY"}, false, false)
            -- Save configuration when new tab is created
            self:SaveChatConfiguration()
        end
        dialog:Hide()
    end)
    
    local cancelButton = WoW95:CreateButton("NewTabCancel", dialog, 60, 24, "Cancel")
    cancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 15)
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function Chat:ShowTabSettingsMenu(frameData, tabData)
    WoW95:Debug("Showing tab settings menu for: " .. tabData.name)
    
    local menu = CreateFrame("Frame", "WoW95TabSettingsMenu", UIParent, "BackdropTemplate")
    menu:SetSize(150, 100)
    
    -- Get cursor position and set menu position safely
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale
    
    menu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + 10, y - 10)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(1000)
    
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    menu:SetBackdropColor(0.75, 0.75, 0.75, 1)
    menu:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local options = {"Rename Tab", "Configure Channels"}
    
    -- Only add Close Tab option if not permanent
    if not tabData.isPermanent then
        table.insert(options, "Close Tab")
    end
    
    for i, option in ipairs(options) do
        local button = WoW95:CreateButton("TabSettingsOption" .. i, menu, 130, 20, option)
        button:SetPoint("TOP", menu, "TOP", 0, -(i-1) * 22 - 8)
        button:EnableMouse(true)
        button:SetFrameLevel(menu:GetFrameLevel() + 1)
        
        if button.text then
            button.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        end
        
        button:SetScript("OnClick", function()
            WoW95:Debug("Clicked menu option: " .. option)
            if option == "Close Tab" then
                if #frameData.tabs > 1 and not tabData.isPermanent then
                    self:CloseTab(frameData, tabData)
                else
                    WoW95:Print("Cannot close this tab!")
                end
            elseif option == "Rename Tab" then
                self:ShowRenameTabDialog(frameData, tabData)
            elseif option == "Configure Channels" then
                self:ShowChannelConfigDialog(frameData, tabData)
            end
            menu:Hide()
        end)
        
        -- Add button tooltips
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            if option == "Close Tab" and tabData.isPermanent then
                GameTooltip:SetText("Cannot close permanent tab")
            else
                GameTooltip:SetText("Click to " .. option:lower())
            end
            GameTooltip:Show()
        end)
        
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Close menu when clicking outside
    local closeFrame = CreateFrame("Frame", nil, UIParent)
    closeFrame:SetAllPoints(UIParent)
    closeFrame:SetFrameStrata("TOOLTIP")
    closeFrame:SetFrameLevel(990)
    closeFrame:EnableMouse(true)
    closeFrame:SetScript("OnMouseDown", function()
        WoW95:Debug("Closing tab settings menu")
        menu:Hide()
        closeFrame:Hide()
    end)
    
    menu:Show()
    C_Timer.After(0.1, function() 
        closeFrame:Show() 
        WoW95:Debug("Tab settings menu displayed")
    end)
end

function Chat:ShowRenameTabDialog(frameData, tabData)
    local dialog = CreateFrame("Frame", "WoW95RenameTabDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(300, 140)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("TOOLTIP")
    dialog:SetFrameLevel(600)
    
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    dialog:SetBackdropColor(0.75, 0.75, 0.75, 1)
    dialog:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create Windows 95 blue title bar
    local titleBar = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", dialog, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    title:SetText("Rename Tab")
    title:SetTextColor(1, 1, 1, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 15, -25)
    nameLabel:SetText("New Name:")
    nameLabel:SetTextColor(0, 0, 0, 1)
    nameLabel:SetShadowOffset(0, 0)
    
    local nameInput = CreateFrame("EditBox", "RenameTabInput", dialog, "InputBoxTemplate")
    nameInput:SetSize(150, 20)
    nameInput:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameInput:SetText(tabData.name)
    nameInput:SetAutoFocus(true)
    
    local okButton = WoW95:CreateButton("RenameTabOK", dialog, 60, 24, "OK")
    okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 15)
    okButton:SetScript("OnClick", function()
        local newName = nameInput:GetText()
        if newName and newName ~= "" then
            tabData.name = newName
            if tabData.button and tabData.button.text then
                tabData.button.text:SetText(newName)
            end
            -- Save configuration when tab is renamed
            self:SaveChatConfiguration()
        end
        dialog:Hide()
    end)
    
    local cancelButton = WoW95:CreateButton("RenameTabCancel", dialog, 60, 24, "Cancel")
    cancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 15)
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function Chat:ShowChannelConfigDialog(frameData, tabData)
    local dialog = CreateFrame("Frame", "WoW95ChannelConfigDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(400, 450)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("TOOLTIP")
    dialog:SetFrameLevel(600)
    
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    dialog:SetBackdropColor(0.75, 0.75, 0.75, 1)
    dialog:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create Windows 95 blue title bar
    local titleBar = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", dialog, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(20)
    
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    titleBar:SetBackdropColor(0.0, 0.0, 0.5, 1)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    title:SetText("Configure Channels for: " .. tabData.name)
    title:SetTextColor(1, 1, 1, 1)
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Adjust content area to account for title bar
    local contentArea = CreateFrame("Frame", nil, dialog)
    contentArea:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -10)
    contentArea:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 50)
    
    local availableChannels = {
        "SAY", "YELL", "WHISPER", "WHISPER_INFORM", "EMOTE",
        "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", 
        "GUILD", "OFFICER", "SYSTEM", "ACHIEVEMENT", 
        "LOOT", "MONEY", "TRADESKILLS", "COMBAT_XP_GAIN",
        "COMBAT_HONOR_GAIN", "COMBAT_FACTION_CHANGE",
        "BG_HORDE", "BG_ALLIANCE", "BG_NEUTRAL",
        "CHANNEL1", "CHANNEL2", "CHANNEL3", "CHANNEL4", "CHANNEL5",
        "AFK", "DND", "IGNORED", "SKILL", "LOOT",
        "CURRENCY", "MONSTER_SAY", "MONSTER_YELL", "MONSTER_EMOTE",
        "MONSTER_WHISPER", "MONSTER_BOSS_EMOTE", "MONSTER_BOSS_WHISPER",
        "ERRORS", "TEXT_EMOTE", "TARGETICONS", "BN_WHISPER",
        "BN_WHISPER_INFORM", "BN_CONVERSATION", "BN_INLINE_TOAST_ALERT"
    }
    local checkboxes = {}
    
    for i, channel in ipairs(availableChannels) do
        local checkbox = CreateFrame("CheckButton", "ChannelCheckbox" .. i, dialog, "UICheckButtonTemplate")
        checkbox:SetSize(16, 16) -- Smaller checkboxes
        
        -- Position in 3 columns with better spacing
        local x = 15 + ((i-1) % 3) * 125
        local y = -15 - math.floor((i-1) / 3) * 22
        checkbox:SetPoint("TOPLEFT", contentArea, "TOPLEFT", x, y)
        
        local label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0) -- More space between checkbox and text
        label:SetText(channel)
        label:SetTextColor(0, 0, 0, 1)
        label:SetShadowOffset(0, 0)
        label:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
        
        -- Check if channel is currently enabled
        local isEnabled = false
        for _, enabledChannel in ipairs(tabData.channels) do
            if enabledChannel == channel then
                isEnabled = true
                break
            end
        end
        checkbox:SetChecked(isEnabled)
        
        checkboxes[channel] = checkbox
    end
    
    local okButton = WoW95:CreateButton("ChannelConfigOK", dialog, 60, 24, "OK")
    okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 15)
    okButton:SetScript("OnClick", function()
        -- Update tab channels based on checkboxes
        tabData.channels = {}
        for channel, checkbox in pairs(checkboxes) do
            if checkbox:GetChecked() then
                table.insert(tabData.channels, channel)
            end
        end
        -- Save configuration when channels are changed
        self:SaveChatConfiguration()
        dialog:Hide()
    end)
    
    local cancelButton = WoW95:CreateButton("ChannelConfigCancel", dialog, 60, 24, "Cancel")
    cancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 15)
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    dialog:Show()
end

function Chat:CloseTab(frameData, tabData)
    if #frameData.tabs <= 1 then
        WoW95:Print("Cannot close the last tab!")
        return
    end
    
    -- Remove tab from list
    for i, tab in ipairs(frameData.tabs) do
        if tab == tabData then
            table.remove(frameData.tabs, i)
            break
        end
    end
    
    -- Hide and destroy tab button
    tabData.button:Hide()
    
    -- Switch to first remaining tab if this was active
    if tabData.isActive and #frameData.tabs > 0 then
        self:SwitchToTab(frameData, frameData.tabs[1])
    end
    
    -- Reposition remaining tabs
    local xOffset = 4
    for i, tab in ipairs(frameData.tabs) do
        tab.button:ClearAllPoints()
        tab.button:SetPoint("LEFT", frameData.tabContainer, "LEFT", xOffset, 0)
        xOffset = xOffset + tab.button:GetWidth() + 2
    end
    
    -- Save configuration when tab is closed
    self:SaveChatConfiguration()
end

function Chat:ToggleLockFrame(frameData)
    frameData.isLocked = not frameData.isLocked
    
    WoW95:Debug("Toggling lock for frame: " .. frameData.name .. " to " .. (frameData.isLocked and "LOCKED" or "UNLOCKED"))
    
    -- Update lock button text
    if frameData.lockButton then
        -- Find the text child safely
        local lockText = frameData.lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if not lockText then
            lockText = frameData.lockButton:GetFontString()
        end
        
        if frameData.lockButton.lockText then
            lockText = frameData.lockButton.lockText
        else
            -- Create and store the text element
            lockText = frameData.lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lockText:SetPoint("CENTER")
            lockText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
            lockText:SetTextColor(0, 0, 0, 1)
    lockText:SetShadowOffset(0, 0)
            frameData.lockButton.lockText = lockText
        end
        
        if frameData.isLocked then
            lockText:SetText("🔒")
            -- Disable moving and resizing
            frameData.window:SetMovable(false)
            frameData.window:EnableMouse(false)
            if frameData.window.titleBar then
                frameData.window.titleBar:SetScript("OnDragStart", nil)
                frameData.window.titleBar:SetScript("OnDragStop", nil)
                frameData.window.titleBar:EnableMouse(false)
            end
            WoW95:Print("Chat frame LOCKED - cannot move")
        else
            lockText:SetText("🔓")
            -- Enable moving and resizing
            frameData.window:SetMovable(true)
            frameData.window:EnableMouse(true)
            if frameData.window.titleBar then
                frameData.window.titleBar:EnableMouse(true)
                frameData.window.titleBar:SetScript("OnDragStart", function()
                    frameData.window:StartMoving()
                    WoW95:Debug("Started moving window")
                end)
                frameData.window.titleBar:SetScript("OnDragStop", function()
                    frameData.window:StopMovingOrSizing()
                    WoW95:Debug("Stopped moving window")
                end)
            end
            WoW95:Print("Chat frame UNLOCKED - can move")
        end
    end
    
    WoW95:Debug("Lock state updated successfully")
end

function Chat:ToggleMinimize(frameData)
    if frameData.isMinimized then
        frameData.scrollFrame:Show()
        frameData.inputBox:Show()
        frameData.channelButton:Show()
        frameData.tabContainer:Show()
        frameData.window:SetHeight(CHAT_HEIGHT)
        
        -- Update minimize button texture to minimize icon
        if frameData.minimizeButton and frameData.minimizeButton.icon then
            frameData.minimizeButton.icon:SetTexture(WoW95.textures.minimize)
        end
        frameData.isMinimized = false
    else
        frameData.scrollFrame:Hide()
        frameData.inputBox:Hide()
        frameData.channelButton:Hide()
        frameData.tabContainer:Hide()
        frameData.window:SetHeight(TITLE_BAR_HEIGHT + 8)
        
        -- Update minimize button texture to maximize icon
        if frameData.minimizeButton and frameData.minimizeButton.icon then
            frameData.minimizeButton.icon:SetTexture(WoW95.textures.maximize)
        end
        frameData.isMinimized = true
    end
end

function Chat:ShowChannelMenu(frameData)
    local menu = CreateFrame("Frame", "WoW95ChatChannelMenu", UIParent, "BackdropTemplate")
    menu:SetSize(120, 200)
    menu:SetPoint("BOTTOMLEFT", frameData.channelButton, "TOPLEFT", 0, 0)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(300)
    
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    menu:SetBackdropColor(0.75, 0.75, 0.75, 1)
    menu:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local channels = {"SAY", "YELL", "PARTY", "RAID", "GUILD", "WHISPER", "EMOTE"}
    
    for i, channel in ipairs(channels) do
        local button = WoW95:CreateButton("ChannelButton" .. i, menu, 100, 20, channel)
        button:SetPoint("TOP", menu, "TOP", 0, -(i-1) * 22 - 8)
        if button.text then
            button.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        end
        
        button:SetScript("OnClick", function()
            frameData.currentChannel = channel
            if frameData.channelButton and frameData.channelButton.text then
                frameData.channelButton.text:SetText(channel)
            end
            menu:Hide()
        end)
    end
    
    menu:Show()
end

function Chat:SendChatMessage(text, frameData)
    if not frameData then return end
    
    -- Handle ALL slash commands by directly executing them
    if string.sub(text, 1, 1) == "/" then
        WoW95:Debug("Executing slash command: " .. text)
        
        -- Use WoW's built-in chat frame system to execute the command
        if ChatFrame1 and ChatFrame1.editBox then
            ChatFrame1.editBox:SetText(text)
            ChatEdit_SendText(ChatFrame1.editBox)
            WoW95:Debug("Command sent through Blizzard system: " .. text)
        else
            -- Fallback method
            local success, result = pcall(function()
                -- Split command and arguments
                local command, args = text:match("^(/[^%s]+)%s*(.*)")
                if command then
                    -- Try the slash command table
                    local slashCmd = SlashCmdList[string.upper(command:sub(2))]
                    if slashCmd then
                        slashCmd(args or "")
                        return true
                    end
                    
                    -- Try direct execution
                    RunSlashCmd(text)
                    return true
                end
                return false
            end)
            
            if success and result then
                WoW95:Debug("Successfully executed: " .. text)
            else
                WoW95:Debug("Failed to execute command: " .. text)
                -- Show error message like Blizzard would
                self:AddMessage(frameData, "Unknown command: " .. text, 1, 0, 0)
            end
        end
        return
    end
    
    -- Handle regular chat messages
    local chatType = frameData.currentChannel or "SAY"
    local target = nil
    
    -- Parse chat channel commands like /say, /guild, etc.
    if string.sub(text, 1, 1) == "/" then
        local command = string.match(text, "^/(%w+)")
        local message = string.match(text, "^/%w+%s+(.+)")
        
        if command == "say" or command == "s" then
            chatType = "SAY"
            text = message or ""
        elseif command == "yell" or command == "y" then
            chatType = "YELL"
            text = message or ""
        elseif command == "guild" or command == "g" then
            chatType = "GUILD"
            text = message or ""
        elseif command == "party" or command == "p" then
            chatType = "PARTY"
            text = message or ""
        elseif command == "raid" or command == "r" then
            chatType = "RAID"
            text = message or ""
        elseif command == "whisper" or command == "w" or command == "tell" or command == "t" then
            local targetName, whisperText = string.match(text, "^/%w+%s+(%S+)%s+(.+)")
            if targetName and whisperText then
                chatType = "WHISPER"
                target = targetName
                text = whisperText
            end
        end
    end
    
    -- Send the chat message
    if text and text ~= "" then
        if chatType == "WHISPER" and target then
            SendChatMessage(text, chatType, nil, target)
        else
            SendChatMessage(text, chatType)
        end
    end
end

function Chat:AddMessage(frameData, message, r, g, b)
    if not frameData or not message then return end
    
    local activeTab = frameData.activeTab
    if not activeTab then return end
    
    local timestamp = date("%H:%M:%S")
    local colorCode = string.format("|cFF%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
    local formattedMessage = string.format("[%s] %s%s|r", timestamp, colorCode, message)
    
    table.insert(activeTab.messages, formattedMessage)
    
    if #activeTab.messages > 100 then
        table.remove(activeTab.messages, 1)
    end
    
    local displayText = table.concat(activeTab.messages, "\n")
    frameData.chatText:SetText(displayText)
    
    C_Timer.After(0.1, function()
        frameData.scrollFrame:SetVerticalScroll(frameData.scrollFrame:GetVerticalScrollRange())
    end)
end

function Chat:HookEnterKey()
    -- Create invisible frame to capture Enter key globally
    local enterFrame = CreateFrame("Frame", "WoW95ChatEnterFrame", UIParent)
    enterFrame:SetAllPoints(UIParent)
    enterFrame:SetFrameStrata("BACKGROUND")
    enterFrame:SetFrameLevel(1)
    enterFrame:EnableKeyboard(true)
    enterFrame:SetPropagateKeyboardInput(true)
    
    -- Make sure frame can receive keyboard input
    enterFrame:SetScript("OnKeyUp", function(self, key)
        if key == "ENTER" or key == "NUMPADENTER" then
            -- Find the main chat frame and activate its input
            for _, frameData in pairs(Chat.frames) do
                if frameData.window.isMainFrame then
                    frameData.inputBox:SetFocus()
                    frameData.inputBox:Show()
                    Chat.currentFrame = frameData
                    WoW95:Debug("Enter key activated main chat input")
                    return
                end
            end
        end
    end)
    
    -- Alternative method: Hook the global ChatEdit functions
    local originalChatEdit_UpdateHeader = ChatEdit_UpdateHeader or function() end
    ChatEdit_UpdateHeader = function(editBox)
        -- Find our main chat frame and focus it instead
        for _, frameData in pairs(Chat.frames) do
            if frameData.window.isMainFrame then
                frameData.inputBox:SetFocus()
                frameData.inputBox:Show()
                Chat.currentFrame = frameData
                WoW95:Debug("ChatEdit hook activated main chat input")
                return
            end
        end
        originalChatEdit_UpdateHeader(editBox)
    end
    
    WoW95:Debug("Enter key hook installed")
end

function Chat:HookChatEvents()
    local eventFrame = CreateFrame("Frame")
    
    local chatEvents = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_EMOTE", "CHAT_MSG_SYSTEM",
        "CHAT_MSG_ACHIEVEMENT", "CHAT_MSG_LOOT", "CHAT_MSG_MONEY"
    }
    
    for _, event in ipairs(chatEvents) do
        eventFrame:RegisterEvent(event)
    end
    
    eventFrame:SetScript("OnEvent", function(self, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter)
        Chat:OnChatEvent(event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter)
    end)
end

function Chat:OnChatEvent(event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter)
    local chatType = string.gsub(event, "CHAT_MSG_", "")
    
    for _, frameData in pairs(self.frames) do
        if self:ShouldShowMessage(frameData, chatType) then
            local displayMessage = message
            
            if sender and sender ~= "" and sender ~= UnitName("player") then
                if chatType == "SAY" then
                    displayMessage = string.format("%s says: %s", sender, message)
                elseif chatType == "GUILD" then
                    displayMessage = string.format("[Guild] %s: %s", sender, message)
                elseif chatType == "WHISPER" then
                    displayMessage = string.format("%s whispers: %s", sender, message)
                else
                    displayMessage = string.format("[%s]: %s", sender, message)
                end
            end
            
            local r, g, b = self:GetMessageColor(chatType)
            self:AddMessage(frameData, displayMessage, r, g, b)
        end
    end
end

function Chat:ShouldShowMessage(frameData, chatType)
    if not frameData.activeTab then return false end
    
    for _, channel in ipairs(frameData.activeTab.channels) do
        if channel == chatType then
            return true
        end
    end
    return false
end

function Chat:GetMessageColor(chatType)
    local colors = {
        SAY = {0, 0, 0},
        YELL = {1, 0, 0},
        WHISPER = {1, 0, 1},
        WHISPER_INFORM = {1, 0, 1},
        PARTY = {0, 0, 1},
        PARTY_LEADER = {0, 0, 1},
        RAID = {1, 0.5, 0},
        RAID_LEADER = {1, 0.5, 0},
        GUILD = {0, 1, 0},
        OFFICER = {0, 0.7, 0},
        EMOTE = {1, 0.5, 0.25},
        SYSTEM = {1, 1, 0},
        ACHIEVEMENT = {1, 1, 0},
        LOOT = {0, 1, 1},
        MONEY = {1, 1, 0}
    }
    
    local color = colors[chatType] or {0, 0, 0}
    return color[1], color[2], color[3]
end

function Chat:HideBlizzardChatFrames()
    -- More aggressive hiding and disabling of Blizzard chat system
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            frame:EnableMouse(false)
            frame:SetMouseClickEnabled(false)
            frame:SetMouseMotionEnabled(false)
            -- Move frame completely out of the way
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
            -- Create invisible parent to isolate it
            local hiddenParent = CreateFrame("Frame")
            hiddenParent:Hide()
            frame:SetParent(hiddenParent)
        end
        
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            tab:Hide()
            tab:SetAlpha(0)
            tab:EnableMouse(false)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        end
        
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:Hide()
            editBox:SetAlpha(0)
            editBox:EnableMouse(false)
            editBox:ClearAllPoints()
            editBox:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        end
        
        -- Hide scrolling message frame
        local scrollingMessageFrame = _G["ChatFrame" .. i .. "ScrollingMessageFrame"]
        if scrollingMessageFrame then
            scrollingMessageFrame:Hide()
            scrollingMessageFrame:SetAlpha(0)
            scrollingMessageFrame:EnableMouse(false)
            scrollingMessageFrame:ClearAllPoints()
            scrollingMessageFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        end
    end
    
    -- Hide additional chat elements more aggressively
    local elementsToHide = {
        "ChatFrameMenuButton", "ChatFrameChannelButton", 
        "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton",
        "GeneralDockManager", "ChatAlertFrame", "QuickJoinToastButton",
        "ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton",
        "ChatFrameToggleVoiceMuteButton"
    }
    
    for _, elementName in ipairs(elementsToHide) do
        local element = _G[elementName]
        if element then
            element:Hide()
            element:SetAlpha(0)
            element:EnableMouse(false)
            if element.SetMouseClickEnabled then
                element:SetMouseClickEnabled(false)
            end
            if element.ClearAllPoints then
                element:ClearAllPoints()
                element:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
            end
        end
    end
    
    -- Completely disable the general dock manager
    if GeneralDockManager then
        GeneralDockManager:Hide()
        GeneralDockManager:SetAlpha(0)
        GeneralDockManager:EnableMouse(false)
        GeneralDockManager:ClearAllPoints()
        GeneralDockManager:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
    end
    
    -- Disable chat frame updates and events
    if ChatFrame_OnEvent then
        ChatFrame_OnEvent = function() end
    end
    if ChatEdit_OnTextChanged then
        ChatEdit_OnTextChanged = function() end
    end
    
    WoW95:Debug("Blizzard chat system completely disabled and moved out of bounds")
end

function Chat:Show()
    for _, frameData in pairs(self.frames) do
        frameData.window:Show()
    end
end

function Chat:Hide()
    for _, frameData in pairs(self.frames) do
        frameData.window:Hide()
    end
end

-- Register the module
WoW95:RegisterModule("Chat", Chat)