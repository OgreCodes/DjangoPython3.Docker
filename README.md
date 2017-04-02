# Django, MySQL, uWSGI, and NGINX Docker Environment

- [Introduction](#introduction)
  - [Assumptions](#assumptions)
  - [Structure](#structure)
- [Getting Started](#basic-setup)
  - [Create the Django Project](#create-the-django-project)
  - [uWSGI Setup](#connect-uwsgi-to-your-project)
  - [MySQL Server](#mysql-server) (Optional)
  - [Initial Migration](#initial-migration)
  - [Static Files](#static-files)
- [Maintenance](#managing-your-environment)
  - [Using Manage.py from outside the container](#run-managepy-commands-from-outside-the-container)
  - [Restart uWSGI](#restart-uwsgi-after-a-source-change)
  - [MySQL command prompt](#the-mysql-prompt)

# Introduction

This is a complete Django app environment with everything you need to deploy a complete Django server on Docker (everything including the kitchen sink). I created it as a fast way for myself and team-mates to set up a consistent Django environment for testing and development on our local computers. It works exceptionally well on MacOS and Linux, and can be adapted for Windows with a few minor tweaks. 

There are 2 containers to make it a little more modular. There is one container with Django, Nginx, and uWSGI managed via supervisord and a second container based on the stock MySQL container. The way this app is laid out, code and most configuration happens from outside the docker containers and so the django app and associated files can be edited live without rebuilding the docker container. You can also restart uwsgi or collect static files without a rebuild. The only configuration which does require a rebuild is actual changes to your python libraries via pip. 

## Assumptions

This guide is written with the assumption the reader understands the Unix command line and the basics of using docker. Familiarity with MySQL and Django is also very helpful. This guide also assumes you have a functioning docker environment with at least 1 GB of free drive space.

## Structure

    requirements.txt - pip configuration for Django server
    code/ - This is where your django project will live
    mysql-confd/ - Customize your MySQL Server here
    mysql-data/ - MySQL data files.      
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

### MySQL Server

**Note:** *Setting up MySQL Server is optional. If MySQL isn't required, skip to [Creating the Initial Django Migration](#creating-the-initial-migration) and Django will automatically create an SQLLite database in the topmost folder of the django project.*

To set up MySQL, stop the django container with `CTRL-C` or `docker-compose stop`; then open `docker-compose.yml` and uncomment the db settings and the links section under the django settings and set the database name, user, and password. 

    MYSQL_ROOT_PASSWORD: <New MySQL Root Password>
    MYSQL_DATABASE: django
    MYSQL_USER: django
    MYSQL_PASSWORD: <New User Password>

**Note:** *Careful when uncommenting those lines, YML is very picky about indent levels.*

Next, edit `settings.py` (likely `code/<projectname>/<projectname>/settings.py`) and paste the following in place of the existing `DATABASES` section, using the user password set above. Carry any database name or username settings forward as well: 

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

Now bring the complete docker/ MySQL environment up:

    $ docker-compose up

On first start, MySQL takes a bit longer to start because it's creating the database structure. 

### Initial Migration

Docker is still in the foreground so fire up another terminal and check to see if everything is connected properly by running the initial django migrations:

    $ docker exec -it django /bin/bash

    # cd projectname
    # python manage.py migrate

### Static Files

The Nginx server is configured to serve static files, add the STATIC_ROOT setting to `settings.py` so the Django knows where to collect static files:

    STATIC_ROOT = '/var/www/static/'

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

    docker exec django python projectname/manage.py test appname --keepdb

Run a migration:

    docker exec django python projectname/manage.py migrate appname

Collect Static Files:

    docker exec django python projectname/manage.py collectstatic

#### The MySQL Prompt:

    docker exec db mysql -udjango -p django

