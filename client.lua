-- Client hooks
module('client', package.seeall)

params = {}

local function add_to_history(url)
    if type(config.history) ~= "table" then config.history = {} end
    if type(config.history_size) ~= "number" then config.history_size = 16 end
    for k,v in ipairs(config.history) do
        if v == url then table.remove(config.history, k); break; end
    end
    table.insert(config.history, 1, url)
    table.remove(config.history, config.history_size+1)
end

function on_connect(url, pass, conn_params)
    log("IPservera: "..url)
    log("ParametrServ: "..conn_params)
    add_to_history(url)

    -- parse params
    params = {}
    local p = loadstring(conn_params)
    if p then
        setfenv(p, params)
        p() -- trusting setfenv here, without it it's a security hole.
    end

    -- display MOTD
    if params.motd then
        net.recv_chat(params.motd)
    end
end


--------------------------------------------------
-- load event callbacks

dofile('Scripts/net/events.lua')
