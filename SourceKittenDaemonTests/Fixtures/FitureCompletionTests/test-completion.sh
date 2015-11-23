#sourcekitten complete --text "struct A:Identifiable  { let name: String ; let u: Int } ; let aa = A(name: \"carl\", u: 5) ; aa." --offset 97 \
sourcekitten complete --text "struct A:Identifiable  { let name: String ; let u: Int } ; let aa = A(name: \"\", u: 5); company1." --offset 97 \
--compilerargs -- "-module-name FitureCompletion \
`pwd`/FitureCompletionTests/ExampleProtocols.swift \
`pwd`/FitureCompletionTests/ExampleStructs.swift \
`pwd`/FitureCompletionTests/CompletionTarget.swift \
-Xcc -I./build/FitureCompletionTests.build/Debug/FitureCompletionTests.build/swift-overrides.hmap \
-Xcc -I./build/FitureCompletionTests.build/Debug/FitureCompletionTests.build/FitureCompletionTests-all-target-headers.hmap \
-DDEBUG=1"