#!/bin/sh

# AeroSpace.app doesn't inherit the interactive shell's Homebrew PATH.
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
export PATH
unset AEROSPACE_WINDOW_ID AEROSPACE_WORKSPACE

destination=${1:-}

current_workspace=$(aerospace list-workspaces --focused --format '%{workspace}')
current_monitor=$(aerospace list-workspaces --focused --format '%{monitor-id}')

case "$destination" in
    [1-9])
        target_workspace=$destination
        ;;
    prev|next)
        monitor_count=$(aerospace list-monitors --count)
        case "$current_monitor" in ''|*[!0-9]*) exit 1 ;; esac
        case "$monitor_count" in ''|*[!0-9]*) exit 1 ;; esac
        [ "$monitor_count" -gt 1 ] || exit 0

        if [ "$destination" = next ]; then
            target_monitor=$((current_monitor % monitor_count + 1))
        else
            target_monitor=$(( (current_monitor + monitor_count - 2) % monitor_count + 1 ))
        fi

        target_workspace=$(
            aerospace list-workspaces --monitor "$target_monitor" --visible \
                --format '%{workspace}'
        )
        [ -n "$target_workspace" ] || exit 1
        ;;
    *) exit 2 ;;
esac

target_monitor=$(
    aerospace list-workspaces --all --format '%{workspace}|%{monitor-id}' |
        awk -F '|' -v workspace="$target_workspace" '$1 == workspace { print $2; exit }'
)

[ "$current_workspace" = "$target_workspace" ] && exit 0

# Workspaces on the same monitor only need a regular switch.
if [ -z "$target_monitor" ] || [ "$current_monitor" = "$target_monitor" ]; then
    aerospace workspace "$target_workspace"
    exit
fi

# Exchange monitor assignments first, then explicitly reveal each workspace on
# its destination monitor. Selecting the monitor before `workspace` avoids the
# history-dependent focus behavior of AeroSpace 0.20.
aerospace move-workspace-to-monitor --workspace "$target_workspace" "$current_monitor"
aerospace move-workspace-to-monitor --workspace "$current_workspace" "$target_monitor"
aerospace focus-monitor "$target_monitor"
aerospace workspace "$current_workspace"
aerospace focus-monitor "$current_monitor"
aerospace workspace "$target_workspace"
sleep 0.2
aerospace focus-monitor "$current_monitor"
