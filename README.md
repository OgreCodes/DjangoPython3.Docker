# Django/ uWSGI on Python 3 Docker Environment

- [Introduction](#introduction)
  - [Assumptions](#assumptions)
  - [Structure](#structure)
- [Getting Started](#basic-setup)
  - [Create the Django Project](#create-the-django-project)
  - [uWSGI Setup](#connect-uwsgi-to-your-project)
  - [Initial Migration](#initial-migration)
  - [Static Files](#static-files)
- [Maintenance](#managing-your-environment)
  - [Using Manage.py from outside the container](#run-managepy-commands-from-outside-the-container)
  - [Restart uWSGI](#restart-uwsgi-after-a-source-change)
  
# Introduction

This is a complete Django app environment with everything you need to deploy a complete Python 3 based Django server on Docker. This is based on my original "[Kitchen Sink](https://github.com/OgreCodes/DjangoKitchenSinkDocker)" Django environment however the optional MySQL integration has been eliminated and support for GeoDjango added.

These instructions walk through all the steps required to get a complete environment up and running quickly (10-15 minutes).

The app is laid out so the container only needs to be rebuilt if requirements.txt is changed or additional software is added to the image via apt-get. Because this setup uses supervisord to manage uWSGI and NGinx, either service can be safely restarted without restarting the container. You can also collect static files without a rebuild.

Static files and media are served up by NGinx which makes this much more robust than simply using runserver. This image should be suitable for a small production django setup. 

## Assumptions

This guide is written with the assumption the reader understands the Unix command line and the basics of using docker. Familiarity with Django is also very helpful. This guide also assumes you have a functioning docker environment with at least 1 GB of free drive space.

## Structure

    requirements.txt - pip configuration for Django server
    code/ - This is where your django project will live
    nginx-sites-available/ - NGinx site configuration
    supervisor-confd/ - Startup configuration for Nginx and uWSGI
    www/ - Static files served by Nginx

## Basic Setup

This readme walks through setting up a new Django environment for a newly created Django project. If you are using an existing project, these instructions should be easy to adapt. These instructions assume there is a local clone of this repository and paths are relative to the topmost folder of the repository. 

Start by building and running the Django container:
    
    $ docker-compose build
    $ docker-compose up

On first run, `docker-compose up` may throw some errors because the django project isn't set up yet. We'll do that next. To verify the container has started, use `docker ps`. 

### Create the Django Project

Next, get a command prompt inside the docker container, and start the django project.

    $ docker exec -it django /bin/bash

This puts you in the docker container in the `/code` folder which is the folder above where the django project will live. Create the project as normal:

    # django-admin startproject projectname

### Connect uWSGI to your Project

In order for uwsgi to talk to the django project, the `uwsgi.ini` file in the django directory needs to be pointed at the project module. There are two lines which need to be edited, most likely just setting your project name will be sufficient.

    # Update this to point to your django project
    chdir           = /code/<projectname>

    # Change this to your wsgi module. Probably "projectname.wsgi".
    module          = <projectname>.wsgi:application

Once you've made these changes, hit control-C in the window where your docker container is running to stop it, then restart it with `docker-compose up`. If uWSGI starts with no obvious errors this time, you can stop the container running in the foreground and restart it in detached mode with `docker-compose up -d`.

### Initial Migration

With the the container running, open, get a command prompt inside the container and run the initial Django migrations:

    $ docker exec -it django /bin/bash

    # cd projectname
    # python manage.py migrate

### Static Files

The Nginx server is configured to serve static files, add the `STATIC_ROOT` and `STATIC_URL` settings to `settings.py` so the Django knows where to collect static files. If this server is going to support uploading files, this a good time/ place to set up `MEDIA_ROOT` and `MEDIA_URL`. Replace any existing file settings with the following:

    STATIC_ROOT = '/var/www/static/'
    STATIC_URL = '/static/'

    MEDIA_ROOT = '/var/www/media/'  # Optional to support file uploads
    MEDIA_URL = '/media/'           # Optional to support file uploads

At this point, the Django setup is complete and you can get started with working on your actual django code. 

## Managing your environment

Here are a few useful commands to help with running this setup.

### Restart uwsgi after a source change:

*You can set this as the post-save action in your editor for near instant reloads*

    docker exec django /usr/bin/supervisorctl reload uwsgi

### Run manage.py commands from outside the container

Run the Django Shell directly:

    docker exec -it django python projectname/manage.py shell

Run tests for an app:

    docker exec django python projectname/manage.py test appname --keepdb

Run a migration:

    docker exec django python projectname/manage.py migrate appname

Collect Static Files:

    docker exec django python projectname/manage.py collectstatic

