# SourceKittenDaemon
## Swift Auto Completion Helper

[![Travis][badge-travis]][travis]

This is a simple daemon that can read Xcode Swift projects and offers auto completion for Swift files and more over a built-in webserver.
Effectively, this allows any kind of editor like Vim, Emacs, Sublime, or Atom to support Swift, Auto Completion, and Xcode projects.

It includes an example, very simple, Xcode like, editor [(see SwiftCode folder)](https://github.com/terhechte/SourceKittenDaemon/tree/0.1.2/SwiftCode) which explains how to use / embedd the actual SourceKittenDaemon.

Here's a video showing the example editor in action:

[![SwiftCode Editor Example](https://j.gifs.com/qwlJVE.gif)](https://www.youtube.com/watch?v=uk1uYtmOgHg)

## Features

- Get completions for current position in document
- Get completions for edited, unsaved files (via temporary files)
- Return files in project
- Parse Xcode project and understand compiler arguments, targets, etc
- Communication over http for easy integration in various editors

## SourceKit

This app uses the fantastic [SourceKitten](https://github.com/jpsim/SourceKitten) framework without which none of this would be possible. SourceKittenDaemon is really just a small wrapper that keeps an Xcode Project indexer running and offers a nice way to query Xcode Project properties and completions via a comfortable interface.

## Using It
Have a look at the [Protocol.org](https://github.com/terhechte/SourceKittenDaemon/blob/master/Protocol.org) file, which explains how to start and use the daemon.

## Building / Installation

### PKG

You'll find an [installable package under the releases tab](https://github.com/terhechte/SourceKittenDaemon/releases/tag/0.1.2)

### Homebrew

(Coming Soon)

### Source

1. Clone the repository
2. Update the submodules 
`git submodule update --init --recursive`
3. Build the frameworks
`carthage build --platform Mac`
4. Install via `make install`

### SwiftCode Example Editor

You'll find a [zip file under the releases tab](https://github.com/terhechte/SourceKittenDaemon/releases/tag/0.1.2)

## Using it in an editor

Have a look at the [SwiftCode example project](https://github.com/terhechte/SourceKittenDaemon/tree/0.1.2/SwiftCode), or at the existing editor integrations (below). Alternatively, the communication
protocol is outlined in the Protocol.org file in this repository.


## Editor Integrations

### Emacs
SourceKittenDaemon is used in the [company-sourcekit Emacs Swift plugin](https://github.com/nathankot/company-sourcekit):
<img src="https://raw.githubusercontent.com/nathankot/company-sourcekit/master/cap.gif" width="384" height="296" />

### Atom
[autocomplete-swift](https://atom.io/packages/autocomplete-swift) is a working Atom plugin offering Swift auto completion support via SourceKittenDaemon.

### TextMate
There's a [working implementation for TextMate](https://github.com/terhechte/TextMateSwiftCompletion) here.

[![TextMate Example](https://j.gifs.com/OXnG0Z.gif)](https://www.youtube.com/watch?v=jIMvrCkNn1I&feature=youtu.be)

[YouTube Video](https://www.youtube.com/watch?v=jIMvrCkNn1I&feature=youtu.be)

### SwiftCode
This is a very simple, featureless reference implementation to see how to embed SourceKittenDaemon into an editor. It offers:

- Reading Xcode Projects
- Selecting / Editing / Saving files
- Getting completions for files either when you enter a "." or when you hit the ESC key.

This is a *very* simple editor and no sane person should try to write code with it. It is only meant to show how to embed the daemon.

## Linux
SourceKittenDaemon is not Linux-Ready yet, but I'll investigate this in the next days. Also, since it is very dependent upon the SourceKitten and Taylor frameworks, it won't work under Linux until those have been ported, too. The background daemon, SourceKitD, is available as Open Source via Apple's Swift repository.


## Thanks
- A *lot* of thanks go to [Nathan Kot](https://github.com/nathankot) who wrote most parts of this.
- [Tomoya Kose](https://github.com/mitsuse) for updating the project so it works with Homebrew again

[badge-travis]: https://img.shields.io/travis/terhechte/SourceKittenDaemon.svg?style=flat-square
[travis]: https://travis-ci.org/terhechte/SourceKittenDaemon/builds
