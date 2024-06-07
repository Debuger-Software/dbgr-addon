---@diagnostic disable: inject-field, deprecated, undefined-global, param-type-mismatch

local ADDON_NAME = "DBGR"
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
local ADDON_REL_TYPE = GetAddOnMetadata(ADDON_NAME, "X-Release")
local LOGO = function(size) return string.format("|TInterface\\AddOns\\DBGR\\img\\d:%d|t", size) end
local TIME_REQ = false

function AddLootIcons(self, event, msg, ...)
	local _, fontSize = GetChatWindowInfo(self:GetID())
	local 	function iconForLink(link)	return string.format(" %s \124T%s:%s\124t  ",link,GetItemIcon(link),DBGROPT.icon_size);	end
	msg = string.gsub(msg,"(\124c%x+\124Hitem:.-\124h\124r)",iconForLink)
	msg = msg:gsub("You receive loot: ","Loot:")
	msg = msg:gsub("You receive item: ","Loot:")
	msg = msg:gsub("You create: ","Make:")
	return false, msg:sub(1,-2), ...
end

local function showAlertOnScreen(text,r,g,b,t,f,top)
	local	msg = CreateFrame("MessageFrame", "DBGRalert", UIParent)
			msg:SetWidth(1000);
			msg:SetHeight(500);
			msg:SetPoint("TOP", 0, -200);
			msg:SetPoint("CENTER", 0, top);
			msg:SetInsertMode("TOP")
			msg:SetFrameStrata("HIGH")
			msg:SetTimeVisible(t)
			msg:SetFadeDuration(f)
			msg:SetScale(1.2)
			msg:SetFont(STANDARD_TEXT_FONT, 25, "THICK_OUTLINE")
			msg:AddMessage(text, r, g, b)
end

local function create_MsgBox()
	local	MsgBox = CreateFrame("Frame","DBGR_msgbox",UIParent, "GlowBoxTemplate")
			MsgBox:SetFrameStrata("BACKGROUND")
			MsgBox:SetSize(300, 100)
			MsgBox:SetPoint("CENTER",0,0)
			MsgBox.opener = nil
			MsgBox.header = MsgBox:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
			MsgBox.header:SetPoint("TOP",0,-7)
			MsgBox.header:SetTextScale(1.1)
			MsgBox.header:SetText(string.format("%s               %s %s (%s)               %s",LOGO(16),ADDON_NAME,ADDON_VERSION,ADDON_REL_TYPE,LOGO(16)))
			MsgBox.text = MsgBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			MsgBox.text:SetPoint("CENTER",0,0)
			MsgBox.text:SetTextScale(1.0)
			MsgBox.text:SetText("")
			MsgBox.btn = CreateFrame("Button","DBGR_msgbox_btn",MsgBox,"UIPanelButtonTemplate");
			MsgBox.btn:RegisterForClicks("AnyUp");
			MsgBox.btn:SetSize(50,20);
			MsgBox.btn:SetPoint("BOTTOM",0,6)
			MsgBox.btn:SetNormalFontObject("GameFontNormalSmall");
			MsgBox.btn:SetHighlightFontObject("GameFontHighlightSmall");
			MsgBox.btn:SetDisabledFontObject("GameFontDisableSmall");
			MsgBox.btn:SetText("OK");
			MsgBox.btn:SetScript("OnClick", function() MsgBox:Hide(); MsgBox.opener = nil; end )
			MsgBox.btn:Show()
			MsgBox:EnableMouse(true)
			MsgBox:SetResizable(true)
			MsgBox:SetMovable(true)
			MsgBox:RegisterForDrag("LeftButton")
			MsgBox:SetScript("OnDragStart", function(self)	self:StartMoving();	end)
			MsgBox:SetScript("OnDragStop", function(self)	self:StopMovingOrSizing();	end)	
			MsgBox:Hide()
			MsgBox.showMsgBox = function (self,text,title)
				if title and title ~= "" then self.header:SetText(tostring(title)) end
				if text and text ~= "" then self.text:SetText(tostring(text)) end
				if DBGROPT.sound ~= 0 then PlaySoundFile("Interface\\AddOns\\DBGR\\snd\\msg.wav"); end
				self:Show()
			end
	return 	MsgBox
end

local function SecondsToTime(time)
	local days = floor(time/86400)
	local hours = floor(mod(time, 86400)/3600)
	local minutes = floor(mod(time,3600)/60)
	local seconds = floor(mod(time,60))
	return format("%dd, %02dh  %02dm  %02ds",days,hours,minutes,seconds)
end

local function eventHandler(self, event, ...)
	if     event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == ADDON_NAME then
			if DBGROPT == nil then DBGROPT = {sound=true ,icon_size=24}; end												-- defaulting non existing options
		end
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local text, _ = ...
		local xpgained = text:match("(%d+)")
		local xp = UnitXP("player")
		local maxXp=UnitXPMax("player")
		local percent = tonumber(format("%.1f", (xpgained/maxXp)*100))
		local percent_total = tonumber(format("%.1f", (xp/maxXp)*100) + percent)
		print(string.format("\r\nEXP:|cFFFFEE00 +%d|r|cFFEE0000 (-%.1fx)|r       |cFF22FF15 +%.1f%%|r        TOTAL:|cFF00FFFF %.1f%%|r \r\n", xpgained, (100 - percent_total)/percent, percent, percent_total))
		showAlertOnScreen(string.format("+%.1f%%",percent),0,255,0,3,1,50)
	elseif event == "PLAYER_LEVEL_UP" then
		local talentGroup = GetActiveTalentGroup(false, false)
		local free_talent = tonumber(GetUnspentTalentPoints(false, false, talentGroup))
		if free_talent > 0 then	MsgBox:showMsgBox(string.format("You have free %d unspent talent points!",free_talent)) end
	elseif event == "TIME_PLAYED_MSG" then
		if TIME_REQ then
			local timeTotal, timeCurLvl = ...
			MsgBox:showMsgBox(string.format("Total:  %s\nLevel:  %s",SecondsToTime(timeTotal),SecondsToTime(timeCurLvl)),"Play time statistics")
			TIME_REQ = false
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local text, _ = ...
		if text:find("buyer") then
			local extracted = text:match("auction of (.*).")
			if MsgBox:IsShown() and MsgBox.opener == "AH_SELL" then
				MsgBox:showMsgBox(string.format("%s, %s",MsgBox.text:GetText(), extracted), "Auction House")
			else
				MsgBox:showMsgBox(string.format("AH item sell: %s", extracted), "Auction House")
			end
			MsgBox.opener = "AH_SELL"
		end
		if text:find("outbid") then
			local outbid_item = text:match("outbid on (.*).")
			if MsgBox:IsShown() and MsgBox.opener == "AH_OUTBID" then
				MsgBox:showMsgBox(string.format("%s, %s",MsgBox.text:GetText(), outbid_item), "Auction House")
			else
				MsgBox:showMsgBox(string.format("OUTBID: %s", outbid_item), "Auction House")
			end
				MsgBox.opener = "AH_OUTBID"
		end
	end
end
-- ===================================================================================================================================================================================================

local	frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
		frame:RegisterEvent("PLAYER_LEVEL_UP")
		frame:RegisterEvent("CHAT_MSG_SYSTEM")
		frame:RegisterEvent("TIME_PLAYED_MSG")
		frame:SetScript("OnEvent", eventHandler)
MsgBox = create_MsgBox()

ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", AddLootIcons);
ChatFrame1EditBox:SetAltArrowKeyMode(false);

SLASH_DBFRAME1 = "/dbgr"
function SlashCmdList.DBFRAME(msg, editbox)
	if msg == "" then	MsgBox:showMsgBox();	end																			-- show last message in frame
	if msg == "playtime" then TIME_REQ = true; RequestTimePlayed(); end														-- show total & current lvl play time
	if msg == "get" then for k, v in pairs(DBGROPT) do print(k.." : "..tostring(v));	end; end							-- show current saved variables
	if msg:match("set (.*) ") then DBGROPT[msg:match("set (.*) \".*\"")] = msg:match("set .* \"(.*)\"") end 				-- set string variable 	"TEXT"
	if msg:match("setnum (.*) ") then DBGROPT[msg:match("setnum (.*) .*")] = tonumber(msg:match("setnum .* ([0-9]+)")); end	-- set numeric variable	123
end