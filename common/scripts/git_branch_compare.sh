#!/bin/bash

###
### This program will launch a comparison session in beyond compare between two branches of a given git repository
### There are probably some fancy ways to do this with Git, but I haven't found a technique that I like as much as 
### what this script actually does
###

### Usage:
# 	bash git_branch_compare.sh <path to project> <name of branch A> <name of branch B>

set -e # Stop this program on any failure

## Define the showHelp() function
	showHelp(){
		echo
		echo "You called the program with the help parameter. Or you called it incorrectly.  Help is below."
		echo "This script accepts exactly 3 parameters:"
		echo "	1) A path to an directory which has been initialized as a git repository"
		echo "	2) The name of the git branch (Branch A), which we'd like to compare to another git branch (Branch B)"
		echo "	3) The name of the git branch (Branch B), which we'd like to compare to the first git branch (Branch A)"
		echo 
		echo "Example usage:"
		echo "	. git_branch_compare.sh /path/to/local/repository/ main new_feature"

	}

## Define the docmd function
	docmd () {
		echo "Running command: [${1}]" 
		eval "${1}"
	}

## Define the echocmd function.  Good for debugging
	echocmd () {
		echo "The command is: ${1}" 
		echo
	}

###
### Show help then exit if the user calls the program like this:  'make_env.sh help' or something equally obvious
###
	if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]
		then
		showHelp && return 1
	fi

###
### Handle path-related arguments
###
	thisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
	tmpDir=${TMPDIR} # On my mac this isn't /tmp but some other weird thing like /var/folders/0t/_g587p3j6zq936zgvxlkfhlc0000gn/T/
	tmpWorkingDir="${tmpDir}/git_branch_compare_working_area"

###
### Parse Arguments passed into this program
###	

	###
	# Handle path to the repository
	###

		# Get the path to the repository from Arg 1
			if [[ ! -z "${1}" ]]
				then
					repositoryDir="${1}"
				else
					echo "ERROR!  There was no repository path passed into the program!"
					showHelp && return 1
				fi

		# Make sure the target directory actually exists
			if [[ ! -d "${repositoryDir}" ]]
				then
					echo "ERROR!  The specified repository path [${repositoryDir}] does not exist!"
					return 1
				else
					# Expand the value, for good measure
					repositoryDir=$(cd "${repositoryDir}" && pwd -P)
			fi

		# Ensure that it's actually a git repository
			isGitRepoTest=$(cd "${repositoryDir}" && git status > /dev/null 2>&1 && echo $?) # We'll get 0 here if it's a git repo

			if [[ ! "${isGitRepoTest}" = "0" ]]
				then
					echo "ERROR!  The specified repository path [${repositoryDir}] exists on disk but it IS NOT A GIT REPOSITORY!"
					return 1
			fi

	###
	# Handle branch name A (Arg 2)
	###

		# Ensure that argument 2 was passed
			if [[ ! -z "${2}" ]]
			then
				branchNameA="${2}"
			else
				echo "ERROR!  There was no branch name passed into this program in Argument 2"
				return 1
			fi

	###
	# Handle branch name B (Arg 3)
	###

		# Ensure that argument 2 was passed
			if [[ ! -z "${3}" ]]
			then
				branchNameB="${3}"
			else
				echo "ERROR!  There was no branch name passed into this program in Argument 3"
				return 1
			fi

	###
	# Ensure that both branches A and B are valid branch names
	###
		branchExistsTestA=$(cd "${repositoryDir}" && git branch --list "${branchNameA}") # Returns null string if branch not exists
		branchExistsTestB=$(cd "${repositoryDir}" && git branch --list "${branchNameB}") # Returns null string if branch not exists

		if [[ -z "${branchExistsTestA}" ]] || [[ -z "${branchExistsTestB}" ]]
			then
				echo "ERROR!  One or both of the supplied branch names [${branchNameA}] or [${branchNameB}] does not actually exist within the repository [${repositoryDir}]."
				return 1
		fi

		tmpWorkingDirBranchA="${tmpWorkingDir}/${branchNameA}"
		tmpWorkingDirBranchB="${tmpWorkingDir}/${branchNameB}"

###
### Echo back runtime variables
###
	echo "thisDir = ${thisDir}"
	echo "tmpDir = ${tmpDir}"
	echo "tmpWorkingDir = ${tmpWorkingDir}"
	echo "repositoryDir = ${repositoryDir}"
	echo "branchNameA = ${branchNameA}"
	echo "branchNameB = ${branchNameB}"
	echo "branchExistsTestA = ${branchExistsTestA}"
	echo "branchExistsTestB = ${branchExistsTestB}"
	echo "tmpWorkingDirBranchA = ${tmpWorkingDirBranchA}"
	echo "tmpWorkingDirBranchB = ${tmpWorkingDirBranchB}"


###
### Init the temp working area path
### 
	docmd "rm -rf ${tmpWorkingDir}"
	docmd "mkdir -p ${tmpWorkingDir}"
	docmd "mkdir -p ${tmpWorkingDirBranchA}"
	docmd "mkdir -p ${tmpWorkingDirBranchB}"

###
### Recursively copy Branch A into the temp dir
###
	###
	# Branch A
	###
		docmd "cd ${repositoryDir} && git checkout ${branchNameA}"
		docmd "cp -R . ${tmpWorkingDirBranchA}/"

	###
	# Branch B
	###
		docmd "cd ${repositoryDir} && git checkout ${branchNameB}"
		docmd "cp -R . ${tmpWorkingDirBranchB}/"

###
### Go back to where we were when this program was called
###
	# Go back to where we were rooted when this program was called
	cd "${thisDir}"



###
### Launch a folder compare session in Beyond Compare
###

	docmd "bcomp -fv='Folder Compare' ${tmpWorkingDirBranchA} ${tmpWorkingDirBranchB} &"  #See:  https://www.scootersoftware.com/v4help/index.html?command_line_reference.html

