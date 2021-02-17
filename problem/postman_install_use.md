

## postman下载
https://www.postman.com/products/

## postman使用
我自己开了一个django，路由
```bash
url(r'^login/', views.login),
```
视图
```bash
import json
def login(request):
    if request.method == 'POST':
        bytes_str=str(request.body,'utf-8')
        str_json=json.loads(bytes_str)
        username=str_json['username']
        password=str_json['password']
        if username == 'liqianlong':
            if password == '123456':
                msg = {
                    'status': 1001,
                    'access_token': '123456abc'
                }
                return HttpResponse(json.dumps(msg))
            else:
                msg = {
                    'status': 1002,
                    'info': '密码错误。'
                }
                return HttpResponse(json.dumps(msg))
        else:
            msg = {
                'status': 1002,
                'info': '用户名错误。'
            }
            return HttpResponse(json.dumps(msg))
```

### 利用postman发送请求
![image](https://www.liqianlong.cn/book_login.png)

我们可以看到有返回信息，如果我们能把这个返回信息保存在postman里面，那么用到这个返回信息的其他接口都可以携带这个变量去请求了。

### 创建collections
创建一个collections，将所有接口保存至里面，更改名称等，变量就可以使用了。比如

![image](https://www.liqianlong.cn/book_chakanallbook.png)

页面上返回值出错了，因为只有加入到collections里面之后，用左侧book |-->这个键才能获取到变量

### collections Book说明
这里面包含了，登录-查看所有书籍-添加书籍-删除书籍-查看指定Id书籍。

当一点击左侧book |-->，所有的接口会自动执行。
![image](https://www.liqianlong.cn/book_zidongapi.png)

### 断言
可以针对返回值进行判断，一般要有
- 协议状态码
- 业务参数
- 业务状态码

查看所有书籍接口，Tests
```bash
var jsonDate=JSON.parse(responseBody)

pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

tests['测试查看所有书籍接口业务状态码']=jsonDate.status===1001
```
添加书籍接口，Tests
```bash
var jsonDate=JSON.parse(responseBody)

pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

tests['测试添加书籍业务状态码']=jsonDate.status===1001

pm.environment.set("book_id", jsonDate.id);
```

### django快速起的测试程序

路由
```bash
urlpatterns = [
    url(r'^login/', views.login),
    url(r'^book/', views.book),
    url(r'^addbook/', views.addbook),
    url(r'^getbook/(?P<nid>\d+)/', views.getbook),
    url(r'^delbook/(?P<nid>\d+)/', views.delbook)
]
```
视图
```
import json
def login(request):
    if request.method == 'POST':
        bytes_str=str(request.body,'utf-8')
        str_json=json.loads(bytes_str)
        username=str_json['username']
        password=str_json['password']
        if username == 'liqianlong':
            if password == '123456':
                msg = {
                    'status': 1001,
                    'access_token': '123456abc'
                }
                return HttpResponse(json.dumps(msg))
            else:
                msg = {
                    'status': 1002,
                    'info': '密码错误。'
                }
                return HttpResponse(json.dumps(msg))
        else:
            msg = {
                'status': 1002,
                'info': '用户名错误。'
            }
            return HttpResponse(json.dumps(msg))

access_token='123456abc'
book_list=[
    {'id':0,'bookname':'liqianlong0','author':'liqianlong'},
    {'id':1,'bookname':'liqianlong1','author':'liqianlong'}
]

def book(request):
    msg = {}
    if request.method == 'GET':
        if access_token == request.GET.get('access_token'):
            msg['data']=book_list
            msg['status']=1001
            msg['info']='所有书籍信息。'
            return HttpResponse(json.dumps(msg))
        else:
            msg['status']=1002
            msg['info']='access_token没有携带，不能给你数据。'
            return HttpResponse(json.dumps(msg))

def addbook(request):
    msg = {}
    if request.method == 'POST':
        bytes_str = str(request.body, 'utf-8')
        str_json = json.loads(bytes_str)
        if access_token == str_json['access_token']:
            id=len(book_list)
            book_obj={'id': id, 'bookname': 'liqianlong'+str(id), 'author': 'liqianlong'}
            book_list.append(book_obj)
            msg['status'] = 1001
            msg['info']='添加书籍成功。'
            msg['id']=id
            return HttpResponse(json.dumps(msg))
        else:
            msg['status'] = 1002
            msg['info'] = 'access_token没有携带，不能给你数据。'
            return HttpResponse(json.dumps(msg))

def delbook(request,nid):
    msg = {}
    if request.method == 'GET':
        if access_token == request.GET.get('access_token'):
            book_list.pop(int(nid))
            msg['status']=1001
            msg['info']='删除书籍成功。'
            return HttpResponse(json.dumps(msg))
        else:
            msg['status']=1002
            msg['info']='access_token没有携带，不能给你数据。'
            return HttpResponse(json.dumps(msg))

def getbook(request,nid):
    msg={}
    if request.method == 'GET':
        if access_token == request.GET.get('access_token'):
            try:
                book_obj=book_list[int(nid)]
            except IndexError as e:
                msg['status']=1002
                msg['info']='没有该书籍。'
                return HttpResponse(json.dumps(msg))
            else:
                msg['data']=book_obj
                msg['status'] = 1001
                msg['info'] = '有该书籍。'
                return HttpResponse(json.dumps(msg))
        else:
            msg['status']=1002
            msg['info']='access_token没有携带，不能给你数据。'
            return HttpResponse(json.dumps(msg))
```