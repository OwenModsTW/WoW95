-- WoW95 Start Menu Module
-- Complete replacement for the Blizzard escape menu with Windows 95 styling

local addonName, WoW95 = ...

local StartMenu = {}
WoW95.StartMenu = StartMenu

-- Start Menu settings
local MENU_WIDTH = 200
local MENU_ITEM_HEIGHT = 24
local SUBMENU_WIDTH = 180
local SEPARATOR_HEIGHT = 4

-- Start Menu state
StartMenu.frame = nil
StartMenu.isOpen = false
StartMenu.currentSubmenu = nil

-- Menu structure - matches Blizzard's escape menu functionality
StartMenu.menuItems = {
    {
        text = "Programs",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        submenu = {
            {text = "Character Info", icon = "Interface\\Icons\\INV_Chest_Cloth_17", func = function() ToggleCharacter("PaperDollFrame") end},
            {text = "Spellbook & Abilities", icon = "Interface\\Icons\\INV_Misc_Book_11", func = function() 
                -- Try multiple spellbook opening methods
                local success = false
                
                -- Method 1: Try ToggleSpellBook
                if ToggleSpellBook then
                    local ok, err = pcall(ToggleSpellBook, "spell")
                    if ok then 
                        success = true 
                    else
                        WoW95:Debug("ToggleSpellBook failed: " .. tostring(err))
                    end
                end
                
                -- Method 2: Try PlayerSpellsFrame (modern)
                if not success and PlayerSpellsFrame then
                    local ok, err = pcall(function()
                        if PlayerSpellsFrame:IsShown() then
                            PlayerSpellsFrame:Hide()
                        else
                            PlayerSpellsFrame:Show()
                        end
                    end)
                    if ok then success = true end
                end
                
                -- Method 3: Try SpellBookFrame (legacy)
                if not success and SpellBookFrame then
                    local ok, err = pcall(function()
                        if SpellBookFrame:IsShown() then
                            HideUIPanel(SpellBookFrame)
                        else
                            ShowUIPanel(SpellBookFrame)
                        end
                    end)
                    if ok then success = true end
                end
                
                if not success then
                    WoW95:Print("Unable to open spellbook - try pressing P key")
                end
            end},
            {text = "Adventure Guide", icon = "Interface\\Icons\\INV_Misc_Map02", func = function() ToggleEncounterJournal() end},
            {text = "Collections", icon = "Interface\\Icons\\MountJournalPortrait", func = function() ToggleCollectionsJournal() end},
            {text = "Group Finder", icon = "Interface\\Icons\\INV_Helmet_08", func = function() PVEFrame_ToggleFrame() end},
            {text = "Guild & Communities", icon = "Interface\\Icons\\Achievement_GuildPerk_WorkingAsATeam", func = function() ToggleGuildFrame() end},
            {text = "Social", icon = "Interface\\Icons\\INV_Misc_GroupLooking", func = function() 
                -- Open vanilla Friends frame (Social UI)
                if ToggleFriendsFrame then
                    ToggleFriendsFrame(1) -- 1 = Friends tab
                else
                    WoW95:Print("Social window not available")
                end
            end},
        }
    },
    {
        text = "Documents",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        submenu = {
            {text = "Quest Log", icon = "Interface\\Icons\\INV_Misc_Note_06", func = function() ToggleQuestLog() end},
            {text = "Achievement", icon = "Interface\\Icons\\Achievement_General", func = function() ToggleAchievementFrame() end},
            {text = "Calendar", icon = "Interface\\Icons\\INV_Misc_Note_02", func = function() 
                if not CalendarFrame then 
                    if C_AddOns and C_AddOns.LoadAddOn then
                        C_AddOns.LoadAddOn("Blizzard_Calendar")
                    elseif LoadAddOn then
                        LoadAddOn("Blizzard_Calendar")
                    end
                end
                if Calendar_Toggle then Calendar_Toggle() end
            end},
            {text = "Dungeon Journal", icon = "Interface\\Icons\\INV_Misc_Book_17", func = function() ToggleEncounterJournal() end},
        }
    },
    {
        text = "Games",
        icon = "Interface\\Icons\\INV_Misc_Toy_10",
        submenu = {
            {text = "Minesweeper", icon = "Interface\\Icons\\INV_Misc_Bomb_05", func = function() 
                if WoW95.Games and WoW95.Games.OpenMinesweeper then
                    WoW95.Games:OpenMinesweeper()
                else
                    WoW95:Print("Games module not loaded!")
                end
            end},
            {text = "Solitaire", icon = "Interface\\Icons\\INV_Misc_Note_05", func = function() 
                WoW95:Print("Solitaire - Coming Soon!")
            end},
        }
    },
    {
        text = "Settings",
        icon = "Interface\\Icons\\INV_Gizmo_02",
        submenu = {
            {text = "Interface Options", icon = "Interface\\Icons\\Trade_Engineering", func = function() Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID) end},
            {text = "Key Bindings", icon = "Interface\\Icons\\INV_Misc_Key_03", func = function() Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID) end},
            {text = "Macros", icon = "Interface\\Icons\\INV_Misc_Note_04", func = function() 
                -- Execute the /macro slash command directly
                local success = false
                
                -- Method 1: Try the /macro slash command
                local ok, err = pcall(function()
                    ChatFrame1EditBox:SetText("/macro")
                    ChatEdit_SendText(ChatFrame1EditBox)
                    success = true
                end)
                
                if not success then
                    -- Method 2: Load addon and try direct functions
                    if C_AddOns and C_AddOns.LoadAddOn then
                        C_AddOns.LoadAddOn("Blizzard_MacroUI")
                    elseif LoadAddOn then
                        LoadAddOn("Blizzard_MacroUI")
                    end
                    
                    if MacroFrame then
                        local ok2, err2 = pcall(function()
                            MacroFrame:Show()
                            success = true
                        end)
                    end
                end
                
                if not success then
                    WoW95:Print("Unable to open macros - try typing /macro")
                end
            end},
            {text = "Add-Ons", icon = "Interface\\Icons\\Trade_Engineering", func = function() 
                -- Try multiple methods to open the addon interface
                local success = false
                
                -- Method 1: Try to load and show AddonList
                local ok1, err1 = pcall(function()
                    if C_AddOns and C_AddOns.LoadAddOn then
                        C_AddOns.LoadAddOn("Blizzard_AddonList")
                    elseif LoadAddOn then
                        LoadAddOn("Blizzard_AddonList")
                    end
                    
                    if AddonList and AddonList.Show then
                        AddonList:Show()
                        success = true
                    elseif AddonList_Show then
                        AddonList_Show()
                        success = true
                    end
                end)
                
                -- Method 2: Try opening through game menu
                if not success then
                    local ok2, err2 = pcall(function()
                        -- Set flag to allow game menu
                        StartMenu.allowGameMenu = true
                        
                        -- Show game menu
                        if StartMenu.originalToggleGameMenu then
                            StartMenu.originalToggleGameMenu()
                        end
                        
                        -- Wait and try to click the addons button
                        C_Timer.After(0.2, function()
                            if GameMenuFrame and GameMenuFrame:IsShown() then
                                for i = 1, GameMenuFrame:GetNumChildren() do
                                    local child = select(i, GameMenuFrame:GetChildren())
                                    if child and child:GetObjectType() == "Button" then
                                        local text = child:GetText()
                                        if text and (text:find("Add") or text:find("Addon")) then
                                            child:Click()
                                            success = true
                                            break
                                        end
                                    end
                                end
                            end
                            
                            -- Reset flag
                            StartMenu.allowGameMenu = false
                            
                            if not success then
                                WoW95:Print("Could not open Add-Ons - try Esc > AddOns manually")
                            end
                        end)
                    end)
                end
                
                -- Method 3: Fallback to slash command
                if not success then
                    C_Timer.After(0.1, function()
                        local ok3, err3 = pcall(function()
                            ChatFrame1EditBox:SetText("/addons")
                            ChatEdit_SendText(ChatFrame1EditBox)
                        end)
                        
                        if not ok3 then
                            WoW95:Print("Unable to open add-ons - try typing /addons or press Esc > AddOns")
                        end
                    end)
                end
            end},
            {text = "WoW95 Options", icon = "Interface\\Icons\\INV_Misc_Gear_01", func = function() StartMenu:ShowWoW95Options() end},
        }
    },
    {type = "separator"},
    {
        text = "Find",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_02",
        submenu = {
            {text = "Find Group", icon = "Interface\\Icons\\INV_Helmet_08", func = function() if PVEFrame then PVEFrame_ToggleFrame("GroupFinderFrame") else LFGParentFrame_Toggle() end end},
            {text = "Quick Join", icon = "Interface\\Icons\\INV_Misc_GroupLooking", func = function() if FriendsFrame then ToggleFriendsFrame(4) else print("Quick Join not available") end end},
            {text = "Who List", icon = "Interface\\Icons\\INV_Misc_Spyglass_02", func = function() 
                -- Execute /who command directly to show player list
                ChatFrame1EditBox:SetText("/who")
                ChatEdit_SendText(ChatFrame1EditBox)
            end},
            {text = "Guild Finder", icon = "Interface\\Icons\\Achievement_GuildPerk_WorkingAsATeam", func = function() if IsInGuild() then ToggleGuildFrame() else print("Not in a guild") end end},
        }
    },
    {
        text = "Help",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        submenu = {
            {text = "Help Request", icon = "Interface\\Icons\\INV_Letter_18", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Customer Support", icon = "Interface\\Icons\\INV_Misc_Note_01", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Bug Report", icon = "Interface\\Icons\\INV_Misc_Bug_02", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Submit Suggestion", icon = "Interface\\Icons\\INV_Misc_Note_03", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "About WoW95", icon = "Interface\\Icons\\Achievement_General", func = function() StartMenu:ShowAbout() end},
        }
    },
    {type = "separator"},
    {
        text = "Run...",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        func = function() StartMenu:ShowRunDialog() end
    },
    {type = "separator"},
    {
        text = "Log Off " .. (UnitName("player") or ""),
        icon = "Interface\\Icons\\INV_Misc_Head_Human_01",
        func = function() 
            -- Close our start menu immediately
            StartMenu:Hide()
            
            -- Check if we're in combat
            if InCombatLockdown() then
                WoW95:Print("Cannot log off during combat!")
                return
            end
            
            -- Use a timer to ensure clean execution path
            C_Timer.After(0.01, function()
                -- Set flag to allow game menu to show
                StartMenu.allowGameMenu = true
                
                -- Use original ToggleGameMenu to show vanilla menu
                if StartMenu.originalToggleGameMenu then
                    -- Ensure we're not in a tainted context
                    local success, err = pcall(StartMenu.originalToggleGameMenu)
                    if not success then
                        WoW95:Debug("Error opening game menu: " .. tostring(err))
                        -- Fallback: Try to show the game menu frame directly
                        if GameMenuFrame and not GameMenuFrame:IsShown() then
                            GameMenuFrame:Show()
                        end
                    end
                end
                
                -- Reset flag after a delay
                C_Timer.After(1.0, function()
                    StartMenu.allowGameMenu = false
                end)
            end)
        end
    },
    {
        text = "Exit WoW",
        icon = "Interface\\Icons\\INV_Misc_PowerCrystal_01",
        func = function() 
            -- Close our start menu immediately
            StartMenu:Hide()
            
            -- Check if we're in combat
            if InCombatLockdown() then
                WoW95:Print("Cannot exit game during combat!")
                return
            end
            
            -- Use a timer to ensure clean execution path
            C_Timer.After(0.01, function()
                -- Set flag to allow game menu to show
                StartMenu.allowGameMenu = true
                
                -- Use original ToggleGameMenu to show vanilla menu
                if StartMenu.originalToggleGameMenu then
                    -- Ensure we're not in a tainted context
                    local success, err = pcall(StartMenu.originalToggleGameMenu)
                    if not success then
                        WoW95:Debug("Error opening game menu: " .. tostring(err))
                        -- Fallback: Try to show the game menu frame directly
                        if GameMenuFrame and not GameMenuFrame:IsShown() then
                            GameMenuFrame:Show()
                        end
                    end
                end
                
                -- Reset flag after a delay
                C_Timer.After(1.0, function()
                    StartMenu.allowGameMenu = false
                end)
            end)
        end
    },
}

function StartMenu:Init()
    WoW95:Debug("Initializing Start Menu module...")
    
    -- Hook the escape key to open our start menu instead
    self:HookEscapeKey()
    
    -- Create the start menu frame (hidden initially)
    self:CreateStartMenu()
    
    WoW95:Debug("Start Menu initialized successfully!")
end

function StartMenu:CreateStartMenu()
    -- Main start menu frame
    self.frame = CreateFrame("Frame", "WoW95StartMenu", UIParent, "BackdropTemplate")
    self.frame:SetSize(MENU_WIDTH, 400) -- Will be resized based on content
    self.frame:SetFrameStrata("TOOLTIP")
    self.frame:SetFrameLevel(200)
    self.frame:Hide()
    
    -- Menu backdrop (solid gray)
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.frame:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Add Windows 95 style blue vertical bar on the left (like reference image)
    local blueBar = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    blueBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
    blueBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 2, 2)
    blueBar:SetWidth(22)
    blueBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8
    })
    blueBar:SetBackdropColor(unpack(WoW95.colors.titleBar)) -- Use consistent WoW95 blue
    
    -- Add small gray gradient strip next to blue bar (like reference)
    local grayStrip = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    grayStrip:SetPoint("TOPLEFT", blueBar, "TOPRIGHT", 0, 0)
    grayStrip:SetPoint("BOTTOMLEFT", blueBar, "BOTTOMRIGHT", 0, 0)
    grayStrip:SetWidth(4)
    grayStrip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8
    })
    grayStrip:SetBackdropColor(0.6, 0.6, 0.6, 1) -- Darker gray for gradient effect
    
    -- Add "WOW95" text rotated correctly (reading from bottom to top like Windows reference)
    local logoText = blueBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    logoText:SetPoint("CENTER", blueBar, "BOTTOM", -3, 35) -- Move left in code (away from right side visually)
    logoText:SetText("WOW95")
    logoText:SetTextColor(unpack(WoW95.colors.titleBarText)) -- Use consistent title bar text color
    logoText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- Slightly smaller text to fit in 22px width
    logoText:SetRotation(math.rad(90)) -- Rotate 90 degrees clockwise (text reads bottom to top)
    
    -- Store reference for potential future use
    self.frame.blueBar = blueBar
    self.frame.logoText = logoText
    
    -- Close menu when clicking outside
    self.frame:SetScript("OnShow", function()
        self:RegisterClickOutside()
    end)
    self.frame:SetScript("OnHide", function()
        self:UnregisterClickOutside()
        self:CloseSubmenu()
    end)
    
    -- Create menu items
    self:CreateMenuItems()
end

function StartMenu:CreateMenuItems()
    local yOffset = -4
    
    for i, item in ipairs(self.menuItems) do
        if item.type == "separator" then
            -- Create separator (account for blue bar + gray strip)
            local separator = self.frame:CreateTexture(nil, "ARTWORK")
            separator:SetHeight(SEPARATOR_HEIGHT)
            separator:SetPoint("LEFT", self.frame, "LEFT", 30, yOffset - 2) -- Start after blue bar + gray strip
            separator:SetPoint("RIGHT", self.frame, "RIGHT", -8, yOffset - 2)
            separator:SetColorTexture(0.5, 0.5, 0.5, 1)
            
            yOffset = yOffset - SEPARATOR_HEIGHT
        else
            -- Create menu item button (account for blue bar + gray strip)
            local button = CreateFrame("Button", "WoW95StartMenuItem" .. i, self.frame, "BackdropTemplate")
            button:SetSize(MENU_WIDTH - 30, MENU_ITEM_HEIGHT) -- Reduce width for blue bar + gray strip  
            button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 28, yOffset) -- Start after blue bar + gray strip
            
            -- Button backdrop for hover effect
            button:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                tile = true,
                tileSize = 8,
            })
            button:SetBackdropColor(0, 0, 0, 0) -- Transparent by default
            
            -- Icon
            if item.icon then
                local icon = button:CreateTexture(nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", button, "LEFT", 8, 0)
                icon:SetTexture(item.icon)
            end
            
            -- Text
            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", button, "LEFT", item.icon and 30 or 8, 0)
            text:SetText(item.text)
            text:SetTextColor(0, 0, 0, 1)
        text:SetShadowOffset(0, 0)
            text:SetShadowOffset(0, 0)
            text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            
            -- Submenu arrow
            if item.submenu then
                local arrow = button:CreateTexture(nil, "OVERLAY")
                arrow:SetSize(8, 8)
                arrow:SetPoint("RIGHT", button, "RIGHT", -8, 0)
                arrow:SetTexture(WoW95.textures.arrow)
                arrow:SetVertexColor(0, 0, 0, 1) -- Black arrow
            end
            
            -- Button functionality
            button:SetScript("OnClick", function()
                if item.submenu then
                    self:ShowSubmenu(item.submenu, button)
                elseif item.func then
                    -- Ensure clean execution by breaking out of the click handler
                    C_Timer.After(0, function()
                        item.func()
                    end)
                    self:Hide()
                end
            end)
            
            -- Hover effects
            button:SetScript("OnEnter", function()
                button:SetBackdropColor(unpack(WoW95.colors.selection))
                text:SetTextColor(unpack(WoW95.colors.selectedText))
                if item.submenu then
                    self:ShowSubmenu(item.submenu, button)
                else
                    self:CloseSubmenu()
                end
            end)
            button:SetScript("OnLeave", function()
                button:SetBackdropColor(0, 0, 0, 0)
                text:SetTextColor(0, 0, 0, 1)
                text:SetShadowOffset(0, 0)
        text:SetShadowOffset(0, 0)
            text:SetShadowOffset(0, 0)
            end)
            
            yOffset = yOffset - MENU_ITEM_HEIGHT
        end
    end
    
    -- Resize frame to fit content
    self.frame:SetHeight(math.abs(yOffset) + 8)
end

function StartMenu:ShowSubmenu(submenuItems, parentButton)
    self:CloseSubmenu()
    
    -- Create submenu frame
    self.currentSubmenu = CreateFrame("Frame", "WoW95StartSubmenu", UIParent, "BackdropTemplate")
    self.currentSubmenu:SetSize(SUBMENU_WIDTH, #submenuItems * MENU_ITEM_HEIGHT + 8)
    self.currentSubmenu:SetFrameStrata("TOOLTIP")
    self.currentSubmenu:SetFrameLevel(201)
    
    -- Position submenu to the right of parent button
    self.currentSubmenu:SetPoint("TOPLEFT", parentButton, "TOPRIGHT", 0, 0)
    
    -- Submenu backdrop (solid gray)
    self.currentSubmenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.currentSubmenu:SetBackdropColor(0.75, 0.75, 0.75, 1)
    self.currentSubmenu:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Create submenu items
    for i, subitem in ipairs(submenuItems) do
        local button = CreateFrame("Button", "WoW95StartSubMenuItem" .. i, self.currentSubmenu, "BackdropTemplate")
        button:SetSize(SUBMENU_WIDTH - 8, MENU_ITEM_HEIGHT)
        button:SetPoint("TOP", self.currentSubmenu, "TOP", 0, -(i-1) * MENU_ITEM_HEIGHT - 4)
        
        -- Button backdrop for hover effect
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 8,
        })
        button:SetBackdropColor(0, 0, 0, 0)
        
        -- Text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", button, "LEFT", 8, 0)
        text:SetText(subitem.text)
        text:SetTextColor(0, 0, 0, 1)
        text:SetShadowOffset(0, 0)
        text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        
        -- Button functionality
        button:SetScript("OnClick", function()
            if subitem.func then
                subitem.func()
                self:Hide()
            end
        end)
        
        -- Hover effects
        button:SetScript("OnEnter", function()
            button:SetBackdropColor(unpack(WoW95.colors.selection))
            text:SetTextColor(unpack(WoW95.colors.selectedText))
        end)
        button:SetScript("OnLeave", function()
            button:SetBackdropColor(0, 0, 0, 0)
            text:SetTextColor(0, 0, 0, 1)
        text:SetShadowOffset(0, 0)
            text:SetShadowOffset(0, 0)
        end)
    end
    
    self.currentSubmenu:Show()
end

function StartMenu:CloseSubmenu()
    if self.currentSubmenu then
        self.currentSubmenu:Hide()
        self.currentSubmenu = nil
    end
end

function StartMenu:Show()
    if self.isOpen then
        self:Hide()
        return
    end
    
    -- Position menu above the start button
    local taskbar = WoW95.Taskbar and WoW95.Taskbar.startButton
    if taskbar then
        self.frame:SetPoint("BOTTOMLEFT", taskbar, "TOPLEFT", 0, 2)
    else
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 40)
    end
    
    self.frame:Show()
    self.isOpen = true
end

function StartMenu:Hide()
    self.frame:Hide()
    self:CloseSubmenu()
    self.isOpen = false
end

function StartMenu:Toggle()
    if self.isOpen then
        self:Hide()
    else
        self:Show()
    end
end

function StartMenu:RegisterClickOutside()
    -- Register for clicks outside the menu to close it
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(190)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        self:Hide()
        frame:Hide()
    end)
    
    self.clickFrame = frame
end

function StartMenu:UnregisterClickOutside()
    if self.clickFrame then
        self.clickFrame:Hide()
        self.clickFrame = nil
    end
end

function StartMenu:HookEscapeKey()
    -- Override the escape key functionality
    self.originalToggleGameMenu = ToggleGameMenu
    
    ToggleGameMenu = function()
        -- If any Blizzard menus are open, close them first
        if GameMenuFrame and GameMenuFrame:IsShown() then
            StartMenu.originalToggleGameMenu()
        else
            -- Show our start menu instead
            StartMenu:Toggle()
        end
    end
    
    -- Also hook the Game Menu frame to hide it completely ONLY when opened via escape key
    if GameMenuFrame then
        GameMenuFrame:HookScript("OnShow", function()
            -- Only hide if we're not deliberately trying to show it from logout/exit buttons
            if not StartMenu.allowGameMenu then
                GameMenuFrame:Hide()
                StartMenu:Show()
            end
        end)
    end
end

function StartMenu:ShowRunDialog()
    -- Create a "Run" dialog exactly like Windows 95
    local dialog = CreateFrame("Frame", "WoW95RunDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(350, 150)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("TOOLTIP")
    dialog:SetFrameLevel(300)
    
    -- Dialog backdrop (solid gray)
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
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", dialog, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(18)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8
    })
    titleBar:SetBackdropColor(unpack(WoW95.colors.titleBar))
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    titleText:SetText("Run")
    titleText:SetTextColor(unpack(WoW95.colors.titleBarText))
    
    -- Run icon (folder icon)
    local runIcon = dialog:CreateTexture(nil, "ARTWORK")
    runIcon:SetSize(32, 32)
    runIcon:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -35)
    runIcon:SetTexture("Interface\\Icons\\INV_Misc_Folder_01")
    
    -- Instructions
    local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", runIcon, "TOPRIGHT", 8, -5)
    instructions:SetText("Type a slash command and WoW95 will execute it for you.\\nExamples: reload, macro, who, guild, calendar")
    instructions:SetTextColor(0, 0, 0, 1)
    instructions:SetShadowOffset(0, 0)
    instructions:SetJustifyH("LEFT")
    instructions:SetWidth(250)
    
    -- Open label
    local openLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    openLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -85)
    openLabel:SetText("Open:")
    openLabel:SetTextColor(0, 0, 0, 1)
    openLabel:SetShadowOffset(0, 0)
    
    -- Input box
    local inputBox = CreateFrame("EditBox", "WoW95RunInput", dialog, "InputBoxTemplate")
    inputBox:SetSize(250, 20)
    inputBox:SetPoint("LEFT", openLabel, "RIGHT", 8, 0)
    inputBox:SetAutoFocus(true)
    
    -- Buttons
    local okButton = WoW95:CreateButton("WoW95RunOK", dialog, 60, 24, "OK")
    okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
    okButton:SetScript("OnClick", function()
        local command = inputBox:GetText()
        if command and command ~= "" then
            -- Add slash if not present
            if not command:match("^/") then
                command = "/" .. command
            end
            -- Execute the slash command
            ChatFrame1EditBox:SetText(command)
            ChatEdit_SendText(ChatFrame1EditBox)
        end
        dialog:Hide()
    end)
    
    local cancelButton = WoW95:CreateButton("WoW95RunCancel", dialog, 60, 24, "Cancel")
    cancelButton:SetPoint("RIGHT", okButton, "LEFT", -8, 0)
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    
    -- Enter key functionality
    inputBox:SetScript("OnEnterPressed", function()
        okButton:Click()
    end)
    
    dialog:Show()
    self:Hide()
end

function StartMenu:ShowAbout()
    -- Show about dialog for WoW95
    local aboutWindow = WoW95:CreateWindow("WoW95AboutWindow", UIParent, 400, 300, "About WoW95")
    aboutWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    local aboutText = aboutWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aboutText:SetPoint("CENTER", aboutWindow, "CENTER", 0, 0)
    aboutText:SetText("WoW95 - Windows 95 UI for World of Warcraft\n\nVersion: " .. WoW95.version .. "\n\nBringing back the nostalgia of 1995!")
    aboutText:SetTextColor(0, 0, 0, 1)
    aboutText:SetShadowOffset(0, 0)
    aboutText:SetJustifyH("CENTER")
    
    aboutWindow:Show()
    self:Hide()
end

function StartMenu:ShowWoW95Options()
    -- Show WoW95 settings window
    if WoW95.Settings then
        WoW95.Settings:CreateSettingsWindow()
        self:Hide()
    else
        WoW95:Print("Settings module not loaded!")
    end
end

function StartMenu:OpenAddOnList()
    -- Try multiple methods to open the addon list
    
    -- Method 1: Try the modern addon interface
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_AddonList")
        if AddonList_Show then
            AddonList_Show()
            self:Hide()
            return
        end
    end
    
    -- Method 2: Try legacy LoadAddOn function
    if LoadAddOn then
        LoadAddOn("Blizzard_AddonList")
        if AddonList_Show then
            AddonList_Show()
            self:Hide()
            return
        end
    end
    
    -- Method 3: Try opening the game menu and finding addons
    if GameMenuFrame then
        ToggleGameMenu()
        if GameMenuButtonAddons then
            GameMenuButtonAddons:Click()
            self:Hide()
            return
        end
    end
    
    -- Method 4: Try direct addon list access
    if AddonList_Show then
        AddonList_Show()
        self:Hide()
        return
    end
    
    -- Method 5: Use the escape menu as fallback
    ToggleGameMenu()
    self:Hide()
end

-- Register the module
WoW95:RegisterModule("StartMenu", StartMenu)