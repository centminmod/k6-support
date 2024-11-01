#!/bin/sh
set -e

# Substitute environment variables in config_template.yml and generate config.yml
echo "Generating Alertmanager configuration..."
sed \
  -e "s|\${ALERTMANAGER_SMTP_SMARTHOST}|${ALERTMANAGER_SMTP_SMARTHOST}|g" \
  -e "s|\${ALERTMANAGER_SMTP_FROM}|${ALERTMANAGER_SMTP_FROM}|g" \
  -e "s|\${ALERTMANAGER_SMTP_AUTH_USERNAME}|${ALERTMANAGER_SMTP_AUTH_USERNAME}|g" \
  -e "s|\${ALERTMANAGER_SMTP_AUTH_PASSWORD}|${ALERTMANAGER_SMTP_AUTH_PASSWORD}|g" \
  -e "s|\${ALERTMANAGER_EMAIL_TO}|${ALERTMANAGER_EMAIL_TO}|g" \
  -e "s|\${ALERTMANAGER_EMAIL_CRITICAL_TO}|${ALERTMANAGER_EMAIL_CRITICAL_TO}|g" \
  -e "s|\${ALERTMANAGER_EMAIL_WARNING_TO}|${ALERTMANAGER_EMAIL_WARNING_TO}|g" \
  /etc/alertmanager/config_template.yml > /etc/alertmanager/config.yml

# Start Alertmanager with the generated config
echo "Starting Alertmanager..."
exec /bin/alertmanager "$@"
