local addonName, addon = ...

-- constants / yettings
local PREFIX = "|cffA335EE[FGS]|r "
local FULLNAME = "|cffA335EE[Furanku Gold Sync]|r "

-- helper-functions
local function Print(msg)
    print(PREFIX .. tostring(msg))
end
local function NamePrint(msg)
    print(FULLNAME .. tostring(msg))
end


-- main-function
local function OnLogin()
    Print("Loaded!")
end

-- register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        OnLogin()
    end
end)
