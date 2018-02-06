cjson=require "cjson"
local _M = {}
local mt = { __index = _M }

-- use the lookup table to figure out what to do
local function _rule_action(code)
    ngx.log(ngx.WARN, "errno=63 errmsg=downgrade hit deny " .. " id=" .. code)
    ngx.header.downgrade = code
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- 主要执行函数
function _M.exec(self)
    local rs = require ("common_features")
    if nil == rs then
        ngx.log(ngx.WARN, "errno=1 errmsg=commonDowngrade features is null")
        return
    end

    ---降级配置
    local conf = parseJsonConf("/home/work/nginx/lua/downgrade/file/conf.json")
    if nil == conf then
        ngx.log(ngx.WARN, "[access] no conf")
		return
	end

	--特征
    local features_all = rs.features()
    features = features_all.get_features(conf.common)
    if nil == features then
        ngx.log(ngx.WARN, "[access] no commonDowngrade conf")
        return
    end

    level = features.level
    host = features.host
    uri = features.uri

    ---常规降级等级小雨1表示不开启
    if level < 1 then
        ---ngx.log(ngx.INFO, "[access] commonDowngrade function off,level:" .. level)
        return
    end

    ---判断是不是在白名单中,白名单直接返回
    if features_all.hit_whitelist(host, uri, conf, level) then
        ngx.log(ngx.INFO, "[access] commonDowngrade hit whitelist:" .. host .. " " .. uri .. " " .. level)
        return
    end

    ---命中降级黑名单id
    hit_id = features_all.hit_blacklist(host, uri, conf, level)
    if hit_id ~= 0 then
        ngx.log(ngx.WARN, "access] commonDowngrade hit blacklist:" .. host .. " " .. uri .. " " .. level)
        _rule_action(hit_id)
        return
    end
    ngx.log(ngx.WARN, "[access] commonDowngrade accept")
end

-- instantiate a new instance of the module
function _M.new(self)
    return setmetatable({}, mt)
end

return _M
