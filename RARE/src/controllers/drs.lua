local drs = {}

DRS_ZONES = {}

---@class DRS_Points
---@param fileName string
---@return DRS_Points
DrsZones = class("DRS_Points", function()
	local drsIni = ac.INIConfig.trackData("drs_zones.ini")
	local detectionLines = {}
	local startLines = {}
	local endLines = {}

	local zoneCount = 0
	for index, section in drsIni:iterate("ZONE") do
		index = index - 1
		detectionLines[index] = drsIni:get(section, "DETECTION", -1)
		startLines[index] = drsIni:get(section, "START", -1)
		endLines[index] = drsIni:get(section, "END", -1)

		log(
			"Loaded DRS Zone "
				.. index
				.. " ["
				.. detectionLines[index]
				.. ","
				.. startLines[index]
				.. ","
				.. endLines[index]
				.. "]"
		)

		zoneCount = index
	end

	return {
		detectionLines = detectionLines,
		startLines = startLines,
		endLines = endLines,
		count = zoneCount,
	}
end, class.NoInitialize)

--- Checks if driver is before the detection line, not in the pits,
--- not in a drs zone, and within 1 second of the car ahead on track
---@param driver Driver
local function setDrsAvailable(driver, drsEnabled, drsEnabledLap)
	if drsEnabled and driver.car.lapCount + 1 >= drsEnabledLap and not driver.car.isInPitlane then
		local drsZones = DRS_ZONES
		local detectionLines = drsZones.detectionLines
		local startLines = drsZones.startLines
		local endLines = drsZones.endLines
		local driverSplinePosition = driver.car.splinePosition

		for i = 0, #startLines do
			local detectionLine = detectionLines[i]
			local startLine = startLines[i]
			local endLine = endLines[i]

			-- This handles when a DRS start zone is past the finish line after the detection zone
			if detectionLine > startLine then
				if driverSplinePosition >= 0 and driverSplinePosition < startLine then
					driverSplinePosition = driverSplinePosition + 1
				end
				startLine = startLine + 1
			end

			-- This handles when a DRS start zone is past the finish line after the detection zone
			if startLine > endLine then
				if driverSplinePosition >= 0 and driverSplinePosition < endLine then
					driverSplinePosition = driverSplinePosition + 1
				end
				endLine = endLine + 1
			end

			local isInDrsZone = driverSplinePosition >= detectionLine and driverSplinePosition < endLine
			local isInDrsActivationZone = isInDrsZone and driverSplinePosition >= startLine

			-- if driver.car.index == 10 then
			-- 	ac.debug("driver." .. i .. ".detectionLine", detectionLine)
			-- 	ac.debug("driver." .. i .. ".startLine", startLine)
			-- 	ac.debug("driver." .. i .. ".zendLine", endLine)
			-- 	ac.debug("driver.pos", driverSplinePosition)
			-- end

			if not isInDrsZone then
				driver.drsDetection[i] = inDrsRange(driver)
			elseif isInDrsActivationZone then
				driver.drsZoneId = i
				driver.drsZoneNextId = i == #startLines and 0 or i + 1
				driver.drsZonePrevId = i == 0 and #startLines or i - 1
			end
		end

		return driver.drsDetection[driver.drsZoneId]
	else
		return false
	end
end

--- Converts session type number to the corresponding session type string
---@param driver Driver
local function setDriverDrsZones(driver)
	local startLines = DRS_ZONES.startLines
	local endLines = DRS_ZONES.endLines
	local closestDetection = 0
	local drsZoneNext = 0
	local drsZone = 0
	local drsZonePrev = 0

	--- Get next detection line
	for i = 0, #startLines do
		if driver.car.splinePosition >= startLines[i] and driver.car.splinePosition < endLines[i] then
			drsZone = i
		end
	end

	drsZone = drsZoneNext == 0 and #startLines or drsZoneNext - 1
	drsZonePrev = drsZone == 0 and #startLines or drsZone - 1

	driver.drsZoneNextId = drsZoneNext
	driver.drsZoneId = drsZone
	driver.drsZonePrevId = drsZonePrev
end

--- Locks the specified driver's DRS
---@param driver Driver
local function setDriverDRS(sim, driver, allowed)
	if not sim.isOnlineRace then
		physics.allowCarDRS(driver.index, not allowed)
	end

	if driver.car.isAIControlled then
		if not allowed then
			physics.setCarDRS(driver.index, false)
		elseif allowed and driver.car.speedKmh > 100 and getEndLineDistanceM(driver) > 175 and not driver.aiPitCall then
			physics.setCarDRS(driver.index, true)
		end
	elseif not allowed then
		ac.setDRS(false)
	end
end

--- Checks if delta is within 1 second
---@param driver Driver
---@return boolean
function inDrsRange(driver1)
	local delta = driver1.carAheadDelta
	local deltaLimit = RARECONFIG.data.RULES.DRS_GAP_DELTA / 1000
	return (delta <= deltaLimit and delta > 0.0) and true or false
end

function inDeployZone(driver)
	local zones = DRS_ZONES
	local track_pos = driver.car.splinePosition
	local detection_line = zones.detectionLines[driver.drsZoneId]
	local start_line = zones.startLines[driver.drsZonePrevId]

	-- This handles when a DRS start zone is past the finish line after the detection zone
	if detection_line > start_line then
		if track_pos >= 0 and track_pos < start_line then
			track_pos = track_pos + 1
		end
		start_line = start_line + 1
	end

	-- If driver is between the end zone of the previous DRS zone, and the detection line of the upcoming DRS zone
	return (track_pos >= detection_line and track_pos < start_line) and true or false
end

--- Returns the main driver's distance to the detection line in meters
---@param driver Driver
---@return number
function getZoneLineDistanceM(zones, driver, drsZoneId)
	local sim = ac.getSim()
	local zoneLine = zones[drsZoneId]
	local distance = zoneLine - driver.car.splinePosition
	if distance <= 0 then
		distance = distance + 1
	end
	return math.round(math.clamp(distance * sim.trackLengthM, 0, 10000), 5)
end

--- Returns the main driver's distance to the detection line in meters
---@param driver Driver
---@return number
function getDetectionLineDistanceM(driver)
	return getZoneLineDistanceM(DRS_ZONES.detectionLines, driver, driver.drsZoneNextId)
end

--- Returns the main driver's distance to the detection line in meters
---@param driver Driver
---@return number
function getStartLineDistanceM(driver)
	return getZoneLineDistanceM(DRS_ZONES.startLines, driver, driver.drsZoneNextId)
end

--- Returns the main driver's distance to the detection line in meters
---@param driver Driver
---@return number
function getEndLineDistanceM(driver)
	local endLinesDistanceM = getZoneLineDistanceM(DRS_ZONES.endLines, driver, driver.drsZoneId)
	local startLinesDistanceM = getZoneLineDistanceM(DRS_ZONES.startLines, driver, driver.drsZoneNextId)

	return startLinesDistanceM < endLinesDistanceM
			and getZoneLineDistanceM(DRS_ZONES.endLines, driver, driver.drsZoneNextId)
		or getZoneLineDistanceM(DRS_ZONES.endLines, driver, driver.drsZoneId)
end

--- Returns whether driver is between a detection line and a start line
---@param driver Driver
---@return bool
function crossedDetectionLine(driver)
	local zones = DRS_ZONES
	local track_pos = driver.car.splinePosition
	local detection_line = zones.detectionLines[driver.drsZoneId]
	local start_line = zones.startLines[driver.drsZoneId]

	-- This handles when a DRS start zone is past the finish line after the detection zone
	if detection_line > start_line then
		if track_pos >= 0 and track_pos < start_line then
			track_pos = track_pos + 1
		end

		start_line = start_line + 1
	end

	-- If driver is between the end zone of the previous DRS zone, and the detection line of the upcoming DRS zone
	if track_pos >= detection_line and track_pos < start_line then
		return true
	else
		return false
	end
end

--- Control driver's DRS deployment
--- @param driver Driver
--- @param drsEnabled boolean
function drs.controller(rc, driver, drsEnabled)
	-- setDriverDrsZones(driver)
	driver.drsAvailable = setDrsAvailable(driver, drsEnabled, rc.drsEnabledLap)
	setDriverDRS(rc.sim, driver, drsEnabled and driver.drsAvailable or false)
end

return drs
