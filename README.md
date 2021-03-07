# Zoneminder Container

Early release at directly compiling and installling Zoneminder from source in container.
This will be an AIO container running all services required by Zoneminder in a single container, managed by s6 overlay.


TODO:
- Fix symbolic linking in Zoneminder (causes ui to not load properly)
- Implement s6 overlay
- Install ZM Event Server
- Implement CI/CD

Considerations:
- Nginx
- Alpine
