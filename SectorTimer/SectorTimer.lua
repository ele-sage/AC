-- Author: 	Emile Le Sage
-- Date: 	2023-04-15

-- This script is made to create timer for deffined sectors of a map
-- It allows you time deffined sectors of the track
-- I can also add checkpoints to each sectors

-- This script is a work in progress, and will be updated in the future

local serverIp = "95.211.222.135"

local firstLoad = true
local distance = 0
local time = 0
local stime = ''
local min = 0
local s = 0
local sectors = {}
local speedTraps = {}
local driftZone = {}
local first = true

local function tabLocation()

end

local function tabCamera()
	if ac.getSim().cameraMode == ac.CameraMode.Free then
		local pos3 = ac.getCameraPosition()
		local dir3 = ac.getCameraForward()

		ui.text("Camera position: " .. pos3.x .. ", " .. pos3.y .. ", " .. pos3.z)
		ui.text("Camera direction: " .. dir3.x .. ", " .. dir3.y .. ", " .. dir3.z)
		if ui.button("Get camera position") then
			ac.setClipboadText("vec3(" .. pos3.x .. ", " .. pos3.y .. ", " .. pos3.z .. ")\nvec3(" .. dir3.x .. ", " .. dir3.y .. ", " .. dir3.z .. ")")
		end
	end
end

local function tabSpeedTrap()
	local car = ac.getCar(0)

	for i = 1, #speedTraps do
		if car.position.x > speedTraps[i].location.x and car.position.z > speedTraps[i].location.y and car.position.x < speedTraps[i].location.z and car.position.z < speedTraps[i].location.w then
			if car.speedKmh > speedTraps[i].PB then
				speedTraps[i].PB = car.speedKmh
			end
		end
		ui.dwriteDrawText(speedTraps[i].NAME, 20, vec2(20, i*30 + 50), rgbm.colors.withe)
		ui.dwriteDrawText(string.format("Speed:  %.2f", car.speedKmh) .."km/h\n", 20, vec2(250, i*30 + 50), rgbm.colors.green)
	end
end

local function tabDriftZone()
	local car = ac.getCar(0)

	for i = 1, #driftZone do
		if car.position.x > driftZone[i].location.x and car.position.z > driftZone[i].location.y and car.position.x < driftZone[i].location.z and car.position.z < driftZone[i].location.w then
			driftZone[i].speed = car.speedKmh
		end
		ui.dwriteDrawText(driftZone[i].NAME, 20, vec2(20, i*30 + 50), rgbm.colors.withe)
		ui.dwriteDrawText(string.format("Speed:  %.2f", driftZone[i].speed) .."km/h\n", 20, vec2(250, i*30 + 50), rgbm.colors.green)
	end
end

local function tabSector(dt)
	local pos3 = ac.getCar(0).position

	if firstLoad then
		ui.dwriteDrawText("Sectors NULL | time: 0:00:00", 30, vec2(10, 60), rgbm.colors.red)
	end
	for i = 1, #sectors do
		if pos3.x > sectors[i].start.x and pos3.z > sectors[i].start.y and pos3.x < sectors[i].start.z and pos3.z < sectors[i].start.w then
			sectors[i].time = 0
			min = 0
			for j = 1, #sectors do
				sectors[j].ACTIVE = false
			end
			distance = ac.getCar(0).distanceDrivenSessionKm
			sectors[i].ACTIVE = true
			sectors[i].FINISHED = false
			s = i
			if s == i then
				break
			end
		end
	end
	if sectors[s].ACTIVE == true then
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
		ui.dwriteDrawText("Sector " .. sectors[s].NAME .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.red)
		if pos3.x > sectors[s].END.x and pos3.z > sectors[s].END.y and pos3.x < sectors[s].END.z and pos3.z < sectors[s].END.w then
			if ac.getCar(0).distanceDrivenSessionKm - distance > sectors[s].lenght then
				sectors[s].ACTIVE = false
				sectors[s].FINISHED = true
				if sectors[s].PB == 0 or sectors[s].PB < time then
					sectors[s].PB = time
					ac.sendChatMessage("Sector " .. sectors[s].NAME .. " | TIME: " .. string.format("%d:", min) .. stime .. " New PB!")
				end
			end
		end
	end
	if sectors[s].FINISHED == true then
		ui.dwriteDrawText("Sector " .. sectors[s].NAME .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.green)
	end
end

local function loadSectors(ini)
	for a, b in ini:iterateValues('SECTOR_TIMER', 'SECTOR') do
		local n = tonumber(b:match('%d+')) + 1

		if sectors[n] == nil then
			for i = #sectors, n do
				if sectors[i] == nil then sectors[i] = {} end
			end
		end
		local suffix = b:match('_(%a+)$')
		if suffix==nil then sectors[n]['NAME'] = ini:get('SECTOR_TIMER', b, '')
		elseif suffix == 'START' then sectors[n]['START'] = ini:get('SECTOR_TIMER', b, vec4())
		elseif suffix == 'END' then sectors[n]['END'] = ini:get('SECTOR_TIMER', b, vec4())
		elseif suffix == 'PB' then sectors[n]['PB'] = ini:get('SECTOR_TIMER', b, 0)
		elseif suffix == 'PNG' then sectors[n]['PNG'] = ini:get('SECTOR_TIMER', b, '')
		end
		sectors[n]['ACTIVE'] = false
		sectors[n]['FINISHED'] = false
	end
end

local function loadSpeedTraps(ini)
	for a, b in ini:iterateValues('SPEED_TRAPS', 'SPEEDTRAP') do
		local n = tonumber(b:match('%d+')) + 1

		if speedTraps[n] == nil then
			for i = #speedTraps, n do
				if speedTraps[i] == nil then speedTraps[i] = {} end
			end
		end
		local suffix = b:match('_(%a+)$')
		if suffix==nil then speedTraps[n]['NAME'] = ini:get('SPEED_TRAPS', b, '')
		elseif suffix == 'POS' then speedTraps[n]['POS'] = ini:get('SPEED_TRAPS', b, vec4())
		elseif suffix == 'PB' then speedTraps[n]['PB'] = ini:get('SPEED_TRAPS', b, 0)
		elseif suffix == 'PNG' then speedTraps[n]['PNG'] = ini:get('SPEED_TRAPS', b, '')
		end
	end
end

local function loadDriftZone(ini)
	for a, b in ini:iterateValues('DRIFT_ZONE', 'DRIFTZONE') do
		local n = tonumber(b:match('%d+')) + 1

		if driftZone[n] == nil then
			for i = #driftZone, n do
				if driftZone[i] == nil then driftZone[i] = {} end
			end
		end
		local suffix = b:match('_(%a+)$')
		if suffix==nil then driftZone[n]['NAME'] = ini:get('DRIFT_ZONE', b, '')
		elseif suffix == 'POS' then driftZone[n]['POS'] = ini:get('DRIFT_ZONE', b, vec4())
		elseif suffix == 'PB' then driftZone[n]['PB'] = ini:get('DRIFT_ZONE', b, 0)
		elseif suffix == 'PNG' then driftZone[n]['PNG'] = ini:get('DRIFT_ZONE', b, '')
		end
	end
end

local function onShowWindow()
	if first then
		local onlineExtras = ac.INIConfig.onlineExtras()
		loadSectors(onlineExtras)
		loadSpeedTraps(onlineExtras)
		loadDriftZone(onlineExtras)
	first = false
	end
end

function script.windowMain(dt)
	if serverIp == ac.getServerIP() then
		onShowWindow()
		ui.tabBar('someTabBarID', function ()
			ui.tabItem('Location', tabLocation)
			ui.tabItem('camera', tabCamera)
			ui.tabItem('SpeedTrap', tabSpeedTrap)
			ui.tabItem('DriftZone', tabDriftZone)
			ui.tabItem('Sectors', tabSector(dt))
		end)
	else
		ui.text("This MOD was made for the ACP server")
		ui.textHyperlink("https://discord.com/invite/5Wka8QF")
	end
end

-- ac.broadcastSharedEvent(key: string, data: string|any): integer // Returns number of listeners to the event with given key.
-- ac.onSharedEvent(key: string, callback: integer): lua_linked_id