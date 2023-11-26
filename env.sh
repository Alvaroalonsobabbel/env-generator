#!/bin/bash

# HELP
# run: ./env.sh -h

# VARIABLES #
# list your variables here
variables=(
  "API_KEY"
  "DATABASE_HOST"
  "DATABASE_NAME"
  "DATABASE_USER"
  "DATABASE_PASSWORD"
)

# VAULT #
# we use three different vaults for test, development and production
# so the vault should in this case be named "cicd-test", etc. here you
# only set the name of the vault and not the environment as this is
# going to be filled out automatically depending on your selection
vault="cicd"

# ITEM #
# every credential and variable for a project must be in the same item
# inside the vault. secrets and variables will be picked up by the
# field name and those should be named exactly as the variable name
item="my-project"

createEnv() {
  if [ -f .env ]; then rm .env; fi

  touch .env
  for var in "${variables[@]}"; do
    echo "$var=op://$vault-$1/$item/$var" >>.env
  done
  echo ".env set to $1!"
}

opRun() {
  if [ -f .env ]; then
    op run --env-file="./.env" -- $1
  else
    echo ".env file doesn't exist! set the .env first."
    exit 1
  fi
}

help() {
  echo "Usage: $0 -[option] [args]"
  echo
  echo "Example:"
  echo "  $0 -t"
  echo "  $0 -r rackup app/server.rb"
  echo "  $0 -a -r terraform apply"
  echo
  echo "Setup:"
  echo "  Edit the script and change 'variables', 'vault' and 'item' according to your needs."
  echo
  echo "Options:"
  echo "  -r <command>     Runs 1Password CLI injecting the .env file into the passed command."
  echo "  -t               Set .env to Test."
  echo "  -s               Set .env to Staging."
  echo "  -p               Set .env to Production."
  echo "  -a               Adds the 'TF_VAR_' prefix to all the variables."
  echo "  -c               Deletes the .env file."
  echo "  -h               Print this Help."
  echo
}

while getopts ":tspacr:h" arg; do
  case "$arg" in
  t) # Set .env to Test
    createEnv "test"
    ;;
  s) # Set to .env Staging
    createEnv "staging"
    ;;
  p) # Set to .env Production
    createEnv "prod"
    ;;
  a) # Prefix TF_VAR_
    sed -i '' -e 's/^/TF_VAR_/' .env
    echo "prefixed "TF_VAR_" to every variable in the .env file!"
    ;;
  c) # Remove the .env file
    if [ -f .env ]; then
      rm .env
      echo ".env file has been removed!"
    else
      echo ".env file doesn't exist!"
    fi
    exit
    ;;
  r) # Run 1Password CLI using the .env file
    opRun $OPTARG
    exit
    ;;
  h) # Help
    help
    exit
    ;;
  \?) # Any option
    echo "Error: Invalid option"
    exit
    ;;
  :) # Returns an error when no mandatory argument is passed
    echo "option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
  exit
done

help
