---@diagnostic disable: inject-field, deprecated, undefined-global, param-type-mismatch

local ADDON_NAME = "DBGR"
local ADDON_VERSION = format("%s rev.%s",GetAddOnMetadata(ADDON_NAME, "Version"),GetAddOnMetadata(ADDON_NAME, "X-Revision"))
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
			MsgBox.header:SetTextScale(1.2)
			MsgBox.header:SetText(string.format("%1$s        %s %s (%s)        %1$s",LOGO(16):rep(5),ADDON_NAME,ADDON_VERSION,ADDON_REL_TYPE))
			MsgBox.text = MsgBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			MsgBox.text:SetPoint("CENTER",0,0)
			MsgBox.text:SetTextScale(1.1)
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
			MsgBox:SetResizeBounds(300,80,800,500)
			MsgBox:SetScript("OnDragStart",function(self)	if IsShiftKeyDown() then self:StartSizing() else self:StartMoving(); end	end)
			MsgBox:SetScript("OnDragStop", function(self)	self:StopMovingOrSizing(); DBGROPT.msgbox_width=self:GetWidth(false); DBGROPT.msgbox_height=self:GetHeight(false);	end)
			MsgBox:SetScript("OnKeyDown", function (self, key)	 	if self:IsShown() and (key=="ESCAPE" or key=="ENTER") then self:Hide(); end;		end)
			MsgBox:Hide()
			MsgBox.showMsgBox = function (self,text,title)
				if title and title ~= "" then self.header:SetText(tostring(title)) end
				if text and text ~= "" then self.text:SetText(tostring(text)) end
				if DBGROPT.sound == true then PlaySoundFile("Interface\\AddOns\\DBGR\\snd\\msg.wav"); end
				self:SetSize(tonumber(DBGROPT.msgbox_width) or 300, tonumber(DBGROPT.msgbox_height) or 100)
				self:Show()
			end
	return 	MsgBox
end

local function SecondsToTime(time)
	local hours = floor(mod(time, 86400)/3600) + floor(time/86400)*24
	local minutes = floor(mod(time,3600)/60)
	local seconds = floor(mod(time,60))
	return format("  %02dh   %02dm   %02ds",hours,minutes,seconds)
end

local function displayMailsInfo(self)
	local curSoundSet = DBGROPT.sound;
	local numItems, totalItems = GetInboxNumItems();
	local numAttach, totalGold = CountItemsAndMoney(self);
	local pozostalo, turatxt, itemy, gold = " "," "," "," ";
	if numAttach ~= 0 then itemy   = "Ilosc itemow w mailach: |cFF33FF33"..numAttach.."|r\n" end
	if totalGold ~= 0 then gold    = "Ilosc golda w mailach: |cFF33FF33"..tostring(forsaTranslate(totalGold)).."|r" end
	if totalItems > 0 then
		MailInfoFrame:Show();
		local tury = ceil(totalItems / 50);
		if tury < 5 then
			pozostalo = "Pozostaly";
			tura = "tury";
		elseif tury > 4 then
			pozostalo = "Pozostalo";
			tura = "tur";
		end
		if tury ~= 1 then turatxt = "\n"..pozostalo.." |cFF33FF33"..tostring(tury).."|r "..tura.." otwierania." end
		--DBGROPT.sound=false;
		--MsgBox:showMsgBox("W skrzynce jest w sumie |cFFFF00FF"..totalItems.."|r maili.\n\n" .. itemy .. gold .. turatxt, "Mailbox stats");
		--DBGROPT.sound=curSoundSet;
		MailInfoFrame_Text:SetText("W skrzynce jest w sumie |cFFFF00FF"..totalItems.."|r maili.\n" .. itemy .. gold .. turatxt);
	else
		print("|cFFFF99FFSkrzynka pusta :(|r");
	end
	--MsgBox.opener="MAIL"
end

function CountItemsAndMoney(self)
	local numAttach = 0;
	local numGold = 0;
	local msgSubject;
	local spam = 0;
	self:UnregisterEvent("MAIL_INBOX_UPDATE");
	for i = 1, GetInboxNumItems() do
			local msgSubject, msgMoney, _, _, msgItem = select(4, GetInboxHeaderInfo(i))
			numAttach = numAttach + (msgItem or 0);
			numGold = numGold + msgMoney;
	end
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	return numAttach, numGold
end

function forsaTranslate(money)
	return GetMoneyString(math.abs(money));
end

local function eventHandler(self, event, ...)
	if     event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == ADDON_NAME and DBGROPT == nil then OnClick_RestoreDef(); end -- DBGROPT = {sound=true ,icon_size=24, msgbox_width=300, msgbox_height=100}; end	-- defaulting non existing options
	elseif event == "PLAYER_ENTERING_WORLD" then
		local is_init_login, is_reloading_UI = ...
		if is_init_login then showAlertOnScreen(format("%s %s (%s)", ADDON_NAME, ADDON_VERSION, ADDON_REL_TYPE),255,75,0,8,5,500) end
		if is_reloading_UI then print(format("%1$s%2$s%s %s (%s)%2$s%1$s",LOGO(20),(" "):rep(10), ADDON_NAME, ADDON_VERSION, ADDON_REL_TYPE, LOGO(20)));	end
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" and DBGROPT.xpinfo then
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
		if free_talent > 0 then	MsgBox:showMsgBox(string.format("You have free %d unspent talent points!",free_talent)); MsgBox.opener="PLAYER_LEVEL_UP"; end
	elseif event == "TIME_PLAYED_MSG" then
		if TIME_REQ then
			local timeTotal, timeCurLvl = ...
			MsgBox:showMsgBox(string.format("Total:  %s\nLevel:  %s",SecondsToTime(timeTotal),SecondsToTime(timeCurLvl)),"Play time statistics")
			MsgBox.opener = "TIME_PLAYED_MSG"
			TIME_REQ = false
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local 	text, _ = ...
		if		text:find("buyer") and DBGROPT.ah then
			local extracted = text:match("auction of (.*).")
			if MsgBox:IsShown() and MsgBox.opener == "AH_SELL" then
				MsgBox:showMsgBox(string.format("%s, %s",MsgBox.text:GetText(), extracted), "Auction House")
			else
				MsgBox:showMsgBox(string.format("AH item sell: %s", extracted), "Auction House")
			end
			MsgBox.opener = "AH_SELL"
		elseif	text:find("outbid") and DBGROPT.ah then
			local outbid_item = text:match("outbid on (.*).")
			if MsgBox:IsShown() and MsgBox.opener == "AH_OUTBID" then
				MsgBox:showMsgBox(string.format("%s, %s",MsgBox.text:GetText(), outbid_item), "Auction House")
			else
				MsgBox:showMsgBox(string.format("OUTBID: %s", outbid_item), "Auction House")
			end
				MsgBox.opener = "AH_OUTBID"
		elseif	text:find("AFK") and DBGROPT.afk then
			MsgBox:showMsgBox("Move or your character has been logout soon!", "! ! !  AFK  WARNING  ! ! !")
			MsgBox.opener = "AFK_WARNING"
		end
	elseif event == "MAIL_INBOX_UPDATE" then
		displayMailsInfo(self);
	end
end
-- ===================================================================================================================================================================================================

local	frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
		frame:RegisterEvent("PLAYER_LEVEL_UP")
		frame:RegisterEvent("CHAT_MSG_SYSTEM")
		frame:RegisterEvent("TIME_PLAYED_MSG")
		frame:RegisterEvent("MAIL_INBOX_UPDATE")
		frame:SetScript("OnEvent", eventHandler)

MsgBox = create_MsgBox()

ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", AddLootIcons);
ChatFrame1EditBox:SetAltArrowKeyMode(false);

SLASH_DBFRAME1 = "/dbgr"
function SlashCmdList.DBFRAME(msg, editbox)
	if msg == "" then	MsgBox:showMsgBox();	end																			-- show last message in frame
	if msg == "config" then SettingsFrame:Show();	end
	if msg == "playtime" then TIME_REQ = true; RequestTimePlayed(); end														-- show total & current lvl play time
	if msg == "get" then for k, v in pairs(DBGROPT) do print(k.." : "..tostring(v));	end; end							-- show current saved variables
end

--#region 		SettingsFrame UI handlers
function OnShow_SettingsFrame(obj)
	Title:SetText(format("%1$s%2$s%s %s (%s) - SETTINGS%2$s%1$s",LOGO(30),(" "):rep(5), ADDON_NAME, ADDON_VERSION, ADDON_REL_TYPE, LOGO(30)))
	SetNotifySounds:SetChecked(DBGROPT.sound);
	SetAHNotify:SetChecked(DBGROPT.ah);
	SetAfkNotify:SetChecked(DBGROPT.afk);
	SetXPNotify:SetChecked(DBGROPT.xpinfo);
end
function OnClick_SaveReload()
	SettingsFrame:Hide();
	ReloadUI();
end
function OnClick_RestoreDef()
	DBGROPT = {
				sound=true,
				xpinfo=true,
				ah=true,
				afk=true,
				icon_size=24,
				msgbox_width=300,
				msgbox_height=100
			};
	SettingsFrame:Hide();
end
function OnClick_SetNotifySounds(obj, _)
	DBGROPT.sound = obj:GetChecked();
end
function OnClick_SetAHNotify(obj, _)
	DBGROPT.ah = obj:GetChecked();
end
function OnClick_SetAfkNotify(obj, _)
	DBGROPT.afk = obj:GetChecked();
end
function OnClick_SetXPNotify(obj, _)
	DBGROPT.xpinfo = obj:GetChecked();
end
--#endregion 	SettingsFrame UI handlers

