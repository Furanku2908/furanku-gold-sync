local addonName, addon = ...

local panel = CreateFrame("Frame")
panel.name = "Furanku Gold Sync"

local function Print(msg)
    print("|cffA335EE[FGS]|r " .. tostring(msg))
end

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Furanku Gold Sync")

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

local autoButton = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
autoButton:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -20)
autoButton.Text:SetText("Enable auto sync")

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

local function Refresh()
    local targetGold = FGS_DB and FGS_DB.targetGold or 50000
    local autoSync = FGS_DB and FGS_DB.autoSync

    statusText:SetText(
        "Target Gold: " .. tostring(targetGold) .. "g\n" ..
        "Auto Sync: " .. (autoSync and "Enabled" or "Disabled")
    )

    targetBox:SetText(tostring(targetGold))
    autoButton:SetChecked(autoSync == true)
end

autoButton:SetScript("OnClick", function(self)
    FGS_DB = FGS_DB or {}
    FGS_DB.autoSync = self:GetChecked() == true
    Refresh()
end)

saveButton:SetScript("OnClick", function()
    FGS_DB = FGS_DB or {}

    local value = tonumber(targetBox:GetText())

    if not value or value < 0 then
        Print("Invalid target gold. Example: 50000")
        return
    end

    FGS_DB.targetGold = math.floor(value)
    Print("Target gold set to " .. tostring(FGS_DB.targetGold) .. "g")

    Refresh()
    targetBox:ClearFocus()
end)

targetBox:SetScript("OnEnterPressed", function()
    saveButton:Click()
end)

targetBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    Refresh()
end)

panel:SetScript("OnShow", Refresh)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

addon.optionsCategory = category