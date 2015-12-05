//
//  EditorController.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 03/12/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import AppKit

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
        self.outlineView.setDelegate(self)
        self.outlineView.setDataSource(self)
        self.logView.string = "Completer Communication Log"
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
                self.completer?.debugDelegate = self
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

extension EditorController: CompleterDebugDelegate {
    func startedCompleter(command: String) {
        if let currentString = self.logView.string {
            self.logView.string = "Started: \(command)\n--------\n\(currentString)"
        }
    }
    
    func calledURL(url: NSURL, withHeaders headers: [String: String]) {
        if let currentString = self.logView.string {
            self.logView.string = "Get: \(url)\nHeaders: \(headers)\n--------\n\(currentString)"
        }
    }
}

extension EditorController: AutoCompleteDelegate {
    func calculateCompletions(file: NSURL, content: String, offset: Int, completion: (entries: [String]?) -> ()) {
        // write into temporaryfile
        let temporaryFileName = NSTemporaryDirectory() + "/" + NSProcessInfo.processInfo().globallyUniqueString + ".swift"
        
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