-- WoW95 Windows Core Module
-- Shared utilities and base functionality for all Windows modules

local addonName, WoW95 = ...

local WindowsCore = {}
WoW95.WindowsCore = WindowsCore

-- Core windows state
WindowsCore.programWindows = {}
WindowsCore.isInitialized = false

-- Program definitions for Blizzard UI windows
WindowsCore.PROGRAMS = {
    -- Character & Equipment
    ["CharacterFrame"] = {
        name = "Character Sheet", 
        icon = {1, 1, 0, 1}, 
        tooltip = "Character Information",
        window = {width = 750, height = 500, title = "Character Information - World of Warcraft"}
    },
    
    -- Social & Guild
    ["GuildFrame"] = {
        name = "Guild", 
        icon = {0, 0.5, 1, 1}, 
        tooltip = "Guild Management",
        window = {width = 800, height = 600, title = "Guild - World of Warcraft"}
    },
    ["CommunitiesFrame"] = {
        name = "Guild & Communities", 
        icon = {0, 0.5, 1, 1}, 
        tooltip = "Guild & Communities",
        window = {width = 800, height = 600, title = "Guild & Communities - World of Warcraft"}
    },
    ["FriendsFrame"] = {
        name = "Social", 
        icon = {1, 0.5, 0.8, 1}, 
        tooltip = "Friends & Social",
        window = {width = 450, height = 400, title = "Social - World of Warcraft"}
    },
    
    -- Adventure & Quests
    ["WorldMapFrame"] = {
        name = "World Map", 
        icon = {0.6, 0.3, 0, 1}, 
        tooltip = "World Map",
        window = {width = 700, height = 500, title = "Map - World of Warcraft"}
    },
    ["QuestLogFrame"] = {
        name = "Quest Log", 
        icon = {1, 1, 0.3, 1}, 
        tooltip = "Quest Log",
        window = {width = 700, height = 500, title = "Quest Log - World of Warcraft"}
    },
    ["AchievementFrame"] = {
        name = "Achievements", 
        icon = {1, 0.8, 0, 1}, 
        tooltip = "Achievements",
        window = {width = 600, height = 500, title = "Achievements - World of Warcraft"}
    },
    
    -- Systems & Settings
    ["GameMenuFrame"] = {
        name = "Game Menu", 
        icon = {0.5, 0.5, 0.5, 1}, 
        tooltip = "Game Menu",
        window = {width = 300, height = 400, title = "Game Menu - World of Warcraft"}
    },
}

function WindowsCore:Init()
    print("[WoW95] WindowsCore:Init() called!")
    WoW95:Debug("Initializing Windows Core module...")
    
    -- Make program definitions available globally
    WoW95.PROGRAMS = self.PROGRAMS
    
    -- Set up frame hooks with delay for proper loading
    C_Timer.After(0.1, function()
        WoW95:Print("WoW95 Windows: Setting up frame hooks...")
        WindowsCore:SetupFrameHooks()
    end)
    
    self.isInitialized = true
    print("[WoW95] WindowsCore initialization complete - isInitialized: " .. tostring(self.isInitialized))
    WoW95:Debug("Windows Core module initialized successfully!")
end

function WindowsCore:SetupFrameHooks()
    WoW95:Debug("Starting WindowsCore frame hooks...")
    
    -- Hook into Blizzard UI window show/hide events
    local function HookFrame(frameName, windowModule)
        if not windowModule then
            WoW95:Debug("WARNING: windowModule is nil for " .. frameName)
            return
        end
        
        local frame = _G[frameName]
        if frame then
            WoW95:Debug("SUCCESS: Hooking frame: " .. frameName)
            
            -- Hook show - ONLY if not already hooked
            if not frame.WoW95ShowHooked then
                frame:HookScript("OnShow", function()
                    local program = self.PROGRAMS[frameName]
                    WoW95:Debug("=== FRAME SHOW HOOK TRIGGERED ===")
                    WoW95:Debug("Frame: " .. frameName)
                    WoW95:Debug("Program exists: " .. tostring(program ~= nil))
                    WoW95:Debug("WindowModule exists: " .. tostring(windowModule ~= nil))
                    WoW95:Debug("CreateWindow exists: " .. tostring(windowModule and windowModule.CreateWindow ~= nil))
                    
                    if program and windowModule and windowModule.CreateWindow then
                        -- Check if our custom window already exists
                        local existingWindow = WindowsCore:GetProgramWindow(frameName)
                        if existingWindow and existingWindow:IsShown() then
                            WoW95:Debug("Custom window already open, hiding it (toggle behavior)")
                            existingWindow:Hide()
                            
                            -- Mark that we're deliberately hiding this frame to prevent OnHide cleanup
                            frame.WoW95DeliberateHide = true
                            frame:Hide()
                            return
                        end
                        
                        WoW95:Debug("Creating custom window to replace Blizzard frame: " .. frameName)
                        
                        -- Mark that we're deliberately hiding this frame to prevent OnHide cleanup
                        frame.WoW95DeliberateHide = true
                        
                        -- Completely hide and disable the original frame
                        frame:Hide()
                        frame:SetAlpha(0)
                        frame:EnableMouse(false)
                        frame:SetFrameLevel(0)
                        
                        -- Create our custom window
                        windowModule:CreateWindow(frameName, program)
                    else
                        WoW95:Debug("Missing requirements for custom window - showing original frame")
                    end
                end)
                frame.WoW95ShowHooked = true
                WoW95:Debug("Successfully hooked OnShow for: " .. frameName)
            end
            
            -- Hook hide - ONLY if not already hooked
            if not frame.WoW95HideHooked then
                frame:HookScript("OnHide", function()
                    -- Check if this is a deliberate hide by our OnShow hook
                    if frame.WoW95DeliberateHide then
                        WoW95:Debug("Blizzard frame hidden deliberately by WoW95 - skipping cleanup")
                        frame.WoW95DeliberateHide = false -- Reset the flag
                        return
                    end
                    
                    WoW95:Debug("Blizzard frame hidden: " .. frameName .. ", removing program window")
                    
                    -- Restore original frame
                    frame:SetAlpha(1)
                    frame:EnableMouse(true)
                    
                    -- Special cleanup for WorldMapFrame reskin
                    if frameName == "WorldMapFrame" and WoW95.MapWindow then
                        WoW95.MapWindow:CleanupWorldMapReskin(frameName)
                    else
                        -- Remove our custom window
                        WindowsCore:RemoveProgramWindow(frameName)
                    end
                end)
                frame.WoW95HideHooked = true
                WoW95:Debug("Successfully hooked OnHide for: " .. frameName)
            end
        else
            WoW95:Debug("FRAME NOT FOUND: " .. frameName)
        end
    end
    
    -- Hook character frame (handled by CharacterWindow module)
    HookFrame("CharacterFrame", WoW95.CharacterWindow)
    
    -- Hook map frame (handled by MapWindow module)
    HookFrame("WorldMapFrame", WoW95.MapWindow)
    
    -- Hook quest frame (handled by QuestWindow module)
    HookFrame("QuestLogFrame", WoW95.QuestWindow)
    
    -- Note: AchievementFrame will be hooked when Blizzard_AchievementUI loads
    
    -- Hook social frames (handled by SocialWindows module)
    HookFrame("GuildFrame", WoW95.SocialWindows)
    HookFrame("CommunitiesFrame", WoW95.SocialWindows)
    HookFrame("FriendsFrame", WoW95.SocialWindows)
    HookFrame("LFGParentFrame", WoW95.SocialWindows)
    HookFrame("PVPUIFrame", WoW95.SocialWindows)
    
    -- Hook system frames (handled by SystemWindows module)
    HookFrame("GameMenuFrame", WoW95.SystemWindows)
    HookFrame("InterfaceOptionsFrame", WoW95.SystemWindows)
    HookFrame("EncounterJournal", WoW95.SystemWindows)
    
    WoW95:Debug("WindowsCore frame hooks completed")
    
    -- Hook frames that load later with on-demand addons
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("ADDON_LOADED")
    hookFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_AchievementUI" then
            WoW95:Debug("Blizzard_AchievementUI loaded, hooking AchievementFrame")
            HookFrame("AchievementFrame", WoW95.AchievementsWindow)
        elseif addonName == "Blizzard_EncounterJournal" then
            WoW95:Debug("Blizzard_EncounterJournal loaded, hooking EncounterJournal")
            HookFrame("EncounterJournal", WoW95.SystemWindows)
        elseif addonName == "Blizzard_GuildUI" then
            WoW95:Debug("Blizzard_GuildUI loaded, hooking GuildFrame")
            HookFrame("GuildFrame", WoW95.SocialWindows)
        end
    end)
end

-- Store a program window reference
function WindowsCore:StoreProgramWindow(frameName, window)
    self.programWindows[frameName] = window
    WoW95:Debug("Stored program window: " .. frameName)
end

-- Remove a program window reference
function WindowsCore:RemoveProgramWindow(frameName)
    local programWindow = self.programWindows[frameName]
    if programWindow then
        WoW95:Debug("Removing program window for: " .. frameName)
        
        -- Hide and cleanup the window
        programWindow:Hide()
        self.programWindows[frameName] = nil
        
        WoW95:Debug("Program window removed: " .. frameName)
    end
end

-- Get a program window reference
function WindowsCore:GetProgramWindow(frameName)
    return self.programWindows[frameName]
end

-- Check if a program window is open
function WindowsCore:IsProgramWindowOpen(frameName)
    return self.programWindows[frameName] ~= nil
end

-- Debug command to check current state
SLASH_WOW95WINDEBUG1 = "/wow95windebug"
SlashCmdList["WOW95WINDEBUG"] = function(msg)
    WoW95:Print("=== WoW95 Windows Debug Info ===")
    WoW95:Print("WindowsCore initialized: " .. tostring(WindowsCore.isInitialized))
    
    local windowCount = 0
    for frameName, window in pairs(WindowsCore.programWindows) do
        windowCount = windowCount + 1
        local isShown = window:IsShown() and "YES" or "NO"
        WoW95:Print("Window " .. frameName .. ": " .. isShown)
    end
    WoW95:Print("Total open windows: " .. windowCount)
    
    WoW95:Print("Available programs:")
    for frameName, program in pairs(WindowsCore.PROGRAMS) do
        local blizzFrame = _G[frameName]
        local exists = blizzFrame and "EXISTS" or "MISSING"
        local hooked = (blizzFrame and blizzFrame.WoW95ShowHooked) and "HOOKED" or "NOT HOOKED"
        local shown = (blizzFrame and blizzFrame:IsShown()) and "SHOWN" or "HIDDEN"
        WoW95:Print("  " .. frameName .. " (" .. program.name .. "): " .. exists .. ", " .. hooked .. ", " .. shown)
    end
end

-- Register the core module
WoW95:RegisterModule("WindowsCore", WindowsCore)