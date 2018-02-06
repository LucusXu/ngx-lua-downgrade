cjson=require "cjson"
local _M = {}
local mt = { __index = _M }

-- 主要执行函数
function _M.exec(self)
    local rs = require ("auto_features")
    if nil == rs then
        ngx.log(ngx.WARN, "errno=1 msg=downgrade features")
        return
    end

    local conf = parseJsonConf("/home/work/nginx/lua/downgrade/file/conf.json")
	if nil == conf then
        ngx.log(ngx.WARN, "[log] no conf")
		return
	end

	--特征
    local features_all = rs.features()
    features = features_all.get_features(conf.auto)

    if nil == features then
        ngx.log(ngx.WARN, "[log] no autoDowngrade conf")
        return
    end

    if features.mode ~= "on" then
        ---ngx.log(ngx.WARN, "[log] autoDowngrade funciotn is not on")
        return
    end

    ---host白名单不统计
    if ((table_has_value(conf.auto.white_host, features.host))) then
		ngx.log(ngx.INFO, "[log] autoDowngrade hit host whitelist")
        return
    end

    ---uri白名单不统计
    if ((table_has_value(conf.auto.white_uri, features.uri))) then
		ngx.log(ngx.INFO, "[log] autoDowngrade hit uri whitelist")
        return
    end

    ---没有黑名单也不需要统计
    if table_is_empty(conf.auto.black_host) and table_is_empty(conf.auto.black_uri) then
		ngx.log(ngx.INFO, "[log] autoDowngrade black conf empty")
        return
    end

    ---不在统计配置中
    if (not table_has_value(conf.auto.black_host, features.host)) and (not table_has_value(conf.auto.black_uri, features.uri)) then
		ngx.log(ngx.INFO, "[log] not hit auto downgrade black conf")
        return
    end

    ---自动降级本地计数器
    local countkeys = rs.countkeys()
    _statis_local_counts(countkeys._local, features)
end

-- instantiate a new instance of the module
function _M.new(self)
    return setmetatable({}, mt)
end

return _M
