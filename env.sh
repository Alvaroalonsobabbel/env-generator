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

# FUNCTIONS #
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

tfVAR() {
  while IFS= read -r string; do
    if [[ $string == "TF_VAR_"* ]]; then
      continue
    else
      echo "TF_VAR_$string"
    fi
  done <.env >.tmp

  if [ ! -s .tmp ]; then
    rm .tmp
    echo "TF_VAR_ is already present in every variable of the .env file"
  else
    echo "TF_VAR_ has been added to every variable in the .env file"
    mv .tmp .env
  fi
}

help() {
  echo "Usage: $0 -[option] [args]"
  echo
  echo "Example:"
  echo "  $0 -t"
  echo "  $0 -r rackup app/server.rb"
  echo "  $0 -a"
  echo "  $0 -r terraform apply"
  echo
  echo "Setup:"
  echo "  Edit the script and change 'variables', 'vault' and 'item' according to your needs."
  echo
  echo "Options:"
  echo "  -r <command>     Runs 1Password CLI injecting the .env file into the passed command."
  echo "  -t               Set .env to Test."
  echo "  -s               Set .env to Staging."
  echo "  -p               Set .env to Production."
  echo "  -a               Adds the 'TF_VAR_' prefix to all the variables in the current .env file."
  echo "  -d               Deletes the .env file."
  echo "  -h               Print this Help."
  echo
}

# MAIN LOOP #
while getopts ":tspadr:h" arg; do
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
    if [ ! -f .env ]; then
      echo ".env file doesn't exist! generate the .env file first!"
      exit 1
    fi
    tfVAR
    ;;
  d) # Remove the .env file
    if [ -f .env ]; then
      rm .env
      echo ".env file has been removed!"
    else
      echo ".env file doesn't exist!"
    fi
    exit 0
    ;;
  r) # Run 1Password CLI using the .env file
    opRun $OPTARG
    exit 0
    ;;
  h) # Help
    help
    exit 0
    ;;
  \?) # Any option
    echo "Error: Invalid option"
    exit 1
    ;;
  :) # Returns an error when no mandatory argument is passed
    echo "option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done

# runs help if no options are passed
if [ $OPTIND -eq 1 ]; then help; fi
