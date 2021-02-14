

## 对新增日志如何过滤分析PM2+PYTHON+LOGROTATE
> 问题描述，苹果充值用户多有反馈，充过钱后钻石没有到账。前期通过日志上报，利用NGINX日志收集，再通过针对新增的日志进行分析。分析是否是丢单日志，如果是我们发送钉钉通知，不是则PASS。

### 我们来看下PY脚本
```bash
# !/usr/bin/env python
# _*_ coding:utf-8 _*_
# Author: Li

import time,re,json,requests
access_token=""

def tail(filename):
    with open(filename) as f:
        f.seek(0, 2) #从文件末尾算起 第一个0是偏移量，第二部分2是文件末尾，0是文件开头，1是当前行
        while True:
            line = f.readline()  # 读取文件中新的文本行
            if not line:
                time.sleep(1)
                continue
            yield line

def send_msg(diamond,toid,BorderId,line,*args,**kwargs):
    info = "#### 账号：**" + toid + "**\n" + "#### 钻石：**" + diamond + "**\n" +  "#### 订单：**" + BorderId + "**\n"
    reslog = "### 原始日志" + "\n" + line

    url = "https://oapi.dingtalk.com/robot/send?access_token=" + access_token
    data = {
        "msgtype": "markdown",
        "markdown": {
            "title": "苹果补单通知",
            "text": "### 苹果补单通知 " + "\n" + info + reslog
        },
        "at": {
            "atMobiles": [
            ],
            "isAtAll": False
        }
    }
    json_data = json.dumps(data).encode(encoding='utf-8')
    header_encoding = {"Content-Type": "application/json"}
    response = requests.post(url, headers=header_encoding, data=json_data)
    return response

for line in tail('/log_data/log/nginx/post_access.log'):
    print(line)
    if 'notApplicationUsername' in line:
        try:
            diamond_str = re.search('diamond=\d+', line).group()
            diamond = re.search('\d+', diamond_str).group()
            toid_str = re.search('toid=\d+', line).group()
            toid = re.search('\d+', toid_str).group()
            BorderId_str = re.search('=\d+&debug', line).group()
            BorderId = re.search('\d+', BorderId_str).group()
            print(diamond,toid,BorderId)
            send_msg(diamond,toid,BorderId,line)
        except Exception as e:
            diamond='解析异常'
            toid='解析异常'
            BorderId='解析异常'
            send_msg(diamond,toid,BorderId,line)
    else:
        pass
```

### 为了脚本意外退出引入PM2
```bash
{
  "apps": [{
    "name": "listenpay",
    "script": "/log_data/script/listenapple.py", 
    "exec_interpreter":"/usr/local/python-3.6.4/bin/python3",
    "cwd": "/log_data/script",
    "autorestart": true,
    "args": [],
    "output": "/log_data/script/listenapp_output.log",
    "error": "/log_data/script/listenapp_error.log",
    "merge_logs": true,
    "watch": false,
  }]
}
```

### 坑就是当系统进行LOGRATE时候，脚本无法断定文件末尾行，监听就失败了，所以在LOGTATE加入重启PM2
```bash
/log_data/log/nginx/*log {
    create 0644 nginx nginx
    daily 
    rotate 60
    missingok
    notifempty
    compress
    dateext
    dateformat -%Y%m%d.%s
    sharedscripts
    postrotate
        /bin/kill -USR1 `cat /run/nginx.pid 2>/dev/null` 2>/dev/null || true
        /usr/local/src/node-v10.16.3-linux-x64/bin/pm2 restart 0
    endscript
}
```

### 还有个坑就是在切割时候，脚本没有运行成功，问题是LOGRATE依赖/etc/anacrontab,而这里面有个PATH变量，将PM2绝对路径加入进去。

