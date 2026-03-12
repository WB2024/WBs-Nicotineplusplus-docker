#!/bin/bash

# Configuration script for Nicotine+
# Updates config file based on environment variables

CONFIG_FILE="${NICOTINE_CONFIG_DIR}/config"
CONFIG_DEFAULT="${NICOTINE_CONFIG_DIR}/config-default"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONFIG: $1"
}

# Import default config if none exists
if [ ! -f "$CONFIG_FILE" ]; then
    log "No existing config found, importing default configuration"
    cp "$CONFIG_DEFAULT" "$CONFIG_FILE"
    log "Default configuration imported"
fi

# Update login credentials
if [ -n "$NICOTINE_LOGIN" ]; then
    log "Setting Soulseek username"
    sed -i "s/^login = .*/login = ${NICOTINE_LOGIN}/" "$CONFIG_FILE"
fi

if [ -n "$NICOTINE_PASSWORD" ]; then
    log "Setting Soulseek password"
    sed -i "s/^passw = .*/passw = ${NICOTINE_PASSWORD}/" "$CONFIG_FILE"
fi

# Update connection settings
log "Configuring connection settings"
sed -i "s/^auto_connect_startup = .*/auto_connect_startup = ${NICOTINE_AUTO_CONNECT}/" "$CONFIG_FILE"
sed -i "s/^upnp = .*/upnp = ${NICOTINE_UPNP}/" "$CONFIG_FILE"

# Update listen port
if [ -n "$NICOTINE_LISTEN_PORT" ]; then
    log "Setting listen port to ${NICOTINE_LISTEN_PORT}"
    sed -i "s/^portrange = .*/portrange = (${NICOTINE_LISTEN_PORT}, ${NICOTINE_LISTEN_PORT})/" "$CONFIG_FILE"
fi

# Update UI settings
log "Configuring UI settings"
sed -i "s/^dark_mode = .*/dark_mode = ${NICOTINE_DARKMODE}/" "$CONFIG_FILE"

# Disable tray icon (doesn't work in web interface anyway)
if [ "${NICOTINE_TRAY_ICON:-False}" = "False" ]; then
    sed -i "s/^trayicon = .*/trayicon = False/" "$CONFIG_FILE"
fi

# Disable notifications (these cause popups in Xpra)
if [ "${NICOTINE_NOTIFY_FILE:-False}" = "False" ]; then
    sed -i "s/^notification_popup_file = .*/notification_popup_file = False/" "$CONFIG_FILE"
fi

if [ "${NICOTINE_NOTIFY_FOLDER:-False}" = "False" ]; then
    sed -i "s/^notification_popup_folder = .*/notification_popup_folder = False/" "$CONFIG_FILE"
fi

if [ "${NICOTINE_NOTIFY_TITLE:-False}" = "False" ]; then
    sed -i "s/^notification_window_title = .*/notification_window_title = False/" "$CONFIG_FILE"
fi

if [ "${NICOTINE_NOTIFY_PM:-False}" = "False" ]; then
    sed -i "s/^notification_popup_private_message = .*/notification_popup_private_message = False/" "$CONFIG_FILE"
fi

if [ "${NICOTINE_NOTIFY_CHATROOM:-False}" = "False" ]; then
    sed -i "s/^notification_popup_chatroom = .*/notification_popup_chatroom = False/" "$CONFIG_FILE"
fi

if [ "${NICOTINE_NOTIFY_MENTION:-False}" = "False" ]; then
    sed -i "s/^notification_popup_chatroom_mention = .*/notification_popup_chatroom_mention = False/" "$CONFIG_FILE"
fi

log "Nicotine+ configuration complete"
