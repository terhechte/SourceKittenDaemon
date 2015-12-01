BUILD := .build
DIST := dist
PREFIX := /usr/local

IDENTIFIER := com.stylemac.SourceKittenDaemon

APPLICATION_FOLDER := /Applications/SourceKittenDaemon.app
BINARIES_FOLDER := /bin
FRAMEWORKS_FOLDER := /lib/SourceKittenDaemon.Frameworks

default: $(DIST)

.PHONY: clean
clean:
	rm -rf "$(DIST)"

.PHONY: install
install: $(DIST)
	mkdir -p "$(PREFIX)$(BINARIES_FOLDER)"
	mkdir -p "$(PREFIX)$(FRAMEWORKS_FOLDER)"
	cp -f "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon" "$(PREFIX)$(BINARIES_FOLDER)/"
	cp -Rf "$(DIST)$(FRAMEWORKS_FOLDER)/" "$(PREFIX)$(FRAMEWORKS_FOLDER)/"

.PHONY: $(DIST)
$(DIST): $(BUILD)
	mkdir -p "$(DIST)$(BINARIES_FOLDER)"
	mkdir -p "$(DIST)$(FRAMEWORKS_FOLDER)"
	cp "$(BUILD)$(APPLICATION_FOLDER)/Contents/MacOS/SourceKittenDaemon" "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon"
	cp -r "$(BUILD)$(APPLICATION_FOLDER)/Contents/Frameworks/" "$(DIST)$(FRAMEWORKS_FOLDER)/"
	install_name_tool -add_rpath "@executable_path/..$(FRAMEWORKS_FOLDER)" "$(DIST)$(BINARIES_FOLDER)/sourcekittendaemon"

.PHONY: $(BUILD)
$(BUILD):
	mkdir -p $@
	xcodebuild -project SourceKittenDaemon.xcodeproj \
						 -scheme SourceKittenDaemon \
						 install \
						 DSTROOT=$@

