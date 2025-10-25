# Docker Environment Variables Guide

## Overview

This Docker container is designed to be **self-contained** and automatically handles most Laravel configuration internally. You only need to provide **essential external configuration** such as database credentials and application URL.

## How It Works

### Automatic Configuration Inside Container

When the container starts, it automatically:

1. ✅ **Creates `.env` file** from `.env.example` if it doesn't exist
2. ✅ **Generates `APP_KEY`** automatically using `php artisan key:generate`
3. ✅ **Runs database migrations** using `php artisan migrate --force`
4. ✅ **Optimizes Laravel** (config cache, route cache, view cache)
5. ✅ **Sets proper permissions** for storage and cache directories

### What You Need to Provide

Only provide these **essential external variables**:

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `APP_URL` | Yes | Your application URL | `https://yourdomain.com` |
| `DB_HOST` | Yes | Database host | `mysql` or `db` or IP |
| `DB_DATABASE` | Yes | Database name | `akaunting` |
| `DB_USERNAME` | Yes | Database username | `akaunting_user` |
| `DB_PASSWORD` | Yes | Database password | `your-secure-password` |

## Deployment Methods

### 1. Docker Run

```bash
docker run -d \
  --name akaunting \
  -p 80:80 \
  -e APP_URL=https://yourdomain.com \
  -e DB_HOST=your-db-host \
  -e DB_DATABASE=akaunting \
  -e DB_USERNAME=akaunting_user \
  -e DB_PASSWORD=your-secure-password \
  ghcr.io/your-org/akaunting:latest
```

### 2. Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: akaunting-db
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: akaunting
      MYSQL_USER: akaunting_user
      MYSQL_PASSWORD: secure_password
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - akaunting-network
    restart: unless-stopped

  akaunting:
    image: ghcr.io/your-org/akaunting:latest
    container_name: akaunting
    ports:
      - "80:80"
    environment:
      # Essential Configuration
      APP_URL: https://yourdomain.com
      
      # Database Configuration
      DB_HOST: db
      DB_DATABASE: akaunting
      DB_USERNAME: akaunting_user
      DB_PASSWORD: secure_password
    depends_on:
      - db
    volumes:
      - app_data:/var/www/html/storage
    networks:
      - akaunting-network
    restart: unless-stopped

volumes:
  db_data:
    driver: local
  app_data:
    driver: local

networks:
  akaunting-network:
    driver: bridge
```

Start the stack:

```bash
docker-compose up -d
```

### 3. Kubernetes Deployment

Create `akaunting-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: akaunting-secrets
  namespace: default
type: Opaque
stringData:
  DB_PASSWORD: "your-secure-password"
```

Create `akaunting-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: akaunting
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: akaunting
  template:
    metadata:
      labels:
        app: akaunting
    spec:
      containers:
      - name: akaunting
        image: ghcr.io/your-org/akaunting:latest
        ports:
        - containerPort: 80
        env:
        - name: APP_URL
          value: "https://yourdomain.com"
        - name: DB_HOST
          value: "mysql-service"
        - name: DB_DATABASE
          value: "akaunting"
        - name: DB_USERNAME
          value: "akaunting_user"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: akaunting-secrets
              key: DB_PASSWORD
        volumeMounts:
        - name: storage
          mountPath: /var/www/html/storage
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: akaunting-storage-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: akaunting-service
  namespace: default
spec:
  selector:
    app: akaunting
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

Apply configurations:

```bash
kubectl apply -f akaunting-secret.yaml
kubectl apply -f akaunting-deployment.yaml
```

## Proxy Configuration (Cloudflare, Nginx, etc.)

The container is **pre-configured** to work behind reverse proxies like Cloudflare, Nginx, or Traefik.

### How It Works

- ✅ Container listens on **HTTP port 80**
- ✅ Your reverse proxy terminates **HTTPS (443)**
- ✅ Proxy forwards to container: **HTTPS → HTTP**
- ✅ Container automatically detects proxy headers
- ✅ Laravel generates correct HTTPS URLs

### Example: Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

### Example: Cloudflare

Just point your Cloudflare DNS to your server IP and enable **SSL/TLS mode: Full** or **Full (strict)**. The container will automatically detect Cloudflare's proxy headers.

## Advanced Configuration

### Custom Environment Variables

If you need to override additional Laravel settings, you can pass any `.env` variable:

```bash
docker run -d \
  --name akaunting \
  -p 80:80 \
  -e APP_URL=https://yourdomain.com \
  -e DB_HOST=mysql \
  -e DB_DATABASE=akaunting \
  -e DB_USERNAME=akaunting_user \
  -e DB_PASSWORD=password \
  -e APP_LOCALE=tr \
  -e APP_TIMEZONE=Europe/Istanbul \
  -e SESSION_LIFETIME=1440 \
  -e CACHE_DRIVER=redis \
  -e REDIS_HOST=redis \
  ghcr.io/your-org/akaunting:latest
```

### Persistent Storage

To persist uploaded files and data, mount volumes:

```bash
docker run -d \
  --name akaunting \
  -p 80:80 \
  -v akaunting-storage:/var/www/html/storage \
  -e APP_URL=https://yourdomain.com \
  -e DB_HOST=mysql \
  -e DB_DATABASE=akaunting \
  -e DB_USERNAME=akaunting_user \
  -e DB_PASSWORD=password \
  ghcr.io/your-org/akaunting:latest
```

### Health Check

Add a health check to your deployment:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/login"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Troubleshooting

### Check Container Logs

```bash
docker logs akaunting
```

You should see initialization messages:

```
==> Starting Laravel container initialization...
==> Creating .env from .env.example...
✓ .env file created
==> Generating Laravel APP_KEY...
✓ APP_KEY generated
==> Configuring environment variables from container...
✓ DB_HOST set to: mysql
✓ DB_DATABASE set to: akaunting
...
==> ✓ Container initialization completed successfully!
```

### Access Container Shell

```bash
docker exec -it akaunting /bin/sh
```

### Check Laravel Configuration

```bash
docker exec -it akaunting php artisan config:show
docker exec -it akaunting php artisan env
```

### Database Connection Issues

```bash
# Test database connection
docker exec -it akaunting php artisan tinker
>>> DB::connection()->getPdo();
```

### Permission Issues

```bash
# Fix permissions manually if needed
docker exec -it akaunting chown -R www-data:www-data /var/www/html/storage
docker exec -it akaunting chmod -R 775 /var/www/html/storage
```

## Security Best Practices

### 1. Use Docker Secrets (Docker Swarm)

```bash
echo "your-secure-db-password" | docker secret create db_password -

docker service create \
  --name akaunting \
  --secret db_password \
  -e APP_URL=https://yourdomain.com \
  -e DB_HOST=mysql \
  -e DB_DATABASE=akaunting \
  -e DB_USERNAME=akaunting_user \
  -e DB_PASSWORD_FILE=/run/secrets/db_password \
  ghcr.io/your-org/akaunting:latest
```

### 2. Use Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: akaunting-secrets
type: Opaque
data:
  # Base64 encoded values
  db-password: eW91ci1zZWN1cmUtcGFzc3dvcmQ=
```

### 3. Environment Files (Not Recommended for Production)

Only for development/testing:

```bash
# .env.docker
APP_URL=https://yourdomain.com
DB_HOST=mysql
DB_DATABASE=akaunting
DB_USERNAME=akaunting_user
DB_PASSWORD=your-secure-password

docker run --env-file .env.docker akaunting:latest
```

### 4. Restrict Network Access

```yaml
# docker-compose.yml
networks:
  akaunting-network:
    driver: bridge
    internal: true  # No external access
```

## Multi-Platform Support

This container supports multiple architectures:

- ✅ `linux/amd64` - Intel/AMD 64-bit
- ✅ `linux/arm64` - ARM 64-bit (Apple Silicon, AWS Graviton)
- ✅ `linux/arm/v7` - ARM 32-bit (Raspberry Pi)

Docker automatically pulls the correct image for your platform.

## Production Checklist

- [ ] Set strong `DB_PASSWORD`
- [ ] Use HTTPS with valid SSL certificate
- [ ] Configure proper reverse proxy (Cloudflare, Nginx, Traefik)
- [ ] Set up database backups
- [ ] Mount persistent volumes for `/var/www/html/storage`
- [ ] Configure monitoring and health checks
- [ ] Use container orchestration (Kubernetes, Docker Swarm)
- [ ] Set resource limits (CPU, memory)
- [ ] Enable container auto-restart policy
- [ ] Set up log aggregation (ELK, Grafana Loki)
- [ ] Configure firewall rules
- [ ] Use secrets management (Vault, Kubernetes Secrets)

## Support

For issues or questions:
- GitHub Issues: https://github.com/your-org/akaunting/issues
- Documentation: https://github.com/your-org/akaunting/blob/master/DOCKER_SETUP.md

## License

This Docker configuration is provided as-is for the Akaunting project.
