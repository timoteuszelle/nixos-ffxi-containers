#!/bin/bash
set -e

echo "Checking environment..."
echo "DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_USER=$DB_USER DB_PASS=$DB_PASS DB_NAME=$DB_NAME ZONE_IP=$ZONE_IP"

echo "Checking log directories..."
ls -ld /server/log

echo "Checking settings files..."
ls -l /app/settings/network.lua /app/login.key /app/login.cert
echo "Checking network.lua content..."
cat /app/settings/network.lua

echo "Checking database connection..."
mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASS" "$DB_NAME" -e "SELECT 1" || { echo "Database connection failed: $? $DB_HOST $DB_PORT $DB_USER $DB_NAME"; exit 1; }

echo "Waiting for zone_weather table..."
while ! mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASS" "$DB_NAME" -e "SELECT 1 FROM zone_weather LIMIT 1"; do
    echo "Waiting for database... Error: $?"
    sleep 5
    if [ "$((SECONDS / 60))" -ge 5 ]; then
        echo "Timeout waiting for database after 5 minutes"
        exit 1
    fi
done

echo "Database is ready!"
sleep 5

echo "Skipping database update (git repo not required)..."
sleep 5

echo "Starting FFXI server..."
cd /app
echo "Starting xi_connect..."
./xi_connect --log /server/log/connect.log &
echo "Starting xi_search..."
./xi_search --log /server/log/search.log &
echo "Starting xi_map..."
./xi_map --log /server/log/map.log &
echo "Starting xi_world..."
./xi_world --log /server/log/world.log &

echo "FFXI server started!"
wait
