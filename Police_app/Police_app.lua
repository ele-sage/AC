-- Author: 	Emile Le Sage
-- Date: 	2023-04-18

-- This script is a police app for Assetto Corsa
-- It allows you to send in game chat messages that tagged automatically infos of the player in front of you
-- To send a message, all you need to do is clicking one of the buttons 
-- It also allows you to see the speed of any player whitin a certain range of you (radar tab)
-- This script is a work in progress, and will be updated in the future
-- Option to send what is on your clipboard to the chat 

-- Currently the script output messages in the message tab to not spoiled the players with the messages

local msgStop = {
	"Metatropolis PD, pull the vehicle over!",
	"This is the MPD, pull over the vehicle safely!",
	"I am Chief of Police Britarnya Valon. Pull over the vehicle. If you cooperate, we can work something out!",
	"Metatropolis PD, stop your vehicle!",
}

local msgOther = {
	"Pursuit Started, Unknown Vehicle",
	"",
	"Last WARNING, Stop The Vehicle Immediately or I will have to use force",
	", I'm attempting PIT maneuver.\nCurrent Speed :",
	"Suspect In Visual, Vehicle Description: ",
	"Suspect Lost, Vehicle Description: ",
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
	"Reason of the Arrest : Intoxication While Driving\n",
	"Reason of the Arrest : Public Disturbance\n",
}

local buttonsOther = {
	"Pursuit.png",
	"Stop.png",
	"Final.png",
	"PIT.png",
	"Lost.png",
	"Regained.png",
	"Terminate.png",
	"H1.png",
	"H2.png",
	"H3.png",
	"C1.png",
}

local buttonsArrest = {
	"Speeding",
	"Racing",
	"Hitting",
	"Theft",
	"Evading",
	"Intoxication",
	"Disturbance",
}

local bob = {
	name = "BOB'S SCRAPYARD",
	pos = vec3(-3564, (30 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5), -103),
	dir = math.round(-ac.getCompassAngle(vec3(0.30, -0.18, -0.94))),
	fov = 60
}

local arena = {
	name = "ARENA",
	pos = vec3(-2283, (114 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5), 3284),
	dir = math.round(-ac.getCompassAngle(vec3(-0.87, -0.08, 0.47))),
	fov = 70
}

local bank = {
	name = "BANK",
	pos = vec3(-716, (149.5 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5),3556.4),
	dir = math.round(-ac.getCompassAngle(vec3(-0.04, -0.05, -1.00))),
	fov = 95
}

local SR = {
	name = "STREET RUNNERS",
	pos = vec3(-57.3, (102 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5), 2935.5),
	dir = math.round(-ac.getCompassAngle(vec3(-0.10, -0.05, -0.99))),
	fov = 67
}

local RC = {
	name = "ROAD CRIMINALS",
	pos = vec3(-2332, (99.6 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5), 3119.2),
	dir = math.round(-ac.getCompassAngle(vec3(-0.93, -0.01, 0.36))),
	fov = 60
}

local RR = {
	name = "RECKLESS RENEGADES",
	pos = vec3(-2993.7, (-25.9 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5),-601.7),
	dir = math.round(-ac.getCompassAngle(vec3(0.96, -0.04, -0.27))),
	fov = 60
}

local MM = {
	name = "MOTION MASTERS",
	pos = vec3(-2120.4, (-13.3 - physics.raycastTrack(pos3, vec3(0, -1, 0), 20) + 0.5),-1911.5),
	dir = math.round(-ac.getCompassAngle(vec3(-1.00, 0.00, 0.03))),
	fov = 60
}

local cameras = {
	bob,
	arena,
	bank,
	SR,
	RC,
	RR,
	MM
}

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
local serverIp = "95.211.222.135"
local valideCar = "chargerpolice_acpursuit"

local function sendMsgOther(b)
	if suspectName ~= "" then
		if b == 5 or b == 6 then
			ac.sendChatMessage(msgOther[b] .. suspectCar .. string.format(" driving at %dmph",suspectSpeed/1.609344))
		end
	end
	if b == 1 or b == 3 then
		ac.sendChatMessage(msgOther[b])
	elseif b == 2 then
		ac.sendChatMessage(msgStop[math.floor(os.clock()) % 4 + 1])
	elseif b == 4 then
		ac.sendChatMessage("Control, this is Officer "  .. ac.getDriverName(0) .. msgOther[b] .. string.format("%dmph",ac.getCar(0).speedKmh/1.609344))
	elseif b == 7 then
		ac.sendChatMessage(msgOther[b] .. "Officer " .. ac.getDriverName(0) .. " has lost the suspect")
	elseif b > 7 then
		ac.sendChatMessage("Officer " .. ac.getDriverName(0) .. msgOther[b])
	end
end

local function sendMsgArrest(b)
	if suspectName ~= "" then 
		arrestations[nbArrest] = string.format("%s", msgArrest[b] .. "Officer " .. ac.getDriverName(0) .. " has arrested " .. suspectName .."\nWho was driving a " .. suspectCar .. os.date("\nDate of the Arrestation: %c"))
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
	
	ui.dwriteText("Other Messages", 20, rgbm.colors.green)
	for i = 1, #buttonsOther do
		ui.image(buttonsOther[i], vec2(15, 15))
		if ui.invisibleButton(buttonsOther[i], vec2(15, 15)) then
			sendMsgOther(i)
		end
		if i % 4 == 1 then
			ui.sameLine(100)
		elseif i % 4 == 2 then
			ui.sameLine(200)
		elseif i % 4 == 3 then
			ui.sameLine(300)
		end
	end
	ui.newLine()
	ui.dwriteText("Arrest Messages", 20, rgbm.colors.green)
	for i = 1, #buttonsArrest do
		if ui.button(buttonsArrest[i]) then
			sendMsgArrest(i)
		end
		if i % 4 == 1 then
			ui.sameLine(100)
		elseif i % 4 == 2 then
			ui.sameLine(200)
		elseif i % 4 == 3 then
			ui.sameLine(300)
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

local function tabCamera()
	for i = 1, #cameras do		
		local h = math.rad(cameras[i].dir + ac.getCompassAngle(vec3(0, 0, 1)))
		if ui.button(cameras[i].name) then 
			ac.setCurrentCamera(ac.CameraMode.Free) 
			ac.setCameraPosition(cameras[i].pos) 
			ac.setCameraDirection(vec3(math.sin(h), 0, math.cos(h))) 
			ac.setCameraFOV(cameras[i].fov)
		end
	end
	if ac.getSim().cameraMode == ac.CameraMode.Free then --button to return to car because pressing f1 is annoying 
        if ui.button('Police car camera') then ac.setCurrentCamera(ac.CameraMode.Cockpit) end
    end
end

local function getMessage()
	local allMsg = ""
	
	ui.text("Set ClipBoard by clicking on the button\nnext to the message you want to copy.")
	for i = 1, #arrestations do
		if ui.smallButton("#" .. i .. ": ", vec2(0,10)) then
			ui.setClipboardText(arrestations[i])
		end
		ui.sameLine()
		ui.text(arrestations[i])
	end
	ui.newLine()
	if ui.button("Set all messages to ClipBoard") then
		for i = 1, #arrestations do
			allMsg = allMsg .. arrestations[i] .. "\n\n"
		end
		ui.setClipboardText(allMsg)
	end
end

function script.windowMain(dt)
	if serverIp == ac.getServerIP() then
		if ac.getCarID(0) == valideCar then
			ui.tabBar('someTabBarID', function ()
				ui.tabItem('Shortcuts', tabShortcuts)
				ui.tabItem('Radar', tabRadar)
				ui.tabItem('Cameras', tabCamera)
				ui.tabItem('Arrestations', getMessage)
			end)
		else
			ui.text("This APP is only for police cars")
		end
	else
		ui.text("This MOD was made for the ACP server")
		if ui.textHyperlink("https://discord.gg/acpursuit") then
			os.openURL("https://discord.gg/acpursuit")
		end
	end
end
