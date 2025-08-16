-- PartyRaid.lua - Windows 95 styled party and raid frames
-- Implements authentic retro UI for group management

local addonName, WoW95 = ...

print("WoW95: Starting PartyRaid.lua load...")

local PartyRaid = {}

print("WoW95: PartyRaid table created, setting up constants...")

-- Configuration constants
local PARTY_FRAME_WIDTH = 150
local PARTY_FRAME_HEIGHT = 40
local PARTY_FRAME_SPACING = 2

local RAID_FRAME_WIDTH = 80
local RAID_FRAME_HEIGHT = 30
local RAID_FRAME_SPACING = 1

-- Module state
PartyRaid.frames = {}
PartyRaid.partyFrames = {}
PartyRaid.raidFrames = {}
PartyRaid.currentGroupType = "solo"
PartyRaid.isEnabled = true

-- Initialize the module
function PartyRaid:Initialize()
    WoW95:Debug("Initializing Windows 95 Party/Raid frames...")
    
    -- Hide Blizzard party frames
    self:HideBlizzardPartyFrames()
    
    -- Create container frames
    self:CreatePartyContainer()
    self:CreateRaidContainer()
    
    -- Register events
    self:RegisterEvents()
    
    -- Start periodic range checking
    self:StartRangeUpdates()
    
    -- Initial update
    self:UpdateGroupType()
    
    WoW95:Debug("Party/Raid frames module initialized successfully!")
end

-- Start periodic updates for range checking
function PartyRaid:StartRangeUpdates()
    -- Create a frame to handle periodic updates
    local updateFrame = CreateFrame("Frame")
    self.rangeUpdateFrame = updateFrame
    
    local timeSinceLastUpdate = 0
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        
        -- Update every 0.5 seconds
        if timeSinceLastUpdate >= 0.5 then
            timeSinceLastUpdate = 0
            PartyRaid:UpdateRangeStatus()
        end
    end)
    
    WoW95:Debug("Range update timer started")
end

-- Update range status for all party/raid frames
function PartyRaid:UpdateRangeStatus()
    if self.currentGroupType == "party" and self.partyFrames then
        for i, frame in ipairs(self.partyFrames) do
            if frame:IsShown() and frame.unit then
                self:UpdatePartyMemberFrame(frame, frame.unit)
            end
        end
    elseif self.currentGroupType == "raid" and self.raidFrames then
        for i, frame in ipairs(self.raidFrames) do
            if frame:IsShown() and frame.unit then
                self:UpdateRaidMemberFrame(frame, frame.unit)
            end
        end
    end
end

-- Module initialization function that gets called by WoW95
function PartyRaid:Init()
    self:Initialize()
end

-- Hide Blizzard's default party frames
function PartyRaid:HideBlizzardPartyFrames()
    WoW95:Debug("Hiding Blizzard party frames...")
    
    -- Modern approach for hiding party frames
    local function HidePartyFrames()
        -- Hide the main party frame container
        if PartyFrame then
            PartyFrame:Hide()
            PartyFrame:UnregisterAllEvents()
        end
        
        -- Hide individual party member frames
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame then
                frame:Hide()
                frame:UnregisterAllEvents()
            end
        end
        
        -- Hide the compact party frame (used in modern WoW)
        if CompactPartyFrame then
            CompactPartyFrame:Hide()
            CompactPartyFrame:UnregisterAllEvents()
        end
        
        -- Hide compact raid frames
        if CompactRaidFrameManager then
            CompactRaidFrameManager:Hide()
            CompactRaidFrameManager:UnregisterAllEvents()
        end
        
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:Hide()
            CompactRaidFrameContainer:UnregisterAllEvents()
        end
        
        -- Hide individual raid frames
        for i = 1, 40 do
            local frame = _G["CompactRaidFrame" .. i]
            if frame then
                frame:Hide()
                frame:UnregisterAllEvents()
            end
        end
    end
    
    -- Hide frames immediately
    HidePartyFrames()
    
    -- Hook events to keep them hidden
    local hiddenFrame = CreateFrame("Frame")
    hiddenFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    hiddenFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
    hiddenFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
    hiddenFrame:SetScript("OnEvent", function()
        C_Timer.After(0.1, HidePartyFrames) -- Small delay to ensure they're hidden after Blizzard shows them
    end)
    
    WoW95:Debug("Blizzard party frames hidden with persistent hooks")
end

-- Create party frame container
function PartyRaid:CreatePartyContainer()
    WoW95:Debug("Creating party frame container...")
    
    -- Create a simple draggable container (no window frame for cleaner look)
    local partyContainer = CreateFrame("Frame", "WoW95PartyContainer", UIParent)
    partyContainer:SetSize(PARTY_FRAME_WIDTH + 10, (PARTY_FRAME_HEIGHT + PARTY_FRAME_SPACING) * 5 + 35) -- +35 for drag handle and spacing
    partyContainer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -120)
    partyContainer:Hide() -- Hidden until in party
    
    -- Create a drag handle for moving the party cluster
    local dragHandle = CreateFrame("Frame", "WoW95PartyDragHandle", partyContainer, "BackdropTemplate")
    dragHandle:SetSize(PARTY_FRAME_WIDTH, 20)
    dragHandle:SetPoint("TOPLEFT", partyContainer, "TOPLEFT", 5, 5)
    
    -- Visual drag handle (title bar style)
    dragHandle:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    dragHandle:SetBackdropColor(unpack(WoW95.colors.titleBar))
    
    -- Drag handle title
    local dragText = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dragText:SetPoint("CENTER", dragHandle, "CENTER")
    dragText:SetText("Party")
    dragText:SetTextColor(1, 1, 1, 1)
    dragText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Make the container draggable
    partyContainer:SetMovable(true)
    partyContainer:SetClampedToScreen(true)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function() 
        partyContainer:StartMoving() 
        dragHandle:SetBackdropColor(0.4, 0.4, 0.7, 1) -- Darker blue when dragging
    end)
    dragHandle:SetScript("OnDragStop", function() 
        partyContainer:StopMovingOrSizing() 
        dragHandle:SetBackdropColor(unpack(WoW95.colors.titleBar)) -- Restore original color
    end)
    
    -- Hover effects for drag handle
    dragHandle:SetScript("OnEnter", function() 
        dragHandle:SetBackdropColor(0.2, 0.2, 0.7, 1) -- Lighter blue on hover
    end)
    dragHandle:SetScript("OnLeave", function() 
        dragHandle:SetBackdropColor(unpack(WoW95.colors.titleBar)) -- Restore original
    end)
    
    -- Store reference
    partyContainer.dragHandle = dragHandle
    
    self.partyContainer = partyContainer
    
    WoW95:Debug("Party container created successfully")
end

-- Create raid frame container
function PartyRaid:CreateRaidContainer()
    WoW95:Debug("Creating raid frame container...")
    
    -- Main raid window - larger for grid layout
    local raidWindow = WoW95:CreateWindow("WoW95RaidFrame", UIParent, 400, 300, "Raid")
    raidWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -120)
    raidWindow:Hide() -- Hidden until in raid
    
    self.raidWindow = raidWindow
    self.raidContainer = raidWindow
    
    WoW95:Debug("Raid container created successfully")
end

-- Get current group type
function PartyRaid:GetGroupType()
    if IsInRaid() then
        return "raid"
    elseif IsInGroup() then
        return "party"
    else
        return "solo"
    end
end

-- Update group type and show/hide appropriate frames
function PartyRaid:UpdateGroupType()
    local newGroupType = self:GetGroupType()
    
    if newGroupType ~= self.currentGroupType then
        WoW95:Debug("Group type changed from " .. self.currentGroupType .. " to " .. newGroupType)
        self.currentGroupType = newGroupType
        
        -- Hide all frames first
        if self.partyContainer then
            self.partyContainer:Hide()
        end
        if self.raidWindow then
            self.raidWindow:Hide()
        end
        
        -- Show appropriate frame based on group type
        if newGroupType == "party" then
            self:UpdatePartyFrames()
        elseif newGroupType == "raid" then
            self:UpdateRaidFrames()
        end
        -- Solo = both hidden
    end
end

-- Create individual party member frame
function PartyRaid:CreatePartyMemberFrame(unit, index)
    local frameName = "WoW95PartyMember" .. index
    -- Create main frame as regular frame (not secure button)
    local frame = CreateFrame("Frame", frameName, self.partyContainer)
    
    -- Frame setup with backdrop for class coloring
    frame:SetSize(PARTY_FRAME_WIDTH, PARTY_FRAME_HEIGHT)
    -- Position below the drag handle (20px + 5px spacing = 25px offset)
    frame:SetPoint("TOPLEFT", self.partyContainer, "TOPLEFT", 5, -25 - ((index-1) * (PARTY_FRAME_HEIGHT + PARTY_FRAME_SPACING)))
    
    -- Add backdrop template for class coloring
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame:SetBackdropColor(0.2, 0.2, 0.2, 0.3) -- Default background
    
    -- Create invisible secure button for mouseover/clicking
    local secureButton = CreateFrame("Button", frameName .. "SecureButton", frame, "SecureUnitButtonTemplate")
    secureButton:SetAllPoints(frame)
    secureButton:SetFrameLevel(frame:GetFrameLevel() + 1) -- Just above main frame
    
    -- Setup for direct spell casting (not just targeting)
    secureButton:SetAttribute("unit", unit)
    secureButton:SetAttribute("type1", "target") -- Left click to target
    secureButton:SetAttribute("type2", "togglemenu") -- Right click for menu
    
    -- Key fix: Enable spell casting directly on the frame
    secureButton:SetAttribute("*type*", "target")
    secureButton:SetAttribute("*unit*", unit)
    
    -- Enable mouse for all interactions
    secureButton:EnableMouse(true)
    secureButton:RegisterForClicks("AnyUp")
    
    -- Register with unit watching system (this is critical)
    RegisterUnitWatch(secureButton)
    
    -- Clean secure template - no extra attributes that might interfere
    
    -- Debug mouseover on the secure button
    secureButton:SetScript("OnEnter", function(self)
        local unitAttr = self:GetAttribute("unit")
        WoW95:Debug("Mouseover unit: " .. tostring(unitAttr))
        if unitAttr and UnitExists(unitAttr) then
            WoW95:Debug("Unit name: " .. UnitName(unitAttr))
        end
    end)
    
    -- Store references
    frame.secureButton = secureButton
    frame.unit = unit
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText = nameText
    
    -- Health bar
    local healthBar = CreateFrame("StatusBar", frameName .. "HealthBar", frame)
    healthBar:SetSize(PARTY_FRAME_WIDTH - 8, 12)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -14)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green health
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    
    -- Health bar background
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(healthBar)
    healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    healthBg:SetVertexColor(0.2, 0.2, 0.2, 1)
    
    -- Health text overlay
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER")
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    healthText:SetTextColor(1, 1, 1, 1)
    frame.healthText = healthText
    frame.healthBar = healthBar
    
    -- Power bar (smaller)
    local powerBar = CreateFrame("StatusBar", frameName .. "PowerBar", frame)
    powerBar:SetSize(PARTY_FRAME_WIDTH - 8, 8)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
    powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    powerBar:SetStatusBarColor(0, 0, 1, 1) -- Blue mana
    powerBar:SetMinMaxValues(0, 100)
    powerBar:SetValue(100)
    
    -- Power bar background
    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(powerBar)
    powerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    powerBg:SetVertexColor(0.1, 0.1, 0.2, 1)
    frame.powerBar = powerBar
    
    -- Role icon (small)
    local roleIcon = frame:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(12, 12)
    roleIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    roleIcon:Hide() -- Show only when role assigned
    frame.roleIcon = roleIcon
    
    -- Status indicators
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -2)
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    statusText:SetTextColor(1, 0, 0, 1) -- Red for status
    statusText:SetText("")
    frame.statusText = statusText
    
    return frame
end

-- Update party frames
function PartyRaid:UpdatePartyFrames()
    WoW95:Debug("Updating party frames...")
    WoW95:Debug("Group members: " .. GetNumGroupMembers())
    WoW95:Debug("Party container exists: " .. tostring(self.partyContainer ~= nil))
    
    -- Clear existing frames and unregister unit watches
    for i, frame in ipairs(self.partyFrames) do
        if frame.secureButton then
            UnregisterUnitWatch(frame.secureButton)
        end
        frame:Hide()
    end
    
    -- Get group members
    local numMembers = GetNumGroupMembers()
    if numMembers <= 1 then
        WoW95:Debug("Not enough members for party frames, hiding container")
        if self.partyContainer then
            self.partyContainer:Hide()
        end
        return
    end
    
    WoW95:Debug("Creating party frames for " .. numMembers .. " members")
    
    local frameIndex = 1
    
    -- Add player frame first (party frames don't include player by default)
    local playerFrame = self.partyFrames[frameIndex] or self:CreatePartyMemberFrame("player", frameIndex)
    self.partyFrames[frameIndex] = playerFrame
    self:UpdatePartyMemberFrame(playerFrame, "player")
    playerFrame:Show()
    frameIndex = frameIndex + 1
    
    -- Add party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local memberFrame = self.partyFrames[frameIndex] or self:CreatePartyMemberFrame(unit, frameIndex)
            self.partyFrames[frameIndex] = memberFrame
            memberFrame.unit = unit -- Update unit reference
            
            -- Update unit attribute on the secure button
            if memberFrame.secureButton then
                memberFrame.secureButton:SetAttribute("unit", unit)
                WoW95:Debug("Updated secure button unit to: " .. unit)
            end
            
            self:UpdatePartyMemberFrame(memberFrame, unit)
            memberFrame:Show()
            frameIndex = frameIndex + 1
        end
    end
    
    -- Resize party container based on member count (include drag handle)
    local totalHeight = 35 + (frameIndex - 1) * (PARTY_FRAME_HEIGHT + PARTY_FRAME_SPACING) + 10
    self.partyContainer:SetHeight(totalHeight)
    
    -- Show the container
    self.partyContainer:Show()
    
    WoW95:Debug("Party frames updated - " .. (frameIndex - 1) .. " members")
end

-- Update individual party member frame
function PartyRaid:UpdatePartyMemberFrame(frame, unit)
    if not frame or not UnitExists(unit) then return end
    
    -- Check if unit is out of range or can't be assisted
    local canAssist = UnitCanAssist("player", unit)
    local inRange = UnitInRange(unit)
    local isReachable = canAssist and inRange
    
    -- Debug output for range checking
    if unit == "party1" then -- Only debug the first party member to avoid spam
        WoW95:Debug("Unit: " .. unit .. " | CanAssist: " .. tostring(canAssist) .. " | InRange: " .. tostring(inRange) .. " | Reachable: " .. tostring(isReachable))
    end
    
    -- Update name
    local name = UnitName(unit)
    if name then
        frame.nameText:SetText(name)
        -- Grey out name if unreachable
        if isReachable then
            frame.nameText:SetTextColor(1, 1, 1, 1) -- White
        else
            frame.nameText:SetTextColor(0.5, 0.5, 0.5, 1) -- Grey
        end
    end
    
    -- Update health
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if maxHealth > 0 then
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
        local healthPercent = math.floor((health / maxHealth) * 100)
        frame.healthText:SetText(healthPercent .. "%")
        
        -- Color health bar based on percentage and reachability
        if not isReachable then
            frame.healthBar:SetStatusBarColor(0.3, 0.3, 0.3, 1) -- Grey for unreachable
        elseif healthPercent > 50 then
            frame.healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
        elseif healthPercent > 25 then
            frame.healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
        else
            frame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
        end
    end
    
    -- Update power
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    if maxPower > 0 then
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)
        
        -- Set power color based on type and reachability
        local powerType = UnitPowerType(unit)
        if not isReachable then
            frame.powerBar:SetStatusBarColor(0.3, 0.3, 0.3, 1) -- Grey for unreachable
        elseif powerType == 0 then -- Mana
            frame.powerBar:SetStatusBarColor(0, 0, 1, 1)
        elseif powerType == 1 then -- Rage
            frame.powerBar:SetStatusBarColor(1, 0, 0, 1)
        elseif powerType == 2 then -- Focus
            frame.powerBar:SetStatusBarColor(1, 0.5, 0, 1)
        elseif powerType == 3 then -- Energy
            frame.powerBar:SetStatusBarColor(1, 1, 0, 1)
        else
            frame.powerBar:SetStatusBarColor(0.5, 0.5, 1, 1)
        end
    end
    
    -- Update class color background
    if UnitIsPlayer(unit) then
        local _, classFileName = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[classFileName]
        if classColor then
            if isReachable then
                frame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.3)
            else
                -- Greyed out version of class color
                frame:SetBackdropColor(classColor.r * 0.4, classColor.g * 0.4, classColor.b * 0.4, 0.6)
            end
        end
    end
    
    -- Update role icon
    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" then
        if role == "TANK" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
        elseif role == "HEALER" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        elseif role == "DAMAGER" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
        end
        frame.roleIcon:Show()
    else
        frame.roleIcon:Hide()
    end
    
    -- Update status indicators
    local statusText = ""
    if not UnitIsConnected(unit) then
        statusText = "DC"
        frame.statusText:SetTextColor(0.5, 0.5, 0.5, 1)
    elseif UnitIsDead(unit) then
        statusText = "DEAD"
        frame.statusText:SetTextColor(1, 0, 0, 1)
    elseif UnitIsGhost(unit) then
        statusText = "GHOST"
        frame.statusText:SetTextColor(0.5, 0.5, 1, 1)
    elseif UnitAffectingCombat(unit) then
        statusText = "COMBAT"
        frame.statusText:SetTextColor(1, 1, 0, 1)
    end
    frame.statusText:SetText(statusText)
end

-- Create individual raid member frame (compact rectangle like vanilla)
function PartyRaid:CreateRaidMemberFrame(unit, index)
    local frameName = "WoW95RaidMember" .. index
    -- Create main frame as regular frame (not secure button)
    local frame = CreateFrame("Frame", frameName, self.raidContainer)
    
    -- Compact frame setup - rectangular layout like party frames
    frame:SetSize(RAID_FRAME_WIDTH, RAID_FRAME_HEIGHT)
    
    -- No background - clean look for raid frames
    
    -- Create invisible secure button for mouseover/clicking
    local secureButton = CreateFrame("Button", frameName .. "SecureButton", frame, "SecureUnitButtonTemplate")
    secureButton:SetAllPoints(frame)
    secureButton:SetFrameLevel(frame:GetFrameLevel() + 1) -- Just above main frame
    
    -- Setup for direct spell casting (same as party frames)
    secureButton:SetAttribute("unit", unit)
    secureButton:SetAttribute("type1", "target") -- Left click to target
    secureButton:SetAttribute("type2", "togglemenu") -- Right click for menu
    
    -- Key fix: Enable spell casting directly on the frame
    secureButton:SetAttribute("*type*", "target")
    secureButton:SetAttribute("*unit*", unit)
    
    -- Enable mouse for all interactions
    secureButton:EnableMouse(true)
    secureButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Register with unit watching system (this is critical)
    RegisterUnitWatch(secureButton)
    
    -- Debug mouseover on the secure button
    secureButton:SetScript("OnEnter", function(self)
        local unitAttr = self:GetAttribute("unit")
        WoW95:Debug("Raid mouseover unit: " .. tostring(unitAttr))
        if unitAttr and UnitExists(unitAttr) then
            WoW95:Debug("Raid unit name: " .. UnitName(unitAttr))
        end
    end)
    
    -- Store references
    frame.secureButton = secureButton
    frame.unit = unit
    
    -- Name text (smaller font for compact layout)
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -1)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText = nameText
    
    -- Health bar (most of the frame)
    local healthBar = CreateFrame("StatusBar", frameName .. "HealthBar", frame)
    healthBar:SetSize(RAID_FRAME_WIDTH - 4, RAID_FRAME_HEIGHT - 10)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -8)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green health
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    
    -- Health bar background
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(healthBar)
    healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    healthBg:SetVertexColor(0.2, 0.2, 0.2, 1)
    
    -- Health text overlay (smaller)
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER")
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 7, "")
    healthText:SetTextColor(1, 1, 1, 1)
    frame.healthText = healthText
    frame.healthBar = healthBar
    
    -- Role icon (small, top right)
    local roleIcon = frame:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(8, 8)
    roleIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    roleIcon:Hide() -- Show only when role assigned
    frame.roleIcon = roleIcon
    
    -- Status indicator (small dot in corner)
    local statusIcon = frame:CreateTexture(nil, "OVERLAY")
    statusIcon:SetSize(4, 4)
    statusIcon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    statusIcon:SetTexture("Interface\\Buttons\\WHITE8X8")
    statusIcon:Hide() -- Show only when status present
    frame.statusIcon = statusIcon
    
    return frame
end

-- Update raid frames
function PartyRaid:UpdateRaidFrames()
    WoW95:Debug("Updating raid frames...")
    
    -- Clear existing frames and unregister unit watches
    for i, frame in ipairs(self.raidFrames) do
        if frame.secureButton then
            UnregisterUnitWatch(frame.secureButton)
        end
        frame:Hide()
    end
    
    -- Get raid members
    local numMembers = GetNumGroupMembers()
    if numMembers <= 1 then
        WoW95:Debug("Not enough members for raid frames, hiding container")
        if self.raidContainer then
            self.raidContainer:Hide()
        end
        return
    end
    
    WoW95:Debug("Creating raid frames for " .. numMembers .. " members")
    
    local frameIndex = 1
    
    -- Add all raid members (including player)
    for i = 1, 40 do -- Max raid size
        local unit = "raid" .. i
        if UnitExists(unit) then
            local memberFrame = self.raidFrames[frameIndex] or self:CreateRaidMemberFrame(unit, frameIndex)
            self.raidFrames[frameIndex] = memberFrame
            memberFrame.unit = unit -- Update unit reference
            
            -- Update unit attribute on the secure button
            if memberFrame.secureButton then
                memberFrame.secureButton:SetAttribute("unit", unit)
                WoW95:Debug("Updated raid secure button unit to: " .. unit)
            end
            
            self:UpdateRaidMemberFrame(memberFrame, unit)
            memberFrame:Show()
            frameIndex = frameIndex + 1
        end
    end
    
    -- Arrange raid frames in grid layout
    self:ArrangeRaidFrames(frameIndex - 1)
    
    -- Show the container
    self.raidContainer:Show()
    
    WoW95:Debug("Raid frames updated - " .. (frameIndex - 1) .. " members")
end

-- Update individual raid member frame (same logic as party frames but compact)
function PartyRaid:UpdateRaidMemberFrame(frame, unit)
    if not frame or not UnitExists(unit) then return end
    
    -- Check if unit is out of range or can't be assisted
    local canAssist = UnitCanAssist("player", unit)
    local inRange = UnitInRange(unit)
    local isReachable = canAssist and inRange
    
    -- Update name
    local name = UnitName(unit)
    if name then
        -- Truncate name for compact display
        local displayName = string.len(name) > 8 and string.sub(name, 1, 7) .. "." or name
        frame.nameText:SetText(displayName)
        -- Grey out name if unreachable
        if isReachable then
            frame.nameText:SetTextColor(1, 1, 1, 1) -- White
        else
            frame.nameText:SetTextColor(0.5, 0.5, 0.5, 1) -- Grey
        end
    end
    
    -- Update health
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if maxHealth > 0 then
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)
        local healthPercent = math.floor((health / maxHealth) * 100)
        frame.healthText:SetText(healthPercent .. "%")
        
        -- Color health bar based on percentage and reachability
        if not isReachable then
            frame.healthBar:SetStatusBarColor(0.3, 0.3, 0.3, 1) -- Grey for unreachable
        elseif healthPercent > 50 then
            frame.healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
        elseif healthPercent > 25 then
            frame.healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
        else
            frame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
        end
    end
    
    -- No background coloring - raid frames use health bar color only
    
    -- Update role icon
    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" then
        if role == "TANK" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
        elseif role == "HEALER" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        elseif role == "DAMAGER" then
            frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            frame.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
        end
        frame.roleIcon:Show()
    else
        frame.roleIcon:Hide()
    end
    
    -- Update status indicators
    if not UnitIsConnected(unit) then
        frame.statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grey for disconnected
        frame.statusIcon:Show()
    elseif UnitIsDead(unit) then
        frame.statusIcon:SetVertexColor(1, 0, 0, 1) -- Red for dead
        frame.statusIcon:Show()
    elseif UnitIsGhost(unit) then
        frame.statusIcon:SetVertexColor(0.5, 0.5, 1, 1) -- Blue for ghost
        frame.statusIcon:Show()
    elseif UnitAffectingCombat(unit) then
        frame.statusIcon:SetVertexColor(1, 1, 0, 1) -- Yellow for combat
        frame.statusIcon:Show()
    else
        frame.statusIcon:Hide()
    end
end

-- Arrange raid frames in a grid layout with group organization (like vanilla WoW)
function PartyRaid:ArrangeRaidFrames(memberCount)
    local framesPerGroup = 5 -- Standard raid group size
    local groupsPerColumn = 2 -- Groups per column before starting new column
    local groupSpacing = 10 -- Extra space between groups
    
    -- Clear existing group labels
    if self.groupLabels then
        for _, label in ipairs(self.groupLabels) do
            label:Hide()
        end
    end
    self.groupLabels = {}
    
    local currentColumn = 0
    local currentGroupInColumn = 0
    
    for i = 1, memberCount do
        local frame = self.raidFrames[i]
        if frame then
            local groupNum = math.floor((i - 1) / framesPerGroup) + 1
            local posInGroup = (i - 1) % framesPerGroup
            
            -- Check if we need to start a new column
            if posInGroup == 0 and currentGroupInColumn >= groupsPerColumn then
                currentColumn = currentColumn + 1
                currentGroupInColumn = 0
            end
            
            -- Create group label if this is the first member of a group
            if posInGroup == 0 then
                local groupLabel = self.raidContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                groupLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                groupLabel:SetTextColor(1, 1, 1, 1)
                groupLabel:SetText("Group " .. groupNum)
                
                local labelX = currentColumn * (RAID_FRAME_WIDTH + 40) + 10
                local labelY = -(currentGroupInColumn * (framesPerGroup * RAID_FRAME_HEIGHT + groupSpacing + 15)) - 30
                groupLabel:SetPoint("TOPLEFT", self.raidContainer, "TOPLEFT", labelX, labelY)
                
                table.insert(self.groupLabels, groupLabel)
                currentGroupInColumn = currentGroupInColumn + 1
            end
            
            -- Position the frame
            local x = currentColumn * (RAID_FRAME_WIDTH + 40) + 10
            local y = -((currentGroupInColumn - 1) * (framesPerGroup * RAID_FRAME_HEIGHT + groupSpacing + 15) + 45 + posInGroup * (RAID_FRAME_HEIGHT + RAID_FRAME_SPACING))
            
            frame:SetPoint("TOPLEFT", self.raidContainer, "TOPLEFT", x, y)
        end
    end
    
    -- Calculate window size
    local totalColumns = currentColumn + 1
    local windowWidth = totalColumns * (RAID_FRAME_WIDTH + 40) + 20
    local windowHeight = groupsPerColumn * (framesPerGroup * RAID_FRAME_HEIGHT + groupSpacing + 15) + 60
    self.raidContainer:SetSize(windowWidth, windowHeight)
    
    WoW95:Debug("Arranged " .. memberCount .. " raid frames in " .. math.ceil(memberCount / framesPerGroup) .. " groups across " .. totalColumns .. " columns")
end

-- Register events
function PartyRaid:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    self.eventFrame = eventFrame
    
    -- Group events
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("GROUP_FORMED")
    eventFrame:RegisterEvent("GROUP_LEFT")
    
    -- Unit events
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_CONNECTION")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    
    -- Set event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        PartyRaid:OnEvent(event, ...)
    end)
    
    WoW95:Debug("Party/Raid events registered successfully")
end

-- Event handler
function PartyRaid:OnEvent(event, ...)
    local unit = ...
    
    if event == "GROUP_ROSTER_UPDATE" or event == "GROUP_FORMED" or event == "GROUP_LEFT" then
        self:UpdateGroupType()
        if self.currentGroupType == "party" then
            self:UpdatePartyFrames()
        elseif self.currentGroupType == "raid" then
            self:UpdateRaidFrames()
        end
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or 
           event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or
           event == "UNIT_CONNECTION" or event == "UNIT_AURA" then
        -- Update specific unit frame
        if self.currentGroupType == "party" then
            for _, frame in ipairs(self.partyFrames) do
                if frame.unit == unit and frame:IsShown() then
                    self:UpdatePartyMemberFrame(frame, unit)
                    break
                end
            end
        end
    elseif event == "PLAYER_ROLES_ASSIGNED" then
        -- Update all frames when roles change
        if self.currentGroupType == "party" then
            self:UpdatePartyFrames()
        elseif self.currentGroupType == "raid" then
            self:UpdateRaidFrames()
        end
    end
end

-- Test functionality for development
PartyRaid.testMode = false
PartyRaid.testPartyData = {
    {name = "Testadin", class = "PALADIN", level = 70, health = 85, maxHealth = 100, power = 60, maxPower = 80, role = "TANK"},
    {name = "Testpriest", class = "PRIEST", level = 68, health = 45, maxHealth = 90, power = 70, maxPower = 100, role = "HEALER"},
    {name = "Testmage", class = "MAGE", level = 69, health = 90, maxHealth = 85, power = 30, maxPower = 95, role = "DAMAGER"},
    {name = "Testrogue", class = "ROGUE", level = 70, health = 100, maxHealth = 100, power = 80, maxPower = 100, role = "DAMAGER", status = "COMBAT"}
}

function PartyRaid:EnableTestMode()
    self.testMode = true
    self.currentGroupType = "party"
    self:CreateTestPartyFrames()
    self.partyWindow:Show()
    WoW95:Print("Party frame test mode enabled! Use /wow95partytest off to disable.")
end

function PartyRaid:DisableTestMode()
    self.testMode = false
    self.currentGroupType = "solo"
    self.partyWindow:Hide()
    WoW95:Print("Party frame test mode disabled.")
end

function PartyRaid:CreateTestPartyFrames()
    WoW95:Debug("Creating test party frames...")
    
    -- Clear existing frames
    for i, frame in ipairs(self.partyFrames) do
        frame:Hide()
    end
    
    -- Create player frame first
    local playerFrame = self.partyFrames[1] or self:CreatePartyMemberFrame("player", 1)
    self.partyFrames[1] = playerFrame
    playerFrame:Show()
    
    -- Set test data for player
    playerFrame.nameText:SetText(UnitName("player") or "You")
    playerFrame.healthBar:SetMinMaxValues(0, 100)
    playerFrame.healthBar:SetValue(100)
    playerFrame.healthText:SetText("100%")
    playerFrame.powerBar:SetMinMaxValues(0, 100)
    playerFrame.powerBar:SetValue(100)
    playerFrame.statusText:SetText("")
    
    -- Create test party member frames
    for i, testData in ipairs(self.testPartyData) do
        local frameIndex = i + 1
        local frame = self.partyFrames[frameIndex] or self:CreateTestPartyMemberFrame(frameIndex, testData)
        self.partyFrames[frameIndex] = frame
        self:UpdateTestPartyMemberFrame(frame, testData)
        frame:Show()
    end
    
    -- Resize party window
    local totalFrames = 1 + #self.testPartyData
    local totalHeight = 30 + totalFrames * (PARTY_FRAME_HEIGHT + PARTY_FRAME_SPACING) + 10
    self.partyWindow:SetHeight(totalHeight)
    
    WoW95:Debug("Test party frames created - " .. totalFrames .. " members")
end

function PartyRaid:CreateTestPartyMemberFrame(index, testData)
    local frameName = "WoW95TestPartyMember" .. index
    local frame = CreateFrame("Button", frameName, self.partyContainer)
    
    -- Frame setup (same as regular party frame but without secure attributes)
    frame:SetSize(PARTY_FRAME_WIDTH, PARTY_FRAME_HEIGHT)
    frame:SetPoint("TOPLEFT", self.partyContainer, "TOPLEFT", 10, -30 - (index * (PARTY_FRAME_HEIGHT + PARTY_FRAME_SPACING)))
    
    -- Windows 95 styling
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame:SetBackdropColor(unpack(WoW95.colors.window))
    frame:SetBackdropBorderColor(unpack(WoW95.colors.windowFrame))
    
    -- Test click handler
    frame:EnableMouse(true)
    frame:SetScript("OnClick", function()
        WoW95:Print("Clicked test party member: " .. testData.name)
    end)
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2)
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText = nameText
    
    -- Health bar
    local healthBar = CreateFrame("StatusBar", frameName .. "HealthBar", frame)
    healthBar:SetSize(PARTY_FRAME_WIDTH - 8, 12)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -14)
    healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthBar:SetMinMaxValues(0, 100)
    
    -- Health bar background
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(healthBar)
    healthBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    healthBg:SetVertexColor(0.2, 0.2, 0.2, 1)
    
    -- Health text overlay
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healthText:SetPoint("CENTER", healthBar, "CENTER")
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    healthText:SetTextColor(1, 1, 1, 1)
    frame.healthText = healthText
    frame.healthBar = healthBar
    
    -- Power bar
    local powerBar = CreateFrame("StatusBar", frameName .. "PowerBar", frame)
    powerBar:SetSize(PARTY_FRAME_WIDTH - 8, 8)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1)
    powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    powerBar:SetMinMaxValues(0, 100)
    
    -- Power bar background
    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(powerBar)
    powerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    powerBg:SetVertexColor(0.1, 0.1, 0.2, 1)
    frame.powerBar = powerBar
    
    -- Role icon
    local roleIcon = frame:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(12, 12)
    roleIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.roleIcon = roleIcon
    
    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -2)
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    frame.statusText = statusText
    
    return frame
end

function PartyRaid:UpdateTestPartyMemberFrame(frame, testData)
    -- Set name
    frame.nameText:SetText(testData.name)
    
    -- Set health
    frame.healthBar:SetMinMaxValues(0, testData.maxHealth)
    frame.healthBar:SetValue(testData.health)
    local healthPercent = math.floor((testData.health / testData.maxHealth) * 100)
    frame.healthText:SetText(healthPercent .. "%")
    
    -- Color health bar
    if healthPercent > 50 then
        frame.healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
    elseif healthPercent > 25 then
        frame.healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
    else
        frame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
    end
    
    -- Set power
    frame.powerBar:SetMinMaxValues(0, testData.maxPower)
    frame.powerBar:SetValue(testData.power)
    
    -- Set power color based on class
    if testData.class == "PALADIN" or testData.class == "PRIEST" or testData.class == "MAGE" then
        frame.powerBar:SetStatusBarColor(0, 0, 1, 1) -- Blue mana
    elseif testData.class == "WARRIOR" then
        frame.powerBar:SetStatusBarColor(1, 0, 0, 1) -- Red rage
    elseif testData.class == "ROGUE" then
        frame.powerBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow energy
    else
        frame.powerBar:SetStatusBarColor(0.5, 0.5, 1, 1) -- Default
    end
    
    -- Set class color background
    local classColor = RAID_CLASS_COLORS[testData.class]
    if classColor then
        frame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.3)
    end
    
    -- Set role icon
    if testData.role == "TANK" then
        frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
        frame.roleIcon:Show()
    elseif testData.role == "HEALER" then
        frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        frame.roleIcon:Show()
    elseif testData.role == "DAMAGER" then
        frame.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        frame.roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
        frame.roleIcon:Show()
    else
        frame.roleIcon:Hide()
    end
    
    -- Set status
    if testData.status then
        frame.statusText:SetText(testData.status)
        if testData.status == "COMBAT" then
            frame.statusText:SetTextColor(1, 1, 0, 1)
        else
            frame.statusText:SetTextColor(1, 0, 0, 1)
        end
    else
        frame.statusText:SetText("")
    end
end

-- Slash commands are now registered in main WoW95.lua file

-- Register the module with WoW95
print("WoW95: About to register PartyRaid module...")
WoW95.PartyRaid = PartyRaid
WoW95:RegisterModule("PartyRaid", PartyRaid)
print("WoW95: PartyRaid module registered successfully!")

