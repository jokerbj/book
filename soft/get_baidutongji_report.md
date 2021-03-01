
## 注册百度账号


## 登录百度统计

## 开通数据导出服务

在管理--其他设置--数据导出服务

按照说明一步一步操作，注册开发者，创建工程，保存好项目工程的API Key 和 Secret Key。

## 如何访问Openapi

### 第一步
获取code

http://openapi.baidu.com/oauth/2.0/authorize?response_type=code&client_id={CLIENT_ID}&redirect_uri={REDIRECT_URI}&scope=basic&display=popup


设置信息对应参数
```bash
    API Key         {CLIENT_ID}
    Secret Key      {CLIENT_SECRET}
    回调 URI         {REDIRECT_URI}
```
    
这里你肯定疑惑，回调URL不太清楚，那你就写`oob`就行了。

### 第二步
获取access_token

http://openapi.baidu.com/oauth/2.0/token?grant_type=authorization_code&code={CODE}&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}&redirect_uri={REDIRECT_URI}

这里比第一步多一个CODE变量，而这个变量就是第一步请求返回的。

这里会返回如下信息

```bash

{
        "expires_in": 2592000,
        "refresh_token":"2.385d55f8615fdfd9edb7c4b5ebdc3e39.604800.1293440400-2346678-124328",
        "access_token":"1.a6b7dbd428f731035f771b8d15063f61.86400.1292922000-2346678-124328",
        "session_secret":"ANXxSNjwQDugf8615OnqeikRMu2bKaXCdlLxn",
        "session_key":" 248APxvxjCZ0VEC43EYrvxqaK4oZExMB",
        "scope":"basic"
    }
```

### 第三步
访问openapi

第二步返回的信息中，expires_in过期时间，refresh_token这个是在access_token过期时候，要用到它更新。access_token就是访问openapi的。

在线调试工具
https://tongji.baidu.com/api/debug/

### 第四步
更新access_token

http://openapi.baidu.com/oauth/2.0/token?grant_type=refresh_token&refresh_token={REFRESH_TOKEN}&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}

