#!/bin/bash

# Copyright (C) 2021 Neal Gompa
#
# Fedora-License-Identifier: MIT
# SPDX-2.0-License-Identifier: MIT
# SPDX-3.0-License-Identifier: MIT
#
# This program is free software.
# For more information on free software, see
# <https://www.gnu.org/philosophy/free-sw.en.html>.

# This script rewrites SDDM configuration to switch from Wayland to X11 in the event
# Plasma Wayland session is not desired.


# Determine whether Plasma Wayland is the default session
WAYLAND_DEFAULT=1
X11_SESSION_NAME="plasmax11.desktop"

if [ -f "/usr/share/xsessions/plasma.desktop" ]; then
	# We're in a world before Plasma Wayland is default
	WAYLAND_DEFAULT=0
	X11_SESSION_NAME="plasma.desktop"
fi

# If autologin is configured, force back to X11 session
if [ -f "/etc/sddm.conf" ]; then
	sed -e "s|^Session=plasma.*|Session=${X11_SESSION_NAME}|" -i /etc/sddm.conf
fi

# If previous session was Wayland, set it to X11 now
if [ -f "/var/lib/sddm/state.conf" ]; then
	sed -e "s|^Session=/usr/share/wayland-sessions/plasma.*|Session=/usr/share/xsessions/${X11_SESSION_NAME}|" -i /var/lib/sddm/state.conf
fi
