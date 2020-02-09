# website-downloader
This script downloads files from a remote server according to the values passed with the arguments '-bcdfklnprsu'. This is very useful to get files from a server without having to connect to it and do it manually.

The website-downloader script comes with another script, storepass.sh, which lets encrypt a password and store it in the configuration file. To know more, execute 'storepass.sh -h' in a console.

With no option, the command loads the default configuration file declared in the 'website-downloader.conf' file.

The general configuration file is firstly loaded ('website-downloader.conf'). Then the configuration file declared in that general configuration file which contains the values specific to the server you download from and to the machine you download to. At last, the options are read from the command line. That means, the command line options overwrite the variables used by the script. This can be very useful when exceptionally the files are downloaded from a server with some unusual options. For example to dwonload files from a preprod server which is identical to a production one but its hostname. Then the same configuration file can be included and the option '-r' specified with a different REMOTE_SERVER_HOSTNAME.

website-downloader [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES] [-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME] [-u SSH_USER]

website-uploader [-h]

website-uploader [-v]

OPTIONS

-c : The configuration file to include.

-d : If this option is used then the password following the '-p' option will be decrypted before being used.

-f : The file containing the list of files (regular ones or folders) to send to the remote server.

-h : Display the help.

-k : The files are sent in a compressed format (bz2) to speed up the download. The files are compressed before being downloaded then uncompressed once on the local machine. Then the local compressed files are removed automatically.

-l : The local website path.

-n : The number of transfers is displayed before each transfer. At the end, the total amount of transfers is displayed. That number is incremented before each try. Therefore, it doesnot represent only succeeded transfers.

-p : The SSH user's password. With the option '-d', the password will be decrypted before being used.

-r : The website path on the remote server.

-s : The web server's hostname.

-u : The SSH username to use to connect to the remote web server.

-v : This script version.

Exit status :

0 = success ; 1 = failure due to wrong parameters ; 2 = abnormal exit

To inform about any problem : https://github.com/ShaoLunix/website-downloader/issues.
