## Dynamically patch settings

import os
import pathlib

here = pathlib.Path(__file__).parent.absolute()

settings_file = here.joinpath('backend_settings.v2.py')

settings_url = 'https://github.com/uselotus/lotus/raw/main/backend/lotus/settings.py'

os.system(f"wget -O {settings_file.as_posix()} {settings_url}")

settings_text = ""

with settings_file.open('r') as f:
    skip = 0
    skip_until = ""
    for line in f.readlines():
        if skip > 1:
            skip -= 1
            continue

        if skip_until:
            if skip_until in line:
                settings_text += line
                skip_until = ""
            continue

        # Patch K8s
        if line.startswith('ON_HEROKU'):
            settings_text += f"""
{line.strip()}
IN_K8S = config("IN_K8S", default=False, cast=bool)
FRONTEND_SERVICE_HOST = config("LOTUS_FRONTEND_SERVICE_HOST", default="")
FRONTEND_HOST = config("LOTUS_FRONTEND_PORT_80_TCP_ADDR", default="")
"""
            continue

        # Patch Postgres DB
        if line.startswith('POSTGRES_DB'):
            settings_text += f"""
POSTGRES_HOST = config("LOTUS_POSTGRES_SERVICE_HOST", default="")
POSTGRES_PORT = config("LOTUS_POSTGRES_SERVICE_PORT", default=5432, cast = int)
POSTGRES_OPTIONS = config("LOTUS_POSTGRES_OPTIONS", default="")
{line.strip()}
"""
            continue
        
        # Add SSL
        if line.startswith('POSTGRES_PASSWORD'):
            settings_text += f"""
{line.strip()}
POSTGRES_SSL_MODE = config("POSTGRES_SSL_MODE", default="disable")
"""
                            
            continue

        # Patch SelfHosted
        if line.startswith('SELF_HOSTED'):
            settings_text += """
SELF_HOSTED = config("SELF_HOSTED", default=IN_K8S, cast=bool)
"""         
            continue
        
        # Add Email Settings
        if line.startswith('if ON_HEROKU:'):
            settings_text += """
EMAIL_USE_SENDGRID = config("EMAIL_USE_SENDGRID", default=False, cast=bool)
SENDGRID_API_KEY = config("SENDGRID_API_KEY", default="")

# Email Settings
if EMAIL_USE_SENDGRID and SENDGRID_API_KEY != "":
    EMAIL_BACKEND = "anymail.backends.sendgrid.EmailBackend"
    APP_URL = "http://localhost"
    ANYMAIL['SENDGRID_API_KEY'] = SENDGRID_API_KEY
elif ON_HEROKU:
    EMAIL_BACKEND = "anymail.backends.mailgun.EmailBackend"
    APP_URL = "https://app.uselotus.io"
else:
    EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
    APP_URL = "http://localhost:8000"

APP_URL = config("APP_URL", default=APP_URL)
APP_DOMAIN = config("APP_DOMAIN", default=APP_URL.split('://', 1)[-1])
APP_SCHEME = config("APP_SCHEME", default=APP_URL.split('://', 1)[0])

EMAIL_DOMAIN = os.getenv('EMAIL_DOMAIN', os.getenv("MAILGUN_DOMAIN"))
EMAIL_USERNAME = "noreply"
EMAIL_HOST = os.getenv("EMAIL_HOST", os.getenv('MAILGUN_HOST'))
EMAIL_PORT = config('EMAIL_PORT', default=465, cast=int)
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", os.getenv('MAILGUN_SMTP_LOGIN'))
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", os.getenv('MAILGUN_SMTP_PASSWORD'))
EMAIL_USE_TLS = config("EMAIL_USE_TLS", default=True, cast=bool)
EMAIL_USE_SSL = config("EMAIL_USE_SSL", default=True, cast=bool)
EMAIL_FROM = f"{EMAIL_USERNAME}@{EMAIL_DOMAIN}"
EMAIL_SUBJECT_PREFIX = config('EMAIL_SUBJECT_PREFIX', "[Lotus] ")

DEFAULT_FROM_EMAIL = f"{EMAIL_USERNAME}@{EMAIL_DOMAIN}"
SERVER_EMAIL = f"you@{EMAIL_DOMAIN}"  # ditto (default from-email for Django errors)

"""
            skip_until = "if PROFILER_ENABLED:"
            continue
        
        # patch postgres settings
        if line.startswith('if os.environ.get("DATABASE_URL"):'):
            settings_text += """

if os.environ.get("DATABASE_URL"):
    DATABASES = {
        "default": dj_database_url.parse(
            os.environ["DATABASE_URL"],
            engine="django.db.backends.postgresql",
            conn_max_age=600,
        )
    }
    django_heroku.settings(locals(), databases=False)
elif POSTGRES_HOST:
    pg_options = {'sslmode': POSTGRES_SSL_MODE}
    if POSTGRES_OPTIONS:
        pg_options.update(dict([x.split('=') for x in POSTGRES_OPTIONS.split(',')]))
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": POSTGRES_DB,
            "USER": POSTGRES_USER,
            "PASSWORD": POSTGRES_PASSWORD,
            "HOST": POSTGRES_HOST,
            "PORT": POSTGRES_PORT,
            "OPTIONS": pg_options
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": POSTGRES_DB,
            "USER": POSTGRES_USER,
            "PASSWORD": POSTGRES_PASSWORD,
            "HOST": "db" if DOCKERIZED else "localhost",
            "PORT": 5432,
        }
    }

"""
            skip_until = "# Password validation"
            continue
        
        # Redis Caches
        if line.startswith('CELERY_TIMEZONE = "America/New_York"'):
            settings_text += """
CELERY_TIMEZONE = "America/Chicago"


if ON_HEROKU:
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": f"{REDIS_URL}/3",
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
                "REDIS_CLIENT_KWARGS": {"ssl_cert_reqs": ssl.CERT_NONE},
                "CONNECTION_POOL_KWARGS": {"ssl_cert_reqs": None},
            },
        }
    }
elif DOCKERIZED or IN_K8S:
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": f"{REDIS_URL}/3",
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
            },
        }
    }
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "unique-snowflake",
        }
    }

"""
            skip_until = "# Internationalization"
            continue

        # Patch Internal IPs
        if line.startswith('INTERNAL_IPS = ['):
            settings_text += """
INTERNAL_IPS = ["127.0.0.1"]
if IN_K8S:
    import socket
    hostname, _, ips = socket.gethostbyname_ex(socket.gethostname())
    INTERNAL_IPS += [".".join(ip.split(".")[:-1] + ["1"]) for ip in ips]
    if FRONTEND_HOST:
        INTERNAL_IPS.append(FRONTEND_HOST)
    if FRONTEND_SERVICE_HOST:
        INTERNAL_IPS.append(FRONTEND_SERVICE_HOST)

elif DOCKERIZED:
    import socket

    hostname, _, ips = socket.gethostbyname_ex(socket.gethostname())
    INTERNAL_IPS += [".".join(ip.split(".")[:-1] + ["1"]) for ip in ips]
    try:
        _, _, ips = socket.gethostbyname_ex("frontend")
        INTERNAL_IPS.extend(ips)
    except socket.gaierror:
        print(
            "tried to get frontend container ip but failed, current internal ips:",
            INTERNAL_IPS,
        )
        pass

"""
            skip_until = 'VITE_APP_DIR = BASE_DIR / "src"'
            continue
    
        # Patch CORS

        if line.startswith('DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"'):
            settings_text += """
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True
else:
    CORS_ALLOWED_ORIGIN_REGEXES = [
        r"^https://\w+\.uselotus\.io$",
        f"{APP_SCHEME}://*.{APP_DOMAIN}",
    ]

"""
            skip_until = "CORS_ALLOW_CREDENTIALS = True"
            continue

        if line.startswith('CSRF_TRUSTED_ORIGINS'):
            settings_text += """
CSRF_TRUSTED_ORIGINS = ["https://*.uselotus.io", f"{APP_SCHEME}://*.{APP_DOMAIN}"]
"""
            continue

        settings_text += line

# settings_text = settings_file.read_text()


settings_text.replace('phc_6HB6j1Hp68ESe2FpvodVwF48oisXYpot5Ymc06SbY9M', 'phc_cwylLiJu07xp9imixZ7edaiLjJYS1D1NNhe3wg4Xms0')

settings_file.write_text(settings_text)
print('Patched settings.py')