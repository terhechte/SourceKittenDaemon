ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION := $(shell agvtool what-marketing-version -terse1)
BUILD := .build
DIST := dist
PREFIX := /usr/local
IDENTIFIER := com.stylemac.SourceKittenDaemon
BINARIES_FOLDER := /bin
LIB_FOLDER := /lib
PWD := $(shell pwd)

default: SourceKittenDaemon.pkg

.PHONY: clean
clean:
	rm -rf "$(DIST)"

.PHONY: install
install: $(DIST)
	mkdir -p "$(PREFIX)$(BINARIES_FOLDER)"
	cp -f "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon" "$(PREFIX)$(BINARIES_FOLDER)/"

$(DIST): $(DIST)$(BINARIES_FOLDER)/sourcekittendaemon $(DIST)$(LIB_FOLDER)/libCYaml.dylib $(DIST)$(LIB_FOLDER)/libCLibreSSL.dylib

$(DIST)$(LIB_FOLDER)/%.dylib: $(BUILD)/release/%.dylib
	mkdir -p $(@D)
	cp $< $@

$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon: $(BUILD)/release/sourcekittend
	mkdir -p $(@D)
	cp $< $@
	install_name_tool -change $(PWD)/.build/release/libCYaml.dylib  $(PREFIX)$(LIB_FOLDER)/libCYaml.dylib $@
	install_name_tool -change $(PWD)/.build/release/libCLibreSSL.dylib  $(PREFIX)$(LIB_FOLDER)/libCLibreSSL.dylib $@

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
