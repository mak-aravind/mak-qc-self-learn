# CKA Exam Notes: Container Runtimes (Docker vs Containerd)

## Historical Context & Evolution

### Early Container Era

- **Docker dominated**: Simple user experience made it the primary container tool
- **Kubernetes + Docker**: Initially tightly coupled, Kubernetes only worked with Docker
- **Other runtimes existed**: rkt and others, but Docker was dominant

### The CRI Introduction

- **Problem**: Other container runtimes (like rkt) wanted Kubernetes support
- **Solution**: Container Runtime Interface (CRI) introduced
- **Purpose**: Allow any vendor to work as container runtime for Kubernetes
- **Requirement**: Must adhere to OCI (Open Container Initiative) standards

### OCI Standards

- **imagespec**: Specifications on how container images should be built
- **runtimespec**: Standards on how container runtimes should be developed
- **Benefit**: Anyone can build CRI-compatible container runtime

### Docker's Challenge

- **Problem**: Docker was built before CRI existed
- **Solution**: Kubernetes introduced **dockershim**
- **dockershim**: Hacky but temporary way to support Docker outside CRI
- **Result**: Docker worked without CRI while other runtimes used CRI

## Docker Architecture Components

Docker is not just a runtime - it consists of multiple tools:

- Docker CLI
- Docker API
- Build tools for image creation
- Volume support
- Auth and security features
- **runC**: The actual container runtime
- **Containerd**: Daemon that managed runC

## Containerd Details

### Key Facts

- **Origin**: Part of Docker but now separate project
- **Status**: CNCF graduated project
- **Compatibility**: CRI compatible, works directly with Kubernetes
- **Independence**: Can be installed without Docker

### Containerd Removal of Docker Support

- **Kubernetes 1.24**: Removed dockershim completely
- **Impact**: Docker no longer supported as runtime in Kubernetes
- **Images compatibility**: Docker images still work (follow OCI imagespec standards)
- **Migration**: Use Containerd directly instead of Docker

## CLI Tools Comparison

### 1. ctr (Containerd CLI)

**Purpose**: Debugging Containerd only **Limitations**:

- Very limited features
- Not user-friendly
- Not for production use
- Requires API calls for advanced operations

**Basic Commands**:

```bash
# Pull image
ctr images pull redis

# Run container  
ctr run <image-address>
```

### 2. nerdctl (Docker-like CLI for Containerd)

**Purpose**: General purpose container management **Advantages**:

- Docker-like CLI for Containerd
- Supports most Docker options
- Access to newest Containerd features
- Better than ctr for production

**Additional Features**:

- Encrypted container images
- Lazy pulling of images
- P2P image distribution
- Image signing and verifying
- Kubernetes namespaces support

**Usage Examples**:

```bash
# Instead of: docker run
nerdctl run <image>

# Port mapping works same as Docker
nerdctl run -p 8080:80 <image>
```

### 3. crictl (CRI Control)

**Purpose**: Debugging CRI-compatible runtimes **Developed by**: Kubernetes community **Scope**: Works across ALL CRI-compatible runtimes (not just Containerd)

**Important Notes**:

- Must be installed separately
- **Debugging tool only** - not for creating containers in production
- Works with kubelet
- **Warning**: Containers created with crictl will be deleted by kubelet (kubelet is unaware of them)

**Common Commands**:

```bash
# List images
crictl images

# List containers (like docker ps)
crictl ps

# Execute command in container
crictl exec -it <container-id> <command>

# View logs
crictl logs <container-id>

# List pods (unique to crictl)
crictl pods
```

## Command Comparison: Docker vs crictl

|Function|Docker Command|crictl Command|
|---|---|---|
|List containers|`docker ps`|`crictl ps`|
|Execute command|`docker exec -it`|`crictl exec -it`|
|View logs|`docker logs`|`crictl logs`|
|List images|`docker images`|`crictl images`|
|Container stats|`docker stats`|`crictl stats`|
|Inspect|`docker inspect`|`crictl inspect`|

**Unique to crictl**: `crictl pods` (Docker wasn't pod-aware)

## CKA Exam Critical Points

### Kubernetes 1.24+ Changes

- **dockershim removed**: No more Docker support
- **crictl endpoint changes**:
    - Old: dockershim.socket
    - New: cri-dockerd.sock
- **Recommendation**: Manually set endpoints
- **References**: Check Kubernetes cri-tools GitHub (PR #869, Issue #868)

### Tool Selection Guidelines

|Tool|Use Case|Community|Runtime Support|
|---|---|---|---|
|**ctr**|Debugging only|Containerd|Containerd only|
|**nerdctl**|General purpose|Containerd|Containerd only|
|**crictl**|Debugging only|Kubernetes|All CRI-compatible|

### Exam Scenarios

1. **Troubleshooting containers**: Use `crictl` commands
2. **Working with Containerd**: Use `nerdctl` for general tasks
3. **Debugging runtime issues**: Use `crictl` for CRI-compatible runtimes
4. **Legacy Docker commands**: Replace with `crictl` equivalents

## Migration Summary

- **From**: Docker as container runtime
- **To**: Containerd as container runtime
- **CLI Change**: Replace `docker` commands with `crictl` for troubleshooting
- **Images**: All existing Docker images continue to work
- **New installations**: Install Containerd instead of Docker

## Key Takeaways for CKA

1. **Understand the evolution**: Docker → dockershim → Containerd
2. **Know the tools**: ctr (debug), nerdctl (general), crictl (debug/k8s)
3. **Command equivalents**: Docker commands have crictl equivalents
4. **Pod awareness**: Only crictl understands pods
5. **Kubernetes 1.24+**: Docker support completely removed
6. **Production usage**: Use nerdctl for general container operations, crictl for debugging only