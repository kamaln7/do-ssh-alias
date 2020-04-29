# 🎒 do-ssh-alias

**do-ssh-alias is a small bash script that generates SSH aliases for your Droplets based on their hostnames. For example, if you have a Droplet named `shiny.example.com`, this script will create aliases for `ssh shiny` and `ssh shiny.example.com`. The latter is useful if you need to log in using a different username than yours.**

For one-off uses, `doctl` has a `doctl compute ssh` command which is perfectly fine. The main difference is that `doctl` looks up the Droplet's IP address using the DigitalOcean API every time you run it, while do-ssh-alias generates a static config file that `ssh` reads. You might prefer do-ssh-alias if:

- you want an SSH config that can be copied to other computers without having to install doctl on them and log in with your account; or
- want to avoid the latency added by `doctl`'s API request to look up the IP address of the Droplet.

### dependencies
 - [doctl](https://github.com/digitalocean/doctl)
 - [jq](https://stedolan.github.io/jq/)

### installation

First, download the script [do-ssh-alias.sh](/do-ssh-alias.sh) and save it on your computer:

```
wget -O do-ssh-alias https://kmln.sr/do-ssh-alias.sh
```

Alternatively, download it using your browser. Then, set its permissions to allow it to be executed:

```
chmod +x do-ssh-alias
```

You can optionally move it to `/usr/local/bin` so that you can easily run it as `do-ssh-alias` in any directory:

```
sudo chown root:root do-ssh-alias
sudo chmod 755 /usr/local/bin/do-ssh-alias
sudo mv do-ssh-alias /usr/local/bin/do-ssh-alias
```

### usage

Make sure you are logged in with `doctl` (`doctl auth init`) and run:

```sh
do-ssh-alias > do_conf
```

You can then include this file in your SSH config:

`~/.ssh/config`
```ssh
Include /path/to/do_conf

...
```

#### available options

* Pass your SSH username using the `-u` option.
* To ignore certain Droplets, use the `-i` option.
* Pass a suffix with the `-s` option to generate additional aliases with said suffix stripped. See the example below.

```
do-ssh-alias -u user -i ignored-hostname -i ignored-hostname-2 -s .mydomain.com
```

### example output

Assuming you have the following Droplets on your account:

- `droplet1`
- `droplet2.domain.com`
- `droplet3.domain.com`

Running:

```sh
do-ssh-alias -u cucumber -i droplet1 -s .domain.com
```

will generate aliases for:

- `droplet2.domain.com`
- `droplet2`
- `droplet3.domain.com`
- `droplet3`

all using the username `cucumber`. The SSH config will look like:

```ssh
Host droplet2.domain.com droplet2
    Hostname (IP GOES HERE)
    User cucumber

Host droplet3.domain.com droplet3
    Hostname (IP GOES HERE)
    User cucumber
```
