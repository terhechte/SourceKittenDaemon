ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION := $(shell agvtool what-marketing-version -terse1)
BUILD := .build
DIST := dist
PREFIX := /usr/local
IDENTIFIER := com.stylemac.SourceKittenDaemon
BINARIES_FOLDER := /bin

default: $(DIST)

.PHONY: clean
clean:
	rm -rf "$(DIST)"

.PHONY: install
install: $(DIST)
	mkdir -p "$(PREFIX)$(BINARIES_FOLDER)"
	cp -f "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon" "$(PREFIX)$(BINARIES_FOLDER)/"

.PHONY: $(DIST)
$(DIST): $(BUILD)
	mkdir -p "$(DIST)$(BINARIES_FOLDER)"
	cp "$(BUILD)/release/sourcekittend" "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon"

.PHONY: test
test:
	FIXTURE_PATH="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures" \
	FIXTURE_PROJECT_DIR="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures/Project" \
	FIXTURE_PROJECT_FILE_PATH="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures/Project/Fixture.xcodeproj" \
	swift test

SourceKittenDaemon.pkg: $(DIST)
	pkgbuild \
		--identifier "$(IDENTIFIER)" \
		--root "$(DIST)" \
		--install-location "$(PREFIX)" \
		--version "$(VERSION)" \
		$@

.PHONY: $(BUILD)
$(BUILD):
	mkdir -p $@
	swift build -c release --build-path $(BUILD)
