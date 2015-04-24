import os
import sys

sys.path.append('/opt/vigilante')
os.environ['DJANGO_SETTINGS_MODULE'] = 'vigilapi.settings'

import django.core.handlers.wsgi
application = django.core.handlers.wsgi.WSGIHandler()
