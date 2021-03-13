local GWTVersion, currentAchievementId, characterHasObtainedAchievement, GWT_Button

local GWT = CreateFrame("frame")
GWT:RegisterEvent("ADDON_LOADED")
GWT:RegisterEvent("PLAYER_LOGIN")
GWT:RegisterEvent("ACHIEVEMENT_EARNED")

GWT:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "GladiatorWinsTracker" then
	-- Set character saved variable if none
		if not GWT_HideButton then
			GWT_HideButton = "default"
		end
	-- Set account saved variable if none
		if not GWT_LoginIntro then
			GWT_LoginIntro = "true"
		end
	end

	-- Only setup the button once the parent frame has loaded
	if event == "ADDON_LOADED" and arg1 == "Blizzard_PVPUI" then
		setUpButton()
		updateButtonVisibility()
	end

	-- Setup variables
	if event == "PLAYER_LOGIN" then
		setGWTVersion()
		setCurrentPVPSeasonAchieveId()
		setCharacterHasObtainedAchievement()
		createOptions()
		if GWT_LoginIntro == "true" then
			print("|cff33ff99Gladiator Wins Tracker|r - use |cffFF4500 /gwt |r to open options")
		end
	end

	-- Check if button should hide after achievement obtained during session
	if event == "ACHIEVEMENT_EARNED" and arg1 == currentAchievementId then
		setCharacterHasObtainedAchievement()
		updateButtonVisibility()
	end
end)

function setUpButton()
	-- ConquestFrame is not nil as Blizzard_PVPUI has loaded
	GWT_Button = CreateFrame("Button", "GWTButton", ConquestFrame, "UIPanelButtonTemplate")
	GWT_Button:SetSize(200, 35)
	GWT_Button:SetText("Track Gladiator Wins")
	GWT_Button:SetPoint("BOTTOMRIGHT", 168, -34)

	GWT_Button:SetScript("OnClick", function()
		-- Check that theres a valid achievement ID and not already obtained
		if currentAchievementId ~= 0 and not characterHasObtainedAchievement then
			local trackedAchievements = { GetTrackedAchievements() }
			-- Handle no tracked achievements
			if trackedAchievements[1] == nil then
				RunScript("AddTrackedAchievement(" .. currentAchievementId .. ")")
			end
			-- Iterate over tracked achievements
			for i,v in ipairs(trackedAchievements) do
				if v == currentAchievementId then
					RunScript("RemoveTrackedAchievement(" .. currentAchievementId .. ")")
				-- dont add achieve if 10 tracked already
				elseif GetNumTrackedAchievements() < 10 then
					RunScript("AddTrackedAchievement(" .. currentAchievementId .. ")")
				end
			end
		end
	end)
end

function updateButtonVisibility()
	-- Check if button visibility has been overridden
	if GWT_HideButton == "default" then
		if characterHasObtainedAchievement then
			GWT_Button:Hide()
		else
			GWT_Button:Show()
		end
	elseif GWT_HideButton == "true" then
		GWT_Button:Hide()
	elseif GWT_HideButton == "false" then
		if characterHasObtainedAchievement then
			GWT_Button:Hide()
		else
			GWT_Button:Show()
		end
	end
end

function setGWTVersion()
	local version = GetAddOnMetadata("GladiatorWinsTracker", "Version")
	GWTVersion = version
end

function setCharacterHasObtainedAchievement()
	if currentAchievementId ~= 0 then
		local id, _, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(currentAchievementId)
		if completed and wasEarnedByMe then
			characterHasObtainedAchievement = true
		else 
			characterHasObtainedAchievement = false
		end
	end
end

function setCurrentPVPSeasonAchieveId()
	local currentPVPSeason = GetCurrentArenaSeason()
	if currentPVPSeason == 0 then currentAchievementId = 0 -- No active arena season
	elseif currentPVPSeason == 30 then currentAchievementId = 14689 -- Gladiator: Shadowlands Season 1
	elseif currentPVPSeason == 31 then currentAchievementId = 14689 -- Gladiator: Shadowlands Season 2 (when added to game files)
	elseif currentPVPSeason == 32 then currentAchievementId = 14689 -- Gladiator: Shadowlands Season 3 (when added to game files)
	else currentAchievementId = 0 end-- Default case for if addon very out of date
end

function setCharSavedVariable(state)
	if state == "hide" then
		GWT_HideButton = "true"
	elseif state == "show" then
		GWT_HideButton = "false"
	elseif state == "reset" then
		GWT_HideButton = "default"
	end
	if GWT_Button then
		updateButtonVisibility()
	end
end

function setAccountSavedVariable(state)
	if state == "hide" then
		GWT_LoginIntro = "false"
	elseif state == "show" then
		GWT_LoginIntro = "true"
	end
end

--------------------------------------------
-- OPTIONS PANEL
--------------------------------------------

local SimpleOptions = LibStub("LibSimpleOptions-1.01")

function createOptions()
	local panel = SimpleOptions.AddOptionsPanel("Gladiator Wins Tracker", function() end)
    SimpleOptions.AddSlashCommand("Gladiator Wins Tracker","/gwt")
	local title, subText = panel:MakeTitleTextAndSubText("Gladiator Wins Tracker", "")

	local characterSpecificSectionText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    characterSpecificSectionText:SetText("|cffffff00Character specific settings:|r")
    characterSpecificSectionText:SetJustifyH("LEFT")
    characterSpecificSectionText:SetSize(600, 40)
	characterSpecificSectionText:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -30)

	local hideButtonToggle = panel:MakeToggle(
	    'name', 'Always hide button on this character',
	    'description', 'Hide button in Rated PVP tab',
	    'default', false,
	    'getFunc', function()
			if GWT_HideButton == "true" then
				return true
			elseif GWT_HideButton == "false" or GWT_HideButton == "default" then
				return false
			end
		end,
	    'setFunc', function(value)
			if value == true then
				setCharSavedVariable("hide")
			elseif value == false then
				setCharSavedVariable("show")
			end
		end
	)
	hideButtonToggle:SetPoint("TOPLEFT", characterSpecificSectionText, "TOPLEFT", 40, -35)

	local noteText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    noteText:SetText("|cffffff00|r |cffffffff(Note: Button always hidden if character has obtained Gladiator this season)|r")
    noteText:SetJustifyH("LEFT")
    noteText:SetSize(600, 40)
    noteText:SetPoint("TOPLEFT", hideButtonToggle, "TOPLEFT", 0, -20)

	local resetButton = panel:MakeButton(
	    'name', 'Reset',
	    'description', 'Restore default settings',
	    'func', function()
			setCharSavedVariable("reset")
			panel:Refresh()
		end
	)
	resetButton:SetPoint("TOPLEFT", noteText, "TOPLEFT", 0, -40)

	local accountSectionText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    accountSectionText:SetText("|cffffff00Account settings:|r")
    accountSectionText:SetJustifyH("LEFT")
    accountSectionText:SetSize(600, 40)
	accountSectionText:SetPoint("TOPLEFT", resetButton, "TOPLEFT", -40, -30)

	local hideLoginIntro = panel:MakeToggle(
	    'name', 'Disable Intro',
	    'description', 'Disable intro text for all characters',
	    'default', false,
	    'getFunc', function()
			if GWT_LoginIntro == "true" then
				return false
			elseif GWT_LoginIntro == "false" then
				return true
			end
		end,
	    'setFunc', function(value)
			if value == true then
				setAccountSavedVariable("hide")
			elseif value == false then
				setAccountSavedVariable("show")
			end
		end
	)
    hideLoginIntro:SetPoint("TOPLEFT", accountSectionText, "TOPLEFT", 40, -35)

	local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    versionText:SetText("|cffffff00Version:|r |cffffffffv"..GWTVersion.."|r")
    versionText:SetJustifyH("RIGHT")
    versionText:SetSize(600, 40)
    versionText:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -5)

	local authorText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    authorText:SetText("|cffffff00Author:|r |cffffffffDezopri|r")
    authorText:SetJustifyH("RIGHT")
    authorText:SetSize(600, 40)
    authorText:SetPoint("TOPLEFT", versionText, "TOPLEFT", 0, -20)
end







































