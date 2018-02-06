local autoDowngrade=require "auto_downgrade_statis"

function _main()
    local obj = autoDowngrade:new()
    obj:exec()
end

_main()
