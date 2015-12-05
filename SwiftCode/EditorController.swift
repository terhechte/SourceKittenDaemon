//
//  EditorController.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 03/12/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import AppKit

enum CompletionError: ErrorType {
    case Error(message: String)
}

enum Result {
    case Started
    case Stopped
    case Files([String])
    case Completions([String])
    case Error(ErrorType)
}

typealias Completion = (result: Result) -> ()

/**
This class takes care of all the completer / sourcekittendaemon handling. It:
- Searches the sourcekittendaemon binary in the SwiftCode binary
- Starts an `NSTask` with the binary
- Does the network requests against the sourcekittendaemon
- Converts the results to the proper types
- And offers rudimentary error handling via the `Result` type
 
 This can be considered the main component for connecting to the SourceKittenDaemon
 completion engine.
*/
class Completer {
    
    let port = "44876"
    
    let projectURL: NSURL
    let task: NSTask
    
    /**
    Create a new Completer for an Xcode project
     - parameter project: The Xcode project to load
     - parameter finished: This will be called once the task is running and the server is started up
    */
    init(project: NSURL, completion: Completion) {
        self.projectURL = project
        
        /// Find the SourceKittenDaemon Binary in our bundle
        let bundle = NSBundle.mainBundle()
        guard let supportPath = bundle.sharedSupportPath
            else { fatalError("Could not find Support Path") }
        
        let daemonBinary = (supportPath as NSString).stringByAppendingPathComponent("SourceKittenDaemon.app/Contents/MacOS/SourceKittenDaemon")
        guard NSFileManager.defaultManager().fileExistsAtPath(daemonBinary)
            else { fatalError("Could not find SourceKittenDaemon") }
        
        /// Start up the SourceKittenDaemon
        self.task = NSTask()
        self.task.launchPath = daemonBinary
        self.task.arguments = ["start", "--port", self.port, "--project", project.path!]
        
        /// Create an output pipe to read the sourcekittendaemon output
        let outputPipe = NSPipe()
        self.task.standardOutput = outputPipe.fileHandleForWriting

        /// Wait until the server started up properly
        /// Read the server output to figure out if startup succeeded.
        var started = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
            var content: String = ""
            while true {
                
                let data = outputPipe.fileHandleForReading.readDataOfLength(1)
                
                guard let dataString = String(data: data, encoding: NSUTF8StringEncoding)
                    else { continue }
                content += dataString
                
                if content.rangeOfString("\\[INFO\\] Started", options: .RegularExpressionSearch) != nil &&
                    !started {
                        started = true
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(result: Result.Started)
                    })
                }
                
                if content.rangeOfString("\\[ERR\\]", options: .RegularExpressionSearch) != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(result: Result.Error(CompletionError.Error(message: "Failed to start the Daemon")))
                    })
                    return
                }
            }
        }
        
        self.task.launch()
    }
    
    /**
    Stop the completion server, kill the task. This will be performed when a new
    Xcode project is loaded */
    func stop(completed: Completion) {
        self.dataFromDaemon("/stop", headers: [:]) { (data) -> () in
            self.task.terminate()
            completed(result: Result.Stopped)
        }
    }
    
    /**
    Return all project files in the Xcode project
    */
    func projectFiles(completion: Completion) {
        self.dataFromDaemon("/files", headers: [:]) { (data) -> () in
            do {
                let files = try data() as? [String]
                completion(result: Result.Files(files!))
            } catch let error {
                completion(result: Result.Error(error))
            }
        }
    }
    
    /**
    Get the completions for the given file at the given offset
    - parameter temporaryFile: A temporary file containing the content to be completed upon
    - parameter offset: The cursor / byte position in the file for which we need completions
    */
    func calculateCompletions(temporaryFile: NSURL, offset: Int, completion: Completion) {
        // Create the arguments
        guard let temporaryFilePath = temporaryFile.path
            else {
                completion(result: Result.Error(CompletionError.Error(message: "No file path")))
                return
        }
        let attributes = ["X-Path": temporaryFilePath, "X-Offset": "\(offset)"]
        self.dataFromDaemon("/complete", headers: attributes) { (data) -> () in
            do {
                guard let completions = try data() as? [NSDictionary] else {
                    completion(result: Result.Error(CompletionError.Error(message: "Wrong Completion Return Type")))
                    return
                }
                var results = [String]()
                for c in completions {
                    guard let s = (c["name"] as? String) else { continue }
                    results.append(s)
                }
                completion(result: Result.Completions(results))
            } catch let error {
                completion(result: Result.Error(error))
            }
        }
    }
    
    /**
    This is the work horse that makes sure we're receiving valid data from the completer.
     It does not use the Result type as that would include too much knowledge into this function
     (i.e. do we have a files or a completion request). Instead it uses the throwing closure
     concept as explained here: http://appventure.me/2015/06/19/swift-try-catch-asynchronous-closures/
    */
    private func dataFromDaemon(path: String, headers: [String: String], completion: (data: () throws -> AnyObject) -> () ) {
        guard let url = NSURL(string: "http://localhost:\(self.port)\(path)")
            else {
                completion(data: { throw CompletionError.Error(message: "Could not create completer URL") })
                return
        }
        print(url)
        print(headers)
        
        let session = NSURLSession.sharedSession()
        
        let mutableRequest = NSMutableURLRequest(URL: url)
        headers.forEach { (h) -> () in
            mutableRequest.setValue(h.1, forHTTPHeaderField: h.0)
        }
        
        let task = session.dataTaskWithRequest(mutableRequest, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                completion(data: { throw CompletionError.Error(message: "error: \(error.localizedDescription): \(error.userInfo)") })
                return
            }
            
            guard let data = data,
                parsedData = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                else {
                    completion(data: { throw CompletionError.Error(message: "Invalid Json") })
                    return
            }
            
            // Detect errors
            if let parsedDict = parsedData as? [String: AnyObject],
                jsonError = parsedDict["error"]
            where parsedDict.count == 1 {
                completion(data: { throw CompletionError.Error(message: "Error: \(jsonError)") })
                return
            }
            
            completion(data: {return parsedData})
        })
       
        task.resume()
    }
}

@objc class EditorController: NSViewController {
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var textView: HighlightingTextView!
    @IBOutlet var logView: NSTextView!
    @IBOutlet var waitWindow: NSWindow!
    
    private var completer: Completer?
    private var files: [String] = []
    
    override func awakeFromNib() {
        self.textView.setSyntaxHighlighter(SwiftSyntaxHighligher)
        self.textView.autoCompleteDelegate = self
        //self.textView.editingFile = NSURL(fileURLWithPath: "/tmp/test.swift")
        self.outlineView.setDelegate(self)
        self.outlineView.setDataSource(self)
    }
    
    override func viewDidAppear() {
        self.openXcodeProject(self)
    }
    
    @IBAction func openXcodeProject(sender: AnyObject?) {
        let openDialog = NSOpenPanel()
        openDialog.canChooseFiles = true
        openDialog.canChooseDirectories = false
        openDialog.allowedFileTypes = ["xcodeproj"]
        openDialog.title = "Open Xcode Project"
        openDialog.prompt = "Open Xcode Project"
        
        openDialog.beginSheetModalForWindow(self.view.window!) { (result: Int) -> Void in
            guard result == NSFileHandlingPanelOKButton else { return }
            guard let url = openDialog.URL else { return }
            
            // lock the UI
            self.lockUI()
            
            let creationAction = {
                self.completer = Completer(project: url, completion: { (result: Result) -> () in
                    print(result)
                    switch result {
                    case .Started:
                        // Read the project files
                        self.readProject()
                        
                        // Unlock the UI
                        self.unlockUI()
                        
                    case .Error(let error):
                        // display the error
                        self.displayError(error)
                    default:()
                    }
                })
            }
            
            if let currentCompleter = self.completer {
                currentCompleter.stop({ (result) -> () in
                    creationAction()
                })
            } else {
                creationAction()
            }
        }
    }
    
    private func readProject() {
        guard let completer = self.completer
            else { return }
        completer.projectFiles { (result) -> () in
            switch result {
            case Result.Error(let error):
                self.displayError(error)
            case Result.Files(let files):
                self.files = files
                self.outlineView.reloadData()
            default: ()
            }
        }
    }
    
    func displayError(error: ErrorType) {
        guard let error = error as? CompletionError else { return }
        switch error {
        case .Error(message: let msg):
            let alert = NSAlert()
            alert.messageText = msg
            alert.runModal()
        }
    }
    
    func terminate() {
        self.completer?.stop({ (result) -> () in
        })
    }
    
    private func lockUI() {
        self.view.window?.beginSheet(self.waitWindow, completionHandler: nil)
    }
    
    private func unlockUI() {
        self.view.window?.endSheet(self.waitWindow)
    }
    
    private func loadFile(filePath: String) {
        let url = NSURL(fileURLWithPath: filePath)
        self.textView.editingFile = url
        
        // read the file and set the contents
        do {
            let contents = try String(contentsOfFile: filePath)
            self.textView.string = contents
        } catch let error {
            self.displayError(CompletionError.Error(message: "\(error)"))
        }
    }
}

extension EditorController: AutoCompleteDelegate {
    func calculateCompletions(file: NSURL, content: String, offset: Int, completion: (entries: [String]?) -> ()) {
        // write into temporaryfile
        let temporaryFileName = NSTemporaryDirectory() + "/" + NSProcessInfo.processInfo().globallyUniqueString + ".swift"
        print(temporaryFileName)
        NSFileManager.defaultManager().createFileAtPath(temporaryFileName, contents: content.dataUsingEncoding(NSUTF8StringEncoding) , attributes: [:])
        self.completer?.calculateCompletions(NSURL(fileURLWithPath: temporaryFileName), offset: offset + 1,
            completion: { (result) -> () in
            switch result {
            case Result.Error(let error):
                self.displayError(error)
            case Result.Completions(let completions):
                completion(entries: completions)
            default: ()
            }
        })
    }
}

extension EditorController: NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        // root = nil
        if item == nil {
            return self.files.count
        }
        return 0
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return self.files[index]
        }
        // should never end here
        fatalError("No children for files")
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        if item == nil {
            return "Files"
        }
        guard let name = item as? String,
            lastItem = (name as NSString).pathComponents.last
            else { return nil }
        return lastItem
    }
}

extension EditorController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        // open the file
        guard let filePath = item as? String
            else { return false }
        self.loadFile(filePath)
        return true
    }
}