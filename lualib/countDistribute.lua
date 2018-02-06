function _get_distribute_counts(distribute_conf, features)
    local distribute_count =  {}    -- retrun value :{ key = count, ... }
    local keys             =  {}    -- store keys user config
    local keys_trans       =  {}    -- store keys transformed (add time prefix according expire_time)
    local keys_increase    =  {}    -- store keys and increase flag like  {key1 = true, key2 = false}
    local keys_expire      =  {}    -- store keys transformed and expire_time like {key_t = expire_time}
    local keys_update      =  {}    -- store keys transformed which needed update expire time in redis
    local mset_input       =  {}    -- store input for mset function
    local red              =  nil
    local upstream_name    =  distribute_conf.upstream

    -- get upstream servre by upstream_name then get ip&port
    -- local get_servers = upstream.get_servers
    -- local servers = get_servers(upstream_name)
    local servers = nil
    if servers == nil then
        --ngx.log(ngx.WARN, "anti err_code=65 msg=not config upstream server for redis")
        return distribute_count
    end
    local size = table.getn(servers)
    local index = math.random(1, size)
    local server = servers[index]["addr"]
    local index_t = string.find(server, ":")
    local ip = string.sub(server, 1, index_t-1)
    local port = string.sub(server, index_t+1, string.len(server))

    if ip == nil and port == nil then
        return distribute_count
    end
    for i, v in ipairs(distribute_conf.var) do
        local key = v.key(features)
        table.insert(keys, key)
        keys_increase[key] = v.increase(features)
        local prefix = math.modf(ngx.now()/v.expire_time)
        key_t = prefix .."_" .. key
        --key_t = mmh2 (tostring(key_t))
        table.insert(keys_trans, key_t)
        keys_expire[key_t] = v.expire_time
    end

    -- if keys is empty return
    local next = next
    if next(keys) == nil then
        return distribute_count
    end

    local red  = nil
    -- local ip   = distribute_conf.ip
    -- local port = distribute_conf.port
    local upstream_name = distribute_conf.upstream

    if upstream_name ~= nil then
        red = redis:new()
        red:set_timeout(distribute_conf.timeouts)
        local ok, err = red:connect(ip, port)
        if not ok then
            ngx.log(ngx.WARN, "err_code=66 msg=redis connect redis failed [" .. err .. "]")
        else
            ngx.log(ngx.DEBUG, "err_code=0 msg=redis key ::" .. cjson.encode(keys_trans))
            local res, err = red:mget(unpack(keys_trans))
            if res then
                for i, count in ipairs(res) do
                    local key = keys[i]
                    count = tonumber(count)
                    if count == nil then
                        count = 0
                    end
                    if  keys_increase[key] ~= nil and keys_increase[key] then
                        count = count + 1
                        table.insert(keys_update, keys_trans[i])
                        table.insert(mset_input, keys_trans[i])
                        table.insert(mset_input, count)
                    end
                    distribute_count[key] = count
                end
            else
                ngx.log(ngx.WARN, "err_code=67 msg=redis mget failed [" .. err .."]")
            end
        end
    end
    red:init_pipeline()
    red:mset(unpack(mset_input))
    for _, v in ipairs(keys_update) do
        red:expire(v, keys_expire[v])
    end
    local res, err = red:commit_pipeline()
    if not res then
        ngx.log(ngx.WARN, "err_code=68 msg=redis mset failed [" .. err .. "]")
    end

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle time
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.WARN, "err_code=69 msg=redis failed to set keepalive: [" ..  err .. "]")
    end

    return distribute_count
end
