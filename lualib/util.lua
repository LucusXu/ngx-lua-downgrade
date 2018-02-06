cjson=require "cjson"
-- 如果在table中存在就返回true
function table_has_value(table, value)
    if (type(table) ~= "table") then
	    ngx.log(ngx.WARN, "not table, type:" .. type(table))
        return false
    end

    for _, v  in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- 如果在table中存在就返回true
function table_is_empty(table)
    if (type(table) ~= "table") then
	    ngx.log(ngx.WARN, "not table, type:" .. type(table))
        return true
    end

    if next(table) == nil then
        return true
    end
    return false
end

function FileRead(path)
    local file = io.open(path, "r")
	if file then
		local json = file:read("*a")
 		file:close()
 		return json
	end
	return nil
end

function parseJsonConf(path)
    local file = FileRead(path)
	if nil == file then
        ngx.log(ngx.WARN, 'conf is not exist!')
        return nil
    end

    local ok, json = pcall(cjson.decode, file)
    if not ok then
        ngx.log(ngx.WARN, 'conf file is not json!')
        return nil
    end
    return json
end
