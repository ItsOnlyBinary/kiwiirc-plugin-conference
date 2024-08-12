local timer = require "util.timer";

function on_joined (event)
    local room, occupant = event.room, event.occupant;

    local affiliation = event.origin.jitsi_meet_affiliation;

    -- Possible values for affiliation are "owner", "admin", "member", "outcast" (banned) and "none" (no affiliation).
    -- local valid_roles = { "none", "visitor", "participant", "moderator" };
    -- module:log("warn", "dump:", getKeysAsString(event));
    -- room:set_affiliation(true, occupant.bare_jid, affiliation);
    if affiliation == nil then

        return;
    end
    occupant["affiliation"] = affiliation;
    module:log("warn", "on_joined affiliation = '%s', role = '%s' for %s", affiliation, occupant.role, occupant.jid);
    room:set_affiliation(true, occupant.bare_jid, affiliation);

    timer.add_task(0.5, function()
        -- room:set_affiliation(true, occupant.bare_jid, affiliation);
        module:log("warn", "timer affiliation = '%s', role = '%s' for %s", room:get_affiliation(occupant.bare_jid), occupant.role, occupant.jid);
    end)
end

function on_prejoined(event)
    local room, occupant = event.room, event.occupant;
    module:log("warn", "on_pre-join role = '%s' for %s", occupant.role, occupant.jid);
end

module:hook("muc-occupant-joined", on_joined, -1);
module:hook("muc-occupant-pre-join", on_prejoined, 1);

-- function dumpVariable(variable, indent, visited)
--     indent = indent or ""
--     visited = visited or {}
--     if type(variable) == "table" then
--         if visited[variable] then
--             return "<circular reference>"
--         end
--         visited[variable] = true

--         local str = "{\n"
--         local innerIndent = indent .. "    "
--         for k, v in pairs(variable) do
--             str = str .. innerIndent .. "[" .. tostring(k) .. "] = " .. dumpVariable(v, innerIndent, visited) .. ",\n"
--         end
--         str = str .. indent .. "}"
--         return str
--     else
--         return tostring(variable)
--     end
-- end

function getKeysAsString(tbl)
    if type(tbl) ~= "table" then
        return "Not a table"
    end

    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end

    return table.concat(keys, ", ")
end
