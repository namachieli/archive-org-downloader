#!/bin/bash
# This script makes the downloading of archives found in archive.org easier.

#####
# Variables
#####
# Where should the log be written
logpath="./archive_downloader.log"

# Base Archive.org URL for downloads
base_url=https://archive.org/download/

# Default directory for download
dir="./"

# Default throttle limit for wget
throttle="10M"

# Archive.org requires a 'logged-in-user' and 'logged-in-sig' Cookie field passed as a header 
# to be able to access restricted content. You must login using a normal browser to obtain
# the 'logged-in-sig'.
# See https://blog.archive.org/2013/07/04/how-to-use-the-virtual-machine-for-researchers/ 
# "How do I bulk download data from archive.org onto the VM?" For more details
# You can also use a Chrome extension called 'CurlWget' to find the same info
LOGGED_IN_USER="user@domain.com"
LOGGED_IN_SIG="1111111111111+222222222222+asdfASDF%asdfASDF..."
#####
# Variables
#####

#Logging | lazy file operations
touch $logpath
chmod 666 $logpath

# Make sure we have args
if [ -z "$1" ]
    then
    echo "usage: archive_downloader [-i|-e|-d|-L|-o|-t] <value>"
    echo "archive_downloader -h for more info"
    exit 0;
fi

printf "%s\n" "$(date); Execution Begin" >> $logpath

# Parse flags into variables
while getopts i:e:d:L:o:t:ysrh flag
do
    case $flag in
        i)
            # Set the identifier to scrape/download
            identifier=$OPTARG
            printf "%s\n" "$(date); Identifier is set to ${identifier}" >> $logpath
            ;;
        e)
            # Set the extensions to scrape
            ext=$OPTARG
            printf "%s\n" "$(date); Archive Extension is set to ${ext}" >> $logpath
            ;;
        d)
            # Set the directory to download into
            if [ ! -w "$OPTARG" ]; then
                echo "$(date); Download directory not found or isn't writable, setting to './'" | tee -a $logpath
                dir="./"
            else
                dir=$OPTARG
                printf "%s\n" "$(date); Download directory is set to ${dir}" >> $logpath 
            fi
            ;;
        L)
            # Path to scrape file to be loaded
            load_list=$OPTARG
            ;;
        y)
            # Skip confirmation and auto continue
            non_interactive=true
            ;;
        s)
            # Scrape only flag
            scrape_only=true
            ;;
        r)
            # Remove item from list when complete flag
            remove_when_complete=true
            ;;
        t)
            # Set max speed for wget
            printf "%s\n" "$(date); Throttling speed - Max: $OPTARG" >> $logpath 
            throttle=$OPTARG
            ;;
        o)
            # Output Scraped list to file
            touch $OPTARG &> /dev/null 
            if [ ! -w "$OPTARG" ]; then
                echo "$(date); Unable to open '$OPTARG' for writting, please check location and permissions." | tee -a $logpath
                exit 0
            else
                output_scrape=$OPTARG
                printf "%s\n" "$(date); Scrape list will be output to '$output_scrape'" >> $logpath 
            fi
            ;;
        h)
            echo " "
            echo "This script makes the downloading of ALL archives found in an archive.org redump easier."
            echo " "
            echo "You must set your 'LOGGED_IN_USER' and 'LOGGED_IN_SIG' in the variables section of this script."
            echo "See script source for details"
            echo " "
            echo " "
            echo "-i, Identifier		The Archive.org identifier" 
            echo "			  You can find this on the Details page of a collection"
            echo " "
            echo "-e, Archive Extension	Include only the listed extensions (zip, 7z, rar, etc)"
            echo "			  You can specify multiple by seperating them with |"
            echo "			  default: \".rar|.zip|.7z\" (Must be quoted)"
            echo " "
            echo "-d, Download directory	The full path directory that items will be downloaded to" 
            echo "			  (/path/to/dir/) (Defaults to current dir)"
            echo " "
            echo "-L, Load Scrape File		Path to file that contains a scraped list to download"
            echo "			  Use -s to generate a scrape taht you can edit and load in."
            echo "-y, Skip Confirmation	Run script in non-interactive mode (Assumes 'Yes')"
            echo " "
            echo "-s, Scrape Only		Will only scrape the files found and output to screen."
            echo " 			  Ignores '-d'"
            echo " "
            echo "-o, Output Scrape List	Outputs the result of a scrape to the specified file."
            echo " "
            echo "-r, Remove When Complete 	Removes the item from the list (-L) when completed"
            echo " "
            echo "-t, Throttle			Cap max speed for download (wget --limit-rate)"
            echo " 			  Expressed in Bytes/s, K, M, and G are recognized. (Example: 3M for 3 MBps)"
            echo " 			  Default set in variable: 10MBps (80 Mbps)"
            echo " "
            exit 0;;
        ?)
            echo "ERROR: Unrecognized option, please see -h for details."
            exit 0;;
       esac
done

if [[ -z "${identifier}" ]]; then echo "$(date); There was an error preventing this script from continuing, please check '$logpath' for more details"
    exit 0;
fi

# Check that the value for throttle mattches appropriate pattern.
if [[ ! "$throttle" =~ ^[0-9]+($|k$|K$|m$|M$|g$|G$) ]]; then
	printf "%s\n" "$(date); Value for throttle (${throttle}) does match a pattern required for 'wget --limit-rate'" >> $logpath
	echo "'${throttle}' is not valid for 'wget --limit-rate'. Exiting..."
	exit 0
fi

#Make sure LOGGED_IN_USER has a URL encoded @
printf "%s\n" "$(date); Logging in as user: $LOGGED_IN_USER" >> $logpath
LOGGED_IN_USER=$(echo ${LOGGED_IN_USER} | sed 's/@/%40/')

# If no extension specified, look for common ones
if [ -z "${ext}" ] && [ -z "$load_list" ]; then
    printf "%s\n" "$(date); Scraping default extensions: '.rar|.zip|.7z'" >> $logpath
    ext=".rar|.zip|.7z"
fi
# Fix escaping for extensions
ext=$(echo "$ext" | sed 's/./\\./')

source="${base_url}${identifier}"
printf "%s\n" "$(date); Source URL set to: $source" >> $logpath

if [ -z "$load_list" ]; then
    printf "%s\n" "$(date); Scraping $source" >> $logpath
    mapfile -t list < <(wget -qO- $source | grep -E "${ext}" | sed "s/^[ \t]*<td>//" | sed "s/<\/td>//" | sed 's/\&amp;/\&/')
else
	printf "%s\n" "$(date); Loading items from list '$load_list'" >> $logpath
    declare -a list
    readarray -t list < $load_list
fi

total=${#list[@]}

if [ "$scrape_only" = "true" ]; then
    if [ ! -z "$output_scrape" ]; then
    	printf "%s\n" "$(date); Outputting scrape to '$output_scrape'" >> $logpath
        printf '%s\n' "${list[@]}" > $output_scrape
    else
        printf '%s\n' "${list[@]}"
    fi
    printf "%s\n" "$(date); Scrape only requested, Exiting..." >> $logpath
    exit 0
fi

echo "Begining download of ${total} items to ${dir}"
if [ ! "$non_interactive" = "true" ]; then
    read -p "Are you sure you want to do this? (y/N) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        printf "%s\n" "$(date); Execution canceled by user" >> $logpath
        echo "Canceled"
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
fi

i=1
declare -a uncompleted
for item in "${list[@]}"; do
    if [ -f "${dir}/${item}" ]; then
        printf "%s\n" "$(date); ${dir}/${item} already exists, replacing." >> $logpath
        rm "${dir}/${item}"
    fi
    printf "%s\n" "$(date); (${i}/${total}) Downloading: ${item}" >> $logpath
    echo "$(date); Downloading: ${item} (${i}/${total})"
    wget -q --show-progress -P ${dir} \
        --limit-rate ${throttle} \
        --execute robots=off \
        --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 \
        --header "Cookie: logged-in-user=${LOGGED_IN_USER}; logged-in-sig=${LOGGED_IN_SIG};" \
        "${source}/${item}"
    result=$?
    if [ $result -eq 0 ]; then
        if [ "$remove_when_complete" = "true" ]; then
            sed -i "/${item}/d" $load_list > /dev/null
        fi
    else
        printf '%s\n' "$(date); Failed to download: ${item} (wget exit code: $result)" >> $logpath
        uncompleted+=("${item}")
    fi
    ((i++))
done

echo "The following were not downloaded, please try these items again:"
printf '%s\n' "${uncompleted[@]}"

echo "$(date); All operations completed."
printf "%s\n" "$(date); All operations completed." >> $logpath
