local addonName, addon = ...

local panel = CreateFrame("Frame")
panel.name = FGS_GetLocalizedString("PANEL_TITLE")

-- =========================
-- Helpers
-- =========================

local function Print(msg)
    print("|cffA335EE[FGS]|r " .. tostring(msg))
end

local function EnsureDB()
    FGS_DB = FGS_DB or {}
    FGS_DB.globalTargetGold = FGS_DB.globalTargetGold or 50000

    if FGS_DB.globalAutoSync == nil then
        FGS_DB.globalAutoSync = true
    end

    FGS_DB.categories = FGS_DB.categories or {}
    FGS_DB.characters = FGS_DB.characters or {}
end

local function GetCharacterKey()
    return GetRealmName() .. "-" .. UnitName("player")
end

local function GetCurrentCategoryKey()
    EnsureDB()

    local charKey = GetCharacterKey()
    local charData = FGS_DB.characters[charKey]

    return charData and charData.category or nil
end

local function GetCurrentCategory()
    local categoryKey = GetCurrentCategoryKey()

    if not categoryKey then
        return nil
    end

    return FGS_DB.categories[categoryKey]
end

local function GetCurrentTargetGold()
    EnsureDB()

    local category = GetCurrentCategory()

    if category and category.targetGold ~= nil then
        return category.targetGold
    end

    return FGS_DB.globalTargetGold or 50000
end

local function IsCurrentAutoSyncEnabled()
    EnsureDB()

    local category = GetCurrentCategory()

    if category and category.autoSync ~= nil then
        return category.autoSync == true
    end

    return FGS_DB.globalAutoSync == true
end

local function SetCurrentCategory(categoryKey)
    EnsureDB()

    local charKey = GetCharacterKey()

    if categoryKey == "global" then
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

    FGS_DB.characters[charKey] = FGS_DB.characters[charKey] or {}
    FGS_DB.characters[charKey].category = categoryKey

    Print(FGS_GetLocalizedString("CATEGORY_SET_TO", categoryKey))
end

local function IsReservedCategoryKey(key)
    return key == "global"
end

local function CreateCategory(key, gold)
    EnsureDB()

    key = string.lower(key or "")
    key = key:gsub("%s+", "_")

    if key == "" then
        Print(FGS_GetLocalizedString("INVALID_CATEGORY_KEY_UI"))
        return false
    end

    if IsReservedCategoryKey(key) then
        Print(FGS_GetLocalizedString("GLOBAL_RESERVED"))
        return false
    end

    if FGS_DB.categories[key] then
        Print(FGS_GetLocalizedString("CATEGORY_EXISTS", key))
        return false
    end

    local amount = tonumber(gold)

    if not amount or amount < 0 then
        Print(FGS_GetLocalizedString("INVALID_GOLD_VALUE"))
        return false
    end

    FGS_DB.categories[key] = {
        name = key,
        targetGold = math.floor(amount),
        autoSync = true,
        builtIn = false,
    }

    Print(FGS_GetLocalizedString("CREATED_CATEGORY", key, amount))
    return true
end

local function DeleteCategory(categoryKey)
    EnsureDB()

    if not categoryKey or categoryKey == "" then
        Print(FGS_GetLocalizedString("NO_CATEGORY_SELECTED"))
        return false
    end

    if categoryKey == "global" then
        Print(FGS_GetLocalizedString("GLOBAL_NOT_CATEGORY"))
        return false
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print(FGS_GetLocalizedString("CATEGORY_NOT_FOUND", categoryKey))
        return false
    end

    if category.builtIn then
        Print(FGS_GetLocalizedString("BUILT_IN_CANNOT_DELETE"))
        return false
    end

    FGS_DB.categories[categoryKey] = nil

    for _, charData in pairs(FGS_DB.characters) do
        if charData.category == categoryKey then
            charData.category = nil
        end
    end

    Print(FGS_GetLocalizedString("DELETED_CATEGORY", categoryKey))
    return true
end

-- Forward declaration
local Refresh

-- =========================
-- Panel
-- =========================

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(FGS_GetLocalizedString("PANEL_TITLE"))

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

local categoryLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
categoryLabel:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -25)
categoryLabel:SetText(FGS_GetLocalizedString("CHARACTER_CATEGORY"))

local categoryDropdown = CreateFrame("Frame", "FGS_CategoryDropdown", panel, "UIDropDownMenuTemplate")
categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", -10, -2)

UIDropDownMenu_Initialize(categoryDropdown, function(self, level)
    EnsureDB()

    local info = UIDropDownMenu_CreateInfo()
    info.text = "Global"
    info.func = function()
        SetCurrentCategory("global")
        Refresh()
    end
    UIDropDownMenu_AddButton(info, level)

    for key, cat in pairs(FGS_DB.categories) do
        local categoryInfo = UIDropDownMenu_CreateInfo()
        categoryInfo.text = tostring(cat.name) .. " (" .. tostring(key) .. ")"
        categoryInfo.func = function()
            SetCurrentCategory(key)
            Refresh()
        end
        UIDropDownMenu_AddButton(categoryInfo, level)
    end
end)

local autoButton = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
autoButton:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -25)
autoButton.Text:SetText(FGS_GetLocalizedString("ENABLE_AUTO_SYNC"))

local targetLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
targetLabel:SetPoint("TOPLEFT", autoButton, "BOTTOMLEFT", 0, -25)
targetLabel:SetText(FGS_GetLocalizedString("TARGET_GOLD_LABEL"))

local targetBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
targetBox:SetSize(120, 24)
targetBox:SetPoint("LEFT", targetLabel, "RIGHT", 10, 0)
targetBox:SetAutoFocus(false)
targetBox:SetNumeric(true)

local saveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
saveButton:SetSize(80, 24)
saveButton:SetPoint("LEFT", targetBox, "RIGHT", 10, 0)
saveButton:SetText(FGS_GetLocalizedString("SAVE_BUTTON"))

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.5, 0.5, 0.5, 0.4)
divider:SetSize(420, 1)
divider:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -30)

local createTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
createTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -18)
createTitle:SetText(FGS_GetLocalizedString("CREATE_CATEGORY_TITLE"))

local newCategoryLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
newCategoryLabel:SetPoint("TOPLEFT", createTitle, "BOTTOMLEFT", 0, -15)
newCategoryLabel:SetText(FGS_GetLocalizedString("KEY_LABEL"))

local newCategoryBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
newCategoryBox:SetSize(120, 24)
newCategoryBox:SetPoint("LEFT", newCategoryLabel, "RIGHT", 10, 0)
newCategoryBox:SetAutoFocus(false)

local newCategoryGoldLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
newCategoryGoldLabel:SetPoint("LEFT", newCategoryBox, "RIGHT", 15, 0)
newCategoryGoldLabel:SetText(FGS_GetLocalizedString("GOLD_LABEL"))

local newCategoryGoldBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
newCategoryGoldBox:SetSize(100, 24)
newCategoryGoldBox:SetPoint("LEFT", newCategoryGoldLabel, "RIGHT", 10, 0)
newCategoryGoldBox:SetAutoFocus(false)
newCategoryGoldBox:SetNumeric(true)

local createButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
createButton:SetSize(80, 24)
createButton:SetPoint("LEFT", newCategoryGoldBox, "RIGHT", 10, 0)
createButton:SetText(FGS_GetLocalizedString("CREATE_BUTTON"))

local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
deleteButton:SetSize(140, 24)
deleteButton:SetPoint("TOPLEFT", newCategoryLabel, "BOTTOMLEFT", 0, -25)
deleteButton:SetText(FGS_GetLocalizedString("DELETE_SELECTED"))

local languageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
languageLabel:SetPoint("TOPLEFT", deleteButton, "BOTTOMLEFT", 0, -25)
languageLabel:SetText(FGS_GetLocalizedString("LANGUAGE_LABEL"))

local languageDropdown = CreateFrame("Frame", "FGS_LanguageDropdown", panel, "UIDropDownMenuTemplate")
languageDropdown:SetPoint("LEFT", languageLabel, "RIGHT", -10, -2)

UIDropDownMenu_Initialize(languageDropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "English"
    info.func = function()
        FGS_DB.language = "enUS"
        Print("Language set to English")
        Refresh()
    end
    UIDropDownMenu_AddButton(info, level)

    local deInfo = UIDropDownMenu_CreateInfo()
    deInfo.text = "Deutsch"
    deInfo.func = function()
        FGS_DB.language = "deDE"
        Print("Sprache auf Deutsch gesetzt")
        Refresh()
    end
    UIDropDownMenu_AddButton(deInfo, level)
end)

-- =========================
-- Refresh / Actions
-- =========================

Refresh = function()
    EnsureDB()

    local categoryKey = GetCurrentCategoryKey()
    local category = GetCurrentCategory()
    local targetGold = GetCurrentTargetGold()
    local autoSync = IsCurrentAutoSyncEnabled()

    local categoryText = "Global"
    if categoryKey and category then
        categoryText = tostring(category.name) .. " (" .. tostring(categoryKey) .. ")"
    end

    statusText:SetText(
        FGS_GetLocalizedString("CURRENT_CATEGORY_STATUS", categoryText) .. "\n" ..
        FGS_GetLocalizedString("TARGET_GOLD_UI", targetGold) .. "\n" ..
        FGS_GetLocalizedString("AUTO_SYNC_UI", autoSync and FGS_GetLocalizedString("ENABLED") or FGS_GetLocalizedString("DISABLED"))
    )

    UIDropDownMenu_SetText(categoryDropdown, categoryText)
    targetBox:SetText(tostring(targetGold))
    autoButton:SetChecked(autoSync == true)

    local canDelete = categoryKey ~= nil
        and categoryKey ~= "global"
        and category ~= nil
        and category.builtIn ~= true

    deleteButton:SetEnabled(canDelete)

    -- Set language dropdown
    local currentLang = FGS_DB.language or GetLocale()
    local langText = (currentLang == "deDE") and "Deutsch" or "English"
    UIDropDownMenu_SetText(languageDropdown, langText)
end

autoButton:SetScript("OnClick", function(self)
    EnsureDB()

    local categoryKey = GetCurrentCategoryKey()
    local checked = self:GetChecked() == true

    if categoryKey then
        FGS_DB.categories[categoryKey].autoSync = checked
        Print(FGS_GetLocalizedString("AUTO_SYNC_UI", checked and FGS_GetLocalizedString("ENABLED") or FGS_GetLocalizedString("DISABLED")))
    else
        FGS_DB.globalAutoSync = checked
        Print(FGS_GetLocalizedString("AUTO_SYNC_UI", checked and FGS_GetLocalizedString("ENABLED") or FGS_GetLocalizedString("DISABLED")))
    end

    Refresh()
end)

saveButton:SetScript("OnClick", function()
    EnsureDB()

    local value = tonumber(targetBox:GetText())

    if not value or value < 0 then
        Print(FGS_GetLocalizedString("INVALID_GOLD_AMOUNT"))
        return
    end

    local amount = math.floor(value)
    local categoryKey = GetCurrentCategoryKey()

    if categoryKey then
        FGS_DB.categories[categoryKey].targetGold = amount
        Print(FGS_GetLocalizedString("TARGET_GOLD_CATEGORY_SET", categoryKey, amount))
    else
        FGS_DB.globalTargetGold = amount
        Print(FGS_GetLocalizedString("TARGET_GOLD_SET", tostring(amount)))
    end

    targetBox:ClearFocus()
    Refresh()
end)

targetBox:SetScript("OnEnterPressed", function()
    saveButton:Click()
end)

targetBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    Refresh()
end)

createButton:SetScript("OnClick", function()
    local key = newCategoryBox:GetText()
    local gold = newCategoryGoldBox:GetText()

    if CreateCategory(key, gold) then
        newCategoryBox:SetText("")
        newCategoryGoldBox:SetText("")
        newCategoryBox:ClearFocus()
        newCategoryGoldBox:ClearFocus()
    end

    Refresh()
end)

deleteButton:SetScript("OnClick", function()
    local categoryKey = GetCurrentCategoryKey()

    if DeleteCategory(categoryKey) then
        Refresh()
    end
end)

panel:SetScript("OnShow", Refresh)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

addon.optionsCategory = category