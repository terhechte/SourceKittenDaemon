ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION := $(shell agvtool what-marketing-version -terse1)
BUILD := .build
DIST := dist
PREFIX := /usr/local
IDENTIFIER := com.stylemac.SourceKittenDaemon
BINARIES_FOLDER := /bin
LIB_FOLDER := /lib
PWD := $(shell pwd)

SRC_FILES := $(shell find  Sources -name '*.swift' -type file)

default: SourceKittenDaemon.pkg

.PHONY: clean
clean:
	rm -rf "$(DIST)"
	rm -rf "$(BUILD)"

.PHONY: install
install: $(DIST)$(BINARIES_FOLDER)/sourcekittendaemon
	mkdir -p "$(PREFIX)$(BINARIES_FOLDER)"
	mkdir -p "$(PREFIX)$(LIB_FOLDER)"
	cp -f "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon" "$(PREFIX)$(BINARIES_FOLDER)/"

.PHONY: test
test:
	FIXTURE_PATH="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures" \
	FIXTURE_PROJECT_DIR="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures/Project" \
	FIXTURE_PROJECT_FILE_PATH="$(ROOT_DIR)/Tests/SourceKittenDaemonTests/Fixtures/Project/Fixture.xcodeproj" \
	swift test

SourceKittenDaemon.pkg: $(DIST)$(BINARIES_FOLDER)/sourcekittendaemon 
	pkgbuild \
		--identifier "$(IDENTIFIER)" \
		--root "$(DIST)" \
		--install-location "$(PREFIX)" \
		--version "$(VERSION)" \
		$@

$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon: $(BUILD)/release/sourcekittend
	mkdir -p $(@D)
	cp $< $@

$(DIST)$(LIB_FOLDER)/%.dylib: $(BUILD)/release/%.dylib
	mkdir -p $(@D)
	cp $< $@

$(BUILD)/release/sourcekittend: $(SRC_FILES)
	mkdir -p $(@D)
	swift build -c release --build-path $(BUILD)

