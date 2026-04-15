#!/bin/bash
set -e

echo "Starting Sendy Docker container..."

# Wait for MySQL to be ready (with timeout)
echo "Waiting for MySQL to be ready..."
MAX_RETRIES=60
RETRY=0
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --skip-ssl -e "SELECT 1" >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "ERROR: MySQL not ready after ${MAX_RETRIES}s. Exiting."
        exit 1
    fi
    echo -n "."
    sleep 1
done

echo ""
echo "MySQL is ready!"

# Config.php now reads from environment variables directly
# No need to update the file manually

# Set proper permissions on uploads directory only
chown -R www-data:www-data /var/www/html/uploads
chmod 775 /var/www/html/uploads

echo "Sendy is ready!"

# Execute the main container command
exec "$@"
