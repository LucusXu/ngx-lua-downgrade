#!/bin/bash
basepath=$(cd `dirname $0`; pwd)

rm -rf output
mkdir -p output/nginx/lua output/nginx/conf
mkdir -p output/nginx/lua/downgrade output/nginx/lua/ext
cp nginx.conf.example output/nginx/conf

cp -r init.lua access.lua lualib output/nginx/lua/downgrade/
# 常规降级脚本
cp -r common_downgrade.lua common_features.lua output/nginx/lua/downgrade/
# 自动降级脚本
cp -r auto_downgrade.lua auto_features.lua output/nginx/lua/downgrade/
cp -r log.lua auto_downgrade_statis.lua output/nginx/lua/downgrade/
cp -r file output/nginx/lua/downgrade

cp -r luaso/* output/nginx/lua/ext
tar zcvf output.tar.gz output/

rm -rf output
echo "build done"
