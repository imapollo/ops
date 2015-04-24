# Viligante REST API

## Live environment on srwd00dvo002:3000

1. Checked out stable release of dashboard into `/nas/reg/devops-vigilante`.
2. `ln -s /nas/reg/devops-vigilante/vigilante/vigilapi /opt/vigilante`
3. `ln -s /nas/reg/devops-vigilante/vigilante/vigilapi/conf/devops-vigilante-vhost.conf /etc/httpd/conf.d/vhosts.d/devops-vigilante-vhost.conf`
4. `mkdir /var/log/vigilante/`
5. `cp /opt/vigilante/vigilapi/__init__.py.sample /opt/vigilante/vigilapi/__init__.py`
6. Edit `/opt/vigilante/vigilapi/__init__.py`
7. `cp /nas/utl/devops/github/devops-vigilante/vigilante/vigillib/settings.py.sample /nas/utl/devops/github/devops-vigilante/vigilante/vigillib/settings.py`
8. Edit `/nas/utl/devops/github/devops-vigilante/vigilante/vigillib/settings.py`
9. Add line `Include conf.d/vhosts.d/*.conf` into /etc/httpd/conf/httpd.conf
9. `service httpd restart`
10. Try to access http://devops.stubcorp.dev:3000/vigilante/api/v0.1/version

## Test environment on srwd00dvo002

1. Checked out vigilante develop branch into `${workspace}`.
2. `cd ${workspace}`
3. `nohup python manage.py runserver 0.0.0.0:${TCP_PORT} &`
4. Try to access srwd00dvo002.stubcorp.dev:${TCP_PORT}.

## Dependencies on server

1. Python (2.6+).
2. Django==1.5.8.
3. `pip install pyyaml`
4. `pip install pymongo`
5. Install apache mod_wsgi module.
6. Insert this line to `/etc/bashrc` `export LD_LIBRARY_PATH=/usr/local/lib`

## Setup Live / Test Mongo DB for Facts

1. Follow manual on http://docs.mongodb.org/manual/tutorial/install-mongodb-on-red-hat/#install-mongodb to install mongod.
2. Restore facts schema `mongorestore /nas/home/minjzhang/dump`
