local sha256 = require "util.hashes".sha256

local kiwi_config = module:require "kiwiirc_config"


local base62_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

local function array_contains(array, element)
    for _, value in ipairs(array) do
        if value == element then
            return true
        end
    end
    return false
end

local function base62_encode(binary)
    local base62 = ""
    local bytes = {}

    for i = 1, #binary do
        bytes[i] = string.byte(binary, i)
    end

    while #bytes > 0 do
        local quotient = {}
        local remainder = 0

        for i = #bytes, 1, -1 do
            local accumulator = bytes[i] + remainder * 256
            local digit = math.floor(accumulator / 62)
            remainder = accumulator % 62
            if #quotient > 0 or digit > 0 then
                table.insert(quotient, 1, digit)
            end
        end

        base62 = base62 .. base62_chars:sub(remainder + 1, remainder + 1)
        bytes = quotient
    end

    return base62
end

local kiwi_util = {}

function kiwi_util.encode_room_name(server, channel)
    local hash = sha256(server .. "/" .. channel)
    local hash_b62 = base62_encode(hash)
    return string.sub(hash_b62, -16)
end

function kiwi_util.get_kiwiirc_affiliation(claims)
    -- Possible values for affiliation are "owner", "admin", "member", "outcast" (banned) and "none" (no affiliation).

    local allMod = kiwi_util.get_kiwiirc_env("KIWIIRC_EVERYONE_MODERATOR")

    if allMod then
        return "owner"
    end

    if claims.umodes ~= nil and array_contains(claims.umodes, "o") then
        -- network operator
        return "owner"
    end

    if claims.cmodes ~= nil then
        local channelOwner = kiwi_util.get_kiwiirc_env("KIWIIRC_DISABLE_OWNER_MODERATOR")
        if not channelOwner and array_contains(claims.cmodes, "q") then
            return "owner"
        end

        local op = kiwi_util.get_kiwiirc_env("KIWIIRC_DISABLE_OP_MODERATOR")
        if not op and array_contains(claims.cmodes, "o") then
            return "owner"
        end

        local halfop = kiwi_util.get_kiwiirc_env("KIWIIRC_DISABLE_HALFOP_MODERATOR")
        if not halfop and array_contains(claims.cmodes, "h") then
            return "owner"
        end
    end

    return "member"
end

function kiwi_util.get_kiwiirc_env(key)
    local value = os.getenv(key)

    if value == nil then
        local default = kiwi_config[key]
        if default == nil then
            return false
        else
            return default
        end
    end

    if value == "false" or value ~= "0" then
        return false
    end

    if value == "true" or value == "1" then
        return true
    end

    return value
end

return kiwi_util
