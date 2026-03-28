#!/bin/bash

###
### This script accepts just a single argument - the name of a dbt model
### and goes on to compile that model and makes a symlink to the compiled code
### which is useful for development purposes
###

##
# Define the docmd function
##
  docmd () {
     echo "Running command: [${1}]"
      echo
      eval "${1}"
      }

##
# Define the echocmd function.  Good for debugging
##
  echocmd () {
    echo "The command is:"
    echo
    echo "${1}"
      }

##
# Handle Variables
## 
    thisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )" # The dir of this program
    cwdDir=$(pwd)

##
# Validations
##
    
    # Validate that we got exactly one command line argument
    argErrMsg="Error.  Exactly one argument should be passed into this program:  The name of the model (.sql file) to compile and symlink.  Try again"
    if [ $# -ne 1 ]; then
      echo "${argErrMsg} Got $#"
      exit 1
    fi


    # Be reasonably sure that we're at the root of the DBT project
    soughtDir="${cwdDir}/models"
    # echo "Looking for evidence that '${cwdDir}' is a DBT dir.  Does ${soughtDir} exist?"
    if [ ! -d "${soughtDir}" ]; then
        echo "Current Directory Doesn't Seem to be a DBT project root.  Please try again."
        exit 1
    fi

##
# Handle Input (model name)
##
    dbtModelName="${1}"

    # Drop .sql ext as needed
    if [[ $dbtModelName == *.sql ]]; then
        dbtModelName=${dbtModelName%.sql}
        echo "Removed .sql extension from model.  New value: ${dbtModelName}"
    fi

    dbtModelNamewithSqlExtension="${dbtModelName}.sql"

##
# Compile the model
## 

    # Compile the model
    cmd="dbt compile --select ${dbtModelName} --target prod"
    docmd "${cmd}"

    # Exit if compilation failed
    if [ $? -ne 0 ]; then
        echo "Compilation command against model '${dbtModelName}' failed.  Does it exist?"
        exit 1
    fi

    # Locate the model and symlink to it.  
    # Here, we're relying on the fact that despite a given model's path, any given model
    # (e.g.  "foo.sql"), can only exist in one place anywhere within the project
    # under the /models dir.  This pattern does not account for aliases in DBT configuration
    # but should still be just fine
    compiledModelsBaseDir="${cwdDir}/target/compiled"
    # cmd="find ${compiledModelsBaseDir} -type f -name '${dbtModelNamewithSqlExtension}' | head -n 1"
    dbtModelFullyQualifiedFileName=$(find ${compiledModelsBaseDir} -type f -name "${dbtModelNamewithSqlExtension}" | head -n 1)
    # echocmd "find ${compiledModelsBaseDir} -type f -name '${dbtModelNamewithSqlExtension}' | head -n 1"
    echo "Compiled Model Path:  ${dbtModelFullyQualifiedFileName}"

##
# Symlink the model
##

    # Fail if last step didn't find the model
    if [[ -z "${dbtModelFullyQualifiedFileName}" ]]; then
        echo "" && echo "Failed to resolve DBT Model fully Qualified File name for input [${dbtModelName}].  Does this model exist?"
        exit 1
    fi
    symLinkFileName="${cwdDir}/WIP_${dbtModelNamewithSqlExtension}"
    cmd="ln -sf ${dbtModelFullyQualifiedFileName} ${symLinkFileName}"
    docmd "${cmd}"


##
# Show dir contents
##
    echo "DONE!  The model was compiled and symlink'd:  ${dbtModelNamewithSqlExtension}"
    ls -lahG 


##
# Best Effort to open this file in Datagrip.  
# This section assumes you've got all the proper stuff set up right
## 
    cmd="datagrip ${symLinkFileName}"
    docmd "${cmd}"
