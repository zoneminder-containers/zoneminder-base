# Zoneminder Container

<a href="https://github.com/zoneminder-addons/zoneminder-base/actions"><img alt="GitHub Actions Build" src="https://github.com/zoneminder-addons/zoneminder-base/actions/workflows/docker-build.yaml/badge.svg"></a>
<a href="https://hub.docker.com/r/yaoa/zoneminder-base"><img alt="Docker Hub Pulls" src="https://img.shields.io/docker/pulls/yaoa/zoneminder-base.svg"></a>

Early release at directly compiling and installling Zoneminder from source in container.
This will be an AIO container running all services required by Zoneminder in a single container, managed by s6 overlay.


TODO:
- Replace Apache2 with Nginx + php-fpm + php-fpm optimizations
- Figure out correct sql commands to automate multiserver support

  
DONE:
- ~~Go back to internal mariadb instead of external container~~ (will not do for multi-server support)
- ~~Get finish scripts to output logs properly~~
- ~~Fix ZM install/file directories (set to unified mount dir)~~
- ~~Implement s6 overlay~~
- ~~Automatically tag and release new ZM versions~~
  - ~~PR file? Auto tag then build?~~
- ~~Implement CI/CD~~
- ~~Find way to parse control file to dynamically install deps (Need to install both Depends and Recommends)~~
    - ~~Consider writing python script to parse control file and output commands to a bash script~~

Future Containers:
1. 
- Install ZM Event Server
- Automatically enable Event Server and modify Servers table entry to enable Event Server

2. Builds off 1
- Install YOLO ML Models without opencv

3.1. Builds off 2
- Build and install standard opencv

3.2. Builds off 2
- Develop autobuilding opencv with cuda support container

Considerations:
- Alpine
