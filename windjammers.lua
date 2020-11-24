function Usage()
	print "Very basic Windjammers training script made by peon2 for Heritage for our Future"
	print "Lua Macro 1 or C to try and put the disc in p1's hands"
	print "Lua Macro 2 or D to toggle the throw timer for p1 and enable free movement"
	print "Lua Macro 3 or Select to toggle between players"
end

Usage()


rb, rw = memory.readbyte, memory.readword
wb, ww = memory.writebyte, memory.writeword

--global timer word 0x100058

--0x100a00 is UID disc?
--0x100a07 -- disc x
--0x100a0b -- disc y

--0x100800 is UID p1?
--0x100807 -- p1 x
--0x10080b -- p1 y
--0x10083b -- p1 throw timer

--0x100880 is UID p2?
--0x100887 -- p1 x
--0x10088b -- p1 y
--0x10088b -- p1 throw timer
function zerop1Score()
	wb(0x100873, 0)
end

function zerop2Score()
	wb(0x1008f3, 0)
end

function infiniteTime()
	wb(0x10008d, 39)
end

local throwtimer = true

local p1 = {
	x,
	y,
	state,
	throwtimer,
}

local p2 = {
	x,
	y,
	state,
	throwtimer,
}

local disc = {
	x,
	y,
}

function readMemoryAddresses()
	p1.x = rw(0x100806)
	p1.y = rw(0x10080a)
	p1.state = rb(0x100820) -- 1 -> facing away, 128 -> has thrown?? 32 -> holding 36 -> catching or throwing
	p1.throwtimer = rb(0x10083b)
	
	p2.x = rw(0x100886)
	p2.y = rw(0x10088a)
	p2.state = rb(0x1008a0)
	p2.throwtimer = rb(0x1008bb) 
end

function setToPlayer()
	if rb(0x100a28) == 255 then -- throw direction I think. Don't write to this
		ww(0x100a06, p1.x)
		ww(0x100a0a, p1.y)
	else
		ww(0x100a06, p2.x)
		ww(0x100a0a, p2.y)
	end
end

function toggleThrowTimer()
	throwtimer = not throwtimer
end

function toggleSetPlayer()
	toggleswapplayer = not toggleswapplayer
end

local previousbuttonC = false
local previousbuttonD = false

local inputs

function inputCheck()
	inputs = joypad.get()
	
	if inputs["P1 Button C"] and not previousbuttonC then
		setToPlayer()
	end
	
	if inputs["P1 Button D"] and not previousbuttonD then
		toggleThrowTimer()
	end
	
	if inputs["P1 Select"] and not previousbuttonselect then
		toggleSetPlayer()
	end
	
	previousbuttonC = inputs["P1 Button C"]
	previousbuttonD = inputs["P1 Button D"]
	previousbuttonselect = inputs["P1 Select"]
end

function swapInputs()

	if not toggleswapplayer then return end
	
	local player
	local input
	local t = {}
	for i,v in pairs(inputs) do
		player = i:sub(1,2)
		input = i:sub(4)
		if player == "P1" then
			t["P2 "..input] = v
		elseif player == "P2" then
			t["P1 "..input] = v
		else
			t[i] = v
		end
	end
	inputs = t
	joypad.set(inputs)
end

function throwTimerHandler()
	if not throwtimer then
	
		if (not toggleswapplayer) and (p1.state ~= 32 and p1.state ~= 36) then return end
		if toggleswapplayer and (p2.state ~= 33 and p2.state ~= 37) then return end
		
		local player = "P1"
		if toggleswapplayer then player = "P2" end
		
		if not toggleswapplayer then
			wb(0x10083b,0)
		else
			wb(0x1008bb,0)
		end
		
		if inputs[player.." Up"] then
			if toggleswapplayer then
				ww(0x10088a, p2.y - 1)
			else
				ww(0x10080a, p1.y - 1)
			end
		end
		if inputs[player.." Down"] then
			if toggleswapplayer then
				ww(0x10088a, p2.y + 1)
			else
				ww(0x10080a, p1.y + 1)
			end
		end
		if inputs[player.." Left"] then
			if toggleswapplayer then
				ww(0x100886, p2.x - 1)
			else
				ww(0x100806, p1.x - 1)
			end
		end
		if inputs[player.." Right"] then
			if toggleswapplayer then
				ww(0x100886, p2.x + 1)
			else
				ww(0x100806, p1.x + 1)
			end
		end
	end
end

function Run()

	throwTimerHandler()
	
	readMemoryAddresses()
	infiniteTime()
	zerop1Score()
	zerop2Score()
	
	gui.text(p1.x-26, p1.y+10,"x:"..p1.x)
	gui.text(p1.x-4, p1.y+10,"y:"..p1.y)
	gui.text(p1.x-20, p1.y+20,"("..p1.throwtimer.."/57)")
	
	gui.text(p2.x-26, p2.y+10,"x:"..p2.x)
	gui.text(p2.x-4, p2.y+10,"y:"..p2.y)
	gui.text(p2.x-20, p2.y+20,"("..p2.throwtimer.."/57)")
end

input.registerhotkey(1, setToPlayer)
input.registerhotkey(2, toggleThrowTimer)
input.registerhotkey(3, toggleSetPlayer)

emu.registerbefore(function() inputCheck() swapInputs() end)
gui.register(Run)