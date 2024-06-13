local LOGLEVEL = "debug";

local is_admin = require "core.usermanager".is_admin;
local is_healthcheck_room = module:require "util".is_healthcheck_room;
local timer = require "util.timer";
local st = require "util.stanza";
local it = require "util.iterators";

local kiwi_util = module:require "kiwiirc_util";

module:log(LOGLEVEL, "loaded");

local function _is_admin(jid)
    return is_admin(jid, module.host);
end

module:hook("muc-occupant-pre-join", function(event)
    local allow_guest_create = kiwi_util.get_kiwiirc_env("KIWIIRC_ALLOW_GUEST_CREATE");

    if allow_guest_create then
        return;
    end

    local room, origin, stanza = event.room, event.origin, event.stanza;
    if not event.is_new_room then
        local affiliation = origin.jitsi_meet_affiliation;
        local participant_count = it.count(room:each_occupant());
        local auth_domain = kiwi_util.get_kiwiirc_env("XMPP_AUTH_DOMAIN") or "auth.meet.jitsi";
        local has_affiliate = false;

        if affiliation ~= nil then
            -- User is an affiliate meaning they authed with jwt token
            has_affiliate = true;
        else
            -- User is a guest
            for _, o in room:each_occupant() do
                -- Check current members for a user who authed with jwt token
                if o.bare_jid:match("^focus@" .. auth_domain) == nil and room:get_affiliation(o.jid) ~= nil then
                    has_affiliate = true;
                end
            end
        end

        if not has_affiliate then
            -- User is a guest and no irc users are present
            origin.send(st.error_reply(stanza, "cancel", "service-unavailable", "No IRC user is present in conference room"));
            return true;
        end
    end
end)

module:hook("muc-occupant-joined", function (event)
    local room, occupant = event.room, event.occupant;

    if is_healthcheck_room(room.jid) or _is_admin(occupant.jid) then
        module:log(LOGLEVEL, "skip affiliation, %s", occupant.jid);
        return;
    end

    if not event.origin.auth_token then
        module:log(LOGLEVEL, "skip affiliation, no token");
        return;
    end

    local affiliation = event.origin.jitsi_meet_affiliation;

    if affiliation == nil then
        return;
    end

    local i = 0
    local function setAffiliation()
        room:set_affiliation(true, occupant.bare_jid, affiliation)
        if i > 3 then return end;

        i = i + 1;
        timer.add_task(0.2 * i, setAffiliation);
    end
    setAffiliation()

    module:log(LOGLEVEL, "replacing affiliation: '%s' with '%s' for %s", room:get_affiliation(occupant.jid), affiliation, occupant.jid)
end)
