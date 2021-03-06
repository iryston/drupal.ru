#!/bin/sh

set -e

CI_COLOR='\033[1;32m'
NO_COLOR='\033[0m'
DRUPALRU_DUMP_FILE=$HOME/backups/drupal_main_$(date +%Y%m%d%H%M%S).sql
sm() {
  echo "";
  echo "${CI_COLOR}$@${NO_COLOR}";
}

exe() {
  sm "$@";
  $@;
}

. ~/.profile
exe "drush @dru.prod wd-del all -y"

sm "Create dumps"
exe "drush @dru.prod sql-dump --result-file=$DRUPALRU_DUMP_FILE --gzip --skip-tables-list=sphinxmain -y"
zcat $DRUPALRU_DUMP_FILE.gz | drush @dru.temp sqlc
exe "drush @dru.temp scr profiles/drupalru/scripts/sync/dev/sanitize.php"
drush @dru.temp sql-dump --result-file=$DRUPALRU_DEV_DUMP --gzip > /dev/null 2>&1
# Cleaning for local environments
exe "drush @dru.temp scr profiles/drupalru/scripts/sync/local/sanitize.php"
exe "drush @dru.temp ucrt admin --password=111"
exe "drush @dru.temp sql-dump --result-file=$HOME/domains/drupal.ru/sites/default/files/drupalru-dump.sql --gzip"
