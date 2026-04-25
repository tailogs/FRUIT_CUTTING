local M = {}
local bit = require("bit")
local file_name = "save_file_data.save"
local secret_key = "tailogs"
local save_version = 2

local default_data = {
    version = save_version,
    high_score = 0,
    fruit_coins = 0,
}

M.data = {}
for k,v in pairs(default_data) do M.data[k] = v end

local function xor_crypt(input, key)
    local output = {}
    local key_len = #key
    for i = 1, #input do
        local key_idx = (i % key_len) + 1
        output[i] = string.char(bit.bxor(input:byte(i), key:byte(key_idx)))
    end
    return table.concat(output)
end

local function encode_data(data)
    local serialized = ""
    for k,v in pairs(data) do
        serialized = serialized .. k .. "=" .. tostring(v) .. ";"
    end
    local encrypted = xor_crypt(serialized, secret_key)
    return (encrypted:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
end

local function decode_data(hex_str)
    local encrypted = hex_str:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end)
    local decrypted = xor_crypt(encrypted, secret_key)
    
    local data = {}
    for pair in decrypted:gmatch("([^;]+)") do
        local k, v = pair:match("(.+)=(.+)")
        if k and v then
            data[k] = tonumber(v) or v
        end
    end
    return data
end

local migrations = {
    [1] = function(old_data)
        local new_data = {
            version = 2,
            high_score = old_data.high_score or 0,
            fruit_coins = old_data.fruit_coins or 0
        }
        return new_data
    end
}

function M.save_to_file_progress()
    local file = io.open(file_name, "w")
    if file then
        M.data.version = save_version
        file:write(encode_data(M.data))
        file:close()
    else
        print("Error entry in file!")
    end
end

function M.open_file_progress()
    local file = io.open(file_name, "r")
    if file then
        local contents = file:read("*a")
        file:close()
        
        local loaded_data = decode_data(contents)
        
        while loaded_data.version and loaded_data.version < save_version do
            loaded_data = migrations[loaded_data.version](loaded_data)
        end
        
        for k,v in pairs(default_data) do
            M.data[k] = loaded_data[k] or v
        end
    else
        for k,v in pairs(default_data) do
            M.data[k] = v
        end
    end
end

function M.get_high_score() return M.data.high_score end
function M.get_fruit_coins() return M.data.fruit_coins end

function M.set_high_score(value) M.data.high_score = value end
function M.set_fruit_coins(value) M.data.fruit_coins = value end

return M
