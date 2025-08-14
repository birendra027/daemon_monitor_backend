# Daemon Monitor Backend Helm Chart

This Helm chart deploys the Daemon Monitor Backend application on Kubernetes. The application consists of a Flask backend service and a MySQL database.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Access to the container registry containing the application images

## Chart Components

- **Flask Application**: The main backend service
- **MySQL Database**: Persistent database using Bitnami MySQL chart
- **ConfigMap**: Non-sensitive configuration data
- **Secret**: Sensitive data like passwords and API keys
- **Service**: Network access to the application
- **Ingress**: Optional external access configuration
- **HPA**: Optional horizontal pod autoscaler

## Quick Start

### 1. Install the Chart

```bash
# Make scripts executable
chmod +x install.sh uninstall.sh

# Install the application
./install.sh
```

### 2. Uninstall the Chart

```bash
# Uninstall the application
./uninstall.sh
```

## Manual Installation

### 1. Add the Bitnami repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Install dependencies

```bash
cd helm
helm dependency build
cd ..
```

### 3. Install the chart

```bash
helm install daemon-monitor ./helm \
  --namespace daemon-monitor \
  --create-namespace \
  --wait \
  --timeout 10m
```

## Configuration

### Values File

The `values.yaml` file contains all configurable parameters. Key sections include:

- **app**: Application deployment configuration
- **mysql**: Database configuration
- **config**: Application and database connection settings
- **ingress**: External access configuration
- **autoscaling**: Horizontal pod autoscaler settings

### Environment Variables

Create a `.env` file based on `env.example` with your actual values:

```bash
cp helm/env.example helm/.env
# Edit helm/.env with your actual values
```

### Custom Values

You can override values during installation:

```bash
helm install daemon-monitor ./helm \
  --namespace daemon-monitor \
  --set app.replicaCount=3 \
  --set mysql.auth.password=my-secure-password \
  --set ingress.enabled=true
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress      │    │   Service       │    │   Deployment    │
│   (Optional)   │───▶│   (ClusterIP)   │───▶│   (Flask App)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   ConfigMap     │    │   Secret        │
                       │   (Non-sensitive│    │   (Sensitive    │
                       │    config)      │    │    data)        │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   MySQL        │    │   PVC           │
                       │   (Database)   │───▶│   (Storage)     │
                       └─────────────────┘    └─────────────────┘
```

## Accessing the Application

### Port Forward

```bash
kubectl port-forward --namespace daemon-monitor svc/daemon-monitor-app 8080:80
```

Then access at: http://localhost:8080

### Service URL

```bash
# Get the service URL
kubectl get svc --namespace daemon-monitor daemon-monitor-app
```

### Ingress (if enabled)

```bash
# Get the ingress URL
kubectl get ingress --namespace daemon-monitor
```

## Monitoring and Logs

### Check Pod Status

```bash
kubectl get pods --namespace daemon-monitor
```

### View Logs

```bash
# Application logs
kubectl logs --namespace daemon-monitor -l app.kubernetes.io/instance=daemon-monitor

# Database logs
kubectl logs --namespace daemon-monitor -l app.kubernetes.io/instance=daemon-monitor,app.kubernetes.io/component=database
```

### Resource Usage

```bash
kubectl top pods --namespace daemon-monitor
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment daemon-monitor-app --replicas=5 --namespace daemon-monitor
```

### Auto Scaling

Enable HPA in `values.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 70
```

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and requests
2. **Database connection issues**: Verify MySQL credentials and service names
3. **Image pull errors**: Ensure image repository access and correct tags

### Debug Commands

```bash
# Describe resources
kubectl describe pod <pod-name> --namespace daemon-monitor
kubectl describe service <service-name> --namespace daemon-monitor

# Check events
kubectl get events --namespace daemon-monitor --sort-by='.lastTimestamp'

# Check configmaps and secrets
kubectl get configmaps,secrets --namespace daemon-monitor
```

## Security Considerations

- Secrets are base64 encoded but not encrypted by default
- Consider using external secret management solutions for production
- Network policies can be added for additional security
- RBAC can be configured for fine-grained access control

## Backup and Recovery

### Database Backup

```bash
# Create backup
kubectl exec --namespace daemon-monitor <mysql-pod-name> -- \
  mysqldump -u root -p<password> daemon_monitor > backup.sql

# Restore backup
kubectl exec -i --namespace daemon-monitor <mysql-pod-name> -- \
  mysql -u root -p<password> daemon_monitor < backup.sql
```

### Persistent Volume Backup

```bash
# Backup PVC data
kubectl cp daemon-monitor/<mysql-pod-name>:/var/lib/mysql ./mysql-backup
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This chart is licensed under the same license as the parent project.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes and Helm documentation
- Open an issue in the project repository
