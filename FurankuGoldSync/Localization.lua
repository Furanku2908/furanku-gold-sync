-- ============================================================================
-- Localization.lua - Furanku Gold Sync
-- ============================================================================
-- This file contains all localized strings for the addon in multiple languages.
-- 
-- Structure:
--   FGS_L[language][key] = value
--   - FGS_L.enUS: English localized strings
--   - FGS_L.deDE: German (Deutsch) localized strings
--
-- Usage:
--   Access localized strings via: FGS_GetLocalizedString(key, ...)
--   This function is defined in Localization.lua and handles:
--   - Language selection (uses client locale by default, overridable in DB)
--   - String formatting with variable arguments (e.g., "%s", "%d")
-- ============================================================================

local addonName, addon = ...

-- Global localization table: accessible throughout the addon
FGS_L = {
    enUS = {
        AUTO_SYNC_ENABLED = "Auto sync enabled",
        AUTO_SYNC_DISABLED = "Auto sync disabled",
        INVALID_GOLD_AMOUNT = "Invalid gold amount. Use e.g.: /fgs set 50000",
        GOLD_CANNOT_NEGATIVE = "Gold amount cannot be negative.",
        TARGET_GOLD_SET = "Target Gold set to: %s",
        CURRENT_STATUS = "Current Status:",
        TARGET_GOLD_STATUS = "Target Gold is set to %s Gold",
        CATEGORY_STATUS = "Category: %s",
        COMMANDS = "Commands:",
        CMD_OPTIONS = "/fgs or /fgsync for Options",
        CMD_SET = "/fgs set <gold> to set target gold amount",
        CMD_AUTO = "/fgs auto [on|off] to toggle auto sync",
        CMD_STATUS = "/fgs status to see current settings",
        UNKNOWN_VALUE_AUTO_SYNC = "Unknown value for auto sync: %s",
        OPTIONS_NOT_AVAILABLE = "Options panel is not available.",
        CATEGORIES = "Categories:",
        CATEGORY_LIST_ITEM = "- %s (%s): %sg",
        CATEGORY_SET_GLOBAL = "Category set to: Global",
        CATEGORY_NOT_FOUND = "Category not found: %s",
        CATEGORY_SET_TO = "Category set to: %s",
        INVALID_CATEGORY_KEY = "Invalid category key. Use: /fgs category create <key> <gold>",
        GLOBAL_RESERVED = "'global' is reserved and cannot be used as a category name.",
        CATEGORY_EXISTS = "Category already exists: %s",
        INVALID_GOLD_VALUE = "Invalid gold value",
        CREATED_CATEGORY = "Created category: %s (%sg)",
        INVALID_CATEGORY_KEY_TARGET = "Invalid category key. Use: /fgs category target <key> <gold>",
        TARGET_GOLD_CATEGORY_SET = "Target gold for category '%s' set to %sg",
        INVALID_CATEGORY_KEY_DELETE = "Invalid category key. Use: /fgs category delete <key>",
        GLOBAL_NOT_CATEGORY = "'global' is not a category and cannot be deleted.",
        BUILT_IN_CANNOT_DELETE = "Built-in categories cannot be deleted.",
        DELETED_CATEGORY = "Deleted category: %s",
        CATEGORY_USAGE = "Usage:",
        CMD_CATEGORY_LIST = "/fgs category list",
        CMD_CATEGORY_SET = "/fgs category set <key>",
        CMD_CATEGORY_SET_GLOBAL = "/fgs category set global",
        CMD_CATEGORY_CREATE = "/fgs category create <key> <gold>",
        CMD_CATEGORY_TARGET = "/fgs category target <key> <gold>",
        CMD_CATEGORY_DELETE = "/fgs category delete <key>",
        UNKNOWN_COMMAND = "Unknown command: %s",
        USE_HELP = "Use /fgs help or /fgsync help",
        LOADED = "Loaded!",
        CURRENT_GOLD = "Current gold: %s",
        TARGET_GOLD = "Target gold: %s",
        GOLD_SYNCED = "Gold synced.",
        MISSING = "Missing: %s",
        WARBANK_NO_GOLD = "Warbank has no gold to withdraw.",
        NOT_ENOUGH_GOLD_WARBANK = "Not enough gold in Warband Bank. Withdrawing remaining: %s",
        WITHDRAWING_MISSING = "Withdrawing missing gold",
        EXCESS = "Excess: %s",
        DEPOSITING_EXCESS = "Depositing excess gold.",
        AUTO_SYNC_DISABLED_STATUS = "Auto sync is disabled",
        -- UI strings
        PANEL_TITLE = "Furanku Gold Sync",
        CHARACTER_CATEGORY = "Character Category:",
        ENABLE_AUTO_SYNC = "Enable auto sync for current selection",
        TARGET_GOLD_LABEL = "Target Gold:",
        SAVE_BUTTON = "Save",
        CREATE_CATEGORY_TITLE = "Create Category",
        KEY_LABEL = "Key:",
        GOLD_LABEL = "Gold:",
        CREATE_BUTTON = "Create",
        DELETE_SELECTED = "Delete Selected",
        CURRENT_CATEGORY_STATUS = "Current Category: %s",
        TARGET_GOLD_UI = "Target Gold: %sg",
        AUTO_SYNC_UI = "Auto Sync: %s",
        ENABLED = "Enabled",
        DISABLED = "Disabled",
        INVALID_CATEGORY_KEY_UI = "Invalid category key.",
        NO_CATEGORY_SELECTED = "No category selected.",
        LANGUAGE_LABEL = "Language:",
    },
    deDE = {
        AUTO_SYNC_ENABLED = "Auto-Sync aktiviert",
        AUTO_SYNC_DISABLED = "Auto-Sync deaktiviert",
        INVALID_GOLD_AMOUNT = "Ungültiger Goldbetrag. Verwende z.B.: /fgs set 50000",
        GOLD_CANNOT_NEGATIVE = "Goldbetrag kann nicht negativ sein.",
        TARGET_GOLD_SET = "Ziel-Gold gesetzt auf: %s",
        CURRENT_STATUS = "Aktueller Status:",
        TARGET_GOLD_STATUS = "Ziel-Gold ist gesetzt auf %s Gold",
        CATEGORY_STATUS = "Kategorie: %s",
        COMMANDS = "Befehle:",
        CMD_OPTIONS = "/fgs oder /fgsync für Optionen",
        CMD_SET = "/fgs set <gold> um Ziel-Gold zu setzen",
        CMD_AUTO = "/fgs auto [on|off] um Auto-Sync umzuschalten",
        CMD_STATUS = "/fgs status um aktuelle Einstellungen zu sehen",
        UNKNOWN_VALUE_AUTO_SYNC = "Unbekannter Wert für Auto-Sync: %s",
        OPTIONS_NOT_AVAILABLE = "Options-Panel ist nicht verfügbar.",
        CATEGORIES = "Kategorien:",
        CATEGORY_LIST_ITEM = "- %s (%s): %sg",
        CATEGORY_SET_GLOBAL = "Kategorie gesetzt auf: Global",
        CATEGORY_NOT_FOUND = "Kategorie nicht gefunden: %s",
        CATEGORY_SET_TO = "Kategorie gesetzt auf: %s",
        INVALID_CATEGORY_KEY = "Ungültiger Kategorie-Schlüssel. Verwende: /fgs category create <key> <gold>",
        GLOBAL_RESERVED = "'global' ist reserviert und kann nicht als Kategoriename verwendet werden.",
        CATEGORY_EXISTS = "Kategorie existiert bereits: %s",
        INVALID_GOLD_VALUE = "Ungültiger Goldwert",
        CREATED_CATEGORY = "Kategorie erstellt: %s (%sg)",
        INVALID_CATEGORY_KEY_TARGET = "Ungültiger Kategorie-Schlüssel. Verwende: /fgs category target <key> <gold>",
        TARGET_GOLD_CATEGORY_SET = "Ziel-Gold für Kategorie '%s' gesetzt auf %sg",
        INVALID_CATEGORY_KEY_DELETE = "Ungültiger Kategorie-Schlüssel. Verwende: /fgs category delete <key>",
        GLOBAL_NOT_CATEGORY = "'global' ist keine Kategorie und kann nicht gelöscht werden.",
        BUILT_IN_CANNOT_DELETE = "Eingebaute Kategorien können nicht gelöscht werden.",
        DELETED_CATEGORY = "Kategorie gelöscht: %s",
        CATEGORY_USAGE = "Verwendung:",
        CMD_CATEGORY_LIST = "/fgs category list",
        CMD_CATEGORY_SET = "/fgs category set <key>",
        CMD_CATEGORY_SET_GLOBAL = "/fgs category set global",
        CMD_CATEGORY_CREATE = "/fgs category create <key> <gold>",
        CMD_CATEGORY_TARGET = "/fgs category target <key> <gold>",
        CMD_CATEGORY_DELETE = "/fgs category delete <key>",
        UNKNOWN_COMMAND = "Unbekannter Befehl: %s",
        USE_HELP = "Verwende /fgs help oder /fgsync help",
        LOADED = "Geladen!",
        CURRENT_GOLD = "Aktuelles Gold: %s",
        TARGET_GOLD = "Ziel-Gold: %s",
        GOLD_SYNCED = "Gold synchronisiert.",
        MISSING = "Fehlend: %s",
        WARBANK_NO_GOLD = "Warbank hat kein Gold zum Abheben.",
        NOT_ENOUGH_GOLD_WARBANK = "Nicht genug Gold in der Warband Bank. Restliches abheben: %s",
        WITHDRAWING_MISSING = "Fehlendes Gold abheben",
        EXCESS = "Überschuss: %s",
        DEPOSITING_EXCESS = "Überschüssiges Gold einzahlen.",
        AUTO_SYNC_DISABLED_STATUS = "Auto-Sync ist deaktiviert",
        -- UI strings
        PANEL_TITLE = "Furanku Gold Sync",
        CHARACTER_CATEGORY = "Charakter-Kategorie:",
        ENABLE_AUTO_SYNC = "Auto-Sync für aktuelle Auswahl aktivieren",
        TARGET_GOLD_LABEL = "Ziel-Gold:",
        SAVE_BUTTON = "Speichern",
        CREATE_CATEGORY_TITLE = "Kategorie erstellen",
        KEY_LABEL = "Schlüssel:",
        GOLD_LABEL = "Gold:",
        CREATE_BUTTON = "Erstellen",
        DELETE_SELECTED = "Ausgewählte löschen",
        CURRENT_CATEGORY_STATUS = "Aktuelle Kategorie: %s",
        TARGET_GOLD_UI = "Ziel-Gold: %sg",
        AUTO_SYNC_UI = "Auto-Sync: %s",
        ENABLED = "Aktiviert",
        DISABLED = "Deaktiviert",
        INVALID_CATEGORY_KEY_UI = "Ungültiger Kategorie-Schlüssel.",
        NO_CATEGORY_SELECTED = "Keine Kategorie ausgewählt.",
        LANGUAGE_LABEL = "Sprache:",
    },
}

-- ============================================================================
-- FGS_GetLocalizedString(key, ...)
-- ============================================================================
-- Retrieves a localized string from the FGS_L table with optional formatting.
--
-- Parameters:
--   key (string): The localization key to look up (e.g., "AUTO_SYNC_ENABLED")
--   ...: Optional arguments for string formatting (supports standard Lua string.format)
--
-- Returns:
--   string: The localized string, formatted with any provided arguments.
--           If the key doesn't exist, returns the key itself as fallback.
--
-- Behavior:
--   - Respects FGS_DB.language override if set by the user in Options
--   - Falls back to client locale (GetLocale()) if no override is set
--   - Falls back to English (enUS) if the selected language is unavailable
--   - Supports format strings like "Hello %s, you have %dg"
-- ============================================================================
function FGS_GetLocalizedString(key, ...)
    -- Get the language preference: user override (FGS_DB.language) or client locale
    local locale = FGS_DB and FGS_DB.language or GetLocale()

    -- Get string table for the selected language, fall back to English
    local strings = FGS_L[locale] or FGS_L.enUS

    -- Get the localized string, fall back to English key, then the key itself
    local str = strings[key] or FGS_L.enUS[key] or key

    -- Return formatted string (handles both with and without arguments)
    return string.format(str, ...)
end