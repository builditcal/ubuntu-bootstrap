# Welcome to Ubuntu Bootstrap

## An opinionated single script that sets up and new (or existing) Ubuntu Distro.

## Ubuntu 24.04 Eg:
```bash
curl -o- https://raw.githubusercontent.com/builditcal/ubuntu-bootstrap/refs/heads/main/24.04.sh | bash -s -- \
    --debs "vscode,chrome,docker,dbeaver" \
    --flatpaks "bitwarden,cura" \
    --debloat yes \
    --neaten yes \
    --apt_install "htop,aria2" \
    --theme dark
```