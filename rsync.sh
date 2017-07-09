#!/bin/bash

# check if conf file is provided
if [ "$#" -lt 1 ]; then
    echo "Error: Please provide at least a config file as an argument"
fi

CONF=$1

LOGFILE=$(awk '/^logfile/{print $3}' $CONF)-"$(date +%Y%m%d)".log
SOURCE=$(awk '/^source/{print $3}' $CONF)
TARGET=$(awk '/^target/{print $3}' $CONF)
KEYCHAIN=$(awk '/^keychain/{print $3}' $CONF)
RSYNCCONF=$(awk '/^rsyncconf/{print $3}' $CONF)
EXCLUDES=$(awk '/^excludes/{print $3}' $CONF)

RSYNC=`which rsync`

function log {
    echo $1 >> $LOGFILE 2>&1
}

function run {
    log "Sync time: "$(date +%Y%m%d-%H:%M:%S)
    log "Running filesync"
    log "Getting ssh key ..."
    . $KEYCHAIN

    # Log command
    log 'Running '$RSYNC' -aPEh -e ssh '$RSYNCCONF' '$EXCLUDES' '$SOURCE' '$TARGET' >> '$LOGFILE' 2>&1'

    # Run
    $RSYNC -aPEh -e ssh $RSYNCCONF $EXCLUDES "$SOURCE" $TARGET >> $LOGFILE 2>&1
    log "####################"
    log ""
}

# check if more than the allowed arguments are provided
if [ "$#" -gt 3 ]; then
    log "Error: Allowed arguments are: <conf> [<external1-path> <external1-uuid] [<external2>]"
fi

if [ "$#" -eq 1 ]; then
    run
else
    while [ ! $# -eq 0 ]
    do
        case "$1" in
            --external1-mount)
                EXTERNAL1_MOUNT=true
                EXTERNAL1_PATH=$(awk '/^external1path/{print $3}' $CONF)
                EXTERNAL1_UUID=$(awk '/^external1uuid/{print $3}' $CONF)
                ;;
            --external2-mount)
                EXTERNAL2_MOUNT=true
                EXTERNAL2_PATH=$(awk '/^external2path/{print $3}' $CONF)
                EXTERNAL2_UUID=$(awk '/^external2uuid/{print $3}' $CONF)
                ;;
        esac
        shift
    done

    # runs the sync if external hard drive/drives is/are mounted
    # else mounts before running the sync, unmounts after and triggers harddrive spindown

    if [ "$EXTERNAL1_MOUNT" = true ] && [ "$EXTERNAL2_MOUNT" = true ] ; then
        if (mount | grep $EXTERNAL1_PATH > /dev/null) && (mount | grep $EXTERNAL2_PATH > /dev/null); then
            run
        elif (mount | grep $EXTERNAL1_PATH > /dev/null); then
            mount $EXTERNAL2_PATH
            run
            umount $EXTERNAL2_PATH
            hdparm -y /dev/disk/by-uuid/$EXTERNAL2_UUID
        elif (mount | grep $EXTERNAL2_PATH > /dev/null); then
            mount $EXTERNAL1_PATH
            run
            umount $EXTERNAL1_PATH
            hdparm -y /dev/disk/by-uuid/$EXTERNAL1_UUID
        else
            mount $EXTERNAL1_PATH
            mount $EXTERNAL2_PATH
            run
            umount $EXTERNAL1_PATH
            umount $EXTERNAL2_PATH
            hdparm -y /dev/disk/by-uuid/$EXTERNAL1_UUID
            hdparm -y /dev/disk/by-uuid/$EXTERNAL2_UUID
        fi
    elif [ "$EXTERNAL1_MOUNT" = true ]; then
        if (mount | grep $EXTERNAL1_PATH > /dev/null); then
            run
        else
            mount $EXTERNAL1_PATH
            run
            umount $EXTERNAL1_PATH
            hdparm -y /dev/disk/by-uuid/$EXTERNAL1_UUID
        fi
    elif [ "$EXTERNAL2_MOUNT" = true ]; then
        if (mount | grep $EXTERNAL2_PATH > /dev/null); then
            run
        else
            mount $EXTERNAL2_PATH
            run
            umount $EXTERNAL2_PATH
            hdparm -y /dev/disk/by-uuid/$EXTERNAL2_UUID
        fi
    else
        log "Something went wrong regarding external drive mounts."
    fi
fi

exit 0

