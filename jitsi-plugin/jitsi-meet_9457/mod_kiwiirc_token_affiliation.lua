local LOGLEVEL = "debug"

local is_admin = require "core.usermanager".is_admin
local is_healthcheck_room = module:require "util".is_healthcheck_room
local timer = require "util.timer"
module:log(LOGLEVEL, "loaded")

local function _is_admin(jid)
    return is_admin(jid, module.host)
end

module:hook("muc-occupant-joined", function (event)
    local room, occupant = event.room, event.occupant

    if is_healthcheck_room(room.jid) or _is_admin(occupant.jid) then
        module:log(LOGLEVEL, "skip affiliation, %s", occupant.jid)
        return
    end

    if not event.origin.auth_token then
        module:log(LOGLEVEL, "skip affiliation, no token")
        return
    end

    local affiliation = event.origin.jitsi_meet_affiliation;

    if affiliation == nil then
        return;
    end

    local i = 0
    local function setAffiliation()
        room:set_affiliation(true, occupant.bare_jid, affiliation)
        if i > 3 then return end

        i = i + 1
        timer.add_task(0.2 * i, setAffiliation)
    end
    setAffiliation()

    module:log("warn", "setting affiliation: '%s' for %s", room:get_affiliation(occupant.jid), occupant.jid)
end)
