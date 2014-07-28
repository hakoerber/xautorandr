#!/usr/bin/env bash

# a script to automatically detect and configure available outputs.
#
# dependencies: xrandr

# settings:

# set to empty string to disable logging
LOGFILE="$HOME/.var/log/xautorandr.log"

# determine the relative positioning of all outputs. available values:
# - "side-by-side" : place all outputs next to each other, with the primary
#   output being the leftmost
# - "mirror" : mirror all outputs
POSITIONING="side-by-side"

log() {
    [[ "$LOGFILE" ]] && { echo -e "[$(date +%FT%T)] $*" >> $LOGFILE ; }
}

output() {
    echo -e $*
    log $*
}

error() {
    msg="[ERROR] $*"
    echo -e $msg >&2
    log $msg
}

mkdir -p "$(dirname $LOGFILE)"
output "Logging to $LOGFILE."

case "$POSITIONING" in 
    "side-by-side")
        position_command="--right-of"
        ;;
    "mirror")
        position_command="--same-as"
        ;;
    *)
        error "Invalid value \"$POSITIONING\" for \$POSITIONING"
        exit 1
        ;;
esac

primary_output=$(xrandr -q | grep "primary" | cut -d ' ' -f 1)
output "$primary_output is the primary output."

execute="xrandr --output $primary_output --auto"

i=0
for nonprimary_output in $(xrandr -q | grep " connected" | grep -v "primary" | cut -d ' ' -f 1); do
    output "$nonprimary_output is a non-primary, connected output."
    nonprimary_outputs="$nonprimary_outputs $nonprimary_output"
    if [[ $i == 0 ]]; then
        reference=$primary_output
    else
        reference=$last
    fi
    execute="$execute --output $nonprimary_output $position_command $reference --auto"
    last=$nonprimary_output
    i=$(( i+1 ))
done

# explicitly diable all disconnected outputs, necessary for example for i3 to notice
# the change
for disconnected_output in $(xrandr -q | grep " disconnected" | cut -d ' ' -f 1); do
    output "$disconnected_output is a disconnected_output."
    execute="$execute --output $disconnected_output --off"
done

output "Running constructed command:\n$execute"
xrandr_output="$($execute 2>&1)"
xrandr_exitcode=$?
if [[ ! $xrandr_exitcode == 0 ]]; then
    error "xrandr failed. output: \n$xrandr_output"
else
    output "Done."
fi
