#!/bin/bash
set -e

export SITE_ROOT=api 
export REMOTE_USER_AUTHENTICATION=False 
export ROW_SECURITY=False 
export DEBUG=True 


cd /openimis-be/
python modules-requirements.py openimis.json > modules-requirements.txt
pip install -r modules-requirements.txt
pip install -e /openimis-be-core_py
pip install -e /openimis-be-program_py
pip install -e /openimis-be-cs_py
pip install -e /openimis-be-csu_py
pip install -e /openimis-be-claim_py
pip install -e /openimis-be-location_py
pip install -e /openimis-be-product_py
pip install -e /openimis-be-report-csu_py
pip install -e /openimis-be-policy_py
pip install -e /openimis-be-insuree_py
cd /openimis-be/openIMIS/
python manage.py runserver 0.0.0.0:8000

while :; do sleep 10; done

show_help() {
  echo """
  Commands
  ---------------------------------------------------------------

  start            : start django
  worker           : start Celery worker

  manage           : run django manage.py
  eval             : eval shell command
  bash             : run bash
  """
}

#export PYTHONPATH="/opt/app:$PYTHONPATH"
if [ -z "$DJANGO_SETTINGS_MODULE" ]; then
  export DJANGO_SETTINGS_MODULE=openIMIS.settings
fi

case "$1" in
  "start" )
    if [ "$SITE_ROOT" == "api" ] 
    then
      echo "Migrating..."
      python manage.py migrate
    fi
    echo "Starting Django..."
    SCHEDULER_AUTOSTART=True python server.py
  ;;
  "start_asgi" )
    echo "Starting Django ASGI..."
    def_ip='0.0.0.0'
    def_port='8000'
    def_app='openIMIS.asgi:application'

    SERVER_IP="${ASGI_IP:-$def_ip}"
    SERVER_PORT="${ASGI_PORT:-$def_port}"
    SERVER_APPLICATION="${ASGI_APPLICATION:-$def_app}"

    daphne -b "$SERVER_IP" -p "$SERVER_PORT" "$SERVER_APPLICATION"
  ;;
  "worker" )
    echo "Starting Celery with url ${CELERY_BROKER_URL} ${DB_NAME}..."
    echo "Settings module: $DJANGO_SETTINGS_MODULE"
    celery -A openIMIS worker --loglevel=DEBUG
  ;;
  "manage" )
    ./manage.py "${@:2}"
  ;;
  "eval" )
    eval "${@:2}"
  ;;
  "bash" )
    bash
  ;;
  * )
    show_help
  ;;
esac