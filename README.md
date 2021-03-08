# Zoneminder Container

Early release at directly compiling and installling Zoneminder from source in container.
This will be an AIO container running all services required by Zoneminder in a single container, managed by s6 overlay.


TODO:
- Implement s6 overlay
- Install ZM Event Server
- Fix ZM install/file directories (set to unified mount dir)
  
DONE:
- ~~Implement CI/CD~~
- ~~Find way to parse control file to dynamically install deps (Need to install both Depends and Recommends)~~
    - ~~Consider writing python script to parse control file and output commands to a bash script~~

Considerations:
- Nginx
- Alpine
