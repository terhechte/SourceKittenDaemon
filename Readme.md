# SourceKittenDaemon
## Swift Auto Completion Helper

This is a simple daemon that can read Xcode Swift projects and offers auto completion for Swift files and more over a built-in webserver.
Effectively, this allows any kind of editor like Vim, Emacs, Sublime, or Atom to support Swift, Auto Completion, and Xcode projects.

It includes an example, very simple, Xcode like, editor (see SwiftCode folder) which explains how to use / embedd the actual SourceKittenDaemon.

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

## Building / Installation

### PKG

You'll find an installable package under the releases tab

### Source

1. Clone the repository
2. Update the submodules 
`git submodule update --init --recursive`
3. Build the frameworks
`carthage bootstrap --no-use-binaries --platform Mac`
4. Install via `make install`

### SwiftCode Example Editor

You'll find a zip file under the releases tab

## Using it in an editor

Have a look at the SwiftCode example project, or at the existing editor integrations (below). Alternatively, the communication
protocol is outlined in the Protocol.org file in this repository.


## Editor Integrations
### Emacs
SourceKittenDaemon is used in the [company-sourcekit Emacs Swift plugin](https://github.com/nathankot/company-sourcekit):
<img src="https://raw.githubusercontent.com/nathankot/company-sourcekit/master/screen.gif" width="384" height="296" />


## Linux
SourceKittenDaemon is not Linux-Ready yet, but I'll investigate this in the next days. Also, since it is very dependent upon the SourceKitten and Taylor frameworks, it won't work under Linux until those have been ported, too. The background daemon, SourceKitD, is available as Open Source via Apple's Swift repository.

