-- WoW Rambler Project - Quest History Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local AddonName = ...

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}

local Version, Build = GetBuildInfo()

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
		WoWRamblerProjectQuestSnapshots = WoWRamblerProjectQuestSnapshots or {}
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
		["event"] = event or nil,
		["title"] = C_QuestLog.GetTitleForQuestID(questId) or nil,
		["datetime"] = string.format("%s @ %s (%s)", date(), Version, Build),
		["instance id"] = instanceId or nil,
		["instance x"] = x or nil,
		["instance y"] = y or nil,	
		["map id"] = uiMapID or nil,
		["map x"] = mapX or nil,
		["map y"] = mapY or nil,
		["zone"] = GetRealZoneText() or nil,
		["subzone"] = GetSubZoneText() or nil,
		["target"] = UnitName("target") or nil,
		["target GUID"] = UnitGUID("target") or nil
	}
end

function mainFrame.events:QUEST_ACCEPTED(questId)
	self:AddLogEntry("QUEST_ACCEPTED", questId)
end

function mainFrame.events:QUEST_TURNED_IN(questId)
	WoWRamblerProjectQuestSnapshots[questId] = WoWRamblerProjectQuestSnapshots[questId] or {}
	WoWRamblerProjectQuestSnapshots[questId][GetServerTime()] = C_QuestLog.GetAllCompletedQuestIDs()

	self:AddLogEntry("QUEST_TURNED_IN", questId)
end

mainFrame:SetupEvents()
