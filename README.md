Docker infra repository (demo functional, TP-ready)
================================================

Structure:
  - livraison.sh             # installs Docker + compose and deploys stacks (run with sudo)
  - monitoring/              # Zabbix stack (MySQL + Zabbix server + web (nginx) + agent)
  - administration/          # Portainer stack
  - developpement/          # GitLab CE stack (demo ports)
  - production/              # EspoCRM + AWX (demo) + Vault (dev mode)

Notes:
  - Designed for Debian 12 or 13 (script uses get.docker.com convenience script).
  - Network: all stacks join Docker network 'infra-net' so services can talk to each other.
  - The compose files are meant for demo/teaching use; **do not** use these credentials in production.
  - To deploy: unzip, cd into the repo, then run:
        sudo ./livraison.sh
    Use --no-start to only install Docker without starting services.

