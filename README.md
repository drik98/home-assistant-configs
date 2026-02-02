# home-assistant-configs

This repository contains configs for my raspberry pi which runs home assistant as well as some other supporting tools.

## How to connect

Connect to the raspbi via ssh:

```bash
ssh hendrik@smarthome-pi.local
```

Note that the user here is `hendrik` and the hostname is `raspberrypi` this was configured when setting up the raspbi using [this guide](https://www.tim-kleyersburg.de/articles/home-assistant-with-docker-2022/). The password for `hendrik` should be available through 1password.

### Connect to the services Frontends

You can access Home Assistant in two ways:

1) Preferred: `homeassistant.sieweck.de` via the Cloudflared tunnel.
2) SSH tunnel for local-only access to multiple services (e.g. Home Assistant, other frontends):

```
ssh -L 8080:127.0.0.1:8080 -L 8123:127.0.0.1:8123 hendrik@smarthome-pi
```

Then open the services via `localhost` in your browser (e.g. `http://localhost:8123` for Home Assistant).

## Additional Configurations

The docker-compose.yml expects some environment variables to be set in order to work. This can be achieved by
creating an `.env`-file in the root of this repository. The necessary variables are:

- `CLOUDFLARE_TUNNEL_TOKEN`: The token created on cloudflare

## Docker IPv6 (required for Home Assistant Matter Hub)

We had to enable IPv6 for Docker on the Raspberry Pi because it is required by the Home Assistant Matter Hub Docker setup guide:
`https://riddix.github.io/home-assistant-matter-hub/installation/#id-2-1-docker-image`.

We followed this guide to enable Docker IPv6 with propagation:
`https://fariszr.com/docker-ipv6-setup-with-propagation/`.

We generated unique local IPv6 subnets via:
`https://simpledns.plus/private-ipv6` and chose non-overlapping prefixes for `fixed-cidr-v6`
and the IPv6 pool.

Example `/etc/docker/daemon.json` configuration on the Pi (replace with your generated ULA ranges):

```json
{
  "ipv6": true,
  "fixed-cidr-v6": "fdxx:xxxx:xxxx:xxxx::/64",
  "experimental": true,
  "ip6tables": true,
  "default-address-pools": [
    { "base": "172.17.0.0/16", "size": 16 },
    { "base": "172.18.0.0/16", "size": 16 },
    { "base": "172.19.0.0/16", "size": 16 },
    { "base": "172.20.0.0/14", "size": 16 },
    { "base": "172.24.0.0/14", "size": 16 },
    { "base": "172.28.0.0/14", "size": 16 },
    { "base": "192.168.0.0/16", "size": 20 },
    { "base": "fdxx:xxxx:xxxx:yyyy::/104", "size": 112 }
  ]
}
```

Note: When setting up a new Raspberry Pi, repeat this IPv6 configuration (and pick new subnets).

Also ensure the Docker network enables IPv6 in `docker-compose.yml`:

```yaml
networks:
  default:
    name: smarthome_net
    enable_ipv6: true
```

You may need to restart Docker and recreate the compose stack/network after these changes:

```bash
sudo systemctl restart docker
docker compose down
docker compose up -d
```

## Update Strategy

This system runs:

- Infrastructure services via **Docker Compose**
- The base operating system via **Linux packages (APT)**

Both layers must be updated regularly to receive:

- Security patches
- Bug fixes
- Compatibility updates

> **Recommended cadence:** roughly **once per month** or when security updates are announced.

---

### 🐳 Updating Docker Services

Docker containers do **not** update automatically.  
Updates must be done intentionally by updating image versions in the `docker-compose.yml` file.

#### 1️⃣ Update image versions

Edit the version tags in `docker-compose.yml`, for example:

```yaml
image: koenkk/zigbee2mqtt:1.42.0 → 1.43.1
```

---

#### 2️⃣ Pull the new images

```bash
docker compose pull
```

---

#### 3️⃣ Restart the services

```bash
docker compose up -d
```

This recreates containers using the new versions **without deleting persistent data**.

> ⚠️ **Do NOT use `docker compose down -v`**  
> The `-v` flag deletes volumes and may remove important data (e.g. Zigbee network, MQTT data, Home Assistant config).

---

#### 4️⃣ Verify services

Check logs after updates:

```bash
docker compose logs -f
```

Ensure:

- Home Assistant starts correctly
- Zigbee2MQTT connects to the coordinator
- MQTT broker is running
- No crash loops

---

### 🐧 Updating the Linux System

The underlying OS also requires regular updates.

---

#### 1️⃣ Refresh package lists

```bash
sudo apt update
```

---

#### 2️⃣ Review available updates

```bash
sudo apt list --upgradable
```

This shows what will change before installing updates.

---

#### 3️⃣ Install updates

```bash
sudo apt upgrade
```

This updates installed packages but does not remove anything.

---

#### 4️⃣ Reboot (if required)

If kernel, firmware, or low-level system components were updated, reboot:

```bash
sudo reboot
```

Reboots are typically required after:

- Kernel updates
- Raspberry Pi firmware updates
