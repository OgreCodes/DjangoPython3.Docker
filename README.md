# Django, MySQL, uWSGI, and NGINX Docker Environment

This is a kitchen sink Django app environment. It includes everything you need to set up a very basic Django server. I created it as a fast way for myself and team-mates to set up a consistent Django environment for testing and development on our local computers. It works exceptionally well on MacOS and Linux, and can be adapted for Windows with a few minor issues. As presented, this is intended as a testing and development setup

This setup has 2 separate docker containers to make it a little more modular. There is one container with Django, Nginx, and uWSGI managed via supervisord and a second container based on the stock MySQL container. The way this app is laid out, code and most configuration happens from outside the docker containers and so the django app and associated files can be edited live without rebuilding the docker container. You can also restart uwsgi or collect static files without a rebuild. The only configuration which does require a rebuild is actual changes to your python libraries via pip. 

### Basic Setup

If you want to build a new django project, it's pretty straight forward. From the project's root folder run the following (For the moment we're not starting the mysql container):
    
    $ docker-compose build
    $ docker-compose up django

The output of these commands have been omitted. On first run, `docker-compose up` will throw a bunch of 
errors because the django project isn't set up yet. We'll do that next. For the moment, open a new terminal
session and verify the container has started:

    $ docker ps

    CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                    NAMES
    21326497645b        docker_django   "supervisord -n"         6 minutes ago       Up 5 minutes        0.0.0.0:80->80/tcp       django


Your output should be similar to the above with two docker containers running. Lets go into the django 
container and create the django project.

    $ docker exec -it django /bin/bash

This puts you in the docker container, in the folder where the environment expects the project to be. Create 
the project and the first app as normal:

    # django-admin startproject projectname

Before bringing the database container online, set the database name, user, and password. Stop the django docker container, then edit `docker-compose.yml` and set the passwords to something a little more secure than the existing. Optionally, change the database name and username.

    MYSQL_ROOT_PASSWORD: <New MySQL Root Password>
    MYSQL_DATABASE: django
    MYSQL_USER: django
    MYSQL_PASSWORD: <New User Password>

Next, edit `settings.py` (likely `django/<projectname>/<projectname>/settings.py`) and paste the following in place of the existing `DATABASES` section, using the user password you set above. If you changed the database name or username, make sure you carry those changes forward as well: 

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.mysql',
            'NAME': 'django',
            'USER': 'django',
            'PASSWORD': '<New User Password>',
            'HOST': 'db',
            'PORT': '',
        }
    }

Now we can bring our whole environment up:

    $ docker-compose up

Docker is still in the foreground so fire up another terminal and lets check to see if everything is connected properly by running our initial django migrations:

    $ docker exec -it django /bin/bash

    # cd projectname
    # python manage.py migrate

At this point, you can create an app and use your django environment as normal. You can stop the docker containers and run them in the background with `docker-compose up -d`.

### Managing your environment

Here are a few useful commands to help with running this setup.

#### Restart uwsgi after a source change (I have pycharm run this after edits):

    docker exec django /usr/bin/supervisorctl reload uwsgi

#### Run manage.py commands from outside the container

Run the Django Shell directly:

    docker exec -it django python projectname/manage.py shell


Run tests for an app:

    docker exec django /usr/bin/python projectname/manage.py test appname --keepdb

Run a migration app:

    docker exec django /usr/bin/python projectname/manage.py migrate appname

