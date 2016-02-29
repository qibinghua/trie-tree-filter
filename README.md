##名称

关键词过滤器，基于trie tree字典树建成

##描述

很多时候我们的一些文本内容、聊天需要过滤一些关键字，本项目使用lua构建trie tree，用于过滤关键字。结合Lua的代码缓存方式，将字典树放在代码缓存中，使用起来速度飞快，结合用[openresty](https://github.com/openresty)效果更佳。
本项目已结合openresty用在项目上，感谢春哥！

##使用

1.敏感词列表文件

敏感词列表文件的格式应为

    XXX
    KKK
    XXX|YYY

其中|为代表或的意思，即如果语句中含有XXX或YYY则为敏感词。
可以根据自己的文件格式重写trie_tree/build_tree分词。

2.匹配

直接调用keyword/check，输入语句判断是否含有关键字。