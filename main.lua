-- WoW Rambler Project - Quest History Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local AddonName = ...

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}

local Version, Build = GetBuildInfo()

local function ArrayUniqueDifference(minuend, subtrahend)
	local tempArray = {}

	for k, v in pairs(minuend) do
		tempArray[v] = true
	end

	for k, v in pairs(subtrahend) do
		tempArray[v] = false
	end

	local difference = {}
	local n = 0

	for k, v in pairs(tempArray) do
		if v then
			n = n + 1
			difference[n] = k
		end
	end

	return difference, n
end

function mainFrame:SetupEvents()
	self:SetScript("OnEvent", function(self, event, ...)
		self.events[event](self, ...)
	end)

	for k, v in pairs(self.events) do
		self:RegisterEvent(k)
	end
end

function mainFrame.events:ADDON_LOADED(addonName)
	if addonName == AddonName then
		WoWRamblerProjectQuestLog = WoWRamblerProjectQuestLog or {}
		WoWRamblerProjectHiddenQuests = WoWRamblerProjectHiddenQuests or {}
		WoWRamblerProjectQuestsDone = WoWRamblerProjectQuestsDone or {}
	end
end

function mainFrame:AddLogEntry(event, questId)
	local y, x, z, instanceId = UnitPosition("player") -- First returned value really is the 'y' coordinate.
	local mapX, mapY
	local uiMapID = C_Map.GetBestMapForUnit("player")

	if uiMapID then
		local position = C_Map.GetPlayerMapPosition(uiMapID, "player")
		if position then
			mapX = position.x
			mapY = position.y
		end
	end

	WoWRamblerProjectQuestLog[questId] = WoWRamblerProjectQuestLog[questId] or {}
	WoWRamblerProjectQuestLog[questId][GetServerTime()] = {
		["event"] = event or "nil",
		["title"] = C_QuestLog.GetTitleForQuestID(questId) or "nil",
		["datetime"] = string.format("%s @ %s (%s)", date(), Version, Build),
		["instance id"] = instanceId or "nil",
		["instance x"] = x or "nil",
		["instance y"] = y or "nil",	
		["map id"] = uiMapID or "nil",
		["map x"] = mapX or "nil",
		["map y"] = mapY or "nil",
		["zone"] = GetRealZoneText() or "nil",
		["subzone"] = GetSubZoneText() or "nil",
		["target"] = UnitName("target") or "nil",
		["target GUID"] = UnitGUID("target") or "nil"
	}
end

function mainFrame.events:QUEST_ACCEPTED(questId)
	self:AddLogEntry("QUEST_ACCEPTED", questId)
end

function mainFrame.events:QUEST_TURNED_IN(questId)
	local serverQuests = C_QuestLog.GetAllCompletedQuestIDs()
	
	-- Make sure serverQuests contains the just completed quest.
	table.insert(serverQuests, questId)

	local diff, count = ArrayUniqueDifference(serverQuests, WoWRamblerProjectQuestsDone)
	WoWRamblerProjectQuestsDone = serverQuests

	if count > 1 then
		-- Okay, there is at least one additional (hidden) quest completed.
		WoWRamblerProjectHiddenQuests[questId] = {}
	
		for k, v in pairs(diff) do
			if questId ~= v then
				table.insert(WoWRamblerProjectHiddenQuests[questId], v)
			end
		end
	end

	self:AddLogEntry("QUEST_TURNED_IN", questId)
end

mainFrame:SetupEvents()
