# n6293_db

## Purpose:
This is one of two docker images used for NURS 6293 Introduction to Database Systems at the University of Colorado Anschutz Medical Campus College of Nursing (https://catalog.ucdenver.edu/cu-anschutz/courses-a-z/nurs/) as part of its Masters level Nursing Informatics program. This docker image provides RDBMS support using Firebird 3.0.10. The second image provides a Ubuntu front end running HTML-5 based NOVNC along with class-required DBMS applications. The image is multi-architecture for ARM64 and AARCH64.

## Core features:
- Dockerfile uses "builder" model using mgkahn/firebird3:latest on DockerHub. This is a simple clone of the FB 3.0.10 build by jacobalberty (https://github.com/jacobalberty/firebird-docker) altered only to support multi-architecture builds to support Apple Intel and Silcon Mac (and Windows). See https://github.com/mgkahn/Firebird3
- Image accepts all ENV variables described in https://github.com/jacobalberty/firebird-docker. 
- Image uses Docker-managed volume, named db_vol to persist the /firebird mount point which holds all FB databases (/firebird/data) and all configuration files (/firebird/etc).
- Image communicates with UI docker container via docker-compose network called n6293_net.
- FB server is access via "standard" port 3050. No encryption.
- FB server is initialized with initial `SYSDBA` password = `nurs6293`
- Any Firebird backup files (FBK) placed into databases-restore will be converted to FB 3.0.10 format and placed into /firebird/data. This is a feature implemented in jacobalberty image.
- Place Firebird databases to be used/persisted into databases folder
- Place FB configuration files into etc directory. These will be moved to /firebird/etc by docker-entrypoint.sh
  - Pre-defined Firebird database aliases are placed into etc/databases.conf. I have made no changes to firebird.conf, fbtrace.conf, plugins.conf
- FBD files used for NURS6293 are deidentified or synthetic. They are managed in GitHub using LFS (large file storage)

## To build Docker image:
- Make sure mgkahn/Firebird3:latest is still on DockerHub (should be multiarch). If not, pull https://github.com/mgkahn/Firebird3.git and create multiarch version of Firebird 3.0.10 and use that image as the builder container in Dockerfile
- Use Makefile commands:
  - Key variables for localization at top of Makefile
  - `make from-scratch`: uses --no-cache to create a pristine image **only on native architecture**
  - `make buildx-push`: creates multi-arch images and pushes to DockerHub. Includes manifest
  - `make buildx-nocache`: creates multi-arch images using --no-cache and pushes to DockerHub. Includes manifest
  - `make run`: Not really a build command but runs the newly created image with the following ENV variables set:
    - Publishes port 3050 to expose Firebird server API
    - Attaches current working directory to /workspace. Useful for moving files in/out of container during development. Not really needed during production.
    - Mounts /firebird to Docker-managed volume named db_vol. This is where data and config files are persisted across execution.
    - Sets sysdba password to nurs6293
    - Sets timezone to Denver
    - Sets internal network name to nurs6293_net
    - Sets image name

## To run:
- For a local image only: `make run`
- For an image based on DockerHub multiarch:
  - Mac: Run startCompose.sh (requires docker-compose.yml file in same directory) or run startCompose2.sh (embeds docker-compose.yml in script) from terminal window
  - MS Windows: startup script under construction

## TO DOs:
- Current shutdown is via `docker compose --abort-on-container-exit`. Would prefer to shutdown DBMS container when UI container is stopped using "shutdown" button on the GUI.  
  - `docker-entrypoint.sh` script has a `trap` on SIGTERM statement.
  - Need to figure out how to send UI container's SIGTERM over to DB container to trip the trap statement, which will shut down DB
  - Once working, can remove ugly --abort-on-container-exit hack
- Create desktop launchers for Mac and Windows so students do not need to execute a script.

## Construction points for me to remember:
- Cannot preinstall files into any directory that is a mount point at build time. When db_vol is mounted to /firebird at run_time, db_vol will "shadow" any files placed on /volume during build.
- Therefore, Dockerfile stages files destined for /firebird into /tmp (/tmp/databases, /tmp/restore, /tmp/etc), which is not a mount point.
- `docker-entrypoint.sh` moves files from /tmp to /volume in the startup script. See BEGIN MGK/END MGK block in `docker-entrypoint.sh` where this happens.
- This places the files on to the mounted drive, which is persisted across execution.
