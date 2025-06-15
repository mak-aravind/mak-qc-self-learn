# ETCD Essential Notes for CKA Certification

## What is ETCD?

ETCD is a **distributed, reliable, key-value store** that is:

- **Simple** - Easy to install and use
- **Secure** - Built with security in mind
- **Fast** - High performance key-value operations

## Key-Value Store vs Traditional Databases

### Traditional SQL/Relational Databases

- Store data in **tabular format** (rows and columns)
- Each row represents an entity, columns represent attributes
- Adding new attributes affects the **entire table**
- Results in many **empty cells** when attributes don't apply to all entities
- Schema changes impact all records

### Key-Value Store (ETCD)

- Stores information as **documents/pages**
- Each entity gets its **own document**
- Information stored within individual files
- **Any format or structure** supported
- Changes to one document **don't affect others**
- No empty fields - only relevant data stored
- Commonly uses **JSON or YAML** formats for complex data

## ETCD Installation & Setup

### Quick Installation

```bash
# Download binary from GitHub Releases
# Extract the binary
# Run the ETCD executable
./etcd
```

### Default Configuration

- **Default Port**: 2379
- Service starts automatically when ETCD runs
- Clients can connect to store/retrieve information

## ETCDCTL Client Commands

### Version Detection

```bash
# Check ETCDCTL version and API version
etcdctl version
```

**Important**: Two version types exist:

1. **ETCDCTL utility version** (e.g., v3.0)
2. **API version** (either 2 or 3)

### API Version Configuration

#### Check Current API Version

```bash
etcdctl version
# Look for "API version" in output
```

#### Set API Version to v3

```bash
# Option 1: Per command
ETCDCTL_API=3 etcdctl [command]

# Option 2: Export for entire session (recommended)
export ETCDCTL_API=3
```

### ETCD Commands by API Version

#### API Version 2.0 Commands

```bash
# Set key-value pair
./etcdctl set key1 value1

# Get value
./etcdctl get key1

# Check version (option format)
./etcdctl --version
```

#### API Version 3.0 Commands

```bash
# Set key-value pair
./etcdctl put key1 value1

# Get value
./etcdctl get key1

# Check version (command format)
./etcdctl version
```

## ETCD Version History (Important for CKA)

|Version|Release Date|Key Features|
|---|---|---|
|v0.1|August 2013|First version|
|v2.0|February 2015|**RAFT consensus algorithm redesigned**<br/>Supported 10,000+ writes/second|
|v3.0|January 2017|Major optimizations & performance improvements<br/>**API changes**|
|CNCF|November 2018|ETCD project incubated in CNCF|

### Critical Version Differences (v2.0 vs v3.0)

- **API versions changed** between v2.0 and v3.0
- **Command syntax changed**
- **Default API version** in newer ETCD installations is v3.0
- Always check API version before running commands

## CKA Exam Key Points

### Command Compatibility

- **Always verify API version** before executing commands
- Use `export ETCDCTL_API=3` for consistency
- Remember command differences:
    - v2: `set/get`, `--version` (option)
    - v3: `put/get`, `version` (command)

### Troubleshooting Tips

1. If commands don't work, check API version first
2. Set environment variable if needed
3. Newer ETCD defaults to API v3, but always verify

### Future Topics (Advanced CKA)

- **High Availability (HA)** ETCD setup
- **Distributed systems** concepts
- **RAFT protocol** understanding
- **Cluster mode** operations
- **Best practices** for node count in clusters
- **ETCD in Kubernetes** integration

## Quick Reference Commands

```bash
# Essential commands for CKA
export ETCDCTL_API=3                    # Set API version
etcdctl version                         # Check versions
etcdctl put key1 value1                 # Store data
etcdctl get key1                        # Retrieve data
etcdctl                                 # List all available commands
```

## Exam Preparation Notes

- **Practice both API versions** - you might encounter either in exam scenarios
- **Always set ETCDCTL_API=3** as first step in ETCD tasks
- **Understand the concept** of key-value vs relational storage
- **Remember default port**: 2379
- **Know the evolution** from v2 to v3 and why commands changed
- Be prepared for **HA and clustering** concepts in advanced scenarios