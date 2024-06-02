function AddLootIcons(self, event, msg, ...)
	local _, fontSize = GetChatWindowInfo(self:GetID())
	local 	function iconForLink(link)
		local texture = GetItemIcon(link)
		return "\124T"..texture..":28\124t"..link
	end
	msg = string.gsub(msg,"(\124c%x+\124Hitem:.-\124h\124r)",iconForLink)
	return false, msg:gsub("You receive loot:","Loot :   "), ...
end

function showAlertOnScreen(text,r,g,b,t,f,top)
	local	msg = CreateFrame("MessageFrame", "debugeralert", UIParent)
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

function eventHandler(self, event, ...)
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local text, _ = ...
		local xpgained = text:match("(%d+)")
		local xp = UnitXP("player")
		local maxXp=UnitXPMax("player")
		local percent = tonumber(format("%.1f", (xpgained/maxXp)*100))
		local percent_total = tonumber(format("%.1f", (xp/maxXp)*100) + percent)
		print(string.format("\r\nEXP:|cFFFFEE00 +%d|r|cFFEE0000 (-%.1fx)|r       |cFF22FF15 +%.1f%%|r        TOTAL:|cFF00FFFF %.1f%%|r \r\n", xpgained, (100 - percent_total)/percent, percent, percent_total))
		showAlertOnScreen(string.format("+%.1f%%",percent),0,255,0,3,1,50)
	end
end

function create_MsgBox()
	local	MsgBox = CreateFrame("Frame","dbgr_msgbox",UIParent, "GlowBoxTemplate")
			MsgBox:SetFrameStrata("BACKGROUND")
			MsgBox:SetSize(300, 100)
			MsgBox:SetPoint("CENTER",0,0)
			MsgBox.text = MsgBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			MsgBox.text:SetPoint("TOP",0,-10)
			MsgBox.text:SetTextScale(1.1)
			MsgBox.text:SetText("Debuger Addon")
			MsgBox.btn = CreateFrame("Button","dbgr_msgbox_btn",MsgBox,"UIPanelButtonTemplate");
			MsgBox.btn:RegisterForClicks("AnyUp");
			MsgBox.btn:SetSize(60,25);
			MsgBox.btn:SetPoint("BOTTOM",0,8)
			MsgBox.btn:SetNormalFontObject("GameFontNormal");
			MsgBox.btn:SetHighlightFontObject("GameFontHighlight");
			MsgBox.btn:SetDisabledFontObject("GameFontDisable");
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
	return 	MsgBox
end


-- ===================================================================================================================================================================================================

local	MsgBox = create_MsgBox()
local	frame = CreateFrame("Frame")
		frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
		frame:SetScript("OnEvent", eventHandler)

ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", AddLootIcons);
ChatFrame1EditBox:SetAltArrowKeyMode(false);

SLASH_DBGR1 = "/dbgr"
function SlashCmdList.DBGR(msg, editbox)
	MsgBox:Show()
end