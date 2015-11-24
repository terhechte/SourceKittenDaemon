#sourcekitten complete --text "struct A:Identifiable  { let name: String ; let u: Int } ; let aa = A(name: \"carl\", u: 5) ; aa." --offset 97 \
#--compilerargs -- "-sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk  `pwd`/FitureCompletionTests/ExampleProtocols.swift \
#`pwd`/FitureCompletionTests/ExampleStructs.swift \
#`pwd`/FitureCompletionTests/CompletionTarget.swift"

# Replicate the behaviour line-by-line from the unit test
sourcekitten complete --file /var/folders/mn/8hcn0nrn4_xbv81g62pzn_gh0000gn/T/8CF7673C-079B-4E05-AD4D-492A087115A5-51075-00027A61CFE46C94.swift \
--offset 98 \
--compilerargs -- "-sdk \
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk \
/Users/terhechte/Development/Cocoa/SourceKittenDaemon/SourceKittenDaemonTests/Fixtures/FitureCompletionTests/AppDelegate.swift \
/Users/terhechte/Development/Cocoa/SourceKittenDaemon/SourceKittenDaemonTests/Fixtures/FitureCompletionTests//FitureCompletionTests/Classes/ExampleProtocols.swift \
/Users/terhechte/Development/Cocoa/SourceKittenDaemon/SourceKittenDaemonTests/Fixtures/FitureCompletionTests//FitureCompletionTests/Classes/ExampleStructs.swift"
