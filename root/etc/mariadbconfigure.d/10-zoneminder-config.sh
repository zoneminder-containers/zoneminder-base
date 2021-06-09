#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
# ==============================================================================
# ZoneMinder-config
# Configure default ZM Settings
# ==============================================================================

insert_command=""

if ! (mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -e 'USE zm; SELECT * FROM Config LIMIT 1' > /dev/null 2>&1); then
  echo "Creating ZoneMinder db for first run" | init
  mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" < /usr/share/zoneminder/db/zm_create.sql

  echo "Disabling file log to prevent duplicate logs from syslog" | init
  insert_command+="UPDATE Config SET Value = -5 WHERE Name = 'ZM_LOG_LEVEL_FILE';"

  echo "Configuring ZoneMinder Email settings..." | init
  insert_command+="UPDATE Config SET Value = 1 WHERE Name = 'ZM_NEW_MAIL_MODULES';"
  insert_command+="UPDATE Config SET Value = 1 WHERE Name = 'ZM_OPT_EMAIL';"
  insert_command+="UPDATE Config SET Value = 1 WHERE Name = 'ZM_OPT_MESSAGE';"
  insert_command+="UPDATE Config SET Value = 1 WHERE Name = 'ZM_SSMTP_MAIL';"
  insert_command+="UPDATE Config SET Value = '/usr/bin/msmtp' WHERE Name = 'ZM_SSMTP_PATH';"
  insert_command+="UPDATE Config SET Value = '${EMAIL_ADDRESS}' WHERE Name = 'ZM_EMAIL_ADDRESS';"
  insert_command+="UPDATE Config SET Value = '${EMAIL_ADDRESS}' WHERE Name = 'ZM_FROM_EMAIL';"

else

  echo "Configuring ZoneMinder Email From Address..." | info
  insert_command+="UPDATE Config SET Value = '${EMAIL_ADDRESS}' WHERE Name = 'ZM_FROM_EMAIL';"

fi

if [[ -n "${ZM_SERVER_HOST}" ]] \
 && [ "$(mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" zm -e \
  "SELECT COUNT(*) FROM Servers WHERE Name = '${ZM_SERVER_HOST}';"  \
  | cut -f 2 \
  | sed -n '2 p' \
  )" \
  == "0" ]; then
    echo "Adding multi-server db entry" | init
    insert_command+="INSERT INTO \`Servers\` "
    insert_command+="(Protocol, Hostname, Port, PathToIndex, PathToZMS, PathToApi, Name, zmstats, zmaudit, zmtrigger, zmeventnotification)";
    insert_command+=" VALUES "
    insert_command+="('http','${ZM_SERVER_HOST}',80,'/index.php','/cgi-bin/nph-zms','/zm/api','${ZM_SERVER_HOST}',1,1,1,0);";
fi

echo "Applying db changes..." | info
mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" zm -e "${insert_command}"
