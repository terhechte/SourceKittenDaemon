# SourceKittenD

This is a simple daemon for sourcekitten to keep it running and be able to get completion information or docs from emacs via webserver calls.
I decided to use simple REST services as other IPC mechanism were either lacking in emacs or lacking in swift. And for this kind of info (just a bit of json) I suppose a webserver is fine.

# Status
This currently doesn't work yet. It compiles, but it is not yet connecting the different modules properly to actually generate docs.

# Components
- A WebServer (Taylor.Swift) that communicates with Emacs
- A Commandline Parser to start the server
- A XcodeParser that parses an Xcode project to generate the proper completion settings
- A Completer that uses SourceKitten to generate completions and return them via the webserver