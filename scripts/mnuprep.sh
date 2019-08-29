#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Prep MNU images
#
# Version 1.0.0

# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nIcon Maker\n"
    echo -e "Usage:\n  iconprep [-p path] [-d path] [-t type]\n"
    echo    "Options:"
    echo    "  -s / --source       [path]  The path of the source image(s). Default: ~/Downloads"
    echo    "  -d / --destination  [path]  The path to the target folder. Default: ~/Desktop"
    echo    "  -h / --help                 This help screen"
    echo
}

# Set inital state values
sourceFolder="$HOME/Downloads"
destFolder="$HOME/Desktop"
extension="png"
argIsAValue=0
args=(-s -d)
# Set required sizes (@2x will be created too:
# 20 - Menu icon
# 64 - Popover icon
m_a_sizes=(20 64)

# Functions
m_a_make() {
    # Make MNU script icons
    for size in ${m_a_sizes[@]}; do
        # Set the destination file name
        destFile=${1%.*}

        # Set the destination extension lowercase
        extension=${1##*.}
        extension=${extension,,}

        # Make the standard-size image
        make "$1" "$destFolder/$destFile-$size.$extension" "$size"

        # Make the retina-size image (@2x)
        retinaSize=$(($size * 2))
        make "$1" "$destFolder/$destFile-$size@2x.$extension" "$retinaSize"
    done
}

make() {
    # Generic function to copy source to new file and then resize the copy using SIPS
    # $1 - The source image file
    # $2 - The destination image file
    # $3 - The destination image size (width and height)
    cp "$1" "$2"
    sips "$2" -Z "$3" -i > /dev/null
}

# Process the arguments
argCount=0
for arg in "$@"
do
    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${args[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$argIsAValue" in
            1)  sourceFolder=$arg ;;
            2)  destFolder=$arg ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ $arg = "-s" || $arg = "--source" ]]; then
            argIsAValue=1
        elif [[ $arg = "-d" || $arg = "--destination" ]]; then
            argIsAValue=2
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        fi
    fi

    ((argCount++))
    if [[ $argCount -eq $# && $argIsAValue -ne 0 ]]; then
        echo "Error: Missing value for $arg"
        exit 1
    fi
done

# Make sure we have a source image
if [ "$sourceFolder" != "UNSET" ]; then
    if [ -d "$sourceFolder" ]; then
        if [ -d "$destFolder" ] ; then
            cd "$sourceFolder"
            for file in *
            do
                # Make the images
                echo "Processing '$file'..."
                m_a_make "$file"
            done
        else
            echo "Destination folder $destFolder can't be found"
            exit 1
        fi
    else
        echo "Source folder $sourceFolder can't be found"
        exit 1
    fi
else
    echo "Error: No source folder set"
    exit 1
fi
