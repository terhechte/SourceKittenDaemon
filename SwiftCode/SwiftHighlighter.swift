//
//  GroovySyntaxHighligher.swift
//  SwiftEdit
//
//  Created by Scott Horn on 18/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

let SWIFT_ELEMENT_TYPE_KEY = "swiftElementType"

class SyntaxHighligher: NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate {
    var textStorage : NSTextStorage?
    let swiftStyles = [
        "COMMENT": NSColor.grayColor(),
        "QUOTES": NSColor.magentaColor(),
        "SINGLES_QUOTES": NSColor.greenColor(),
        "SLASHY_QUOTES": NSColor.orangeColor(),
        "DIGIT": NSColor.redColor(),
        "OPERATION": NSColor.purpleColor(),
        "RESERVED_WORDS": NSColor.blueColor()
    ]
    
    func reservedWords() -> [String] {
        return []
    }
    
    func reservedMatchers() -> [String] {
        return []
    }
    
    var matchers: [String] = []
    var regex : NSRegularExpression?
    var textView : NSTextView?
    var scrollView: NSScrollView?
    
    override init() {
        super.init()
        let reserved = self.reservedWords().joinWithSeparator("|")
        self.matchers = self.reservedMatchers() + ["RESERVED_WORDS", reserved]
        
        var regExItems: [String] = []
        for (idx, item) in matchers.enumerate() {
            if idx % 2 == 1 {
                regExItems.append(item)
            }
        }
        let regExString = "(" + regExItems.joinWithSeparator(")|(") + ")"
        do {
            try regex = NSRegularExpression(pattern: regExString, options: [])
        } catch _ {
            regex = nil
        }
    }
    
    convenience required init(textStorage: NSTextStorage, textView: NSTextView, scrollView: NSScrollView) {
        self.init()
        self.textStorage = textStorage
        self.scrollView = scrollView
        self.textView = textView
        
        textStorage.delegate = self
        scrollView.contentView.postsBoundsChangedNotifications = true
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "textStorageDidProcessEditing:",
            name: NSViewBoundsDidChangeNotification,
            object: scrollView.contentView)
        parse(nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func visibleRange() -> NSRange {
        let container = textView!.textContainer!
        let layoutManager = textView!.layoutManager!
        let textVisibleRect = scrollView!.contentView.bounds
        let glyphRange = layoutManager.glyphRangeForBoundingRect(textVisibleRect,
            inTextContainer: container)
        return layoutManager.characterRangeForGlyphRange(glyphRange,
            actualGlyphRange: nil)
    }
    
    func parse(sender: AnyObject?) {
        let range = visibleRange()
        let string = textStorage!.string
        let layoutManagerList = textStorage!.layoutManagers as [NSLayoutManager]
        for layoutManager in layoutManagerList {
            layoutManager.delegate = self
            layoutManager.removeTemporaryAttribute(SWIFT_ELEMENT_TYPE_KEY,
                forCharacterRange: range)
        }
        guard let r = regex else {return}
        
        r.enumerateMatchesInString(string, options: [], range: range) { (match, flags, stop) -> Void in
            for var matchIndex = 1; matchIndex < match!.numberOfRanges; ++matchIndex {
                let matchRange = match!.rangeAtIndex(matchIndex)
                if matchRange.location == NSNotFound {
                    continue
                }
                for layoutManager in layoutManagerList {
                    layoutManager.addTemporaryAttributes([SWIFT_ELEMENT_TYPE_KEY: self.matchers[(matchIndex - 1) * 2]],
                        forCharacterRange: matchRange)
                }
            }
        }
    }
    
    override func textStorageDidProcessEditing(aNotification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.parse(self)
        }
    }
    
    func layoutManager(layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [String : AnyObject], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer) -> [String : AnyObject]? {
        if toScreen {
            if let type = attrs[SWIFT_ELEMENT_TYPE_KEY] as? String {
                if let style = swiftStyles[type] {
                    return [NSForegroundColorAttributeName:style]
                }
            }
        }
        return attrs
    }

}

class SwiftSyntaxHighligher: SyntaxHighligher {
    
    override func reservedMatchers() -> [String] {
        return [ "COMMENT", "/\\*(?s:.)*?(?:\\*/|\\z)",
            "COMMENT", "//.*",
            "QUOTES",  "(?ms:\"{3}(?!\\\"{1,3}).*?(?:\"{3}|\\z))|(?:\"{1}(?!\\\").*?(?:\"|\\Z))",
            "SINGLE_QUOTES", "(?ms:'{3}(?!'{1,3}).*?(?:'{3}|\\z))|(?:'[^'].*?(?:'|\\z))",
            "DIGIT", "(?<=\\b)(?:0x)?\\d+[efld]?",
            "OPERATION", "[\\w\\$&&[\\D]][\\w\\$]* *\\("]
    }
    
    override func reservedWords() -> [String] {
        return ["(?:\\bclass\\b)", "(?:\\bdeinit\\b)", "(?:\\benum\\b)", "(?:\\bextension\\b)", "(?:\\bfunc\\b)", "(?:\\bimport\\b)", "(?:\\binit\\b)", "(?:\\binternal\\b)", "(?:\\blet\\b)", "(?:\\boperator\\b)", "(?:\\bprivate\\b)", "(?:\\bprotocol\\b)", "(?:\\bpublic\\b)", "(?:\\bstatic\\b)", "(?:\\bstruct\\b)", "(?:\\bsubscript\\b)", "(?:\\btypealias\\b)", "(?:\\bvar\\b)", "(?:\\bbreak\\b)", "(?:\\bcase\\b)", "(?:\\bcontinue\\b)", "(?:\\bdefault\\b)", "(?:\\bdo\\b)", "(?:\\belse\\b)", "(?:\\bfallthrough\\b)", "(?:\\bfor\\b)", "(?:\\bif\\b)", "(?:\\bin\\b)", "(?:\\breturn\\b)", "(?:\\bswitch\\b)", "(?:\\bwhere\\b)", "(?:\\bwhile\\b)", "(?:\\bas\\b)", "(?:\\bdynamicType\\b)", "(?:\\bfalse\\b)", "(?:\\bis\\b)", "(?:\\bnil\\b)", "(?:\\bself\\b)", "(?:\\bSelf\\b)", "(?:\\bsuper\\b)", "(?:\\btrue\\b)", "(?:\\b__COLUMN__\\b)", "(?:\\b__FILE__\\b)", "(?:\\b__FUNCTION__\\b)", "(?:\\b__LINE__\\b)", "(?:\\bassociativity\\b)", "(?:\\bconvenience\\b)", "(?:\\bdynamic\\b)", "(?:\\bdidSet\\b)", "(?:\\bfinal\\b)", "(?:\\bget\\b)", "(?:\\binfix\\b)", "(?:\\binout\\b)", "(?:\\blazy\\b)", "(?:\\bleft\\b)", "(?:\\bmutating\\b)", "(?:\\bnone\\b)", "(?:\\bnonmutating\\b)", "(?:\\boptional\\b)", "(?:\\boverride\\b)", "(?:\\bpostfix\\b)", "(?:\\bprecedence\\b)", "(?:\\bprefix\\b)", "(?:\\bProtocol\\b)", "(?:\\brequired\\b)", "(?:\\bright\\b)", "(?:\\bset\\b)", "(?:\\bType\\b)", "(?:\\bunowned\\b)", "(?:\\bweak\\b)", "(?:\\bwillSet\\b)", "(?:\\bString\\b)", "(?:\\bInt\\b)", "(?:\\bInt32\\b)", "(?:\\bNSDate\\b)", "(?:\\bCGFloat\\b)", "(?:\\bDecoded\\b)", "(?:\\bArgo.decodable\\b)"];
    }
}

class JSONSyntaxHighlighter: SyntaxHighligher {
    override func reservedMatchers() -> [String] {
        return [
            "RESERVED_WORDS", "\".+\"\\s:\\s",
            "DIGIT", "(?<=\\b)(?:0x)?[\\d\\.]+[efld]?\\s?[,\n]",
            "SLASHY_QUOTES", "(?ms:\"{3}(?!\\\"{1,3}).*?(?:\"{3}|\\z))|(?:\"{1}(?!\\\").*?(?:\"|\\Z))",
            "SINGLE_QUOTES", "(?ms:'{3}(?!'{1,3}).*?(?:'{3}|\\z))|(?:'[^'].*?(?:'|\\z))"
        ]
    }
    override func reservedWords() -> [String] {
        return []
    }
}
