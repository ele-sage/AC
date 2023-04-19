-- Author: 	Emile Le Sage
-- Date: 	2023-04-15

-- This script is made to create timer for deffined sector of a map
-- It allows you time deffined sectors of the track
-- I can also add checkpoints to each sector

-- This script is a work in progress, and will be updated in the future

local h2 = {
	name = "H2",
	lenght = 13.7,
	start = vec4(1685,604,1695,610),
	end_ = vec4(1566,732,1574,748),
	time = 0,
	active = false,
	finished = false
}

local h3 = {
	name = "H3",
	lenght = 4,
	start = vec4(-186,-120,-184,-118),
	end_ = vec4(162,307,164,329),
	time = 0,
	active = false,
	finished = false
}

local drag = {
	name = "Drag",
	lenght = 0,
	start = vec4(-183,1341,-181,1420),
	end_ = vec4(-859,1341,-855,1420),
	time = 0,
	active = false,
	finished = false
}

local touge = {
	name = "Touge",
	lenght = 2.55,
	start = vec4(-3962,9982,-3949,9989),
	end_ = vec4(-5660,10250,-5649,10253),
	time = 0,
	active = false,
	finished = false
}

local bob = {
	name = "BOB'S SCRAPYARD",
	lenght = 6.35,
	start = vec4(-776,3534.8,-749.2,3536),
	end_ = vec4(-3554,-205,-3539,-202),
	time = 0,
	active = false,
	finished = false
}

local serverIp = "95.211.222.135"
local firstLoad = true
local distance = 0
local time = 0
local stime = ''
local min = 0
local s = 0
local sectors = {
	h2,
	h3,
	drag,
	touge,
	bob
}
local speedTraps = {}
local driftZone = {}
local first = true

local function tabCamera()
	if ac.getSim().cameraMode == ac.CameraMode.Free then
		local pos3 = ac.getCameraPosition()
		local dir3 = ac.getCameraForward()

		ui.text("Camera position: " .. pos3.x .. ", " .. pos3.y .. ", " .. pos3.z)
		ui.text("Camera direction: " .. dir3.x .. ", " .. dir3.y .. ", " .. dir3.z)
		if ui.button("Get camera position") then
			ac.setClipboadText("vec3(" .. string.format("%.2f",pos3.x) .. ", " .. string.format("%.2f",pos3.y) .. ", " .. string.format("%.2f",pos3.z) .. ")\nvec3(" .. string.format("%.2f",dir3.x) .. ", " .. string.format("%.2f",dir3.y) .. ", " .. string.format("%.2f",dir3.z) .. ")")
		end
	end
end

local function tabLocation()
	ui.text("Location: ")
end

local function tabSpeedTrap()
	local car = ac.getCar(0)

	for i = 1, #speedTraps do
		if car.position.x > speedTraps[i].location.x and car.position.z > speedTraps[i].location.y and car.position.x < speedTraps[i].location.z and car.position.z < speedTraps[i].location.w then
			if car.speedKmh > speedTraps[i].PB then
				speedTraps[i].PB = car.speedKmh
			end
		end
		ui.dwriteDrawText(speedTraps[i].name, 20, vec2(20, i*30 + 50), rgbm.colors.withe)
		ui.dwriteDrawText(string.format("Speed:  %.2f", car.speedKmh) .."km/h\n", 20, vec2(250, i*30 + 50), rgbm.colors.green)
	end
end

local function tabDriftZone()
	local car = ac.getCar(0)

	for i = 1, #driftZone do
		if car.position.x > driftZone[i].location.x and car.position.z > driftZone[i].location.y and car.position.x < driftZone[i].location.z and car.position.z < driftZone[i].location.w then
			driftZone[i].speed = car.speedKmh
		end
		ui.dwriteDrawText(driftZone[i].name, 20, vec2(20, i*30 + 50), rgbm.colors.withe)
		ui.dwriteDrawText(string.format("Speed:  %.2f", driftZone[i].speed) .."km/h\n", 20, vec2(250, i*30 + 50), rgbm.colors.green)
	end
end

function script.windowMain(dt)
	if serverIp == ac.getServerIP() then
		ui.tabBar('someTabBarID', function ()
			ui.tabItem('Location', tabLocation)
			ui.tabItem('camera', tabCamera)
			ui.tabItem('SpeedTrap', tabSpeedTrap)
			ui.tabItem('DriftZone', tabDriftZone)
			ui.tabItem('Sectors', function ()
				local pos3 = ac.getCar(0).position

				if firstLoad then
					ui.dwriteDrawText("Sectors NULL | time: 0:00:00", 30, vec2(10, 60), rgbm.colors.red)
				end
				for i = 1, #sectors do
					if pos3.x > sectors[i].start.x and pos3.z > sectors[i].start.y and pos3.x < sectors[i].start.z and pos3.z < sectors[i].start.w then
						time = 0
						min = 0
						for j = 1, #sectors do
							sectors[j].active = false
						end
						distance = ac.getCar(0).distanceDrivenSessionKm
						sectors[i].active = true
						sectors[i].finished = false
						s = i
						if s == i then
							break
						end
					end
				end
				if sectors[s].active == true then
					firstLoad = false
					time = time + dt
					if time > 60 then
						min = min + 1
						time = time - 60
					end
					if time < 10 then
						stime = "0" .. string.format("%.2f", time)
					else
						stime = string.format("%.2f", time)
					end
					ui.dwriteDrawText("Sector " .. sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.red)
					if pos3.x > sectors[s].end_.x and pos3.z > sectors[s].end_.y and pos3.x < sectors[s].end_.z and pos3.z < sectors[s].end_.w then
						if ac.getCar(0).distanceDrivenSessionKm - distance > sectors[s].lenght then
							sectors[s].active = false
							sectors[s].finished = true
							ac.sendChatMessage("Sector " .. sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime)
						end
					end
				end
				if sectors[s].finished == true then
					ui.dwriteDrawText("Sector " .. sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.green)
				end
			end)
		end)
	else
		ui.text("This MOD was made for the ACP server")
		ui.textHyperlink("https://discord.gg/acpursuit")
	end
end

-- ac.broadcastSharedEvent(key: string, data: string|any): integer // Returns number of listeners to the event with given key.
-- ac.onSharedEvent(key: string, callback: integer): lua_linked_id