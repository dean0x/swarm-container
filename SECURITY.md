# Security Configuration Guide

This devcontainer provides multiple security presets to protect against various threat vectors when working with AI-generated code.

## Security Presets

### 🔒 Paranoid Mode (`SECURITY_PRESET=paranoid`)
**Maximum security for handling untrusted code or sensitive environments**

- **Network**: Strict allowlist - only explicitly allowed domains
- **Filesystem**: Read-only except `/workspace` and `/tmp`
- **Process**: No new privileges, all capabilities dropped
- **Resources**: Limited to 6GB RAM, 2 CPUs
- **Monitoring**: All blocked attempts are logged

**Use when:**
- Processing code from untrusted sources
- Working in highly regulated environments
- Handling sensitive data
- Testing potentially malicious prompts

### 🏢 Enterprise Mode (`SECURITY_PRESET=enterprise`)
**Balanced security for corporate environments**

- **Network**: Allowlist with common development services
- **Filesystem**: Restricted system paths, full workspace access
- **Process**: No new privileges, limited capabilities
- **Resources**: 12GB RAM, 6 CPUs
- **Custom domains**: Can add corporate services

**Use when:**
- Standard corporate development
- Team collaboration
- CI/CD pipeline integration
- Internal tool development

### 🚀 Development Mode (`SECURITY_PRESET=development`) - *Default*
**Relaxed security for local development**

- **Network**: Open access with blocklist for known malicious sites
- **Filesystem**: Broader access for development tools
- **Process**: Standard restrictions
- **Resources**: 8GB RAM, 4 CPUs
- **Features**: Hot reload, debug logging

**Use when:**
- Local experimentation
- Rapid prototyping
- Learning and tutorials
- Personal projects

## Quick Start with Security Presets

### Using Paranoid Mode
```bash
# Copy the paranoid environment template
cp .env.paranoid .env

# Edit .env to optionally add your API key
# Option 1: Set API key here
# ANTHROPIC_API_KEY=sk-ant-...
# Option 2: Leave empty and use /login command after starting Claude Code

# Open in VS Code - the container will use paranoid settings
code .
```

### Using Enterprise Mode with Custom Domains
```bash
# Copy the enterprise template
cp .env.enterprise .env

# Edit .env to add your company's internal services
# CUSTOM_ALLOWED_DOMAINS=gitlab.company.com,artifactory.company.com

# Optionally add your API key (or use /login command later)
# ANTHROPIC_API_KEY=sk-ant-...

code .
```

### Using Development Mode
```bash
# Copy the development template
cp .env.development .env

# Optionally add your API key (or use /login command later) and open
code .
```

## Security Features

### 1. Network Isolation

The container implements network security at multiple levels:

- **Firewall Rules**: iptables-based filtering
- **DNS Control**: Custom DNS resolution
- **Domain Allowlisting**: Only approved services can be contacted
- **IP Range Management**: CIDR blocks for cloud services

### 2. Filesystem Protection

- **Read-only Mounts**: System directories are read-only
- **Isolated Workspace**: Code execution limited to `/workspace`
- **No Host Access**: Container cannot access host filesystem
- **Temporary Storage**: `/tmp` is isolated and cleared on restart

### 3. Process Isolation

- **Non-root User**: Runs as `node` user (UID 1000)
- **Capability Dropping**: Removes unnecessary Linux capabilities
- **No New Privileges**: Prevents privilege escalation
- **Resource Limits**: CPU and memory constraints

### 4. Monitoring and Auditing

Run the security monitor to check for issues:
```bash
bash scripts/security/security-monitor.sh
```

This checks for:
- Unexpected network connections
- Suspicious processes
- File system modifications
- SUID binaries
- Claude Code integrity

## Custom Configuration

### Adding Allowed Domains

For enterprise environments, add your internal services:

```bash
# In your .env file
CUSTOM_ALLOWED_DOMAINS=api.company.com,npm.company.com,pypi.company.com
```

### Adjusting Resource Limits

```bash
# In your .env file
CONTAINER_MEMORY=16g
CONTAINER_CPUS=8
```

### Corporate Proxy Support

```bash
# In your .env file
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com
```

## Security Best Practices

1. **Always use the appropriate security preset** for your use case
2. **Review AI-generated code** before execution
3. **Monitor security logs** regularly in paranoid mode
4. **Keep the container updated** with latest security patches
5. **Use separate containers** for different trust levels
6. **Don't disable security features** unless absolutely necessary

## Threat Model

This container protects against:

### From AI/Code Perspective:
- **Prompt Injection**: Malicious prompts trying to escape constraints
- **Data Exfiltration**: Code attempting to send data externally
- **Malware Installation**: Preventing persistent malware
- **Supply Chain Attacks**: Blocking malicious package downloads

### From Container Perspective:
- **Container Escape**: Preventing access to host system
- **Privilege Escalation**: Blocking attempts to gain root
- **Network Pivot**: Preventing lateral movement
- **Resource Exhaustion**: CPU/memory limits prevent DoS

## Troubleshooting

### "Permission Denied" Errors
- Check if you're trying to write outside `/workspace`
- Verify the security preset allows the operation
- Run `ls -la` to check file ownership

### Network Connection Blocked
- Check allowed domains in your security preset
- Add required domains to `CUSTOM_ALLOWED_DOMAINS`
- Use `scripts/security/security-monitor.sh` to see blocked attempts

### Container Won't Start
- Verify Docker has sufficient resources
- Check for conflicting security policies
- Try with `development` preset first

## Emergency Procedures

If you suspect a security breach:

1. **Stop the container immediately**
   ```bash
   docker stop <container-name>
   ```

2. **Check security logs**
   ```bash
   cat security.log
   ```

3. **Review recent file changes**
   ```bash
   find /workspace -mtime -1 -type f
   ```

4. **Report issues**
   - For Claude Code issues: https://github.com/anthropics/claude-code/issues
   - For container issues: Create an issue in this repository