#!/bin/bash
set -e

echo "==> Starting Laravel container initialization..."

# Step 1: Create .env from .env.example if not exists
if [ ! -f .env ]; then
    echo "==> Creating .env from .env.example..."
    cp .env.example .env
    echo "✓ .env file created"
else
    echo "==> .env file already exists, skipping..."
fi

# Step 2: Generate APP_KEY if not set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "==> Generating Laravel APP_KEY..."
    php artisan key:generate --force
    echo "✓ APP_KEY generated"
else
    echo "==> APP_KEY already exists, skipping..."
fi

# Step 3: Run Laravel optimizations
echo "==> Running Laravel optimizations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo "✓ Laravel caches created"

# Step 4: Ensure proper permissions
echo "==> Setting proper permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
echo "✓ Permissions set"

echo "==> ✓ Container initialization completed successfully!"
echo "==> Starting services..."
