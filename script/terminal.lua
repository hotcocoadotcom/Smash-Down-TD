#include "game.lua"
#include "score.lua"
#include "debug.lua"


function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


function init()
	gMissionSelected = ""
	gMissionViewed = ""
	gMissionHighlighted = ""
	gMissionScale = 0

	gLevelSelected = ""
	gLevelViewed = ""
	gLevelHighlighted = ""
	gLevelScale = 0

	gMessageSelected = ""
	gMessageOutput = 0
	gMessageOutputSpeed = 1
	gMessagePause = 0
	gMessageScale = 0
	gMessageListPos = 0
	gMessageListPosSmooth = 0
	gMessagePart = 1
	gMessageAttachmentScale = 0
	gMessageImageScale = 0

	gRankInfoScale = 0
	gCashInfoScale = 0
	gNoCash = 0

	gCash = GetInt("savegame.mod.cash")

	gToolSelected = "none"
	gToolOutput = 0
	gToolScale = 1

	gHoverTop = false
	gHoverDebug = false
	gHoverScore = false
	gHoverCash = false

	gDebugScale = 0

	gTabSelected = "messages"
	gTabScroll = 0

	gTimeSinceMessageRead = 0

	local msg = ListKeys("savegame.mod.message")
	for i=1, #msg do
		local id = msg[i]
		if gMessages[id]==nil then
			ClearKey("savegame.mod.message."..id)
		end
	end
end


function tick()
	gTimeSinceMessageRead = gTimeSinceMessageRead + GetTimeStep()
	evaluate()
end


function evaluate()
	if gDisableEvaluation then
		return
	end

	if not isMessageReceived("cocoa_intro") then
		receiveMessage("cocoa_intro")
	end
end

function isMessageReceived(messageId)
	return GetInt("savegame.mod.message."..messageId) > 0
end


function isMessageRead(messageId, delay)
	if not delay then
		delay = 0
	end
	return GetInt("savegame.mod.message."..messageId) == 2 and (delay == 0 or gTimeSinceMessageRead > delay)
end


function hasUnreadMessages()
	local messages = ListKeys("savegame.mod.message")
	for i=1,#messages do
		if GetInt("savegame.mod.message."..messages[i]) == 1 then
			return true
		end
	end
	return false
end


function isMissionCompleted(missionId)
	return missionId and getMissionScore(missionId) > 0
end


function isSideMission(missionId)
	local m = gMissions[missionId]
	return m and m.sidemission
end


function isMissionInMessageCompleted(messageId)
	return isMissionCompleted(gMessages[messageId].mission)
end


function getTotalScore()
	local score = 0
	local missions = ListKeys("savegame.mod.mission")
	for i=1,#missions do
		score = score + GetInt("savegame.mod.mission."..missions[i]..".score")
	end
	return score
end


function getLevelScore(levelId)
	local score = 0
	for id,mission in pairs(gMissions) do
		if mission.level == levelId then
			score = score + GetInt("savegame.mod.mission."..id..".score")
		end
	end
	return score
end


function getUnfinishedMissionCount(levelId)
	local count = 0
	for id,mission in pairs(gMissions) do
		if mission.level == levelId then
			if GetBool("savegame.mod.mission."..id) and GetInt("savegame.mod.mission."..id..".score") == 0 then
				count = count + 1
			end
		end
	end
	return count
end


function getRank(score)
	local name
	for i=1,#gRanks do
		if score >= gRanks[i].score then
			name = gRanks[i].name
		end
	end
	return name
end


function receiveMessage(messageId)
	UiSound("MOD/ui/terminal/new-message.ogg")
	SetInt("savegame.mod.message."..messageId, 1)
end


function unlockMission(missionId)
	if missionId == nil or missionId == "" then return end
	SetInt("savegame.mod.mission."..missionId, 1)
end


function isMissionUnlocked(missionId)
	return GetInt("savegame.mod.mission."..missionId) == 1
end


function getLevelMissions(level)
	local missions = ListKeys("savegame.mod.mission")
	local levelMissions = {}
	for i=1,#missions do
		local missionId = missions[i]
		if gMissions[missionId] then
			if gMissions[missionId].level == level then
				levelMissions[#levelMissions+1] = missionId
			end
		end
	end
	return levelMissions
end


function getUnlockedLevels()
	local missions = ListKeys("savegame.mod.mission")
	local levels = {}
	local tmp = {}
	for i=1,#missions do
		local missionId = missions[i]
		if gMissions[missionId] then
			local level = gMissions[missionId].level
			if level ~= "" and tmp[level] == nil then
				tmp[level] = 1
				levels[#levels+1] = level
			end
		end
	end
	return levels
end


function getMissionScore(missionId)
	return GetInt("savegame.mod.mission."..missionId..".score")
end

function getMessageForMission(missionId)
	for id,msg in pairs(gMessages) do
		if msg.mission == missionId then
			return msg
		end
	end
	return nil
end


function hasRank(rank)
	for i=1,#gRanks do
		if string.lower(gRanks[i].name) == string.lower(rank) then
			return getTotalScore() >= gRanks[i].score
		end
	end
	return false
end


function startMission(id)
	if gMissions[id] then
		StartLevel(id, gMissions[id].file, gMissions[id].layers, gNoLoadingScreen)
	end
end


-----------------------------------------------------------------------------------------------------------------------------------------


function draw()
	UiPush()
		if gDebugScale > 0 then
			local w = UiWidth()
			local h = UiHeight()
			local dw = 300*gDebugScale
			local mw = UiWidth() - dw
			UiPush()
				UiScale(gDebugScale, 1)
				UiWindow(300, h, true)
				if MOD/ui/terminalDebug then
					terminalDebug()
				end
			UiPop()
			UiTranslate(dw, 0)
			UiScale(mw/w, 1)
			UiWindow(w, h, true)
		end
		drawterminal()
	UiPop()

	if not GetBool("game.deploy") then
		UiPush()
			setFont("h2")
			UiTranslate(60, 1066)
			UiColor(1, 1, 1, 0.5)
			UiAlign("center middle")
			gHoverDebug = UiIsMouseInRect(100, 30)
			if UiTextButton("Debug") then
				if gDebugScale > 0 then
					SetValue("gDebugScale", 0, "cosine", 0.2)
				else
					SetValue("gDebugScale", 1, "cosine", 0.2)
				end
			end
		UiPop()
	end
end


function setTab(tab)
	UiSound("MOD/ui/terminal/tab.ogg")
	gTabSelected = tab
	if tab == "messages" then
		SetValue("gTabScroll", 0, "cosine", 0.4)
	elseif tab == "missions" then
		SetValue("gTabScroll", 1, "cosine", 0.4)
	elseif tab == "tools" then
		SetValue("gTabScroll", 2, "cosine", 0.4)
	end
end


function drawTop()
	UiPush()
		UiColor(0.1,0.1,0.1)
		UiRect(UiWidth(), 50)
		gHoverTop = UiIsMouseInRect(UiWidth(), 50)
		setFont("h1")

		UiTranslate(UiCenter()-200, 25)
		UiAlign("center middle")
		if hasUnreadMessages() and math.mod(GetTime(), 1.0) > 0.5  then
			UiPush()
				UiColor(.5, .8, 1)
				UiTranslate(-95, 0)
				UiImage("MOD/ui/terminal/new-message-dot.png")
			UiPop()
		end
		if gTabSelected == "messages" then UiColor(1,1,1) else UiColor(0.7, 0.7, 0.7) end
		if UiTextButton("Messages") then
			setTab("messages")
		end
		UiTranslate(200, 0)
		if gTabSelected == "missions" then UiColor(1,1,1) else UiColor(0.7, 0.7, 0.7) end
		if UiTextButton("Missions") then
			setTab("missions")
		end
		UiTranslate(170, 0)
		if gTabSelected == "tools" then UiColor(1,1,1) else UiColor(0.7, 0.7, 0.7) end
		if UiTextButton("Tools") then
			setTab("tools")
		end
	UiPop()

	UiPush()
		setFont("h2")

		local score = getTotalScore()
		local cash = GetInt("savegame.mod.cash")
		gCash = gCash + (cash-gCash)*GetTimeStep()*5
		if math.abs(gCash - cash) < 1 then 
			gCash = cash 
		end

		UiPush()
			local rw,_ = UiGetTextSize(getRank(score))
			UiTranslate(20, 10)
			UiColor(.2,.2,.2)
			UiImageBox("MOD/common/box-solid-10.png", 155+rw, 34, 10, 10)
			if gHoverScore then
				UiColor(1,1,1)
			else
				UiColor(.8,.8,.8)
			end

			UiTranslate(20, 24)
			UiText("Score")
			UiTranslate(90, 0)
			UiAlign("right")
			UiText(score)
			
			UiTranslate(20, 0)
			UiAlign("left")
			UiText(getRank(score))
		UiPop()

		UiPush()
			UiTranslate(UiWidth()-180, 10)
			local overCash = UiIsMouseInRect(155+rw, 34)
			UiColor(.2,.2,.2)
			UiImageBox("MOD/common/box-solid-10.png", 160, 34, 10, 10)
			if gHoverCash then
				UiColor(1,1,1)
			else
				UiColor(.8,.8,.8)
			end

			UiTranslate(20, 24)
			UiText("Cash $" .. math.floor(gCash))

			if gNoCash > 0 then
				UiColor(0.8,0.8,0.8,gNoCash)
				UiTranslate(-20, 40)
				UiText("Not enough cash")
			end
		UiPop()

		local overScore = UiIsMouseInRect(195+rw, 50)
		if overScore and not gHoverScore then
			SetValue("gRankInfoScale", 1, "bounce", 0.4)
		elseif not overScore and gHoverScore then
			SetValue("gRankInfoScale", 0, "easein", 0.2)
		end
		gHoverScore = overScore
		if gRankInfoScale > 0 then
			UiPush()
				UiTranslate(20, 55)
				UiScale(1, gRankInfoScale)
				UiColor(.2,.2,.2)
				UiImageBox("MOD/common/box-solid-10.png", 300, gRankInfoHeight, 10, 10)
				UiPush()
					UiColor(.8, .8, .8)
					UiTranslate(0, 30)

					local didNext = false
					local didCurrent = false
					for i=#gRanks, 1, -1 do
						local valid = true
						local s = gRanks[i].score
						local n = gRanks[i].name
						if score < s then
							if score < gRanks[i-1].score then
								valid = false
							else
								didNext = true
								n = "Next rank"
								UiColor(0.4, 0.4, 0.4)
							end
						else
							if didCurrent then
								UiColor(.7,.7,.7)
							else
								UiColor(1,1,1)
								didCurrent = true
							end
						end
						if valid then
							UiPush()
								UiTranslate(110, 0)
								UiAlign("right")
								UiText(s)
								UiTranslate(20, 0)
								UiAlign("left")
								UiText(n)
							UiPop()
							UiTranslate(0, 24)
						end
					end

					UiTranslate(10, 10)
					setFont("p")
					UiColor(.6, .6, .6)
					UiWordWrap(280)
					UiText("Complete missions and clear more targets to increase score and reach higher rank.", true)
					_,gRankInfoHeight = UiGetRelativePos()
				UiPop()
			UiPop()
		end

		UiPush()
			UiTranslate(UiWidth()-190, 0)
			local overCash = UiIsMouseInRect(190, 50)
		UiPop()
		if overCash and not gHoverCash then
			SetValue("gCashInfoScale", 1, "bounce", 0.4)
		elseif not overCash and gHoverCash then
			SetValue("gCashInfoScale", 0, "easein", 0.2)
		end
		gHoverCash = overCash
		if gCashInfoScale > 0 then
			UiPush()
				UiTranslate(UiWidth()-260, 55)
				UiScale(1, gCashInfoScale)
				UiColor(.2,.2,.2)
				UiImageBox("MOD/common/box-solid-10.png", 240, 110, 10, 10)
				UiColor(.8, .8, .8)
				UiTranslate(20, 30)
				setFont("p")
				UiColor(.6, .6, .6)
				UiWordWrap(200)
				UiText("Earn cash by finding hidden valuables. Spend cash on tool upgrades on the tools tab.")
			UiPop()
		end
	UiPop()
end


function drawterminal()
	UiPush()
		local x = -1920 * gTabScroll
		UiTranslate(x, 0)
		drawMessages()

		UiTranslate(1920, 0)
		drawMap()

		UiTranslate(1920, 0)
		drawTools()
	UiPop()

	drawTop()

	if true then
		if not GetBool("game.player.usescreen") then
			if hasUnreadMessages() then
				UiPush()
					if math.mod(GetTime(), 1.0) > 0.4 then
						UiTranslate(UiCenter(), UiMiddle()-100)
						UiAlign("center middle")
						UiWindow(700, 150)
						UiTranslate(UiCenter(), UiMiddle())
						UiColor(.4,.4,.4)
						UiImageBox("MOD/ui/terminal/levelbox.png", UiWidth(), UiHeight(), 5, 17)
						setFont("h1")
						UiScale(2.0)
						UiColor(1,1,1)
						UiText("New message")
					end
				UiPop()
			end
		end
	end
end


function drawMessages()
	UiPush()
		local messageScale = gMessageScale
		local w = 550 + 850*messageScale
		UiTranslate(UiCenter()-w/2, 150)
		UiColor(.15, .15, .15)
		UiImageBox("MOD/common/box-solid-10.png", 550, 800, 10, 10)

		UiTranslate(30, 50)
		setFont("h2", "dim")
		UiPush()
			UiTranslate(20, 0)
			UiText("Inbox")
		UiPop()

		UiTranslate(0, 10)
		UiPush()
			local messages = ListKeys("savegame.mod.message")
			local mouseOver = UiIsMouseInRect(470, 700)
			if mouseOver then
				gMessageListPos = gMessageListPos + InputValue("mousewheel")
			end

			local itemsInView = 11
			if #messages > itemsInView then
				local scrollCount = (#messages-itemsInView)
				if scrollCount < 0 then scrollCount = 0 end
				gMessageListPos = clamp(gMessageListPos, -scrollCount, 0)

				UiPush()
					local h = 656
					UiTranslate(464, 10)
					UiColor(.2,.2,.2)
					UiRect(12, h)
					UiColor(.3,.3,.3)
					local frac = itemsInView / #messages
					local pos = -gMessageListPosSmooth / #messages
					UiTranslate(2,2 + pos*(h-4))
					UiRect(8, (h-4)*frac)
				UiPop()
			else
				gMessageListPos = 0
				gMessageListPosSmooth = 0
			end

			UiWindow(470, 700, true)
			UiTranslate(10, 10)
			gMessageListPosSmooth = gMessageListPosSmooth + (gMessageListPos-gMessageListPosSmooth) * 10 * GetTimeStep()
			UiTranslate(0, gMessageListPosSmooth*60)
			for i = #messages, 1, -1 do
				local id = messages[i]
				local client = gClients[gMessages[id].from]
				if not client then 
					print("Unknown client " .. gMessages[id].from)
				end
				local fromName = client.name
				local image = client.image
				local subject = gMessages[id].subject
				local isRead = isMessageRead(id)
				local mission = gMessages[id].mission
				local hub = gMessages[id].hub
				UiPush()
					if gMessageSelected == id then
						UiColor(.3, .3, .3)
					else
						if mouseOver and UiIsMouseInRect(450, 56) then
							UiColor(.25, .25, .25)
							if InputPressed("lmb") then
								UiSound("MOD/ui/terminal/message-select.ogg")
								selectMessage(id)
							end
						else
							UiColor(.2, .2, .2)
						end
					end
					UiImageBox("MOD/common/box-solid-6.png", 450, 56, 6, 6)
					UiColor(1, 1, 1)
					if isRead then
						UiPush()
							UiTranslate(2, 10)
							UiScale(0.5)
							UiImage(image)
						UiPop()
					else
						UiPush()
							UiColor(.5, .8, 1)
							UiTranslate(8, 16)
							UiImage("MOD/ui/terminal/new-message-dot.png")
						UiPop()
					end
					UiPush()
						UiTranslate(38, 24)
						setFont("h2")
						UiText(fromName)
						UiTranslate(0, 20)
						setFont("p")
						UiText(subject)
					UiPop()
					if mission then
						UiPush()
							UiTranslate(400, 15)
							local completed = isMissionCompleted(mission)
							if completed then
								UiPush()
									UiColor(.4, .8, .4)
									UiTranslate(5, 8)
									UiImage("MOD/ui/terminal/checkmark.png")
								UiPop()
							else
								UiPush()
									if isSideMission(mission) then
										UiColor(0.6, 0.7, 0.8, 0.8)
										UiScale(0.9)
									else
										UiColor(0.9, 0.9, 0.9, 1)
									end
									UiImage("MOD/ui/terminal/attachment.png")
								UiPop()
							end
						UiPop()
					end
					if hub then
						UiPush()
							UiTranslate(400, 15)
							UiColor(0.8, 0.7, 0.6, 1)
							UiImage("MOD/ui/terminal/attachment.png")
						UiPop()
					end
				UiPop()
				UiTranslate(0, 60)
			end
		UiPop()

		UiPush()
			UiTranslate(550, -60)
			UiScale(messageScale, 1)
			UiColor(.25, .25, .25)
			UiTranslate(400, 400)
			UiAlign("center middle")
			UiScale(gMessageImageScale)
			UiImageBox("MOD/common/box-solid-10.png", 800, 800, 10, 10)
			UiWindow(800, 800)
			UiTranslate(50, 60)
			if gMessageSelected ~= "" then
				local name = gClients[gMessages[gMessageSelected].from].name
				local image = gClients[gMessages[gMessageSelected].from].image
				local subject = gMessages[gMessageSelected].subject
				local body = gMessages[gMessageSelected].body
				local mission = gMessages[gMessageSelected].mission
				local tool = gMessages[gMessageSelected].tool
				local hub = gMessages[gMessageSelected].hub
				UiPush()
					UiTranslate(32, 0)
					UiAlign("center middle")
					UiColor(1,1,1)
					UiImage(image)
					UiTranslate(40, 0)
					UiAlign("left")
					setFont("h1")
					UiText(name)
					UiTranslate(0, 30)
					setFont("h2")
					UiText(subject)
				UiPop()
				UiTranslate(0, 50)
				setFont("p")
				UiWordWrap(700)
				UiAlign("top left")

				local partCount = #body
				if gMessagePause > 0 then
					gMessagePause = gMessagePause - GetTimeStep()
				else
					if gMessageOutput < 1.0 then
						gMessageOutput = gMessageOutput + GetTimeStep() * gMessageOutputSpeed
						if gMessageOutput >= 1.0 then
							gMessagePause = 0.15
						end
					else
						if gMessagePart < partCount then
							gMessagePart = gMessagePart + 1
							gMessageOutput = 0
							
							local type = string.sub(body[gMessagePart][1], 1, 3)
							if type == "div" then
								gMessageOutput = 1
							elseif type == "img" then
								gMessageOutput = 0
								gMessageOutputSpeed = 2
								UiSound("MOD/ui/terminal/image.ogg")
							elseif type == "txt" then
								local l = string.len(body[gMessagePart][2])
								if l < 100 then
									gMessageOutputSpeed = 4
									UiSound("MOD/ui/terminal/printout250.ogg")
								elseif l < 400 then
									gMessageOutputSpeed = 2
									UiSound("MOD/ui/terminal/printout500.ogg")
								else
									gMessageOutputSpeed = 1
									UiSound("MOD/ui/terminal/printout1000.ogg")
								end
							end
						else
							if gMessageAttachmentScale == 0 and (mission or tool or hub) then
								UiSound("MOD/ui/terminal/message-mission.ogg")
								SetValue("gMessageAttachmentScale", 1, "bounce", 0.6)
							end
						end
					end
				end
				for i=1,gMessagePart do
					local type = string.sub(body[i][1], 1, 3)
					local extra = string.sub(body[i][1], 4)
					local arg = body[i][2]

					if string.find(extra, "gray") then
						UiColor(.7, .7, .7)
					elseif string.find(extra, "green") then
						UiColor(.3, 1, .3)
					elseif string.find(extra, "red") then
						UiColor(1, .3, .3)
					elseif string.find(extra, "blue") then
						UiColor(.3, .3, 1)
					elseif string.find(extra, "yellow") then
						UiColor(1, 1, .3)
					elseif string.find(extra, "cyan") then
						UiColor(.3, 1, 1)
					elseif string.find(extra, "magenta") then
						UiColor(1, .3, 1)
					else
						UiColor(1, 1, 1)
					end

					if type == "txt" then
						if string.find(extra, "h1") then
							setFont("h1", "nocolor")
						elseif string.find(extra, "h2") then
							setFont("h2", "nocolor")
						else
							setFont("p", "nocolor")
						end

						local maxChars = 10000
						if i == gMessagePart then
							maxChars = gMessageOutput*string.len(arg)
						end

						local w, h = UiText(arg, false, maxChars)
						UiTranslate(0, h+10)
					elseif type == "img" then
						UiTranslate(0, 0)
						local w,h = UiImage(arg)
						if i == gMessagePart then
							UiPush()
								local bh = h*gMessageOutput
								UiTranslate(0, bh)
								UiColor(0.25,0.25,0.25)
								UiRect(w, h-bh+1)
							UiPop()
						end
						UiTranslate(0, h+8)
					elseif type == "div" then
						UiRect(700, 1)
						UiTranslate(0, 4)
					end
				end

				if (mission or tool or hub) and gMessageAttachmentScale > 0 then
					setFont("button")
					UiTranslate(350, 40)
					UiAlign("center middle")
					UiScale(gMessageAttachmentScale * (1 + math.sin(GetTime()*10)*0.03))
					UiButtonImageBox("MOD/common/box-solid-6.png", 6, 6, .4, .4, .4)
					if mission and gMissions[mission] then
						local txt = "Mission"
						if isSideMission(mission) then
							txt = "Side mission"
							UiColor(0.9, 0.95, 1.0)
						end
						if UiTextButton(txt .. " - " .. gMissions[mission].title) then
							showMission(mission)
						end
					elseif tool then
						if UiTextButton("Tool - " .. gTools[tool].name) then
							setTab("tools")
							selectTool(tool)
						end
					elseif hub then
						if hub == "carib" then
							if UiTextButton("Travel to the Muratori Islands") then
								gDisableEvaluation = true
								StartLevel("hub30", "hub_carib.xml", "v30")
							end
					else
							if UiTextButton("Travel back home") then
								gDisableEvaluation = true
								StartLevel("hub40", "hub.xml", "part2 v40")
							end
						end
					end
				end
			end
		UiPop()
	UiPop()
end


function selectMessage(id)
	if gMessages[id].music and GetInt("savegame.mod.message."..id) == 1 then
		PlayMusic(gMessages[id].music)
		--gNoLoadingScreen = true 		-- Would be nice, but there's an audio glitch somewhere
	end
	SetInt("savegame.mod.message."..id, 2)
	SetValue("gMessageScale", 1, "cosine", 0.3)
	if gMessages[id].mission then
		unlockMission(gMessages[id].mission)
	end
	if gMessageSelected == id then
		return
	end
	gMessageSelected = id
	gMessagePart = 0
	gMessageOutput = 1
	if gMessageScale == 1 then
		gMessageImageScale = 0.95
		SetValue("gMessageImageScale", 1, "bounce", 0.5)
	else
		gMessageImageScale = 1
	end
	SetValue("gMessageAttachmentScale", 0)
	gTimeSinceMessageRead = 0
end


function showMessageByMission(mission)
	for id,_ in pairs(gMessages) do
		if gMessages[id].mission == mission then
			selectMessage(id)
			setTab("messages")
			return
		end
	end
end


function showMission(mission)
	setTab("missions")
	if gLevelSelected ~= gMissions[mission].level then
		gLevelHighlighted = gMissions[mission].level
		gLevelSelected = ""
		SetValue("gLevelScale", 0)
	end
	if gMissionSelected ~= mission then
		gMissionHighlighted = mission
		gMissionSelected = ""
		SetValue("gMissionScale", 0)
	end
end


function setFont(t, c)
	if t == "h1" then
		UiFont("bold.ttf", 42)
	end
	if t == "h1.5" then
		UiFont("bold.ttf", 30)
	end
	if t == "h2" then
		UiFont("bold.ttf", 24)
	end
	if t == "button" then
		UiFont("bold.ttf", 24)
	end
	if t == "p" then
		UiFont("regular.ttf", 21)
	end
	if c == "mark" then
		UiColor(1, 0.8, 0.4)
	elseif c == "dim" then
		UiColor(0.7, 0.7, 0.7)
	elseif c ~= "nocolor" then
		UiColor(1, 1, 1)
	end
end


function drawMap()
	local level = gLevelScale
	UiPush()
		if level > 0 then
			UiDisableInput()
		end
		setFont("h2")
		--PART 2
		if isMissionUnlocked("carib_alarm") then
			UiImage("MOD/ui/terminal/map_carib.jpg")
		else
			UiImage("MOD/images/terminal/map.jpg")
		end
		UiPush()
		if GetTagValue(UiGetScreen(), "location") == "nahe" then
			UiTranslate(796,508)
			UiImage("MOD/ui/terminal/map_x.png")
		elseif GetTagValue(UiGetScreen(), "location") == "gate" then
			UiTranslate(1652,227)
			UiImage("MOD/ui/terminal/map_x.png")
		elseif GetTagValue(UiGetScreen(), "location") == "moon" then
			UiTranslate(309,262)
			UiImage("MOD/ui/terminal/map_x.png")
		end
		UiPop()

		local levels = getUnlockedLevels()
		for i=1,#levels do
			local id = levels[i]
			local title = gLevels[id].map_title
			local x = gLevels[id].map_x
			local y = gLevels[id].map_y
			local unfinishedCount = getUnfinishedMissionCount(id)
			UiPush()
				local levelScore =  getLevelScore(id)

				UiTranslate(x, y)
				local w,_ = UiGetTextSize(title)
				w = w + 20
				if w < 100 then w = 100 end
				
				local h = 30
				if levelScore > 0 then
					h = h + 20
				end
				--if unfinishedCount > 0 then
				--	h = h + 20
				--end

				UiAlign("center middle")
				local over = UiIsMouseInRect(40, 40)
				UiPush()
					UiTranslate(0, 20+h/2)
					over = over or UiIsMouseInRect(w, h)
				UiPop()
				if over and gLevelSelected == "" then
					if InputPressed("lmb") then
						UiSound("MOD/ui/terminal/level.ogg", 1, 1.1)
						gLevelSelected = id
						gLevelViewed = id
						gMissionSelected = ""
						gLevelHighlighted = ""
						SetValue("gMissionScale", 0)
						SetValue("gLevelScale", 1, "easeout", 0.3)
					end
					UiColorFilter(0.8, 0.8, 0.8)
				end
				UiPush()
					if id == gLevelHighlighted then
						UiPush()
							UiTranslate(-20-w/2+ math.sin(GetTime()*10)*8, 34)
							UiImage("MOD/ui/terminal/arrow.png")
						UiPop()
					end
					if unfinishedCount > 0 then
						UiScale(1)
						UiImage("MOD/ui/terminal/level-dot.png")
						setFont("h2")
						UiColor(0,0,0)
						UiText(unfinishedCount)
					else
						UiScale(0.75)
						UiImage("MOD/ui/terminal/level-dot.png")
					end
				UiPop()
				UiTranslate(0, 20)
				UiColor(0.3, 0.3, 0.3, 0.7)
				UiAlign("center")
				UiImageBox("MOD/common/box-solid-10.png", w, h, 10, 10)
				UiColor(1,1,1)
				UiTranslate(0, 22)
				setFont("h2")
				UiText(title)
				--if unfinishedCount > 0 then
				--	UiTranslate(0, 20)
				--	setFont("p")
				--	if unfinishedCount == 1 then
				--		UiText("New mission")
				--	else
				--		UiText(unfinishedCount .. " new missions")
				--	end
				--end
				if levelScore > 0 then
					UiTranslate(0, 20)
					setFont("p")
					UiText("Score "..levelScore)
				end
			UiPop()
		end
	UiPop()
	if level > 0 then
		drawLevel(gLevelViewed)
	end
end


function drawStars(stars, starsMax)
	UiPush()
		UiTranslate(-11, -8)
		UiAlign("center middle")
		UiColor(1, 0.9, 0)
		for i=1, stars do
			UiImage("MOD/ui/terminal/star.png")
			UiTranslate(-24, 0)
		end
		if stars < starsMax then
			UiColor(.4, .4, .4)
			for i=1, starsMax-stars do
				UiImage("MOD/ui/terminal/star.png")
				UiTranslate(-24, 0)
			end
		end
	UiPop()
end

function drawLevel(id)
	local levelFade = gLevelScale
	UiPush()
		UiColor(0, 0, 0, 0.7*levelFade)
		UiRect(UiWidth(), UiHeight())
	UiPop()
	local hoverLevel = false
	local hoverMission = false
	UiPush()
		local width = 500
		local height = 700

		local x = gLevels[id].map_x*(1-levelFade) + UiCenter()*levelFade
		local y = gLevels[id].map_y*(1-levelFade) + UiMiddle()*levelFade
		UiTranslate(x,y)

		UiColorFilter(1,1,1, levelFade)
		UiScale(levelFade)
		UiTranslate(-width/2 - 260*gMissionScale,-height/2)

		hoverLevel = UiIsMouseInRect(width, height)

		UiPush()
			UiColor(0.27, 0.27, 0.27)
			UiImageBox("MOD/common/box-solid-10.png", width, height, 10, 10)
		UiPop()

		UiPush()	
			UiPush()
				UiAlign("center top")
				UiTranslate(width/2,20)
				UiImage(gLevels[id].image)
				UiTranslate(0, 180)
				setFont("h1")
				UiText(gLevels[id].title)
			UiPop()
			UiTranslate(20, 260)
			UiPush()
				setFont("p", "dim")
				UiColor(.6, .6, .6)
				UiWordWrap(450)
				w, h = UiText(gLevels[id].desc)
			UiPop()

			UiTranslate(20, h+20)
			
			missions = getLevelMissions(gLevelViewed)
			for i = 1, #missions do
				local id = missions[i]
				local title = gMissions[id].title
				local desc = gMissions[id].desc
				local details = getScoreDetails(id, getMissionScore(id));
				local h
				UiPush()
					setFont("h2")
					if id == gMissionHighlighted then
						UiPush()
							UiTranslate(-22 + math.sin(GetTime()*10)*4, -20)
							UiImage("MOD/ui/terminal/arrow.png")
						UiPop()
					else
						if isMissionCompleted(id) then
							UiPush()
								UiTranslate(-6, -8)
								UiAlign("center middle")
								UiColor(.4, .8, .4)
								UiImage("MOD/ui/terminal/checkmark.png")
							UiPop()
						end
					end
					UiPush()
						UiTranslate(-20, -20)
						if id == gMissionSelected then
							UiColor(1,1,1,0.1)
							UiImageBox("MOD/common/box-solid-6.png", 450, 26, 6, 6)
						end
						if UiIsMouseInRect(450, 26) then
							UiColor(1,1,1,0.08)
							UiImageBox("MOD/common/box-solid-6.png", 450, 26, 6, 6)
							if InputPressed("lmb") then
								gMissionHighlighted = ""
								if gMissionSelected == id then
									UiSound("MOD/ui/terminal/mission.ogg", 1, 0.9)
									SetValue("gMissionScale", 0, "cosine", 0.2)
									gMissionSelected = ""
								else
									UiSound("MOD/ui/terminal/mission.ogg", 1, 1.1)
									gMissionSelected = id
									gMissionViewed = id
									SetValue("gMissionScale", 1, "cosine", 0.2)
								end
							end
						end
					UiPop()
					UiTranslate(10, 0)
					if isSideMission(id) then
						UiColor(0.7, 0.75, 0.8)
					else
						UiColor(1,1,1)
					end
					UiText(title)
					UiTranslate(width-90, 0)

					UiPush()
						UiTranslate(-11, -8)
						UiAlign("center middle")
						UiColor(1,1,1)
						local w = drawTargetDots(details.required, details.requiredTaken)
						UiTranslate(-w, 0)
						UiColor(.6, .6, .6)
						local w = drawTargetDots(details.optional, details.optionalTaken)
						UiTranslate(-w, 0)
						UiColor(0.6, 0.8, 0.6)
						local w = drawTargetDots(details.bonuses, details.bonusesTaken)
						UiTranslate(-w, 0)
					UiPop()

					h = UiFontHeight() + 2
				UiPop()
				UiTranslate(0, h)
			end	
		UiPop()

		local levelScore = getLevelScore(id)
		if levelScore > 0 then
			UiPush()
				UiTranslate(width/2, height-40)
				setFont("h2")
				UiAlign("center middle")
				UiText("Score " .. levelScore)
			UiPop()
		end

		local missionScale = gMissionScale
		if missionScale > 0 then
			local width = 500
			local height = 600
			UiTranslate(width + 20, 20)
			UiScale(missionScale, 1)

			hoverMission = UiIsMouseInRect(width, height)

			UiColorFilter(1,1,1,missionScale)
			UiPush()
				UiColor(0.27, 0.27, 0.27)
				UiImageBox("MOD/common/box-solid-10.png", width, height, 10, 10)
			UiPop()

			UiPush()
				UiTranslate(20,70)
				UiPush()
					setFont("h1")
					UiText(gMissions[gMissionViewed].title)
				UiPop()
				UiPush()
					UiTranslate(0, 36)
					setFont("p")
					UiWordWrap(450)
					local w, h = UiText(gMissions[gMissionViewed].desc)

					setFont("p", "dim")
					UiTranslate(0, h)

					local message = getMessageForMission(gMissionViewed)
					if message then
						if UiTextButton("View e-mail from "..gClients[message.from].name) then
							showMessageByMission(gMissionViewed)
						end
						UiTranslate(0, UiFontHeight())
					end

					local score = getMissionScore(gMissionViewed)
					local timeLeft = GetFloat("savegame.mod.mission."..gMissionViewed..".timeleft")
					local missionTime = GetFloat("savegame.mod.mission."..gMissionViewed..".missiontime")
					local details = getScoreDetails(gMissionViewed, score);

					if gSkipMissionJustPressed then
						score = 0
					end

					if score > 0 then
						drawScore(title, gMissionViewed, score, timeLeft, missionTime, false, true)
					end
				UiPop()
			UiPop()

			UiPush()
				UiAlign("center middle")
				setFont("h2")
				UiButtonImageBox("MOD/common/box-solid-6.png", 6, 6, .4, .4, .4)
				UiTranslate(width/2, height-50)

				if gSkipMissionJustPressed then
					UiDisableInput()
				end
				
				local enableSkip = (score == 0 and GetInt("options.game.missionskipping") == 1)
				if enableSkip then
					UiTranslate(-120)
					if UiTextButton("Skip mission", 180, 36) then
						skipMission(gMissionViewed)
						gDisableEvaluation = true
						if gMissionViewed == "frustrum_chase" then
							startCinematic("ending1")
						elseif gMissionViewed == "cullington_bomb" then
							startCinematic("ending2")
						else
							startHub()
						end
						gSkipMissionJustPressed = true
					end
					UiTranslate(220, 0)
				end

				UiPush()
					UiScale(1.1 + math.sin(GetTime()*10)*0.06)
					local playText = "Play "
					if score > 0 then
						playText = "Replay "
					end
					if isSideMission(gMissionViewed) then
						playText = playText .. "side mission"
						UiColor(0.9, 0.95, 1.0)
					else
						playText = playText .. "mission"
					end				
					if UiTextButton(playText, 200, 36) then
						startMission(gMissionViewed)
					end
				UiPop()
			UiPop()
		end	
	UiPop()

	if gTabSelected == "missions" and InputPressed("lmb") and not hoverLevel and not hoverMission and not gHoverTop and not gHoverDebug then
		UiSound("MOD/ui/terminal/level.ogg", 1, 0.9)
		SetValue("gLevelScale", 0, "easein", 0.3)
		gLevelSelected = ""
		gMissionSelected = ""
	end

end


-- Helper to drawTools
function drawBars(v, ma)
	UiPush()
		local x = 0
		UiTranslate(0, -14)
		UiColor(1,1,1)
		for i=1,v do
			UiRect(10, 14)
			UiTranslate(12, 0)
		end
		UiColor(.3,.3,.3)
		for i=v+1,ma do
			UiRect(10, 14)
			UiTranslate(12, 0)
		end
	UiPop()
end

function selectTool(id)
	gToolSelected = id
	gToolOutput = 1000
	gToolScale = 1
end

function drawTools()
	-------------------------- TOOL SELECTION -----------------------------------------
	UiPush()
		local tools = ListKeys("savegame.mod.tool")
		local toolListBaseHeight = 590
		local toolListExtraHeight = 0
		if #tools > 13 then
			toolListExtraHeight = toolListExtraHeight + 40 * (#tools-13)
		end
		UiTranslate(350, 200 - toolListExtraHeight/2)
		UiColor(0.15, 0.15, 0.15)
		UiImageBox("MOD/common/box-solid-10.png", 300, toolListBaseHeight + toolListExtraHeight, 10, 10)
		UiWindow(300, 600)
		UiTranslate(25, 50)
		UiPush()
			UiTranslate(10, -15)
			setFont("h2", "dim")
			UiText("Tools")
		UiPop()
		setFont("h2")
		for i=1,#tools do
			local id = tools[i]
			if gTools[id] then
				UiPush()
					if gToolSelected == id then
						UiColor(.3, .3, .3)
					else
						if UiIsMouseInRect(250, 39) then
							UiColor(.25, .25, .25)
							if InputPressed("lmb") then
								gToolSelected = id
								gToolOutput = 0
								UiSound("MOD/ui/terminal/tool.ogg")
								UiSound("MOD/ui/terminal/printout500.ogg", 0.5)
								gToolScale = 0
								SetValue("gToolScale", 1, "easeout", 0.25)
							end						
						else
							UiColor(.2, .2, .2)
						end
					end
					UiImageBox("MOD/common/box-solid-6.png", 250, 36, 6, 6)
					UiColor(1, 1, 1)
					UiTranslate(10, 24)
					setFont("h2")
					UiText(gTools[id].name)
				UiPop()
				UiTranslate(0, 40)
			end
		end
	UiPop()

	-------------------------- DRAW TOOL -----------------------------------------
	local tool = gTools[gToolSelected]
	if tool then
		UiPush()
			UiTranslate(700, 150)
			UiColor(.15, .15, .15)
			UiImageBox("MOD/common/box-solid-10.png", 800, 700, 10, 10)
			UiTranslate(50, 50)
			UiWindow(700, 600)
			UiColor(1,1,1)
			UiPush()
				setFont("h1")
				UiTranslate(0, 40)
				UiText(tool.name)
				UiTranslate(0, 30)
				setFont("p")
				UiWordWrap(400)
				if gToolOutput < 1 then
					gToolOutput = gToolOutput + GetTimeStep()*2
				else
					gToolOutput = 1
				end
				local maxChars = string.len(tool.desc)*gToolOutput
				UiText(tool.desc, false, maxChars)
			UiPop()
			UiPush()
				UiTranslate(UiWidth()-120, 80)
				UiAlign("center middle")
				UiScale(gToolScale * (math.sin(GetTime())*0.1+1.1))
				UiImage("MOD/ui/terminal/tool/"..tool.image)
			UiPop()


			local tooExpensive = false

			-------------------------- UPGRADES-----------------------------------------
			UiTranslate(0, 200)
			UiButtonImageBox("MOD/common/box-solid-6.png",6,6, .2, .2, .2)

			UiPush()
				UiPush()	
					UiColor(.2, .2, .2)
					UiTranslate(-15, -24)
					UiImageBox("MOD/common/box-solid-6.png", 450, 34, 6, 6)
				UiPop()
				setFont("h2", "dim")
				UiText("Attribute")
				UiTranslate(310)
				UiText("Upgrade")
			UiPop()
			UiTranslate(0, 42)
			if #tool.upgrades > 0 then
				local info = ""
				local cash = GetInt("savegame.mod.cash")

				for i=1,#tool.upgrades do
					local upgrade = tool.upgrades[i]
					UiPush()
						UiPush()
							UiTranslate(-15, -24)
							if UiIsMouseInRect(450, 36) then
								UiColor(.2, .2, .2)
								UiImageBox("MOD/common/box-solid-6.png", 320, 36, 6, 6)
								info = upgrade.desc
							end
						UiPop()
					
						local key = "savegame.mod.tool."..gToolSelected.."."..upgrade.id
						local current = upgrade.default
						if HasKey(key) then
							current = GetInt(key)
						end

						setFont("h2")
						UiText(upgrade.name)
						UiTranslate(150, 0)
						UiAlign("right")
						UiText(current)
						UiAlign("left")
						UiTranslate(10, 0)
						drawBars(math.ceil(current / upgrade.step), math.ceil(upgrade.max / upgrade.step))
						local upgradePrice = upgrade.price
						UiTranslate(150, 0)
						if current < upgrade.max then
							UiPush()
								if upgradePrice > cash then
									UiDisableInput()
									UiColorFilter(1,1,1,0.5)
								end
								if UiTextButton("$"..upgradePrice, 100, 28) then
									UiSound("MOD/ui/terminal/upgrade.ogg")
									UiSound("MOD/ui/terminal/cash-counter.ogg", 0.5)
									current = current + upgrade.step
									if current > upgrade.max then current = upgrade.max	end
									SetInt(key, current)
									SetInt("game.tool."..gToolSelected.."."..upgrade.id, current)
									SetInt("savegame.mod.cash", cash-upgradePrice)
									gToolScale = 0.8
									SetValue("gToolScale", 1, "bounce", 0.5)
								end
							UiPop()
							UiPush()
								UiTranslate(0, -24)
								if UiIsMouseInRect(90, 36) then
									if upgradePrice <= cash then
										UiTranslate(100, 24)
										setFont("h2", "dim")
										UiText("+"..upgrade.step.." "..string.lower(upgrade.name))
									else
										tooExpensive = true
									end
								end
							UiPop()
						end
					UiPop()
					UiTranslate(0, 36)
				end

				if info ~= "" then
					UiPush()
						setFont("p", "dim")
						UiTranslate(0, 20)
						UiWordWrap(450)
						UiText(info)
					UiPop()
				end
			else
				setFont("h2")
				UiText("No upgrades available")
			end

			if tooExpensive then
				if gNoCash == 0 then
					SetValue("gNoCash", 1, "linear", 0.3)
				end
			else
				if gNoCash == 1 then
					SetValue("gNoCash", 0, "linear", 0.3)
				end
			end

		UiPop()
	end
end


function unlockTool(toolId)
	if not GetBool("savegame.mod.tool."..toolId..".enabled") then
		SetBool("savegame.mod.tool."..toolId..".enabled", true)
		SetBool("game.tool."..toolId..".enabled", true)
		SetInt("game.player.tool", toolId)
		for j=1, #gTools[toolId].upgrades do
			local id = gTools[toolId].upgrades[j].id
			local value = gTools[toolId].upgrades[j].default
			SetInt("game.tool."..toolId.."."..id, value)
		end
	end
end

