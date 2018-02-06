cjson=require "cjson"
local _M = {}
local mt = { __index = _M }

-- use the lookup table to figure out what to do
local function _rule_action(self, rule)
	local actions = {
		LOG = function(self, rule)
			ngx.log(ngx.WARN, "errno=61 rule hit log " .. "rule_id=" .. rule.id)
		end,

		ACCEPT = function(self, rule)
			ngx.log(ngx.WARN, "errno=62 rule hit accept " .. "rule_id=" .. rule.id)
            ngx.exit(ngx.OK)
		end,

		DENY = function(self, rule)
            code = rule.code
			ngx.log(ngx.WARN, "errno=63 rule hit deny " .. "rule_id=" .. rule.id)
            ngx.header.downgrade = code
			ngx.exit(ngx.HTTP_FORBIDDEN)
        end,
    }
	actions[rule.action](self, rule)
end

-- 主要执行函数
function _M.exec(self)
    local rs = require ("auto_features")
    if nil == rs then
        ngx.log(ngx.WARN, "errno=1 errmsg=downgrade features is null")
        return
    end

    local conf = parseJsonConf("/home/work/nginx/lua/downgrade/file/conf.json")
    if nil == conf then
        ngx.log(ngx.WARN, "[access] no conf")
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
        ---ngx.log(ngx.WARN, "[access] auto_downgrade function is not on")
        return
    end

    ---自动降级本地计数器
    local countkeys = rs.countkeys()
    local local_counts = _get_local_counts(countkeys._local, features)

    for _, rule in ipairs(rs.rules()) do
        local judge = rule.judge
        local ret = judge(features, local_counts)

        if (ret) then
            if rule.action == "ACCEPT" then
                return
            end
            _rule_action(self, rule)
            return
        end
    end
end

-- instantiate a new instance of the module
function _M.new(self)
    return setmetatable({}, mt)
end
return _M
