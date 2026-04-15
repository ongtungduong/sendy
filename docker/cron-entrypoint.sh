#!/bin/bash
set -e

echo "Starting Sendy Cron Service..."

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

# Create cron jobs for Sendy
# These cron jobs handle scheduled campaigns, autoresponders, and import tasks
echo "Setting up cron jobs..."

# Remove old cron files if they exist
rm -f /etc/cron.d/sendy

# Create crontab entries for www-data user
# Redirect output to stdout (PID 1) so Docker logging driver can capture it
cat > /tmp/sendy-crontab << 'EOF'
# Sendy scheduled tasks
*/5 * * * * cd /var/www/html && /usr/local/bin/php scheduled.php >> /proc/1/fd/1 2>&1
*/1 * * * * cd /var/www/html && /usr/local/bin/php autoresponders.php >> /proc/1/fd/1 2>&1
*/1 * * * * cd /var/www/html && /usr/local/bin/php import-csv.php >> /proc/1/fd/1 2>&1
EOF

# Install crontab for www-data user
crontab -u www-data /tmp/sendy-crontab
rm /tmp/sendy-crontab

echo "Cron jobs configured successfully!"
echo "Running cron in foreground..."

# Run cron in the foreground
cron -f
