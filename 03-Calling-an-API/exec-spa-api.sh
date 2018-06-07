#!/usr/bin/env bash

function cleanup() {
  rm -rf config
  docker-compose down
}

function create_config_dir() {
  if [ ! -d "config" ]; then
    mkdir config
  fi
}

function run_aspnet_core() {
  create_config_dir

  echo "{" > config/appsettings.json
  echo "  \"Logging\": {" >> config/appsettings.json
  echo "    \"IncludeScopes\": false," >> config/appsettings.json
  echo "    \"LogLevel\": {" >> config/appsettings.json
  echo "      \"Default\": \"Debug\"," >> config/appsettings.json
  echo "      \"System\": \"Information\"," >> config/appsettings.json
  echo "      \"Microsoft\": \"Information\"" >> config/appsettings.json
  echo "    }" >> config/appsettings.json
  echo "  }," >> config/appsettings.json
  echo "  \"Auth0\": {" >> config/appsettings.json
  echo "    \"Domain\": \"${DOMAIN}\"," >> config/appsettings.json
  echo "    \"ApiIdentifier\": \"${AUDIENCE}\"" >> config/appsettings.json
  echo "  }" >> config/appsettings.json
  echo "}" >> config/appsettings.json

  echo "{" > config/hosting.json
  echo "  \"urls\": \"http://*:3010\"" >> config/hosting.json
  echo "}" >> config/hosting.json

  if [ $1 = aspnet-core-webapi ]
  then
    cmd="dotnet run --server.urls http://0.0.0.0:3010 --project /app"
  else
    cmd="dotnet run --project /app/WebAPIApplication.csproj --server.urls http://0.0.0.0:3010"
  fi
  docker-compose run -d --service-ports web
  docker-compose run --service-ports -v ${PWD}/config:/app/config -w /app/config --entrypoint sh backend -c "${cmd}"
  cleanup
}

function run_spring_security() {
  create_config_dir

  echo "server.port=3010" > config/application.properties
  echo "spring.mvc.throw-exception-if-no-handler-found=true" >> config/application.properties
  echo "spring.resources.add-mappings=false" >> config/application.properties
  echo "logging.level.org.springframework.web=INFO" >> config/application.properties
  echo "logging.level.org.springframework.security=DEBUG" >> config/application.properties

  echo "auth0.issuer:https://${DOMAIN}/" > config/auth0.properties
  echo "auth0.apiAudience:${AUDIENCE}" >> config/auth0.properties

  cmd="mvn spring-boot:run"
  docker-compose run -d --service-ports web
  docker-compose run --service-ports --volume ${PWD}/config:/usr/src/app/src/main/resources --entrypoint sh backend -c "${cmd}"
  cleanup
}

function set_up_env_laravel() {
  echo "AUTH0_CLIENT_ID=client_id" >> .env
  echo "AUTH0_CLIENT_SECRET=secret" >> .env
  echo "AUTH0_CALLBACK_URL=callback" >> .env
}

function show_backends_list() {
  echo "Backend must be one of the following:"
  IFS=$'\n'
  printf "%s\n" "${backends[@]}"
}

# Check that .env file exists
if [ ! -f ".env" ]
then
  echo "Make sure that you have set up .env file"
  exit 1
fi

# List of API/Backend
backends=( aspnet-core-webapi-v1_1 aspnet-core-webapi django falcor golang hapi laravel nodejs php python ruby rails java-spring-security symfony )

# Check the first argument in not empty
if [ "$1" =  "" ]; then
  echo "Set up the backend as the argument"
  show_backends_list
  exit 1
fi

# Check the 'backend' arg is in backends list
exists_backend="false"
for ((i=0; i<${#backends[@]}; i++)); do
  if [ ${backends[${i}]} = $1 ]; then
    exists_backend="true"
  fi
done

if [ "$exists_backend" = "false" ]; then
  show_backends_list
  exit 1
fi

# Get the repo name, organization and branch from Auth0 docs
curl https://raw.githubusercontent.com/auth0/docs/new-download-page/articles/quickstart/backend/$1/index.yml > temp.txt
org=$(cat temp.txt | grep org | cut -f 2 -d ':' | xargs)

repo=$(cat temp.txt | grep repo | cut -f 2 -d ':' | xargs)

branch=$(cat temp.txt | grep branch | cut -f 2 -d ':' | xargs)

if [ $1 = laravel ]
then
  repo="auth0-laravel-api-samples"
fi

rm temp.txt

if [ "$branch" = "" ]
then
  branch=master
fi

# Setup the directory for the backend
if [ $1 = aspnet-core-webapi-v1_1 ] || [ $1 = aspnet-core-webapi ]
then
  dir=Quickstart/01-Authorization
elif [ $1 = django ]
then
  dir=01-Authorization
elif  [ $1 = falcor ] || [ $1 = golang ] || [ $1 = laravel ] || [ $1 = nodejs ] || [ $1 = ruby ] || [ $1 = symfony ]
then
  dir=01-Authorization-RS256
elif [ $1 = hapi ] || [ $1 = php ]
then
  dir=01-Authenticate-RS256
elif [ $1 = python ]
then
  dir=00-Starter-Seed
elif [ $1 = rails ]
then
  dir=01-Authentication-RS256
elif [ $1 = java-spring-security ]
then
  dir=01-Authorization
fi

if [ $1 = laravel ]
then
  set_up_env_laravel
fi

# Github repo url
repo_url=${org}/${repo}.git#${branch}:${dir}

# Set up env variables
export REPO=${repo_url}
# Get the value from the variable AUTH0_AUDIENCE from .env file.
AUDIENCE=$(cat .env | grep AUTH0_AUDIENCE | cut -f 2 -d '=')
export AUDIENCE
DOMAIN=$(cat .env | grep AUTH0_DOMAIN | cut -f 2 -d '=')

# Start docker compose
docker-compose build
if [ $1 = aspnet-core-webapi-v1_1 ] || [ $1 = aspnet-core-webapi ]
then
  run_aspnet_core "$1"
elif [ $1 = java-spring-security ]
then
  run_spring_security
else
  docker-compose up
  if [ $1 = laravel ]
  then
    echo "AUTH0_AUDIENCE=${AUDIENCE}" > .env
    echo "AUTH0_DOMAIN=${DOMAIN}" >> .env
  fi
fi
