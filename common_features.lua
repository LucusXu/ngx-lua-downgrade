local _M = {}
--- 主要特征
local _features = {
    ---特征提取
    get_features = function (common_conf)
        if nil == common_conf then
	        ngx.log(ngx.WARN, "no common conf")
            return nil
        end
        return {
            level = common_conf.level,
			uri = ngx.var.request_uri or "",
			host = ngx.var.host or "",
        }
    end,

    ---判断是否命中白名单
    hit_whitelist = function (host, uri, conf, level)
        for i = 1, level, 1 do
            if table_has_value(conf.common.white_host[i], host) then
	            ngx.log(ngx.WARN, "hit whitelist host," .. level .. " " .. i .. " " ..  host)
                return true
            end
        end

        for i = 1, level, 1 do
            if table_has_value(conf.common.white_uri[i], uri) then
	            ngx.log(ngx.WARN, "hit whitelist uri," .. level .. " " ..  i .. " " .. uri)
                return true
            end
        end
        return false
    end,

    ---判断是否命中黑名单,命中后返回降级策略
    hit_blacklist = function (host, uri, conf, level)
        for i = 1, level, 1 do
            if table_has_value(conf.common.black_host[i], host) then
	            ngx.log(ngx.WARN, "hit blacklist host," .. level .. " " ..  i .. " " .. host)
                return i + 1000
            end
        end

        for i = 1, level, 1 do
            if table_has_value(conf.common.black_uri[i], uri) then
	            ngx.log(ngx.WARN, "hit blacklist uri," .. level .. " " ..  i .. " " .. uri)
                return i + 1000
            end
        end
        return 0
    end
}

function _M.rules()
    return _rules
end

function _M.features()
    return _features
end

return _M
