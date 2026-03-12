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

# Xpra display settings - FORCE RGB for quality
ENV DISPLAY_WIDTH="1920" \
    DISPLAY_HEIGHT="1080" \
    XPRA_ENCODING="rgb" \
    XPRA_QUALITY="100" \
    XPRA_SPEED="100" \
    XPRA_COMPRESSION="0"

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

# Create wrapper script that configures then launches nicotine
RUN echo '#!/bin/bash' > /usr/local/bin/start-nicotine && \
    echo 'set -e' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Configure Nicotine+ settings' >> /usr/local/bin/start-nicotine && \
    echo '/usr/local/bin/configure-nicotine.sh' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Set display' >> /usr/local/bin/start-nicotine && \
    echo 'export DISPLAY=:100' >> /usr/local/bin/start-nicotine && \
    echo '' >> /usr/local/bin/start-nicotine && \
    echo '# Launch Nicotine+' >> /usr/local/bin/start-nicotine && \
    echo 'exec nicotine --isolated' >> /usr/local/bin/start-nicotine && \
    chmod +x /usr/local/bin/start-nicotine

# Override base image start script with custom Xpra options
RUN echo '#!/bin/bash' > /usr/local/bin/start-xpra-custom && \
    echo 'set -e' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Encoding settings' >> /usr/local/bin/start-xpra-custom && \
    echo 'ENCODING="${XPRA_ENCODING:-rgb}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'QUALITY="${XPRA_QUALITY:-100}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'SPEED="${XPRA_SPEED:-100}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'COMPRESSION="${XPRA_COMPRESSION:-0}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'WIDTH="${DISPLAY_WIDTH:-1920}"' >> /usr/local/bin/start-xpra-custom && \
    echo 'HEIGHT="${DISPLAY_HEIGHT:-1080}"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo 'export XDG_RUNTIME_DIR="/home/guiwebuser/.xdg"' >> /usr/local/bin/start-xpra-custom && \
    echo 'mkdir -p "$XDG_RUNTIME_DIR"' >> /usr/local/bin/start-xpra-custom && \
    echo 'chmod 700 "$XDG_RUNTIME_DIR"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo 'mkdir -p /home/guiwebuser/.xpra' >> /usr/local/bin/start-xpra-custom && \
    echo 'chmod 700 /home/guiwebuser/.xpra' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Start PulseAudio' >> /usr/local/bin/start-xpra-custom && \
    echo 'pulseaudio --start --exit-idle-time=-1 --log-level=error --disallow-exit 2>/dev/null || true' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo 'echo "[XPRA] Starting with encoding=$ENCODING, quality=$QUALITY, speed=$SPEED, compression=$COMPRESSION"' >> /usr/local/bin/start-xpra-custom && \
    echo '' >> /usr/local/bin/start-xpra-custom && \
    echo '# Start Xpra with RGB-only encoding' >> /usr/local/bin/start-xpra-custom && \
    echo 'exec xpra start :100 \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --bind-tcp=0.0.0.0:5005 \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --html=on \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --daemon=no \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --exit-with-children=no \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --mdns=no \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --webcam=no \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --socket-dir="/home/guiwebuser/.xpra" \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --session-name=nicotine \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --window-close=ignore \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --encoding="$ENCODING" \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --quality="$QUALITY" \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --speed="$SPEED" \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --compression="$COMPRESSION" \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --desktop-scaling=off \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --video-encoders=none \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --csc-modules=none \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --video-decoders=none \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --encodings=rgb,rgb32 \' >> /usr/local/bin/start-xpra-custom && \
    echo '  --start="/usr/local/bin/start-nicotine"' >> /usr/local/bin/start-xpra-custom && \
    chmod +x /usr/local/bin/start-xpra-custom

# Switch back to guiwebuser
USER guiwebuser

# Use our custom wrapper
CMD ["/usr/local/bin/start-xpra-custom"]
