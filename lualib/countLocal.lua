-- 通过lua共享词典记录本地计数
function _get_local_counts(local_conf, features)
    local countdict = ngx.shared.countdict
    local local_count = {}
    local now_time = ngx.now()

    for _, v in ipairs(local_conf) do
        local key = v.key(features)
        local_count[key] = 0

        local count_value = countdict:get(key)
        if count_value ~= nil then
            count_value = cjson.decode(count_value)
            if count_value.count ~= nil then
                local_count[key] = count_value.count
            end
        end
    end
    return local_count
end

---通过共享词典记录错误状态码次数
function _statis_local_counts(local_conf, features)
    local countdict = ngx.shared.countdict
    local now_time = ngx.now()

    for _, v in ipairs(local_conf) do
        local flag = v.increase
        local key = v.key(features)

        local count = v.count
        if type(flag) == "function" then
            flag = v.increase(features)
        end

        local expire_time = v.expire_time
        if type(expire_time) == "function" then
            expire_time = v.expire_time(features)
        end

        local meta_value = {stime = now_time, count = 1, expire_time = nil}
        local count_value = countdict:get(key)

        if count_value == nil then
            if flag == true then
                countdict:safe_set(key, cjson.encode(meta_value), expire_time)
            end
        else
            count_value = cjson.decode(count_value)

            if (count_value.expire_time ~= nil) then
                expire_time = count_value.expire_time
            end

            local new_expire_time = expire_time - (now_time - count_value.stime)

            if new_expire_time > 0 then
                meta_value.expire_time = new_expire_time
                if flag == true then
                    meta_value.count = count_value.count + 1
                    countdict:safe_set(key, cjson.encode(meta_value), new_expire_time)
                end
            else
                if flag == true then
                    countdict:safe_set(key, cjson.encode(meta_value), expire_time)
                end
            end
        end
    end
end
