#!/bin/bash

#==============================================================================#
#
#       WEBSITE-DOWNLOADER
#
# This script downloads files from a remote server.
# This is very useful to send files from a server to another one without having
# to connect to it and do it manually.
#
# Versions
# [2020-02-01] [1.0.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset


#=== THIS SCRIPT DETAILS
VER=1.0.0
myscript="website-downloader"
myproject="$myscript"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#*** CHECKING IF THE CURRENT SCRIPT CAN BE EXECUTED
#*** root is forbidden
myidentity=$(whoami)
if [ $myidentity = "root" ]
then
	RED='\033[0;31m'
	GREEN='\033[0m'
	echo -e "${RED}this script cannot be executed as root${GREEN}\n"
	exit
fi



#=== FUNCTIONS FILE
. functions.sh



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand_1="sshpass"
missingcommands=""
# Params
script_configfile="website-downloader.conf"
list_of_files="listof-files-tobe-downloaded"
isbackup=false
decryptedpass=""
decrypted_ssh_pass=""
decrypted_local_pass=""
isdecrypt=false
iscompressed=false
sourcetype=""
compressfolder=""
compressedfile=""
iscounteron=false
counter=""
remote_website_root=""
remote_website_owner=""
ssh_server=""
ssh_user=""
ssh_pass=""
isssh_pass=false
local_website_root=""
local_website_owner=""
local_website_permissions=""
local_user=""
local_pass=""
# Temporary folder
tempfolder="/tmp"
# Time
currentTime=$(date +"%Y%m%d"_"%H%M%S")



#=== CONFIGURATION FILE
. "$script_configfile"
# Loading the configuration file
load_configfile



#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#====================#
# TEST PREREQUISITES #
#====================#
if ! type $requiredcommand_1 > /dev/null 2>&1
    then
        missingcommands="$requiredcommand_1"
fi
if -z "$missingcommands" > /dev/null 2>&1
    then prerequisitenotmet $missingcommands
fi



#=======#
# FLAGS #
#=======#
# -c : the configuration file to consider
# -d : if this option is present then the password following the option '-p' must be decrypted
# -f : the list of files to download from the remote server
# -h : display the help
# -k : files are downloaded in compressed format (bz2) to speed up the download
# -l : the local website path
# -n : number of downloads. It starts every download with its number
# -p : SSH user's password. With the option '-d', the password must be decrypted.
# -r : the remote website path
# -s : web server name
# -u : SSH user to use to connect to the web server
# -v : this script version

while getopts "b:c:df:hkl:np:r:s:u:v" option
do
    case "$option" in
        c)
            configuration_file=${OPTARG}
            # Loading the configuration file
            load_configfile
            # Getting the decrypted password
            decrypt_password
            ;;
        d)
            isdecrypt=true
            isssh_pass=true
            ;;
        f)
            list_of_files=${OPTARG}
            ;;
        h)
            displayhelp
            exit "$exitstatus"
            ;;
        k)
            iscompressed=true
            ;;
        l)
            local_website_root=${OPTARG}
            ;;
        n)
            counter=0
            iscounteron=true
            ;;
        p)
            ssh_pass=${OPTARG}
            isssh_pass=true
            ;;
        r)
            remote_website_root=${OPTARG}
            ;;
        s)
            ssh_server=${OPTARG}
            ;;
        u)
            ssh_user=${OPTARG}
            ;;
        v)
            echo "$myscript -- Version $VER -- Start"
            date
            exit "$exitstatus"
            ;;
        \? )
            # For invalid option
            usage
            ;;
    esac
done



#=============#
# PREPARATION #
#=============#
# If the password must be decrypted
# Then execute the decrypt function
# Else the decrypted password is as it was passed
if [ "$isdecrypt" == true ] && [ "$isssh_pass" == true ]
    then
        decrypt_password "$ssh_pass"
        decrypted_ssh_pass="$decryptedpass"
elif [ "$isdecrypt" == false ] && [ "$isssh_pass" == true ]
    then
        decrypted_ssh_pass="$ssh_pass"
fi

if [ "$isdecrypt" == true ]
    then
        decrypt_password "$local_pass"
        decrypted_local_pass="$decryptedpass"
fi



#======#
# MAIN #
#======#
#*** READING FILES TO BE DOWNLOADED ***
#*** and downloading them from remote server to local machine
while read line
do
	# Checking if current line is not empty
	if [[ ! -z "$line" ]] && [[ "$line" != \#* ]]
	then
		(( counter++ ))
		echo "$counter"

		filename=$(basename $line)
		fileTobeDownloaded=$(string_replace "$line" "$local_website_root" "$remote_website_root")

		#*** DOWNLOAD
		# Downloading the file from remote server to local machine
        download
		echo
		# Incrementing the counter of downloads
	fi
done < "$list_of_files"

echo "number of downloads : $counter."

exit 0
