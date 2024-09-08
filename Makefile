help: 
	# Snap.startr.cloud 
	#
	# This is the default make command. It will show you all the available make commands
	# If you haven't already we start by installing the development environment
	# `make a_dev_env`
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'

it_run:
	./_Build.sh && ./_Run.sh

this_dev_env:
	#make sure we have brew and docker installed
	brew --version || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	docker --version || brew install docker
	# shallow clone all submodules
	git submodule update --init --recursive --depth=2
	# setup git flow
	$(make) it_flow

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
	git branch master || \
	git branch -m main master || \
	git checkout master
	# TODO: set v as the version prefix
	git flow init -f

feature:
	# Ingest a feature name and save it to a variable we can access in feature_finish:
	git flow feature start $1

feature_finish:
	# Ingest a feature name and save it to a variable we can access in feature_finish:
	git flow feature finish $$(git branch --show-current)


minor_release:
	# Start a minor release with incremented minor version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2+1".0"}')

patch_release:
	# Start a patch release with incremented patch version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}')

major_release:
	# Start a major release with incremented major version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1+1".0.0"}')

hotfix:
	# Start a hotfix with incremented patch version
	git flow hotfix start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}')

release_finish:
	git flow release finish "$$(git branch --show-current | sed 's/release\///')" && git push origin develop && git push origin master && git push --tags && git checkout develop

hotfix_finish:
	git flow hotfix finish "$$(git branch --show-current | sed 's/hotfix\///')" && git push origin develop && git push origin master && git push --tags && git checkout develop

clean_git_repo:
	git clean --exclude=!.env -Xdf
