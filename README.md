# remnanode install script

### without custom port:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY"
```
### with custom port:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY" --p 4252
```
### with sysctl settings:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY" --s
```
### with TrafficGuard (inbound ports separated by :):
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY" --tg 443:8443:2083
```
### with NodeProtect (allowed IPs for node port separated by :):
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY" --np 1.2.3.4:5.6.7.8
```
### all options combined:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/JorikSmith/remnanode_install_script/refs/heads/main/install.sh) --sk "SECRET_KEY" --p 6666 --s --tg 443:8443:2083 --np 1.2.3.4:5.6.7.8
```
