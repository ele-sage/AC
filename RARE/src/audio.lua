local audio = {}

local acMainVolume = ac.getAudioVolume(ac.AudioChannel.Main)

DRS_FLAP = ui.MediaPlayer()
DRS_BEEP = ui.MediaPlayer()

DRS_BEEP:setSource("./assets/audio/drs-available-beep.wav"):setAutoPlay(false)
DRS_BEEP:setVolume(acMainVolume * RARECONFIG.data.AUDIO.MASTER / 100 * RARECONFIG.data.AUDIO.DRS_BEEP / 100)

DRS_FLAP:setSource("./assets/audio/drs-flap.wav"):setAutoPlay(false)
DRS_FLAP:setVolume(acMainVolume * RARECONFIG.data.AUDIO.MASTER / 100 * RARECONFIG.data.AUDIO.DRS_FLAP / 100)

local function formula1(sim, driver)
	if driver.car.focusedOnInterior and sim.isWindowForeground then
		if sim.raceSessionType == ac.SessionType.Race then
			if driver.drsBeepFx and driver.car.drsAvailable and driver.drsAvailable then
				driver.drsBeepFx = false
				DRS_BEEP:play()
			elseif not driver.car.drsAvailable and driver.drsAvailable then
				driver.drsBeepFx = true
			end
		else
			if driver.drsBeepFx and driver.car.drsAvailable then
				driver.drsBeepFx = false
				DRS_BEEP:play()
			elseif not driver.car.drsAvailable then
				driver.drsBeepFx = true
			end
		end

		if driver.drsFlapFx ~= driver.car.drsActive then
			driver.drsFlapFx = driver.car.drsActive
			DRS_FLAP:play()
		end
	end
end

function audio.update(sim)
	local driver = DRIVERS[sim.focusedCar]
	formula1(sim, driver)
end

return audio
