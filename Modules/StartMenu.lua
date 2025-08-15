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
            {text = "Character Info", func = function() ToggleCharacter("PaperDollFrame") end},
            {text = "Spellbook & Abilities", func = function() ToggleSpellBook(BOOKTYPE_SPELL) end},
            {text = "Talents", func = function() if not PlayerTalentFrame then TalentFrame_LoadUI() end ToggleTalentFrame() end},
            {text = "Adventure Guide", func = function() ToggleEncounterJournal() end},
            {text = "Collections", func = function() ToggleCollectionsJournal() end},
            {text = "Group Finder", func = function() PVEFrame_ToggleFrame() end},
            {text = "Guild & Communities", func = function() ToggleGuildFrame() end},
            {text = "Friends & Who", func = function() ToggleFriendsFrame() end},
        }
    },
    {
        text = "Documents",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        submenu = {
            {text = "Quest Log", func = function() ToggleQuestLog() end},
            {text = "Achievement", func = function() ToggleAchievementFrame() end},
            {text = "Calendar", func = function() 
                if not CalendarFrame then 
                    if C_AddOns and C_AddOns.LoadAddOn then
                        C_AddOns.LoadAddOn("Blizzard_Calendar")
                    elseif LoadAddOn then
                        LoadAddOn("Blizzard_Calendar")
                    end
                end
                if Calendar_Toggle then Calendar_Toggle() end
            end},
            {text = "Dungeon Journal", func = function() ToggleEncounterJournal() end},
        }
    },
    {
        text = "Games",
        icon = "Interface\\Icons\\INV_Misc_Toy_10",
        submenu = {
            {text = "Minesweeper", func = function() 
                if WoW95.Games and WoW95.Games.OpenMinesweeper then
                    WoW95.Games:OpenMinesweeper()
                else
                    WoW95:Print("Games module not loaded!")
                end
            end},
            {text = "Solitaire", func = function() 
                WoW95:Print("Solitaire - Coming Soon!")
            end},
        }
    },
    {
        text = "Settings",
        icon = "Interface\\Icons\\INV_Gizmo_02",
        submenu = {
            {text = "Game Menu", func = function() ToggleGameMenu() end},
            {text = "Interface Options", func = function() Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID) end},
            {text = "Key Bindings", func = function() Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID) end},
            {text = "Macros", func = function() 
                if C_AddOns and C_AddOns.LoadAddOn then
                    C_AddOns.LoadAddOn("Blizzard_MacroUI")
                elseif LoadAddOn then
                    LoadAddOn("Blizzard_MacroUI")
                end
                if MacroFrame then ToggleMacroFrame() end 
            end},
            {text = "Add-Ons", func = function() StartMenu:OpenAddOnList() end},
            {text = "WoW95 Options", func = function() StartMenu:ShowWoW95Options() end},
        }
    },
    {type = "separator"},
    {
        text = "Find",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_02",
        submenu = {
            {text = "Find Group", func = function() if PVEFrame then PVEFrame_ToggleFrame("GroupFinderFrame") else LFGParentFrame_Toggle() end end},
            {text = "Who List", func = function() if FriendsFrame then ToggleFriendsFrame(4) else print("/who for who list") end end},
            {text = "Guild Finder", func = function() if IsInGuild() then ToggleGuildFrame() else print("Not in a guild") end end},
        }
    },
    {
        text = "Help",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        submenu = {
            {text = "Help Request", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Customer Support", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Bug Report", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "Submit Suggestion", func = function() if HelpFrame then ToggleHelpFrame() else print("Help system not available") end end},
            {text = "About WoW95", func = function() StartMenu:ShowAbout() end},
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
        func = function() Logout() end
    },
    {
        text = "Exit WoW",
        icon = "Interface\\Icons\\INV_Misc_PowerCrystal_01",
        func = function() Quit() end
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
            -- Create separator
            local separator = self.frame:CreateTexture(nil, "ARTWORK")
            separator:SetHeight(SEPARATOR_HEIGHT)
            separator:SetPoint("LEFT", self.frame, "LEFT", 8, yOffset - 2)
            separator:SetPoint("RIGHT", self.frame, "RIGHT", -8, yOffset - 2)
            separator:SetColorTexture(0.5, 0.5, 0.5, 1)
            
            yOffset = yOffset - SEPARATOR_HEIGHT
        else
            -- Create menu item button
            local button = CreateFrame("Button", "WoW95StartMenuItem" .. i, self.frame, "BackdropTemplate")
            button:SetSize(MENU_WIDTH - 8, MENU_ITEM_HEIGHT)
            button:SetPoint("TOP", self.frame, "TOP", 0, yOffset)
            
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
                local arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                arrow:SetPoint("RIGHT", button, "RIGHT", -8, 0)
                arrow:SetText("►")
                arrow:SetTextColor(0, 0, 0, 1)
                arrow:SetShadowOffset(0, 0)
                arrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            end
            
            -- Button functionality
            button:SetScript("OnClick", function()
                if item.submenu then
                    self:ShowSubmenu(item.submenu, button)
                elseif item.func then
                    item.func()
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
    local originalToggleGameMenu = ToggleGameMenu
    
    ToggleGameMenu = function()
        -- If any Blizzard menus are open, close them first
        if GameMenuFrame and GameMenuFrame:IsShown() then
            originalToggleGameMenu()
        else
            -- Show our start menu instead
            self:Toggle()
        end
    end
    
    -- Also hook the Game Menu frame to hide it completely
    if GameMenuFrame then
        GameMenuFrame:HookScript("OnShow", function()
            GameMenuFrame:Hide()
            self:Show()
        end)
    end
end

function StartMenu:ShowRunDialog()
    -- Create a "Run" dialog similar to Windows 95
    local dialog = CreateFrame("Frame", "WoW95RunDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(300, 120)
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
    
    -- Instructions
    local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", dialog, "TOP", 0, -20)
    instructions:SetText("Type the name of a program, folder, or command:")
    instructions:SetTextColor(0, 0, 0, 1)
    instructions:SetShadowOffset(0, 0)
    
    -- Input box
    local inputBox = CreateFrame("EditBox", "WoW95RunInput", dialog, "InputBoxTemplate")
    inputBox:SetSize(260, 20)
    inputBox:SetPoint("TOP", instructions, "BOTTOM", 0, -10)
    inputBox:SetAutoFocus(true)
    
    -- Buttons
    local okButton = WoW95:CreateButton("WoW95RunOK", dialog, 80, 24, "OK")
    okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 10)
    okButton:SetScript("OnClick", function()
        local command = inputBox:GetText()
        if command and command ~= "" then
            -- Try to execute as a slash command
            ChatFrame1EditBox:SetText("/" .. command)
            ChatEdit_SendText(ChatFrame1EditBox)
        end
        dialog:Hide()
    end)
    
    local cancelButton = WoW95:CreateButton("WoW95RunCancel", dialog, 80, 24, "Cancel")
    cancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 10)
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
    WoW95:Print("WoW95 Options - Coming soon!")
    self:Hide()
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