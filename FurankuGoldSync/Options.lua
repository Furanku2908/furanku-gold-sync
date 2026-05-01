local addonName, addon = ...

local panel = CreateFrame("Frame")
panel.name = "Furanku Gold Sync"

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

        Print("Category set to: Global")
        return
    end

    if not FGS_DB.categories[categoryKey] then
        Print("Category not found: " .. tostring(categoryKey))
        return
    end

    FGS_DB.characters[charKey] = FGS_DB.characters[charKey] or {}
    FGS_DB.characters[charKey].category = categoryKey

    Print("Category set to: " .. tostring(categoryKey))
end

local function IsReservedCategoryKey(key)
    return key == "global"
end

local function CreateCategory(key, gold)
    EnsureDB()

    key = string.lower(key or "")
    key = key:gsub("%s+", "_")

    if key == "" then
        Print("Invalid category key.")
        return false
    end

    if IsReservedCategoryKey(key) then
        Print("'global' is reserved and cannot be used as a category name.")
        return false
    end

    if FGS_DB.categories[key] then
        Print("Category already exists: " .. key)
        return false
    end

    local amount = tonumber(gold)

    if not amount or amount < 0 then
        Print("Invalid gold value.")
        return false
    end

    FGS_DB.categories[key] = {
        name = key,
        targetGold = math.floor(amount),
        autoSync = true,
        builtIn = false,
    }

    Print("Created category: " .. key .. " (" .. math.floor(amount) .. "g)")
    return true
end

local function DeleteCategory(categoryKey)
    EnsureDB()

    if not categoryKey or categoryKey == "" then
        Print("No category selected.")
        return false
    end

    if categoryKey == "global" then
        Print("'global' is not a category and cannot be deleted.")
        return false
    end

    local category = FGS_DB.categories[categoryKey]

    if not category then
        Print("Category not found: " .. tostring(categoryKey))
        return false
    end

    if category.builtIn then
        Print("Built-in categories cannot be deleted.")
        return false
    end

    FGS_DB.categories[categoryKey] = nil

    for _, charData in pairs(FGS_DB.characters) do
        if charData.category == categoryKey then
            charData.category = nil
        end
    end

    Print("Deleted category: " .. categoryKey)
    return true
end

-- Forward declaration
local Refresh

-- =========================
-- Panel
-- =========================

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Furanku Gold Sync")

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

local categoryLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
categoryLabel:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -25)
categoryLabel:SetText("Character Category:")

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
autoButton.Text:SetText("Enable auto sync for current selection")

local targetLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
targetLabel:SetPoint("TOPLEFT", autoButton, "BOTTOMLEFT", 0, -25)
targetLabel:SetText("Target Gold:")

local targetBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
targetBox:SetSize(120, 24)
targetBox:SetPoint("LEFT", targetLabel, "RIGHT", 10, 0)
targetBox:SetAutoFocus(false)
targetBox:SetNumeric(true)

local saveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
saveButton:SetSize(80, 24)
saveButton:SetPoint("LEFT", targetBox, "RIGHT", 10, 0)
saveButton:SetText("Save")

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.5, 0.5, 0.5, 0.4)
divider:SetSize(420, 1)
divider:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -30)

local createTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
createTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -18)
createTitle:SetText("Create Category")

local newCategoryLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
newCategoryLabel:SetPoint("TOPLEFT", createTitle, "BOTTOMLEFT", 0, -15)
newCategoryLabel:SetText("Key:")

local newCategoryBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
newCategoryBox:SetSize(120, 24)
newCategoryBox:SetPoint("LEFT", newCategoryLabel, "RIGHT", 10, 0)
newCategoryBox:SetAutoFocus(false)

local newCategoryGoldLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
newCategoryGoldLabel:SetPoint("LEFT", newCategoryBox, "RIGHT", 15, 0)
newCategoryGoldLabel:SetText("Gold:")

local newCategoryGoldBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
newCategoryGoldBox:SetSize(100, 24)
newCategoryGoldBox:SetPoint("LEFT", newCategoryGoldLabel, "RIGHT", 10, 0)
newCategoryGoldBox:SetAutoFocus(false)
newCategoryGoldBox:SetNumeric(true)

local createButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
createButton:SetSize(80, 24)
createButton:SetPoint("LEFT", newCategoryGoldBox, "RIGHT", 10, 0)
createButton:SetText("Create")

local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
deleteButton:SetSize(140, 24)
deleteButton:SetPoint("TOPLEFT", newCategoryLabel, "BOTTOMLEFT", 0, -25)
deleteButton:SetText("Delete Selected")

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
        "Current Category: " .. categoryText .. "\n" ..
        "Target Gold: " .. tostring(targetGold) .. "g\n" ..
        "Auto Sync: " .. (autoSync and "Enabled" or "Disabled")
    )

    UIDropDownMenu_SetText(categoryDropdown, categoryText)
    targetBox:SetText(tostring(targetGold))
    autoButton:SetChecked(autoSync == true)

    local canDelete = categoryKey ~= nil
        and categoryKey ~= "global"
        and category ~= nil
        and category.builtIn ~= true

    deleteButton:SetEnabled(canDelete)
end

autoButton:SetScript("OnClick", function(self)
    EnsureDB()

    local categoryKey = GetCurrentCategoryKey()
    local checked = self:GetChecked() == true

    if categoryKey then
        FGS_DB.categories[categoryKey].autoSync = checked
        Print("Auto sync for category '" .. categoryKey .. "' set to " .. (checked and "enabled" or "disabled"))
    else
        FGS_DB.globalAutoSync = checked
        Print("Global auto sync set to " .. (checked and "enabled" or "disabled"))
    end

    Refresh()
end)

saveButton:SetScript("OnClick", function()
    EnsureDB()

    local value = tonumber(targetBox:GetText())

    if not value or value < 0 then
        Print("Invalid target gold. Example: 50000")
        return
    end

    local amount = math.floor(value)
    local categoryKey = GetCurrentCategoryKey()

    if categoryKey then
        FGS_DB.categories[categoryKey].targetGold = amount
        Print("Target gold for category '" .. categoryKey .. "' set to " .. amount .. "g")
    else
        FGS_DB.globalTargetGold = amount
        Print("Global target gold set to " .. amount .. "g")
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