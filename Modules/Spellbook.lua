-- WoW95 Spellbook Module
-- Skins the default Blizzard spellbook with Windows 95 styling

local addonName, WoW95 = ...

local Spellbook = {}
WoW95.Spellbook = Spellbook

-- Keep track of original textures to restore if needed
local originalTextures = {}
local isStyled = false

function Spellbook:Init()
    WoW95:Debug("Initializing Spellbook module - Skinning vanilla UI...")
    
    -- Hook spellbook opening to apply our skin
    self:HookSpellbookEvents()
    
    -- Add debug command to manually test styling
    SLASH_SPELLSKIN1 = "/spellskin"
    SlashCmdList["SPELLSKIN"] = function()
        isStyled = false -- Reset flag
        if SpellBookFrame and SpellBookFrame:IsShown() then
            Spellbook:ApplyWindows95Skin()
        else
            WoW95:Debug("SpellBookFrame not shown, cannot apply styling. Open spellbook first.")
        end
    end
    
    WoW95:Debug("Spellbook module initialized")
end

function Spellbook:HookSpellbookEvents()
    -- Hook the modern spellbook toggle functions
    if ToggleSpellBook then
        hooksecurefunc("ToggleSpellBook", function(bookType)
            if SpellBookFrame and SpellBookFrame:IsShown() then
                -- Small delay to let the frame fully show before styling
                C_Timer.After(0.1, function()
                    Spellbook:ApplyWindows95Skin()
                end)
            end
        end)
    end
    
    -- Also hook ShowUIPanel which is used to show the spellbook
    hooksecurefunc("ShowUIPanel", function(frame)
        if frame == SpellBookFrame then
            C_Timer.After(0.1, function()
                Spellbook:ApplyWindows95Skin()
            end)
        end
    end)
    
    -- Hook direct spellbook frame show
    local function HookSpellBookFrame()
        if SpellBookFrame then
            SpellBookFrame:HookScript("OnShow", function()
                Spellbook:ApplyWindows95Skin()
            end)
            WoW95:Debug("Hooked SpellBookFrame OnShow")
        end
    end
    
    -- Try to hook immediately if the frame exists
    if SpellBookFrame then
        HookSpellBookFrame()
    else
        -- Wait for the spellbook addon to load
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", function(self, event, addonName)
            if addonName == "Blizzard_SpellBook" or SpellBookFrame then
                HookSpellBookFrame()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
    
    -- Also hook spell updates to re-style buttons
    local updateFrame = CreateFrame("Frame")
    updateFrame:RegisterEvent("SPELLS_CHANGED")
    updateFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    updateFrame:SetScript("OnEvent", function()
        if SpellBookFrame and SpellBookFrame:IsShown() and isStyled then
            -- Re-style spell buttons in case new ones were created
            C_Timer.After(0.1, function()
                Spellbook:StyleSpellButtons()
            end)
        end
    end)
end

function Spellbook:ApplyWindows95Skin()
    WoW95:Debug("ApplyWindows95Skin called - SpellBookFrame exists: " .. tostring(SpellBookFrame ~= nil))
    WoW95:Debug("IsStyled: " .. tostring(isStyled))
    
    if not SpellBookFrame then
        WoW95:Debug("SpellBookFrame not found, cannot apply styling")
        return
    end
    
    if isStyled then
        WoW95:Debug("Already styled, skipping")
        return
    end
    
    WoW95:Debug("Applying Windows 95 skin to Blizzard spellbook...")
    
    -- Style the main spellbook frame
    self:StyleMainFrame()
    
    -- Style the tabs
    self:StyleTabs()
    
    -- Style the spell buttons
    self:StyleSpellButtons()
    
    -- Style the close button
    self:StyleCloseButton()
    
    isStyled = true
    WoW95:Debug("Windows 95 skin applied to spellbook")
end

function Spellbook:StyleMainFrame()
    -- Apply Windows 95 background and border
    if SpellBookFrame then
        -- Set Windows 95 background color
        if not SpellBookFrame.wow95bg then
            SpellBookFrame.wow95bg = SpellBookFrame:CreateTexture(nil, "BACKGROUND")
            SpellBookFrame.wow95bg:SetAllPoints()
            SpellBookFrame.wow95bg:SetColorTexture(WoW95.colors.buttonFace.r, WoW95.colors.buttonFace.g, WoW95.colors.buttonFace.b, 1)
        end
        
        -- Hide original background textures
        for i = 1, SpellBookFrame:GetNumRegions() do
            local region = select(i, SpellBookFrame:GetRegions())
            if region and region:GetObjectType() == "Texture" and region ~= SpellBookFrame.wow95bg then
                if not originalTextures[region] then
                    originalTextures[region] = region:IsShown()
                end
                region:Hide()
            end
        end
    end
end

function Spellbook:StyleTabs()
    -- Style spellbook tabs with Windows 95 look
    for i = 1, 10 do -- Check more tabs to be safe
        local tab = _G["SpellBookSkillLineTab" .. i]
        if tab then
            self:StyleTab(tab)
        end
    end
end

function Spellbook:StyleTab(tab)
    if not tab or tab.wow95styled then 
        return 
    end
    
    -- Hide original tab texture
    local normalTexture = tab:GetNormalTexture()
    if normalTexture then
        originalTextures[normalTexture] = normalTexture:IsShown()
        normalTexture:Hide()
    end
    
    -- Create Windows 95 style tab background
    if not tab.wow95bg then
        tab.wow95bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.wow95bg:SetAllPoints()
        tab.wow95bg:SetColorTexture(WoW95.colors.buttonFace.r, WoW95.colors.buttonFace.g, WoW95.colors.buttonFace.b, 1)
    end
    
    -- Add Windows 95 style border
    if not tab.wow95border then
        tab.wow95border = CreateFrame("Frame", nil, tab)
        tab.wow95border:SetAllPoints()
        
        -- Create raised button border effect
        tab.wow95border.topLeft = tab.wow95border:CreateTexture(nil, "OVERLAY")
        tab.wow95border.topLeft:SetColorTexture(WoW95.colors.buttonHighlight.r, WoW95.colors.buttonHighlight.g, WoW95.colors.buttonHighlight.b, 1)
        tab.wow95border.topLeft:SetPoint("TOPLEFT", 0, 0)
        tab.wow95border.topLeft:SetPoint("BOTTOMRIGHT", tab.wow95border, "TOPRIGHT", -1, -1)
        
        tab.wow95border.bottomRight = tab.wow95border:CreateTexture(nil, "OVERLAY")
        tab.wow95border.bottomRight:SetColorTexture(WoW95.colors.buttonShadow.r, WoW95.colors.buttonShadow.g, WoW95.colors.buttonShadow.b, 1)
        tab.wow95border.bottomRight:SetPoint("BOTTOMRIGHT", 0, 0)
        tab.wow95border.bottomRight:SetPoint("TOPLEFT", tab.wow95border, "BOTTOMLEFT", 1, 1)
    end
    
    tab.wow95styled = true
end

function Spellbook:StyleSpellButtons()
    -- Style the individual spell buttons
    for i = 1, 12 do -- Standard number of spell buttons shown per page
        local button = _G["SpellButton" .. i]
        if button then
            self:StyleSpellButton(button)
        end
    end
end

function Spellbook:StyleSpellButton(button)
    if not button or button.wow95styled then 
        return 
    end
    
    -- Hide original button texture but keep icon
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        originalTextures[normalTexture] = normalTexture:IsShown()
        normalTexture:Hide()
    end
    
    -- Create Windows 95 style button background
    if not button.wow95bg then
        button.wow95bg = button:CreateTexture(nil, "BACKGROUND")
        button.wow95bg:SetAllPoints()
        button.wow95bg:SetColorTexture(WoW95.colors.buttonFace.r, WoW95.colors.buttonFace.g, WoW95.colors.buttonFace.b, 1)
    end
    
    -- Add subtle Windows 95 border
    if not button.wow95border then
        button.wow95border = CreateFrame("Frame", nil, button)
        button.wow95border:SetAllPoints()
        
        -- Top-left highlight
        button.wow95border.topLeft = button.wow95border:CreateTexture(nil, "OVERLAY")
        button.wow95border.topLeft:SetColorTexture(WoW95.colors.buttonHighlight.r, WoW95.colors.buttonHighlight.g, WoW95.colors.buttonHighlight.b, 0.5)
        button.wow95border.topLeft:SetPoint("TOPLEFT", 0, 0)
        button.wow95border.topLeft:SetPoint("BOTTOMRIGHT", button.wow95border, "TOPRIGHT", -1, -1)
        
        -- Bottom-right shadow
        button.wow95border.bottomRight = button.wow95border:CreateTexture(nil, "OVERLAY")
        button.wow95border.bottomRight:SetColorTexture(WoW95.colors.buttonShadow.r, WoW95.colors.buttonShadow.g, WoW95.colors.buttonShadow.b, 0.5)
        button.wow95border.bottomRight:SetPoint("BOTTOMRIGHT", 0, 0)
        button.wow95border.bottomRight:SetPoint("TOPLEFT", button.wow95border, "BOTTOMLEFT", 1, 1)
    end
    
    button.wow95styled = true
end

function Spellbook:StyleCloseButton()
    local closeButton = SpellBookCloseButton
    if closeButton and WoW95.textures and WoW95.textures.close then
        -- Use our custom close button texture
        closeButton:SetNormalTexture(WoW95.textures.close)
        closeButton:SetPushedTexture(WoW95.textures.close)
        closeButton:SetHighlightTexture(WoW95.textures.close)
        
        -- Adjust size if needed
        closeButton:SetSize(16, 16)
    end
end

-- Register the module
WoW95:RegisterModule("Spellbook", Spellbook)