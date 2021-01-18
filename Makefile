GITHUB_ORG ?= s12chung
GITHUB_REPO ?= mycharts

CHART_PATH ?= charts/$(CHART)

CHARTS_RELEASE_PACKAGE_DIR ?= .charts-releases
GIT_CURRENT_HEAD := $(shell git rev-parse --abbrev-ref HEAD)

release: release.check release.charts.package release.charts.publish

release.check:
ifneq (, $(shell git status -s))
	$(error Please run with a clean working tree)
endif
ifeq (,$(shell git branch --remotes --contains HEAD | grep origin/master))
	$(error Please run on a commit that is part of origin/master)
endif

release.charts.package:
	rm -rf $(CHARTS_RELEASE_PACKAGE_DIR)
	mkdir -p $(CHARTS_RELEASE_PACKAGE_DIR)

	helm package $(CHART_PATH) \
		--destination=$(CHARTS_RELEASE_PACKAGE_DIR)

	git reset --hard

	export http_code=$$(curl -w '%{http_code}' -sSLo $(CHARTS_RELEASE_PACKAGE_DIR)/existing-index.yaml https://$(GITHUB_ORG).github.io/$(GITHUB_REPO)/charts/index.yaml) && \
		([[ $${http_code} -eq 200 ]] || ([[ $${http_code} -eq 404 ]] && rm -f $(CHARTS_RELEASE_PACKAGE_DIR)/existing-index.yaml))
	helm repo index --merge $(CHARTS_RELEASE_PACKAGE_DIR)/existing-index.yaml \
		--url https://$(GITHUB_ORG).github.io/$(GITHUB_REPO)/charts \
		$(CHARTS_RELEASE_PACKAGE_DIR)

release.charts.publish:
	git fetch origin gh-pages
	git checkout -B gh-pages -t origin/gh-pages
	git reset --hard origin/gh-pages
	mkdir -p charts
	cp -r $(CHARTS_RELEASE_PACKAGE_DIR)/index.yaml $(CHARTS_RELEASE_PACKAGE_DIR)/*.tgz charts/
	git add charts/
	git commit -m 'release: Updated helm repo for $(CHART)' -n
	git push origin gh-pages
	git checkout $(GIT_CURRENT_HEAD)

	git push origin --tags
