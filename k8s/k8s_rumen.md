

# 一 资源编排（yaml）

1. YAML文件格式说明
2. YAML文件创建资源对象
3. 资源字段太多，记不住怎么办

## 1.1 YAML文件格式说明

YAML 是一种简洁的非标记语言

> 语法格式

- 缩进表示层级关系
- 不支持制表符“tab”缩进，使用空格缩进
- 通常开头缩进 2 个空格
- 字符后缩进 1 个空格，如冒号、逗号等
- “---” 表示YAML格式，一个文件的开始
- “#”注释

## 1.2 YAML文件创建资源对象

![yaml资源对象解释](https://www.liqianlong.cn/yamlziyuanjieshi.png)

```bash
创建文件资源对象
cat nginx-deploy.yaml 
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15
        ports:
        - containerPort: 80

暴露给外        
cat nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx-service 
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
    
验证
kubectl get pod,svc,ep -o wide

删除
Kubectl delete deploy nginx-deployment
kubectl delete svc nginx-service
```

## 1.3 资源字段太多，记不住怎么办

- 用create命令生成

`kubectl create deployment nginx --image=nginx:1.14 -o yaml --dry-run > my-deploy.yaml` <br>

要对`my-deploy.yaml`进行相对删除哦！！<br>

`kubectl create -f my-deploy.yaml`

- 用get命令导出，导出来就是上面命令生成的

`kubectl get deploy nginx -o yaml --export > my-deploy2.yaml`

- Pod容器的字段拼写忘记了

`kubectl explain pods.spec.containers`


# 二 深入理解pod对象

1. Pod容器分类
2. 镜像拉取策略
3. 资源限制
4. 重启策略
5. 健康检查
6. 调度约束
7. 故障排查

## 2.1 Pod

- 最小部署单元
- 一组容器的集合
- 一个Pod中的容器共享网络命名空间
- Pod是短暂的

## 2.2 Pod容器分类

- Infrastructure Container：基础容器
  - docker ps / pause:3.0 官方命名的，维护整个Pod网络空间的
- InitContainers：初始化容器
  - 先于业务容器开始执行，可以做一些检测，初始化的操作
- Containers：业务容器
  - 并行启动

```bash
containers:
    - image: nginx:1.14
      name: nginx
	- image: php:1.15
      name: php	
```

## 2.3 镜像拉取策略（imagePullPolicy）

- IfNotPresent：默认值，镜像在宿主机上不存在时才拉取
- Always：每次创建 Pod 都会重新拉取一次镜像
- Never： Pod 永远不会主动拉取这个镜像

```bash
cat my-deploy2.yaml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.14
        ==imagePullPolicy: IfNotPresent==
        name: nginx
```

> docker私有仓库认证拉取

```bash
NAME 创建的名字
kubectl create secret docker-registry -help
kubectl create secret docker-registry NAME --docker-username=user --docker-password=password --docker-email=email [--docker-server=string] [--from-literal=key1=value1] [--dry-run]
```
> 假如上面的仓库地址是harbor.liqianlong.cn，账号harbor，密码12345

`kubectl create secret docker-registry harborcert --docker-username=harbor --docker-password=12345 --docker-server=harbor.liqianlong.cn`


```bash
cat my-deploy2.yaml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - image: harbor.liqianlong.cn/library/nginx:1.14==
        name: nginx
      ==imagePullSecrets:
        - name: harborcert==
```
https://kubernetes.io/docs/concepts/containers/images/

## 2.4 资源限制

requests：想要多大的资源，分配参考 <br>
limits：限制死的资源，资源限制 <br>
能写数字


Pod和Container的资源请求和限制：
- spec.containers[].resources.requests.cpu
- spec.containers[].resources.requests.memory
- spec.containers[].resources.limits.cpu
- spec.containers[].resources.limits.memory

```bash
cat nginx-deploy-xianzhi.yaml 
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15
        ports:
        - containerPort: 80
      ==resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"==
```
https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/

## 2.5 重启策略（restartPolicy）

- Always：当容器终止退出后，总是重启容器，默认策略。
- OnFailure：当容器异常退出（退出状态码非0）时，才重启容器。
- Never：当容器终止退出，从不重启容器。一次性任务就是不希望重启

```bash
cat busy.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: busybox:1.28.4
    command:
    - sleep
    - "36000"
    imagePullPolicy: IfNotPresent
  ==restartPolicy: Always==
```

https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/

## 2.6 健康检查（Probe）

Probe有以下两种类型：
- livenessProbe<br>
   如果检查失败，将杀死容器，根据Pod的restartPolicy来操作。
- readinessProbe<br>
   如果检查失败，Kubernetes会把Pod从service endpoints中剔除。

Probe支持以下三种检查方法：
- httpGet<br>
   发送HTTP请求，返回200-400范围状态码为成功。
- exec<br>
   执行Shell命令返回状态码是0为成功。
- tcpSocket<br>
   发起TCP Socket建立成功。

```bash
cat probe.yaml 
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c 
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    ==livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy==
      initialDelaySeconds: 5
      periodSeconds: 5
```

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/

## 2.7 调度约束

![调度约束](https://www.liqianlong.cn/diaoduyueshu.png)

> create pod --> apiserver --> write etcd --> scheduler --> bind pod --> apiserver --> write --> etcd --> kubelet(bound pod) --> docker --> update pods status --> apiserver --> etcd


> nodename,用于将Pod调度到指定的Node名称上

```bash
cat scheduler.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-example
  labels:
    app: nginx
spec:
  ==nodeName: k8s-node1==
  containers:
  - name: nginx
    image: nginx:1.15
```

> nodeSelector,用于将Pod调度到匹配Label的Node上

给Node打上标签

```bash
kubectl label node k8s-node1 team=dev1
kubectl label node k8s-node2 team=dev2
```

查看打的标签

```bash
kubectl get node --show-labels
```

```bash
cat scheduler2.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-example
  labels:
    app: nginx
spec:
 == nodeSelector:
    team: dev2==
  containers:
  - name: nginx
    image: nginx:1.15
```

## 2.8 故障排查

值	|描述
---|---
Pending	|Pod创建已经提交到Kubernetes。但是，因为某种原因而不能顺利创建。例如下载镜像慢，调度不成功。
Running	|Pod已经绑定到一个节点，并且已经创建了所有容器。至少有一个容器正在运行中，或正在启动或重新启动。
Succeeded|	Pod中的所有容器都已成功终止，不会重新启动。
Failed	|Pod的所有容器均已终止，且至少有一个容器已在故障中终止。也就是说，容器要么以非零状态退出，要么被系统终止。
Unknown	|由于某种原因apiserver无法获得Pod的状态，通常是由于Master与Pod所在主机kubelet通信时出错。
CrashLoopBackOff|	


kubectl describe TYPE/NAME <br>
kubectl logs TYPE/NAME <br>
kubectl exec POD

https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/

# 三 部署应用常用控制器(也叫工作负载)

1. Deployment
2. DaemonSet
3. Job
4. CronJob

## 3.1 Pod与controllers的关系

- controllers：在集群上管理和运行容器的对象
- 通过label-selector相关联
- Pod通过控制器实现应用的运维，如伸缩，滚动升级等

![Pod与controllers关系](https://www.liqianlong.cn/pod_controllers.png)


## 3.2 Deployment

- 部署无状态应用
- 管理Pod和ReplicaSet
- 具有上线部署、副本设定、滚动升级、回滚等功能
- 提供声明式更新，例如只更新一个新的Image

> 应用场景：Web服务，微服务，不用考虑固定网络，数据的状态

```bash
cat my-deploy.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.14
        name: nginx
```

## 3.3 DaemonSet
- 在每一个Node上运行一个Pod
- 新加入的Node也同样会自动运行一个Pod

> 应用场景：Agent，Flannel

https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/


## 3.4 Job

Job分为普通任务（Job）和定时任务（CronJob）

- Job 一次性执行

> 应用场景：离线数据处理，视频解码等业务

```bash
cat job.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4

查看  
kubectl logs pod pi-6vbms/3.1415926
清理，没有暴露端口，不用删除service
kubectl delete -f job.yaml
kubectl delete job pi
```
back off Limit重启次数，默认6

https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/

- CronJob 定时任务，像Linux的Crontab一样

> 应用场景：通知，备份

```bash
cat crontab.yaml 
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c 
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure

查看          
kubectl logs hello-1567569300-xt5fd
Wed Sep  4 03:55:26 UTC 2019
Hello from the Kubernetes cluster
清理，没有暴露端口，不用删除service
kubectl delete -f crontab.yaml
kubectl delete crontab hello
```

https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/

## 3.5 小结

- Deployment：无状态部署
- DaemonSet：守护进程部署
- Job & CronJob：批处理


# 四 Service  统一入口访问应用

1. Pod与Service的关系
2. Service类型
3. Service代理模式
4. DNS

## 4.1 Service

- 防止Pod失联（服务发现）
- 定义一组Pod的访问策略（负载均衡）
- 支持ClusterIP，NodePort以及LoadBalancer三种类型
- Service的底层实现主要有iptables和ipvs二种网络模式

## 4.2 Pod与Service的关系

- 通过label-selector相关联
- 通过Service实现Pod的负载均衡（ TCP/UDP 4层）

![Pod与Service的关系](https://www.liqianlong.cn/pod_service.png)


## 4.3 Service类型

- ClusterIP：分配一个内部集群IP地址，只能在集群内部访问（同Namespace内的Pod），默认ServiceType。
- ClusterIP 模式的 Service 为你提供的，就是一个 Pod 的稳定的 IP 地址，即 VIP。

---

- NodePort：分配一个内部集群IP地址，并在每个节点上启用一个端口来暴露服务，可以在集群外部访问。
- 访问地址：<NodeIP>:<NodePort>

---

- LoadBalancer：分配一个内部集群IP地址，并在每个节点上启用一个端口来暴露服务。
- 除此之外，Kubernetes会请求底层云平台上的负载均衡器，将每个Node（[NodeIP]:[NodePort]）作为后端添加进去。

> 下面的yaml文件创建资源模板，配合service类型暴露统一入口

```bash
cat nginx-deploy.yaml 
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15
        ports:
        - containerPort: 80
```

### 4.3.1 集群内部 clusterIP 集群内部

![clusterip](https://www.liqianlong.cn/clusterip.png)

```bash
cat cluster.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx-deployment
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
```

> get pod/svc/ep，clusterip就是vip，通过ep可以看到ip对应的pod ip，通过curl clusterip（service + ip）就可以访问nginx



### 4.3.2 集群外部 nodeport

访问就是nodeip+port就可以了,默认三万起端口,一般node不会暴漏公网，不会让用户访问NODE节点，所以要在service前面做个LB

![nodeport](https://www.liqianlong.cn/nodeport.png)

```bash
cat nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service 
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
```


### 4.3.3 负载模式 loadBalancer

自动注册到公有云LB，然后自动监听后端端口，不需要手动添加

![loadBalancer](https://www.liqianlong.cn/loadbalancer.png)



## 4.4 Service 代理模式

![代理模式](https://www.liqianlong.cn/dailimoshi.png)

Iptables VS IPVS 1.13版本之后支持

> Iptables： 

- 灵活，功能强大
- 规则遍历匹配和更新，呈线性时延
- 可扩展性

> IPVS： 

- 工作在内核态，有更好的性能
- 调度算法丰富：rr，wrr，lc，wlc，ip hash...

> 开启ipvs

```bash
启用ipvs模式：节点操作，内核肯定集成了，但是需要启用

# node节点开启Ipvs转发
lsmod|grep ip_vs
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4

# master修改kube-proxy配置
kubectl describe cm kube-proxy -n kube-system

kubectl edit configmap kube-proxy -n kube-system
修改mode模式为ipvs默认是空，也就是Iptables
二进制也是需要更改Kube-proxy配置文件。

# master重启或者重建kube-proxy
kubectl delete pod xxx -n kube-system

# node节点安装ipvsadm工具
yum install ipvsadm 

# node节点使用ipvsadm查看转发规则
ipvsadm -ln
```

> srevice转发分析

在node上，通过iptab-svae|more（KUBE-NODEPORTS，KUBE-SERVICES），-j 重定向到另一条规则，也可以通过iptables -nL -t nat查看
dnat  转发模式

## 4.5 DNS

DNS服务监视Kubernetes API，为每一个Service创建DNS记录用于域名解析。

```bash
cat busy.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: busybox:1.28.4
    command:
    - sleep
    - "36000"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

进入busybox容器使用nslookup进行对service的解析，一般格式`nslookup service+namespace`

```bash
nslookup kubernetes.default
nslookup kubernetes-dashboard.kube-system
```

https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/coredns


## 4.6 小结

1. 采用NodePort对外暴露应用，前面加一个LB实现统一访问入口
2. 优先使用IPVS代理模式
3. 集群内应用采用DNS名称访问






