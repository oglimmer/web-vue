
# Web-Application

# VUE

* Depends on JEE API 8.0.1
* Runs on JEE Server

* JPA as ORM (using DataSource)
* 
* Nothing generic, uses Beans to transfer data
* DataSource defined in web.xml

# DEV SETUP

## start a database

To start a Mysql database inside Docker use `./run_local.sh mysql`

## server / java

Either import the project into an IDE and start it there or just use `./run_local.sh -f source tomee` to compile and start the java RESTful API inside a TomEE.

### Eclipse

You might need to add `-javaagent:$TOMEE_HOME/lib/openejb-javaagent.jar`, also disable `suspend execution on uncaught exceptions`

## client / vue

Use

```
cd src/client
npm i
./node_modules/.bin/vue-cli-service serve --port 8081
```

to dev start a web server. Then go to `http://localhost:8081/`
