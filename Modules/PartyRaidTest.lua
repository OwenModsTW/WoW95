-- Simple test file to see if module loading works

print("WoW95: Loading PartyRaidTest.lua...")

local PartyRaidTest = {}

function PartyRaidTest:Initialize()
    print("WoW95: PartyRaidTest initialized!")
end

function PartyRaidTest:EnableTestMode()
    print("TEST: Creating fake party window...")
    
    -- Create a simple window for testing
    local testWindow = CreateFrame("Frame", "WoW95TestPartyWindow", UIParent, "BackdropTemplate")
    testWindow:SetSize(200, 300)
    testWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -120)
    testWindow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    testWindow:SetBackdropColor(0.7, 0.7, 0.7, 1)
    testWindow:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Add title
    local title = testWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", testWindow, "TOP", 0, -10)
    title:SetText("TEST PARTY FRAME")
    
    -- Add some test members
    for i = 1, 4 do
        local memberFrame = CreateFrame("Frame", nil, testWindow, "BackdropTemplate")
        memberFrame:SetSize(180, 30)
        memberFrame:SetPoint("TOPLEFT", testWindow, "TOPLEFT", 10, -30 - (i * 35))
        memberFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 4,
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        memberFrame:SetBackdropColor(0.5, 0.5, 0.5, 1)
        memberFrame:SetBackdropBorderColor(0, 0, 0, 1)
        
        local memberText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        memberText:SetPoint("LEFT", memberFrame, "LEFT", 5, 0)
        memberText:SetText("Test Member " .. i)
    end
    
    testWindow:Show()
    self.testWindow = testWindow
    
    print("TEST: Party test window created successfully!")
end

function PartyRaidTest:DisableTestMode()
    if self.testWindow then
        self.testWindow:Hide()
        self.testWindow = nil
        print("TEST: Party test window hidden")
    else
        print("TEST: No test window to hide")
    end
end

print("WoW95: Setting PartyRaidTest reference...")
WoW95.PartyRaidTest = PartyRaidTest
print("WoW95: Reference set, now registering module...")
WoW95:RegisterModule("PartyRaidTest", PartyRaidTest)
print("WoW95: PartyRaidTest module registered!")