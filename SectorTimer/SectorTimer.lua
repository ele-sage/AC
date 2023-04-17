-- Author: 	Emile Le Sage
-- Date: 	2023-04-15

-- This script is made to create timer for deffined sector of a map
-- It allows you time deffined sectors of the track
-- I can also add checkpoints to each sector

-- This script is a work in progress, and will be updated in the future
local h2 = {
	name = "H2",
	start = vec4(1685,604,1695,610),
	end_ = vec4(1566,732,1574,748),
	time = 0,
	active = false,
	finished = false
}

local h3 = {
	name = "H3",
	start = vec4(-186,-120,-184,-118),
	end_ = vec4(162,307,164,329),
	time = 0,
	active = false,
	finished = false
}

local drag = {
	name = "Drag",
	start = vec4(-183,1341,-181,1420),
	end_ = vec4(-859,1341,-855,1420),
	time = 0,
	active = false,
	finished = false
}

local touge = {
	name = "Touge",
	start = vec4(-3962,9982,-3949,9989),
	end_ = vec4(-5660,10250,-5649,10253),
	time = 0,
	active = false,
	finished = false
}

local firstLoad = true
local stime = ''
local min = 0
local s = 0
local sector = {
	h2,
	h3,
	drag,
	touge
}

local function tabH2()
	ui.drawImage("H2.png", vec2(0,80), vec2(560,400))
end

local function tabH3()
	ui.drawImage("H3.png", vec2(0,80), vec2(560,400))
end

local function tabDrag()
	ui.drawImage("Drag.png", vec2(0,80), vec2(560,400))
end

local function tabTouge()
	ui.drawImage("Touge.png", vec2(0,80), vec2(560,400))
end

local function tabRoute()
	ui.tabBar('someTabBarID', function ()
		ui.tabItem('H2', tabH2)	
		ui.tabItem('H3', tabH3)
		ui.tabItem('Drag', tabDrag)
		ui.tabItem('Touge', tabTouge)
	end)
end

function script.windowMain(dt)

	ui.tabBar('someTabBarID', function ()
		ui.tabItem('Route', tabRoute)
		ui.tabItem('Sector', function ()
			local pos3 = ac.getCar(0).position

			if firstLoad then
				ui.dwriteDrawText("Sector NULL | time: 0:00:00", 30, vec2(10, 60), rgbm.colors.red)
			end
			for i = 1, #sector do
				if pos3.x > sector[i].start.x and pos3.z > sector[i].start.y and pos3.x < sector[i].start.z and pos3.z < sector[i].start.w then
					sector[i].time = 0
					min = 0
					for j = 1, #sector do
						sector[j].active = false
					end
					sector[i].active = true
					sector[i].finished = false
					s = i
					if s == i then
						break
					end
				end
			end
			if sector[s].active == true then
				firstLoad = false
				sector[s].time = sector[s].time + dt
				if sector[s].time > 60 then
					min = min + 1
					sector[s].time = sector[s].time - 60
				end
				if sector[s].time < 10 then
					stime = "0" .. string.format("%.2f", sector[s].time)
				else
					stime = string.format("%.2f", sector[s].time)
				end
				ui.dwriteDrawText("Sector " .. sector[s].name .. " | time: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.red)
				if pos3.x > sector[s].end_.x and pos3.z > sector[s].end_.y and pos3.x < sector[s].end_.z and pos3.z < sector[s].end_.w then
					sector[s].active = false
					sector[s].finished = true
					ac.sendChatMessage("Sector " .. sector[s].name .. " | time: " .. string.format("%.2f",sector[s].time))
				end
			end
			if sector[s].finished == true then
				ui.dwriteDrawText("Sector " .. sector[s].name .. " | time: " .. string.format("%d:", min) .. stime, 30, vec2(10, 60), rgbm.colors.green)
			end
		end)
	end)
end