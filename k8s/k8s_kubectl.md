


[toc]

# kubectl 命令行管理工具

## kubectl 指令说明

<table border="" cellpadding="" cellspacing="">
        <tr>
            <td align="center">类型</td>
            <td align="center">指令</td>
            <td align="center">说明</td>
        </tr>
        <tr>
            <td rowspan="8">基础命令</td>
            <td>create</td>
            <td>通过文件名或标准输入创建资源</td>
        </tr>
            <td>expose</td>
            <td>将一个资源公开为一个新的Service</td>
        </tr>
        <tr>
            <td>run</td>
            <td>在集群中运行一个特定的镜像</td>
        </tr>
        <tr>
            <td>set</td>
            <td>在对象上设置特定的功能</td>
        </tr>
        <tr>
            <td>get</td>
            <td>显示一个或多个资源</td>
        </tr>
        <tr>
            <td>explain</td>
            <td>文档参考资料</td>
        </tr>
        <tr>
            <td>edit</td>
            <td>使用默认的编辑器编辑一个资源</td>
        </tr>
        <tr>
            <td>delete</td>
            <td>通过文件名、标准输入、资源名称或标签选择器来删除资源</td>
        </tr>
        <tr>
            <td rowspan="4">部署命令</td>
            <td>rollout</td>
            <td>管理资源的发布</td>
        </tr>
         <tr>
            <td>rolling-update</td>
            <td>对给定的复制控制器滚动更新</td>
        </tr>
         <tr>
            <td>scale</td>
            <td>扩容或缩容Pod数量，Deployment、ReplicaSet、RC或Job</td>
        </tr>
        <tr>
            <td>autoscale</td>
            <td>创建一个自动选择扩容或缩容并设置Pod数量</td>
        </tr>
        <tr>
            <td rowspan="7">集群管理命令</td>
            <td>certificate</td>
            <td>修改证书资源</td>
        </tr>
        <tr>
            <td>cluster-info</td>
            <td>显示集群信息</td>
        </tr>
        <tr>
            <td>top</td>
            <td>显示资源（CPU/Memory/Storage）使用。需要Heapster运行</td>
        </tr>
        <tr>
            <td>cordon</td>
            <td>标记节点不可调度</td>
        </tr>
        <tr>
            <td>uncordon</td>
            <td>标记节点可调度</td>
        </tr>
        <tr>
            <td>drain</td>
            <td>驱逐节点上的应用，准备下线维护</td>
        </tr>
        <tr>
            <td>taint</td>
            <td>修改节点taint标记</td>
        </tr>
        <tr>
            <td rowspan="8">故障诊断和调试</td>
            <td>describe</td>
            <td>显示特定资源或资源组的详细信息</td>
        </tr>
        <tr>
            <td>logs</td>
            <td>在一个Pod中打印一个容器日志。如果Pod只有一个容器，容器名称是可选的</td>
        </tr>
        <tr>
            <td>attach</td>
            <td>附加到一个运行的容器</td>
        </tr>
        <tr>
            <td>exec</td>
            <td>执行命令到容器</td>
        </tr>
        <tr>
            <td>port-forward</td>
            <td>转发一个或多个本地端口到一个pod</td>
        </tr>
        <tr>
            <td>proxy</td>
            <td>运行一个proxy到Kubernetes API server</td>
        </tr>
        <tr>
            <td>cp</td>
            <td>拷贝文件或目录到容器中</td>
        </tr>
        <tr>
            <td>auth</td>
            <td>检查授权</td>
        </tr>
        <tr>
            <td rowspan="4">高级命令</td>
            <td>apply</td>
            <td>通过文件名或标准输入对资源应用配置</td>
        </tr>
        <tr>
            <td>patch</td>
            <td>使用补丁修改、更新资源的字段</td>
        </tr>
        <tr>
            <td>replace</td>
            <td>通过文件名或标准输入替换一个资源</td>
        </tr>
        <tr>
            <td>convert</td>
            <td>不同的API版本之间转换配置文件</td>
        </tr>
        <tr>
            <td rowspan="3">设置命令</td>
            <td>label</td>
            <td>更新资源上的标签</td>
        </tr>
        <tr>
            <td>annotate</td>
            <td>更新资源上的注释</td>
        </tr>
        <tr>
            <td>completion</td>
            <td>用于实现kubectl工具自动补全</td>
        </tr>
         <tr>
            <td rowspan="5">设置命令</td>
            <td>api-versions</td>
            <td>打印受支持的API版本</td>
        </tr>
        <tr>
            <td>config</td>
            <td>修改kubeconfig文件（用于访问API，比如配置认证信息）</td>
        </tr>
        <tr>
        <td>help</td>
            <td>所有命令帮助</td>
        </tr>
          <tr>
            <td>plugin</td>
            <td>运行一个命令行插件</td>
        </tr>
        <tr>
            <td>version</td>
            <td>打印客户端和服务版本信息</td>
        </tr>
</table>


## 简单参考
```bash
帮助
kubectl create --help
kubectl get all  当前命名空间
kubectl get all -A
kubectl api-resources 缩写
kubectl get cs/no/cm/ep/ns/pvc/po/sa/svc/

基础命令
1. 查看
kubectl get ns
kubectl get pods -n kube-system
2. 编辑
kubectl edit deploy nginx
3. 删除
kubectl delete deploy nginx

命令补全，可以跟kubectl completion官方说明对照下
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)

配置文件
kubectl config view
ls .kube/config
```

## k8s应用生命周期（针对Pod）

> 创建

```bash
kubectl create deployment nginx --image=nginx:1.14
kubectl get deploy,pods
```

> 发布

```bash
kubectl expose deployment nginx --port=80 --type=NodePort --target-port=80 --name=nginx-service
kubectl get service,svc
```

> 更新

```bash
kubectl set image deployment nginx nginx=nginx:1.15
```

> 回滚

```bash
kubectl rollout history deployment nginx
kubectl rollout undo deployment nginx
```

> 删除

```bash
kubectl delete deploy/nginx
kubectl delete svc nginx-service
```