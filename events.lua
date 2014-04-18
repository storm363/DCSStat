--[[
Network game callbacks.

]]

local function translate(str)
	if str ~= "" then
		return gettext.translate(str)
	else
		return ""
	end
end

local function dtranslate(dom, str)
	if str ~= "" then
		return gettext.dtranslate(dom, str)
	else
		return ""
	end
end

_ = translate

local players = {}
local unit2player = {}


local function unit_property(unit, prop)
	return net.get_unit_property(unit, prop) or ""
end

local function select_by_side(side, red, blue, spec)
	if side == 1 then return red
	elseif side == 2 then return blue
	else return spec end
end

local get_name = function(id)
	local p = players[id]
	if p then return p.name end
	log(string.format("UNKNOWN PLAYER"))
	return _("UNKNOWN PLAYER")
	--return net.get_name(id)
end

local report = function(msg, ...)
	net.recv_chat(string.format(msg, ...))
end

local player_info_noside = function(id)
	return '"'..get_name(id)..'"';
end

local player_info = function(id)
	local p = players[id]
	if not p then return _("UNKNOWN PLAYER") end
	log(string.format(select_by_side(players[id].side, _("RED player"), _("BLUE player"), _("SPECTATOR")) .. ' "' .. p.name .. '"'))
	return select_by_side(players[id].side, _("RED player"), _("BLUE player"), _("SPECTATOR")) .. ' "' .. p.name .. '"'
end

local unit_info = function(unit)
	return dtranslate("missioneditor", unit_property(unit, 4))
end

local bot_info = function(unit)
	local info = unit_property(unit, 14)
	if info == "" then info = unit_info(unit) end
	if info == "" then return info end
	return '"'..info..'"'
end

local weapon_info = function(weapon)
	return dtranslate("missioneditor", weapon)
end


-- called when simulation starts
function on_start()
	-- TODO: move this to client.on_connect
	local myid = net.get_local_id()
	local myname = net.get_name(myid)
	players[myid] = { name = myname }
	log(string.format("DCSStat_id=%d, DCSStat_name=%q", myid, myname))
end

-- called when simulation stops
function on_stop()
end

-- called on client only.
function on_pause()
-- net.send_chat(1, "/pause")
end

-- called on client only.
function on_resume()
-- net.send_chat(1, "/resume")
end

function on_player_add(id, name_)
	players[id] = { name = name_ }
	report(_("%s entered the game."), player_info_noside(id))
end

function on_player_name(id, name)
	report(_("%s changed name to %q."), player_info(id), name)
	players[id].name = name
end

-- not implemented
--function on_player_spawn(id)
--end

function on_player_slot(id, side, unit)
	local p = players[id]
	if p then
		if p.unit then unit2player[p.unit] = nil end
		p.side = side
		p.unit = unit
	end
	local unit_name
	if unit ~= "" then
		unit2player[unit] = p
		unit_name = net.get_unit_display_name(unit)
	end
	if not unit_name then unit_name = "" end
	log(string.format("DCSStat_info=%s joined in DCSStat_plane=%s.", player_info_noside(id), unit_name))
	report(select_by_side(side,
		_("%s joined RED in %s."),
		_("%s joined BLUE in %s."),
		_("%s joined SPECTATORS."))
		, player_info_noside(id), unit_name)
end

function on_player_stat(id, stat, value)
end

function on_player_del(id)
	report(_("%s left the game."), player_info(id))
	local p = players[id]
	if p then
		local unit = p.unit
		if unit then unit2player[unit] = nil end
		players[id] = nil
	end
end

function on_eject(id)
log(string.format("DCSStat_eject=%s", player_info(id)))
	report(_("DCSStat_eject=%s"), player_info(id))
end

function on_crash(id)
log(string.format("DCSStat_crush=%s", player_info(id)))
	report(_("%s crashed."), player_info(id))
end

function on_takeoff(id, airdrome)
	if airdrome ~= "" then
	log(string.format("%s took off from %s.", player_info(id), airdrome))
		report(_("%s took off from %s."), player_info(id), dtranslate("missioneditor", airdrome))
	else
	log(string.format("%s took off."), player_info(id))
		report(_("%s took off."), player_info(id))
	end
end

function on_landing(id, airdrome)
		log(string.format("%s landed", player_info(id)))
	report(_("%s landed at %s."), player_info(id), dtranslate("missioneditor", airdrome))
end

function on_kill(id, weapon, victim)
	local victimName = bot_info(victim) 
	if victimName == "" then victimName = _("Building") end
	
	if weapon ~= "" then
		report(_("%s killed %s with %s."), player_info(id), victimName, weapon_info(weapon))
	else
		report(_("%s killed %s."), player_info(id), victimName)
	end
end

function on_mission_end(winner, msg)
	if winner == "" then
		local red_score = net.check_mission_result("red")
		local blue_score = net.check_mission_result("blue")
		net.recv_chat(string.format(_("Mission ended, RED score = %f, BLUE score = %f"), red_score, blue_score))
	else
		local text
		if winner == "RED" then text = _("Mission ended, RED won.")
		elseif winner == "BLUE" then text = _("Mission ended, BLUE won.")
		else text = _("Mission ended.") end
		net.recv_chat(text)
		if msg ~= "" then net.recv_chat(msg) end
	end
end

function on_damage(shooter_objid, weapon_objid, victim_objid)
	local shooter_id = net.get_unit_property(shooter_objid, 2)
	local weapon_id = net.get_unit_property(weapon_objid, 2)
	local offence_player = unit2player[shooter_id] or unit2player[weapon_id]

	local victim_id = net.get_unit_property(victim_objid, 2)
	local defence_player = unit2player[victim_id]

	if offence_player and defence_player then
		if offence_player.side == defence_player.side then
			net.recv_chat(string.format(_("%s team-damaged %s"), offence_player.name, defence_player.name))
		end
	end
end

--В случае столкновения с землёй, зданием или обломками другого самолёта, пишем что игрок мёртв
--не указывая, что его убило здание
function on_kill_player(id, weapon, killa)
	local killerName = bot_info(killa)
	if weapon ~= "" then
		report(_("%s killed %s with %s."), bot_info(killa), player_info(id), weapon_info(weapon))
	elseif killerName ~= "" then
			report(_("%s killed %s."), killerName, player_info(id))
	else
			report(_("%s is dead."), player_info(id))
	end
end

---
log('events.lua loaded')
