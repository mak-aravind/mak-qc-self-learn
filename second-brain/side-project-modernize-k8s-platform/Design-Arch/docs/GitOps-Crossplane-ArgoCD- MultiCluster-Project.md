# GitOps with Crossplane and ArgoCD - Multi-Cluster Project - Version 22

## Project Overview

This project demonstrates modern GitOps practices using Crossplane for Infrastructure as Code (IaC) and ArgoCD for continuous deployment. We'll build a management control plane that can provision and manage multiple Kubernetes clusters declaratively using a sophisticated three-tier isolation model.

### Architecture Components - Multi-Tier Isolation Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Control Plane (Kind)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐                 │
│  │   ArgoCD    │  │ Crossplane  │  │    GitOps Repo      │                 │
│  │             │  │             │  │   (GitHub)          │                 │
│  └─────────────┘  └─────────────┘  └─────────────────────┘                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Provisions & Manages
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Physical Host Cluster (MicroK8s/AKS)                  │
│                                                                             │
│  ┌───────────────────────────────┐  ┌─────────────────────────────────────┐ │
│  │        vCluster (Prod)        │  │       vCluster (Non-Prod)          │ │
│  │  ┌─────────────────────────┐  │  │  ┌───────────────────────────────┐  │ │
│  │  │  Capsule Tenant         │  │  │  │  Capsule Tenant               │  │ │
│  │  │    (Staging)            │  │  │  │    (Development)              │  │ │
│  │  └─────────────────────────┘  │  │  └───────────────────────────────┘  │ │
│  │  ┌─────────────────────────┐  │  │  ┌───────────────────────────────┐  │ │
│  │  │  Capsule Tenant         │  │  │  │  Capsule Tenant               │  │ │
│  │  │   (Production)          │  │  │  │    (Testing)                  │  │ │
│  │  └─────────────────────────┘  │  │  └───────────────────────────────┘  │ │
│  └───────────────────────────────┘  └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

Three-Tier Isolation Model:
Layer 1: Physical Host Cluster (Infrastructure Isolation)
Layer 2: vCluster (Environment Isolation - Prod vs Non-Prod)  
Layer 3: Capsule Tenants (Team/Function Isolation)
```

## Phase 1: Foundation Setup

### Step 1: Prepare Local Environment

```bash
# Install required tools
# Docker Desktop or Docker Engine
# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# Install vCluster CLI
curl -L -o vcluster "https://github.com/loft-sh/vcluster/releases/latest/download/vcluster-linux-amd64"
chmod +x vcluster
sudo mv vcluster /usr/local/bin

# Verify installation
vcluster --version
```

### Step 2: Create Control Plane (Kind Cluster)

```bash
# Create kind-config.yaml
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: control-plane
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EOF

# Create the control plane cluster
kind create cluster --config kind-config.yaml
```

### Step 3: Install Crossplane on Control Plane

```bash
# Add Crossplane Helm repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
kubectl create namespace crossplane-system
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --wait

# Verify installation
kubectl get pods -n crossplane-system
kubectl get crd | grep crossplane
```

### Step 4: Install ArgoCD on Control Plane

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Phase 2: GitOps Repository Structure

### Step 5: Create Multi-Tier GitOps Repository Structure

Create the following repository structure on GitHub:

```
gitops-infrastructure/
├── README.md
├── control-plane/
│   ├── argocd/
│   │   ├── applications/
│   │   │   ├── crossplane-providers.yaml
│   │   │   ├── infrastructure-compositions.yaml
│   │   │   ├── vcluster-applications.yaml
│   │   │   └── cluster-applications.yaml
│   │   └── projects/
│   │       └── infrastructure-project.yaml
│   └── crossplane/
│       ├── providers/
│       │   ├── provider-kubernetes.yaml
│       │   ├── provider-helm.yaml
│       │   └── provider-vcluster.yaml
│       ├── compositions/
│       │   ├── microk8s-cluster-composition.yaml
│       │   ├── vcluster-composition.yaml
│       │   ├── capsule-tenant-composition.yaml
│       │   └── azure-aks-composition.yaml (future)
│       └── claims/
│           ├── dev-microk8s-cluster.yaml
│           ├── prod-vcluster.yaml
│           ├── nonprod-vcluster.yaml
│           └── capsule-tenants.yaml
├── clusters/
│   ├── host-cluster/
│   │   ├── microk8s/
│   │   │   ├── infrastructure/
│   │   │   └── base-config/
│   │   └── azure-aks/
│   │       └── infrastructure/
│   ├── vclusters/
│   │   ├── prod/
│   │   │   ├── vcluster-config.yaml
│   │   │   ├── capsule/
│   │   │   │   ├── staging-tenant.yaml
│   │   │   │   └── production-tenant.yaml
│   │   │   └── applications/
│   │   │       ├── monitoring/
│   │   │       └── ingress/
│   │   └── nonprod/
│   │       ├── vcluster-config.yaml
│   │       ├── capsule/
│   │       │   ├── development-tenant.yaml
│   │       │   └── testing-tenant.yaml
│   │       └── applications/
│   │           ├── monitoring/
│   │           └── development-tools/
│   └── tenants/
│       ├── development/
│       │   ├── namespaces/
│       │   ├── applications/
│       │   └── policies/
│       ├── testing/
│       ├── staging/
│       └── production/
└── environments/
    ├── dev/
    ├── test/
    ├── staging/
    └── production/
```

### Step 6: Create Crossplane Provider Configurations

**File: `control-plane/crossplane/providers/provider-kubernetes.yaml`**

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.11.0
---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider-config
spec:
  credentials:
    source: InjectedIdentity
```

**File: `control-plane/crossplane/providers/provider-helm.yaml`**

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-helm
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-helm:v0.15.0
---
apiVersion: helm.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: helm-provider-config
spec:
  credentials:
    source: InjectedIdentity
```

**File: `control-plane/crossplane/providers/provider-vcluster.yaml`**

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-vcluster
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-helm:v0.15.0
---
apiVersion: helm.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: vcluster-provider-config
spec:
  credentials:
    source: InjectedIdentity
```

### Step 7: Create Multi-Tier Compositions

**File: `control-plane/crossplane/compositions/vcluster-composition.yaml`**

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: vcluster-environment
  labels:
    cluster-type: vcluster
    provider: helm
spec:
  compositeTypeRef:
    apiVersion: infrastructure.example.com/v1alpha1
    kind: XVCluster
  resources:
  - name: vcluster-namespace
    base:
      apiVersion: v1
      kind: Namespace
      metadata:
        name: # Will be patched
        labels:
          environment: # Will be patched
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
      transforms:
      - type: string
        string:
          fmt: "vcluster-%s"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.environment
      toFieldPath: metadata.labels['environment']
  
  - name: vcluster-helm-release
    base:
      apiVersion: helm.crossplane.io/v1beta1
      kind: Release
      metadata:
        name: # Will be patched
      spec:
        providerConfigRef:
          name: helm-provider-config
        forProvider:
          chart:
            name: vcluster
            repository: https://charts.loft.sh
            version: "0.16.4"
          namespace: # Will be patched
          values:
            isolation:
              enabled: true
            sync:
              nodes:
                enabled: true
              persistentvolumes:
                enabled: true
            resources:
              limits:
                cpu: "2"
                memory: "4Gi"
              requests:
                cpu: "1"
                memory: "2Gi"
            rbac:
              clusterRole:
                create: true
            multiNamespaceMode:
              enabled: false
            pro: false
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
      transforms:
      - type: string
        string:
          fmt: "vcluster-%s"
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.forProvider.namespace
      transforms:
      - type: string
        string:
          fmt: "vcluster-%s"
    - type: FromCompositeFieldPath
      fromFieldPath: spec.resources.cpu
      toFieldPath: spec.forProvider.values.resources.limits.cpu
    - type: FromCompositeFieldPath
      fromFieldPath: spec.resources.memory
      toFieldPath: spec.forProvider.values.resources.limits.memory

  - name: capsule-helm-release
    base:
      apiVersion: helm.crossplane.io/v1beta1
      kind: Release
      metadata:
        name: # Will be patched
      spec:
        providerConfigRef:
          name: helm-provider-config
        forProvider:
          chart:
            name: capsule
            repository: https://projectcapsule.github.io/charts
            version: "0.4.6"
          namespace: capsule-system
          values:
            manager:
              resources:
                limits:
                  cpu: "1"
                  memory: "1Gi"
                requests:
                  cpu: "100m"
                  memory: "128Mi"
            webhook:
              enabled: true
        dependsOn:
        - name: vcluster-helm-release
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
      transforms:
      - type: string
        string:
          fmt: "capsule-%s"

---
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xvclusters.infrastructure.example.com
spec:
  group: infrastructure.example.com
  names:
    kind: XVCluster
    plural: xvclusters
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              environment:
                type: string
                enum: ["prod", "nonprod"]
              resources:
                type: object
                properties:
                  cpu:
                    type: string
                  memory:
                    type: string
              tenants:
                type: array
                items:
                  type: string
          status:
            type: object
            properties:
              vclusterStatus:
                type: string
              kubeconfig:
                type: string
  claimNames:
    kind: VCluster
    plural: vclusters
```

**File: `control-plane/crossplane/compositions/capsule-tenant-composition.yaml`**

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: capsule-tenant
  labels:
    tenant-type: capsule
    provider: kubernetes
spec:
  compositeTypeRef:
    apiVersion: infrastructure.example.com/v1alpha1
    kind: XTenant
  resources:
  - name: tenant-definition
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha1
      kind: Object
      metadata:
        name: # Will be patched
      spec:
        providerConfigRef:
          name: kubernetes-provider-config
        forProvider:
          manifest:
            apiVersion: capsule.clastix.io/v1beta2
            kind: Tenant
            metadata:
              name: # Will be patched
            spec:
              owners:
              - name: # Will be patched
                kind: User
              namespaceOptions:
                quota: # Will be configured
              limitRanges:
                items:
                - limits:
                  - default:
                      cpu: "1"
                      memory: "1Gi"
                    defaultRequest:
                      cpu: "100m"
                      memory: "128Mi"
                    type: Container
              resourceQuotas:
                scope: Tenant
                items:
                - hard:
                    limits.cpu: # Will be patched
                    limits.memory: # Will be patched
                    requests.cpu: # Will be patched
                    requests.memory: # Will be patched
                    count/pods: "10"
              networkPolicies:
                items:
                - policyTypes:
                  - Ingress
                  - Egress
                  egress:
                  - {}
                  ingress:
                  - from:
                    - namespaceSelector:
                        matchLabels:
                          capsule.clastix.io/tenant: # Will be patched
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.forProvider.manifest.metadata.name
    - type: FromCompositeFieldPath
      fromFieldPath: spec.owner
      toFieldPath: spec.forProvider.manifest.spec.owners[0].name
    - type: FromCompositeFieldPath
      fromFieldPath: spec.resources.cpu
      toFieldPath: spec.forProvider.manifest.spec.resourceQuotas.items[0].hard['limits.cpu']
    - type: FromCompositeFieldPath
      fromFieldPath: spec.resources.memory
      toFieldPath: spec.forProvider.manifest.spec.resourceQuotas.items[0].hard['limits.memory']
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: spec.forProvider.manifest.spec.networkPolicies.items[0].ingress[0].from[0].namespaceSelector.matchLabels['capsule.clastix.io/tenant']

---
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xtenants.infrastructure.example.com
spec:
  group: infrastructure.example.com
  names:
    kind: XTenant
    plural: xtenants
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              environment:
                type: string
                enum: ["development", "testing", "staging", "production"]
              owner:
                type: string
              resources:
                type: object
                properties:
                  cpu:
                    type: string
                  memory:
                    type: string
              namespaceQuota:
                type: integer
                minimum: 1
                maximum: 20
          status:
            type: object
            properties:
              tenantStatus:
                type: string
              namespaces:
                type: array
                items:
                  type: string
  claimNames:
    kind: Tenant
    plural: tenants
```

### Step 8: Create Multi-Tier Cluster Claims

**File: `control-plane/crossplane/claims/prod-vcluster.yaml`**

```yaml
apiVersion: infrastructure.example.com/v1alpha1
kind: VCluster
metadata:
  name: prod
  namespace: default
spec:
  environment: prod
  resources:
    cpu: "4"
    memory: "8Gi"
  tenants:
  - staging
  - production
  compositionRef:
    name: vcluster-environment
```

**File: `control-plane/crossplane/claims/nonprod-vcluster.yaml`**

```yaml
apiVersion: infrastructure.example.com/v1alpha1
kind: VCluster
metadata:
  name: nonprod
  namespace: default
spec:
  environment: nonprod
  resources:
    cpu: "2"
    memory: "4Gi"
  tenants:
  - development
  - testing
  compositionRef:
    name: vcluster-environment
```

**File: `control-plane/crossplane/claims/capsule-tenants.yaml`**

```yaml
# Development Tenant
apiVersion: infrastructure.example.com/v1alpha1
kind: Tenant
metadata:
  name: development
  namespace: default
spec:
  environment: development
  owner: dev-team@company.com
  resources:
    cpu: "2"
    memory: "4Gi"
  namespaceQuota: 5
  compositionRef:
    name: capsule-tenant
---
# Testing Tenant
apiVersion: infrastructure.example.com/v1alpha1
kind: Tenant
metadata:
  name: testing
  namespace: default
spec:
  environment: testing
  owner: qa-team@company.com
  resources:
    cpu: "1"
    memory: "2Gi"
  namespaceQuota: 3
  compositionRef:
    name: capsule-tenant
---
# Staging Tenant
apiVersion: infrastructure.example.com/v1alpha1
kind: Tenant
metadata:
  name: staging
  namespace: default
spec:
  environment: staging
  owner: staging-team@company.com
  resources:
    cpu: "2"
    memory: "4Gi"
  namespaceQuota: 3
  compositionRef:
    name: capsule-tenant
---
# Production Tenant
apiVersion: infrastructure.example.com/v1alpha1
kind: Tenant
metadata:
  name: production
  namespace: default
spec:
  environment: production
  owner: ops-team@company.com
  resources:
    cpu: "4"
    memory: "8Gi"
  namespaceQuota: 5
  compositionRef:
    name: capsule-tenant
```

## Phase 3: ArgoCD Configuration

### Step 9: Create ArgoCD Project

**File: `control-plane/argocd/projects/infrastructure-project.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: infrastructure
  namespace: argocd
spec:
  description: Infrastructure management project
  sourceRepos:
  - 'https://github.com/YOUR_USERNAME/gitops-infrastructure'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  - namespace: '*'
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  roles:
  - name: admin
    policies:
    - p, proj:infrastructure:admin, applications, *, infrastructure/*, allow
    - p, proj:infrastructure:admin, repositories, *, *, allow
    groups:
    - infrastructure-admins
```

### Step 10: Create ArgoCD Applications

**File: `control-plane/argocd/applications/crossplane-providers.yaml`**

```yaml
  name: sample-app-production
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app-manifests
    targetRevision: release
    path: environments/production
  destination:
    server: https://vcluster-prod-api-server
    namespace: production-app
  syncPolicy:
    manual: {}
    syncOptions:
    - CreateNamespace=true
```

**File: `clusters/vclusters/nonprod/applications/sample-app.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-development
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app-manifests
    targetRevision: develop
    path: environments/development
  destination:
    server: https://vcluster-nonprod-api-server
    namespace: dev-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-testing
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app-manifests
    targetRevision: develop
    path: environments/testing
  destination:
    server: https://vcluster-nonprod-api-server
    namespace: test-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Step 19: Tenant-Specific Resource Policies

**File: `clusters/tenants/development/policies/resource-quotas.yaml`**

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: development-compute-quota
  namespace: development-default
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
    count/pods: "20"
    count/services: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: development-limits
  namespace: development-default
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "1Gi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "1"
      memory: "2Gi"
    type: Container
```

**File: `clusters/tenants/production/policies/network-policies.yaml`**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-isolation
  namespace: production-default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          capsule.clastix.io/tenant: production
  - from:
    - namespaceSelector:
        matchLabels:
          name: istio-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          capsule.clastix.io/tenant: production
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

## Phase 7: Advanced Multi-Tier Operations

### Step 20: Cross-Environment Service Mesh Integration

**File: `clusters/vclusters/prod/infrastructure/istio-setup.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: istio-base-prod
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://istio-release.storage.googleapis.com/charts
    chart: base
    targetRevision: 1.19.0
  destination:
    server: https://vcluster-prod-api-server
    namespace: istio-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: istio-control-plane-prod
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://istio-release.storage.googleapis.com/charts
    chart: istiod
    targetRevision: 1.19.0
    helm:
      values: |
        pilot:
          env:
            EXTERNAL_ISTIOD: true
        global:
          meshID: prod-mesh
          multiCluster:
            clusterName: prod-vcluster
          network: prod-network
  destination:
    server: https://vcluster-prod-api-server
    namespace: istio-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step 21: Monitoring and Observability Stack

**File: `clusters/vclusters/prod/monitoring/prometheus-stack.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus-stack-prod
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 51.9.4
    helm:
      values: |
        prometheus:
          prometheusSpec:
            retention: 15d
            storageSpec:
              volumeClaimTemplate:
                spec:
                  storageClassName: fast-ssd
                  accessModes: ["ReadWriteOnce"]
                  resources:
                    requests:
                      storage: 100Gi
            additionalScrapeConfigs:
            - job_name: 'vcluster-metrics'
              kubernetes_sd_configs:
              - role: pod
                namespaces:
                  names:
                  - vcluster-prod
        grafana:
          adminPassword: admin123
          dashboardProviders:
            dashboardproviders.yaml:
              apiVersion: 1
              providers:
              - name: 'default'
                orgId: 1
                folder: ''
                type: file
                disableDeletion: false
                editable: true
                options:
                  path: /var/lib/grafana/dashboards/default
  destination:
    server: https://vcluster-prod-api-server
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Step 22: Security and Compliance Enforcement

**File: `clusters/vclusters/prod/security/opa-gatekeeper.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opa-gatekeeper-prod
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://open-policy-agent.github.io/gatekeeper/charts
    chart: gatekeeper
    targetRevision: 3.14.0
    helm:
      values: |
        replicas: 3
        auditInterval: 60
        constraintViolationsLimit: 20
        auditFromCache: false
        disableValidatingAdmissionWebhook: false
        validatingWebhookConfiguration:
          failurePolicy: Fail
        mutatingWebhookConfiguration:
          failurePolicy: Fail
  destination:
    server: https://vcluster-prod-api-server
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required label: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-environment-label
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    excludedNamespaces: ["kube-system", "gatekeeper-system"]
  parameters:
    labels: ["environment", "team", "app"]
```

## Phase 8: Disaster Recovery and Backup Strategy

### Step 23: Multi-Tier Backup Configuration

**File: `clusters/vclusters/backup/velero-setup.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: velero-backup-prod
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://vmware-tanzu.github.io/helm-charts
    chart: velero
    targetRevision: 5.1.4
    helm:
      values: |
        initContainers:
        - name: velero-plugin-for-aws
          image: velero/velero-plugin-for-aws:v1.8.0
          volumeMounts:
          - mountPath: /target
            name: plugins
        configuration:
          provider: aws
          backupStorageLocation:
            bucket: my-backup-bucket
            config:
              region: us-west-2
          volumeSnapshotLocation:
            config:
              region: us-west-2
        credentials:
          useSecret: true
          secretContents:
            cloud: |
              [default]
              aws_access_key_id=YOUR_ACCESS_KEY
              aws_secret_access_key=YOUR_SECRET_KEY
        schedules:
          daily-backup:
            disabled: false
            schedule: "0 2 * * *"
            template:
              storageLocation: default
              includedNamespaces:
              - "*"
              excludedNamespaces:
              - velero
              includeClusterResources: true
              snapshotVolumes: true
  destination:
    server: https://vcluster-prod-api-server
    namespace: velero
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Step 24: Cross-vCluster Communication Setup

**File: `clusters/vclusters/networking/cluster-mesh.yaml`**

```yaml
# Service to expose prod vCluster API to nonprod
apiVersion: v1
kind: Service
metadata:
  name: prod-vcluster-api
  namespace: vcluster-prod
spec:
  type: ClusterIP
  ports:
  - port: 443
    targetPort: 8443
    protocol: TCP
  selector:
    app: vcluster
    release: prod
---
# EndpointSlice for cross-cluster service discovery
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: prod-vcluster-endpoints
  namespace: vcluster-nonprod
  labels:
    kubernetes.io/service-name: prod-vcluster-api
addressType: IPv4
ports:
- name: https
  port: 443
  protocol: TCP
endpoints:
- addresses:
  - "prod-vcluster-api.vcluster-prod.svc.cluster.local"
```

## Operational Best Practices

### Multi-Tier GitOps Workflow

1. **Development Flow:**
   ```bash
   # Developer commits to feature branch
   git checkout -b feature/new-app
   git add .
   git commit -m "Add new application manifests"
   git push origin feature/new-app
   
   # ArgoCD automatically deploys to development tenant
   # Testing occurs in development vCluster
   ```

2. **Promotion Pipeline:**
   ```bash
   # Promote to testing
   git checkout develop
   git merge feature/new-app
   git push origin develop
   
   # Promote to staging (manual approval)
   git checkout main
   git merge develop
   git tag v1.2.3
   git push origin main --tags
   
   # Production deployment (manual trigger)
   argocd app sync sample-app-production
   ```

### Monitoring Multi-Tier Architecture

```bash
# Monitor vCluster health
kubectl get pods -n vcluster-prod -l app=vcluster
kubectl get pods -n vcluster-nonprod -l app=vcluster

# Check Capsule tenant status
kubectl get tenants -o wide

# Monitor resource usage across tenants
kubectl top nodes
kubectl top pods --all-namespaces --containers

# Check ArgoCD application health
argocd app list --output wide
```

### Troubleshooting Guide

#### vCluster Issues
```bash
# Debug vCluster connectivity
vcluster connect prod --namespace vcluster-prod --debug

# Check vCluster logs
kubectl logs -n vcluster-prod deployment/prod-vcluster

# Verify vCluster resources
kubectl describe vcluster prod
```

#### Capsule Tenant Issues
```bash
# Check tenant configuration
kubectl describe tenant development

# Verify tenant webhook
kubectl get validatingwebhookconfigurations capsule-validating-webhook-configuration

# Debug tenant resource quotas
kubectl describe resourcequota -n development-default
```

#### Network Isolation Testing
```bash
# Test cross-tenant communication (should fail)
kubectl run test-pod --image=busybox -n development-app --rm -it -- /bin/sh
# Inside pod: wget production-service.production-app.svc.cluster.local

# Test tenant-internal communication (should succeed)
kubectl run test-pod --image=busybox -n development-app --rm -it -- /bin/sh
# Inside pod: wget dev-service.development-app.svc.cluster.local
```

## Key Benefits Achieved

### 1. **Perfect Isolation Hierarchy**
- **Physical Level**: Host cluster provides infrastructure isolation
- **Environment Level**: vClusters provide API server and control plane isolation
- **Team Level**: Capsule tenants provide namespace and resource isolation

### 2. **Cost Optimization**
- Single host cluster reduces infrastructure costs
- vClusters are lightweight compared to separate clusters
- Capsule eliminates need for multiple vClusters per team

### 3. **Operational Efficiency**
- Centralized management through single control plane
- GitOps-driven deployment across all tiers
- Consistent policies and configurations

### 4. **Security and Compliance**
- Defense in depth with multiple isolation layers
- Network policies at each tier
- Policy enforcement through OPA Gatekeeper

### 5. **Scalability and Flexibility**
- Easy addition of new environments via vCluster claims
- Simple tenant onboarding through Capsule
- Seamless promotion workflows between environments

This architecture provides enterprise-grade multi-tenancy with the flexibility to scale from local development to cloud production environments while maintaining consistent GitOps practices throughout.

## Next Steps for Azure AKS Integration

### Step 25: Prepare for Cloud Migration

**File: `control-plane/crossplane/providers/provider-azure.yaml`**

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure:v0.36.0
---
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: azure-provider-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
```

**File: `control-plane/crossplane/compositions/azure-aks-composition.yaml`**

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: azure-aks-cluster
  labels:
    cluster-type: aks
    provider: azure
spec:
  compositeTypeRef:
    apiVersion: infrastructure.example.com/v1alpha1
    kind: XCluster
  resources:
  - name: resource-group
    base:
      apiVersion: azure.upbound.io/v1beta1
      kind: ResourceGroup
      spec:
        forProvider:
          location: "East US"
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
      transforms:
      - type: string
        string:
          fmt: "rg-%s"
  
  - name: aks-cluster
    base:
      apiVersion: containerservice.azure.upbound.io/v1beta1
      kind: KubernetesCluster
      spec:
        forProvider:
          location: "East US"
          resourceGroupNameSelector:
            matchControllerRef: true
          defaultNodePool:
          - name: default
            nodeCount: 3
            vmSize: Standard_D2s_v3
          identity:
          - type: SystemAssigned
    patches:
    - type: FromCompositeFieldPath
      fromFieldPath: metadata.name
      toFieldPath: metadata.name
    - type: FromCompositeFieldPath
      fromFieldPath: spec.nodeCount
      toFieldPath: spec.forProvider.defaultNodePool[0].nodeCount
```

This completes the comprehensive GitOps project with proper phase ordering and progressive complexity from local development to enterprise cloud deployments.
  name: crossplane-providers
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/gitops-infrastructure
    targetRevision: HEAD
    path: control-plane/crossplane/providers
  destination:
    server: https://kubernetes.default.svc
    namespace: crossplane-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

**File: `control-plane/argocd/applications/infrastructure-compositions.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure-compositions
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/gitops-infrastructure
    targetRevision: HEAD
    path: control-plane/crossplane/compositions
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**File: `control-plane/argocd/applications/vcluster-applications.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vcluster-environments
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/gitops-infrastructure
    targetRevision: HEAD
    path: control-plane/crossplane/claims
    directory:
      include: "*vcluster.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: capsule-tenants
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/gitops-infrastructure
    targetRevision: HEAD
    path: control-plane/crossplane/claims
    directory:
      include: "capsule-tenants.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Phase 4: Implementation and Testing

### Step 11: Deploy the GitOps Pipeline

```bash
# 1. Push your GitOps repository to GitHub
git init
git add .
git commit -m "Initial GitOps infrastructure setup"
git remote add origin https://github.com/YOUR_USERNAME/gitops-infrastructure.git
git push -u origin main

# 2. Apply ArgoCD project
kubectl apply -f control-plane/argocd/projects/infrastructure-project.yaml

# 3. Apply ArgoCD applications
kubectl apply -f control-plane/argocd/applications/
```

### Step 12: Monitor Multi-Tier Architecture

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check Crossplane providers
kubectl get providers

# Check vCluster deployments
kubectl get vclusters
kubectl get pods -n vcluster-prod
kubectl get pods -n vcluster-nonprod

# Check Capsule tenants
kubectl get tenants

# Monitor cluster provisioning
kubectl describe vcluster prod
kubectl describe tenant development

# Connect to vCluster environments
vcluster connect prod --namespace vcluster-prod
vcluster connect nonprod --namespace vcluster-nonprod
```

### Step 13: Access ArgoCD Dashboard

```bash
# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login with admin user and the password obtained earlier
# Navigate to https://localhost:8080
```

## Phase 5: Local MicroK8s Installation and Integration

### Step 14: Install MicroK8s Locally

```bash
# Install MicroK8s
sudo snap install microk8s --classic

# Add user to microk8s group
sudo usermod -a -G microk8s $USER
newgrp microk8s

# Enable necessary addons
microk8s enable dns dashboard storage ingress

# Check status
microk8s status --wait-ready

# Get kubeconfig
microk8s config > ~/.kube/microk8s-config

# Set context
export KUBECONFIG=~/.kube/microk8s-config:~/.kube/config
kubectl config view --flatten > ~/.kube/config
```

### Step 15: Connect MicroK8s to ArgoCD

```bash
# Add MicroK8s cluster to ArgoCD
microk8s config > /tmp/microk8s-kubeconfig
argocd cluster add microk8s --kubeconfig /tmp/microk8s-kubeconfig
```

## Phase 6: Multi-Tier Environment Management

### Step 16: Working with vClusters and Capsule Tenants

```bash
# List all vClusters
vcluster list

# Connect to Production vCluster
vcluster connect prod --namespace vcluster-prod
# You're now in the prod vCluster context

# Check Capsule tenants in prod vCluster
kubectl get tenants

# Switch to a specific tenant context (staging)
kubectl config set-context --current --namespace=staging-team-ns

# Connect to Non-Production vCluster
vcluster connect nonprod --namespace vcluster-nonprod
# You're now in the nonprod vCluster context

# Check development tenant resources
kubectl get all -n development-team-ns
```

### Step 17: Tenant Operations and Management

```bash
# Create a new namespace in development tenant
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: my-dev-app
  labels:
    capsule.clastix.io/tenant: development
EOF

# Deploy an application to development tenant
kubectl apply -n my-dev-app -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF

# Check tenant resource usage
kubectl describe tenant development
```

### Step 18: Multi-Environment Promotion Workflow

Create environment-specific configurations:

**File: `clusters/vclusters/prod/applications/sample-app.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-staging
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app-manifests
    targetRevision: HEAD
    path: environments/staging
  destination:
    server: https://vcluster-prod-api-server
    namespace: staging-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: