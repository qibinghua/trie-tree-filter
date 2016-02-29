-- 获取敏感词

local pairs      = pairs
local type       = type


local _M = { _VERSION = '0.01' }
local filepath = "/data1/ngx_lua/txt" --敏感词列表文件，格式为XXX\nKKK\nXXX|YYY

function _M:build_tree(tb)
    local ok, file = pcall(io.open, filepath, "r")
    if not ok then
        get_instance().debug:log_error("cant not open file " .. filepath)
        get_instance().output:exit_error("内部错误", 1) --直接中断
    end

    for l in file:lines() do
        local strings = split(l, "|") --多条件项
        if #strings > 1 then --多个关键字组
            for i = 1 , #strings do
                if #(strings[i]) > 0 then --有字符的
                    local others = {}
                    for j = 1, #strings do
                        if i ~= j and #(strings[j]) > 0 then --除去本身项
                            others[#others + 1] = strings[j]
                        end
                    end
                    self:build(tb, strings[i], others)
                end
            end
        else
            self:build(tb, strings[1])
        end
    end
    file:close()
end

--取str中第一个字符作为键，生成字符树
function _M:build(tb, str, others)
    local bytes = string.byte(str, 1) --第一位，用于判断中英文
    local first --首字符
    local length = #str --剩余的长度
    if bytes >= 128 and bytes <= 255 then --中文范围，3个字符
        first = string.sub(str, 1, 3)
        length = length - 3
    else
        first = string.sub(str, 1, 1)
        length = length - 1
    end
    if length > 0 then --还有字符
        tb[first] = tb[first] or {} --增加字段
        tb[first].p = tb[first].p or {} --取保有p域，指针域，指向下属字符数组
        self:build(tb[first].p, string.sub(str, #str - length + 1, #str), others) --除去第一个字符后所有字符
    else
        local relatives
        tb[first] = tb[first] or {}
        tb[first].is_end = true --相关项为"且"的条件项
        if others then
            tb[first].relatives = tb[first].relatives or {} --记录多项的内容
            tb[first].relatives[#(tb[first].relatives) + 1] = others
        else
            tb[first].is_single = true --单项标记
        end
    end
end

--对比str与tb中的某个分支
--str :需要对比的字符串
--tb  :关键字树
--part:拼接关键字
--single:独立成军的关键字
--multi :成组的关键字
--return: true 没有出现关键字；false 出现了关键字
function _M:compare(tb, str, part, single, multi)
    local bytes = string.byte(str, 1) --第一位，用于判断中英文
    local first --首字符
    local length = #str --剩余的长度
    if bytes >= 128 and bytes <= 255 then --中文范围，3个字符
        first = string.sub(str, 1, 3)
        length = length - 3
    else
        first = string.sub(str, 1, 1)
        length = length - 1
    end
    if tb[first] then --树中有这个字
        part = part .. first
        if tb[first].is_end then
            if tb[first].is_single then --独立派
                --single[#single + 1] = { strings = part, }
                return false --存在独立的关键词！直接出局
            else
                multi[#multi + 1] = { --找出所有匹配上的项
                    strings  = part,
                    relatives = tb[first].relatives or {},
                }
            end
        end
        if tb[first].p and length > 0 then --还有两边都还有后续，需要继续对
            return self:compare(tb[first].p, string.sub(str, #str - length + 1, #str), part, single, multi) --除去第一个字符后所有字符
        else
            return true --传入字符串没有后续了
        end
    else
        return true --不相同项出现
    end
end

return _M

