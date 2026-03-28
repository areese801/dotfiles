#!/bin/bash

###
### This progam accepts a model name and tells us things about that model gleaned from the manifest.json file
###

##
# Define the docmd function
##
docmd() {
  echo "Running command: [${1}]"
  echo
  eval "${1}"
}

##
# Define the echocmd function.  Good for debugging
##
echocmd() {
  echo "The command is:"
  echo
  echo "${1}"
}

##
# Handle Prerequisites:  jq
##
whichJq=$(which jq)

if [ -z ${whichJq} ]; then
  echo "Error!  This program requires 'jq' be installed, for JSON parsing.  It is not installed or not on PATH"
  echo "Installation instructions for jq can be found here:  https://stedolan.github.io/jq/download/"
  exit 1
fi

##
# Handle Variables
##
thisDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" # The dir of this program
cwdDir=$(pwd)
dbtTargetDir="${cwdDir}/target"
dbtManifestFileShortName=manifest.json
dbtManifestFile="${dbtTargetDir}/${dbtManifestFileShortName}"

# Validate that we got exactly one command line argument
argErrMsg="Error.  Exactly one argument should be passed into this program:  The name of the model (.sql file) get information about.  Try again"
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

# Echo back runtime argumenets
# echo "thisDir = ${thisDir}"
# echo "cwdDir = ${cwdDir}"
# echo "dbtTargetDir = ${dbtTargetDir}"
# echo "dbtManifestFileShortName = ${dbtManifestFileShortName}"
# echo "dbtManifestFile = ${dbtManifestFile}"
# echo ""

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
# Run dbt parse command, which generates a manifest.json file
# See:  https://docs.getdbt.com/reference/commands/parse
##

docmd "dbt parse --target prod >/dev/null 2>&1" # This causes manifest.json to be created, which dmtManifestFile should point to already

##
# Preamble
##
echo "*****************************************************************************************************************************"
echo "**                                              DBT Model Infromation Report.                                              **"
echo "*****************************************************************************************************************************"

##
# Resolve the fully qualified database table name, and fully qualified path on the OS using the 'nodes' element of manifest.json
# See:  https://docs.getdbt.com/reference/artifacts/manifest-json
##
# We'll need the project name which is part of many of the JSON paths in manifest.json
dbtProjectName=$(cat ${dbtManifestFile} | jq -r '.metadata.project_name')

nodesJqPath=".nodes | .[\"model.${dbtProjectName}.${dbtModelName}\"]" # This us gets us to the specific model beneath .nodes

# Get the materialized type
materializedType=$(cat ${dbtManifestFile} | jq -r "${nodesJqPath}" | jq -r ".config.materialized" | tr '[:lower:]' '[:upper:]')

# Database, Schema, and Table name, can be gleaned from the elements: database, schema, name
# TODO:  If using aliases in dbt config, might have to parse this differently
databaseName=$(cat ${dbtManifestFile} | jq -r "${nodesJqPath}" | jq -r ".database")
schemaName=$(cat ${dbtManifestFile} | jq -r "${nodesJqPath}" | jq -r ".schema")
tableName=$(cat ${dbtManifestFile} | jq -r "${nodesJqPath}" | jq -r ".name")
fullyQualifiedTableName=$(echo "${databaseName}.${schemaName}.${tableName}" | tr '[:lower:]' '[:upper:]')
echo
echo "Model Name : ${dbtModelName}"
echo "Materialized Type: ${materializedType}"

if [[ "${materializedType}" != "EPHEMERAL" ]]; then
  echo "Table Name : ${fullyQualifiedTableName}"
else
  echo "Table Name : Not Applicable.  Ephemeral Model"
fi

# Fully qualified path to the file can be gleaned by concatenating the cwd onto original_file_path
originalFilePath=$(cat ${dbtManifestFile} | jq -r "${nodesJqPath}" | jq -r ".original_file_path")
fullyQualifiedModelFileName="${cwdDir}/${originalFilePath}"
echo "File Name  : ${fullyQualifiedModelFileName}"

##
# Handle the parent_map element
##

parentMapJqPath=".parent_map | .[\"model.${dbtProjectName}.${dbtModelName}\"]" # This us gets us to the specific model beneath .nodes
# echo "${parentMapJqPath}"
parentModelsAndSources=$(cat ${dbtManifestFile} | jq -r "${parentMapJqPath}" | jq -r '.[]') # Gets an array of elements into individual lines.  Could also be a source
if [ -z "${parentModelsAndSources}" ]; then
  echo "${dbtModelName} has no parents."
else
  # Loop over the parent models
  echo
  echo
  echo "👨 [Immediate Parent Models for ${dbtModelName}] 👩"
  for pM in ${parentModelsAndSources}; do

    # Resolve the parent type:  model or source
    parentType="" # will either be 'model' or 'source'
    if [[ "${pM}" == "model."* ]]; then
      parentType="Model"
    elif [[ "${pM}" == "source."* ]]; then
      parentType="Source"
    elif [[ "${pM}" == "test."* ]]; then
      # TODO:  Not doing anything with tests at this point.  Just continuing.  Update this code in the future as needed
      parentType="Test"
      continue
    else
      echo "ERROR!  Could not parse the expected type ('Model' or 'Source') from the value ${pM}.  Please debug."
      exit 1
    fi

    # Resolve the fully qualified table name and file name of the immediate parent
    if [[ "${parentType}" == "Model" ]]; then
      pMShort=$(echo ${pM} | cut -d '.' -f 3) #pM looks like: "model.wp_dbt._commercial_prospects_construction"
    elif [[ "${parentType}" == "Source" ]]; then
      pMShort=$(echo ${pM} | cut -d '.' -f 4) #pM looks like: "source.wp_dbt.google_sheets.commercial_prospects_construction_20230915__commercial_prospects_construction_20230915"
    else
      echo "ERROR!  No handling defined to cut the string based on parentType (${parentType}) value.  Please debug.  String:  ${pm}."
      exit 1
    fi

    # Handling for 'Model' parentType
    if [[ "${parentType}" == "Model" ]]; then

      pmNodesJQPath=".nodes | .[\"model.${dbtProjectName}.${pMShort}\"]"
      # echo "${pmNodesJQPath}"

      pmMaterializedType=$(cat ${dbtManifestFile} | jq -r "${pmNodesJQPath}" | jq -r ".config.materialized" | tr '[:lower:]' '[:upper:]')

      # Handle the Parent Model's fully qualified table name
      pmDatabaseName=$(cat ${dbtManifestFile} | jq -r "${pmNodesJQPath}" | jq -r ".database")
      pmSchemaName=$(cat ${dbtManifestFile} | jq -r "${pmNodesJQPath}" | jq -r ".schema")
      pmTableName=$(cat ${dbtManifestFile} | jq -r "${pmNodesJQPath}" | jq -r ".name")
      pmFullyQualifiedTableName=$(echo "${pmDatabaseName}.${pmSchemaName}.${pmTableName}" | tr '[:lower:]' '[:upper:]')

      # Handle the fully qualified path to the parent model
      pmOriginalFilePath=$(cat ${dbtManifestFile} | jq -r "${pmNodesJQPath}" | jq -r ".original_file_path")
      pmFullyQualifiedModelFileName="${cwdDir}/${pmOriginalFilePath}"
    elif [[ "${parentType}" == "Source" ]]; then
      #TODO:  Implement this
      # Handling for 'Source' parentType

      pmSourcesJQPath=".sources | .[\"${pM}\"]"
      echo "pmSourcesJQPath = ${pmSourcesJQPath}"

      # Handle the Parent Model's (In reality, a source) fully qualified table name
      pmDatabaseName=$(cat ${dbtManifestFile} | jq -r "${pmSourcesJQPath}" | jq -r ".database")
      pmSchemaName=$(cat ${dbtManifestFile} | jq -r "${pmSourcesJQPath}" | jq -r ".schema")
      pmTableName=$(cat ${dbtManifestFile} | jq -r "${pmSourcesJQPath}" | jq -r ".name")
      pmFullyQualifiedTableName=$(echo "${pmDatabaseName}.${pmSchemaName}.${pmTableName}" | tr '[:lower:]' '[:upper:]')

      # Handle the fully qualified path to the parent model (in reality, a source)
      pmOriginalFilePath=$(cat ${dbtManifestFile} | jq -r "${pmSourcesJQPath}" | jq -r ".original_file_path")
      pmFullyQualifiedModelFileName="${cwdDir}/${pmOriginalFilePath}"

    else
      echo "ERROR!  No handling defined to determine the json path for parentType (${parentType}) value.  Please debug"
      exit 1
    fi

    echo
    if [[ "${parentType}" == "Model" ]]; then
      echo "Parent Type  : ${parentType}"
      echo "Model Name   : ${pMShort} "
      echo "Materialized Type: ${pmMaterializedType}"

      if [[ "${pmMaterializedType}" != "EPHEMERAL" ]]; then
        echo "Table Name   : ${pmFullyQualifiedTableName}"
      else
        echo "Table Name   : Not Applicable.  Ephemeral Model"
      fi

      echo "File Name    : $pmFullyQualifiedModelFileName"
    elif [[ "${parentType}" == "Source" ]]; then
      echo "Parent Type  : ${parentType}"
      echo "Source Name  : ${pMShort} "

      if [[ "${pmMaterializedType}" != "EPHEMERAL" ]]; then
        echo "Table Name   : ${pmFullyQualifiedTableName}"
      else
        echo "Table Name   : Not Applicable.  Ephemeral Model"
      fi

      echo "File Name    : $pmFullyQualifiedModelFileName"
    else
      echo "ERROR!  No handling defined to print information about the parentType (${parentType}) value.  Please debug"
      exit 1
    fi
  done

fi

##
# Handle the child_map element
##
echo
echo
echo "👶 [Immediate Child Models for ${dbtModelName}] 👧"

childMapJqPath=".child_map | .[\"model.${dbtProjectName}.${dbtModelName}\"]" # This gets us to the specific model beneath .nodes
# echo "${childMapJqPath}"
childModelsAndSources=$(cat ${dbtManifestFile} | jq -r "${childMapJqPath}" | jq -r '.[]') # Gets an array of elements into individual lines. Could also be a source
if [ -z "${childModelsAndSources}" ]; then
  echo
  echo "${childModelsAndSources}"
  echo "${dbtModelName} has no children or tests."
else
  # Loop over the child models

  for cM in ${childModelsAndSources}; do
    # echo "cM = ${cM}"

    # Resolve the child type: model or source
    childType="" # will either be 'model' or 'source'
    if [[ "${cM}" == "model."* ]]; then
      childType="Model"
    elif [[ "${cM}" == "source."* ]]; then
      childType="Source"
    elif [[ "${cM}" == "test."* ]]; then
      # TODO:  Not doing anything with tests at this point.  Just continuing.  Update this code in the future as needed
      childType="Test"
      continue
    else
      echo "ERROR! Could not parse the expected type ('Model' or 'Source') from the value ${cM}. Please debug."
      exit 1
    fi

    # Resolve the fully qualified table name and file name of the immediate child
    if [[ "${childType}" == "Model" ]]; then
      cMShort=$(echo ${cM} | cut -d '.' -f 3) #cM looks like: "model.wp_dbt._commercial_prospects_construction"
    elif [[ "${childType}" == "Source" ]]; then
      cMShort=$(echo ${cM} | cut -d '.' -f 4) #cM looks like: "source.wp_dbt.google_sheets.commercial_prospects_construction_20230915__commercial_prospects_construction_20230915"
    else
      echo "ERROR!  No handling defined to cut the string based on childType (${childType}) value.  Please debug.  String:  ${cm}."
      exit 1
    fi

    # Handling for 'Model' childType
    if [[ "${childType}" == "Model" ]]; then

      cmNodesJQPath=".nodes | .[\"model.${dbtProjectName}.${cMShort}\"]"
      # echo "${cmNodesJQPath}"

      cmMaterializedType=$(cat ${dbtManifestFile} | jq -r "${cmNodesJQPath}" | jq -r ".config.materialized" | tr '[:lower:]' '[:upper:]')

      # Handle the Child Model's fully qualified table name
      cmDatabaseName=$(cat ${dbtManifestFile} | jq -r "${cmNodesJQPath}" | jq -r ".database")
      cmSchemaName=$(cat ${dbtManifestFile} | jq -r "${cmNodesJQPath}" | jq -r ".schema")
      cmTableName=$(cat ${dbtManifestFile} | jq -r "${cmNodesJQPath}" | jq -r ".name")
      cmFullyQualifiedTableName=$(echo "${cmDatabaseName}.${cmSchemaName}.${cmTableName}" | tr '[:lower:]' '[:upper:]')

      # Handle the fully qualified path to the child model
      cmOriginalFilePath=$(cat ${dbtManifestFile} | jq -r "${cmNodesJQPath}" | jq -r ".original_file_path")
      cmFullyQualifiedModelFileName="${cwdDir}/${cmOriginalFilePath}"
    elif [[ "${childType}" == "Source" ]]; then
      #TODO: Implement this
      # Handling for 'Source' childType
      cmSourcesJQPath=".sources | .[\"${cM}\"]"
      echo "cmSourcesJQPath = ${cmSourcesJQPath}"

      # Handle the Child Model's (In reality, a source) fully qualified table name
      cmDatabaseName=$(cat ${dbtManifestFile} | jq -r "${cmSourcesJQPath}" | jq -r ".database")
      cmSchemaName=$(cat ${dbtManifestFile} | jq -r "${cmSourcesJQPath}" | jq -r ".schema")
      cmTableName=$(cat ${dbtManifestFile} | jq -r "${cmSourcesJQPath}" | jq -r ".name")
      cmFullyQualifiedTableName=$(echo "${cmDatabaseName}.${cmSchemaName}.${cmTableName}" | tr '[:lower:]' '[:upper:]')

      # Handle the fully qualified path to the child model (in reality, a source)
      cmOriginalFilePath=$(cat ${dbtManifestFile} | jq -r "${cmSourcesJQPath}" | jq -r ".original_file_path")
    fi

    echo
    # TODO This bit is a little silly and should be refactored.
    # For one thing, it's not very dry (nor is the equivalent for the 'Parent' block above)
    # For another, in the context of a child model, it will never be a Source, only ever an Model
    # Yet we're handling for it here.  Kind of silly but I was going fast
    if [[ "${childType}" == "Model" ]]; then
      echo "Child Type   : ${childType}"
      echo "Model Name   : ${cMShort} "
      echo "Materialized Type : ${cmMaterializedType}"

      if [[ "${cmMaterializedType}" != "EPHEMERAL" ]]; then
        echo "Table Name   : ${cmFullyQualifiedTableName}"
      else
        echo "Table Name   : Not Applicable.  Ephemeral Model"
      fi

      echo "File Name    : $cmFullyQualifiedModelFileName"
    elif [[ "${childType}" == "Source" ]]; then
      echo "Child Type   : ${childType}"
      echo "Source Name  : ${cMShort} "

      if [[ "${cmMaterializedType}" != "EPHEMERAL" ]]; then
        echo "Table Name   : ${cmFullyQualifiedTableName}"
      else
        echo "Table Name   : Not Applicable.  Ephemeral Model"
      fi

      echo "File Name    : $cmFullyQualifiedModelFileName"
    fi
  done
fi

echo
exit
