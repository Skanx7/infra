#!lua name=token_bucket
-- 2 keys, 5 args
-- ARG[1] (key) = global bucket key
-- ARG[2] (key) = category bucket key
-- ARG[3] (arg) = global bucket max capacity
-- ARG[4] (arg)= global bucket refill rate (tokens per second)
-- ARG[5] (arg) = category bucket max capacity
-- ARG[6] (arg) = category bucket refill rate (tokens per second)
-- ARG[7] (arg) = current timestamp (seconds)
local function update_bucket(key, max_cap, rate, now)
    local data = redis.call('HMGET', key, 'tokens', 'last_time')
    local tokens = tonumber(data[1])
    local last_time = tonumber(data[2])

    if not tokens then
        return max_cap, now 
    end

    local delta = math.max(0, now - last_time)
    local filled = math.min(max_cap, tokens + (delta * rate))
    
    return filled, last_time
end

redis.register_function('check_limit', function(keys, args)

    local global_key = keys[1]
    local cat_key    = keys[2]
    
    local g_max  = tonumber(args[1])
    local g_rate = tonumber(args[2])
    local c_max  = tonumber(args[3])
    local c_rate = tonumber(args[4])
    local now    = tonumber(args[5])

    local g_tokens, _ = update_bucket(global_key, g_max, g_rate, now)
    local c_tokens, _ = update_bucket(cat_key, c_max, c_rate, now)

    if g_tokens >= 1 and c_tokens >= 1 then
        local new_g = g_tokens - 1
        local new_c = c_tokens - 1

        redis.call('HMSET', global_key, 'tokens', new_g, 'last_time', now)
        redis.call('HMSET', cat_key,    'tokens', new_c, 'last_time', now)
        
        return {1, 0}
    else
        local wait_g = 0
        if g_tokens < 1 then
            wait_g = (1 - g_tokens) / g_rate
        end

        local wait_c = 0
        if c_tokens < 1 then
            wait_c = (1 - c_tokens) / c_rate
        end

        -- Return { Allowed=0, Wait=Max(wait_g, wait_c) }
        return {0, math.max(wait_g, wait_c)}
    end
end)