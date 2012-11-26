
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")

local loottypes = {freeforall = "FFA", group = "Group", master = "ML", needbeforegreed = "NBG", roundrobin = "RR"}
local raidtypes = {ITEM_QUALITY_COLORS[4].hex.."10", ITEM_QUALITY_COLORS[4].hex.."25", ITEM_QUALITY_COLORS[5].hex.."10H", ITEM_QUALITY_COLORS[5].hex.."25H", ITEM_QUALITY_COLORS[4].hex.."RF"}
local dungeontypes = {ITEM_QUALITY_COLORS[2].hex.."5", ITEM_QUALITY_COLORS[3].hex.."5H", nil, nil, nil, nil, nil, ITEM_QUALITY_COLORS[4].hex.."5C"}
local icons = {
	tank = "|TInterface\\LFGFrame\\LFGRole.blp:0:0:0:0:64:16:32:47:1:16|t",
	heal = "|TInterface\\LFGFrame\\LFGRole.blp:0:0:0:0:64:16:48:63:1:16|t",
	dps  = "|TInterface\\LFGFrame\\LFGRole.blp:0:0:0:0:64:16:16:31:1:16|t",
	none = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady.blp:0|t"
}
local guildsuffix
local classcolors = {}
for i,v in pairs(RAID_CLASS_COLORS) do classcolors[i] = string.format("|cff%02x%02x%02x", v.r*255, v.g*255, v.b*255) end
local names = setmetatable({}, {__index = function(t, i)
	if not i then return i end
	local _, class = UnitClass(i)
	if not class then return i end
	local v = classcolors[class].. i
	t[i] = v
	return v
end})

local function GetGroupTypeText()
	local text = (ITEM_QUALITY_COLORS[0].hex.."Solo")
	if IsInRaid() then
		local diff = GetRaidDifficulty()
		if diff == 0 then
			text = ITEM_QUALITY_COLORS[1].hex.."40"..(guildsuffix or "").."|r - "
		else
			text = raidtypes[(GetRaidDifficulty() or 1)]..(guildsuffix or "").."|r - "
		end
	elseif IsInGroup() or IsInInstance() then
		local diff = GetDungeonDifficultyID() 
		if diff == 0 then
		else
			text = dungeontypes[GetDungeonDifficultyID()]..(guildsuffix or "").. "|r - "
		end
	end
	return text
end


local function GetLootTypeText()
	return GetNumGroupMembers() > 0 and (ITEM_QUALITY_COLORS[GetLootThreshold()].hex.. loottypes[GetLootMethod()]) or ""
end


local function GetText()
	for i = 1, NUM_LE_LFG_CATEGORYS do
		if GetLFGMode(i) == "queued" then
			local _, _, tank, healer, dps, _, instance, _, _, _, _, average, elapsed = GetLFGQueueStats(i)
			dps = dps or 3

			return "LFG ".. (tank == 0 and icons.tank or icons.none)
				..(healer == 0 and icons.heal or icons.none)
				..(dps    <= 2 and icons.dps  or icons.none)
				..(dps    <= 1 and icons.dps  or icons.none)
				..(dps    == 0 and icons.dps  or icons.none)
		else
			return GetGroupTypeText().. GetLootTypeText()
		end
	end
end


local dataobj = ldb:NewDataObject("picoGroup", {type = "data source", icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", text = GetText()})

local function Update()
	dataobj.text = GetText()
end

local function GuildGroupQuery()
	if IsInGuild() then
		RequestGuildPartyState()
	end
end

local function GuildGroupUpdate(event, isguild)
	if isguild then guildsuffix = "G" else guildsuffix = "" end
end

ae.RegisterEvent("picoGroup", "GROUP_ROSTER_UPDATE", Update)
ae.RegisterEvent("picoGroup", "PLAYER_GUILD_UPDATE", GuildGroupQuery)
ae.RegisterEvent("picoGroup", "GUILD_PARTY_STATE_UPDATED", GuildGroupUpdate)
ae.RegisterEvent("picoGroup", "PLAYER_DIFFICULTY_CHANGED", Update)
ae.RegisterEvent("picoGroup", "UPDATE_INSTANCE_INFO", Update)
ae.RegisterEvent("picoGroup", "PARTY_MEMBERS_CHANGED", Update)
ae.RegisterEvent("picoGroup", "PARTY_LEADER_CHANGED", Update)
ae.RegisterEvent("picoGroup", "PARTY_LOOT_METHOD_CHANGED", Update)
ae.RegisterEvent("picoGroup", "LFG_UPDATE", Update)
ae.RegisterEvent("picoGroup", "LFG_QUEUE_STATUS_UPDATE", Update)


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj.OnLeave() GameTooltip:Hide() end
function dataobj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("picoGroup")

	local queue = 0
	for i=1,NUM_LE_LFG_CATEGORYS do
		if GetLFGMode(i) == "queued" then
			queue = i
		end
	end

	if IsInRaid() then
		GameTooltip:AddDoubleLine(RAID_DIFFICULTY, _G["RAID_DIFFICULTY"..GetRaidDifficulty()], nil,nil,nil, 1,1,1)
	elseif GetNumGroupMembers() > 0 then
		GameTooltip:AddDoubleLine(DUNGEON_DIFFICULTY, _G["DUNGEON_DIFFICULTY"..GetDungeonDifficultyID()], nil,nil,nil, 1,1,1)
	elseif queue ~= 0 then
		GameTooltip:AddLine(LFG_TITLE, 0.75,1,0.75)
	else
		GameTooltip:AddLine(ERR_NOT_IN_GROUP, 1,1,1)
		GameTooltip:AddDoubleLine(DUNGEON_DIFFICULTY, _G["DUNGEON_DIFFICULTY"..GetDungeonDifficultyID()], nil,nil,nil, 1,1,1)
		GameTooltip:AddDoubleLine(RAID_DIFFICULTY, _G["RAID_DIFFICULTY"..GetRaidDifficulty()], nil,nil,nil, 1,1,1)
	end

	if queue ~= 0 then
		local _, _, _, _, _, _,_, _, _, _,  instance, _, _, _, _, mywait, elapsed = GetLFGQueueStats(queue)
		local average = average or 0
		mywait  = mywait  or 0

		if instance then GameTooltip:AddLine(instance, 1,1,1) end
		if mywait > 0 then GameTooltip:AddDoubleLine(AVERAGE_WAIT_TIME, SecondsToTime(mywait), nil,nil,nil, 1,1,1) end
		if elapsed then GameTooltip:AddDoubleLine(TIME_IN_QUEUE:gsub(": %%s", ""), SecondsToTime(GetTime() - elapsed), nil,nil,nil, 1,1,1) end
	end

	if GetNumGroupMembers() == 0 then return GameTooltip:Show() end

	if guildgroup then
		GameTooltip:AddLine("Guild Group")
	end

	GameTooltip:AddDoubleLine("Loot method", GetLootTypeText())

	local _, pML, rML = GetLootMethod()
	if pML or rML then GameTooltip:AddDoubleLine("Master looter", names[UnitName(rML and "raid"..rML or pML == 0 and "player" or "party"..pML)]) end

	if IsInRaid() then
		local officers

		for i=1,GetNumGroupMembers() do
			local name, rank, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(i)
			if rank == 1 then officers = true
			elseif rank == 2 then GameTooltip:AddDoubleLine("Leader", names[name]) end
		end

		if officers then
			for i=1,GetNumGroupMembers() do
				local name, rank = GetRaidRosterInfo(i)
				if rank == 1 then
					GameTooltip:AddDoubleLine(officers and "Officers" or " ", names[name])
					officers = false
				end
			end
		end
	elseif UnitInParty("player") then
		local leader = ""
		for i = 1, GetNumGroupMembers() do
			if UnitIsGroupLeader("party"..i) then
				leader = UnitName("party"..i)
				break
			end
		end
		GameTooltip:AddDoubleLine("Leader", names[leader])
	end

	GameTooltip:Show()
end


local dropdown, dropdowninit, menuitems
function dataobj:OnClick(button)
	if not dropdown then
		dropdown = CreateFrame("Frame", "picoGroupDownFrame", self, "UIDropDownMenuTemplate")

		local function sdd(self)
			SetDungeonDifficultyID(self.value)
			if GetNumGroupMembers() <= 5 then ConvertToParty() end
		end
		local function srd(self)
			SetRaidDifficulty(self.value)
			if not IsInRaid() then ConvertToRaid() end
		end
		local function slm(self) SetLootMethod(self.value, self.value == "master" and UnitName("player") or nil) end
		local function slt(self) SetLootThreshold(self.value) end
		local function gdd(i) return GetNumGroupMembers() == 0 and GetDungeonDifficultyID() == i end
		local function grd(i) return GetNumGroupMembers() > 0 and GetRaidDifficulty() == i end
		local function glm(i) return GetLootMethod() == i end
		local function glt(i) return GetLootThreshold() == i end
		menuitems = {
			{text = "Group Mode", isTitle = true, leaderonly = true},
			{text = DUNGEON_DIFFICULTY1, value = 1, func = sdd, checkedfunc = gdd, leaderonly = true},
			{text = DUNGEON_DIFFICULTY2, value = 2, func = sdd, checkedfunc = gdd, leaderonly = true},
			{text = CHALLENGE_MODE, value = 8, func = sdd, checkedfunc = gdd, leaderonly = true},
			{text = RAID_DIFFICULTY1, value = 1, func = srd, checkedfunc = grd, leaderonly = true},
			{text = RAID_DIFFICULTY2, value = 2, func = srd, checkedfunc = grd, leaderonly = true},
			{text = RAID_DIFFICULTY3, value = 3, func = srd, checkedfunc = grd, leaderonly = true},
			{text = RAID_DIFFICULTY4, value = 4, func = srd, checkedfunc = grd, leaderonly = true},

			{disabled = true, leaderonly = true},
			-- local loottypes = {freeforall = "FFA", group = "Group", master = "ML", needbeforegreed = "NBG", roundrobin = "RR"}
			{text = LOOT_METHOD, isTitle = true, leaderonly = true},
			{text = LOOT_FREE_FOR_ALL,      value = "freeforall",      func = slm, checkedfunc = glm, leaderonly = true},
			{text = LOOT_ROUND_ROBIN,       value = "roundrobin",      func = slm, checkedfunc = glm, leaderonly = true},
			{text = LOOT_MASTER_LOOTER,     value = "master",          func = slm, checkedfunc = glm, leaderonly = true},
			{text = LOOT_GROUP_LOOT,        value = "group",           func = slm, checkedfunc = glm, leaderonly = true},
			{text = LOOT_NEED_BEFORE_GREED, value = "needbeforegreed", func = slm, checkedfunc = glm, leaderonly = true},

			{disabled = true, leaderonly = true},
			{text = LOOT_THRESHOLD, isTitle = true, leaderonly = true},
			{text = ITEM_QUALITY_COLORS[2].hex..ITEM_QUALITY2_DESC, value = 2, func = slt, checkedfunc = glt, leaderonly = true},
			{text = ITEM_QUALITY_COLORS[3].hex..ITEM_QUALITY3_DESC, value = 3, func = slt, checkedfunc = glt, leaderonly = true},
			{text = ITEM_QUALITY_COLORS[4].hex..ITEM_QUALITY4_DESC, value = 4, func = slt, checkedfunc = glt, leaderonly = true},

			{disabled = true, leaderonly = true},
			{text = RESET_INSTANCES, func = function() StaticPopup_Show("CONFIRM_RESET_INSTANCES") end, leaderonly = true},
			{text = RESET_CHALLENGE_MODE, func = function() StaticPopup_Show("CONFIRM_RESET_CHALLENGE_MODE") end, leaderonly = true},
			{disabled = true, leaderonly = true},
			{text = OPT_OUT_LOOT_TITLE:gsub(":.+$", ""), func = function() SetOptOutOfLoot(not GetOptOutOfLoot()) end, checked = GetOptOutOfLoot},
			{disabled = true},
			{text = PARTY_LEAVE, func = LeaveParty},
		}
		function dropdowninit()
			local isleader = UnitIsGroupLeader("player") or UnitIsRaidOfficer("player")
			for i,v in ipairs(menuitems) do
				if not v.leaderonly or isleader then
					if v.checkedfunc then v.checked = v.checkedfunc(v.value) end
					UIDropDownMenu_AddButton(v, 1)
				end
			end
		end
	end

	GameTooltip:Hide()
	UIDropDownMenu_Initialize(dropdown, dropdowninit, "MENU")
	UIDropDownMenu_SetAnchor(dropdown, 0, 0, GetTipAnchor(self))

	if button == "MiddleButton" then
		if IsInInstance() then 
			LFGTeleport(true)
		else
			LFGTeleport()
		end
	else
		ToggleDropDownMenu(1, "picoGroupDownFrame", dropdown, "meh")
	end
end
