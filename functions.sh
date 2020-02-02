#!/bin/bash

#============#
# FUNCTIONS  #
#============#

# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$missingcommands : missing"
    echo "Please, install it first and check you can access '$missingcommands'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES]" \
                    "[-h] [-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME]" \
                    "[-u SSH_USER] [-v]"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Display the help of this script
displayhelp()
{
    echo "${myscript^^}"
    echo
    echo "Syntax : $myscript [OPTION ...]"
    echo "This script downloads files from a remote server according to the values passed with the arguments '-bcdfklnprsu'." \
         "This is very useful to send files from a server to another one without having to connect to it and do it manually."
    echo
    echo "With no option, the command loads the default configuration file declared in the '$myscript.conf' file."
    echo
    echo "The general configuration file is firstly loaded ('$myscript.conf')."
    echo "Then the configuration file declared in that general configuration file" \
         "which contains the values specific to the source and destination machines."
    echo "At last, the options are read from the command line."
    echo "That means, the command line options overwrite the variables used by the script." \
         "This can be very useful when exceptionally the files are downloaded to a server with some unusual options."
    echo "For example to download files from a preprod server which is identical to a production one but its hostname." \
         "Then the same configuration file can be included and the option '-r' specified with a different REMOTE_SERVER_HOSTNAME."
    echo
    echo "$myscript [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES]" \
                    "[-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME]" \
                    "[-u SSH_USER]"
    echo "$myscript [-h]"
    echo "$myscript [-v]"
    echo
    echo " OPTIONS"
    echo
    echo "  -c :        The configuration file to include."
    echo "  -d :        If this option is used then the password following the '-p' option will be decrypted before being used."
    echo "  -f :        The file containing the list of files (regular ones or folders) to send to the remote server."
    echo "  -h :        Display the help."
    echo "  -k :        The files are downloaded in a compressed format (bz2) to speed up the download." \
                        "The files are compressed on the remote server before being downloaded then uncompressed " \
                        "locally." \
                        "The local and the remote compressed files are removed automatically."
    echo "  -l :        The local website path."
    echo "  -n :        The number of transfers is displayed before each transfer." \
                        "At the end, the total amount of transfers is displayed." \
                        "That number is incremented before each try. Therefore, it doesnot represent only succeeded transfers."
    echo "  -p :        The SSH user's password. With the option '-d', the password will be decrypted before being used."
    echo "  -r :        The website path on the remote server."
    echo "  -s :        The web server's hostname."
    echo "  -u :        The SSH username to use to connect to the remote web server."
    echo "  -v :        This script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about any problem : $mycontact."
    exit
}

# Loading the configuration file
load_configfile()
{
    # If the configuration file is set with a relative path
    # Then it is converted to absolute
    if [[ "$configuration_file" != /* ]]
        then
            script_dir="$( cd "$( dirname "$0" )" && pwd )"
            configuration_file="$script_dir/$configuration_file"
    fi

    # Loading the configuration file only if it exists
    # Else exit with an error
    if [ ! -f "$configuration_file" ]
        then
            echo "$configuration_file could not be found."
            exit 1
        else
            . "$configuration_file"
    fi
}

# Password decryption
decrypt_password()
{
    decryptedpass=$(./storepass.sh -d "decrypted" "$1")
    # Exiting if the decrypted password is wrong
    if [ -z "$decryptedpass" ]
        then
            echo "Something went wrong with the decryption of the password."
            usage
    fi
}

# Substring replacement
#   Substitute to the local path ($2) in the line (string $1) the remote path ($3)
#
#	@parameter $1 : string to modify (hay)
#	@parameter $2 : string substring to be replaced (needle)
#	@parameter $3 : string new substring
#	@return string new string
string_replace()
{
	echo "${1/$2/$3}"
}

# Compressing file
compress()
{
    echo "compressing before downloading ..."

    #compressfolder=${line%/*}
    compressfolder=$(dirname $line)
    #compressedfile="$compressfolder/$filename.bz2"
    compressedfile="$filename.bz2"
    # compressing through the bzip2 filter
    sshpass -p"$decrypted_ssh_pass" \
            ssh -tt -n -p "$ssh_port" "$ssh_user@$ssh_server" \
            "cd $compressfolder; " \
            "echo $decrypted_ssh_pass | sudo -S tar -cj -f $tempfolder/$compressedfile $filename; " \
            "exit" >/dev/null 2>&1
}

# Uncompressing file
uncompress()
{
    echo "uncompressing $compressedfile to the destination folder"
    # uncompressing through the bzip2 filter to the destination folder
    echo "$decrypted_local_pass" | sudo -S tar -xjf "$tempfolder/$compressedfile" --directory "$destFolder/" --overwrite
}

# Changing the attributes (owner and permissions) of the folder/file
change_attrib()
{
    echo "changing the owner to $local_website_owner"
    echo "$decrypted_local_pass" | sudo -S chown -R $local_website_owner: "$destFolder"
    echo "changing the permissions to $local_website_permissions"
    echo "$decrypted_local_pass" | sudo -S chmod -R $local_website_permissions "$destFolder"
}

# Removing temporary compressed files
remove_temp_compressedfile()
{
    echo "Removing the remote temporary file $filename.bz2"
    sshpass -p"$decrypted_ssh_pass" \
            ssh -tt -n -p "$ssh_port" "$ssh_user@$ssh_server" \
            echo "$decrypted_ssh_pass" | sudo -S \rm -f "$tempfolder/$filename.bz2; " \
            "exit" >/dev/null 2>&1
    # Checking the removal
#    check_remote_removal

    echo "Removing the local temporary file $filename.bz2"
    echo "$decrypted_local_pass" | sudo -S \rm -f "$tempfolder/$filename.bz2"
    # Checking the removal
    check_local_removal
}



# Downloading the files
download()
{
	echo -e "downloading : "$line" to "$fileTobeDownloaded

    # Declaration of the destination folder
    destFolder=$(dirname $fileTobeDownloaded)

    # Creation of the destination path
    #echo "$decrypted_local_pass" | sudo -S chown -R $local_user: $local_website_root
    #mkdir -p $destFolder
    # Redeclaring the owner
    #echo "$decrypted_local_pass" | sudo -S chown -R $local_website_owner: $local_website_root

    # The transfer procedure is slightly different
    # according to if the compression is used or not
	case "$iscompressed" in
	    # Compressed file
	    true )
                # Compressing the file on the local machine
                compress

                # Downloading the file to the destination folder on the local machine
                sshpass -p"$decrypted_ssh_pass" \
                        scp -P "$ssh_port" "$ssh_user"@"$ssh_server":"$tempfolder/$compressedfile" "$tempfolder/" 2>&1 1>/dev/null

                # Checking if download is ok
	            check_download

                # Uncompressing the file on the local machine
                uncompress

                # Changing the attributes of the file on the local machine
                change_attrib

                # Removing the local compressed file
                remove_temp_compressedfile
                ;;

        # Not compressed file
        false )
                # Downloading the file from the source folder on the remote server
                # to the destination folder on the local machine
                sshpass -p "$decrypted_ssh_pass" \
                            scp -P "$ssh_port" "$line" "$ssh_user@$ssh_server:$fileTobeDownloaded" >/dev/null 2>&1

	            # Checking if download is ok
	            check_download
                ;;
    esac
}



# Checking the downloaded files
check_download()
{
	# checking if download is ok
	if [ -f "$tempfolder/$compressedfile" ]
	    then echo "file downloaded."
	    else echo "file couldnot be downloaded."
	fi
}



# Checking the removal of local files
check_local_removal()
{
	# checking if the file could be removed
	if [ -f "$tempfolder/$compressedfile" ]
	    then echo "The local temporary file $tempfolder/$compressedfile couldnot be deleted."
	    else echo "The local temporary file has been deleted."
	fi
}



# Checking the removal of remote files
check_remote_removal()
{
	# checking if the file could be removed
    sshpass -p"$decrypted_ssh_pass" \
            ssh -tt -n -p "$ssh_port" "$ssh_user@$ssh_server" \
	        "if [ -f $tempfolder/$compressedfile ]; then echo 'The temporary file has been deleted.'; " \
            "else echo 'The temporary file '$tempfolder/$compressedfile' couldnot be deleted.'; " \
	        "fi; " \
            "exit" >/dev/null 2>&1
}

