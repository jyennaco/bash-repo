#!/bin/bash

# Set log commands
logTag=apache2
logInfo="logger -i -s -p local3.info -t ${logTag} [INFO] "
logWarn="logger -i -s -p local3.warning -t ${logTag} [WARNING] "
logErr="logger -i -s -p local3.err -t ${logTag} [ERROR] "

# Get the current timestamp and append to logfile name
TIMESTAMP=$(date "+%Y-%m-%d-%H%M")
LOGFILE=/var/log/${logTag}-${TIMESTAMP}.log

# Redirect stdout and stderr to the log file
exec >> ${LOGFILE} 2>&1

######################### GLOBAL VARIABLES #########################

# Array to maintain exit codes of commands
resultSet=();

####################### END GLOBAL VARIABLES #######################

# Executes the passed command, adds the status to the resultSet
# array and return the exit code of the executed command
# Parameters:
# 1 - Command to execute
# Returns:
# Exit code of the command that was executed
function run() {
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

    ${logInfo} "Installing Apache2 ..."

    run apt-get -y install apache2

    # Check the results of commands from this script, return error if an
    # error is found
    for resultCheck in "${resultSet[@]}" ; do
        if [ ${resultCheck} -ne 0 ] ; then
            ${logErr} "Non-zero exit code found: ${resultCheck}"
            return 1
        fi
    done

    ${logInfo} "${logTag} completed successfully with no errors!"
    return 0
}

main
result=$?

${logInfo} "Exiting with code ${result} ..."
exit ${result}