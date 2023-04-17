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

local bob = {
	name = "BOB'S SCRAPYARD",
	pos = vec3(-3564, 42, -103),
	dir = vec3(0.31, -0.32, -0.89),
	active = false,
	fov = 62.76
}

local arena = {
	name = "ARENA",
	pos = vec3(-2283, 114, 3284),
	dir = vec3(-0.87, -0.08, 0.47),
	active = false,
	fov = 55.22
}

local bank = {
	name = "BANK",
	pos = vec3(-713, 153, 3558),
	dir = vec3(-0.05, -0.33, -0.94),
	active = false,
	fov = 90
}

local cameras = {
	bob,
	arena,
	bank
}

local players = {}
local carInFront
local radarRange = 250
local suspectName = ""
local suspectCar = ""
local suspectSpeed = 0
local isRadar = false
local isLockedOnPlayer = false
local isCamera = false
local message = ""

local function sendMsgOther(b)
	if suspectName ~= "" then 
		if b == 3 then
			message = message .. msgOther[b] .. suspectCar .. string.format(" driving at %d",suspectSpeed/1.609344) .. "mph\n\n"
		end
	end
	if b == 1 or b == 2 then
		message = message .. msgOther[b] .. "\n\n"

	elseif b == 4 then
		message = message .. msgOther[b] .. "Agent " .. ac.getDriverName(0) .. " has lost the suspect\n\n"
	elseif b > 4 then
		message = message .. "Agent " .. ac.getDriverName(0) .. msgOther[b] .. "\n\n"
	end
end

local function sendMsgArrest(b)
	if suspectName ~= "" then 
		message = message .. msgArrest[b] .. "Agent " .. ac.getDriverName(0) .. " has arrested " .. suspectName .." driving a " .. suspectCar .. "\n\n"
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
	ui.text(message)
end

local function tabCamera()
	-- for i = 1, #cameras do		
	-- 	if ui.button(cameras[i].name) then
	-- 		ac.setCurrentCamera(6)
	-- 		for j = 1, #cameras do
	-- 			cameras[j].active = false
	-- 		end
	-- 		cameras[i].active = true
	-- 	end
	-- 	if cameras[i].active then
	-- 		ui.text("Camera Direction : " .. cameras[i].dir.x .. " " .. cameras[i].dir.y .. " " .. cameras[i].dir.z)
	-- 		ac.setCameraDirection(cameras[i].dir)
	-- 		ac.setCameraPosition(cameras[i].pos)
	-- 		ac.setCameraFOV(cameras[i].fov)
	-- 	end
	-- end
end

function script.windowMain(dt)
	ui.tabBar('someTabBarID', function ()
		ui.tabItem('Shortcuts', tabShortcuts)	
		ui.tabItem('Radar', tabRadar)
		ui.tabItem('Message', printMessage)
	end)
end
