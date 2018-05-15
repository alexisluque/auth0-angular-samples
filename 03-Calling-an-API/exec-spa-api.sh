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
backends=( aspnet-core-webapi-v1_1 aspnet-core-webapi django falcor golang hapi laravel nodejs php python ruby rails java-spring-security symfony )

# Check the 'backend' arg is in backends list
exists_backend="false"
for ((i=0; i<${#backends[@]}; i++)); do
  if [ ${backends[${i}]} = $1 ]; then
    exists_backend="true"
  fi
done

if [ "$exists_backend" = "false" ]; then
  echo "Backend must be one of the following:"
  echo "aspnet-core-webapi-v1_1"
  echo "aspnet-core-webapi"
  echo "django"
  echo "falcor"
  echo "golang"
  echo "hapi"
  echo "java-spring-security"
  echo "laravel"
  echo "nodejs"
  echo "php"
  echo "python"
  echo "ruby"
  echo "rails"
  echo "symfony"
  exit 1
fi

# Get the repo name, organization and branch from Auth0 docs
curl https://raw.githubusercontent.com/auth0/docs/new-download-page/articles/quickstart/backend/$1/index.yml > temp.txt
org=$(cat temp.txt | grep org | cut -f 2 -d ':' | xargs)

repo=$(cat temp.txt | grep repo | cut -f 2 -d ':' | xargs)

branch=$(cat temp.txt | grep branch | cut -f 2 -d ':' | xargs)

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

# Github repo url
repo_url=${org}/${repo}.git#${branch}:${dir}

# Set up env variables
export REPO=${repo_url}
# Get the value from the variable AUTH0_AUDIENCE from .env file.
AUDIENCE=$(cat .env | grep AUTH0_AUDIENCE | cut -f 2 -d '=')
export AUDIENCE

# Start docker compose
docker-compose build
docker-compose up
