# Docker Build ve Push Otomasyonu

Bu dokümantasyon, Akaunting projesi için GitHub Actions ile otomatik Docker build ve push işlemlerinin nasıl yapılandırılacağını açıklar.

## 🚀 Özellikler

- **Otomatik Build**: Her tag push'unda ve main/master branch'inde otomatik build
- **Multi-Platform**: AMD64, ARM64 ve ARMv7 desteği (Linux, macOS, Raspberry Pi)
- **Cache Optimizasyonu**: GitHub Actions cache ile hızlı build
- **Security**: Artifact attestation ile güvenlik
- **Registry**: GitHub Container Registry (ghcr.io) entegrasyonu

## 📋 Gereksinimler

### 1. GitHub Repository Ayarları

Repository'nizde aşağıdaki ayarların yapılması gerekmektedir:

#### Secrets (Gerekli değil - GITHUB_TOKEN otomatik)
- `GITHUB_TOKEN`: Otomatik olarak sağlanır, manuel ekleme gerekmez

#### Repository Permissions
Repository Settings > Actions > General > Workflow permissions:
- ✅ "Read and write permissions" seçin
- ✅ "Allow GitHub Actions to create and approve pull requests" seçin

### 2. Package Permissions

GitHub Container Registry'ye push yapabilmek için:
1. Repository Settings > Actions > General
2. "Workflow permissions" bölümünde "Read and write permissions" seçin
3. "Allow GitHub Actions to create and approve pull requests" seçin

## 🔧 Kullanım

### Otomatik Build Tetikleyicileri

Workflow aşağıdaki durumlarda otomatik olarak çalışır:

1. **Tag Push**: `v1.0.0`, `v2.1.3` gibi semantic versioning tag'leri
2. **Main/Master Branch**: Ana branch'e push
3. **Pull Request**: Main/master branch'e açılan PR'lar (sadece build, push yapmaz)

### Manuel Build

Manuel olarak build tetiklemek için:
1. GitHub repository'de Actions sekmesine gidin
2. "Docker Build and Push" workflow'unu seçin
3. "Run workflow" butonuna tıklayın

## 🏷️ Tag Stratejisi

### Semantic Versioning
```
v1.0.0    -> ghcr.io/username/repo:1.0.0
v1.0.0    -> ghcr.io/username/repo:1.0
v1.0.0    -> ghcr.io/username/repo:1
v1.0.0    -> ghcr.io/username/repo:latest (eğer default branch ise)
```

### Branch Tags
```
main      -> ghcr.io/username/repo:main
master    -> ghcr.io/username/repo:master
```

## 📦 Docker Image Kullanımı

### Pull Image (Multi-Platform)
```bash
# Otomatik olarak host platformuna uygun image çekilir
docker pull ghcr.io/username/akaunting:latest

# Belirli platform için image çekmek isterseniz
docker pull --platform linux/amd64 ghcr.io/username/akaunting:latest
docker pull --platform linux/arm64 ghcr.io/username/akaunting:latest
docker pull --platform linux/arm/v7 ghcr.io/username/akaunting:latest
```

### Run Container
```bash
docker run -d \
  --name akaunting \
  -p 80:80 \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e DB_CONNECTION=mysql \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_DATABASE=akaunting \
  -e DB_USERNAME=akaunting \
  -e DB_PASSWORD=password \
  ghcr.io/username/akaunting:latest
```

### Docker Compose Örneği
```yaml
version: '3.8'

services:
  akaunting:
    image: ghcr.io/username/akaunting:latest
    ports:
      - "80:80"
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=akaunting
      - DB_USERNAME=akaunting
      - DB_PASSWORD=password
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=akaunting
      - MYSQL_USER=akaunting
      - MYSQL_PASSWORD=password
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

## 🔍 Monitoring ve Debugging

### Build Logları
1. GitHub repository'de Actions sekmesine gidin
2. İlgili workflow run'ına tıklayın
3. Job detaylarını inceleyin

### Container Logları
```bash
docker logs akaunting
```

### Container İçine Girme
```bash
docker exec -it akaunting sh
```

## 🛠️ Özelleştirme

### Environment Variables
Container'da aşağıdaki environment variable'ları kullanabilirsiniz:

```bash
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=akaunting
DB_USERNAME=akaunting
DB_PASSWORD=password
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-password
MAIL_ENCRYPTION=tls

# Proxy Configuration (Cloudflare/Reverse Proxy)
TRUSTED_PROXIES=*
FORCE_HTTPS=true
```

### Proxy/Cloudflare Konfigürasyonu

Bu Docker image proxy arkasında (Cloudflare, Nginx proxy, vs.) çalışacak şekilde optimize edilmiştir:

#### Cloudflare/Proxy Konfigürasyonu
```bash
# Tüm proxy trafiğine güven - Docker container için optimize edilmiş
# HTTPS -> HTTP geçişi sorunsuz çalışır
docker run -d \
  --name akaunting \
  -p 80:80 \
  -e APP_URL=https://your-domain.com \
  -e FORCE_HTTPS=true \
  -e TRUSTED_PROXIES=* \
  ghcr.io/username/akaunting:latest
```

#### Nginx Proxy Konfigürasyonu
```nginx
upstream akaunting {
    server container-ip:80;
}

server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://akaunting;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

### Volume Mounts
```bash
docker run -d \
  --name akaunting \
  -p 80:80 \
  -v akaunting_storage:/var/www/html/storage \
  -v akaunting_cache:/var/www/html/bootstrap/cache \
  ghcr.io/username/akaunting:latest
```

## 🚨 Troubleshooting

### Build Hataları
1. Dockerfile syntax kontrolü
2. Dependencies eksikliği
3. Permission sorunları

### Runtime Hataları
1. Environment variables kontrolü
2. Database bağlantısı
3. Storage permissions

### Registry Push Hataları
1. GitHub token permissions
2. Repository settings
3. Package permissions

## 🖥️ Platform Desteği

### Desteklenen Platformlar
- **linux/amd64**: Intel/AMD 64-bit (x86_64) - Çoğu sunucu ve masaüstü
- **linux/arm64**: ARM 64-bit (aarch64) - Apple Silicon Mac, ARM sunucular
- **linux/arm/v7**: ARM 32-bit (armhf) - Raspberry Pi, eski ARM cihazlar

### Platform Seçimi
```bash
# Otomatik platform seçimi (önerilen)
docker run ghcr.io/username/akaunting:latest

# Manuel platform seçimi
docker run --platform linux/amd64 ghcr.io/username/akaunting:latest
docker run --platform linux/arm64 ghcr.io/username/akaunting:latest
docker run --platform linux/arm/v7 ghcr.io/username/akaunting:latest
```

### Platform Performansı
- **AMD64**: En yüksek performans, production için önerilen
- **ARM64**: Apple Silicon Mac'ler için optimize edilmiş
- **ARMv7**: Raspberry Pi ve eski ARM cihazlar için

## 📚 Ek Kaynaklar

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Multi-platform Builds](https://docs.docker.com/buildx/working-with-buildx/)
- [Laravel Docker Best Practices](https://laravel.com/docs/deployment#docker)
- [Docker Platform Support](https://docs.docker.com/engine/reference/builder/#platform-specific-arguments)
