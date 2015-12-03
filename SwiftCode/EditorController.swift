//
//  EditorController.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 03/12/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import AppKit


@objc class EditorController: NSObject {
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var textView: HighlightingTextView!
    
    override func awakeFromNib() {
        self.textView.setSyntaxHighlighter(SwiftSyntaxHighligher)
        self.textView.autoCompleteDelegate = self
        self.textView.editingFile = NSURL(fileURLWithPath: "/tmp/test.swift")
    }
}

extension EditorController: AutoCompleteDelegate {
    func calculateCompletions(file: NSURL, content: String, offset: Int, completion: (entries: [String]?) -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            sleep(1)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(entries: ["klaus", "bernharnd", "jochen"])
            })
        }
    }
}