#!/bin/bash

# Set log commands
logTag=init
logInfo="logger -i -s -p local3.info -t ${logTag} [INFO] "
logWarn="logger -i -s -p local3.warning -t ${logTag} [WARNING] "
logErr="logger -i -s -p local3.err -t ${logTag} [ERROR] "

# Get the current timestamp and append to logfile name
TIMESTAMP=$(date "+%Y-%m-%d-%H%M")
LOGFILE=/var/log/${logTag}-${TIMESTAMP}.log

# Redirect stdout and stderr to the log file
exec >> ${LOGFILE} 2>&1

######################### GLOBAL VARIABLES #########################

# Name of the CONS3RT deployment properties file
PROPS_FILE=deployment.properties

# Full path to CONS3RT deployment properties file
DEPLOYMENT_PROPS=

# Array to maintain exit codes of commands
resultSet=();

# Ordered list of scripts to execute
assetList=( apache2-ubuntu.sh bogus-test.sh )

####################### END GLOBAL VARIABLES #######################

# Executes the passed command, adds the status to the resultSet
# array and return the exit code of the executed command
# Parameters:
# 1 - Command to execute
# Returns:
# Exit code of the command that was executed
function run_and_check_status() {
    "$@"
    local status=$?
    if [ ${status} -ne 0 ] ; then
        ${logErr} "Error executing: $@, exited with code: ${status}"
    else
        ${logInfo} "$@ executed successfully and exited with code: ${status}"
    fi
    resultSet+=("${status}")
    return ${status}
}

function main() {

    # Ensure ASSET_DIR exists, if not assume this script exists in ASSET_DIR/scripts
    if [ -z ${ASSET_DIR} ] ; then
        ${logWarn} "ASSET_DIR not found, assuming ASSET_DIR is 1 level above this script ..."
        SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        ASSET_DIR=${SCRIPT_DIR}/..
    fi

    # Ensure ASSET_DIR exists
    if [ ! -d ${ASSET_DIR} ] ; then
        ${logWarn} "ASSET_DIR isn't a directory, but it should be!"
        return 1
    else
        ${logInfo} "ASSET_DIR: ${ASSET_DIR}"
    fi
    
    # Ensure DEPLOYMENT_HOME exists
    if [ -z "${DEPLOYMENT_HOME}" ] ; then
        ${logWarn} "Can't find value for DEPLOYMENT_HOME, using default assetList: ${assetList[@]}"
    else
        ${logInfo} "DEPLOYMENT_HOME: ${DEPLOYMENT_HOME}"
        DEPLOYMENT_PROPS=${DEPLOYMENT_HOME}/${PROPS_FILE}
    fi

    # Verify the Deployment Props file exists
    if [ ! -f "${DEPLOYMENT_PROPS}" ] ; then
        ${logWarn} "DEPLOYMENT_HOME is set but file not found: ${DEPLOYMENT_PROPS}, using default assetList: ${assetList[@]}"
    else
        ${logInfo} "File found: ${DEPLOYMENT_PROPS}"
        
        # Get the local IP address to assign this host's hostname
        ${logInfo} "Getting assetList ..."
        local assetListProp=`cat ${DEPLOYMENT_PROPS} | grep -i assetList | awk -F = '{ print $2 }'`
        ${logInfo} "assetListProp: ${assetListProp}"
        
        # TODO
        ${logWarn} "Not doing anything with the assetList property yet ..."
    fi
    
    # Execute the scripts specified in the assetList
    for asset in "${assetList[@]}" ; do
        ${logInfo} "Running asset: ${asset}"
        
        if [ ! -f ${ASSET_DIR}/scripts/${asset} ] ; then
            ${logErr} "Skipping asset not found: ${ASSET_DIR}/scripts/${asset}"
            continue
        else
            ${logInfo} "Running asset: ${ASSET_DIR}/scripts/${asset}"
            chmod 755 ${ASSET_DIR}/scripts/${asset}
            run_and_check_status ${ASSET_DIR}/scripts/${asset}
        fi
    done
    
    # Check the results of commands from this script, return error if an
    # error is found
    for resultCheck in "${resultSet[@]}" ; do
        if [ ${resultCheck} -ne 0 ] ; then
            ${logErr} "Non-zero exit code found: ${resultCheck}"
            return 2
        fi
    done

    ${logInfo} "${logTag} completed successfully with no errors!"
    return 0
}

main
result=$?

${logInfo} "Exiting with code ${result} ..."
exit ${result}
