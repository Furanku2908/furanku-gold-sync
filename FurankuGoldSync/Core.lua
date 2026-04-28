local addonName, addon = ...

-- constants
local PREFIX = "|cffA335EE[FGS]|r "
local FULLNAME = "|cffA335EE[Furanku Gold Sync]|r "

-- defaults
FGS_DB = FGS_DB or {}

local defaults = {
    targetGold = 50000,
    autoSync = false,
}

-- helper functions
local function Print(msg)
    print(PREFIX .. tostring(msg))
end

local function NamePrint(msg)
    print(FULLNAME .. tostring(msg))
end

local function IsWarbandBankInteraction(interactionType)
    return interactionType == 8 or interactionType == 68
end

local function MoneyConverter (amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) /100)
    local copper = amount % 100

    return gold, silver, copper
end

local function FormatMoney(amount)
    local g, s, c = MoneyConverter(amount)

    if s == 0 and c == 0 then
        return g .. "g"
    elseif c == 0 then
        return g .. "g " .. s .. "s"
    else
        return g .. "g " .. s .. "s " .. c .. "c"
    end
end

-- command functions
local function SetAutoSync(value)
    value = string.lower(value or "")

    if value == "" then
        FGS_DB.autoSync = not (FGS_DB.autoSync == true)

        if FGS_DB.autoSync then
            Print("Auto sync enabled")
        else
            Print("Auto sync disabled")
        end

    elseif value == "on" or value == "an" or value == "1" then
        FGS_DB.autoSync = true
        Print("Auto sync enabled")

    elseif value == "off" or value == "aus" or value == "0" then
        FGS_DB.autoSync = false
        Print("Auto sync disabled")

    else
        Print("Unknown value for auto sync: " .. tostring(value))
    end
end

local function SetTargetGold(value)
    local amount = tonumber(value)
    if amount == nil then
        Print("Invalid gold amount. Use e.g.: /fgs set 50000")
        return
    end

    if amount < 0 then
        Print("Gold amount cannot be negative.")
        return
    end

    FGS_DB.targetGold = math.floor(amount)
    Print("Target Gold set to: " .. tostring(FGS_DB.targetGold))
end

local function StatusCommand()
    local targetGold = ("Target Gold is set to " .. tostring(FGS_DB.targetGold) .. " Gold") 
    local sync = FGS_DB.autoSync and "Auto sync is enabled" or "Auto sync is disabled"

    Print("Current Status:")
    Print(sync)
    Print(targetGold)
end    

local function HelpCommand()
    Print("Commands:")
    Print("/fgs or /fgsync for Options")
    Print("/fgs set <gold> to set target gold amount")
    Print("/fgs auto [on|off] to toggle auto sync")
    Print("/fgs status to see current settings")
    
end



-- apply defaults
local function ApplyDefaults()
    for key, value in pairs(defaults) do
        if FGS_DB[key] == nil then
            FGS_DB[key] = value
        end
    end
end

-- slash command handling
local function HandleSlashCommand(msg)
    msg = msg or ""

    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "help" then
        HelpCommand()

    elseif command == "set" then
        SetTargetGold(rest)

    elseif command == "auto" then
        local autoValue = string.lower(rest or "")
        SetAutoSync(autoValue)

    elseif command == "status" then
        StatusCommand()
    
    elseif command == "options" or command == "config" or command == "opt" or command == "conf" or command == ""  then
        Print("Option command detected")
    else
        Print("Unknown command: " .. tostring(command))
        Print("Use /fgs help or /fgsync help")
    end
end


-- main logic
local function OnLogin()
    SLASH_FURANKUGOLDSYNC1 = "/fgs"
    SLASH_FURANKUGOLDSYNC2 = "/fgsync"

    SlashCmdList["FURANKUGOLDSYNC"] = HandleSlashCommand
    ApplyDefaults()
    NamePrint("Loaded!")
end

-- event registration
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OnLogin()

    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        local interactionType = ...
        --Print("Interaction opened: " .. tostring(interactionType))
        if IsWarbandBankInteraction(interactionType) then
            --Print("Warband bank detected")
            if FGS_DB.autoSync then
                --Print("Auto sync would run now")
                local playerMoney = GetMoney()
                local targetGold = FGS_DB.targetGold
                local targetMoney = (targetGold * 10000)
                local differenceMoney = playerMoney - targetMoney
                local bankMoney = C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0
                Print("Curent gold: " .. FormatMoney(playerMoney))
                Print("Target gold: " .. FormatMoney(targetMoney))
                if differenceMoney == 0 then
                    Print("Gold synced.")
                elseif differenceMoney < 0 then
                    Print("Missing: " .. FormatMoney(-differenceMoney))
                    if bankMoney == 0 then
                        Print("Warbank has no gold to withdraw.") 
                    elseif bankMoney < -differenceMoney then
                        
                        Print("Not enough gold in Warband Bank. Withdrawing remaining: " .. FormatMoney(bankMoney) )
                        C_Bank.WithdrawMoney(Enum.BankType.Account, bankMoney)
                    else
                        Print("Withdrawing missing gold")
                        C_Bank.WithdrawMoney(Enum.BankType.Account, -differenceMoney)
                    end
                else
                    Print("Excess: " .. FormatMoney(differenceMoney))
                    Print("Depositing excess gold.")
                    C_Bank.DepositMoney(Enum.BankType.Account, differenceMoney)
                end

            else
                 Print("Auto sync is disabled")
            end
        end
    end
end)
