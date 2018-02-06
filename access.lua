local autoDowngrade=require "auto_downgrade"
local commonDowngrade=require "common_downgrade"

function _main()
    local cObj = commonDowngrade:new()
    cObj:exec()

    local autoObj = autoDowngrade:new()
    autoObj:exec()
end

_main()
