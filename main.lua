-- WoW Rambler Project - Quest History Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local AddonName = ...
local Version, Build = GetBuildInfo()

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}

local function ArrayDifference(minuend, subtrahend)
	local tempArray = {}

	for k, v in pairs(minuend) do
		tempArray[v] = true
	end

	for k, v in pairs(subtrahend) do
		tempArray[v] = nil
	end

	local difference = {}
	local n = 0

	for k, v in pairs(minuend) do
		if tempArray[v] then
			n = n + 1
			difference[n] = v
		end
	end

	return difference
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
		WoWRamblerProjectQuestMap = WoWRamblerProjectQuestMap or {}
		WoWRamblerProjectQuestsDone = WoWRamblerProjectQuestsDone or {}
	end
end

function mainFrame:AddLogEntry(event, questId)
	local y, x, z, instanceId = UnitPosition("player") -- First returned value is really the 'y' coordinate.
	local mapX, mapY
	local uiMapID = C_Map.GetBestMapForUnit("player")

	if uiMapID then
		local position = C_Map.GetPlayerMapPosition(uiMapID, "player")
		if position then
			mapX, mapY = position:GetXY()
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
	local diff = ArrayDifference(serverQuests, WoWRamblerProjectQuestsDone)

	if next(diff) ~= nil then
		WoWRamblerProjectQuestMap[questId] = {}
		for k, v in pairs(diff) do
			-- Usually GetAllCompletedQuestIDs() does not return just completed quests. Usually...
			if questId ~= v then
				table.insert(WoWRamblerProjectQuestMap[questId], v)
			end
		end
	end

	WoWRamblerProjectQuestsDone = serverQuests
	table.insert(WoWRamblerProjectQuestsDone, questId)

	self:AddLogEntry("QUEST_TURNED_IN", questId)
end

mainFrame:SetupEvents()
