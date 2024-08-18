help: 
	# Snap.startr.cloud 
	#
	# This is the default make command. It will show you all the available make commands
	# If you haven't already we start by installing the development environment
	# `make a_dev_env`
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'

run:
	./_Build.sh && ./_Run.sh

amd64:
	# Build for amd64 architecture
	./Build.sh linux/amd64

apple:
	# Build for apple architecture
	./Build.sh linux/arm64/v8 

pi:
	# Build for raspberry pi architecture
	./Build.sh linux/arm/v7

it_publish:
	# Publish all our images to docker hub
	./Publish.sh

it_flow:
	git flow init

feature:
	# Injest a feature name and save it to a variable we can access in feature_finish:
	git flow feature start $1

feature_finish:
	# Injest a feature name and save it to a variable we can access in feature_finish:
	git flow feature finish $$(git branch --show-current)

minor_release:
	# Start a minor release with incremented minor version
	git flow release start $$(next_tag=$$(git describe --tags --abbrev=0 | awk -F'[v._]' '{print $$2"."$$3+1".0"}')._$$(date +'_%Y-%m-%d'); while git rev-parse "v$${next_tag}" >/dev/null 2>&1; do next_tag=$$(echo $${next_tag} | awk -F'[_]' '{print $$1"."$$2"."$$3+1"._"$${4}}'); done; echo v$${next_tag})

patch_release:
	# Start a patch release with incremented patch version
	git flow release start $$(next_tag=$$(git describe --tags --abbrev=0 | awk -F'[v._]' '{print $$2"."$$3"."$$4+1}')._$$(date +'_%Y-%m-%d'); while git rev-parse "v$${next_tag}" >/dev/null 2>&1; do next_tag=$$(echo $${next_tag} | awk -F'[_]' '{print $$1"."$$2"."$$3+1"._"$${4}}'); done; echo v$${next_tag})

major_release:
	# Start a major release with incremented major version
	git flow release start $$(next_tag=$$(git describe --tags --abbrev=0 | awk -F'[v._]' '{print $$2+1".0.0"}')._$$(date +'_%Y-%m-%d'); while git rev-parse "v$${next_tag}" >/dev/null 2>&1; do next_tag=$$(echo $${next_tag} | awk -F'[_]' '{print $$1"."$$2"."$$3+1"._"$${4}}'); done; echo v$${next_tag})

hotfix:
	# Start a hotfix with the same version but updated date
	git flow hotfix start $$(next_tag=$$(git describe --tags --abbrev=0 | awk -F'[v._]' '{print $$2"."$$3"."$$4}')._$$(date +'_%Y-%m-%d'); while git rev-parse "v$${next_tag}" >/dev/null 2>&1; do next_tag=$$(echo $${next_tag} | awk -F'[_]' '{print $$1"."$$2"."$$3+1"._"$${4}}'); done; echo v$${next_tag})

release_finish:
	git flow release finish "$$(git branch --show-current | sed 's/release\///')" && git push origin develop && git push origin master && git push --tags && git checkout develop

hotfix_finish:
	git flow hotfix finish "$$(git branch --show-current | sed 's/hotfix\///')" && git push origin develop && git push origin master && git push --tags && git checkout develop

clean_git_repo:
	git clean --exclude=!.env -Xdf
