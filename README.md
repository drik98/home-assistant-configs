# home-assistant-configs

This repository contains configs for my raspberry pi which runs home assistant as well as some other supporting tools.

## How to connect

Connect to the raspbi via ssh:

```bash
ssh hendrik@raspberrypi.local
```

Note that the user here is `hendrik` and the hostname is `raspberrypi` this was configured when setting up the raspbi using [this guide](https://www.tim-kleyersburg.de/articles/home-assistant-with-docker-2022/). The password for `hendrik` should be available through 1password.

## Additional Configurations

The docker-compose.yml expects some environment variables to be set in order to work. This can be achieved by
creating an `.env`-file in the root of this repository. The necessary variables are:

- `CLOUDFLARE_TUNNEL_TOKEN`: The token created on cloudflare
