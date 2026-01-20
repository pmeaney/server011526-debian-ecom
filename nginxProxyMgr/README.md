### Nginx Proxy Manager

- Access NPM admin panel at `http://<server-ip>:81`
  - Default credentials:
    - Username: admin@example.com
    - Password: changeme

Copied from here-- the npm & postgres services
https://nginxproxymanager.com/setup/

I added container_names.

```bash
# Copy the newest Nginx Proxy Manager config update via rsync

#### RUN FROM LAPTOP, at project root folder -- To transfer files to server

# If you setup your ssh config file via the 'generateTwoKeys' shells script--
rsync -avvz ./nginxProxyMgr/ debblue:~/nginxProxyMgr
# OR
# Via ssh user:
ITEM_1P="May 2025 Debian Server - 052225blue"
export LINUX_HUMAN_USERNAME=$(op item get ${ITEM_1P} --fields label=LINUX_HUMAN_USERNAME)
export LINUX_SERVER_IPADDRESS=$(op item get ${ITEM_1P} --fields label=LINUX_SERVER_IPADDRESS)
# use one one of these rsync commands.  
# the 1st resembles a basic ssh login-- user@ip
# the 2nd one depends on your ssh config file setup-- where debianServer1 is the hostname in a ~/.ssh/config file-- basically just shorthand.
rsync -avvz ./nginxProxyMgr/ "${LINUX_HUMAN_USERNAME}"@"${LINUX_SERVER_IPADDRESS}":~/nginxProxyMgr


# ssh into the server...
# ssh  "${LINUX_HUMAN_USERNAME}"@"${LINUX_SERVER_IPADDRESS}"
ssh debblue

#### RUN FROM SERVER -- To start up the Nginx Proxy Manager docker container
# This command is to Run in background, then check out logs.  It's a nice way to view the running container, while leaving it running after you exit the logs view.
cd nginxProxyMgr && \
docker compose -vvv -f docker-compose.yml up --build --remove-orphans -d && \
docker compose logs -f nginx-proxy-mgr-020325
```

## Creating Proxy Hosts

Now we're ready to setup access into the containers, from the public internet.

- Click into the Proxy Host section of Nginx Proxy Manager (running at http://yourServerIP:81 (that's http, not https!))
- In the upper right corner, click 'Add Proxy Host'.\*\*\*\*
- We'll only be working with two screens:
  - New Proxy Host - "Details" Tab
    - Default settings you can leave:
    - "Scheme: `http`" (it's set as default)
    - Set up your `Domain Name`, `Forward Hostname/IP`, and `Forward Port` as specified in the table below, or based on your own settings

#### Re: Http vs Https -- When we create these Nginx Proxy Mgr configurations ("Proxy Hosts"), we'll have it automatically request Let's Encrypt SSL certs for each domain or subdomain we create. So, these will all be accessed at https:// instead of http://

### Now for our domain definitions...

Note:

- Set `Forward Hostname / IP` to the Docker Engine's IP. You can find it by running this: `ip addr show docker0` (usually its 172.17.0.1)
- `Forward Port` is the application port, running in a docker container, depending on what app you've setup to run and its specified exposed ports.
- set 'block common exploits' to on.

- Somtimes NPM can be finnicky, especially after it starts up, or after you try to re-create certs with the same domain, but on a new server. Try again if there's an internal error with npm during its automatic lets encrypt cert attempts.

| Purpose        | Domain Name          | Forward Hostname / IP | Forward Port | Description                                             |
| -------------- | -------------------- | --------------------- | ------------ | ------------------------------------------------------- |
| Base Domain    | myDomainName.com     | 172.17.0.1            | 3000         | Main NextJS application running on Docker network       |
| WWW Subdomain  | www.myDomainName.com | 172.17.0.1            | 3000         | Standard www prefix pointing to main NextJS application |
| CMS Subdomain  | cms.myDomainName.com | 172.17.0.1            | 1337         | Access point for Strapi CMS administration              |
| DNS Management | dns.myDomainName.com | 172.17.0.1            | 81           | Nginx Proxy Manager administration interface            |

On the SSL Certificate Tab of "New Proxy Host",

- Request a new SSL certificate
- enter your email
- switch "I agree to the Lets Encrypt Terms of Service" to on.
- Click save.
- If it fails, try again.

OR

If you want to automate it...
use NPM's API

```bash
curl -X POST "http://npm-instance:81/api/tokens" \
  -H "Content-Type: application/json" \
  -d '{
    "identity": "admin@example.com",
    "secret": "changeme"
  }'
```

Below,
"force_ssl": true should trigger both SSL cert generation and HTTP to HTTPS redirection
...

nah looks like maybe its "forced_ssl" -- see npm schema json example:
https://github.com/NginxProxyManager/nginx-proxy-manager/blob/develop/backend/schema/common.json#L9

... nope... that doesnt seem to work either.

additonal example(s):
https://www.reddit.com/r/nginxproxymanager/comments/va0hjb/rest_api/?rdt=64435

# 2. Create proxy host (& request SSl cert for it)

```bash
curl -X POST "http://npm-instance:81/api/nginx/proxy-hosts" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain_names": ["cms.myDomainName.com"],
    "forward_scheme": "http",
    "forward_host": "172.17.0.1",
    "forward_port": 3000,
    "block_exploits": true,
    "certificate_id": null,
    "force_ssl": true,
    "meta": {
      "letsencrypt_agree": true,
      "dns_challenge": false
    },
    "advanced_config": "",
    "locations": [],
    "allow_websocket_upgrade": true,
    "http2_support": false,
    "enabled": true
}'

```
