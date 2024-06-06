---@diagnostic disable: inject-field, deprecated, undefined-global, param-type-mismatch

local ADDON_NAME = "DBGR"
local ADDON_VERSION = "0.4.3"
local ADDON_REL_TYPE = "BETA"
local LOGO = function(size) return string.format("|TInterface\\AddOns\\DBGR\\img\\d:%d|t", size) end

function AddLootIcons(self, event, msg, ...)
	local _, fontSize = GetChatWindowInfo(self:GetID())
	local 	function iconForLink(link)
		local texture = GetItemIcon(link)
		return "\124T"..texture..":30\124t"..link
	end
	msg = string.gsub(msg,"(\124c%x+\124Hitem:.-\124h\124r)",iconForLink)
	return false, msg:gsub("You receive loot:","Loot :   "), ...
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
			MsgBox.header = MsgBox:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
			MsgBox.header:SetPoint("TOP",0,-7)
			MsgBox.header:SetTextScale(1.1)
			MsgBox.header:SetText(string.format("%s               %s %s (%s)               %s",LOGO(18),ADDON_NAME,ADDON_VERSION,ADDON_REL_TYPE,LOGO(18)))
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
			MsgBox.btn:SetText(" OK ");
			MsgBox.btn:SetScript("OnClick", function() MsgBox:Hide(); end )
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
				self:Show()
			end
	return 	MsgBox
end

local function eventHandler(self, event, ...)
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
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
		if free_talent > 0 then
			MsgBox.text:SetText(string.format("You have free %d unspent talent points!",free_talent))
			MsgBox:Show()
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local text, _ = ...
		if string.find(text, "buyer") then
			local extracted = string.match(text, "auction of (.*).")
			if MsgBox:IsShown() then
				MsgBox:showMsgBox(string.format("%s, %s",MsgBox.text:GetText(), extracted), "Auction House")
			else
				MsgBox:showMsgBox(string.format("AH item sell: %s", extracted), "Auction House")
			end
		end
	end
end
-- ===================================================================================================================================================================================================

local	frame = CreateFrame("Frame")
		frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
		frame:RegisterEvent("PLAYER_LEVEL_UP")
		frame:RegisterEvent("CHAT_MSG_SYSTEM")
		frame:SetScript("OnEvent", eventHandler)
MsgBox = create_MsgBox()

ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", AddLootIcons);
ChatFrame1EditBox:SetAltArrowKeyMode(false);

SLASH_DBFRAME1 = "/dbgr"
function SlashCmdList.DBFRAME(msg, editbox)
	if msg == "" then	MsgBox:showMsgBox();	end		-- show last message in frame
end