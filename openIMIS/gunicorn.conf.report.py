# gunicorn.conf.py
import multiprocessing

bind = "0.0.0.0:8000"

# Nombre de workers : (2 x CPU) + 1
workers = multiprocessing.cpu_count() * 2 + 1
print("workers ", workers)

# Worker Gevent : le changement clé
worker_class = "gevent"

# Connexions simultanées par worker
worker_connections = 1000

# Timeouts
timeout = 600          # 10 min pour les rapports longs
graceful_timeout = 120
keepalive = 5

# Recyclage des workers (évite les memory leaks)
max_requests = 1000
max_requests_jitter = 100

# Logs
accesslog = "./access.log"
errorlog  = "./error.log"
loglevel  = "info"
