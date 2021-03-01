

[toc]


# 一 从外部访问应用最佳方式


## 1.1 Pod与Ingress的关系

- 为何外部访问NODEPORT不是最好的选择

> nodeport是将端口暴露出去，访问需要节点IP+PORT访问，在创建NODEPORT时候，你需要维护这些端口是否占用，基于snat,dnat都是四层的，不能做七层的。端口转发性能可能会稍差一些，要经过防火墙的过滤。

- 具有全局的负载均衡器 ingress（实质规则）

> 暴漏端口一般都是80 443，然后转发到后端的站点上，实现上跟nginx工作原理是一样的。


![Pod与Ingress的关系](https://www.liqianlong.cn/POD%E4%B8%8EINGRESS%E7%9A%84%E5%85%B3%E7%B3%BB.png)

`ep 维持着pod和service的关系，通过Ingress Controller实现Pod的负载均衡，支持TCP/UDP 4层和HTTP 7层，基于域名的实现`



## 1.2 Ingress Controller （控制器实现）

1. 部署Ingress Controller

> 部署文档 ：https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md

`或直接下载 wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml`

- 控制器有很多种，比如istio，traefik，nginx ingress

注意事项：<br>
 • 镜像地址修改成国内的：lizhenliang/nginx-ingress-controller:0.20.0 <br>
 • 使用宿主机网络：hostNetwork: true （暴露端口）
 
```
spec:
  serviceAccountName: nginx-ingress-serviceaccount 
  hostNetwork: true
  containers:
  - name: nginx-ingress-controller
    image: lizhenliang/nginx-ingress-controller:0.20.0 

kubectl apply -f mandatory.yaml
kubectl get ns
kubectl get deploy -n ingress-nginx
kubectl get pod -o wide -n ingress-nginx
在node1上查看端口会有80 443的监听
```

https://kubernetes.io/docs/concepts/services-networking/ingress/

2. 创建Ingress规则

> 创建的规则一般都是放在了ingress控制器里，解析就要解析到控制器安装的node 的ip上，规则：域名+端口

提前：
`nginx-deploy.yaml nginx-svc.yaml`创建起来

- 创建规则其实就是针对service暴露
```
cat ingress.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: www.foo.com
    http:
      paths:
      - backend:
          ==serviceName: nginx-service ==
          servicePort: 80

kubectl create -f ingress.yaml          
kubectl get ingress
将service暴露出去
通过修改hosts，解析域名解析到Node的宿主机
```
> 请求流程 www.foo.com == nginx-service == (ep)POD


- 解决单点

第一种方案 LB
```bash
修改类型为dameset，replicas: 1 删除
kubectl delete -f mandatory.yaml
kubectl create -f mandatory2.yaml
kubectl get pod -n ingress-nginx -o wide
2个节点都有安装了，都可以看到80 443
user --> lb(vm-nginx 4c) --> node1/node2 --> pod，在通过nginx upstrem转发即可
```


第二种方案 做个HA keepavlied VIP

## 1.3 Ingress（HTTP与HTTPS）

创建证书工具
```
cat cfssl.sh 
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64 
mv cfssl_linux-amd64 /usr/local/bin/cfssl 
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson 
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```

创建证书
```
cat certs.sh 
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

cat > blog.ctnrs.com-csr.json <<EOF
{
  "CN": "blog.ctnrs.com",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes blog.ctnrs.com-csr.json | cfssljson -bare blog.ctnrs.com 

# 创建tls证书
kubectl create secret tls blog-ctnrs-com --cert=blog.ctnrs.com.pem --key=blog.ctnrs.com-key.pem
```
kubectl get secret
```
NAME                                 TYPE                                  DATA   AGE
blog-ctnrs-com                       kubernetes.io/tls                     2      5d21h
```
创建ingress-https
```
cat ingress-https.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
 == tls:
  - hosts:
    - blog.ctnrs.com
    secretName: blog-ctnrs-com==
  rules:
  - host: blog.ctnrs.com
    http:
      paths:
      - path: /
        backend:
          ==serviceName: nginx-service==
          servicePort: 80
          
kubectl apply -f ingress-https.yaml
kubectl get ingress
NAME                  HOSTS            ADDRESS   PORTS     AGE
example-ingress       www.foo.com                80        34m
tls-example-ingress   blog.ctnrs.com             80, 443   5d21h
```

## 1.4 访问过程

> user --> cdn --> waf/ddos lb(vm-nginx 4c) ingress-controller (node1/node2) --> pod

> user --> node(vip,ingress controller + keepavlied) --> pod

# 二 配置管理

## 2.1 Secret
> 加密数据并存放Etcd中，让Pod的容器以挂载Volume方式访问。
应用场景：凭据

Pod使用secret两种方式：<br>
• 变量注入 <br> 
• 挂载

随机生成变量
```
echo -n 'admin' | base64
YWRtaW4=
echo -n '1f2d1e2e67df' | base64
MWYyZDFlMmU2N2Rm
```

创建secret
```
cat secret.yaml 
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
  
kubectl -f secret.yaml
kubectl get secret
```

第一种变量注入
```
cat secret-pod1.yaml 
apiVersion: v1 
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: nginx
    image: nginx
    env:
      - name: SECRET_USERNAME
        valueFrom:
          secretKeyRef:
            ==name: mysecret
            key: username==
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            ==name: mysecret
            key: password==
            
kubectl create -f secret-pod1.yaml

验证
kubectl exec -it mypod bash
root@mypod:/# echo $SECRET_USERNAME
admin
```

`kubectl delete -f secret-pod1.yaml`

第二种方法挂载



```
cat secret-pod2.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  volumes:
  - name: foo 
    secret:
      ==secretName: mysecret==
  containers:
  - name: nginx
    image: nginx
    ==volumeMounts:
    - name: foo 
      readOnly: true
      mountPath: "/etc/foo"==
      
kubectl create -f secret-pod2.yaml
验证
kubectl exec -it mypod bash
root@mypod:/# cat /etc/foo/username 
admin
```

`kubectl delete -f secret-pod2.yaml`

https://kubernetes.io/docs/concepts/configuration/secret/

## 2.2 Configmap

> 与Secret类似，区别在于ConfigMap保存的是不需要加密配置信息。
应用场景：应用配置


env

```
cat configmap1.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myconfig
  namespace: default
data:
  special.level: info
  special.type: hello

---

apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: busybox
      image: busybox
      command: [ "/bin/sh", "-c", "echo $(LEVEL) $(TYPE)" ]
      ==env:
        - name: LEVEL
          valueFrom:
            configMapKeyRef:
              name: myconfig
              key: special.level
        - name: TYPE
          valueFrom:
            configMapKeyRef:
              name: myconfig
              key: special.type==
  restartPolicy: Never
  
kubectl create -f configmap1.yaml
kubectl get cm
验证
kubectl logs mypod
info hello
```

`kubectl delete -f configmap1.yaml`

Volume

```
cat configmap2.yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.properties: |
    redis.host=127.0.0.1
    redis.port=6379
    redis.password=123456

---

apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: busybox
      image: busybox
      command: [ "/bin/sh","-c","cat /etc/config/redis.properties" ]
      ==volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: redis-config==
  restartPolicy: Never

kubectl create -f configmap2.yaml 
验证
kubectl logs mypod
redis.host=127.0.0.1
redis.port=6379
redis.password=123456
```

`kubectl delete -f configmap2.yaml`


https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/


# 三 数据卷与数据持久卷

1. Volume
2. PersistentVolume
3. PersistentVolume 动态供给


## 3.1 Volume

• Kubernetes中的Volume提供了在容器中挂载外部存储的能力<br>
• Pod需要设置卷来源（spec.volume）和挂载点（spec.containers.volumeMounts）两个信息后才可
以使用相应的Volume

存储类型<br>
本地 hostPath，emptyDir<br>
网络 NFS，Ceph，Glusterfs<br>
公有云 AWS EBS<br>
K8S资源 configmap，secret

https://kubernetes.io/docs/concepts/storage/volumes/

### 3.1.1 本地存储 
emptyDir emptyDir = docker(volumes)

> 创建一个空卷，挂载到Pod中的容器。Pod删除该卷也会被删除。
应用场景：Pod中容器之间数据共享

```
cat emptydir.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: write
    image: centos
    command: ["bash","-c","for i in {1..100};do echo $i >> /data/hello;sleep 1;done"]
    volumeMounts:
    - name: data
      mountPath: /data
  
  - name: read
    image: centos
    command: ["bash","-c","tail -f /data/hello"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
    
kubectl create -f emptydir.yaml 
验证
kubectl logs my-pod -c read -f
```

`kubectl delete -f emptydir.yaml`

hostPath= bind mounts

> 挂载Node文件系统上文件或者目录到Pod中的容器。
应用场景：Pod中容器需要访问宿主机文件


```
cat hostpath.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: busybox
    image: busybox
    args:
    - /bin/sh
    - -c 
    - sleep 36000
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    hostPath:
      path: /tmp
      type: Directory
      
kubectl create -f hostpath.yaml
kubectl get pod -o wide
验证
在node节点/tmp创建文件，在容器里创建都是一样的效果
kubectl exec -it my-pod sh
ls /data
```

`kubectl delete -f hostpath.yaml`

### 3.1.2 网络存储

NFS

在master节点安装nfs服务
```
yum install -y nfs-utils
vi /etc/exports

设置共享目录
mkdir /opt/k8s
/opt/k8s 192.168.31.0/24(rw,no_root_squash)

node 节点测试可以挂载(也是需要安装的)
mount -t nfs 192.168.31.61:/opt/k8s /mnt
umount /mnt 
```

在k8s里面使用

```
cat nfs.yaml 
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: wwwroot
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80
      ==volumes:
      - name: wwwroot
        nfs:
          server: 192.168.31.61
          path: /opt/k8s==
          
kubectl create -f nfs.yaml
验证
kubectl exec -it nginx-deployment-d88d8f455-jgphg bash
df -h|grep k8s
192.168.31.61:/opt/k8s   18G  2.9G   14G  19% /usr/share/nginx/html
cd /usr/share/nginx/html/
echo helloword > index.html

kubectl get pod -o wide
curl 10.244.1.27
helloword
```

`kubectl delete -f nfs.yaml`



## 3.2 PersistentVolume(持久卷)
PersistentVolume（PV）：对存储资源创建和使用的抽象，使得存储作为集群中的资源管理<br>
- 静态
- 动态

PersistentVolumeClaim（PVC）：让用户不需要关心具体的Volume实现细节

### 3.2.1 静态供给

![PV静态供给](https://www.liqianlong.cn/PV%E9%9D%99%E6%80%81%E4%BE%9B%E7%BB%99.png)

先创建PV

```
cat pv1.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteMany
  nfs:
    path: /opt/k8s/001
    server: 192.168.31.61
    
cat pv2.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteMany
  nfs:
    path: /opt/k8s/002
    server: 192.168.31.61

kubectl create -f pv1.yaml
kubectl create -f pv2.yaml
kubectl get pv

```


创建pvc和pod，一般是可以写到一起的

```
cat pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: www
      mountPath: /usr/share/nginx/html
  volumes:
  - name: www
    persistentVolumeClaim:
      claimName: my-pvc

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
      
kubectl create -f pod.yaml       
kubectl get pvc 你会看到绑定的是5Gi的PV卷
验证 同nfs，进入容器
```

`kubectl delete -f pod.yaml & kubectl delete -f pv1.yaml & kubectl delete -f pv2.yaml`


Kubernetes支持持久卷的存储插件：
https://kubernetes.io/docs/concepts/storage/persistent-volumes/


### 3.2.2 动态供给

![PV动态供给](https://www.liqianlong.cn/PV%E5%8A%A8%E6%80%81%E4%BE%9B%E7%BB%99.png)



Dynamic Provisioning机制工作的核心在于StorageClass的API对象。
StorageClass声明存储插件，用于自动创建PV。

Kubernetes支持动态供给的存储插件：
https://kubernetes.io/docs/concepts/storage/storage-classes/

基于NFS存储实现数据持久化。
https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client/deploy

生成rbac访问权限

```
cat rbac.yaml 
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-client-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io

kubectl create -f rbac.yaml 
kubectl get sa
```

创建存储类支持nfs

```
cat class.yaml 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "true"

kubectl create -f class.yaml
kubectl get sc
```

部署

```
cat deployment.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: lizhenliang/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs
            - name: NFS_SERVER
              value: 192.168.31.61 
            - name: NFS_PATH
              value: /opt/k8s
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.31.61
            path: /opt/k8s
            
kubectl create -f deployment.yaml 
kubectl get pod
kubectl get deploy
```

pod

```
cat pod2.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: www
      mountPath: /usr/share/nginx/html
  volumes:
  - name: www
    persistentVolumeClaim:
      claimName: my-pvc

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  ==annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"==
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi


kubectl create -f pod2.yaml
kubectl get pvc
验证，同nfs
master看挂载点会自动生成一个目录
ls /opt/k8s/
001  002  default-my-pvc-pvc-8aefb4b9-c9fd-48f0-bb77-569e17e3fcb8 
```

`kubectl delete -f pod2.yaml/deployment.yaml/class.yaml/rbac.yaml`

pod --> pvc --> storageclass(后端存储) --> pv

https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/


# 四 再谈有状态应用部署

1. Headless Service
2. StatefulSet


有状态:db（存储，网络ID）
无状态:web，访问波动大，版本迭代快，弹性伸缩（放在K8s）


> 部署有状态应用

- 解决Pod独立生命周期，保持Pod启动顺序和唯一性
    - 稳定，唯一的网络标识符，持久存储
    - 有序，优雅的部署和扩展、删除和终止
    - 有序，滚动更新
- 应用场景：数据库


## 4.1 Headless Service 无头服务

https://kubernetes.io/zh/docs/concepts/services-networking/service/

创建普通的svc

```
kind: Service
apiVersion: v1
metadata:
  name: my-service
spec:
  selector:
    app: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
```      


有时不需要或不想要负载均衡，以及单独的 Service IP。 遇到这种情况，可以通过指定 Cluster IP（spec.clusterIP）的值为 "None" 来创建 Headless Service。


创建无头的svc

```
cat headless.yaml 
kind: Service
apiVersion: v1
metadata:
  ==name: my-service==
spec:
  selector:
    app: nginx 
  clusterIP: None
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9376
      
kubectl create -f headless.yaml
kubectl get svc
```

没有IP了，如何实现访问呢？


### 4.2 StatefulSet

创建sateful对象

```
cat satefulset.yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: nginx-statefulset
  namespace: default
spec:
  ==serviceName: my-service==
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
        image: nginx:latest
        ports:
        - containerPort: 80
        
kubectl create -f satefulset.yaml  (创建是0 1 2)      
```
通过`kubectl get ep`没有IP，通过内部DNS访问

创建了一个busybox镜像，进入然后nslookup

```
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
  
kubectl create -f busy.yaml  
```

验证
```
kubectl exec -it busybox sh

nslookup my-service
Server:    10.1.0.10
Address 1: 10.1.0.10 kube-dns.kube-system.svc.cluster.local

Name:      my-service
Address 1: 10.244.2.13 nginx-statefulset-0.my-service.default.svc.cluster.local
Address 2: 10.244.1.19 nginx-statefulset-1.my-service.default.svc.cluster.local
Address 3: 10.244.2.14 nginx-statefulset-2.my-service.default.svc.cluster.local
ping 哪个地址都能Ping通
```

`kubectl delete -f satefulset.yaml`


存储状态
专属存储(volumeClaimTemplates)，确保每一个POD用自己的

```
cat satefulset2.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 3 # by default is 1
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx 
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  ==volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "managed-nfs-storage"
      resources:
        requests:
          storage: 1Gi==
          
kubectl create -f satefulset2.yaml
kubectl get pods
kubecte get pv

验证
ls /opt/k8s
```

`kubectl delete -f satefulset2.yaml`
强制删除pod `kubectl delete pod web-0 --force --grace-period=0` <br>
删除pvc `kubectl delete pvc www-web-0` <br>
删除Pv `kubectl delete pv pvc-84b626ff-d06c-44ae-b737-4cd70c15be25`

注意 <br>
`因为用了存储状态，需要存储类class.yaml，部署deployment，权限rbac.yaml`



### 4.3 StatefulSet与Deployment区别：有身份的！
身份三要素：
- 域名
- 主机名
- 存储（PVC)

> ClusterIP A记录格式： 
<service-name>.<namespace-name>.svc.cluster.local

> ClusterIP=None A记录格式： 
<statefulsetName-index>.<service-name> .<namespace-name>.svc.cluster.local

nslookup kubernetes.default.svc.cluster.local<br>
nslookup web-0.nginx.default.svc.cluster.local


# 五 K8S 安全机制

1. Kubernetes的安全框架
2. 传输安全，认证，授权，准入控制
3. 使用RBAC授权


## 5.1 Kubernetes的安全框架

![K8S安全框架](https://www.liqianlong.cn/K8S%E5%AE%89%E5%85%A8%E6%A1%86%E6%9E%B6.png)

• 访问K8S集群的资源需要过三关：传输安全、认证、鉴权、准入控制
• 普通用户若要安全访问集群API Server，往往需要证书、Token或者用户名+密码；Pod访问，需要ServiceAccount
• K8S安全控制框架主要由下面3个阶段进行控制，每一个阶段都支持插件方式，通过API Server配置来启用插件。
1. Authentication
2. Authorization
3. Admission Control


api相关认证
`cat /etc/kubernetes/mainfests/kube-apiserver.yaml`

## 5.2 传输安全，认证，授权，准入控制

### 5.2.1 传输安全

• 告别8080，迎接6443
• 全面基于HTTPS


### 5.2.2 认证

三种客户端身份认证： 
- HTTPS 证书认证：基于CA证书签名的数字证书认证
- HTTP Token认证：通过一个Token来识别用户
- HTTP Base认证：用户名+密码的方式认证


### 5.2.3 鉴权

RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作。


### 5.2.4 准入控制（插件集合，启用插件）

Adminssion Control实际上是一个准入控制器插件列表，发送到API Server的请求都需要经过这个列表中的每个准入控制器
插件的检查，检查不通过，则拒绝请求。
1.11版本以上推荐使用的插件：
--enable-admission-plugins= \
NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,ResourceQuota


## 5.3 使用RBAC授权

RBAC（Role-Based Access Control，基于角色的访问控制），允许通过Kubernetes API动态配置策略。

![RBAC授权](https://www.liqianlong.cn/RBAC%E6%8E%88%E6%9D%83.png)

- 角色（权限的集合）
    - Role：授权特定命名空间的访问权限
    - ClusterRole：授权所有命名空间的访问权限
- 角色绑定
    - RoleBinding：将角色绑定到主体（即subject） 
    - ClusterRoleBinding：将集群角色绑定到主体
- 主体（subject） 
    - User：用户
    - Group：用户组
    - ServiceAccount：服务账号


示例：为aliang用户授权default命名空间Pod读取权限
1. 用K8S CA签发客户端证书

cfssl工具
```
cat cfssl.sh 
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64 
mv cfssl_linux-amd64 /usr/local/bin/cfssl 
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson 
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```

创建证书
```
cat cert.sh 

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

cat > aliang-csr.json <<EOF
{
  "CN": "aliang",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=kubernetes aliang-csr.json | cfssljson -bare aliang
```

2. 生成kubeconfig授权文件

```
cat config.sh 

kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=https://192.168.31.61:6443 \
  --kubeconfig=aliang.kubeconfig
 
# 设置客户端认证
kubectl config set-credentials aliang \
  --client-key=aliang-key.pem \
  --client-certificate=aliang.pem \
  --embed-certs=true \
  --kubeconfig=aliang.kubeconfig

# 设置默认上下文
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=aliang \
  --kubeconfig=aliang.kubeconfig

# 设置当前使用配置
kubectl config use-context kubernetes --kubeconfig=aliang.kubeconfig
```

3. 创建RBAC权限策略

```
cat rbac.yaml 
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods","services","configmaps"]
  verbs: ["get", "watch", "list"]

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: aliang
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

kubectl create -f rbac.yaml
kubectl get role
验证
kubectl get --kubeconfig=./aliang.kubeconfig pods
kubectl get --kubeconfig=./aliang.kubeconfig svc
kubectl get --kubeconfig=./aliang.kubeconfig cm
```


用ServiceAccount授权，对应的就是TOKEN认证

```
cat sa.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: default

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sa-read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: pod-reader
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

kubectl create -f sa.yaml
kubectl get sa
```

token在这里查看

```
kubectl get secret
pod-reader-token-ndwk8               kubernetes.io/service-account-token   3      107s
kubectl describe secret pod-reader-token-ndwk8
```
用token登录UI


https://kubernetes.io/docs/reference/access-authn-authz/rbac/