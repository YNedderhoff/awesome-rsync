#!/bin/bash

LOGFILE="/path/to/logfile-"$(date +%Y%m%d)".log"
SOURCES="path/to/remote/source/folder"
TARGET="/path/to/external/harddrive/path/to/target/folder"
RSYNCCONF='--protect-args --delete --delete-excluded --stats'
EXCLUDES="--exclude-from=/path/to/ignorelist"
RSYNC=`which rsync`

function run {
    echo "Sync time: "$(date +%Y%m%d-%H:%M:%S) >> $LOGFILE
    echo "Running filesync"  >> $LOGFILE
    echo "Getting ssh key ..." >> $LOGFILE
    . /path/to/keychain

    # Log command
    echo 'Running '$RSYNC' -aPEh -e ssh '$RSYNCCONF' '$EXCLUDES' '$SOURCES' '$TARGET' >> '$LOGFILE' 2>&1' >> $LOGFILE 2>&1

    # Run
    $RSYNC -aPEh -e ssh $RSYNCCONF $EXCLUDES "$SOURCES" $TARGET >> $LOGFILE 2>&1
    echo "####################" >> $LOGFILE
    echo "" >> $LOGFILE
}

# runs the sync if external hard drive is mounted
# else mounts before running the sync, unmounts after and trigger harddrive spindown
if mount | grep /m > /dev/null; then
    run
else
    mount /path/to/external/harddrive
    run
    umount /path/to/external/hardrive
    hdparm -y /dev/disk/by-uuid/<uuid-of-external-hardrive>
fi

exit 0

