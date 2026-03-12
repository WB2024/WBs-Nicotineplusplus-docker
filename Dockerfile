# Nicotine+ with Xpra - Full clipboard, audio, and proper window management
# Based on aandree5/gui-web-base for superior web GUI experience

FROM aandree5/gui-web-base:v1.1

LABEL org.opencontainers.image.authors="WB2024" \
      org.opencontainers.image.title="Nicotine+ with Xpra" \
      org.opencontainers.image.description="Nicotine+ Soulseek client with full clipboard support, audio forwarding, and proper UI via Xpra" \
      org.opencontainers.image.url="https://github.com/WB2024/WBs-Nicotineplusplus-docker" \
      org.opencontainers.image.source="https://github.com/WB2024/WBs-Nicotineplusplus-docker" \
      org.opencontainers.image.licenses="MIT"

# Switch to root for installations
USER root

# Nicotine+ specific environment variables
ENV NICOTINE_LOGIN="" \
    NICOTINE_PASSWORD="" \
    NICOTINE_AUTO_CONNECT="True" \
    NICOTINE_DARKMODE="True" \
    NICOTINE_UPNP="False" \
    NICOTINE_LISTEN_PORT="2234" \
    NICOTINE_TRAY_ICON="False" \
    NICOTINE_NOTIFY_FILE="False" \
    NICOTINE_NOTIFY_FOLDER="False" \
    NICOTINE_NOTIFY_TITLE="False" \
    NICOTINE_NOTIFY_PM="False" \
    NICOTINE_NOTIFY_CHATROOM="False" \
    NICOTINE_NOTIFY_MENTION="False" \
    NICOTINE_DATA_DIR="/home/guiwebuser/.local/share/nicotine" \
    NICOTINE_CONFIG_DIR="/home/guiwebuser/.config/nicotine"

# Xpra display settings
ENV DISPLAY_WIDTH="1920" \
    DISPLAY_HEIGHT="1080" \
    XPRA_ENCODING="auto" \
    XPRA_QUALITY="auto" \
    XPRA_SPEED="auto" \
    XPRA_COMPRESSION="auto"

# Expose Nicotine+ listening port (default 2234)
EXPOSE 2234

# Install Nicotine+ dependencies and build from PyPI
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-gi \
    python3-gi-cairo \
    python3-pip \
    gir1.2-gtk-4.0 \
    gir1.2-adw-1 \
    gir1.2-gspell-1 \
    libgtk-4-bin \
    librsvg2-common \
    fonts-noto-cjk \
    gettext \
    git \
    && pip3 install --break-system-packages nicotine-plus \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create Nicotine+ directories with correct permissions (user guiwebuser, uid 1000)
RUN mkdir -p "${NICOTINE_CONFIG_DIR}" \
             "${NICOTINE_DATA_DIR}/plugins" \
             "${NICOTINE_DATA_DIR}/downloads" \
             "${NICOTINE_DATA_DIR}/incomplete" \
             "${NICOTINE_DATA_DIR}/received" \
    && chown -R 1000:1000 "${NICOTINE_CONFIG_DIR}" "${NICOTINE_DATA_DIR}"

# Copy configuration files
COPY --chown=1000:1000 config/config-default "${NICOTINE_CONFIG_DIR}/config-default"
COPY --chmod=755 scripts/configure-nicotine.sh /usr/local/bin/configure-nicotine.sh

# Create wrapper script that configures then launches nicotine with display settings
RUN echo '#!/bin/bash' > /usr/local/bin/start-nicotine && \
    echo 'set -e' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Configure Nicotine+ settings' >> /usr/local/bin/start-nicotine && \
    echo '/usr/local/bin/configure-nicotine.sh' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Set display resolution' >> /usr/local/bin/start-nicotine && \
    echo 'export DISPLAY=:100' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Launch Nicotine+' >> /usr/local/bin/start-nicotine && \
    echo 'exec nicotine --isolated' >> /usr/local/bin/start-nicotine && \
    chmod +x /usr/local/bin/start-nicotine

# Create custom Xpra start wrapper with configurable settings
RUN echo '#!/bin/bash' > /usr/local/bin/start-xpra-custom && \
    echo 'set -e' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Default to auto if not set' >> /usr/local/bin/start-xpra-custom && \
    echo 'ENCODING="${XPRA_ENCODING:-auto}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'QUALITY="${XPRA_QUALITY:-auto}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'SPEED="${XPRA_SPEED:-auto}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'COMPRESSION="${XPRA_COMPRESSION:-auto}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'WIDTH="${DISPLAY_WIDTH:-1920}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'HEIGHT="${DISPLAY_HEIGHT:-1080}"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Build Xpra command with options' >> /usr/local/bin/start-xpra-custom && \
    echo 'XPRA_OPTS="--encoding=${ENCODING}"' >> /usr/local/bin/start-xpra-custom && \
    echo '[ "$QUALITY" != "auto" ] && XPRA_OPTS="$XPRA_OPTS --quality=${QUALITY}"' >> /usr/local/bin/start-xpra-custom && \
    echo '[ "$SPEED" != "auto" ] && XPRA_OPTS="$XPRA_OPTS --speed=${SPEED}"' >> /usr/local/bin/start-xpra-custom && \
    echo '[ "$COMPRESSION" != "auto" ] && XPRA_OPTS="$XPRA_OPTS --compression=${COMPRESSION}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'XPRA_OPTS="$XPRA_OPTS --resize-display=${WIDTH}x${HEIGHT}"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo 'echo "[XPRA] Starting with: $XPRA_OPTS"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Call base image start script with our app and Xpra options' >> /usr/local/bin/start-xpra-custom && \
    echo 'export XPRA_OPTIONS="$XPRA_OPTS"' >> /usr/local/bin/start-xpra-custom && \
    echo 'exec /usr/local/bin/start /usr/local/bin/start-nicotine' >> /usr/local/bin/start-xpra-custom && \
    chmod +x /usr/local/bin/start-xpra-custom

# Switch back to guiwebuser
USER guiwebuser

# Use our custom Xpra wrapper
CMD ["/usr/local/bin/start-xpra-custom"]
