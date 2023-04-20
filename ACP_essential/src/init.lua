local function getSectors()
	local speedTrapsIni = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/ACP_essential/data/sectors.ini", ac.INIFormat.Default)
	local sectors = {}
	
	for index, section in speedTrapsIni:iterate("SECTOR") do
		local sector = {}
		sector.name = speedTrapsIni:get(section, "NAME", "Unknown Sector")
		sector.start = vec4(
			speedTrapsIni:get(section, "START_X", 0),
			speedTrapsIni:get(section, "START_Y", 0),
			speedTrapsIni:get(section, "START_Z", 0),
			speedTrapsIni:get(section, "START_W", 0)
		)
		sector.finish = vec4(
			speedTrapsIni:get(section, "FINISH_X", 0),
			speedTrapsIni:get(section, "FINISH_Y", 0),
			speedTrapsIni:get(section, "FINISH_Z", 0),
			speedTrapsIni:get(section, "FINISH_W", 0)
		)
		sector.length = speedTrapsIni:get(section, "LENGTH", 0)
		sector.pb = speedTrapsIni:get(section, "PB", 0)
		sector.png_path = speedTrapsIni:get(section, "PNG_PATH", "")
		sector.index = index - 1
		sector.active = false
		sector.finished = false
		table.insert(sectors, sector)
	end
	return sectors
end

local function getSpeedTraps()
	local speedTrapsIni = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/ACP_essential/data/speedtraps.ini", ac.INIFormat.Default)
	local speedTraps = {}
	
	for index, section in speedTrapsIni:iterate("SPEEDTRAP") do
		local speedTrap = {}
		speedTrap.name = speedTrapsIni:get(section, "NAME", "Unknown Speed Trap")
		speedTrap.pos = vec4(
			speedTrapsIni:get(section, "POS_X", 0),
			speedTrapsIni:get(section, "POS_Y", 0),
			speedTrapsIni:get(section, "POS_Z", 0),
			speedTrapsIni:get(section, "POS_W", 0)
		)
		speedTrap.pb = speedTrapsIni:get(section, "PB", 0)
		speedTrap.png_path = speedTrapsIni:get(section, "PNG_PATH", "")
		speedTrap.index = index - 1
		table.insert(speedTraps, speedTrap)
	end
	return speedTraps
end

local function getDriftZones()
	local driftZonesIni = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/ACP_essential/data/driftzones.ini", ac.INIFormat.Default)
	local driftZones = {}

	for index, section in driftZonesIni:iterate("DRIFTZONE") do
		local driftZone = {}
		driftZone.name = driftZonesIni:get(section, "NAME", "Unknown Drift Zone")
		driftZone.pos = vec4(
			driftZonesIni:get(section, "POS_X", 0),
			driftZonesIni:get(section, "POS_Y", 0),
			driftZonesIni:get(section, "POS_Z", 0),
			driftZonesIni:get(section, "POS_W", 0)
		)
		driftZone.radius = driftZonesIni:get(section, "RADIUS", 0)
		driftZone.pb = driftZonesIni:get(section, "PB", 0)
		driftZone.png_path = driftZonesIni:get(section, "PNG_PATH", "")
		driftZone.index = index - 1
		table.insert(driftZones, driftZone)
	end
	return driftZones
end

local function loadData(data)
	data.sectors = getSectors()
	data.speedTraps = getSpeedTraps()
	data.driftZones = getDriftZones()
end

local function initDataDir()
	local rareDataDir = ac.getFolder(ac.FolderID.ACApps) .. "/lua/ACP_essential/data"
	if not io.dirExists(rareDataDir) then
		io.createDir(rareDataDir)
	end
end


--- Initialize ACP Essential and returns initialized state
--- @return boolean
function initialize(data)
	initDataDir()
	loadData(data)

	FIRST_LAUNCH = false
	return true
end
