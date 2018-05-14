#!/usr/bin/env bash

# Check that .env file exists
if [ ! -f ".env" ]
then
  echo "Make sure that you have set up .env file"
  exit 1
fi

# Check the first argument in not empty
if [ "$1" =  "" ]; then
  echo "Set up the backend as the argument"
  exit 1
fi

# List of API/Backend
backends=( aspnet-core1 aspnet-core2 django falcor golang hapi laravel express php python ruby rubyonrails spring-security symfony )

# Check the 'backend' arg is in backends list
exists_backend="false"
for ((i=0; i<${#backends[@]}; i++)); do
  if [ ${backends[${i}]} = $1 ]; then
    exists_backend="true"
    echo ${backends[${i}]}
  fi
done

if [ "$exists_backend" = "false" ]; then
  echo "Backend must be one of the following:"
  echo "aspnet-core1"
  echo "aspnet-core2"
  echo "django"
  echo "falcor"
  echo "golang"
  echo "hapi"
  echo "laravel"
  echo "express"
  echo "php"
  echo "python"
  echo "ruby"
  echo "rubyonrails"
  echo "spring-security"
  echo "symfony"
  exit 1
fi

# Setup the repo for the backend
if [ $1 = aspnet-core1 ]
then
  repo=auth0-samples/auth0-aspnetcore-webapi-samples.git#v1:Quickstart/01-Authorization
elif [ $1 = aspnet-core2 ]
then
  repo=auth0-samples/auth0-aspnetcore-webapi-samples.git#master:Quickstart/01-Authorization
elif [ $1 = django ]
then
  repo=auth0-samples/auth0-django-api.git#master:01-Authorization
elif  [ $1 = falcor ]
then
  repo=auth0-community/auth0-falcor-sample.git#master:01-Authorization-RS256
elif [ $1 = golang ]
then
  repo=auth0-samples/auth0-golang-api-samples.git#master:01-Authorization-RS256
elif [ $1 = hapi ]
then
  repo=auth0-samples/auth0-hapi-api-samples.git#master:01-Authenticate-RS256
elif [ $1 = laravel ]
then
  repo=auth0-samples/auth0-laravel-api-samples.git#master:01-Authorization-RS256
elif [ $1 = express ]
then
  repo=auth0-samples/auth0-express-api-samples.git#master:01-Authorization-RS256
elif [ $1 = php ]
then
  repo=auth0-samples/auth0-php-api-samples.git#master:01-Authenticate-RS256
elif [ $1 = python ]
then
  repo=auth0-samples/auth0-python-api-samples.git#master:00-Starter-Seed
elif [ $1 = ruby ]
then
  repo=auth0-samples/auth0-ruby-api-samples.git#master:01-Authorization-RS256
elif [ $1 = rubyonrails ]
then
  repo=auth0-samples/auth0-rubyonrails-api-samples.git#master:01-Authentication-RS256
elif [ $1 = spring-security ]
then
  repo=auth0-samples/auth0-spring-security-api-sample.git#master:01-Authorization
elif [ $1 = symfony ]
then
  repo=auth0-samples/auth0-symfony-api-samples.git#master:01-Authorization-RS256
fi

# Set up env variables
export REPO=${repo}
# Get the value from the variable AUTH0_AUDIENCE from .env file.
AUDIENCE=$(cat .env | grep AUTH0_AUDIENCE | cut -f 2 -d '=')
export AUDIENCE

# Start docker compose
docker-compose build
docker-compose up
