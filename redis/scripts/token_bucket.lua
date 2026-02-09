-- KEYS[1]: Global key (example: "massivecom:global")
-- KEYS[2]: Category key (example: "massivecom:news")


-- ARGV[1]: Global max capacity
-- ARGV[2]: Global refill rate (tokens per second)

-- ARGV[3]: Category max capacity
-- ARGV[4]: Category refill rate (tokens per second)

-- ARGV[5]: UNIX timestamp

local function update_bucket(key, max_cap, rate, now)
    local data = redis.call('HMGET', key, 'tokens', 'last_time')
    local tokens = tonumber(data[1])
    local last_time = tonumber(data[2])

    -- Initialize if missing
    if not tokens then
        tokens = max_cap
        last_time = now
    end

    -- Calculate refill
    local delta = math.max(0, now - last_time)
    local filled_tokens = math.min(max_cap, tokens + (delta * rate))

    return filled_tokens, last_time
end

local now = tonumber(ARGV[5])

-- 1. Calculate state of Global Bucket
local g_tokens, g_last = update_bucket(KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), now)

-- 2. Calculate state of Category Bucket
local c_tokens, c_last = update_bucket(KEYS[2], tonumber(ARGV[3]), tonumber(ARGV[4]), now)

-- 3. Check if BOTH have at least 1 token
if g_tokens >= 1 and c_tokens >= 1 then
    -- Consuming tokens
    local new_g = g_tokens - 1
    local new_c = c_tokens - 1

    -- Save Global
    redis.call('HMSET', KEYS[1], 'tokens', new_g, 'last_time', now)
    redis.call('EXPIRE', KEYS[1], 120) -- Safety cleanup

    -- Save Category
    redis.call('HMSET', KEYS[2], 'tokens', new_c, 'last_time', now)
    redis.call('EXPIRE', KEYS[2], 120)

    return 1 -- Allowed
else
    return 0 -- Rejected (Not enough tokens)
end