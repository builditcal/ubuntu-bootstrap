# ubuntu-bootstrap
Simple Script that should remove all bloat and install the necessary apps that I (and potentially others) need.

```bash
curl -o- https://raw.githubusercontent.com/builditcal/ubuntu-bootstrap/refs/heads/24.04/start.sh | bash -s -- \
    --debs "vscode,chrome,docker,dbeaver" \
    --flatpaks "bitwarden,cura"
```