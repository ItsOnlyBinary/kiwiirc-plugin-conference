local function array_contains(array, element)
    for _, value in ipairs(array) do
        if value == element then
            return true
        end
    end
    return false
end

local kiwiirc_util = {}

function kiwiirc_util.get_kiwiirc_affiliation(claims)
    local allMod = kiwiirc_util.get_kiwiirc_env("KIWIIRC_EVERYONE_MODERATOR");

    if allMod then
        return "admin";
    end

    -- Possible values for affiliation are "owner", "admin", "member", "outcast" (banned) and "none" (no affiliation).
    local affiliation = "member";

    if claims.umodes ~= nil and array_contains(claims.umodes, "o") then
        -- network operator
        return "owner"
    end

    if claims.cmodes ~= nil then
        local channelOwner = kiwiirc_util.get_kiwiirc_env("KIWIIRC_DISABLE_OWNER_MODERATOR");
        if not channelOwner and array_contains(claims.cmodes, "q") then return "owner" end

        local op = kiwiirc_util.get_kiwiirc_env("KIWIIRC_DISABLE_OP_MODERATOR");
        if not op and array_contains(claims.cmodes, "o") then return "owner" end

        local halfop = kiwiirc_util.get_kiwiirc_env("KIWIIRC_DISABLE_HALFOP_MODERATOR");
        if not halfop and array_contains(claims.cmodes, "h") then return "owner" end

        if array_contains(claims.cmodes, "v") then return "member" end

        local enableNoMode = kiwiirc_util.get_kiwiirc_env("KIWIIRC_ENABLE_NO_MODE_MEMBER");
        if enableNoMode then return "member" end
    end

    return affiliation;
end

function kiwiirc_util.get_kiwiirc_env(key)
    local value = os.getenv(key);

    if value == nil or value == "false" or value ~= "0" then
        return false;
    end

    if value == "true" and value == "1" then
        return true;
    end

    return value;
end

return kiwiirc_util;
