#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="msmtp-config"

EMAIL_USER=${EMAIL_USER:-"${EMAIL_ADDRESS}"}

echo "Configuring msmtp settings..." | info "[${program_name}] "
sed -i "s/EMAIL_HOST/${EMAIL_HOST}/g" /etc/msmtprc
sed -i "s/EMAIL_PORT/${EMAIL_PORT}/g" /etc/msmtprc
sed -i "s/EMAIL_ADDRESS/${EMAIL_ADDRESS}/g" /etc/msmtprc
sed -i "s/EMAIL_USER/${EMAIL_USER}/g" /etc/msmtprc
sed -i "s/EMAIL_PASSWORD/${EMAIL_PASSWORD}/g" /etc/msmtprc
