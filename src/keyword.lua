-- keyword_filter
local cjson         = require "cjson"

local _M = {}


local keyword_tb
local lock

function _M.check(keyword)
	local tree = require('trie_tree')
    
    if not keyword_tb then --仅需第一次生成树。增加更新锁
        if not lock then
            lock = true
            keyword_tb = {}
            tree:build_tree(keyword_tb)
            debug("finish build keyword_tb")
            lock = nil
        else
            return false --暂时无法判断
        end
    end
    
    local filter = true
    local index = 1
    local single = {}
    local multi = {}
    local key_repeat = {} --用于去重关键字

    while index <= #keyword and filter do
        --当存在独立的关键字，则返回false
        filter = tree:compare(keyword_tb, string.sub(keyword, index, #keyword), "", single, multi)
    
        local bytes = string.byte(keyword, index) --第一位，用于判断中英文
        if bytes >= 128 and bytes <= 255 then --中文范围，3个字符
            index = index + 3
        else
            index = index + 1
        end
    end
    
    --[[对比单项中问题，再对比多项中是否有相应项]]
    --[[if #single > 0 then
        filter = false
    end]]

    local i = 1
    while i <= #multi and filter do --所有命中关键字中查找
        local relatives = multi[i].relatives
        local index = 1
        while index <= #relatives and filter do
            local target = 0
            local j = 1
            local relative = relatives[index]
            while j <= #relative and filter do
                local k = i
                while k <= #multi and filter do --查看后面是否有关联项
                    if relative[j] == multi[k].strings then --命中其余项
                        target = target + 1
                        if target == #relative then --后续字符的命中数，等于其余相关项长度，再包括本身，即全部找到
                            filter = false
                        end
                        break
                    end
                    k = k + 1
                end
                j = j + 1
            end
            index = index + 1
        end
        i = i + 1
    end
    
	return true
end

return _M