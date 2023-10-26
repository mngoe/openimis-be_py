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
pip install -e /openimis-be-report-cs_py
pip install -e /openimis-be-policy_py
pip install -e /openimis-be-insuree_py
pip install -e /openimis-be-medical_py
pip install -e /openimis-be-api_fhir_r4_py
pip install pydantic==1.10.0
pip install gunicorn
cd /openimis-be/openIMIS/
gunicorn -b 0.0.0.0:8000 -w 4 openIMIS.wsgi
#python manage.py runserver 0.0.0.0:8000

#while :; do sleep 10; done

show_help() {
  echo """
  Commands
  ---------------------------------------------------------------

  start            : start django
  worker           : start Celery worker
  start_asgi       : use daphne -b ASGI_IP:WSGI_PORT -p SERVER_PORT  ASGI_APPLICATION
  start_wsgi       : use gunicorn -b 0.0.0.0 -w 4 openIMIS.wsgi
  manage           : run django manage.py
  eval             : eval shell command
  bash             : run bash
  """
}

init(){
  if [ "${DJANGO_MIGRATE,,}" == "true" ] || [ -z "$SCHEDULER_AUTOSTART" ]; then
        echo "Migrating..."
        python manage.py migrate
        export SCHEDULER_AUTOSTART=True
  fi
}

#export PYTHONPATH="/opt/app:$PYTHONPATH"
if [ -z "$DJANGO_SETTINGS_MODULE" ]; then
  export DJANGO_SETTINGS_MODULE=openIMIS.settings
fi

case "$1" in
  "start" )
    init
    echo "Starting Django..."
    python server.py
  ;;
  "start_asgi" )
    init
    echo "Starting Django ASGI..."
    def_ip='0.0.0.0'
    def_port='8000'
    def_app='openIMIS.asgi:application'
    SERVER_IP="${ASGI_IP:-$def_ip}"
    SERVER_PORT="${ASGI_PORT:-$def_port}"
    SERVER_APPLICATION="${ASGI_APPLICATION:-$def_app}"

    daphne -b "$SERVER_IP" -p "$SERVER_PORT" "$SERVER_APPLICATION"
  ;;
  "start_wsgi" )
    init
    echo "Starting Django WSGI..."
    def_ip='0.0.0.0'
    def_port='8000'
    def_app='openIMIS.wsgi'

    SERVER_IP="${WSGI_IP:-$def_ip}"
    SERVER_PORT="${WSGI_PORT:-$def_port}"
    SERVER_APPLICATION="${WSGI_APPLICATION:-$def_app}"
    SERVER_WORKERS="${WSGI_WORKERS:-4}"

    gunicorn -b "$SERVER_IP:$SERVER_PORT" -w $SERVER_WORKERS "$SERVER_APPLICATION"
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