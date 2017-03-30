# Django, MySQL, uWSGI, and NGINX Docker Environment

This is a kitchen sink Django app environment. It includes everything you need to set up a very basic Django server. MySQL is set up as a separate container, but django, Nginx, and uWSGI are all hosted together in a separate container which is 

### Setup

I've tried to get all the pieces in place so you can easily get going without too much hassle. 

If you want to build a new django project, it's pretty straight forward. Build the docker environment
then bring it up. using docker compose. From the projects root folder run the following:
    
    $ docker-compose build
    $ docker-compose up

The output of these commands have been omitted. On first run, `docker-compose up` will throw a bunch of 
errors because the django project isn't set up yet. We'll do that next. For the moment, open a new terminal
session and verify the two containers have started:

    $ docker ps
    CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                    NAMES
    21326497645b        balloondocker_django   "supervisord -n"         6 minutes ago       Up 5 minutes        0.0.0.0:80->80/tcp       django
    bd71ecb8b70c        mysql                  "docker-entrypoint..."   6 minutes ago       Up 6 minutes        0.0.0.0:3306->3306/tcp   db


Your output should be similar to the above with two docker containers running. Lets go into the django 
container and create the django project and your first app so we can test this is running.

    $ docker exec -it django /bin/bash