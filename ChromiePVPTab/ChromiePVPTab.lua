local ChromiePVPTab = {}
ChromiePVPTab.frame = nil
ChromiePVPTab.tab = nil
ChromiePVPTab.tabID = nil
ChromiePVPTab.progressBar = nil

ChromiePVPTabSettings = ChromiePVPTabSettings or {
    arenaAnnouncements = false,
    bgAnnouncements = false,
}

-- Honor title thresholds
local PvPTitles = {
    Rank_1 = 250,
    Rank_2 = 500,
    Rank_3 = 2500,
    Rank_4 = 5000,
    Rank_5 = 10000,
    Rank_6 = 20000,
    Rank_7 = 25000,
    Rank_8 = 30000,
    Rank_9 = 40000,
    Rank_10 = 50000,
    Rank_11 = 62500,
    Rank_12 = 75000,
    Rank_13 = 100000,
    Rank_14 = 125000
}

-- Rank names for display - Alliance and Horde
local RankNames = {
    Alliance = {
        [1] = "Private",
        [2] = "Corporal",
        [3] = "Sergeant",
        [4] = "Master Sergeant",
        [5] = "Sergeant Major",
        [6] = "Knight",
        [7] = "Knight-Lieutenant",
        [8] = "Knight-Captain",
        [9] = "Knight-Champion",
        [10] = "Lieutenant Commander",
        [11] = "Commander",
        [12] = "Marshal",
        [13] = "Field Marshal",
        [14] = "Grand Marshal"
    },
    Horde = {
        [1] = "Scout",
        [2] = "Grunt",
        [3] = "Sergeant",
        [4] = "Senior Sergeant",
        [5] = "First Sergeant",
        [6] = "Stone Guard",
        [7] = "Blood Guard",
        [8] = "Legionnaire",
        [9] = "Centurion",
        [10] = "Champion",
        [11] = "Lieutenant General",
        [12] = "General",
        [13] = "Warlord",
        [14] = "High Warlord"
    }
}

function ChromiePVPTab:SetTab(id)
    PanelTemplates_SetTab(PVPParentFrame, id)
    PVPFrame:Hide()
    PVPBattlegroundFrame:Hide()
    if self.frame then self.frame:Hide() end

    if id == 1 then
        PVPFrame:Show()
    elseif id == 2 then
        PVPBattlegroundFrame:Show()
    elseif id == self.tabID then
        if self.frame then 
            self.frame:Show()
            self:UpdateProgressBar()
        end
    end
end

function ChromiePVPTab:Initialize()
    if not PVPParentFrame then return end
    self:CreateArenaTab()
    self:CreateArenaFrame()
    self:HookTabClicks()
    self:SetTab(1)
end

function ChromiePVPTab:CreateArenaTab()
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

-- Detect if ElvUI is running
function ChromiePVPTab:IsUIReplacement()
    if ElvUI then return true end
    if TukUI then return true end
    -- Check if PortraitFrameTemplate actually exists
    local success, testFrame = pcall(CreateFrame, "Frame", "ChromiePVPTabTestFrame", UIParent, "PortraitFrameTemplate")
    if success and testFrame then
        testFrame:Hide()
        testFrame = nil  -- or testFrame:SetParent(nil) for proper cleanup
        return false
    end
    return true -- Assume UI replacement if template test failed
end

function ChromiePVPTab:CreateProgressBar(parent)
    local progressBG = CreateFrame("Frame", "ChromiePVPTabProgressBG", parent)
    progressBG:SetSize(280, 35)
    progressBG:SetPoint("TOP", parent, "TOP", 0, -60)
    progressBG:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    progressBG:SetBackdropColor(0, 0, 0, 0.8)
    progressBG:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    -- Progress bar fill
    local progressBar = CreateFrame("StatusBar", "ChromiePVPTabProgressBar", progressBG)
    progressBar:SetSize(272, 27)
    progressBar:SetPoint("CENTER", progressBG, "CENTER", 0, 0)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(1, 0.7, 0, 1) -- Gold color
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    -- Progress text
    local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)
    progressText:SetTextColor(1, 1, 1, 1)
    -- Current rank text
    local rankText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rankText:SetPoint("BOTTOM", progressBG, "TOP", 0, 2)
    rankText:SetTextColor(1, 0.82, 0, 1)
    self.progressBar = {
        bg = progressBG,
        bar = progressBar,
        text = progressText,
        rankText = rankText
    }
    self:UpdateProgressBar()
end

function ChromiePVPTab:GetCurrentRankInfo()
    local kills = GetStatistic(588) -- Honorable kills statistic ID
    local numKills = tonumber(kills) or 0
    local currentRank = 0
    local nextRank = 1
    local currentThreshold = 0
    local nextThreshold = PvPTitles.Rank_1
    -- Find current rank
    for rank = 1, 14 do
        local threshold = PvPTitles["Rank_" .. rank]
        if numKills >= threshold then
            currentRank = rank
            currentThreshold = threshold
            if rank < 14 then
                nextRank = rank + 1
                nextThreshold = PvPTitles["Rank_" .. nextRank]
            else
                nextRank = 14
                nextThreshold = threshold
            end
        else
            break
        end
    end
    return numKills, currentRank, nextRank, currentThreshold, nextThreshold
end

function ChromiePVPTab:UpdateProgressBar()
    if not self.progressBar then return end
    local kills, currentRank, nextRank, currentThreshold, nextThreshold = self:GetCurrentRankInfo()
    -- Get player faction
    local faction, _ = UnitFactionGroup("player")
    local factionRanks = RankNames[faction] or RankNames.Alliance -- Fallback to Alliance if faction not found
    -- Update rank text
    if currentRank == 0 then
        self.progressBar.rankText:SetText("No Rank")
    elseif currentRank == 14 then
        self.progressBar.rankText:SetText("Rank " .. currentRank .. ": " .. factionRanks[currentRank] .. " (Max Rank)")
    else
        self.progressBar.rankText:SetText("Rank " .. currentRank .. ": " .. factionRanks[currentRank])
    end
    -- Update progress bar
    if currentRank == 14 then
        -- Max rank reached
        self.progressBar.bar:SetValue(100)
        self.progressBar.text:SetText(kills .. " / " .. nextThreshold .. " HKs (MAX)")
    else
        -- Calculate progress to next rank
        local progress = 0
        if nextThreshold > currentThreshold then
            progress = ((kills - currentThreshold) / (nextThreshold - currentThreshold)) * 100
        end
        self.progressBar.bar:SetValue(progress)
        self.progressBar.text:SetText(kills .. " / " .. nextThreshold .. " HKs (" .. math.floor(progress) .. "%)")
    end
end

function ChromiePVPTab:CreateArenaFrame()
    local frame
    local useBasicFrame = self:IsUIReplacement()
    if useBasicFrame then
        -- Fallback for ElvUI/UI replacements - create basic frame
        frame = CreateFrame("Frame", "ChromiePVPTabFrame", PVPParentFrame)
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
        frame = CreateFrame("Frame", "ChromiePVPTabFrame", PVPParentFrame, "PortraitFrameTemplate")
        frame:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", 14, -14)
        frame:SetSize(338, 422)
        frame:Hide()
        local closeButton = _G[frame:GetName() .. "CloseButton"]
        if closeButton then closeButton:Hide() end
        local portrait = _G[frame:GetName() .. "Portrait"]
        if portrait then
            SetPortraitToTexture(portrait, "Interface\\Icons\\inv_staff_99")
        end
        local titleText = _G[frame:GetName() .. "TitleText"]
        if titleText then
            titleText:SetText("Chromiecraft PVP Tab")
        end
    end
    self.frame = frame
    self:CreateProgressBar(frame)
    self:CreateSettingsSection(frame)
    self:CreateSkirmishSection(frame)
    self:Create1v1Section(frame)
    self:Create3v3SoloSection(frame)
end

function ChromiePVPTab:CreateSettingsSection(parent)
    local yOffset = -100 -- Moved down to make room for progress bar

    -- Arena Announcer Checkbox
    local arenaCheck = CreateFrame("CheckButton", "ChromiePVPTabArenaAnnouncerCheck", parent, "UICheckButtonTemplate")
    arenaCheck:SetSize(24, 24)
    arenaCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    _G[arenaCheck:GetName() .. "Text"]:SetText("Arena System Announcements")
    -- Set the checkbox state from saved variables.
    arenaCheck:SetChecked(ChromiePVPTabSettings.arenaAnnouncements)

    arenaCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ChromiePVPTabSettings.arenaAnnouncements = true
            SendChatMessage(".settings announcer arena on", "SAY")
            else
            ChromiePVPTabSettings.arenaAnnouncements = false
            SendChatMessage(".settings announcer arena off", "SAY")
        end
    end)

    -- Battleground Announcer Checkbox
    local bgCheck = CreateFrame("CheckButton", "ChromiePVPTabBGAnnouncerCheck", parent, "UICheckButtonTemplate")
    bgCheck:SetSize(24, 24)
    bgCheck:SetPoint("TOPLEFT", arenaCheck, "BOTTOMLEFT", 0, -10) -- Anchor below the first checkbox
    _G[bgCheck:GetName() .. "Text"]:SetText("Battleground System Announcements")

    -- Set the checkbox state from saved variables.
    bgCheck:SetChecked(ChromiePVPTabSettings.bgAnnouncements)

    bgCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ChromiePVPTabSettings.bgAnnouncements = true
            SendChatMessage(".settings announcer bg on", "SAY")
            else
            ChromiePVPTabSettings.bgAnnouncements = false
            SendChatMessage(".settings announcer bg off", "SAY")
        end
    end)
end

function ChromiePVPTab:CreateSkirmishSection(parent)
    local yOffset = -170 -- Adjusted for progress bar
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    header:SetText("Skirmish")
    header:SetTextColor(1, 0.82, 0)
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    desc:SetText("Unrated arena matches")
    desc:SetTextColor(0.8, 0.8, 0.8)
    local button = CreateFrame("Button", "SkirmishQueueButton", parent, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    button:SetText("Join Skirmish (2v2)")
    button:SetScript("OnClick", function() ChromiePVPTab:QueueForArena("skirmish") end)
    self:CreateCrossfactionSection(parent, yOffset)
end

function ChromiePVPTab:Create1v1Section(parent)
    local yOffset = -250
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
    ratedButton:SetScript("OnClick", function() ChromiePVPTab:QueueForArena("1v1rated") end)
    local unratedButton = CreateFrame("Button", "Arena1v1UnratedQueueButton", parent, "UIPanelButtonTemplate")
    unratedButton:SetSize(120, 22)
    unratedButton:SetPoint("LEFT", ratedButton, "RIGHT", 10, 0)
    unratedButton:SetText("1v1 Unrated")
    unratedButton:SetScript("OnClick", function() ChromiePVPTab:QueueForArena("1v1unrated") end)
end

function ChromiePVPTab:CreateCrossfactionSection(parent, yOffset)
    local raceHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    raceHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 180, yOffset)
    raceHeader:SetText("Crossfaction BG Race")
    raceHeader:SetTextColor(1, 0.82, 0)

    local raceDropdown = CreateFrame("Frame", "ChromiePVPTabRaceDropdown", parent, "UIDropDownMenuTemplate")
    raceDropdown:SetPoint("TOPLEFT", raceHeader, "BOTTOMLEFT", -20, -22)
    UIDropDownMenu_SetWidth(raceDropdown, 120)
    -- Function to get available races based on player's class, race, and gender
    local function GetAvailableRaces()
        local playerClass = select(2, UnitClass("player"))
        local playerGender = UnitSex("player")
        local isFemale = (playerGender == 3) -- 2 = Male, 3 = Female
        -- Data for race change options from from: https://github.com/azerothcore/mod-cfbg/
        local classRaceMapping = {
            ["WARRIOR"] = {
                alliance = {"human", "dwarf", "gnome", "draenei"},
                horde = {"orc", "tauren", "troll"}
            },
            ["PALADIN"] = {
                alliance = {"human", "dwarf", "draenei"},
                horde = {"bloodelf"}
            },
            ["HUNTER"] = {
                alliance = {"dwarf", "draenei"},
                horde = {"orc", "tauren", "troll", "bloodelf"}
            },
            ["ROGUE"] = {
                alliance = {"human", "dwarf", "gnome"},
                horde = {"orc", "troll", "bloodelf"}
            },
            ["PRIEST"] = {
                alliance = {"human", "dwarf", "draenei"},
                horde = {"troll", "bloodelf"}
            },
            ["DEATHKNIGHT"] = {
                alliance = {"human", "dwarf", "gnome", "draenei"},
                horde = {"orc", "tauren", "troll", "bloodelf"}
            },
            ["SHAMAN"] = {
                alliance = {"draenei"},
                horde = {"orc", "tauren", "troll"}
            },
            ["MAGE"] = {
                alliance = {"human", "gnome"},
                horde = {"bloodelf", "troll"}
            },
            ["WARLOCK"] = {
                alliance = {"human", "gnome"},
                horde = {"orc", "bloodelf"}
            },
            ["DRUID"] = {
                alliance = {"human"},
                horde = {"tauren"}
            }
        }
        local faction, _ = UnitFactionGroup("player")
        local isAlliance = (faction == "Alliance")
        -- Races that don't have female models
        local noFemaleModels = {
            ["troll"] = true,
            ["dwarf"] = true
        }

        -- Get available crossfaction races
        local availableRaces = {}
        if classRaceMapping[playerClass] then
            local targetFaction = isAlliance and "horde" or "alliance"
            local baseRaces = classRaceMapping[playerClass][targetFaction]
            if baseRaces then
                -- Filter out races that don't support the player's gender
                for _, race in ipairs(baseRaces) do
                    if not isFemale or not noFemaleModels[race] then
                        table.insert(availableRaces, race)
                    end
                end
            end
        end

        return availableRaces
    end

    -- Display of names in the dropdownmenu. Night Elfes and Undeads are missing from the module
    local raceDisplayNames = {
        ["human"]       =   "Human",
        ["dwarf"]       =   "Dwarf",
        ["gnome"]       =   "Gnome",
        ["draenei"]     =   "Draenei",
        ["orc"]         =    "Orc",
        ["bloodelf"]    =   "Blood Elf",
        ["troll"]       =   "Troll",
        ["tauren"]      =   "Tauren",
    }

    UIDropDownMenu_Initialize(raceDropdown, function(self, level)
        local availableRaces = GetAvailableRaces()
        if #availableRaces == 0 then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "No crossfaction races available"
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
        else
            for i, raceKey in ipairs(availableRaces) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = raceDisplayNames[raceKey]
                info.value = raceKey
                info.func = function()
                    ChromiePVPTabSettings.cfbgRace = raceKey
                    UIDropDownMenu_SetSelectedValue(raceDropdown, raceKey)
                    SendChatMessage(".cfbg race " .. raceKey, "SAY")
                    ChromiePVPTab:Print("race set to : " .. raceDisplayNames[raceKey] .. " (%s is a serverside visual bug)")
                end
                info.checked = (ChromiePVPTabSettings.cfbgRace == raceKey)
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    -- Set default value if not set or invalid
    local availableRaces = GetAvailableRaces()
    if not ChromiePVPTabSettings.cfbgRace or not tContains(availableRaces, ChromiePVPTabSettings.cfbgRace) then
        if #availableRaces > 0 then
            ChromiePVPTabSettings.cfbgRace = availableRaces[1]
        end
    end
    if ChromiePVPTabSettings.cfbgRace then
        UIDropDownMenu_SetSelectedValue(raceDropdown, ChromiePVPTabSettings.cfbgRace)
    end
end

function ChromiePVPTab:Create3v3SoloSection(parent)
    local yOffset = -320 -- Adjusted to move higher
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
    ratedButton:SetScript("OnClick", function() ChromiePVPTab:QueueForArena("3v3solorated") end)
    local unratedButton = CreateFrame("Button", "Arena3v3SoloUnratedQueueButton", parent, "UIPanelButtonTemplate")
    unratedButton:SetSize(140, 22)
    unratedButton:SetPoint("LEFT", ratedButton, "RIGHT", 10, 0)
    unratedButton:SetText("3v3 Solo Unrated")
    unratedButton:SetScript("OnClick", function() ChromiePVPTab:QueueForArena("3v3solounrated") end)
end

function ChromiePVPTab:HookTabClicks()
    PVPParentFrameTab1:SetScript("OnClick", function() self:SetTab(1) end)
    PVPParentFrameTab2:SetScript("OnClick", function() self:SetTab(2) end)
    self.tab:SetScript("OnClick", function() self:SetTab(self.tabID) end)
end

function ChromiePVPTab:QueueForArena(arenaType)
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

function ChromiePVPTab:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ChromiePVPTab]|r " .. msg)
end

function ChromiePVPTab:ApplySavedSettings()
    if ChromiePVPTabSettings.arenaAnnouncements then
        SendChatMessage(".settings announcer arena on", "SAY")
    else
        SendChatMessage(".settings announcer arena off", "SAY")
    end

    if ChromiePVPTabSettings.bgAnnouncements then
        SendChatMessage(".settings announcer bg on", "SAY")
    else
        SendChatMessage(".settings announcer bg off", "SAY")
    end

    if ChromiePVPTabSettings.cfbgRace then
        SendChatMessage(".cfbg race " .. ChromiePVPTabSettings.cfbgRace, "SAY")
    end
end


PVPParentFrame_SetTab = function(frame, id)
    ChromiePVPTab:SetTab(id)
end

--[[SLASH_CHROMIEPVPTAB1 = "/chromiepvptab" --For Debugging
SLASH_CHROMIEPVPTAB2 = "/cpt"
SlashCmdList["CHROMIEPVPTAB"] = function(msg)
    if msg == "show" then
        if not ChromiePVPTab.tabID then return end
        ShowUIPanel(PVPParentFrame)
        PVPParentFrame_SetTab(PVPParentFrame, ChromiePVPTab.tabID)
    elseif msg == "test" then
        ChromiePVPTab:Print("ChromiePVP Tab addon is working!")
    else
        ChromiePVPTab:Print("Commands: /cpt show, /cpt test")
    end
end]]

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") -- For potential updates
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ChromiePVPTab:Initialize()
        ChromiePVPTab:ApplySavedSettings() -- Apply settings right after initialization.
    elseif event == "UPDATE_MOUSEOVER_UNIT" and ChromiePVPTab.progressBar then
        -- Update progress bar occasionally(might want to use a different event) 
        ChromiePVPTab:UpdateProgressBar()
    end
end)