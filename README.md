# ngx-lua-downgrade
```
降级nginx模块,主要功能有常规降级和自动降级。应用场景是当流量高峰时，通过快速配置降级上线后可以将主要接口压力降低。
```

## 安装
1. openresty 或者安装了ngx-lua-module模块的nginx。
2. 根据需要修改conf.lua配置文件。
3. sh build.sh
3. 将打包好的output.tar.gz发到需要安装的nginx目录下解压。
4. 根据nginx.conf.example修改nginx.conf。
5. reload nginx。

## 关键元素
1. host
2. uri
3. 白名单
4. 黑名单

## 功能
1. 常规降级
	根据文件中的白名单，黑名单进行降级策略。白名单与黑名单都是从level1开始，逐级向上增加。命中白名单中的host或者uri则不进行降级，命中黑名单中的host或者uri，则进行降级。
	host优先级高于uri。如果配置level=3，则策略判断命中时包含level2和level1中的配置。
	如果命中降级策略则nginx返回状态码403，response header中返回downgrade:1001 / 1002 / 1003 (等级相关)

2. 自动降级
	自动降级与常规降级类似。不同的是如果当前请求的返回码是5xx, 并且命中了黑名单中的host和uri，则对其进行计数。下一次同样的请求来时会判断在expire_time时间内，该host或者uri的计数是否达到了阈值，如果达到则返回403状态码，response header中返回downgrade:1000。

## 实现原理
	利用ngx-lua-module中提供的init_by_lua_file, access_by_lua_file, log_by_lua_file实现在各个阶段的策略。
	1. 常规降级：
	access阶段，利用lua读取降级配置，对请求的host和uri进行判断，并对命中的请求进行对应的处理。
	2. 自动降级：
	log阶段读取降级配置，对异常请求记录host和uri的请求次数。access阶段判断过期时间内host和uri是否超过阈值，并进行降级处理。

## 优点
1. 平时可以配置好降级配置，关闭开关，紧急情况打开，可以快速降级。
2. 灵活配置降级host和uri的黑白名单，可以对内网和外网调用分别处理。
3. 通过http response header标记降级类型，客户端或者内部rpc调用可以了解具体的后端情况。
4. 自动降级可以辅助保证线上稳定性；尤其是当高峰期后端超时比较多的情况下，能够一定程度降级后端压力。

## 不足
1. 有待线上验证。
2. 自动降级的恢复机制尚不完善。
3. laraval框架uri多数是Restful, 目前不支持正则匹配。
