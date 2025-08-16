-- Simple PartyRaid test file

print("WoW95: Loading PartyRaidSimple.lua...")

local PartyRaidSimple = {}

function PartyRaidSimple:Initialize()
    print("WoW95: PartyRaidSimple initialized!")
end

function PartyRaidSimple:Init()
    self:Initialize()
end

-- Register the module with WoW95 (simple direct registration like other modules)
print("WoW95: About to register PartyRaidSimple...")
WoW95.PartyRaidSimple = PartyRaidSimple
WoW95:RegisterModule("PartyRaidSimple", PartyRaidSimple)
print("WoW95: PartyRaidSimple registered successfully!")