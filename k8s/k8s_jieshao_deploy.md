


# 一、Kubernetes概述

## 1.1 Kubernetes是什么

- Kubernetes是Google在2014年开源的一个容器集群管理系统，Kubernetes简称K8S。
- **K8S用于容器化应用程序的部署，扩展和管理**。
- **K8S提供了容器编排，资源调度，弹性伸缩，部署管理，服务发现等一系列功能**。
- Kubernetes目标是让部署容器化应用简单高效。


## 1.2 Kubernetes特性

- **自我修复**
    - 在节点故障时重新启动失败的容器，替换和重新部署，**保证预期的副本数量**；杀死健康检查失败的容器，并且在未准备好之前不会处理客户端请求，确保线上服务不中断。
- **弹性伸缩**
    - 使用命令、UI或者基于CPU使用情况自动快速扩容和缩容应用程序实例，保证应用业务高峰并发时的高可用性；业务低峰时回收资源，**以最小成本运行服务**。
- **自动部署和回滚**
    - K8S采用滚动更新策略更新应用，一次更新一个Pod，而不是同时删除所有Pod，如果更新过程中出现问题，将回滚更改，**确保升级不受影响业务**。
- **服务发现和负载均衡**
    - K8S为多个容器**提供一个统一访问入口**（内部IP地址和一个DNS名称），并且负载均衡关联的所有容器，使得**用户无需考虑容器IP问题**。
- **机密和配置管理**
    - 管理机密数据和应用程序配置，而不需要把敏感数据暴露在镜像里，提高敏感数据安全性。并可以将一些常用的配置存储在K8S中，方便应用程序使用。
- **存储编排**
    - 挂载外部存储系统，无论是来自本地存储，公有云（如AWS），还是网络存储（如NFS、GlusterFS、Ceph）都**作为集群资源的一部分使用**，极大提高存储使用灵活性。
- **批处理**
    - 提供一次性任务，定时任务；满足批量数据处理和分析的场景。

## 1.3 Kubernetes集群架构与组件
![image](https://www.liqianlong.cn/k8sjiqunjiagou.png)

kubectl是管理集群工具，请求给apiserver，apiserver交给scheduler（调度器选取节点）,选取好后会返回给apisever，这时候就会有告诉controller-manager创建多少副本，在那个节点上。也会告诉节点kubelet，这样master和Node才能通信。kubelet就会调用docker api去创建。kube-proxy，容器代理功能，如何访问。这五个组件是必须的，apiserver尤其重要。

## 1.4 Kubernetes集群组件介绍

### 1.4.1 Master组件

- **kube-apiserver**
    - Kubernetes API，==集群的统一入口==，各组件协调者，以RESTful API提供接口服务，所有对象资源的增删改查和监听操作都交给APIServer处理后再提**交给Etcd存储**。
- **kube-scheduler**
    - 根据调度算法为新创建的Pod选择一个Node节点，可以任意部署,可以部署在同一个节点上,也可以部署在不同的节点上。
- **kube-controller-manager**
    - 处理集群中常规后台任务，一个资源对应一个控制器，而ControllerManager就是负责管理这些控制器的。
- **etcd**
    - 分布式键值存储系统。用于保存集群状态数据，比如Pod、Service等对象信息。

### 1.4.2 Node组件

- **kubelet**
    - kubelet是Master在Node节点上的Agent，管理本机运行容器的生命周期，比如创建容器、Pod挂载数据卷、下载secret、获取容器和节点状态等工作。kubelet将每个Pod转换成一组容器。
- **kube-proxy**
    - 在Node节点上实现Pod网络代理，维护网络规则和四层负载均衡工作。
- **docker或rocket**
    - 容器引擎，运行容器。


## 1.5 Kubernetes 核心概念
![image](https://www.liqianlong.cn/k8shexingainian.png)

- **Pod**
    - 最小部署单元
    - 一组容器的集合
    - **一个Pod中的容器共享网络命名空间**
    - Pod是短暂的
- **Controllers**
    - ReplicaSet ：确保预期的Pod副本数量
    - Deployment ：无状态应用部署
    - StatefulSet ：有状态应用部署
    - DaemonSet ：确保所有Node运行同一个Pod
    - Job ：一次性任务
    - Cronjob ：定时任务

**更高级层次对象，部署和管理Pod**

- **Service**
    - ==防止Pod失联==
    - ==定义一组Pod的访问策略==


- **Other**

    - Label ：标签，附加到某个资源上，用于关联对象、查询和筛选
    - Namespaces：命名空间，将对象逻辑上隔离
    - Annotations ：注释


# 二、快速部署K8S集群方式

## 2.1 kubernetes 官方提供的三种部署方式

- **minikube**

Minikube是一个工具，可以在本地快速运行一个单点的Kubernetes，仅用于尝试Kubernetes或日常开发的用户使用。
部署地址：https://kubernetes.io/docs/setup/minikube/

- **kubeadm**

Kubeadm也是一个工具，提供kubeadm init和kubeadm join，用于快速部署Kubernetes集群。
部署地址：https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/

- **二进制包**

推荐，从官方下载发行版的二进制包，手动部署每个组件，组成Kubernetes集群。
下载地址：https://github.com/kubernetes/kubernetes/releases


# 三、30分钟部署一个Kubernetes集群

## 3.1 安装kubeadm环境准备
> 以下操作,在三台节点都执行

### 3.2 环境需求
环境：centos 7.3 +

硬件需求： CPU>=2c ,内存>=2G


kubeadm是官方社区推出的一个用于快速部署kubernetes集群的工具。

这个工具能通过两条指令完成一个kubernetes集群的部署：

```
# 创建一个 Master 节点
$ kubeadm init

# 将一个 Node 节点加入到当前集群中
$ kubeadm join <Master节点的IP和端口 >
```


### 3.3 环境角色

IP | 角色 | 安装软件
---|---|---
192.168.31.61 | k8s-Master | kube-apiserver <br> kube-schduler <br> kube-controller-manager <br> docker <br>  flannel <br> kubelet
192.168.31.62 | k8s-node01 | kubelet <br> kube-proxy <br> docker <br> flannel
192.168.31.63 | k8s-node02 | kubelet <br> kube-proxy <br> docker <br> flannel


## 1. 安装要求

在开始之前，部署Kubernetes集群机器需要满足以下几个条件：

- 一台或多台机器，操作系统 CentOS7.x-86_x64
- 硬件配置：2GB或更多RAM，2个CPU或更多CPU，硬盘30GB或更多
- 集群中所有机器之间网络互通
- 可以访问外网，需要拉取镜像
- 禁止swap分区

## 2. 学习目标

1. 在所有节点上安装Docker和kubeadm
2. 部署Kubernetes Master
3. 部署容器网络插件
4. 部署 Kubernetes Node，将节点加入Kubernetes集群中
5. 部署Dashboard Web页面，可视化查看Kubernetes资源

## 3. 准备环境

```
关闭防火墙：
$ systemctl stop firewalld
$ systemctl disable firewalld

关闭selinux：
$ sed -i 's/enforcing/disabled/' /etc/selinux/config 
$ setenforce 0

关闭swap：
$ swapoff -a  $ 临时
$ vim /etc/fstab  $ 永久

添加主机名与IP对应关系（记得设置主机名）：
$ cat /etc/hosts
192.168.31.61 k8s-master
192.168.31.62 k8s-node1
192.168.31.63 k8s-node2

将桥接的IPv4流量传递到iptables的链：
$ cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sysctl --system
```

## 4. 所有节点安装Docker/kubeadm/kubelet

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。

### 4.1 安装Docker

```
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum -y install docker-ce-18.06.1.ce-3.el7
systemctl enable docker && systemctl start docker
docker --version
Docker version 18.06.1-ce, build e68fc7a
```

### 4.2 添加阿里云YUM软件源

```
$ cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

### 4.3 安装kubeadm，kubelet和kubectl

由于版本更新频繁，这里指定版本号部署：

```
yum install -y kubelet-1.15.0 kubeadm-1.15.0 kubectl-1.15.0
systemctl enable kubelet
```

## 5. 部署Kubernetes Master

在192.168.31.63（Master）执行。

```
kubeadm init \
  --apiserver-advertise-address=192.168.31.61 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.15.0 \
  --service-cidr=10.1.0.0/16 \
  --pod-network-cidr=10.244.0.0/16
```

由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址。

使用kubectl工具：

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes /NotReady状态
```

## 6. 安装Pod网络插件（CNI）

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```

确保能够访问到quay.io这个registery。

如果下载失败，可以改成这个镜像地址：lizhenliang/flannel:v0.11.0-amd64

## 7. 加入Kubernetes Node

在192.168.31.65/66（Node）执行。

向集群添加新节点，执行在kubeadm init输出的kubeadm join命令：

```
kubeadm join 192.168.31.63:6443 --token esce21.q6hetwm8si29qxwn \
    --discovery-token-ca-cert-hash sha256:00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
```

## 8. 测试kubernetes集群

`kubectl get nodes /Ready状态`

在Kubernetes集群中创建一个pod，验证是否正常运行：

```
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get pod,svc
kubectl delete deployment nginx
```

访问地址：http://NodeIP:Port  

## 9. 部署 Dashboard

在192.168.31.61（Master）执行。

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

默认镜像国内无法访问，在`Dashboard Deployment`的`containers:image`修改镜像地址为： lizhenliang/kubernetes-dashboard-amd64:v1.10.1

默认Dashboard只能集群内部访问，修改Service为NodePort类型，暴露到外部：
在`Dashboard Service`修改`ports:nodePort`

```
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
```
```
$ kubectl apply -f kubernetes-dashboard.yaml
```
访问地址：http://192.168.31.61:30001

创建service account并绑定默认cluster-admin管理员集群角色：

```
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
查看TOKEN
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```

## 10. 重新设置

`sudo kubeadm reset`

## 11. 解决https

删除默认的secret，用自签证书创建新的secret
```
kubectl delete secret kubernetes-dashboard-certs -n kube-system
生成证书切记不能再/etc/kubernetes/pki/目录下执行，这样会给所有组件刷新证书会出问题。
kubectl create secret generic kubernetes-dashboard-certs --from-file=./ -n kube-system
```

将证书放在与kubernetes-dashboard.yaml同级目录，最简单就是拷贝成功的证书。
```
cp /etc/kubernetes/pki/apiserver.crt dashboard.pem
cp /etc/kubernetes/pki/apiserver.key dashboard-key.pem 
```

修改 kubernetes-dashboard.yaml 文件，在args下面增加证书两行
```
args:
    - --auto-generate-certificates
    - --tls-cert-file=dashboard.pem
    - --tls-key-file=dashboard-key.pem
```
应用更新
```
kubectl apply -f kubernetes-dashboard.yaml
```

## 分析网络 

`iptables -n -v -L -t nat`

```bash
ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001

[root@k8s-master ~]# kubectl get endpoints -o wide -n kube-system
NAME                      ENDPOINTS                                               AGE
kubernetes-dashboard      10.244.2.4:8443                                         29h

[root@k8s-master ~]# kubectl get svc -o wide -n kube-system
NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
kubernetes-dashboard   NodePort    10.1.5.26    <none>        443:30001/TCP            29h   k8s-app=kubernetes-dashboard



Chain KUBE-NODEPORTS (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kubernetes-dashboard: */ tcp dpt:30001
    0     0 KUBE-SVC-XGLOHA7QRQ3V22RZ  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kubernetes-dashboard: */ tcp dpt:30001



KUBE-SERVICES
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !10.244.0.0/16        10.1.5.26            /* kube-system/kubernetes-dashboard: cluster IP */ tcp dpt:443
    0     0 KUBE-SVC-XGLOHA7QRQ3V22RZ  tcp  --  *      *       0.0.0.0/0            10.1.5.26            /* kube-system/kubernetes-dashboard: cluster IP */ tcp dpt:443


	
Chain KUBE-SVC-XGLOHA7QRQ3V22RZ (2 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-6LYTTFENITSGLYCX  all  --  *      *       0.0.0.0/0            0.0.0.0/0 	
	
	
Chain KUBE-SEP-6LYTTFENITSGLYCX (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       10.244.2.4           0.0.0.0/0           
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp to:10.244.2.4:8443
```



