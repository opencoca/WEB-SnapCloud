help: 
	# Snap.startr.cloud 
	#
	# This is the default make command. It will show you all the available make commands
	# If you haven't already we start by installing the development environment
	# `make a_dev_env`
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'

run:
	./Build.sh && ./Run.sh

it_flow:
	git flow init

feature:
	# Injest a feature name and save it to a variable we can access in feature_finish:
	git flow feature start
	# TODO injest and save $feature_name to a variable that stays accessable between reboots until feature_finish is called

feature_finish:
	# Injest a feature name and save it to a variable we can access in feature_finish:
	git flow feature finish $(feature_name)
	# TODO injest  $feature_name from a variable that stays accessable between reboots until feature_finish is called

minor_release:
	git flow release start $$(git describe --tags --abbrev=0 | awk -F'[v.]' '{print $$2"."$$3+1".0"}').$$(date +'_%Y-%m-%d')

patch_release:
	git flow release start $$(git describe --tags --abbrev=0 | awk -F'[v.]' '{print $$2"."$$3"."$$4+1}').$$(date +'_%Y-%m-%d')

major_release:
	git flow release start $$(git describe --tags --abbrev=0 | awk -F'[v.]' '{print $$2+1".0.0"}').$$(date +'_%Y-%m-%d')

release_finish:
	git flow release finish "$$(git branch --show-current | sed 's/release\///')" && git push origin develop && git push origin main && git push --tags && git checkout develop

clean_git_repo:
	git clean --exclude=!.env -Xdf
