local _M = {}
--- 主要特征
local _features = {
    get_features = function (auto_conf)
        if nil == auto_conf then
	        ngx.log(ngx.WARN, "no auto conf")
            return nil
        end
        return {
            mode = auto_conf.mode,
            host_expire_time = auto_conf.host_expire_time,
            uri_expire_time = auto_conf.uri_expire_time,
            host_deny_threshold = auto_conf.host_deny_threshold,
            uri_deny_threshold = auto_conf.uri_deny_threshold,

			uri = ngx.var.request_uri or "",
			host = ngx.var.host or "",
			status = ngx.status or ngx.HTTP_OK,
        }
    end
}

local _countkeys = {
    _local = {
        {
            key = function(features)
                return "downgrade:lucus" .. ";time_" .. features.host_expire_time .. ";host_"  .. features.host .. ";"
            end,

            expire_time = function(features)
                return features.host_expire_time
            end,

            increase = function(features)
                code = features.status / 100
                if (5 ~= code) then
	                ---ngx.log(ngx.INFO, "good status," .. features.status .. " " .. code)
                    return false
                end
                return true
            end,
        },
        {
            key = function(features)
                return "downgrade:lucus" .. ";time_" .. features.uri_expire_time .. ";uri_"  .. features.uri .. ";"
            end,

            expire_time = function(features)
                return features.uri_expire_time
            end,

            increase = function(features)
                code = features.status / 100
                if (5 ~= code) then
	                ---ngx.log(ngx.INFO, "good status," .. features.status .. " " .. code)
                    return false
                end
                return true
            end,
        },
    },
}

--- 规则rules
local _rules = {
    {
        id = 1000,
        judge = function (features, local_counts)
            ---5xx 次数超过多少自动降级，需要统计count
            local key = "downgrade:lucus" .. ";time_" .. features.host_expire_time .. ";host_"  .. features.host .. ";"

            if (local_counts[key] >= features.host_deny_threshold) then
                ngx.log(ngx.WARN, "hit auto downgrade host");
                return true
            end

            local key = "downgrade:lucus" .. ";time_" .. features.uri_expire_time .. ";uri_"  .. features.uri .. ";"
            if (local_counts[key] >= features.uri_deny_threshold) then
                ngx.log(ngx.WARN, "hit auto downgrade uri");
                return true
            end
            return false
        end,

        action = "DENY",
        code = 1000,
        description = "auto downgrade api deny",
    },
}

function _M.rules()
    return _rules
end

function _M.features()
    return _features
end

function _M.countkeys()
    return _countkeys
end

return _M
