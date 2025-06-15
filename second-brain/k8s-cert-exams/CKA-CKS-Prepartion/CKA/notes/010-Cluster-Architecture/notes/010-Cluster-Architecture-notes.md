# CKA Exam Notes: Kubernetes Cluster Architecture

## 🎯 **Core Concept**

Kubernetes hosts applications in containers with automated deployment, scaling, and inter-service communication capabilities.

---

## 🏗️ **High-Level Architecture**

### **Two Node Types:**

1. **Master Nodes (Control Plane)** - Management and orchestration
2. **Worker Nodes** - Host application containers

### **Ship Analogy:**

- **Cargo Ships** = Worker Nodes (carry containers)
- **Control Ships** = Master Nodes (manage cargo ships)

---

## 🎛️ **Master Node Components (Control Plane)**

### **1. etcd Cluster**

- **Purpose:** Highly available key-value store
- **Function:** Stores all cluster information
- **Data Stored:**
    - Node information
    - Container placement details
    - Load timestamps
    - Cluster state data
- **Key Characteristics:** Distributed, consistent, fault-tolerant

### **2. Kube-Scheduler**

- **Purpose:** Places containers on appropriate nodes
- **Decision Factors:**
    - Container resource requirements
    - Node capacity and availability
    - Number of existing containers on nodes
    - Scheduling constraints:
        - Taints and tolerations
        - Node affinity rules
        - Pod affinity/anti-affinity
- **Process:** Identifies → Evaluates → Assigns

### **3. Controllers**

Multiple specialized controllers handle different cluster aspects:

#### **Node Controller:**

- Onboards new nodes
- Handles node failures/unavailability
- Manages node lifecycle

#### **Replication Controller:**

- Ensures desired number of pod replicas
- Maintains application availability
- Handles pod failures and replacements

#### **Other Controllers:**

- Deployment Controller
- Service Controller
- Endpoint Controller
- etc.

### **4. Kube API Server**

- **Role:** Primary management component
- **Functions:**
    - Exposes Kubernetes REST API
    - Orchestrates all cluster operations
    - Authentication and authorization
    - Admission control
- **Communication Hub for:**
    - External users (kubectl, UI)
    - Controllers monitoring cluster state
    - Worker nodes reporting status
    - All internal components

### **5. Container Runtime**

- **Purpose:** Runs containers on master (if control plane is containerized)
- **Supported Runtimes:**
    - Docker
    - containerd
    - CRI-O
    - rkt (Rocket)

---

## 🚢 **Worker Node Components**

### **1. Kubelet**

- **Role:** Node agent ("Captain of the ship")
- **Responsibilities:**
    - Registers node with cluster
    - Receives pod specifications from API server
    - Manages pod lifecycle (create, start, stop, delete)
    - Reports node and pod status back to API server
    - Performs health checks
    - Manages container volumes and networking

### **2. Kube-proxy**

- **Purpose:** Network proxy service
- **Functions:**
    - Enables pod-to-pod communication
    - Implements service networking
    - Maintains network rules (iptables/IPVS)
    - Load balances traffic to service endpoints
    - Handles service discovery

### **3. Container Runtime**

- **Required on all worker nodes**
- **Runs the actual application containers**
- **Same options as master nodes**

---

## 🔄 **Communication Flow**

1. **API Server** ← External users, kubectl commands
2. **API Server** ↔ **etcd** (read/write cluster state)
3. **API Server** ↔ **Scheduler** (pod placement decisions)
4. **API Server** ↔ **Controllers** (monitoring and management)
5. **API Server** ↔ **Kubelet** (pod specifications and status)
6. **Kube-proxy** enables inter-pod communication

---

## 📝 **CKA Exam Key Points**

### **Architecture Questions:**

- Identify master vs worker node components
- Understand component responsibilities
- Know communication patterns
- Troubleshoot component failures

### **Component Locations:**

- **Master:** etcd, API server, scheduler, controllers
- **Worker:** kubelet, kube-proxy, container runtime
- **Both:** Container runtime (if needed)

### **Critical for Troubleshooting:**

- API server is central to all operations
- etcd stores all cluster state
- Kubelet manages pod lifecycle
- Kube-proxy handles networking

### **Common Exam Scenarios:**

- Component failure analysis
- Cluster setup and configuration
- Node management and troubleshooting
- Understanding pod scheduling process

---

## 🎯 **Quick Reference Commands**

```bash
# Check cluster components
kubectl get nodes
kubectl get pods -n kube-system

# Component status
kubectl get componentstatuses

# Node details
kubectl describe node <node-name>

# API server
kubectl cluster-info

# etcd information (if accessible)
kubectl get pods -n kube-system | grep etcd
```

---

## ⚡ **Exam Tips**

1. **Understand the flow:** User → API Server → etcd/Scheduler/Controllers → Kubelet → Container Runtime
2. **Component failures:** Know which component failure causes what symptoms
3. **Master vs Worker:** Be clear on what runs where
4. **Communication:** All components communicate through API server
5. **Container Runtime:** Required on all nodes that run containers

---

_This architecture understanding is fundamental for all other Kubernetes concepts in the CKA exam._