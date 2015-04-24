from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'vigilapi.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),
    url(r'^vigilante/api/v([\d\.]+)/version$', 'restapi.views.version'),
    url(r'^vigilante/api/v([\d\.]+)/collector/role/current/(.*)$',
        'restapi.views.collector_role_current'),
    url(r'^vigilante/api/v([\d\.]+)/collector/env/current/(.*)$',
        'restapi.views.collector_env_current'),
    url(r'^vigilante/api/v([\d\.]+)/collector/env/([\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}Z)/([\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}Z)/(.*)$',
        'restapi.views.collector_env_time'),
    url(r'^vigilante/api/v([\d\.]+)/templates/list$',
        'restapi.views.templates_list'),
    url(r'^vigilante/api/v([\d\.]+)/templates/get/(.*)$',
        'restapi.views.templates_get'),
    url(r'^vigilante/api/v([\d\.]+)/query/template/([^\/]+)/collector/role/current/(.*)$',
        'restapi.views.query_match_template'),
    url(r'^vigilante/api/v([\d\.]+)/query/template/([^\/]+)/collector/env/current/(.*)$',
        'restapi.views.query_match_env_template'),
)
