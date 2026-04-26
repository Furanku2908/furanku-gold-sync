local addonName, addon = ...

-- constants
local PREFIX = "|cffA335EE[FGS]|r "
local FULLNAME = "|cffA335EE[Furanku Gold Sync]|r "

-- helper functions
local function Print(msg)
    print(PREFIX .. tostring(msg))
end
local function NamePrint(msg)
    print(FULLNAME .. tostring(msg))
end


-- main logic
local function OnLogin()
    SLASH_FURANKUGOLDSYNC1 = "/fgs"
    SLASH_FURANKUGOLDSYNC2 = "/fgsync"

    SlashCmdList["FURANKUGOLDSYNC"] = HandleSlashCommand

    NamePrint("Loaded!")
end
-- slash command handling
local function HandleSlashCommand(msg)
    msg = msg or ""

    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "help" then
        Print("Help command detected")

    elseif command == "set" then
        Print("Set command detected with value: " .. tostring(rest))

    elseif command == "auto" then
        local autoValue = string.lower(rest or "")
        Print("Auto command detected with value: " .. tostring(autoValue))

    elseif command == "status" then
        Print("Status command detected")

    else
        Print("Unknown command: " .. tostring(command))
        Print("Use /fgs help or /fgsync help")
    end
end

-- event registration
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        OnLogin()
    end
end)
