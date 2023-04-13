local counter = 0
local cooldown = 5
local countDownState = {
	countdownOn = false,
	ready = true,
	set = true,
	go = true
}

local function printCountdown(text)
	if text == 'Ready' then
		countDownState.ready = false
	elseif text == 'Set' then
		countDownState.set = false
	elseif text == 'Go' then
		countDownState.go = false
	end
end

local function countdown()
	if cooldown < 2 and countDownState.ready == true then
		printCountdown('Ready')
	elseif cooldown < 1 and countDownState.set == true then
		printCountdown('Set')
	elseif cooldown == 0 and countDownState.go == true then
		printCountdown('Go')
		countDownState.countdownOn = false
	end
end

function script.windowMain(dt)
	if ui.button("Start Countdown") and countDownState.countdownOn == false then
		cooldown = 5
		countDownState.countdownOn = true
		countDownState.ready = true
		countDownState.set = true
		countDownState.go = true
	end
end

function script.update(dt)
	if cooldown > 0 then
		cooldown = cooldown - dt
	end
	if cooldown < 0 then
		cooldown = 0
	end
	if countDownState.countdownOn then
		countdown()
	end
end

