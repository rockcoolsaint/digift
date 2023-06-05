#!/bin/sh

set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi



# Run deploy tasks in warmup mode
if [ "$WARMUP_DEPLOY" == "true" ]; then

  if [ "$DB_SETUP" == "true" ]; then

    # The traditional Rails setup
    echo "Warmup deploy: running setup..."
    bundle exec rake db:setup 

    # This is a custom Rake task which perform additional steps our application needs 
    # (e.g. setup cron jobs via Cloudtasker)
    # echo "Warmup deploy: running seed tasks..."
    # bundle exec rake db:seed
  fi


  # The traditional Rails migration
  echo "Warmup deploy: running migrations..."
  bundle exec rake db:migrate
  # This is a custom Rake task which perform additional steps our application needs 
  # (e.g. setup cron jobs via Cloudtasker)
  # echo "Warmup deploy: running deploy tasks..."
  # bundle exec rake deploy:prepare
  echo "Warmup deploy: deploy tasks done"

  
fi

bundle exec rails s -b 0.0.0.0
