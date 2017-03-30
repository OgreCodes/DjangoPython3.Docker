# Django, MySQL, uWSGI, and NGINX Docker Environment

- [Introduction](#introduction)
- [Getting started](#basic-setup)
- [Maintenance](#managing-your-environment)
  - Run commands from outside the docker environment
  - Run the Django Shell
  - [Restart uWSGI](#restart-uwsgi-after-a-source-change)
  - Get a MySQL command prompt

# Introduction

This is a complete Django app environment with everything you need to deploy a complete Django server on Docker (everything including the kitchen sink). I created it as a fast way for myself and team-mates to set up a consistent Django environment for testing and development on our local computers. It works exceptionally well on MacOS and Linux, and can be adapted for Windows with a few minor tweaks. 

There are 2 containers to make it a little more modular. There is one container with Django, Nginx, and uWSGI managed via supervisord and a second container based on the stock MySQL container. The way this app is laid out, code and most configuration happens from outside the docker containers and so the django app and associated files can be edited live without rebuilding the docker container. You can also restart uwsgi or collect static files without a rebuild. The only configuration which does require a rebuild is actual changes to your python libraries via pip. 

## Basic Setup

This readme walks through setting up a new Django environment for a newly created Django project. If you are using an existing project, these instructions should be easy to adapt. Most of these instructions assume you have cloned this repository and paths are relative to the topmost folder in the repository. 

Start by building and running the Django container (for the moment do not start the mysql container):
    
    $ docker-compose build
    $ docker-compose up django

On first run, `docker-compose up` will throw a bunch of errors because the django project isn't set up yet. We'll do that next. To verify the container has started, use `docker ps`. 

### Create the Django Project

Next, get a command prompt inside the docker container, then start the django project.

    $ docker exec -it django /bin/bash

This puts you in the docker container in the `/code` folder which is the folder above where the django project will live. in the folder where the environment expects the project to be. Create 
the project and the first app as normal:

    # django-admin startproject projectname

### Connect uWSGI to your Project

In order for uwsgi to talk to the django project, the `uwsgi.ini` file in the django directory needs to be pointed at the project module. There are two lines which need to be edited, most likely just setting your project name will be sufficient.

    # Update this to point to your django project
    chdir           = /code/<projectname>

    # Change this to your wsgi module. Probably "projectname.wsgi".
    module          = <projectname>.wsgi:application

### Configure MySQL Server

**Note**: *This setup is geared for a MySQL Server setup, but can be used with any database by replacing the MySQL container settings in `docker-compose.yml`. For the simplest setup, comment out the mysql section in docker-compose.yml and use the default SQLLite configuration that comes with Django. In that case, there is no database setup, Django will create a SQLLite database in the code directory and you can skip to the section below on creating your first migration.*

Before bringing the database container online, the database name, user, and password need to be set in both `docker-compose.yml` and in `settings.py` for the project. Stop the django docker container, then edit `docker-compose.yml` and set the passwords to something a little more secure. Optionally, change the database name and username.

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

### Creating the Initial Django Migration

Bring the complete docker environment up:

    $ docker-compose up

Docker is still in the foreground so fire up another terminal and check to see if everything is connected properly by running the initial django migrations:

    $ docker exec -it django /bin/bash

    # cd projectname
    # python manage.py migrate

At this point, the django setup is complete and you can get started with working on your actual django code. You can stop the docker containers and run them in the background with `docker-compose up -d`.

## Managing your environment

Here are a few useful commands to help with running this setup.

### Restart uwsgi after a source change:

*You can set this as the post-save action in your editor for near instant reloads*

    docker exec django /usr/bin/supervisorctl reload uwsgi

### Run manage.py commands from outside the container

Run the Django Shell directly:

    docker exec -it django python projectname/manage.py shell

Run tests for an app:

    docker exec django /usr/bin/python projectname/manage.py test appname --keepdb

Run a migration:

    docker exec django /usr/bin/python projectname/manage.py migrate appname

#### The MySQL Prompt:

    docker exec db mysql -udjango -p django

