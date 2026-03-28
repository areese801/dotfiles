#!/bin/bash

###
### Runs a SQL file against Snowflake via snowsql and outputs results to stdout/file/clipboard
###
### Usage: sq.sh <sql_file> [output_format]
###
### Environment variables:
###   SNOWSQL_CONNECTION - snowsql connection name from ~/.snowsql/config (required)
###   CREDENTIALS_DIR - directory containing snowflake_key_pair/PASSPHRASE (default: /.credentials)
###

# Configuration
connectionName="${SNOWSQL_CONNECTION:?Set SNOWSQL_CONNECTION to your snowsql connection name}"
passphraseFile="${CREDENTIALS_DIR:-/.credentials}/snowflake_key_pair/PASSPHRASE"

if [[ ! -f "${passphraseFile}" ]]; then
    echo "Error: Passphrase file not found at ${passphraseFile}"
    echo "Set CREDENTIALS_DIR or create the passphrase file"
    exit 1
fi

passphrase=$(< ${passphraseFile})

# export SNOWSQL_PRIVATE_KEY_PASSPHRASE=${passphrase}  #snowsql binary will look for this env variable to work with config file
# export SNOWSQL_PWD=${passphrase}  #snowsql binary will look for this env variable to work with config file
export SNOWSQL_PRIVATE_KEY_PASSPHRASE=${passphrase}  #snowsql binary will look for this env variable to work with config file

# Remember where we were working so we can come back to it later
currDir=$(pwd)

#Handle the input file_name
    sqlFile="${1}"
    sqlFileBaseName=$(basename "${sqlFile}")

# As a courtesy, if the SQL file doesn't seem to be prefixed with a path, prefix it with the pwd in hopes of making it valid
    if [[ "${sqlFile}" = "${sqlFileBaseName}" ]]
    then
        sqlFile="${currDir}/${sqlFile}"
    fi
    echo sqlFile = "${sqlFile}"


# Confirm that the input file actually exists before moving on any further
    if [[ ! -f "${sqlFile}" ]]
        then
            echo "'${sqlFile}' is not a file!  Try again"
            return 1
        fi

#Handle output file name
    resultFileBaseName=${sqlFileBaseName%.*}.txt
    resultFile="/tmp/${resultFileBaseName}"
    # rm "/tmp/${resultFileBaseName}" >/dev/null 2>&1  # This line, while not DRY is designed to guard against a foolish value making its way into resultFile
    echo "" > "/tmp/${resultFileBaseName}"

# Handle the desired output format
# For output formats, see:  https://docs.snowflake.com/en/user-guide/snowsql-use.html#running-batch-scripts
    outputFormat="${2}"
    if [[ ! -z "${outputFormat}" ]]
        then
            outputFormatArg="-o output_format=${outputFormat}"
        else
            outputFormatArg=''
        fi


# Arg 1 is actually a file name.  We will let the DB bother with how valid the contents are or not

# Connection name corresponds with an entry in ~/.snowsql/config (See Config Section names).
# Logging wants to cooperate when we're rooted at ~/.snowsql when invoking snowsql
    cd ~/.snowsql 

# Issue the query to the DB.  Careful about trailing whitespace after \ chars below


# 2022-06-10 - The block below is served me quite well but prints a bunch of stuff to std.  Working on a special data project where i need to go as fast as possible so i've temporarily swapped it out for the block below that doesn't print to stderr
# snowsql \
# -c ${connectionName} \
# -f "${sqlFile}" \
# -o output_file="${resultFile}" \
# -o friendly=false \
# -o timing=false \
# ${outputFormatArg}

# 2023-07-21 - I can't get the sublime text build system to use snowsql without the complete path
# snowSQLtoUse=$(which snowsql)
snowSQLtoUse=/Applications/SnowSQL.app/Contents/MacOS/snowsql
# snowSQLtoUse=snowsql

# 2022-06-10 - Added this block today.  The idea is that is we didn't specify an output format, results are printed to stdout.  If we did specify a format they're suppressed but will wind up in a temp file and on the clipboard
# TODO:  Should parameterize this script to support multiple connection profiles

#. TODO:   The warehouse args were added on 2024-01-10 for a POC.  Should remove them later
if [[ ! -z "${outputFormat}" ]]
    then
    ${snowSQLtoUse} \
    -c ${connectionName} \
    -f "${sqlFile}" \
    -o output_file="${resultFile}" \
    -o friendly=false \
    -o timing=false \
    ${outputFormatArg} > /dev/null

    # Preview the results
    echo "Preview:"
    head -n 40 ${resultFile}

else
    ${snowSQLtoUse} \
    -c ${connectionName} \
    -f "${sqlFile}" \
    -o output_file="${resultFile}" \
    -o friendly=false \
    -o timing=false \
    ${outputFormatArg} 
fi


# Go back to the path we were in
cd $currDir

# Report about results
recCount=$(cat ${resultFile} | wc -l)
echo "${recCount} LINES were sent to the output file at ${resultFile}.  Depending on output format this may not match the record count completely"

# Put results on clipboard
cat ${resultFile} | pbcopy
echo "These results have been copied to the clipboard (Hint: tsv pastes nicely into spreadsheets)"


# Open in Easy CSV editor if we're dealing with a tsv file
if [[ "${outputFormatArg}" == "tsv" ]]
    then
        echo "Opened the results of ${resultFile} in Easy CSV Editor"
        # easy_csv_editor -b ${resultFile}
        easy_csv_editor ${resultFile}
fi

