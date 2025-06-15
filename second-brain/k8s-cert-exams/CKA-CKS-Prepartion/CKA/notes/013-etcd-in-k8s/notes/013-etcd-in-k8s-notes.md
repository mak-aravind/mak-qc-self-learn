## What is etcd's Role in Kubernetes?

**etcd is the distributed key-value data store for Kubernetes clusters**

### Data Stored in etcd

- **Cluster Information**: nodes, pods, configs, secrets, accounts, roles, role bindings
- **All kubectl get command results** come from etcd server
- **Every cluster change** (adding nodes, deploying pods, replica sets) must be updated in etcd
- **Change is only complete** when updated in etcd server

## etcd Deployment Methods

### Method 1: From Scratch Setup

**Manual Installation Process:**

- Download etcd binaries manually
- Install binaries on master node
- Configure etcd as a service
- Configure multiple service options

**Key Configuration Options:**

- **Certificate-related options** (covered in TLS certificates section)
- **Cluster configuration options** (for high availability)
- **advertise-client-urls**: Critical option to remember
    - Address where etcd listens
    - Default: `https://[SERVER-IP]:2379`
    - Port 2379 is etcd's default port
    - **Must be configured on kube-apiserver** to reach etcd

### Method 2: kubeadm Setup

**Automated Deployment:**

- kubeadm deploys etcd automatically
- Runs as a **pod in kube-system namespace**
- No manual configuration required

## Working with etcd

### Exploring etcd Database

bash

```bash
# Use etcdctl utility within etcd pod
etcdctl get [options]
```

### Kubernetes Data Structure in etcd

```
/registry/                    # Root directory
├── minions/                  # Nodes
├── pods/                     # Pods
├── replicasets/             # Replica Sets  
├── deployments/             # Deployments
└── [other-k8s-constructs]/  # Other Kubernetes objects
```

**Key Command to Remember:**

bash

```bash
# List all keys stored by Kubernetes
etcdctl get / --prefix --keys-only
```

## High Availability (HA) Configuration

### Multiple etcd Instances

- **Multiple master nodes** = **Multiple etcd instances**
- etcd instances spread across master nodes
- **Critical Requirement**: All etcd instances must know about each other

### HA Configuration Parameter

bash

```bash
# In etcd service configuration
--initial-cluster=[INSTANCE1],[INSTANCE2],[INSTANCE3]
```

- **initial-cluster option**: Specifies all etcd service instances
- Essential for etcd cluster formation

## CKA Exam Key Points

### Must Remember

1. **Default etcd port**: 2379
2. **etcd listens on**: advertise-client-urls
3. **kube-apiserver must be configured** with etcd's advertise-client-urls
4. **All kubectl commands** retrieve data from etcd
5. **Changes aren't complete** until written to etcd
6. **Data structure**: /registry/ is the root directory

### Deployment Differences

|From Scratch|kubeadm|
|---|---|
|Manual binary installation|Automatic pod deployment|
|Service configuration required|Pre-configured|
|Master node service|kube-system namespace pod|
|Manual certificate setup|Automated setup|

### Commands for Troubleshooting

bash

```bash
# Check etcd pod (kubeadm setup)
kubectl get pods -n kube-system | grep etcd

# Access etcd pod
kubectl exec -it etcd-[master-node] -n kube-system -- sh

# List all Kubernetes data in etcd
etcdctl get / --prefix --keys-only
```

## Important for Exam

- **Understand both deployment methods** (from scratch vs kubeadm)
- **Know the default port and URL structure**
- **Understand etcd's critical role** in cluster state management
- **Remember HA configuration requirements**
- **Practice etcdctl commands** for data exploration