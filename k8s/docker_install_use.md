


[toc]

# 学习前准备工作

```bash
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/sysconfig/selinux && setenforce 0
systemctl stop firewalld
systemctl disable firewalld
```

# docker是什么

- 使用最广泛的开源容器引擎
- 一种操作系统级的虚拟化技术
- 依赖于Linux内核特性:Namespace(资源隔离)和Cgroups(资源限制)
- 一个简单的应用程序打包工具

[docker文档](docs.docker.com)  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [docker仓库](hub.docker.com)

## docker内部组件

- namespaces

> 命名空间，Linux内核提供的一种对进程资源隔离的机制，例如进程、网络、挂载点等资源

- cgroups

> 控制组，Linux内核提供的一种限制进程资源的机制；例如CPU、内存等资源

- unionfs

> 联合文件系统，支持将不同位置的目录挂载到同一虚拟文件系统，形成一种分层的模型

## docker设计目标
- 提供简单的应用程序打包工具
- 开发人员和运维人员职责逻辑分离
- 多环境保持一致性

## docker基本组成
- Docker Client:客户端
- Ddocker Daemon:守护进程
- Docker Images:镜像
- Docker Container:容器
- Docker Registry:镜像仓库

![image](https://www.liqianlong.cn/jibenzucheng.png)

## 容器对比虚拟机
![image](https://www.liqianlong.cn/rongqivsxuniji1.png)

![image](https://www.liqianlong.cn/rongqivsxuniji2.png)

## docker应用场景

- 应用程序打包和发布
- 应用程序隔离
- 持续集成
- 部署微服务
- 快速搭建测试环境
- 提供PaaS产品(平台即服务)

# Linux安装docker (本次版本19.03)
- 社区版(Community Edition，CE)
- 企业版(Enterprise Edition，EE)

## 卸载老的版本

```bash
yum remove docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-selinux \
docker-engine-selinux \
docker-engine
```

## Centos7.x安装docker
```bash
安装依赖包
yum install -y yum-utils device-mapper-persistent-data lvm2
添加Docker软件包源
yum-config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo
备用源
https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo
https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
安装Docker CE
yum install -y docker-ce
启动Docker服务并设置开机启动
systemctl start docker 
systemctl enable docker
```
参考
https://docs.docker.com/engine/install/centos/

二进制包：
https://download.docker.com/linux/static/stable/x86_64/

# 镜像管理

## 镜像是什么
- 一个分层存储的文件
- 一个软件的环境
- 一个镜像可以创建N个容器
- 一种标准化的交付
- 一个不包含Linux内核而又精简的Linux操作系统

> 镜像从哪里来?
Docker Hub是由Docker公司负责维护的公共注册中心，包含大量的容器镜像，Docker工具默认从这个公共镜像库下载镜像。 地址:https://hub.docker.com/explor。
下面是配置国内镜像源。

```bash
配置镜像加速器:https://www.daocloud.io/mirror
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
或者手动配置
vi /etc/docker/daemon.json 
{
"registry-mirrors": [ "http://f1361db2.m.daocloud.io"]
}
```

## 镜像与容器联系
![image](https://www.liqianlong.cn/jingxiangrongqi.png)
> 如图，容器其实是在镜像的最上面加了一层读写层，在运行容器里文件改动时， 会先从镜像里要写的文件复制到容器自己的文件系统中(读写层)。 如果容器删除了，最上面的读写层也就删除了，改动也就丢失了。所以无论多 少个容器共享一个镜像，所做的写操作都是从镜像的文件系统中复制过来操作 的，并不会修改镜像的源文件，这种方式提高磁盘利用率。 若想持久化这些改动，可以通过docker commit 将容器保存成一个新镜像。
- 一个镜像创建多个容器
- 镜像增量式存储
- 创建的容器里面修改不会影响到镜像

## 管理命令

指令 |描述
---|---
ls |列出镜像
build |构建镜像来自Dockerfile
history |查看镜像历史
inspect |显示一个或多个镜像详细信息
pull |从镜像仓库拉取镜像
push |推送一个镜像到镜像仓库
rm |移除一个或多个镜像
prune |移除未使用的镜像。没有被标记或被任何容器引用的。
tag| 创建一个引用源镜像标记目标镜像
export |导出容器文件系统到tar归档文件
import |导入容器文件系统tar归档文件创建镜像
save |保存一个或多个镜像到一个tar归档文件
load |加载镜像来自tar归档或标准输入

```bash
导出一个容器作为镜像（导出是文件系统，不常用）
docker images export mynginx > mynginx.tar
docker images import mynginx.tar nginx-test

导出镜像（离线使用）
docker images save mynginx > mynginx.tar
docker images load mynginx.tar
```


# 容器管理

## 创建容器


指令 | 描述
---|---
-i, --interactive |交互式 
-t, --tty |分配一个伪终端 
-d, --detach |运行容器到后台 
-e, --env list |设置环境变量 
-p, --publish list |发布容器端口到主机 
-P, --publish-all |发布容器所有EXPOSE的端口到宿主机随机端
-h, --hostname string |设置容器主机名
--ip string |指定容器IP，只能用于自定义网络
--network |连接容器到一个网络
--mount mount |挂载宿主机分区到容器
-v, --volume list |挂载宿主机目录到容器
--restart string |容器退出时重启策略，默认no[always、on-failure]
    
资源限制指令 |描述
---|---
-m，--memory |容器可以使用的最大内存量
--memory-swap |允许交换到磁盘的内存量
--memory-swappiness=<0-100> |容器使用SWAP分区交换的百分比（0-100，默认为-1） 
--memory-reservation|内存软限制，Docker检测主机容器争用或内存不足时所激活的软限制，使用此选项，值必须设置低于—memory，以使其优先
--oom-kill-disable|当宿主机内存不足时，内核会杀死容器中的进程。建议设置了-memory选项再禁用OOM。如果没有设置，主机可能会耗尽内存
--cpus |限制容器可以使用多少可用的CPU资源
--cpuset-cpus |限制容器可以使用特定的CPU
--cpu-shares|此值设置为大于或小于默认1024值，以增加或减少容器的权重，并使其可以访问主机CPU周期的更大或更小比例

示例
```bash
内存限额:
允许容器最多使用500M内存和100M的Swap，并禁用 OOM Killer:
docker run -d --name nginx03 --memory="500m" --memory-swap="600m" --oom-kill-disable nginx

CPU限额:
允许容器最多使用一个半的CPU:
docker run -d --name nginx04 --cpus="1.5" nginx 允许容器最多使用50%的CPU:
docker run -d --name nginx05 --cpus=".5" nginx

```

## 管理命令

指令 |描述
---|---
ls |列出容器
inspect |显示一个或多个容器详细信息
attach |附加本地标准输入，输出和错误到一个运行的容器
exec |在运行容器中执行命令
commit |创建一个新镜像来自一个容器
cp |拷贝文件/文件夹到一个容器
logs |获取一个容器日志
port |列出或指定容器端口映射
stats |显示容器资源使用统计
top |显示一个容器运行的进程
update |更新一个或多个容器配置
stop/start |停止/启动一个或多个容器
rm |删除一个或多个容器

```bash
创建容器
docker container run -it -d -h mynginx --name mynginx -p 80:80 -e a=2 nginx
root@mynginx:/# echo $a
2

查看资源
docker container stats --no-stream mynginx

容器打镜像
docker container commit local:v1.1.1 mynginx

拷贝
docker container cp nginx.tar mynginx:/
docker container exec mynginx ls /
nginx.tar

删除
docker rm -f $(docker ps -aq)
```


# 数据管理

> Docker提供三种不同的方式将数据从宿主机挂载到容器中：volumes，bind mounts和tmpfs。

- volumes：Docker管理宿主机文件系统的一部分（/var/lib/docker/volumes）。
- bind mounts：可以存储在宿主机系统的任意位置。
- tmpfs：挂载存储在宿主机系统的内存中，而不会写入宿主机的文件系统。


## Volume

指令|描述
---|---
create |创建一个卷    
inspect |检查显示一个或多个卷上的详细信息    
ls |列表卷     
prune |删除所有未使用的本地卷     
rm |删除一个或多个卷
  

- 管理卷
```bash
docker volume create nginx-vol 
docker volume ls
docker volume inspect nginx-vol
```

- 用卷创建一个容器
```bash
docker run -d --name=nginx-test --mount type=volume,src=nginx-vol,dst=/usr/share/nginx/html nginx 
docker run -d --name=nginx-test -v nginx-vol:/usr/share/nginx/html nginx
```

- 清理
```bash
docker stop nginx-test
docker rm nginx-test
docker volume rm nginx-vol
```

> 注意：
1. 如果没有指定卷，自动创建。
2. 建议使用--mount，更通用。


## bind mounts

- 用卷创建一个容器:
```bash
docker run -d --name=nginx-test --mount type=bind,src=/app/wwwroot,dst=/usr/share/nginx/html nginx # docker run -d --name=nginx-test -v /app/wwwroot:/usr/share/nginx/html nginx
```
- 验证绑定:
```bash
docker inspect nginx-test
```
- 清理:
```bash
docker stop nginx-test # docker rm nginx-test
```

> 注意：
1. 如果源文件/目录没有存在，不会自动创建，会抛出一个错误。所以要提前创建
2. 如果挂载目标在容器中非空目录，则该目录现有内容将被隐藏。


Volume特点:
- 多个运行容器之间共享数据，多个容器可以同时挂载相同的卷。 
- 当容器停止或被移除时，该卷依然存在。
- 当明确删除卷时，卷才会被删除。
- 将容器的数据存储在远程主机或其他存储上(间接)。
- 将数据从一台Docker主机迁移到另一台时，先停止容器，然后备份卷的目录(/var/lib/docker/volumes/)。

Bind Mounts特点:

- 从主机共享配置文件到容器。默认情况下，挂载主机/etc/resolv.conf到每个容器，提供DNS解析。
- 在Docker主机上的开发环境和容器之间共享源代码。例如，可以将Maven target目录挂载到容器中，每次在Docker主机上构建Maven项目时，容器都可以访问构建的项目包。
- 当Docker主机的文件或目录结构保证与容器所需的绑定挂载一致时。

# 网络模式

- bridge
> –net=bridge <br> 默认网络，Docker启动后创建一个docker0网桥，默认创建的容器也是添加到这个网桥中。
- host
> –net=host <br> 容器不会获得一个独立的network namespace，而是与宿主机共用一个。这就意味着容器不会有自己的网卡信息，而是使用宿主机的。容器除了网络，其他都是隔离的。
- none <br> 
> –net=none <br> 获取独立的network namespace，但不为容器进行任何网络配置，需要我们手动配置。
- container 
> –net=container:Name/ID <br> 与指定的容器使用同一个network namespace，具有同样的网络配置信息，两个容器除了网络，其他都还是隔离的。
- 自定义网络
> 与默认的bridge原理一样，但自定义网络具备内部DNS发现，可以通过容器名容器之间网络通信。

## 容器网络访问原理
![image](https://www.liqianlong.cn/rongqiwangluo1.png)

eth0与veth是成对出现的，veth存在于宿主机上，eth0在容器内，容器内通信到达eth0--veth收到通信--发给docker0网关--进行SNAT--宿主机eth0出去了。

![image](https://www.liqianlong.cn/rongqiwangluo2.png)

## 管理命令

指令|描述
---|---
connect     |将容器连接到网络
create      |创建一个网络
disconnect  |断开从网络上断开容器的连接
inspect     |检查在一个或多个网络上显示详细信息
ls          |网络列表
prune       |删除所有未使用的网络
rm          |rm删除一个或多个网络

- 创建网络
```bash
docker network create mynet
```

- 创建容器
```bash
docker run -it --rm --name busybox1(2) --network mynet busybox sh
```

- 验证
```bash
# ping busybox1
PING busybox1 (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.125 ms
```

# dockerfile

1. Dockerfile格式
2. Dockerfile指令
3. Build镜像
4. 构建Nginx，PHP，Tomcat基础镜像
5. 快速搭建LNMP网站平台


## Dockerfile格式
![image](https://www.liqianlong.cn/dockerfile_geshi.png)


## Dockerfile指令

<div style="width:100px">指令</div> | 描述 
---|---
FROM |指定基础镜像 例如：FROM centos:7
MAINTAINER |镜像维护者姓名或邮箱地址例如：MAINTAINER liqianlong，但是现在是LABEL maintainer liqianlong
RUN | 用来执行命令 shell 格式：RUN <命令> <br> exec 格式：RUN ["可执行文件", "参数1", "参数2"]
CMD |运行容器时执行的Shell命令 shell 格式：CMD <命令> <br> exec 格式：CMD ["可执行文件", "参数1", "参数2"...] <br> shell 格式的话，实际的命令会被包装为 sh -c 的参数的形式进行执行 CMD [ "sh", "-c", "echo $HOME" ]，只能一个
EXPOSE |声明运行时容器提供服务端口：EXPOSE 80 443
ENV |格式有两种：<br> ENV <key> <value> <br> ENV <key1>=<value1> <key2>=<value2>...
ADD |如果<源路径>为一个tar压缩文件的话，压缩格式为gzip, bzip2以及xz的情况下，ADD指令将会自动解压缩这个压缩文件到 <目标路径> 去,不建议使用了。
COPY |拷贝文件或目录到镜像，可以通配符。用法例如：COPY hom* /mydir/
ENTRYPOINT |格式和CMD指令格式一样,dockerfile里面有ENTRYPOINT和CMD的话，CMD参数会追加到ENTRYPOINT参数的后面，在启动容器的时候，如果给予命令CMD参数将会被覆盖，注意dockerfile里面ENTRYPOINT只有最后一个生效
VOLUME |VOLUME ["<路径1>", "<路径2>"...] <br> VOLUME <路径>
WORKDIR |格式为：WORKDIR <工作目录路径> 使用WORKDIR指令可以来指定工作目录（或者称为当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，WORKDIR会帮你建立目录
USER |格式：USER <用户名>[:<用户组>],USER指令和WORKDIR相似，都是改变环境状态并影响以后的层。WORKDIR是改变工作目录，USER则是改变之后层的执行RUN, CMD以及ENTRYPOINT这类命令的身份。当然，和WORKDIR一样，USER只是帮助你切换到指定用户而已，这个用户必须是事先建立好的，否则无法切换


## Build镜像

> docker build [选项] <上下文路径/URL/->

- -t, --tag list # 镜像名称,版本
- -f, --file string # 指定Dockerfile文件位置 


```bash
docker build -t nginx:v1 .
.表示，如果dockfile中用到了copy，代表容器内目录
```
	
## 构建Nginx，PHP，Tomcat基础镜像

### 构建PHP基础镜像

```bash
FROM centos:7
LABEL maintainer liqianlong
RUN yum install epel-release -y && \
    yum install -y gcc gcc-c++ make gd-devel libxml2-devel \
    libcurl-devel libjpeg-devel libpng-devel openssl-devel \
    libmcrypt-devel libxslt-devel libtidy-devel autoconf \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*

RUN wget http://docs.php.net/distributions/php-5.6.36.tar.gz && \
# COPY php-5.6.36.tar.gz /
RUN tar zxf php-5.6.36.tar.gz && \
    cd php-5.6.36 && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-fpm --enable-opcache \
    --with-mysql --with-mysqli --with-pdo-mysql \
    --with-openssl --with-zlib --with-curl --with-gd \
    --with-jpeg-dir --with-png-dir --with-freetype-dir \
    --enable-mbstring --with-mcrypt --enable-hash && \
    make -j 2 && make install && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp sapi/fpm/php-fpm.conf /usr/local/php/etc/php-fpm.conf && \
    sed -i "90a \daemonize = no" /usr/local/php/etc/php-fpm.conf && \
    mkdir /usr/local/php/log && \
    cd / && rm -rf php* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/php/sbin
COPY php.ini /usr/local/php/etc/
COPY php-fpm.conf /usr/local/php/etc/
WORKDIR /usr/local/php
EXPOSE 9000
CMD ["php-fpm"]
```
- 构建镜像
```bash
docker build -t php:v1 Dockerfile-php .
```

### 构建Nginx基础镜像

```bash
FROM centos:7
LABEL maintainer liqianlong
RUN yum install -y gcc gcc-c++ make \
    openssl-devel pcre-devel gd-devel \
    iproute net-tools telnet wget curl && \
    yum clean all && \
    rm -rf /var/cache/yum/*
# COPY nginx-1.15.5.tar.gz /usr/local/src
WORKDIR /usr/local/src
RUN wget http://nginx.org/download/nginx-1.15.5.tar.gz && \
RUN tar zxf nginx-1.15.5.tar.gz && \
    cd nginx-1.15.5 && \
    ./configure --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module && \
    make -j 2 && make install && \
    rm -rf /usr/local/nginx/html/* && \
    echo "ok" >> /usr/local/nginx/html/status.html && \
    rm -rf nginx-1.15.5* && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/nginx/sbin
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
WORKDIR /usr/local/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

- 构建镜像
```bash
docker build -t nginx:v1 Dockerfile-nginx .
```

### 构建tomcat基础镜像

```bash
FROM centos:7
LABEL maintainer liqianlong

ENV VERSION=8.5.43

RUN yum install java-1.8.0-openjdk wget curl unzip iproute net-tools -y && \
    yum clean all && \
    rm -rf /var/cache/yum/*

RUN wget http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz && \
# COPY apache-tomcat-8.5.43.tar.gz /
RUN tar zxf apache-tomcat-${VERSION}.tar.gz && \
    mv apache-tomcat-${VERSION} /usr/local/tomcat && \
    rm -rf apache-tomcat-${VERSION}.tar.gz /usr/local/tomcat/webapps/* && \
    mkdir /usr/local/tomcat/webapps/test && \
    echo "ok" > /usr/local/tomcat/webapps/test/status.html && \
    sed -i '1a JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"' /usr/local/tomcat/bin/catalina.sh && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV PATH $PATH:/usr/local/tomcat/bin

WORKDIR /usr/local/tomcat

EXPOSE 8080
CMD ["catalina.sh", "run"]

```
- 构建镜像

```bash
docker build -t tomcat:v1 Dockerfile-tomcat .
```

## 快速部署LNMP网站平台
![image](https://www.liqianlong.cn/docker_lnmp.png)


1、 自定义网络

```bash
docker network create lnmp
```

2、 创建Mysql容器

```bash
docker container run -d \
--name lnmp_mysql \
--net lnmp \
--mount type=volume,src=mysql-vol,dst=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
-e MYSQL_DATABASE=wordpress \
mysql:5.7 \
--character-set-server=utf8
```

3、创建PHP容器
```bash
docker run -d --name lnmp_php --net lnmp --mount type=volume,src=wwwroot,dst=/wwwroot php:v1
```

4、创建Nginx容器
```bash
docker run -d --name lnmp_nginx --net lnmp -p 88:80 --mount type=volume,src=wwwroot,dst=/wwwroot nginx:v1
```
> 注意的是，nginx.conf传给Php解析分析的时候，Ip端口是自定义的网桥lnmp。

5、以wordpress博客为例

```bash
https://cn.wordpress.org/wordpress-4.9.4-zh_CN.tar.gz
解压后放在/var/lib/docker/volumes/wwwroot/_data下。
```
> 连接mysql要用容器名lnmp_mysql，而不是Ip。


# 企业级镜像仓库harbor

> Harbor是由VMWare公司开源的容器镜像仓库。事实上，Harbor是在Docker Registry上进行了相应的企业级扩展，从而获得了更加广泛的应用，这些新的企业级特性包括：管理用户界面，基于角色的访问控制 ，AD/LDAP集成以及审计日志等，足以满足基本企业需求。官方地址:https://vmware.github.io/harbor/cn/

<div style="width:130">组件<div/> |功能
---|---
harbor-adminserver |配置管理中心
harbor-db |Mysql数据库
harbor-jobservice |负责镜像复制
harbor-log |记录操作日志
harbor-ui |Web管理页面和AP
Inginx |前端代理，负责前端页面和镜像上传/下载转发
redis |会话
registry |镜像存储


## Harbor安装

`三种安装方式`

- 在线安装：从Docker Hub下载Harbor相关镜像，因此安装软件包非常小 
- 离线安装：安装包包含部署的相关镜像，因此安装包比较大
- OVA安装程序：当用户具有vCenter环境时，使用此安装程序，在部署OVA后启动Harbor

> 注意

- 需要提前安装好docker
- 需要安装compose

> harbor compost下载地址

` https://github.com/docker/compose/releases`

`https://github.com/goharbor/harbor/releases`

```bash
tar -zxf harbor-offline-installer-v1.7.5.tgz -C /usr/local/

vi harbor.cfg
hostname = harbor.liqianlong.cn
ui_url_protocol = http
harbor_admin_password = 12345

./prepare
./install.sh

cp docker-compose-Linux-x86_64 /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
```

> 日志

`/var/log/harbor`

> 登录harbor

`使用admin/12345登录harbor`

## 基本使用

- 配置http镜像仓库可信任
访问harbor地址时候是http，所以需要添加仓库信任，如果是https可以不用。

```bash
cat /etc/docker/daemon.json 
{
"registry-mirrors": [ "http://f1361db2.m.daocloud.io"],
"insecure-registries":["harbor.liqianlong.cn"]
}
```

- 给镜像打标签

`docker tag nginx:v1 harbor.liqianlong.com/library/nginx:v1`

- 登录Harbor（推送镜像是要求要登录）

`docker login harbor.liqianlong.cn`

- 推送镜像（上传，确保有项目已创建）

`docker push harbor.liqianlong.cn/library/nginx:v1`

- 登出Harbor

`docker logout harbor.liqianlong.cn`

- 拉镜像（下载，公开仓库不需要登录）

`docker pull harbor.liqianlong.cn/library/nginx:v1`


# 基于Docker构建企业Jenkins CI平台

1. 什么是CI/CD
2. CI流程
3. 部署Git代码版本仓库 
4. 上传Java项目代码
5. 部署Harbor镜像仓库 
6. 配置JDK和Maven环境 
7. 安装Jenkins
8. 安装Docker
9. 构建Tomcat基础镜像 
10. 流水线发布测试


## 什么是CI/CD

- 持续集成(ContinuousIntegration，CI):代码合并、构建、部署、测试都在一起，不断地执行这个过程，并对结果反馈。 

- 持续部署(ContinuousDeployment，CD):部署到测试环境、预生产环境、生产环境。

- 持续交付(Continuous Delivery，CD):将最终产品发布到生产环境，给用户使用。

![image](https://www.liqianlong.cn/docker_cicd.png)

高效的CI/CD环境可以获得: 
- 及时发现问题
- 大幅度减少故障率
- 加快迭代速度
- 减少时间成本

## CI流程
![image](https://www.liqianlong.cn/docker_cishuoming1.png)

![image](https://www.liqianlong.cn/docker_cishuoming2.png)

## 3-10部署

- 实验环境

主机名 | 安装清单
---|---
10.10.10.20 | jenkins+git(客户端)
10.10.10.21 | harbor+git(服务端)


> 10.10.10.21(git服务端)

```bash
yum install -y git
useradd git
passwd git
su - git
mkdir tomcat-java-demo.git
cd tomcat-java-demo.git/
git --bare init 初始化仓库
```

> 10.10.10.21(harbor略)


> 10.10.10.20(git客户端)

```bash
yum install -y git
ssh-keygen -t rsa
ssh-copy-id git@10.10.10.21
代码文件
git clone https://gitee.com/jokerbj/tomcat-java-demo.git
mv tomcat-java-demo demo
10.10.10.21git服务端代码
git clone git@10.10.10.21:/home/git/tomcat-java-demo.git
mv  demo/* tocamt-java-demo/
cd tocamt-java-demo
git add .
git commit -m "first commit"
git push origin master
```

## 10.10.10.20(tomcat,maven,jdk安装略)


## 10.10.10.20(jenkins安装略,插件git pipeline)

清华源
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

unzip jenkins.war -d /usr/local/tomcat/webapps/ROOT

## 10.10.10.20(hosts)

```bash
cat /etc/hosts 
10.10.10.21 harbor.liqianlong.cn
```

## 10.10.10.20创建流水线项目

> java-hello 构建测试

```
node {
   stage('git clone') { 
   }
   stage('build') {
   }
   stage('deploy') {
   }
}
```

- pipeline脚本如下

> 注意修改jdk，mvn路径，harbor地址

```bash
node () {  
   // 拉取代码
   stage('Git Checkout') { 
	    checkout([$class: 'GitSCM', branches: [[name: '$Branch']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '52e2be15-f2d7-472e-bd6e-41015a26e567', url: 'git@10.10.10.21:/home/git/tomcat-java-demo.git']]])
   }
   // 代码编译
   stage('Maven Build') {
        sh '''
        export JAVA_HOME=/usr/local/jdk1.8.0_91
        /usr/local/apache-maven-3.5.3/bin/mvn clean package -Dmaven.test.skip=true
        '''
   }
   // 项目打包到镜像并推送到镜像仓库
   stage('Build and Push Image') {
        sh '''
        REPOSITORY=harbor.liqianlong.cn/library/java-demo:${Branch}
        cat > Dockerfile << EOF
        FROM harbor.liqianlong.cn/library/tomcat:v1
        LABEL maintainer liqianlong
        RUN rm -fr /usr/local/tomcat/webapps/*
        ADD target/*.war /usr/local/tomcat/webapps/ROOT.war
        EOF
        
        docker build -t $REPOSITORY .
        docker login harbor.liqianlong.cn -u admin -p 12345
        docker push $REPOSITORY
        '''
   }
   // 部署到Docker主机
   stage('Deploy to Docker') {
        sh '''
        REPOSITORY=harbor.liqianlong.cn/library/java-demo:${Branch}
        docker comtainer rm -f tomcat-java-demo |true
        docker container run -d --name tomcat-java-demo -p 88:8080 $REPOSITORY
        '''
   }
}
```

# Jar包的Dockerfile
```bash
FROM java:8-jdk-alpine
LABEL maintainer liqianlong
ENV JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF8 -Duser.timezone=GMT+08"
RUN  apk add -U tzdata && \
     ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY ./target/product-service-biz.jar ./
EXPOSE 8010
CMD java -jar $JAVA_OPTS /product-service-biz.jar
```