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
    }
}
