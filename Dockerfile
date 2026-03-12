# Nicotine+ with Xpra - Full clipboard, audio, and proper window management
# Based on aandree5/gui-web-base for superior web GUI experience

FROM aandree5/gui-web-base:v1.1

LABEL org.opencontainers.image.authors="WB2024" \
      org.opencontainers.image.title="Nicotine+ with Xpra" \
      org.opencontainers.image.description="Nicotine+ Soulseek client with full clipboard support, audio forwarding, and proper UI via Xpra" \
      org.opencontainers.image.url="https://github.com/WB2024/WBs-Nictotineplusplus-docker" \
      org.opencontainers.image.source="https://github.com/WB2024/WBs-Nictotineplusplus-docker" \
      org.opencontainers.image.licenses="MIT"

# Nicotine+ specific environment variables
ENV NICOTINE_LOGIN="" \
    NICOTINE_PASSWORD="" \
    NICOTINE_AUTO_CONNECT="True" \
    NICOTINE_DARKMODE="True" \
    NICOTINE_UPNP="False" \
    NICOTINE_LISTEN_PORT="2234" \
    NICOTINE_DATA_DIR="/home/gwb/.local/share/nicotine" \
    NICOTINE_CONFIG_DIR="/home/gwb/.config/nicotine"

# Expose Nicotine+ listening port (default 2234)
EXPOSE 2234

# Install Nicotine+ and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    python3-gi \
    python3-gi-cairo \
    gir1.2-gtk-4.0 \
    gir1.2-adw-1 \
    gir1.2-gspell-1 \
    libgtk-4-bin \
    librsvg2-common \
    fonts-noto-cjk \
    gettext \
    && add-apt-repository -y ppa:nicotine-team/stable \
    && apt-get update \
    && apt-get install -y nicotine \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create Nicotine+ directories
RUN mkdir -p "${NICOTINE_CONFIG_DIR}" \
             "${NICOTINE_DATA_DIR}/plugins" \
             "${NICOTINE_DATA_DIR}/downloads" \
             "${NICOTINE_DATA_DIR}/incomplete" \
             "${NICOTINE_DATA_DIR}/received" \
    && chown -R gwb:gwb "${NICOTINE_CONFIG_DIR}" "${NICOTINE_DATA_DIR}"

# Copy configuration files and scripts
COPY --chown=gwb:gwb config/config-default "${NICOTINE_CONFIG_DIR}/config-default"
COPY --chmod=755 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=755 scripts/configure-nicotine.sh /usr/local/bin/configure-nicotine.sh

# Configure Xpra content-type mappings for Nicotine+
# This optimizes encoding for different window types
RUN configure-xpra \
    --content-type "class-instance:nicotine=text" \
    --content-type "title:Nicotine+=text"

# Use custom entrypoint to configure Nicotine+ before starting
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start Nicotine+ with Xpra
CMD ["start-app", "--title", "Nicotine+ (Xpra)", "nicotine", "--isolated"]
