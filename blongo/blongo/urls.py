from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'blongo.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', 'blogapp.views.index'),
    url(r'^update/', 'blogapp.views.update'),
    url(r'^comments/update/', 'blogapp.views.comment_update'),
    url(r'^delete/', 'blogapp.views.delete'),
)
