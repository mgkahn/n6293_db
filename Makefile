.PHONY: build buildx-push buildx-nocache manifest buildfat check run debug push save clean clobber

# Default values for variables
REPO  ?= mgkahn/
NAME  ?= n6293_db
TAG   ?= latest
ARCH  := $$(arch=$$(uname -m); if [[ $$arch == "x86_64" ]]; then echo amd64; else echo $$arch; fi)
VOLUME=$(NAME)_vol
NETWORK=n6293_net
SHARED=Transfer_Station
PORT=3050
USER_ID=`id -u`
USER_NAME=`id -n -u`

ARCHS = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)


# Rebuild the container image and remove intermediary images
build: $(templates)
	docker build --tag $(REPO)$(NAME):$(TAG)-$(ARCH) .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

buildx-push: $(templates)
	docker buildx build --push --platform linux/amd64,linux/arm64 --tag $(REPO)$(NAME):$(TAG) .

buildx-nocache: $(templates)
	docker buildx build --push --no-cache --platform linux/amd64,linux/arm64 --tag $(REPO)$(NAME):$(TAG) .

# yarnpkg_pubkey.gpg :
# 	wget --output-document=yarnpkg_pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg

# Safe way to build multiarchitecture images:
# - build each image on the matching hardware, with the -$(ARCH) tag
# - push the architecture specific images to Dockerhub
# - build a manifest list referencing those images
# - push the manifest list so that the multiarchitecture image exist
manifest:
	docker manifest create $(REPO)$(NAME):$(TAG) $(IMAGES)
	@for arch in $(ARCHS); \
	 do \
	   echo docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	   docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	 done
	docker manifest push $(REPO)$(NAME):$(TAG)

rmmanifest:
	docker manifest rm $(REPO)$(NAME):$(TAG)

run:
	docker volume create ${VOLUME}
	
	## Only create network if it isn't present
	## FROM https://stackoverflow.com/questions/48643466/docker-create-network-should-ignore-existing-network
	## FOR WINDOWS/Powershell
	#
	# $networkName = "fb_net"
	#
	# if (docker network ls | select-string $networkName -Quiet )
	# {
	#     Write-Host "$networkName already created"
	# } else {
	#     docker network create $networkName
	# }

	## FOR LINUX.
	docker network inspect ${NETWORK} --format {{.Id}} 2>/dev/null || docker network create --driver bridge ${NETWORK}


	docker run -d --rm \
		--publish ${PORT}:${PORT} \
		--volume "${PWD}":/workspace:rw \
		--volume "${HOME}"/Desktop/${SHARED}:/desktop:rw \
		--volume ${VOLUME}:/firebird:rw \
		--env ISC_PASSWORD=nurs6293 \
		--env TZ=America/Denver \
		--network ${NETWORK} \
		--name ${NAME} \
	$(REPO)$(NAME):$(TAG)

debug:
	docker volume create ${VOLUME}
	
	## Only create network if it isn't present
	## FROM https://stackoverflow.com/questions/48643466/docker-create-network-should-ignore-existing-network
	## FOR WINDOWS/Powershell
	#
	# $networkName = "fb_net"
	#
	# if (docker network ls | select-string $networkName -Quiet )
	# {
	#     Write-Host "$networkName already created"
	# } else {
	#     docker network create $networkName
	# }

	## FOR LINUX.
	docker network inspect ${NETWORK} --format {{.Id}} 2>/dev/null || docker network create --driver bridge ${NETWORK}


	docker run -d --rm \
		--publish ${PORT}:${PORT} \
		--volume "${PWD}":/workspace:rw \
		--volume "${HOME}"/Desktop/${SHARED}:/desktop:rw \
		--volume ${VOLUME}:/firebird:rw \
		--env ISC_PASSWORD=nurs6293 \
		--env TZ=America/Denver \
		--network ${NETWORK} \
		--name ${NAME} \
	$(REPO)$(NAME):$(TAG)

	# Log into the container
	echo "Logging into ${NAME} Firebird container"
	docker exec -it ${NAME} /bin/bash

	
push:
	docker push $(REPO)$(NAME):$(TAG)-$(ARCH)

save:
	docker save $(REPO)$(NAME):$(TAG)-$(ARCH) | gzip > $(NAME)-$(TAG)-$(ARCH).tar.gz

clean:
	docker image prune -f

clobber:
	docker rmi $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$(ARCH)
	docker builder prune --all
