local ArenaQueue = {}
ArenaQueue.frame = nil
ArenaQueue.tab = nil
ArenaQueue.tabID = nil

ArenaQueueSettings = ArenaQueueSettings or {
    arenaAnnouncements = true,
    bgAnnouncements = true,
}

function ArenaQueue:SetTab(id)
    PanelTemplates_SetTab(PVPParentFrame, id)
    PVPFrame:Hide()
    PVPBattlegroundFrame:Hide()
    if self.frame then self.frame:Hide() end

    if id == 1 then
        PVPFrame:Show()
    elseif id == 2 then
        PVPBattlegroundFrame:Show()
    elseif id == self.tabID then
        if self.frame then self.frame:Show() end
    end
end

function ArenaQueue:Initialize()
    if not PVPParentFrame then return end
    self:CreateArenaTab()
    self:CreateArenaFrame()
    self:HookTabClicks()
    self:SetTab(1)
end

function ArenaQueue:CreateArenaTab()
    PVPParentFrame.numTabs = (PVPParentFrame.numTabs or 2) + 1
    self.tabID = PVPParentFrame.numTabs
    local tabName = "PVPParentFrameTab" .. self.tabID
    local tab = CreateFrame("Button", tabName, PVPParentFrame, "CharacterFrameTabButtonTemplate")
    self.tab = tab
    tab:SetID(self.tabID)
    tab:SetText("Chromie")
    tab:SetWidth(90)
    tab:SetPoint("LEFT", _G["PVPParentFrameTab" .. (self.tabID - 1)], "RIGHT", -15, 0)
end

-- Detect if ElvUI or other UI replacements are active
function ArenaQueue:IsUIReplacement()
    -- Check for ElvUI/TukUI
    if ElvUI then return true end
    if TukUI then return true end
    -- Check if PortraitFrameTemplate actually exists
    local testFrame = pcall(CreateFrame, "Frame", "ArenaQueueTestFrame", UIParent, "PortraitFrameTemplate")
    if testFrame and _G["ArenaQueueTestFrame"] then
        _G["ArenaQueueTestFrame"]:Hide()
        _G["ArenaQueueTestFrame"] = nil
        return false
    end
    return true -- Assume UI replacement if template test failed
end

-- Create the frame content with automatic UI replacement detection.
function ArenaQueue:CreateArenaFrame()
    local frame
    local useBasicFrame = self:IsUIReplacement()
    if useBasicFrame then
        -- Fallback for ElvUI/UI replacements - create basic frame
        frame = CreateFrame("Frame", "ArenaQueueFrame", PVPParentFrame)
        -- Set basic properties
        frame:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", 14, -14)
        frame:SetSize(338, 422)
        frame:Hide()
        -- Create title manually
        local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleText:SetPoint("TOP", frame, "TOP", 0, -15)
        titleText:SetText("Chromiecraft PVP Tab")
        titleText:SetTextColor(1, 0.82, 0)
        -- Create portrait manually
        local portrait = frame:CreateTexture(nil, "ARTWORK")
        portrait:SetSize(60, 60)
        portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -10)
        portrait:SetTexture("Interface\\Icons\\inv_staff_99")
        self:Print("Using basic frame (UI replacement detected)")
    else
        -- Use the PortraitFrameTemplate when available
        frame = CreateFrame("Frame", "ArenaQueueFrame", PVPParentFrame, "PortraitFrameTemplate")
        frame:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", 14, -14)
        frame:SetSize(338, 422)
        frame:Hide()

        -- Hide the close button
        local closeButton = _G[frame:GetName() .. "CloseButton"]
        if closeButton then closeButton:Hide() end

        local portrait = _G[frame:GetName() .. "Portrait"]
        if portrait then
            -- Use SetPortraitToTexture for static icons in 3.3.5a
            SetPortraitToTexture(portrait, "Interface\\Icons\\inv_staff_99")
        end
        -- Set the title 
        local titleText = _G[frame:GetName() .. "TitleText"]
        if titleText then
            titleText:SetText("Chromiecraft PVP Tab")
        end
    end
    self.frame = frame
    self:CreateSettingsSection(frame)
    self:CreateSkirmishSection(frame)
    self:Create1v1Section(frame)
    self:Create3v3SoloSection(frame)
end

function ArenaQueue:CreateSettingsSection(parent)
    local yOffset = -70 -- Position for the first checkbox.

    -- Arena Announcer Checkbox
    local arenaCheck = CreateFrame("CheckButton", "ArenaQueueArenaAnnouncerCheck", parent, "UICheckButtonTemplate")
    arenaCheck:SetSize(24, 24)
    arenaCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    _G[arenaCheck:GetName() .. "Text"]:SetText("Arena System Announcements")
    -- Set the checkbox state from saved variables.
    arenaCheck:SetChecked(ArenaQueueSettings.arenaAnnouncements)

    arenaCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ArenaQueueSettings.arenaAnnouncements = true
            SendChatMessage(".settings announcer arena on", "SAY")
            else
            ArenaQueueSettings.arenaAnnouncements = false
            SendChatMessage(".settings announcer arena off", "SAY")
        end
    end)

    -- Battleground Announcer Checkbox
    local bgCheck = CreateFrame("CheckButton", "ArenaQueueBGAnnouncerCheck", parent, "UICheckButtonTemplate")
    bgCheck:SetSize(24, 24)
    bgCheck:SetPoint("TOPLEFT", arenaCheck, "BOTTOMLEFT", 0, -10) -- Anchor below the first checkbox
    _G[bgCheck:GetName() .. "Text"]:SetText("Battleground System Announcements")

    -- Set the checkbox state from saved variables.
    bgCheck:SetChecked(ArenaQueueSettings.bgAnnouncements)

    bgCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ArenaQueueSettings.bgAnnouncements = true
            SendChatMessage(".settings announcer bg on", "SAY")
            else
            ArenaQueueSettings.bgAnnouncements = false
            SendChatMessage(".settings announcer bg off", "SAY")
        end
    end)
end

function ArenaQueue:CreateSkirmishSection(parent)
    local yOffset = -140 -- Was -80
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    header:SetText("Skirmish")
    header:SetTextColor(1, 0.82, 0)
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    desc:SetText("Practice arena matches (no rating)")
    desc:SetTextColor(0.8, 0.8, 0.8)
    local button = CreateFrame("Button", "SkirmishQueueButton", parent, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    button:SetText("Join Skirmish (2v2)")
    button:SetScript("OnClick", function() ArenaQueue:QueueForArena("skirmish") end)
end

function ArenaQueue:Create1v1Section(parent)
    local yOffset = -220 -- Was -180
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    header:SetText("1v1 Arena")
    header:SetTextColor(1, 0.82, 0)
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    desc:SetText("1 versus 1 arena matches")
    desc:SetTextColor(0.8, 0.8, 0.8)
    local ratedButton = CreateFrame("Button", "Arena1v1RatedQueueButton", parent, "UIPanelButtonTemplate")
    ratedButton:SetSize(120, 22)
    ratedButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -15)
    ratedButton:SetText("1v1 Rated")
    ratedButton:SetScript("OnClick", function() ArenaQueue:QueueForArena("1v1rated") end)
    local unratedButton = CreateFrame("Button", "Arena1v1UnratedQueueButton", parent, "UIPanelButtonTemplate")
    unratedButton:SetSize(120, 22)
    unratedButton:SetPoint("LEFT", ratedButton, "RIGHT", 10, 0)
    unratedButton:SetText("1v1 Unrated")
    unratedButton:SetScript("OnClick", function() ArenaQueue:QueueForArena("1v1unrated") end)
end

function ArenaQueue:Create3v3SoloSection(parent)
    local yOffset = -320 -- Was -280
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    header:SetText("3v3 Solo Queue")
    header:SetTextColor(1, 0.82, 0)
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    desc:SetText("3v3 matches with random teammates")
    desc:SetTextColor(0.8, 0.8, 0.8)
    local roleInfo = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    roleInfo:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -5)
    roleInfo:SetTextColor(0.8, 0.8, 0.8)
    local ratedButton = CreateFrame("Button", "Arena3v3SoloRatedQueueButton", parent, "UIPanelButtonTemplate")
    ratedButton:SetSize(140, 22)
    ratedButton:SetPoint("TOPLEFT", roleInfo, "BOTTOMLEFT", 0, -15)
    ratedButton:SetText("3v3 Solo Rated")
    ratedButton:SetScript("OnClick", function() ArenaQueue:QueueForArena("3v3solorated") end)
    local unratedButton = CreateFrame("Button", "Arena3v3SoloUnratedQueueButton", parent, "UIPanelButtonTemplate")
    unratedButton:SetSize(140, 22)
    unratedButton:SetPoint("LEFT", ratedButton, "RIGHT", 10, 0)
    unratedButton:SetText("3v3 Solo Unrated")
    unratedButton:SetScript("OnClick", function() ArenaQueue:QueueForArena("3v3solounrated") end)
end

function ArenaQueue:HookTabClicks()
    PVPParentFrameTab1:SetScript("OnClick", function() self:SetTab(1) end)
    PVPParentFrameTab2:SetScript("OnClick", function() self:SetTab(2) end)
    self.tab:SetScript("OnClick", function() self:SetTab(self.tabID) end)
end

function ArenaQueue:QueueForArena(arenaType)
    if arenaType == "skirmish" then
        SendChatMessage(".lla queue", "SAY")
    elseif arenaType == "1v1rated" then
        SendChatMessage(".q1v1 rated", "SAY")
    elseif arenaType == "1v1unrated" then
        SendChatMessage(".q1v1 unrated", "SAY")
    elseif arenaType == "3v3solorated" then
        SendChatMessage(".qsolo rated", "SAY")
    elseif arenaType == "3v3solounrated" then
        SendChatMessage(".qsolo unrated", "SAY")
    end
end

function ArenaQueue:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ArenaQueue]|r " .. msg)
end

function ArenaQueue:ApplySavedSettings()
    if ArenaQueueSettings.arenaAnnouncements then
        SendChatMessage(".settings announcer arena on", "SAY")
    else
        SendChatMessage(".settings announcer arena off", "SAY")
    end

    if ArenaQueueSettings.bgAnnouncements then
        SendChatMessage(".settings announcer bg on", "SAY")
    else
        SendChatMessage(".settings announcer bg off", "SAY")
    end
end


PVPParentFrame_SetTab = function(frame, id)
    ArenaQueue:SetTab(id)
end

--[[SLASH_ARENAQUEUE1 = "/arenaqueue"
SLASH_ARENAQUEUE2 = "/aq"
SlashCmdList["ARENAQUEUE"] = function(msg)
    if msg == "show" then
        if not ArenaQueue.tabID then return end
        ShowUIPanel(PVPParentFrame)
        PVPParentFrame_SetTab(PVPParentFrame, ArenaQueue.tabID)
    elseif msg == "test" then
        ArenaQueue:Print("Arena Queue addon is working!")
    else
        ArenaQueue:Print("Commands: /aq show, /aq test")
    end
end]]

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    ArenaQueue:Initialize()
    ArenaQueue:ApplySavedSettings() -- Apply settings right after initialization.
    self:UnregisterEvent("PLAYER_LOGIN")
end)