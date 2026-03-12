# Nicotine+ with Xpra Docker Image

A modern, feature-complete Docker image for [Nicotine+](https://nicotine-plus.org) (Soulseek client) with full web browser access via Xpra.

## 🌟 Why This Image?

This image uses **Xpra** instead of GTK Broadway, solving all the common issues:

✅ **Full clipboard support** - Copy/paste between browser and app  
✅ **Proper window management** - Dialogs center correctly  
✅ **Better scrollbar handling** - No losing control when dragging  
✅ **Audio forwarding** - Stream audio from Nicotine+ to your browser  
✅ **HTTPS by default** - Secure connections with automatic SSL  
✅ **Better performance** - Configurable encoding and compression  

## 🚀 Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml`:

```yaml
services:
  nicotine:
    image: wb2024/nicotineplus-xpra:latest
    container_name: nicotine
    restart: unless-stopped
    ports:
      - "5443:5443"  # HTTPS web interface
      - "2234:2234"  # Nicotine+ listening port
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - NICOTINE_LOGIN=YourSoulseekUsername
      - NICOTINE_PASSWORD=YourSoulseekPassword
    volumes:
      - ./data/config:/home/gwb/.config/nicotine
      - ./data/share:/home/gwb/.local/share/nicotine
      - /path/to/downloads:/downloads
      - /path/to/shared:/shared
```

2. Start the container:

```bash
docker-compose up -d
```

3. Access Nicotine+ at `https://localhost:5443`

### Using Docker Run

```bash
docker run -d \
  --name nicotine \
  -p 5443:5443 \
  -p 2234:2234 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e NICOTINE_LOGIN=YourUsername \
  -e NICOTINE_PASSWORD=YourPassword \
  -v ./data/config:/home/gwb/.config/nicotine \
  -v ./data/share:/home/gwb/.local/share/nicotine \
  -v /path/to/downloads:/downloads \
  -v /path/to/shared:/shared \
  wb2024/nicotineplus-xpra:latest
```

## ⚙️ Configuration

### Environment Variables

#### User/Permissions

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID | `1000` |
| `PGID` | Group ID | `1000` |
| `UMASK` | File creation mask | `022` |

#### Nicotine+ Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `NICOTINE_LOGIN` | Soulseek username | (empty) |
| `NICOTINE_PASSWORD` | Soulseek password | (empty) |
| `NICOTINE_AUTO_CONNECT` | Auto-connect on startup | `True` |
| `NICOTINE_DARKMODE` | Enable dark theme | `True` |
| `NICOTINE_UPNP` | Enable UPnP port forwarding | `False` |
| `NICOTINE_LISTEN_PORT` | Listening port for peers | `2234` |

#### Web Interface

| Variable | Description | Default |
|----------|-------------|---------|
| `ALLOW_HTTP` | Allow HTTP access (for reverse proxy) | `false` |
| `TZ` | Timezone | (empty) |

### Volumes

| Path | Description |
|------|-------------|
| `/home/gwb/.config/nicotine` | Nicotine+ configuration |
| `/home/gwb/.local/share/nicotine` | Data, logs, plugins, database |
| `/downloads` | Your download directory |
| `/shared` | Your shared files directory |

### Ports

| Port | Description |
|------|-------------|
| `5443` | HTTPS web interface |
| `5000` | HTTP web interface (if `ALLOW_HTTP=true`) |
| `2234` | Nicotine+ listening port (for peers) |

## 🔧 Advanced Usage

### Using with a VPN Container

```yaml
services:
  nicotine:
    image: wb2024/nicotineplus-xpra:latest
    network_mode: "container:vpn-container-name"
    # Remove ports mapping - use VPN container's ports
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - NICOTINE_LOGIN=YourUsername
      - NICOTINE_PASSWORD=YourPassword
    volumes:
      - ./data/config:/home/gwb/.config/nicotine
      - ./data/share:/home/gwb/.local/share/nicotine
      - /path/to/downloads:/downloads
      - /path/to/shared:/shared
```

### Custom Plugins

Place custom plugins in the mounted data directory:

```bash
mkdir -p ./data/share/plugins
# Copy your plugins to ./data/share/plugins/
```

They will be automatically loaded by Nicotine+ on startup.

### Reverse Proxy Setup

If using a reverse proxy (Nginx, Traefik, Caddy):

1. Enable HTTP mode: `ALLOW_HTTP=true`
2. Configure WebSocket support in your proxy (required for Xpra)

Example Nginx config:

```nginx
location / {
    proxy_pass http://container-ip:5000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

## 🎮 Features from gui-web-base

This image inherits all features from [aandree5/gui-web-base](https://github.com/aandree5/gui-web-base):

- ✨ Integrated clipboard - Seamless copy/paste
- 🔊 Audio forwarding - Browser audio support
- 🔒 HTTPS by default - Secure connections
- 👤 Non-root runtime - Enhanced security
- 🔄 Automatic restart - Apps relaunch when closed
- ⚡ Configurable encoding - Tune for bandwidth/quality

## 🐛 Troubleshooting

### Port 2234 not accessible

- Open port 2234 in your router/firewall
- If using a VPN, configure port forwarding in your VPN provider
- Check if the port is already in use: `sudo netstat -tulpn | grep 2234`

### Can't copy/paste

- This should work out of the box! If not, check browser console for errors
- Ensure you're using HTTPS (clipboard API requires secure context)
- Try using Firefox or Chrome (clipboard support varies by browser)

### Downloads not working

- Check volume permissions match `PUID`/`PGID`
- Verify download directory is writable: `ls -la /path/to/downloads`
- Ensure you have enough disk space

### Connection issues

- Verify your Soulseek credentials are correct
- Check if your ISP blocks P2P ports
- Consider using UPnP (`NICOTINE_UPNP=True`) or manual port forwarding
- If behind VPN, ensure port forwarding is configured in your VPN provider

### Web interface won't load

- Check container logs: `docker logs nicotine`
- Verify port 5443 isn't blocked by firewall
- Try accessing via HTTP (port 5000) with `ALLOW_HTTP=true`

## 📦 Building from Source

```bash
git clone https://github.com/WB2024/WBs-Nicotineplus-docker.git
cd WBs-Nicotineplus-docker
docker build -t nicotineplus-xpra .
```

### Build Arguments

You can customize the build with these arguments:

```bash
docker build \
  --build-arg BASE_IMAGE=aandree5/gui-web-base:v1.1 \
  -t nicotineplus-xpra .
```

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Credits

- [Nicotine+](https://nicotine-plus.org) - The Soulseek client
- [gui-web-base](https://github.com/aandree5/gui-web-base) - Xpra base image by Aandree5
- [sirjmann92/nicotineplus-proper](https://github.com/sirjmann92/nicotineplus-proper) - Inspiration for configuration approach
- [Xpra](https://xpra.org/) - Remote display technology

## 🤝 Contributing

Issues and pull requests welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📊 Project Structure

```
WBs-Nicotineplus-docker/
├── Dockerfile
├── docker-compose.yml
├── README.md
├── LICENSE
├── .gitignore
├── .dockerignore
├── scripts/
│   ├── entrypoint.sh
│   └── configure-nicotine.sh
└── config/
    └── config-default
```

## 🔗 Links

- **Docker Hub**: [wb2024/nicotineplus-xpra](https://hub.docker.com/r/wb2024/nicotineplus-xpra)
- **GitHub**: [WB2024/WBs-Nicotineplus-docker](https://github.com/WB2024/WBs-Nicotineplus-docker)
- **Nicotine+ Documentation**: [https://nicotine-plus.org/doc/](https://nicotine-plus.org/doc/)
- **Report Issues**: [GitHub Issues](https://github.com/WB2024/WBs-Nicotineplus-docker/issues)

---

**Note**: This is an unofficial Docker image. For official Nicotine+ support, please visit the [Nicotine+ GitHub repository](https://github.com/nicotine-plus/nicotine-plus).
