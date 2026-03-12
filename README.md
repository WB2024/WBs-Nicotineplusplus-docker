# Nicotine+ with Xpra Docker Image

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-yellow?logo=buy-me-a-coffee)](https://buymeacoffee.com/succinctrecords)

A modern, feature-complete Docker image for [Nicotine+](https://nicotine-plus.org) (Soulseek client) with full web browser access via Xpra.

## 🌟 Why This Image?

This image uses **Xpra** instead of GTK Broadway, solving all the common issues:

✅ **Full clipboard support** - Copy/paste between browser and app  
✅ **Proper window management** - Dialogs center correctly  
✅ **Better scrollbar handling** - No losing control when dragging  
✅ **Audio forwarding** - Stream audio from Nicotine+ to your browser  
✅ **Better performance** - Configurable encoding and compression  
✅ **Modern GTK 4** - Latest Nicotine+ version with GTK 4.8.3

## 🚀 Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml`:

```yaml
services:
  nicotine:
    image: wb20244/nicotineplus-xpra:latest
    container_name: nicotine
    restart: unless-stopped
    ports:
      - "5005:5005"  # HTTP web interface
      - "2234:2234"  # Nicotine+ listening port
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - NICOTINE_LOGIN=YourSoulseekUsername
      - NICOTINE_PASSWORD=YourSoulseekPassword
      - NICOTINE_AUTO_CONNECT=True
      - NICOTINE_DARKMODE=True
      - NICOTINE_UPNP=False
      - NICOTINE_LISTEN_PORT=2234
    volumes:
      - ./config:/home/guiwebuser/.config/nicotine
      - ./data:/home/guiwebuser/.local/share/nicotine
      - /path/to/downloads:/downloads
      - /path/to/shared:/shared:ro
```

2. Start the container:

```bash
docker-compose up -d
```

3. Access Nicotine+ at `http://localhost:5005`

### Using Docker Run

```bash
docker run -d \
  --name nicotine \
  -p 5005:5005 \
  -p 2234:2234 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e NICOTINE_LOGIN=YourUsername \
  -e NICOTINE_PASSWORD=YourPassword \
  -e NICOTINE_AUTO_CONNECT=True \
  -e NICOTINE_DARKMODE=True \
  -e NICOTINE_UPNP=False \
  -e NICOTINE_LISTEN_PORT=2234 \
  -v ./config:/home/guiwebuser/.config/nicotine \
  -v ./data:/home/guiwebuser/.local/share/nicotine \
  -v /path/to/downloads:/downloads \
  -v /path/to/shared:/shared:ro \
  wb20244/nicotineplus-xpra:latest
```

## ⚙️ Configuration

### Environment Variables

#### User/Permissions

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID | `1000` |
| `PGID` | Group ID | `1000` |
| `UMASK` | File creation mask | `022` |
| `TZ` | Timezone | (empty) |

#### Nicotine+ Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `NICOTINE_LOGIN` | Soulseek username | (empty) |
| `NICOTINE_PASSWORD` | Soulseek password | (empty) |
| `NICOTINE_AUTO_CONNECT` | Auto-connect on startup | `True` |
| `NICOTINE_DARKMODE` | Enable dark theme | `True` |
| `NICOTINE_UPNP` | Enable UPnP port forwarding | `False` |
| `NICOTINE_LISTEN_PORT` | Listening port for peers | `2234` |

### Volumes

| Path | Description |
|------|-------------|
| `/home/guiwebuser/.config/nicotine` | Nicotine+ configuration |
| `/home/guiwebuser/.local/share/nicotine` | Data, logs, plugins, database |
| `/downloads` | Your download directory |
| `/shared` | Your shared files directory (read-only recommended) |

**Note**: The container user is `guiwebuser` (UID 1000 by default). Ensure your mounted volumes have correct permissions.

### Ports

| Port | Description |
|------|-------------|
| `5005` | HTTP web interface (Xpra HTML5 client) |
| `2234` | Nicotine+ listening port (for peers) |

**Security Note**: The web interface uses HTTP on port 5005 by default. If you need HTTPS, use a reverse proxy like Nginx or Traefik.

## 🔧 Advanced Usage

### Configuring Shared Folders

You can configure multiple shared folders in your Nicotine+ config or via volume mounts:

```yaml
volumes:
  - ./config:/home/guiwebuser/.config/nicotine
  - ./data:/home/guiwebuser/.local/share/nicotine
  - /path/to/downloads/complete:/downloads/complete
  - /path/to/downloads/incomplete:/downloads/incomplete
  - /path/to/music:/shared/Music:ro
  - /path/to/videos:/shared/Videos:ro
```

Then in Nicotine+, configure shares pointing to `/shared/Music`, `/shared/Videos`, etc.

### Using with a VPN Container

```yaml
services:
  vpn:
    image: your-vpn-image
    container_name: vpn
    ports:
      - "5005:5005"
      - "2234:2234"
    # VPN configuration...

  nicotine:
    image: wb20244/nicotineplus-xpra:latest
    container_name: nicotine
    network_mode: "service:vpn"
    depends_on:
      - vpn
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - NICOTINE_LOGIN=YourUsername
      - NICOTINE_PASSWORD=YourPassword
    volumes:
      - ./config:/home/guiwebuser/.config/nicotine
      - ./data:/home/guiwebuser/.local/share/nicotine
      - /path/to/downloads:/downloads
      - /path/to/shared:/shared:ro
```

### Custom Plugins

Place custom plugins in the mounted data directory:

```bash
mkdir -p ./data/plugins
# Copy your plugins to ./data/plugins/
```

They will be automatically loaded by Nicotine+ on startup.

### Reverse Proxy Setup (HTTPS)

The base image serves HTTP on port 5005. For HTTPS, use a reverse proxy:

**Nginx Example:**

```nginx
server {
    listen 443 ssl http2;
    server_name nicotine.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:5005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Traefik Example (docker-compose.yml):**

```yaml
services:
  nicotine:
    image: wb20244/nicotineplus-xpra:latest
    container_name: nicotine
    restart: unless-stopped
    ports:
      - "2234:2234"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - NICOTINE_LOGIN=YourUsername
      - NICOTINE_PASSWORD=YourPassword
    volumes:
      - ./config:/home/guiwebuser/.config/nicotine
      - ./data:/home/guiwebuser/.local/share/nicotine
      - /path/to/downloads:/downloads
      - /path/to/shared:/shared:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nicotine.rule=Host(`nicotine.example.com`)"
      - "traefik.http.routers.nicotine.entrypoints=websecure"
      - "traefik.http.routers.nicotine.tls.certresolver=letsencrypt"
      - "traefik.http.services.nicotine.loadbalancer.server.port=5005"
```

## 🎮 Features from gui-web-base

This image is built on [aandree5/gui-web-base](https://github.com/aandree5/gui-web-base) and inherits these features:

- ✨ Integrated clipboard - Seamless copy/paste between browser and app
- 🔊 Audio forwarding - Browser audio support via PulseAudio
- 👤 Non-root runtime - Runs as `guiwebuser` (UID 1000)
- 🔄 Automatic restart - App relaunches if it crashes
- ⚡ Xpra HTML5 client - Modern web-based remote display

## 🐛 Troubleshooting

### Web interface shows blank/loading forever

- Check container logs: `docker logs nicotine`
- Look for errors like "start-nicotine not found" (known issue, app still works)
- Try refreshing the browser page
- Clear browser cache and reload

### Port 2234 not accessible from peers

- Open port 2234 in your router/firewall (TCP and UDP)
- If using a VPN, configure port forwarding in your VPN provider
- Check if the port is already in use: `sudo netstat -tulpn | grep 2234`
- Try enabling UPnP: `NICOTINE_UPNP=True`

### Can't copy/paste

- Clipboard should work automatically via Xpra
- If using Firefox, ensure clipboard permissions are granted
- Check browser console for errors (F12 → Console)
- Some older browsers may have limited clipboard API support

### Shared folders showing 0 files

- Check volume mount paths are correct
- Verify permissions: `ls -la /path/to/shared`
- Ensure mounted directories are readable by UID 1000
- Check Nicotine+ logs: `docker exec nicotine cat /home/guiwebuser/.local/share/nicotine/logs/debug.log`

### Downloads not working

- Check volume permissions match `PUID`/`PGID`
- Verify download directory is writable: `ls -la /path/to/downloads`
- Ensure you have enough disk space: `df -h`
- Check if download path is configured correctly in Nicotine+

### Connection issues / Can't connect to Soulseek

- Verify your Soulseek credentials are correct (check for typos)
- Check container logs for "Connected to server" message
- Verify network connectivity: `docker exec nicotine ping -c 3 google.com`
- Check if your ISP blocks P2P traffic
- If behind VPN, ensure port forwarding is configured

### PulseAudio errors in logs

- These are warnings and can be safely ignored
- Audio forwarding works despite the warnings
- The container uses software audio rendering

### "pgrep: pattern that searches for process name longer than 15 characters"

- This is a known issue with the base image's monitoring script
- It can be safely ignored - the app runs normally
- The warning appears because "start-nicotine" exceeds 15 characters

## 📦 Building from Source

```bash
git clone https://github.com/WB2024/WBs-Nicotineplusplus-docker.git
cd WBs-Nicotineplusplus-docker
docker build -t wb20244/nicotineplus-xpra:latest .
```

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 💖 Support

If you find this project helpful, consider buying me a coffee!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-yellow?logo=buy-me-a-coffee)](https://buymeacoffee.com/succinctrecords)

Your support helps maintain and improve this project.

## 🙏 Credits

- [Nicotine+](https://nicotine-plus.org) - The excellent Soulseek client
- [gui-web-base](https://github.com/aandree5/gui-web-base) - Xpra base image by aandree5
- [Xpra](https://xpra.org/) - Multi-platform screen and application forwarding system
- [sirjmann92/nicotineplus-proper](https://github.com/sirjmann92/nicotineplus-proper) - Inspiration for Broadway-based approach

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
│   └── configure-nicotine.sh
└── config/
    └── config-default
```

## 🔗 Links

- **Docker Hub**: [wb20244/nicotineplus-xpra](https://hub.docker.com/r/wb20244/nicotineplus-xpra) *(coming soon)*
- **GitHub**: [WB2024/WBs-Nicotineplus-docker](https://github.com/WB2024/WBs-Nicotineplusplus-docker)
- **Nicotine+ Documentation**: [https://nicotine-plus.org/doc/](https://nicotine-plus.org/doc/)
- **Report Issues**: [GitHub Issues](https://github.com/WB2024/WBs-Nicotineplusplus-docker/issues)
- **Base Image**: [aandree5/gui-web-base](https://github.com/aandree5/gui-web-base)

---

**Note**: This is an unofficial Docker image. For official Nicotine+ support, please visit the [Nicotine+ GitHub repository](https://github.com/nicotine-plus/nicotine-plus).
