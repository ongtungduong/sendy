#!/bin/bash
set -e

echo "Starting Sendy Docker container..."

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --skip-ssl -e "SELECT 1" >/dev/null 2>&1; do
    echo -n "."
    sleep 1
done

echo "MySQL is ready!"

# Config.php now reads from environment variables directly
# No need to update the file manually

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 777 /var/www/html/uploads

echo "Sendy is ready!"

# Execute the main container command
exec "$@"
