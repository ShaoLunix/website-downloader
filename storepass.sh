#!/bin/bash

#==============================================================================#
#
#       STOREPASS
#
# This script encrypts/decrypts the password passed as an argument.
# It also stores it, after encryption, into the server configuration file
# declared in the main script's general configuration file.
#
# Versions
# [2020-02-01] [1.0.1] [Stéphane-Hervé] modified for local user integration
# [2019-09-02] [1.0.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset


#=== CONFIGURATION FILE
. website-downloader.conf
. "$configuration_file"

#=== THIS SCRIPT DETAILS
VER=1.0.1
myscript="storepass"
myproject="website-downloader"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand="openssl"
lastargument=""
password=""
passphrase="]MK0U3;Rm;U}1Nw"
encryptedpass=""
decryptedpass=""
display_pass="off"
isdisplayed=false
isinteractive=false
isprotocol=false
declare -a protocol
protocol=( "local" "ftp" "ssh" )



#===========#
# FUNCTIONS #
#===========#
# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$requiredcommand : missing"
    echo "Please, install it first and check you can access '$requiredcommand'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript [-d PASSWORD_STATUS] [-p PROTOCOL] PASSWORD"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Display the help of this script
displayhelp()
{
    echo "Syntax : $myscript [OPTION ...]"
    echo "$myscript encrypts the password passed in argument."
    echo "With no option, the command returns an error"
    echo
    echo "$myscript [-i] [-p PROTOCOL] PASSWORD"
    echo "$myscript [-d PASSWORD_STATUS] PASSWORD"
    echo "$myscript [-h]"
    echo "$myscript [-v]"
    echo
    echo "  -d :        display the encrypted or decrypted password. The PASSWORD_STATUS can be 'encrypted' or 'decrypted'. By default, it is 'off' which means the password will not be displayed."
    echo "  -h :        display the help."
    echo "  -i :        interactive mode for the password. The password is typed and confirmed at the prompt in a hidden way."
    echo "  -p :        protocol the password is required for. The PROTOCOL argument can be 'LOCAL', 'FTP' or 'SSH' (insensitive case)."
    echo "  -v :        this script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about the problems : $mycontact."
    exit
}

# Getting the password
# It can be an argument on the command line
# or typed at the prompt in an interactive mode
getPassword()
{
    # If the interactive mode is on
    # Then the password is asked by the script after execution and in a hidden way
    if [ "$isinteractive" == true ]
        then
            pass_1=true
            pass_2=false
            while [ "$pass_1" != "$pass_2" ]
            do
                read -p "Enter password :" -s pass_1
                echo
                read -p "Confirm password :" -s pass_2
                echo
                if [ "$pass_1" == "$pass_2" ]
                    then password="$pass_1"
                    else echo "Passwords do not match. Do it again."
                fi
            done
        else
            password="$lastargument"
    fi
}

# Writing the password to the configuration file
writePassword()
{
    # If the password variable can be found in the configuration file
    # Then the password replaces the one in the file
    # Else the line is created at its place
    if grep -Eq "^$proto"_pass "$configuration_file"
        then
            sed -i -E 's/'"$proto""_pass=\".*\""'/'"$proto""_pass=\"$encryptedpass\""'/g' "$configuration_file"
        else
            sed -i '/'"$proto"'_user/a '"$proto""_pass=\"$encryptedpass\"" "$configuration_file"
    fi
}

#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#=======#
# Flags #
#=======#
# -d : display the encrypted/decrypted password
# -h : display the help
# -i : interactive mode
# -p : protocol the password is required for
# -v : this script version
while getopts "d:hip:v" option
do
    case "$option" in
        d)
            display_pass=${OPTARG}
            isdisplayed=true
            if [ "$display_pass" != "encrypted" ] && [ "$display_pass" != "decrypted" ] && [ "$display_pass" != "off" ]
                then usage
            fi
            ;;
        h)
            displayhelp
            exit "$exitstatus"
            ;;
        i)
            isinteractive=true
            ;;
        p)
            protocol=${OPTARG}
            protocol=$(echo "$protocol" | awk '{print tolower($0)}')
            isprotocol=true
            if [ "$protocol" != "local" ] && [ "$protocol" != "ftp" ] && [ "$protocol" != "ssh" ]
                then usage
            fi
            ;;
        v)
            echo "$myscript -- Version $VER -- Start"
            date
            exit "$exitstatus"
            ;;
        \? ) # For invalid option
            usage
            ;;
    esac
done



#===============#
# PREREQUISITES #
#===============#
#=== Required command
if ! type "$requiredcommand" > /dev/null 2>&1
    then prerequisitenotmet
fi
#=== Required password
lastargument="${@: -1}"
getPassword
if [ -z "$password" ]
    then usage
fi



#======#
# MAIN #
#======#

#=== ENCRYPTION/DECRYPTION OF THE PASSWORD
#=== AND WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE ONLY IF 'OFF' argument is on
case "$display_pass" in
    "encrypted")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                echo "$encryptedpass"
                exit
                ;;

    "decrypted")
                # Decrypting the password
                decryptedpass=$(echo "$password" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)
                echo "$decryptedpass"
                exit
                ;;

    "off")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                # Decrypting the password
                decryptedpass=$(echo "$encryptedpass" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)

                #=== WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE
                # Testing if the given password is identical to the dehashed password
                # If YES, then the hashed password is written to the configuration file
                if [ "$decryptedpass" == "$password" ]
                    then
                        # If the protocol is passed in argument,
                        # then the password is written only for this protocol
                        # else the password is written for all the protocols
                        if $isprotocol == true
                            then
                                proto="$protocol"
                                writePassword
                            else
                                for proto in "${protocol[@]}"
                                do
                                    writePassword
                                done
                        fi
                    else
                        echo "Something went wrong with the encryption of the password."
                        abnormalExit
                fi
                ;;

    \?) # For invalid option
                usage
                ;;
esac

exit

