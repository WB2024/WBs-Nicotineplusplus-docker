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
    NICOTINE_DATA_DIR="/home/guiwebuser/.local/share/nicotine" \
    NICOTINE_CONFIG_DIR="/home/guiwebuser/.config/nicotine"

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
    echo '/usr/local/bin/configure-nicotine.sh' >> /usr/local/bin/start-nicotine && \
    echo 'exec nicotine --isolated' >> /usr/local/bin/start-nicotine && \
    chmod +x /usr/local/bin/start-nicotine

# Switch back to guiwebuser
USER guiwebuser

# Use the base image's start script, passing our nicotine wrapper
CMD ["start", "/usr/local/bin/start-nicotine"]
