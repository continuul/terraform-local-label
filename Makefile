VERSION:=$(shell semtag final -s minor -o)

#:help: help        | Displays the GNU makefile help
.PHONY: help
help: ; @sed -n 's/^#:help://p' Makefile

#:help: lint        | Lint the project files using pre-commit
.PHONY: lint
lint:
	pre-commit run --all-files

#:help: changelog   | Build the changelog
.PHONY: changelog
changelog:
	git-chglog -o CHANGELOG.md --next-tag $(VERSION)
	git add CHANGELOG.md && git commit -m "Updated CHANGELOG"
	git push

#:help: release     | Release the product, setting the tag and pushing.
.PHONY: release
release:
	semtag final -s minor
	git push --follow-tags

#:help: test        | Test the product.
.PHONY: test
test:
	cd test && go test -v -timeout 30m
