-- WoW95 Tooltip Module
-- Windows XP styled tooltip replacement

local addonName, WoW95 = ...

local Tooltip = {}
WoW95.Tooltip = Tooltip

-- Tooltip settings
Tooltip.isInitialized = false
Tooltip.customTooltip = nil
Tooltip.isActive = false

-- Windows XP color scheme
local XP_COLORS = {
    background = {1, 1, 0.85, 1},              -- Light yellow background
    border = {0.4, 0.4, 0.4, 1},               -- Dark gray border
    text = {0, 0, 0, 1},                       -- Black text
    titleText = {0, 0, 0.7, 1},                -- Dark blue for titles
    highlightText = {0.7, 0, 0, 1},            -- Dark red for highlights
}

function Tooltip:Init()
    WoW95:Debug("Initializing Windows XP Tooltip module...")
    
    -- Create our custom Windows XP tooltip
    self:CreateXPTooltip()
    
    -- Hook into the default tooltip system
    self:HookGameTooltip()
    
    self.isInitialized = true
    WoW95:Debug("Tooltip module initialized successfully!")
end

function Tooltip:CreateXPTooltip()
    -- Create the main tooltip frame
    local tooltip = CreateFrame("Frame", "WoW95XPTooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetFrameLevel(1000)
    tooltip:Hide()
    
    -- Windows XP style background with border
    tooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 1,
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    
    tooltip:SetBackdropColor(XP_COLORS.background[1], XP_COLORS.background[2], XP_COLORS.background[3], XP_COLORS.background[4])
    tooltip:SetBackdropBorderColor(XP_COLORS.border[1], XP_COLORS.border[2], XP_COLORS.border[3], XP_COLORS.border[4])
    
    -- Create drop shadow effect (Windows XP style)
    local shadow = CreateFrame("Frame", nil, tooltip, "BackdropTemplate")
    shadow:SetFrameLevel(tooltip:GetFrameLevel() - 1)
    shadow:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 2, -2)
    shadow:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 2, -2)
    shadow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 1
    })
    shadow:SetBackdropColor(0, 0, 0, 0.3) -- Semi-transparent black shadow
    
    -- Store references
    tooltip.shadow = shadow
    tooltip.textLines = {}
    tooltip.currentLine = 0
    
    self.customTooltip = tooltip
    return tooltip
end

function Tooltip:ClearTooltip()
    local tooltip = self.customTooltip
    if not tooltip then return end
    
    -- Hide and clear all text lines
    for i, line in ipairs(tooltip.textLines) do
        if line then
            line:Hide()
            line:SetText("")
        end
    end
    
    tooltip.currentLine = 0
    self.isActive = false
end

function Tooltip:AddLine(text, r, g, b, a)
    local tooltip = self.customTooltip
    if not tooltip then return end
    
    -- Validate and set color parameters safely
    local red = tonumber(r) or XP_COLORS.text[1]
    local green = tonumber(g) or XP_COLORS.text[2]
    local blue = tonumber(b) or XP_COLORS.text[3]
    local alpha = tonumber(a) or XP_COLORS.text[4]
    
    -- Increment line counter
    tooltip.currentLine = tooltip.currentLine + 1
    local lineIndex = tooltip.currentLine
    
    -- Create or reuse text line
    if not tooltip.textLines[lineIndex] then
        tooltip.textLines[lineIndex] = tooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tooltip.textLines[lineIndex]:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        tooltip.textLines[lineIndex]:SetJustifyH("LEFT")
        tooltip.textLines[lineIndex]:SetWordWrap(false)
    end
    
    local textLine = tooltip.textLines[lineIndex]
    
    -- Set text and color safely
    textLine:SetText(text or "")
    textLine:SetTextColor(red, green, blue, alpha)
    
    -- Position the line
    textLine:ClearAllPoints()
    if lineIndex == 1 then
        textLine:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, -8)
    else
        textLine:SetPoint("TOPLEFT", tooltip.textLines[lineIndex - 1], "BOTTOMLEFT", 0, -2)
    end
    
    textLine:Show()
    
    -- WoW95:Debug("Added tooltip line " .. lineIndex .. ": " .. (text or ""))
end

function Tooltip:SetOwner(owner, anchor, offsetX, offsetY)
    local tooltip = self.customTooltip
    if not tooltip then return end
    
    -- Clear existing content
    self:ClearTooltip()
    
    -- Store owner and positioning info
    tooltip.owner = owner
    tooltip.anchor = anchor or "ANCHOR_CURSOR"
    tooltip.offsetX = offsetX or 0
    tooltip.offsetY = offsetY or 0
    
    self.isActive = true
    
    WoW95:Debug("Tooltip owner set: " .. (owner and owner:GetName() or "Unknown"))
end

function Tooltip:Show()
    local tooltip = self.customTooltip
    if not tooltip or not self.isActive then return end
    
    -- Only show if we have content
    if tooltip.currentLine == 0 then
        WoW95:Debug("No tooltip content to show")
        return
    end
    
    -- Calculate tooltip size
    local maxWidth = 0
    local totalHeight = 16 -- Padding
    
    for i = 1, tooltip.currentLine do
        local line = tooltip.textLines[i]
        if line and line:IsShown() then
            local width = line:GetStringWidth()
            local height = line:GetStringHeight()
            maxWidth = math.max(maxWidth, width)
            totalHeight = totalHeight + height + (i > 1 and 2 or 0) -- Line spacing
        end
    end
    
    -- Set final size (minimum size for readability)
    local finalWidth = math.max(maxWidth + 16, 60)
    local finalHeight = math.max(totalHeight, 20)
    
    tooltip:SetSize(finalWidth, finalHeight)
    tooltip.shadow:SetSize(finalWidth, finalHeight)
    
    -- Position tooltip
    self:PositionTooltip()
    
    -- Show tooltip and shadow
    tooltip:Show()
    tooltip.shadow:Show()
    
    WoW95:Debug("Showing XP tooltip: " .. finalWidth .. "x" .. finalHeight .. " with " .. tooltip.currentLine .. " lines")
end

function Tooltip:Hide()
    local tooltip = self.customTooltip
    if tooltip then
        tooltip:Hide()
        tooltip.shadow:Hide()
        self:ClearTooltip()
    end
    WoW95:Debug("Hiding XP tooltip")
end

function Tooltip:PositionTooltip()
    local tooltip = self.customTooltip
    if not tooltip or not tooltip.owner then return end
    
    tooltip:ClearAllPoints()
    
    local anchor = tooltip.anchor
    local owner = tooltip.owner
    
    if anchor == "ANCHOR_CURSOR" then
        -- Position at cursor with offset
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 
            (x / scale) + 15 + tooltip.offsetX, 
            (y / scale) + 15 + tooltip.offsetY)
    elseif anchor == "ANCHOR_TOP" then
        tooltip:SetPoint("BOTTOM", owner, "TOP", tooltip.offsetX, 5 + tooltip.offsetY)
    elseif anchor == "ANCHOR_BOTTOM" then
        tooltip:SetPoint("TOP", owner, "BOTTOM", tooltip.offsetX, -5 + tooltip.offsetY)
    elseif anchor == "ANCHOR_LEFT" then
        tooltip:SetPoint("RIGHT", owner, "LEFT", -5 + tooltip.offsetX, tooltip.offsetY)
    elseif anchor == "ANCHOR_RIGHT" then
        tooltip:SetPoint("LEFT", owner, "RIGHT", 5 + tooltip.offsetX, tooltip.offsetY)
    else
        -- Default to cursor
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 
            (x / scale) + 15 + tooltip.offsetX, 
            (y / scale) + 15 + tooltip.offsetY)
    end
    
    -- Keep tooltip on screen
    self:ClampToScreen()
end

function Tooltip:ClampToScreen()
    local tooltip = self.customTooltip
    if not tooltip then return end
    
    local left = tooltip:GetLeft()
    local right = tooltip:GetRight()
    local top = tooltip:GetTop()
    local bottom = tooltip:GetBottom()
    
    if not left or not right or not top or not bottom then return end
    
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    local offsetX = 0
    local offsetY = 0
    
    -- Check bounds and adjust
    if right > screenWidth then
        offsetX = screenWidth - right - 10
    elseif left < 0 then
        offsetX = -left + 10
    end
    
    if top > screenHeight then
        offsetY = screenHeight - top - 10
    elseif bottom < 0 then
        offsetY = -bottom + 10
    end
    
    if offsetX ~= 0 or offsetY ~= 0 then
        local point, relativeTo, relativePoint, x, y = tooltip:GetPoint()
        tooltip:SetPoint(point, relativeTo, relativePoint, x + offsetX, y + offsetY)
    end
end

function Tooltip:HookGameTooltip()
    -- Store original functions
    local originalSetOwner = GameTooltip.SetOwner
    local originalAddLine = GameTooltip.AddLine
    local originalShow = GameTooltip.Show
    local originalHide = GameTooltip.Hide
    local originalSetText = GameTooltip.SetText
    local originalAddDoubleLine = GameTooltip.AddDoubleLine
    
    -- Hook SetOwner
    GameTooltip.SetOwner = function(self, owner, anchor, offsetX, offsetY, ...)
        -- WoW95:Debug("GameTooltip:SetOwner called")
        
        -- Set up our custom tooltip
        WoW95.Tooltip:SetOwner(owner, anchor, offsetX, offsetY)
        
        -- Call original but hide it
        local result = originalSetOwner(self, owner, anchor, offsetX, offsetY, ...)
        self:SetAlpha(0) -- Hide original
        
        return result
    end
    
    -- Hook AddLine
    GameTooltip.AddLine = function(self, text, r, g, b, a, ...)
        -- WoW95:Debug("GameTooltip:AddLine called: " .. (text or "nil"))
        
        -- Add to our custom tooltip
        if WoW95.Tooltip.isActive then
            WoW95.Tooltip:AddLine(text, r, g, b, a)
        end
        
        -- Call original
        return originalAddLine(self, text, r, g, b, a, ...)
    end
    
    -- Hook SetText (used by some pet tooltips and simple tooltips)
    GameTooltip.SetText = function(self, text, r, g, b, a, ...)
        -- WoW95:Debug("GameTooltip:SetText called: " .. (text or "nil"))
        
        -- Clear and add text to our custom tooltip
        if WoW95.Tooltip.isActive then
            WoW95.Tooltip:ClearTooltip()
            WoW95.Tooltip:AddLine(text, r, g, b, a)
        end
        
        -- Call original
        return originalSetText(self, text, r, g, b, a, ...)
    end
    
    -- Hook AddDoubleLine (used for some formatted tooltips)
    GameTooltip.AddDoubleLine = function(self, leftText, rightText, lr, lg, lb, la, rr, rg, rb, ra, ...)
        -- WoW95:Debug("GameTooltip:AddDoubleLine called: " .. (leftText or "nil") .. " | " .. (rightText or "nil"))
        
        -- Add both parts to our custom tooltip
        if WoW95.Tooltip.isActive then
            -- Combine left and right text with spacing
            local combinedText = (leftText or "") .. "  " .. (rightText or "")
            WoW95.Tooltip:AddLine(combinedText, lr, lg, lb, la)
        end
        
        -- Call original
        return originalAddDoubleLine(self, leftText, rightText, lr, lg, lb, la, rr, rg, rb, ra, ...)
    end
    
    -- Hook Show
    GameTooltip.Show = function(self, ...)
        -- WoW95:Debug("GameTooltip:Show called")
        
        -- Show our custom tooltip instead
        if WoW95.Tooltip.isActive then
            WoW95.Tooltip:Show()
            return -- Don't show original
        end
        
        return originalShow(self, ...)
    end
    
    -- Hook Hide
    GameTooltip.Hide = function(self, ...)
        -- WoW95:Debug("GameTooltip:Hide called")
        
        -- Hide our custom tooltip
        WoW95.Tooltip:Hide()
        
        -- Restore original alpha and hide
        self:SetAlpha(1)
        return originalHide(self, ...)
    end
    
    -- Also hook BattlePetTooltip for pet-specific tooltips
    if BattlePetTooltip then
        local originalPetShow = BattlePetTooltip.Show
        BattlePetTooltip.Show = function(self, ...)
            WoW95:Debug("BattlePetTooltip:Show called")
            
            -- Try to extract pet info and show in our tooltip
            if self.Name and self.Name:GetText() then
                WoW95.Tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                WoW95.Tooltip:AddLine(self.Name:GetText(), XP_COLORS.titleText[1], XP_COLORS.titleText[2], XP_COLORS.titleText[3], XP_COLORS.titleText[4])
                
                -- Add other pet info if available
                if self.PetType and self.PetType:GetText() then
                    WoW95.Tooltip:AddLine(self.PetType:GetText())
                end
                if self.Level and self.Level:GetText() then
                    WoW95.Tooltip:AddLine("Level " .. self.Level:GetText())
                end
                
                WoW95.Tooltip:Show()
                
                -- Hide the original pet tooltip
                self:SetAlpha(0)
                return
            end
            
            return originalPetShow(self, ...)
        end
        
        local originalPetHide = BattlePetTooltip.Hide
        BattlePetTooltip.Hide = function(self, ...)
            WoW95:Debug("BattlePetTooltip:Hide called")
            
            -- Hide our custom tooltip
            WoW95.Tooltip:Hide()
            
            -- Restore original alpha and hide
            self:SetAlpha(1)
            return originalPetHide(self, ...)
        end
    end
    
    WoW95:Debug("GameTooltip hooks installed (including pet support)")
end

-- Utility functions
function Tooltip:ShowSimpleTooltip(text, anchor, r, g, b)
    self:SetOwner(UIParent, anchor or "ANCHOR_CURSOR")
    self:AddLine(text, r, g, b)
    self:Show()
end

function Tooltip:IsShown()
    return self.customTooltip and self.customTooltip:IsShown()
end

-- Register the module
WoW95:RegisterModule("Tooltip", Tooltip)