//
//  HighlightingTextView.swift
//  ArgoFromJSON
//
//  Created by Benedikt Terhechte on 24/06/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import AppKit

protocol AutoCompleteDelegate {
    func calculateCompletions(file: NSURL, content: String, offset: Int, completion: (entries: [String]?) -> ())
}

class HighlightingTextView : NSTextView {
    
    var highlighter: SyntaxHighligher?
    var rulerView: RulerView?
    
    var editingFile: NSURL?
    
    var autoCompleteDelegate: AutoCompleteDelegate?
    
    func setSyntaxHighlighter(highlighter: SyntaxHighligher.Type) {
        let scrollView = self.enclosingScrollView!
        rulerView = RulerView(scrollView:scrollView , orientation: NSRulerOrientation.VerticalRuler)
        scrollView.verticalRulerView = rulerView!
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        self.highlighter = highlighter.init(textStorage: self.textStorage!, textView: self, scrollView: scrollView)
        
        // when a syntax highlighter is applied, we also set a default fixed size font
        let font = NSFont.userFixedPitchFontOfSize(12.0) ?? NSFont(name: "Menlo", size: 12.0) ?? NSFont(name: "Monaco", size: 12.0) ?? NSFont(name: "Helvetica", size: 12.0)!
        self.font = font
    }
    
    override func insertNewline(sender: AnyObject?) {
        super.insertNewline(sender)
        // indent the new line based on a very simple algorithm
        // take the indent of the previous line
        // if the last non-whitespace char is a { add + 2
        // if the last non-whitespace char is a } remove + 2
        let range = self.selectedRange()
        let cursor = range.location
        guard cursor != NSNotFound else { return }
        guard let content = self.string else { return }
        let currentLineRange = (content as NSString).lineRangeForRange(NSRange.init(location: cursor, length: 0))
        let previousLineRange = (content as NSString).lineRangeForRange(NSRange.init(location: currentLineRange.location - 1, length: 0))
        
        let previousLine = (content as NSString).substringWithRange(previousLineRange)
        // get the current indent
        var indent = previousLine.characters.reduce((count: 0, stop: false, last: Character.init(" "))) { (t: (count: Int, stop: Bool, last: Character), char) -> (count: Int, stop: Bool, last: Character) in
            guard t.stop == false
                else {
                    // remember the last non-whitespace char
                    if char == " " || char == "\t" || char == "\n" {
                        return t
                    } else {
                        return (count: t.count, stop: t.stop, last: char)
                    }
            }
            switch char {
            case " ": return (stop: false, count: t.count + 1, last: t.last)
            case "\t": return (stop: false, count: t.count + 2, last: t.last)
            default: return (stop: true, count: t.count, last: t.last)
            }
        }
        
        // find the last-non-whitespace char
        switch indent.last {
        case "{": indent.count += 2
        case "}": indent.count -= 2
        default: ()
        }
        
        // insert the new indent
        self.insertText(String.init(count: indent.count, repeatedValue: Character.init(" ")), replacementRange: NSRange.init(location: currentLineRange.location, length: 0))
    }
    
    var completions: [String]? = nil
    override func insertText(insertString: AnyObject) {
        super.insertText(insertString)
        
        /**
        Only call completion if we have one char (i.e. no paste),
        and that char is a completion char
        */
        let range = self.selectedRange()
        guard let string = insertString as? String,
             completionChars = self.highlighter?.completionChars(),
             firstChar = string.characters.first
            where completionChars.contains(firstChar) && range.location != NSNotFound
        else {
            return
        }
        
        self.performCompletion(range.location)
    }
    
    override func insertCompletion(word: String,
        forPartialWordRange charRange: NSRange,
        movement: Int,
        isFinal flag: Bool) {
            if flag {
                // once the user selected, insert it and clear the completions
                super.insertCompletion(word, forPartialWordRange: NSRange.init(location: charRange.location + charRange.length, length: 0), movement: movement, isFinal: flag)
                self.completions = nil
            }
    }
    
    override func cancelOperation(sender: AnyObject?) {
        // the user force-required completions
        let range = self.selectedRange()
        if range.location != NSNotFound {
            performCompletion(range.location)
        }
    }
    
    override func completionsForPartialWordRange(charRange: NSRange,
        indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
            return completions
    }
    
    private func performCompletion(offset: Int) {
        guard let content = self.string,
             fileName = self.editingFile
            else { return }
        
        self.autoCompleteDelegate?.calculateCompletions(fileName,
            content: content,
            offset: offset, completion: { (entries) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // once we got the completions, we store them and force-complete
                    self.completions = entries
                    self.complete(self)
                })
        })
    }
}