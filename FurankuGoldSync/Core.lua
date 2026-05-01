local addonName, addon = ...

-- constants
local PREFIX = "|cffA335EE[FGS]|r "
local FULLNAME = "|cffA335EE[Furanku Gold Sync]|r "
local CURRENT_DB_VERSION = 2

-- defaults
FGS_DB = FGS_DB or {}

local defaults = {
    dbVersion = CURRENT_DB_VERSION,
    --targetGold = nil,
    --autoSync = nil,
    globalTargetGold = 50000,
    globalAutoSync = true,
    categories = {
        main = { name = "Main", targetGold = 50000, autoSync = true, builtIn = true },
        twink = { name = "Twink", targetGold = 30000, autoSync = true, builtIn = true },
        inactive = { name = "Inactive", targetGold = 10000, autoSync = false, builtIn = true },
    },
    characters = {},
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

local function GetCharacterKey()
    return GetRealmName() .. "-" .. UnitName("player")
end

local function GetCurrentCategoryKey()
    local charKey = GetCharacterKey()
    local charData = FGS_DB.characters and FGS_DB.characters[charKey]
    return charData and charData.category or nil
end

local function GetCurrentCategory()
    local categoryKey = GetCurrentCategoryKey()
    if not categoryKey then
        return nil
    end

    return FGS_DB.categories and FGS_DB.categories[categoryKey]
end


local function GetCurrentTargetGold()
    local charKey = GetCharacterKey()
    local charData = FGS_DB.characters and FGS_DB.characters[charKey]

    if charData and charData.targetGoldOverride ~= nil then
        return charData.targetGoldOverride
    end

    local category = GetCurrentCategory()
    if category and category.targetGold ~= nil then
        return category.targetGold
    end

    return FGS_DB.globalTargetGold or 50000
end

local function IsAutoSyncEnabledForCurrentCharacter()
    local charKey = GetCharacterKey()
    local charData = FGS_DB.characters and FGS_DB.characters[charKey]

    if charData and charData.autoSyncOverride ~= nil then
        return charData.autoSyncOverride
    end

    local category = GetCurrentCategory()
    if category and category.autoSync ~= nil then
        return category.autoSync == true
    end

    return FGS_DB.globalAutoSync == true
end



-- command functions
local function OpenOptions()
    if addon.optionsCategory and addon.optionsCategory.ID then
        Settings.OpenToCategory(addon.optionsCategory.ID)
    else
        Print("Options panel is not available.")
    end
end

local function SetAutoSync(value)
    value = string.lower(value or "")

    if value == "" then
        FGS_DB.globalAutoSync = not (FGS_DB.globalAutoSync == true)

        if IsAutoSyncEnabledForCurrentCharacter() then
            Print("Auto sync enabled")
        else
            Print("Auto sync disabled")
        end

    elseif value == "on" or value == "an" or value == "1" then
        FGS_DB.globalAutoSync = true
        Print("Auto sync enabled")

    elseif value == "off" or value == "aus" or value == "0" then
        FGS_DB.globalAutoSync = false
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

    FGS_DB.globalTargetGold = math.floor(amount)
    Print("Target Gold set to: " .. tostring(FGS_DB.globalTargetGold))
end

local function StatusCommand()
    local targetGold = GetCurrentTargetGold()
    local sync = IsAutoSyncEnabledForCurrentCharacter() and "Auto sync is enabled" or "Auto sync is disabled"
    local categoryKey = GetCurrentCategoryKey()

    Print("Current Status:")
    Print(sync)
    Print("Target Gold is set to " .. tostring(targetGold) .. " Gold")
    Print("Category: " .. tostring(categoryKey or "Global"))
end 

local function HelpCommand()
    Print("Commands:")
    Print("/fgs or /fgsync for Options")
    Print("/fgs set <gold> to set target gold amount")
    Print("/fgs auto [on|off] to toggle auto sync")
    Print("/fgs status to see current settings")
    
end

local function IsReservedCategoryKey(key)
    return key == "global"
end
--categories
local function ListCategories()
    Print("Categories:")

    for key, cat in pairs(FGS_DB.categories) do
        Print("- " .. key .. " (" .. cat.name .. "): " .. cat.targetGold .. "g")
    end
end

local function SetCategory(categoryKey)
    if categoryKey == "global" then
        local charKey = GetCharacterKey()

        if FGS_DB.characters[charKey] then
            FGS_DB.characters[charKey].category = nil
        end

        Print("Category set to: Global")
        return
    end
    
    if not FGS_DB.categories[categoryKey] then
        Print("Category not found: " .. tostring(categoryKey))
        return
    end

    local charKey = GetCharacterKey()
    FGS_DB.characters[charKey] = FGS_DB.characters[charKey] or {}

    FGS_DB.characters[charKey].category = categoryKey

    Print("Category set to: " .. categoryKey)
end

local function CreateCategory(key, gold)
    if not key or key == "" then
        Print("Invalid category key. Use: /fgs category create <key> <gold>")
        return
    end
    if IsReservedCategoryKey(key) then
        Print("'global' is reserved and cannot be used as a category name.")
        return
    end
    if FGS_DB.categories[key] then
        Print("Category already exists: " .. key)
        return
    end

    local amount = tonumber(gold)
    if not amount then
        Print("Invalid gold value")
        return
    end

    if not amount or amount < 0 then
        Print("Invalid gold value")
        return
    end
    
    FGS_DB.categories[key] = {
        name = key,
        targetGold = math.floor(amount),
        autoSync = true,
        builtIn = false,
    }

    Print("Created category: " .. key .. " (" .. amount .. "g)")
end

local function SetCategoryTarget(categoryKey, value)
    if not categoryKey or categoryKey == "" then
        Print("Invalid category key. Use: /fgs category target <key> <gold>")
        return
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print("Category not found: " .. tostring(categoryKey))
        return
    end

    local amount = tonumber(value)

    if not amount or amount < 0 then
        Print("Invalid gold value. Use: /fgs category target <key> <gold>")
        return
    end

    category.targetGold = math.floor(amount)
    Print("Target gold for category '" .. categoryKey .. "' set to " .. category.targetGold .. "g")
end

local function DeleteCategory(categoryKey)
    if not categoryKey or categoryKey == "" then
        Print("Invalid category key. Use: /fgs category delete <key>")
        return
    end

    if categoryKey == "global" then
        Print("'global' is not a category and cannot be deleted.")
        return
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print("Category not found: " .. tostring(categoryKey))
        return
    end

    if category.builtIn then
        Print("Built-in categories cannot be deleted.")
        return
    end

    FGS_DB.categories[categoryKey] = nil

    for _, charData in pairs(FGS_DB.characters) do
        if charData.category == categoryKey then
            charData.category = nil
        end
    end

    Print("Deleted category: " .. categoryKey)
end

local function CategoryHelpCommand()
    Print("Usage:")
    Print("/fgs category list")
    Print("/fgs category set <key>")
    Print("/fgs category set global")
    Print("/fgs category create <key> <gold>")
    Print("/fgs category target <key> <gold>")
    Print("/fgs category delete <key>")
end 

-- apply defaults
local function MigrateDatabase()
    FGS_DB = FGS_DB or {}

    -- v1 -> v1.1
    if not FGS_DB.dbVersion then
        if FGS_DB.targetGold ~= nil and FGS_DB.globalTargetGold == nil then
            FGS_DB.globalTargetGold = FGS_DB.targetGold
        end

        if FGS_DB.autoSync ~= nil and FGS_DB.globalAutoSync == nil then
            FGS_DB.globalAutoSync = FGS_DB.autoSync
        end

        if FGS_DB.globalAutoSync == nil then
            FGS_DB.globalAutoSync = true
        end

        FGS_DB.dbVersion = 2
    end
end

local function DeepMergeDefaults(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if target[key] == nil then
            if type(defaultValue) == "table" then
                target[key] = {}
                DeepMergeDefaults(target[key], defaultValue)
            else
                target[key] = defaultValue
            end
        elseif type(target[key]) == "table" and type(defaultValue) == "table" then
            DeepMergeDefaults(target[key], defaultValue)
        end
    end
end

local function ApplyDefaults()
    FGS_DB = FGS_DB or {}

    MigrateDatabase()
    DeepMergeDefaults(FGS_DB, defaults)

    FGS_DB.dbVersion = CURRENT_DB_VERSION
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
        OpenOptions()

    elseif command == "category" then
        local sub, arg1, arg2 = rest:match("^(%S*)%s*(%S*)%s*(.-)$")

        if sub == "list" then
            ListCategories()

        elseif sub == "set" then
            SetCategory(arg1)

        elseif sub == "create" then
            CreateCategory(arg1, arg2)
        elseif sub == "target" then
            SetCategoryTarget(arg1, arg2)
        elseif sub == "delete" then
            DeleteCategory(arg1)
        else
            CategoryHelpCommand()
        end
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
    local ICON = "|TInterface\\AddOns\\FurankuGoldSync\\media\\icon:16:16|t "
    NamePrint(ICON .. "Loaded!")
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
            if IsAutoSyncEnabledForCurrentCharacter() then
                --Print("Auto sync would run now")
                local playerMoney = GetMoney()
                local targetGold = GetCurrentTargetGold()
                local targetMoney = (targetGold * 10000)
                local differenceMoney = playerMoney - targetMoney
                local bankMoney = C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0
                Print("Current gold: " .. FormatMoney(playerMoney))
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
