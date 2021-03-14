# Zoneminder Container

<a href="https://github.com/zoneminder-addons/zoneminder-base/actions"><img alt="GitHub Actions Build" src="https://github.com/zoneminder-addons/zoneminder-base/actions/workflows/docker-build.yaml/badge.svg"></a>
<a href="https://hub.docker.com/r/yaoa/zoneminder-base"><img alt="Docker Hub Pulls" src="https://img.shields.io/docker/pulls/yaoa/zoneminder-base.svg"></a>

Early release at directly compiling and installling Zoneminder from source in container.
This will be an AIO container running all services required by Zoneminder in a single container, managed by s6 overlay.


TODO:
- Get finish scripts to output logs properly
- Go back to internal mariadb instead of external container?
- Install ZM Event Server
  
DONE:
- ~~Fix ZM install/file directories (set to unified mount dir)~~
- ~~Implement s6 overlay~~
- ~~Automatically tag and release new ZM versions~~
  - ~~PR file? Auto tag then build?~~
- ~~Implement CI/CD~~
- ~~Find way to parse control file to dynamically install deps (Need to install both Depends and Recommends)~~
    - ~~Consider writing python script to parse control file and output commands to a bash script~~

Considerations:
- Nginx
- Alpine
