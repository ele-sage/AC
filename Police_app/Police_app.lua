-- Author: 	Emile Le Sage
-- Date: 	2023-04-15

-- This script is a police app for Assetto Corsa
-- It allows you to send in game chat messages that tagged automatically infos of the player in front of you
-- To send a message, all you need to do is clicking one of the buttons 
-- It also allows you to see the speed of any player whitin a certain range of you (radar tab)
-- This script is a work in progress, and will be updated in the future
-- Option to send what is on your clipboard to the chat 

-- Currently the script output messages in the message tab to not spoiled the players with the messages

local msgOther = {
	"Pursuit Started, Unknown Vehicle",
	"Stop The Vehicle Immediately or You Will Be Arrested",
	"Last WARNING, Stop The Vehicle Immediately or I will have to use force",
	", I'm attempting PIT maneuver.\nCurrent Speed :",
	"Suspect In Visual, Vehicle Description: ",
	"Suspect Lost, Pursuit Aborted\n",
	" is requesting backup on H1",
	" is requesting backup on H2",
	" is requesting backup on H3",
	" is requesting backup on C1"
}

local msgArrest = {
	"Reason of the Arrest : Speeding\n",
	"Reason of the Arrest : Illegal Racing\n",
	"Reason of the Arrest : Hitting Pedestrian\n",
	"Reason of the Arrest : Car Theft\n",
	"Reason of the Arrest : Evading Police\n",
	"Reason of the Arrest : Unlicensed Driver\n",
	"Reason of the Arrest : Public Intoxication\n",
	"Reason of the Arrest : Public Disturbance\n",
}

local buttonsOther = {
	"Pursuit Started",
	"Asking To Stop",
	"Last Warning",
	"PIT maneuver",
	"Suspect In Visual",
	"Suspect Lost",
	"Backup H1",
	"Backup H2",
	"Backup H3",
	"Backup C1",
}

local buttonsArrest = {
	"Speeding",
	"Illegal Racing",
	"Hitting Pedestrian",
	"Car Theft",
	"Evading Police",
	"Unlicensed Driver",
	"Public Intoxication",
	"Public Disturbance",
}

-- local sharedData = ac.connect{
-- 	ac.StructItem.key('ACP'),        -- optional, to avoid collisions
-- 	someString = ac.StructItem.string(24), -- 24 is for capacity
-- 	someInt = ac.StructItem.int(),
-- 	someDouble = ac.StructItem.double(),
-- 	someVec = ac.StructItem.vec3()
-- }

local cameras = {}
local first = true

local players = {}
local carInFront
local radarRange = 250
local suspectName = ""
local suspectCar = ""
local suspectSpeed = 0
local isRadar = false
local isLockedOnPlayer = false
local arrestations = {}
local nbArrest = 1
local serverIp = ""

local function sendMsgOther(b)
	if suspectName ~= "" then
		if b == 5 then
			ac.sendChatMessage(msgOther[b] .. suspectCar .. string.format(" driving at %dmph",suspectSpeed/1.609344))
		end
	end
	if b == 1 or b == 2 or b == 3 then
		ac.sendChatMessage(msgOther[b])
	elseif b == 4 then
		ac.sendChatMessage("Control, this is Officer "  .. ac.getDriverName(0) .. msgOther[b] .. string.format("%dmph",ac.getCar(0).speedKmh/1.609344))
	elseif b == 6 then
		ac.sendChatMessage(msgOther[b] .. "Officer " .. ac.getDriverName(0) .. " has lost the suspect")
	elseif b > 6 then
		ac.sendChatMessage("Officer " .. ac.getDriverName(0) .. msgOther[b])
	end
end

local function sendMsgArrest(b)
	if suspectName ~= "" then 
		arrestations[nbArrest] = msgArrest[b] .. "Officer " .. ac.getDriverName(0) .. " has arrested " .. suspectName .." driving a " .. suspectCar .. os.date("\nDate of the Arrestation: %c")
		ac.sendChatMessage(msgArrest[b] .. "Officer " .. ac.getDriverName(0) .. " has arrested " .. suspectName .." driving a " .. suspectCar)
		nbArrest = nbArrest + 1
	end
end

local function getCarInFront()
	if ui.checkbox('Activate Radar', isRadar) then
		isRadar = not isRadar
	end
	if isRadar then
		if ui.checkbox('Activate Target Mod', isLockedOnPlayer) then
			isLockedOnPlayer = not isLockedOnPlayer
			carInFront = ac.getCarIndexInFront(0)
		end
		if not isLockedOnPlayer then
			carInFront = ac.getCarIndexInFront(0)
		end
		if carInFront ~= -1 then
			suspectName = ac.getDriverName(carInFront)
			suspectCar = ac.getCarName(carInFront)
			suspectSpeed = ac.getCar(carInFront).speedKmh
	
			ui.dwriteDrawText("Driver in Front :  ", 20, vec2(20, 30 + 80), rgbm.colors.white)
			ui.dwriteDrawText(suspectName, 20, vec2(180, 30 + 80), rgbm.colors.yellow)
			ui.dwriteDrawText("Car :  ", 20, vec2(20, 60 + 80), rgbm.colors.white)
			ui.dwriteDrawText(suspectCar, 20, vec2(180, 60 + 80), rgbm.colors.yellow)
			ui.dwriteDrawText("Speed :  ", 20, vec2(20, 90 + 80), rgbm.colors.white)
			ui.dwriteDrawText(string.format("%d",suspectSpeed/1.609344) .. "mph", 20, vec2(180, 90 + 80), rgbm.colors.yellow)		
		else
			ui.dwriteDrawText("No Car In Front", 20, vec2(20, 30 + 80), rgbm.colors.white)
			suspectName = ""
			suspectCar = ""
			suspectSpeed = 0
		end
	end
end

local function tabShortcuts()
	getCarInFront()
	ui.newLine(100)
	ui.dwriteText("Arrest Messages", 20, rgbm.colors.green)
	ui.sameLine(300)
	ui.dwriteText("Other Messages", 20, rgbm.colors.green)
	for i = 1, #buttonsArrest do
		if ui.button(buttonsArrest[i]) then
			sendMsgArrest(i)
		end
		ui.sameLine(300)
		if ui.button(buttonsOther[i]) then
			sendMsgOther(i)
		end
	end
	ui.newLine(50)
	if ui.button("Send ClipBoard") then
		ac.sendChatMessage(ui.getClipboardText())
	end
end

local function tabRadar()
	local police = ac.getCar(0)
	local yourName = ac.getDriverName(0)
	local j = 1

	if ui.checkbox('Activate Radar', isRadar) then
		isRadar = not isRadar
	end
	if isRadar then
		for i = ac.getSim().carsCount - 1, 0, -1 do
			local car = ac.getCar(i)
			if car.isConnected and (not car.isHidingLabels) then
				players[j] = {
					name = ac.getDriverName(i),
					position = car.position,
					speed = car.speedKmh,
				}
				j = j + 1
			end
		end
		j = 1
		for i = 1, #players do
			if players[i].name ~= yourName then
				if players[i].position.x > police.position.x - radarRange and players[i].position.z > police.position.z - radarRange and players[i].position.x < police.position.x + radarRange and players[i].position.z < police.position.z + radarRange then
					ui.dwriteDrawText(players[i].name, 20, vec2(20, j*30 + 50), rgbm.colors.yellow)
					ui.dwriteDrawText(string.format("Speed:  %d",players[i].speed/1.609344) .."mph\n", 20, vec2(250, j*30 + 50), rgbm.colors.white)
					if players[i].speed > 120 then
						ui.dwriteDrawText("Speeding", 20, vec2(450, j*30 + 50), rgbm.colors.red)
					end
					j = j + 1
				end
			end
		end
		if j == 1 then
			ui.dwriteDrawText("No One In Range", 20, vec2(20, 80), rgbm.colors.white)
		end
	end
end

local function printMessage()
	local allMsg = ""

	ui.text("Set ClipBoard by clicking on the message you want to Copy")
	for i = 1, #arrestations do
		if ui.button("#" .. i .. ": ") then
			ui.getClipboardText(arrestations[i])
		end
		ui.sameLine()
		ui.text(arrestations[i])
	end
	if ui.button("Set all messages to ClipBoard") then
		for i = 1, #arrestations do
			allMsg = allMsg .. arrestations[i] .. "\n"
		end
		ui.getClipboardText(arrestations)
	end
end

local function tabCamera()

end

local function loadCameras(ini)
	for a, b in ini:iterateValues('SURVEILLANCE_CAMERAS', 'SECTOR') do
		local n = tonumber(b:match('%d+')) + 1

		if cameras[n] == nil then
			for i = #cameras, n do
				if cameras[i] == nil then cameras[i] = {} end
			end
		end
		local suffix = b:match('_(%a+)$')
		if suffix==nil then cameras[n]['NAME'] = ini:get('SURVEILLANCE_CAMERAS', b, '')
		elseif suffix == 'POS' then cameras[n]['POS'] = ini:get('SURVEILLANCE_CAMERAS', b, vec3())
		elseif suffix == 'DIR' then cameras[n]['DIR'] = ini:get('SURVEILLANCE_CAMERAS', b, vec3())
		elseif suffix == 'FOV' then cameras[n]['FOV'] = ini:get('SURVEILLANCE_CAMERAS', b, 0)
		end
	end
end

local function onShowWindow()
	if first then
		local onlineExtras = ac.INIConfig.onlineExtras()
		loadCameras(onlineExtras)
	first = false
	end
end


function script.windowMain(dt)
	if serverIp == ac.getServerIP() then
		local visible = ac.getCar(0).visibleIndex
		ui.text(visible)
		ui.text(ac.getDriverName(visible))
		if ac.getCarID(0) == "charger" then
			onShowWindow()
			ui.tabBar('someTabBarID', function ()
				ui.tabItem('Shortcuts', tabShortcuts)
				ui.tabItem('Radar', tabRadar)
				ui.tabItem('Surveillance Camras', tabCamera)
				ui.tabItem('Message', printMessage)
			end)
		else
			ui.text("This APP is only for police cars")
		end
	else
		ui.text("This MOD was made for the ACP server")
		ui.textHyperlink("https://discord.com/invite/5Wka8QF")
		ui.text(ac.getServerIP())
		local sim = ac.getSim()
		ui.text(sim.directMessagingAvailable)
	end
end