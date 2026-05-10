local addonName, addon = ...

-- ============================================================================
-- ADDON METADATA & CONSTANTS
-- ============================================================================
-- Chat message prefixes for console output
local PREFIX = "|cffA335EE[FGS]|r "                -- Prefix for addon messages
local FULLNAME = "|cffA335EE[Furanku Gold Sync]|r" -- Full name prefix
local CURRENT_DB_VERSION = 2                       -- Current database schema version

-- Pending options flag: Stores whether options should be opened when combat ends
local pendingOpenOptions = false

-- ============================================================================
-- SAVED VARIABLES & DEFAULTS
-- ============================================================================
-- FGS_DB: Persistent SavedVariables table (stored per character/realm)
FGS_DB = FGS_DB or {}

-- Default database structure that gets merged with existing SavedVariables
local defaults = {
    dbVersion = CURRENT_DB_VERSION,                 -- Version for migration support
    globalTargetGold = 50000,                       -- Default gold target amount
    globalAutoSync = true,                          -- Auto-sync enabled by default
    language = nil,                                 -- nil = use client locale, can be overridden
    -- Built-in categories: Main, Twink, and Inactive with preset gold targets
    categories = {
        main = { name = "Main", targetGold = 50000, autoSync = true, builtIn = true },
        twink = { name = "Twink", targetGold = 30000, autoSync = true, builtIn = true },
        inactive = { name = "Inactive", targetGold = 10000, autoSync = false, builtIn = true },
    },
    characters = {},  -- Character-specific settings: maps "realm-name" -> {category, autoSyncOverride, etc}
}

-- ============================================================================
-- HELPER FUNCTIONS - Output Formatting
-- ============================================================================
-- Print(msg): Print a message with addon prefix
-- Outputs formatted messages to chat with the addon prefix
local function Print(msg)
    print(PREFIX .. tostring(msg))
end

-- NamePrint(msg): Print a message with full addon name prefix
-- Used for important messages like addon loaded notification
local function NamePrint(msg)
    print(FULLNAME .. tostring(msg))
end

-- ============================================================================
-- HELPER FUNCTIONS - Game Interaction Detection & Money Formatting
-- ============================================================================
-- IsWarbandBankInteraction(interactionType): Detect Warband Bank interactions
-- Warband Bank can be accessed via:
--   - Type 8: Direct Warband Bank frame
--   - Type 68: Bank frame with Warband option
local function IsWarbandBankInteraction(interactionType)
    return interactionType == 8 or interactionType == 68
end

-- MoneyConverter(amount): Convert money in copper to gold, silver, copper
-- WoW stores money as total copper (1 gold = 10000 copper, 1 silver = 100 copper)
-- Returns: gold, silver, copper (e.g., 123456 copper -> 12g, 34s, 56c)
local function MoneyConverter (amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) /100)
    local copper = amount % 100

    return gold, silver, copper
end

-- FormatMoney(amount): Convert copper amount to human-readable gold string
-- Examples: 123456 -> "12g 34s 56c", 500000 -> "50g"
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

-- ============================================================================
-- HELPER FUNCTIONS - Character & Category Lookup
-- ============================================================================
-- GetCharacterKey(): Generate a unique identifier for the current character
-- Format: "RealmName-CharacterName" (e.g., "Area 52-Herold")
-- Used to store per-character settings in FGS_DB.characters
local function GetCharacterKey()
    return GetRealmName() .. "-" .. UnitName("player")
end

-- GetCurrentCategoryKey(): Get the category assigned to the current character
-- Returns: the category key (string) or nil if character uses global settings
local function GetCurrentCategoryKey()
    local charKey = GetCharacterKey()
    local charData = FGS_DB.characters and FGS_DB.characters[charKey]
    return charData and charData.category or nil
end

-- GetCurrentCategory(): Fetch the full category table for the current character
-- Returns: table with {name, targetGold, autoSync, builtIn} or nil
local function GetCurrentCategory()
    local categoryKey = GetCurrentCategoryKey()
    if not categoryKey then
        return nil
    end

    return FGS_DB.categories and FGS_DB.categories[categoryKey]
end


-- ============================================================================
-- HELPER FUNCTIONS - Settings Lookup & Resolution
-- ============================================================================
-- GetCurrentTargetGold(): Resolve the target gold amount with proper precedence
-- Priority: Character Override > Category Setting > Global Setting > Default (50000)
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

-- IsAutoSyncEnabledForCurrentCharacter(): Resolve whether auto-sync is enabled
-- Priority: Character Override > Category Setting > Global Setting > Default (true)
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



-- ============================================================================
-- COMMAND FUNCTIONS - User Interface Commands
-- ============================================================================
-- OpenOptions(): Open the addon settings panel
-- Called when user runs: /fgs, /fgs options, /fgs config, etc.
local function OpenOptions()
    if InCombatLockdown() then
        Print(FGS_GetLocalizedString("CANNOT_OPEN_OPTIONS_IN_COMBAT"))
        pendingOpenOptions = true
        return
    end
    
    if addon.optionsCategory and addon.optionsCategory.ID then
        Settings.OpenToCategory(addon.optionsCategory.ID)
    else
        Print(FGS_GetLocalizedString("OPTIONS_NOT_AVAILABLE"))
    end
end

-- SetAutoSync(value): Toggle or set auto-sync globally
-- Parameters: "" (toggle), "on"/"an"/"1" (enable), "off"/"aus"/"0" (disable)
local function SetAutoSync(value)
    value = string.lower(value or "")

    if value == "" then
        FGS_DB.globalAutoSync = not (FGS_DB.globalAutoSync == true)

        if IsAutoSyncEnabledForCurrentCharacter() then
            Print(FGS_GetLocalizedString("AUTO_SYNC_ENABLED"))
        else
            Print(FGS_GetLocalizedString("AUTO_SYNC_DISABLED"))
        end

    elseif value == "on" or value == "an" or value == "1" then
        FGS_DB.globalAutoSync = true
        Print(FGS_GetLocalizedString("AUTO_SYNC_ENABLED"))

    elseif value == "off" or value == "aus" or value == "0" then
        FGS_DB.globalAutoSync = false
        Print(FGS_GetLocalizedString("AUTO_SYNC_DISABLED"))

    else
        Print(FGS_GetLocalizedString("UNKNOWN_VALUE_AUTO_SYNC", value))
    end
end

local function SetTargetGold(value)
    local amount = tonumber(value)
    if amount == nil then
        Print(FGS_GetLocalizedString("INVALID_GOLD_AMOUNT"))
        return
    end

    if amount < 0 then
        Print(FGS_GetLocalizedString("GOLD_CANNOT_NEGATIVE"))
        return
    end

    FGS_DB.globalTargetGold = math.floor(amount)
    Print(FGS_GetLocalizedString("TARGET_GOLD_SET", tostring(FGS_DB.globalTargetGold)))
end

local function StatusCommand()
    local targetGold = GetCurrentTargetGold()
    local sync = IsAutoSyncEnabledForCurrentCharacter() and FGS_GetLocalizedString("AUTO_SYNC_ENABLED") or FGS_GetLocalizedString("AUTO_SYNC_DISABLED_STATUS")
    local categoryKey = GetCurrentCategoryKey()

    Print(FGS_GetLocalizedString("CURRENT_STATUS"))
    Print(sync)
    Print(FGS_GetLocalizedString("TARGET_GOLD_STATUS", tostring(targetGold)))
    Print(FGS_GetLocalizedString("CATEGORY_STATUS", tostring(categoryKey or "Global")))
end 

-- HelpCommand(): Display available slash commands to the user
local function HelpCommand()
    Print(FGS_GetLocalizedString("COMMANDS"))
    Print(FGS_GetLocalizedString("CMD_OPTIONS"))
    Print(FGS_GetLocalizedString("CMD_SET"))
    Print(FGS_GetLocalizedString("CMD_AUTO"))
    Print(FGS_GetLocalizedString("CMD_STATUS"))
end

-- IsReservedCategoryKey(key): Check whether a category key is reserved and not allowed for custom categories
local function IsReservedCategoryKey(key)
    return key == "global"
end
-- ============================================================================
-- CATEGORY MANAGEMENT FUNCTIONS
-- ============================================================================
local function ListCategories()
    Print(FGS_GetLocalizedString("CATEGORIES"))

    for key, cat in pairs(FGS_DB.categories) do
        Print(FGS_GetLocalizedString("CATEGORY_LIST_ITEM", key, cat.name, cat.targetGold))
    end
end

local function SetCategory(categoryKey)
    if categoryKey == "global" then
        local charKey = GetCharacterKey()

        if FGS_DB.characters[charKey] then
            FGS_DB.characters[charKey].category = nil
        end

        Print(FGS_GetLocalizedString("CATEGORY_SET_GLOBAL"))
        return
    end
    
    if not FGS_DB.categories[categoryKey] then
        Print(FGS_GetLocalizedString("CATEGORY_NOT_FOUND", categoryKey))
        return
    end

    local charKey = GetCharacterKey()
    FGS_DB.characters[charKey] = FGS_DB.characters[charKey] or {}

    FGS_DB.characters[charKey].category = categoryKey

    Print(FGS_GetLocalizedString("CATEGORY_SET_TO", categoryKey))
end

local function CreateCategory(key, gold)
    if not key or key == "" then
        Print(FGS_GetLocalizedString("INVALID_CATEGORY_KEY"))
        return
    end
    if IsReservedCategoryKey(key) then
        Print(FGS_GetLocalizedString("GLOBAL_RESERVED"))
        return
    end
    if FGS_DB.categories[key] then
        Print(FGS_GetLocalizedString("CATEGORY_EXISTS", key))
        return
    end

    local amount = tonumber(gold)
    if not amount then
        Print(FGS_GetLocalizedString("INVALID_GOLD_VALUE"))
        return
    end

    if not amount or amount < 0 then
        Print(FGS_GetLocalizedString("INVALID_GOLD_VALUE"))
        return
    end
    
    FGS_DB.categories[key] = {
        name = key,
        targetGold = math.floor(amount),
        autoSync = true,
        builtIn = false,
    }

    Print(FGS_GetLocalizedString("CREATED_CATEGORY", key, amount))
end

local function SetCategoryTarget(categoryKey, value)
    if not categoryKey or categoryKey == "" then
        Print(FGS_GetLocalizedString("INVALID_CATEGORY_KEY_TARGET"))
        return
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print(FGS_GetLocalizedString("CATEGORY_NOT_FOUND", categoryKey))
        return
    end

    local amount = tonumber(value)

    if not amount or amount < 0 then
        Print(FGS_GetLocalizedString("INVALID_GOLD_VALUE"))
        return
    end

    category.targetGold = math.floor(amount)
    Print(FGS_GetLocalizedString("TARGET_GOLD_CATEGORY_SET", categoryKey, category.targetGold))
end

local function DeleteCategory(categoryKey)
    if not categoryKey or categoryKey == "" then
        Print(FGS_GetLocalizedString("INVALID_CATEGORY_KEY_DELETE"))
        return
    end

    if categoryKey == "global" then
        Print(FGS_GetLocalizedString("GLOBAL_NOT_CATEGORY"))
        return
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print(FGS_GetLocalizedString("CATEGORY_NOT_FOUND", categoryKey))
        return
    end

    if category.builtIn then
        Print(FGS_GetLocalizedString("BUILT_IN_CANNOT_DELETE"))
        return
    end

    FGS_DB.categories[categoryKey] = nil

    for _, charData in pairs(FGS_DB.characters) do
        if charData.category == categoryKey then
            charData.category = nil
        end
    end

    Print(FGS_GetLocalizedString("DELETED_CATEGORY", categoryKey))
end

local function CategoryHelpCommand()
    Print(FGS_GetLocalizedString("CATEGORY_USAGE"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_LIST"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_SET"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_SET_GLOBAL"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_CREATE"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_TARGET"))
    Print(FGS_GetLocalizedString("CMD_CATEGORY_DELETE"))
end

-- ============================================================================
-- DATABASE MANAGEMENT - Initialization, Defaults & Migration
-- ============================================================================
-- MigrateDatabase(): Handle version upgrades and legacy data migration
-- v1 -> v2: Migrates old targetGold/autoSync fields to global versions
local function MigrateDatabase()
    FGS_DB = FGS_DB or {}

    -- v1 -> v2: Migrate legacy fields
    if not FGS_DB.dbVersion then
        -- Migrate targetGold to globalTargetGold
        if FGS_DB.targetGold ~= nil and FGS_DB.globalTargetGold == nil then
            FGS_DB.globalTargetGold = FGS_DB.targetGold
        end

        -- Migrate autoSync to globalAutoSync
        if FGS_DB.autoSync ~= nil and FGS_DB.globalAutoSync == nil then
            FGS_DB.globalAutoSync = FGS_DB.autoSync
        end

        -- Set default auto-sync if not set
        if FGS_DB.globalAutoSync == nil then
            FGS_DB.globalAutoSync = true
        end

        FGS_DB.dbVersion = 2
    end
end

-- DeepMergeDefaults(target, defaults): Recursively merge default values into target table
-- Only fills in missing keys; does not overwrite existing values
-- Handles nested tables (like categories)
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

-- ApplyDefaults(): Initialize or update the database with default values
-- Called at addon load to ensure all required fields exist in FGS_DB
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
        Print(FGS_GetLocalizedString("UNKNOWN_COMMAND", command))
        Print(FGS_GetLocalizedString("USE_HELP"))
    end
end


-- main logic
local function OnLogin()
    SLASH_FURANKUGOLDSYNC1 = "/fgs"
    SLASH_FURANKUGOLDSYNC2 = "/fgsync"

    SlashCmdList["FURANKUGOLDSYNC"] = HandleSlashCommand
    ApplyDefaults()
    local ICON = "|TInterface\\AddOns\\FurankuGoldSync\\media\\icon:16:16|t "
    NamePrint(ICON .. FGS_GetLocalizedString("LOADED"))
end

-- event registration
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OnLogin()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingOpenOptions then
            pendingOpenOptions = false
            Print(FGS_GetLocalizedString("OPTIONS_OPENING_AFTER_COMBAT"))
            if addon.optionsCategory and addon.optionsCategory.ID then
                Settings.OpenToCategory(addon.optionsCategory.ID)
            end
        end

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
                Print(FGS_GetLocalizedString("CURRENT_GOLD", FormatMoney(playerMoney)))
                Print(FGS_GetLocalizedString("TARGET_GOLD", FormatMoney(targetMoney)))
                if differenceMoney == 0 then
                    Print(FGS_GetLocalizedString("GOLD_SYNCED"))
                elseif differenceMoney < 0 then
                    Print(FGS_GetLocalizedString("MISSING", FormatMoney(-differenceMoney)))
                    if bankMoney == 0 then
                        Print(FGS_GetLocalizedString("WARBANK_NO_GOLD")) 
                    elseif bankMoney < -differenceMoney then
                        
                        Print(FGS_GetLocalizedString("NOT_ENOUGH_GOLD_WARBANK", FormatMoney(bankMoney)))
                        C_Bank.WithdrawMoney(Enum.BankType.Account, bankMoney)
                    else
                        Print(FGS_GetLocalizedString("WITHDRAWING_MISSING"))
                        C_Bank.WithdrawMoney(Enum.BankType.Account, -differenceMoney)
                    end
                else
                    Print(FGS_GetLocalizedString("EXCESS", FormatMoney(differenceMoney)))
                    Print(FGS_GetLocalizedString("DEPOSITING_EXCESS"))
                    C_Bank.DepositMoney(Enum.BankType.Account, differenceMoney)
                end

            else
                 Print(FGS_GetLocalizedString("AUTO_SYNC_DISABLED_STATUS"))
            end
        end
    end
end)
