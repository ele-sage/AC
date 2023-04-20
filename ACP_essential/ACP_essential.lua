require("src/init")
require("src/settings")


INITIALIZED = false
RESTARTED = false

local sim = ac.getSim()
local data = {}
local serverIp = "95.211.222.135"
local firstLoad = true
local distance = 0
local time = 0
local timeSec = 0
local stime = ''
local min = 0
local s = 0

ac.onSessionStart(function(sessionIndex, restarted)
	if restarted then
		RESTARTED = true
		INITIALIZED = false
	end
end)


local function tabLocation()
	ui.text("Location: ")
end

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

local function tabSpeedTrap()

end

local function tabDriftZone()

end

local function tabSector(dt)
	local pos3 = ac.getCar(0).position

	if firstLoad then
		ui.dwriteDrawText("Sector NULL | time: 0:00:00", 30, vec2(10, 60), rgbm.colors.red)
	end
	for i = 1, #data.sectors do
		if pos3.x > data.sectors[i].start.x and pos3.z > data.sectors[i].start.y and pos3.x < data.sectors[i].start.z and pos3.z < data.sectors[i].start.w then
			time = 0
			min = 0
			for j = 1, #data.sectors do
				data.sectors[j].active = false
			end
			distance = ac.getCar(0).distanceDrivenSessionKm
			data.sectors[i].active = true
			data.sectors[i].finished = false
			s = i
			if s == i then
				break
			end
		end
	end
	if data.sectors[s].active == true then
		firstLoad = false
		time = time + dt
		timeSec = timeSec + dt
		if time > 60 then
			min = min + 1
			time = time - 60
		end
		if time < 10 then
			stime = "0" .. string.format("%.2f", time)
		else
			stime = string.format("%.2f", time)
		end
		ui.dwriteDrawText("Sector " .. data.sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.red)
		if pos3.x > data.sectors[s].finish.x and pos3.z > data.sectors[s].finish.y and pos3.x < data.sectors[s].finish.z and pos3.z < data.sectors[s].finish.w then
			if ac.getCar(0).distanceDrivenSessionKm - distance > data.sectors[s].lenght then
				data.sectors[s].active = false
				data.sectors[s].finished = true
				if data.sectors[s].pb > timeSec then
					data.sectors[s].pb = timeSec
				end
				ac.sendChatMessage("Sector " .. data.sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime)
			end
		end
	end
	if data.sectors[s].finished == true then
		ui.dwriteDrawText("Sector " .. data.sectors[s].name .. " | TIME: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.green)
	end
	ui.text(data.sectors[1].finish.x)
end

function script.windowMain(dt)
	if INITIALIZED then
		if serverIp == ac.getServerIP() then
			ui.tabBar('someTabBarID', function ()
				ui.tabItem('Location', tabLocation)
				ui.tabItem('camera', tabCamera)
				ui.tabItem('SpeedTrap', tabSpeedTrap)
				ui.tabItem('DriftZone', tabDriftZone)
				ui.tabItem('Sectors', function () tabSector(dt) end)
			end)
		else
			ui.text("This MOD was made for the ACP server")
			ui.textHyperlink("https://discord.com/invite/5Wka8QF")
		end
	else
		INITIALIZED = initialize(data)
		ui.text("Initializing...")
	end
end

function script.windowSettings()
	settingsMenu(sim)
end
