#!/usr/bin/env bash

# DO NOT EDIT THIS FILE!
# Generated by fulgens (https://www.npmjs.com/package/fulgens)
# Version: 0.0.23

trap cleanup 2
set -e

#---------------------
# START - FunctionsBuilder

jdk_version() {

	# returns the JDK version.
	# 8 for 1.8.0_nn, 9 for 9-ea etc, and "no_java" for undetected
	# from https://stackoverflow.com/questions/7334754/correct-way-to-check-java-version-from-bash-script
	local result
	local java_cmd
	if [[ -n $(type -p java) ]]; then
		java_cmd=java
	elif [[ (-n "$JAVA_HOME") && (-x "$JAVA_HOME/bin/java") ]]; then
		java_cmd="$JAVA_HOME/bin/java"
	fi
	local IFS=$'\n'
	# remove \r for Cygwin
	local lines=$("$java_cmd" -Xms32M -Xmx32M -version 2>&1 | tr '\r' '\n')
	if [[ -z $java_cmd ]]; then
		result=no_java
	else
		for line in $lines; do
			if [[ (-z $result) && ($line == *"version \""*) ]]; then
				local ver=$(echo $line | sed -e 's/.*version "\(.*\)"\(.*\)/\1/; 1q')
				# on macOS, sed doesn't support '?'
				if [[ $ver == "1."* ]]; then
					result=$(echo $ver | sed -e 's/1\.\([0-9]*\)\(.*\)/\1/; 1q')
				else
					result=$(echo $ver | sed -e 's/\([0-9]*\)\(.*\)/\1/; 1q')
				fi
			fi
		done
	fi
	echo "$result"

}

# END - FunctionsBuilder
#---------------------

verbosePrint() {
	if [ "$VERBOSE" == "YES" ]; then
		echo -e "$1"
	fi
}

startDockerNetwork() {
	if [ -z "$DOCKER_NETWORKED_CHECKED" ]; then
		DOCKER_NETWORKED_CHECKED=YES
		if ! docker network ls | grep -s "vuenet"; then
			verbosePrint "Starting docker network vuenet on 10.142.45.0/24"
			docker network create -d bridge --subnet 10.142.45.0/24 --gateway 10.142.45.1 "vuenet"
		else
			verbosePrint "Docker network vuenet already running"
		fi
	fi
}

#---------------------
# START - CleanupBuilder

cleanup() {
	echo "****************************************************************"
	echo "Stopping software .....please wait...."
	echo "****************************************************************"
	set +e

	ALL_COMPONENTS=(mysql tomee)
	for componentToStop in "${ALL_COMPONENTS[@]}"; do
		IFS=',' read -r -a keepRunningArray <<<"$KEEP_RUNNING"
		componentFoundToKeepRunning=0
		for keepRunningToFindeElement in "${keepRunningArray[@]}"; do
			if [ "$componentToStop" == "$keepRunningToFindeElement" ]; then
				echo "Not stopping $componentToStop!"
				componentFoundToKeepRunning=1
			fi
		done
		if [ "$componentFoundToKeepRunning" -eq 0 ]; then

			if [ "$START_MYSQL" = "YES" ]; then
				if [ "$componentToStop" == "mysql" ]; then
					echo "Stopping $componentToStop ..."

					if [ "$TYPE_SOURCE_MYSQL" == "docker" ]; then
						docker rm -f $dockerContainerIDmysql
						rm -f .mysqlPid
					fi

				fi
			fi

			if [ "$START_TOMEE" = "YES" ]; then
				if [ "$componentToStop" == "tomee" ]; then
					echo "Stopping $componentToStop ..."

					if [ "$TYPE_SOURCE_TOMEE" == "docker" ]; then
						docker rm -f $dockerContainerIDtomee
						rm -f .tomeePid
					fi

					if [ "$TYPE_SOURCE_TOMEE" == "download" ]; then
						./localrun/apache-tomee-webprofile-$TOMEE_VERSION/bin/shutdown.sh
						rm -f .tomeePid
					fi

				fi
			fi

		fi
	done

	exit 0
}

# END - CleanupBuilder
#---------------------

#---------------------
# START - OptionsBuilder

usage="
usage: $(basename "$0") [options] [<component(s)>]

Options:
  -h                         show this help text
  -s                         skip any build
  -S                         skip consistency check against Fulgensfile
  -c [all|build]             clean local run directory, when a build is scheduled for execution it also does a full build
  -k [component]             keep comma sperarated list of components running
  -t [component:type:[path|version]] run component inside [docker] container, [download] component or [local] use installed component from path
  -v                         enable Verbose
  -j version                 macOS only: set/overwrite JAVA_HOME to a specific locally installed version, use format from/for: /usr/libexec/java_home [-V]
  -f                         tail the apache catalina log at the end
  
Url: http://localhost:8080/vue

Details for components:
client {Source:\"npm\", Default-Type:\"local\"}
  -t client:local #build local and respect -j
  -t client:docker:[TAG] #docker based build, default tag: latest, uses image https://hub.docker.com/_/node
source {Source:\"mvn\", Default-Type:\"local\"}
  -t source:local #build local and respect -j
  -t source:docker:[TAG] #docker based build, default tag: latest, uses image https://hub.docker.com/_/maven
mysql {Source:\"mysql\", Default-Type:\"docker:latest\"}
  -t mysql:local #reuse a local, running MySQL installation, does not start/stop this MySQL
  -t mysql:docker:[TAG] #start docker, default tag latest, uses image https://hub.docker.com/_/mysql
tomee {Source:\"tomee\", Default-Type:\"download:8\"}
  -t tomee:docker:[TAG] #start docker, default tag latest, uses image https://hub.docker.com/_/tomee
  -t tomee:download:[1|7|8] #start fresh downloaded tomee, default version 8 and respect -j
  -t tomee:local:TOMEE_HOME_PATH #reuse tomee installation from TOMEE_HOME_PATH, does not start/stop this tomee
"

cd "$(
	cd "$(dirname "$0")"
	pwd -P
)"
BASE_PWD=$(pwd)

BUILD=local
while getopts ':hsSc:k:x:t:vj:f' option; do
	case "$option" in
	h)
		echo "$usage"
		exit
		;;
	s) SKIP_BUILD=YES ;;
	S) SKIP_HASH_CHECK=YES ;;
	c)
		CLEAN=$OPTARG
		if [ "$CLEAN" != "all" -a "$CLEAN" != "build" ]; then
			echo "Illegal -c parameter" && exit 1
		fi
		;;
	k) KEEP_RUNNING=$OPTARG ;;
	x) SKIP_STARTING=$OPTARG ;;
	t) TYPE_SOURCE=$OPTARG ;;
	v) VERBOSE=YES ;;

	j) JAVA_VERSION=$OPTARG ;;

	f) TAIL=YES ;;

	:)
		printf "missing argument for -%s\\n" "$OPTARG" >&2
		echo "$usage" >&2
		exit 1
		;;
	\\?)
		printf "illegal option: -%s\\n" "$OPTARG" >&2
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))

if [ -z "$1" ]; then

	declare START_CLIENT=YES

	declare START_SOURCE=YES

	declare START_MYSQL=YES

	declare START_TOMEE=YES

else
	ALL_COMPONENTS=(CLIENT SOURCE MYSQL TOMEE)
	for comp in "$@"; do
		compUpper=$(echo $comp | awk '{print toupper($0)}')
		compValid=0
		for compDefined in "${ALL_COMPONENTS[@]}"; do
			if [ "$compDefined" = "$compUpper" ]; then
				compValid=1
			fi
		done
		if [ "$compValid" -eq 0 ]; then
			echo "Component $comp is invalid!"
			exit 1
		fi
		declare START_$compUpper=YES
	done
fi

# END - OptionsBuilder
#---------------------

if [ "$SKIP_HASH_CHECK" != "YES" ]; then
	if which md5 1>/dev/null; then
		declare SELF_HASH_MD5="b28a42381de2f880667a476119ad6fef"
		declare SOURCE_FILES=(Fulgensfile Fulgensfile.js)
		for SOURCE_FILE in ${SOURCE_FILES[@]}; do
			declare SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
			if [ -f "$SCRIPT_DIR/$SOURCE_FILE" ]; then
				if [ "$SELF_HASH_MD5" != "$(md5 -q $SCRIPT_DIR/$SOURCE_FILE)" ]; then
					echo "$SOURCE_FILE doesn not match!"
					exit 1
				fi
			fi
		done
	fi
fi

#---------------------
# START - DependencycheckBuilder

npm --version 1>/dev/null || exit 1
mvn --version 1>/dev/null || exit 1
docker --version 1>/dev/null || exit 1
mysql --version 1>/dev/null || exit 1
java -version 2>/dev/null || exit 1
curl --version 1>/dev/null || exit 1

# END - DependencycheckBuilder
#---------------------

# clean if requested
if [ -n "$CLEAN" ]; then
	if [ "$CLEAN" == "all" ]; then
		if [ "$VERBOSE" == "YES" ]; then echo "rm -rf localrun"; fi
		rm -rf localrun
	fi

fi

#---------------------
# START - GlobalVariablesBuilder

verbosePrint "DEFAULT: TYPE_SOURCE_CLIENT=local"
TYPE_SOURCE_CLIENT=local

verbosePrint "DEFAULT: TYPE_SOURCE_SOURCE=local"
TYPE_SOURCE_SOURCE=local

verbosePrint "DEFAULT: TYPE_SOURCE_MYSQL=docker"
TYPE_SOURCE_MYSQL=docker

verbosePrint "DEFAULT: TYPE_SOURCE_TOMEE=download"
TYPE_SOURCE_TOMEE=download

# END - GlobalVariablesBuilder
#---------------------

if [ "$(uname)" = "Linux" ]; then
	ADD_HOST_INTERNAL="--add-host host.docker.internal:$(ip -4 addr show scope global dev docker0 | grep inet | awk '{print $2}' | cut -d / -f 1)"
fi

mkdir -p localrun

f_deploy() {
	echo "No plugin defined f_deploy()"
}

#---------------------
# START - PrepareBuilder

if [ "$(uname)" == "Darwin" ]; then
	if [ -n "$JAVA_VERSION" ]; then
		export JAVA_HOME=$(/usr/libexec/java_home -v $JAVA_VERSION)
	fi
fi

# END - PrepareBuilder
#---------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NpmPlugin // client
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
verbosePrint "NpmPlugin // client"

if [ "$START_CLIENT" = "YES" ]; then

	#---------------------
	# START - Plugin-PrepareComp

	mkdir -p src/client

	OPWD="$(pwd)"
	cd "src/client"

	IFS=',' read -r -a array <<<"$TYPE_SOURCE"
	for typeSourceElement in "${array[@]}"; do
		IFS=: read comp type pathOrVersion <<<"$typeSourceElement"

		if [ "$comp" == "client" ]; then
			TYPE_SOURCE_CLIENT=$type
			if [ "$TYPE_SOURCE_CLIENT" == "local" ]; then
				TYPE_SOURCE_CLIENT_PATH=$pathOrVersion
			else
				TYPE_SOURCE_CLIENT_VERSION=$pathOrVersion
			fi
		fi

	done

	if [ "$TYPE_SOURCE_CLIENT" == "docker" ]; then
		if [ -z "$TYPE_SOURCE_CLIENT_VERSION" ]; then
			TYPE_SOURCE_CLIENT_VERSION=latest
		fi

	fi

	verbosePrint "TYPE_SOURCE_CLIENT = $TYPE_SOURCE_CLIENT // TYPE_SOURCE_CLIENT_PATH = $TYPE_SOURCE_CLIENT_PATH // TYPE_SOURCE_CLIENT_VERSION = $TYPE_SOURCE_CLIENT_VERSION"

	# END - Plugin-PrepareComp
	#---------------------

	if [ "$TYPE_SOURCE_CLIENT" == "local" ]; then
		f_build() {
			verbosePrint "pwd=$(pwd)\nnpm run build"

			npm i
			npm run build

		}
	fi

	if [ "$TYPE_SOURCE_CLIENT" == "docker" ]; then

		dockerImage=node

		f_build() {
			verbosePrint "pwd=$(pwd)\ndocker run --name=client --rm -v $(pwd):/usr/src/build -w /usr/src/build $dockerImage:$TYPE_SOURCE_CLIENT_VERSION npm run build"

			docker run --name=client --rm -v "$(pwd)":/usr/src/build -w /usr/src/build $dockerImage:$TYPE_SOURCE_CLIENT_VERSION npm i && npm run build

		}
	fi

	if [ "$SKIP_BUILD" != "YES" ]; then
		f_build
	else
		verbosePrint "npm build skipped."
	fi

	#---------------------
	# START - Plugin-LeaveComp

	cd "$OPWD"

# END - Plugin-LeaveComp
#---------------------

fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MvnPlugin // source
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
verbosePrint "MvnPlugin // source"

if [ "$START_SOURCE" = "YES" ]; then

	#---------------------
	# START - Plugin-PrepareComp

	IFS=',' read -r -a array <<<"$TYPE_SOURCE"
	for typeSourceElement in "${array[@]}"; do
		IFS=: read comp type pathOrVersion <<<"$typeSourceElement"

		if [ "$comp" == "source" ]; then
			TYPE_SOURCE_SOURCE=$type
			if [ "$TYPE_SOURCE_SOURCE" == "local" ]; then
				TYPE_SOURCE_SOURCE_PATH=$pathOrVersion
			else
				TYPE_SOURCE_SOURCE_VERSION=$pathOrVersion
			fi
		fi

	done

	if [ "$TYPE_SOURCE_SOURCE" == "docker" ]; then
		if [ -z "$TYPE_SOURCE_SOURCE_VERSION" ]; then
			TYPE_SOURCE_SOURCE_VERSION=latest
		fi

	fi

	verbosePrint "TYPE_SOURCE_SOURCE = $TYPE_SOURCE_SOURCE // TYPE_SOURCE_SOURCE_PATH = $TYPE_SOURCE_SOURCE_PATH // TYPE_SOURCE_SOURCE_VERSION = $TYPE_SOURCE_SOURCE_VERSION"

	# END - Plugin-PrepareComp
	#---------------------

	if [ "$TYPE_SOURCE_SOURCE" == "local" ]; then
		f_build() {
			verbosePrint "pwd=$(pwd)\nmvn $MVN_CLEAN $MVN_OPTS package"

			mvn $MVN_CLEAN $MVN_OPTS package

		}
	fi

	if [ "$TYPE_SOURCE_SOURCE" == "docker" ]; then

		dockerImage=maven

		f_build() {
			verbosePrint "pwd=$(pwd)\ndocker run --name=source --rm -v $(pwd):/usr/src/build -v "$(pwd)/localrun/.m2":/root/.m2 -w /usr/src/build $dockerImage:$TYPE_SOURCE_SOURCE_VERSION mvn $MVN_CLEAN $MVN_OPTS package"

			docker run --name=source --rm -v "$(pwd)":/usr/src/build -v "$(pwd)/localrun/.m2":/root/.m2 -w /usr/src/build $dockerImage:$TYPE_SOURCE_SOURCE_VERSION mvn $MVN_CLEAN $MVN_OPTS package

		}
	fi

	if [ "$SKIP_BUILD" != "YES" ]; then
		if [ -n "$CLEAN" ]; then
			MVN_CLEAN=clean
		fi
		f_build
	else
		verbosePrint "Mvn build skipped."
	fi

fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MysqlPlugin // mysql
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
verbosePrint "MysqlPlugin // mysql"

if [ "$START_MYSQL" = "YES" ]; then

	#---------------------
	# START - Plugin-PrepareComp

	IFS=',' read -r -a array <<<"$TYPE_SOURCE"
	for typeSourceElement in "${array[@]}"; do
		IFS=: read comp type pathOrVersion <<<"$typeSourceElement"

		if [ "$comp" == "mysql" ]; then
			TYPE_SOURCE_MYSQL=$type
			if [ "$TYPE_SOURCE_MYSQL" == "local" ]; then
				TYPE_SOURCE_MYSQL_PATH=$pathOrVersion
			else
				TYPE_SOURCE_MYSQL_VERSION=$pathOrVersion
			fi
		fi

	done

	if [ "$TYPE_SOURCE_MYSQL" == "docker" ]; then
		if [ -z "$TYPE_SOURCE_MYSQL_VERSION" ]; then
			TYPE_SOURCE_MYSQL_VERSION=latest
		fi

	fi

	verbosePrint "TYPE_SOURCE_MYSQL = $TYPE_SOURCE_MYSQL // TYPE_SOURCE_MYSQL_PATH = $TYPE_SOURCE_MYSQL_PATH // TYPE_SOURCE_MYSQL_VERSION = $TYPE_SOURCE_MYSQL_VERSION"

	# END - Plugin-PrepareComp
	#---------------------

	if [ "$TYPE_SOURCE_MYSQL" == "docker" ]; then
		# run in docker
		if [ ! -f ".mysqlPid" ]; then
			startDockerNetwork

			verbosePrint "docker run --rm -d -p 3306:3306  -e MYSQL_ALLOW_EMPTY_PASSWORD=true   --net=vuenet --name=mysql   mysql:$TYPE_SOURCE_MYSQL_VERSION"
			dockerContainerIDmysql=$(docker run --rm -d -p 3306:3306 \
				-e MYSQL_ALLOW_EMPTY_PASSWORD=true \
				--net=vuenet \
				--name=mysql $ADD_HOST_INTERNAL \
				mysql:$TYPE_SOURCE_MYSQL_VERSION
			)
			echo "$dockerContainerIDmysql" >.mysqlPid
		else
			dockerContainerIDmysql=$(<.mysqlPid)
			echo "Reusing already running instance $dockerContainerIDmysql"
		fi
	fi
	if [ "$TYPE_SOURCE_MYSQL" == "local" ]; then
		if [ -f ".mysqlPid" ]; then
			echo "mysql running but started from different source type"
			exit 1
		fi
	fi

	while ! mysql -uroot --protocol=tcp -e "select 1" 1>/dev/null 2>&1; do
		echo "waiting for mysql..."
		sleep 3
	done

	mysql -uroot --protocol=tcp -NB -e "create database if not exists vue"

	mysql -uroot --protocol=tcp vue <src/db/init-ddl.sql

	mysql -uroot --protocol=tcp vue <src/db/init-data.sql

fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TomeePlugin // tomee
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
verbosePrint "TomeePlugin // tomee"

if [ "$START_TOMEE" = "YES" ]; then

	#---------------------
	# START - Plugin-PrepareComp

	IFS=',' read -r -a array <<<"$TYPE_SOURCE"
	for typeSourceElement in "${array[@]}"; do
		IFS=: read comp type pathOrVersion <<<"$typeSourceElement"

		if [ "$comp" == "tomee" ]; then
			TYPE_SOURCE_TOMEE=$type
			if [ "$TYPE_SOURCE_TOMEE" == "local" ]; then
				TYPE_SOURCE_TOMEE_PATH=$pathOrVersion
			else
				TYPE_SOURCE_TOMEE_VERSION=$pathOrVersion
			fi
		fi

	done

	if [ "$TYPE_SOURCE_TOMEE" == "docker" ]; then
		if [ -z "$TYPE_SOURCE_TOMEE_VERSION" ]; then
			TYPE_SOURCE_TOMEE_VERSION=latest
		fi

	fi

	if [ "$TYPE_SOURCE_TOMEE" == "download" ]; then
		if [ -z "$TYPE_SOURCE_TOMEE_VERSION" ]; then
			TYPE_SOURCE_TOMEE_VERSION=8
		fi
		# find latest tomee version for $TYPE_SOURCE_TOMEE_VERSION
		TOMEE_BASE_URL="https://www-eu.apache.org/dist/tomee"
		if [ "$TYPE_SOURCE_TOMEE_VERSION" == "1" ]; then
			TOMEE_VERSION="1.7.5"
		elif [ "$TYPE_SOURCE_TOMEE_VERSION" == "7" ]; then
			TOMEE_VERSION="7.1.0"
		elif [ "$TYPE_SOURCE_TOMEE_VERSION" == "8" ]; then
			TOMEE_VERSION="8.0.0-M2"
		else
			echo "Illegal Tomee version: $TYPE_SOURCE_TOMEE_VERSION"
			exit 1
		fi
		TOMEE_URL=$TOMEE_BASE_URL/tomee-$TOMEE_VERSION/apache-tomee-$TOMEE_VERSION-webprofile.tar.gz
	fi

	verbosePrint "TYPE_SOURCE_TOMEE = $TYPE_SOURCE_TOMEE // TYPE_SOURCE_TOMEE_PATH = $TYPE_SOURCE_TOMEE_PATH // TYPE_SOURCE_TOMEE_VERSION = $TYPE_SOURCE_TOMEE_VERSION"

	# END - Plugin-PrepareComp
	#---------------------

	if [ "$TYPE_SOURCE_TOMEE" == "download" ]; then
		if [ -f ".tomeePid" ] && [ "$(<.tomeePid)" != "download" ]; then
			echo "Tomee running but started from different source type"
			exit 1
		fi
		# download tomee
		if [ ! -f "/${TMPDIR:-/tmp}/apache-tomee-$TOMEE_VERSION.tar" ]; then
			curl -s $TOMEE_URL | gzip -d >/${TMPDIR:-/tmp}/apache-tomee-$TOMEE_VERSION.tar
		fi
		# extract tomee
		if [ ! -d "./apache-tomee-$TOMEE_VERSION" ]; then
			tar -xf /${TMPDIR:-/tmp}/apache-tomee-$TOMEE_VERSION.tar -C ./localrun
		fi
	fi

	dockerAddLibRefs=()
	if [ "$TYPE_SOURCE_TOMEE" == "docker" ]; then

		mkdir -p localrun/webapps
		targetPath=localrun/webapps/
	fi

	if [ "$TYPE_SOURCE_TOMEE" == "download" ]; then

		targetPath=localrun/apache-tomee-webprofile-$TOMEE_VERSION/webapps/
	fi

	if [ "$TYPE_SOURCE_TOMEE" == "local" ]; then
		targetPath=$TYPE_SOURCE_TOMEE_PATH/webapps/
	fi

	f_deploy() {
		cp target/vue.war $targetPath
	}
	f_deploy

	if [ "$TYPE_SOURCE_TOMEE" == "download" ]; then
		if [ ! -f ".tomeePid" ]; then

			export JAVA_OPTS="$JAVA_OPTS "
			./localrun/apache-tomee-webprofile-$TOMEE_VERSION/bin/startup.sh
			echo "download" >.tomeePid
		else
			echo "Reusing already running instance"
		fi
		tailCmd="tail -f ./localrun/apache-tomee-webprofile-$TOMEE_VERSION/logs/catalina.out"
	fi

	if [ "$TYPE_SOURCE_TOMEE" == "docker" ]; then
		if [ -f ".tomeePid" ] && [ "$(<.tomeePid)" == "download" ]; then
			echo "Tomee running but started from different source type"
			exit 1
		fi
		if [ ! -f ".tomeePid" ]; then
			startDockerNetwork

			if [ "$TYPE_SOURCE_MYSQL" == "docker" ]; then
				REPLVAR_TOMEE_MYSQL="mysql"
			elif [ "$TYPE_SOURCE_MYSQL" == "local" ]; then
				REPLVAR_TOMEE_MYSQL="host.docker.internal"
			fi

			verbosePrint "docker run --rm -d ${dockerAddLibRefs[@]} -p 8080:8080  --net=vuenet --name=tomee $ADD_HOST_INTERNAL  -e JAVA_OPTS="-Djdbc/facesdatabase.JdbcUrl=jdbc:mysql://$REPLVAR_TOMEE_MYSQL/vue?useSSL=false" -v "$(pwd)/localrun/webapps":/usr/local/tomee/webapps tomee:$TYPE_SOURCE_TOMEE_VERSION"
			dockerContainerIDtomee=$(docker run --rm -d ${dockerAddLibRefs[@]} -p 8080:8080 \
				--net=vuenet \
				--name=tomee $ADD_HOST_INTERNAL \
				-e JAVA_OPTS="-Djdbc/facesdatabase.JdbcUrl=jdbc:mysql://$REPLVAR_TOMEE_MYSQL/vue?useSSL=false" \
				-v "$(pwd)/localrun/webapps":/usr/local/tomee/webapps tomee:$TYPE_SOURCE_TOMEE_VERSION)
			echo "$dockerContainerIDtomee" >.tomeePid
		else
			dockerContainerIDtomee=$(<.tomeePid)
			echo "Reusing already running instance $dockerContainerIDtomee"
		fi
		tailCmd="docker logs -f $dockerContainerIDtomee"
	fi

	if [ "$TYPE_SOURCE_TOMEE" == "local" ]; then
		if [ -f ".tomeePid" ]; then
			echo "Tomee running but started from different source type"
			exit 1
		fi
		tailCmd="tail -f $TYPE_SOURCE_TOMEE_PATH/logs/catalina.out"
	fi

fi

#---------------------
# START - WaitBuilder

# waiting for ctrl-c
echo "*************************************************************"
echo "**** SCRIPT COMPLETED, STARTUP IN PROGRESS ******************"
if [ "$TAIL" == "YES" ]; then
	echo "http://localhost:8080/vue"
	echo "**** now tailing log: $tailCmd"
	$tailCmd
else
	echo "http://localhost:8080/vue"
	echo "$tailCmd"
	echo "<return> to rebuild, ctrl-c to stop mysql, tomee"
	while true; do
		read </dev/tty
		f_build
		f_deploy
	done
fi

# END - WaitBuilder
#---------------------

