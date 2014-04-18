function LuaExportBeforeNextFrame()
local Timers       = LoGetModelTime() 
local name = LoGetPilotName()
local Alt = LoGetAltitudeAboveGroundLevel()
	if Alt>2.0 then	
		log(string.format("playerfly"))
	else 
		log(string.format("playerground"))
	end
end