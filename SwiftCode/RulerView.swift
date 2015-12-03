//
//  RulerView.swift
//  SwiftEdit
//
//  Created by Scott Horn on 14/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

let DEFAULT_THICKNESS = 25.0
let RULER_MARGIN = 11.0

class RulerView: NSRulerView {
    var _lineIndices : [Int]?
    var lineIndices : [Int]? {
        get {
            if self._lineIndices == nil {
                calculateLines()
            }
            return self._lineIndices
        }
    }
    var textView : NSTextView? {
        return (self.clientView as? NSTextView) ?? nil
    }

    override var opaque: Bool { return false }
    override var clientView: NSView? {
        willSet {
            let oldView = self.clientView
            let center = NSNotificationCenter.defaultCenter()
            if let o = oldView as? NSTextView {
                if o != newValue {
                    center.removeObserver(self, name: NSTextDidEndEditingNotification, object: o.textStorage)
                    center.removeObserver(self, name: NSViewBoundsDidChangeNotification, object: scrollView!.contentView)
                }
            }
            if newValue is NSTextView {
                center.addObserver(self, selector: "textDidChange:", name: NSTextDidChangeNotification, object: newValue)
                scrollView!.contentView.postsBoundsChangedNotifications = true
                center.addObserver(self, selector: "boundsDidChange:", name: NSViewBoundsDidChangeNotification, object: scrollView!.contentView)
                invalidateLineIndices()
            }
        }
    }
    
    override init(scrollView: NSScrollView?, orientation: NSRulerOrientation) {
        super.init(scrollView: scrollView, orientation:orientation)
        self.clientView = scrollView!.documentView as? NSView
        self.ruleThickness = CGFloat(DEFAULT_THICKNESS)
        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc func boundsDidChange(notification: NSNotification) {
        needsDisplay = true
    }

    func textDidChange(notification: NSNotification) {
        invalidateLineIndices()
        needsDisplay = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        //super.drawRect(dirtyRect)
        drawHashMarksAndLabelsInRect(dirtyRect)
    }
    
    func invalidateLineIndices() {
        _lineIndices = nil
    }
    
    func lineNumberForCharacterIndex(index: Int) -> Int {
        let lineIndices = self.lineIndices!
        var left = 0, right = lineIndices.count
        while right - left > 1 {
            let mid = (left + right) / 2
            let lineIndex = lineIndices[mid]
            if index < lineIndex {
                right = mid
            } else if index > lineIndex {
                left = mid
            } else {
                return mid + 1
            }
        }
        return left + 1
    }
    
    func calculateRuleThickness() -> CGFloat {
        let lineIndices = self.lineIndices!
        let digits : Int = Int(log10(Double(lineIndices.count))) + 1
        var maxDigits = ""
        for var i = 0; i < digits; i++ {
            maxDigits += "8"
        }
        let digitWidth = (maxDigits as NSString).sizeWithAttributes(textAttributes() as? [String : AnyObject]).width * 2 + CGFloat(RULER_MARGIN)
        let defaultThickness = CGFloat(DEFAULT_THICKNESS)
        return digitWidth > defaultThickness  ? digitWidth : defaultThickness
    }
    
    func calculateLines() {
        var lineIndices : [Int] = []
        if let textView = self.textView {
            let text: NSString = textView.string!
            let textLength: Int = text.length
            var totalLines: Int = 0
            var charIndex: Int = 0
            repeat {
                lineIndices.append(charIndex)
                charIndex = NSMaxRange(text.lineRangeForRange(NSMakeRange(charIndex, 0)))
                totalLines++
            } while charIndex < textLength
            
            // Check for trailing return
            var lineEndIndex: Int = 0, contentEndIndex: Int = 0
            let lastObject = lineIndices[lineIndices.count - 1]
            text.getLineStart(nil, end: &lineEndIndex, contentsEnd: &contentEndIndex, forRange: NSMakeRange(lastObject, 0))
            if contentEndIndex < lineEndIndex {
                lineIndices.append(lineEndIndex)
            }
            self._lineIndices = lineIndices
            
            let ruleThickness = self.ruleThickness
            let newThickness = calculateRuleThickness()
            
            if fabs(ruleThickness - newThickness) > 1 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateThinkness(CGFloat(ceil(Double(newThickness))))
                })
            }
        }
    }
    
    func updateThinkness(thickness: CGFloat) {
        self.ruleThickness = thickness
        self.needsDisplay = true
    }
    
    override func drawHashMarksAndLabelsInRect(rect: NSRect) {
        if let textView = self.textView {
            
            // Make background
            let docRect = convertRect(self.clientView!.bounds, fromView: clientView)
            let y = docRect.origin.y
            let height = docRect.size.height
            let width = bounds.size.width
            NSColor(calibratedRed: 0.969, green: 0.969, blue: 0.969, alpha: 1).set()
            NSRectFill(NSMakeRect(0, y, width, height))
            
            // Code folding area
            //NSColor(calibratedRed: 0.969, green: 0.969, blue: 0.969, alpha: 1).set()
            NSRectFill(NSMakeRect(width - 8, y, 8, height))
            
            // Seperator/s
            NSColor(calibratedRed: 0.902, green: 0.902, blue: 0.902, alpha: 1).set()
            var line = NSBezierPath()
            line.moveToPoint(NSMakePoint(width - 8.5, y))
            line.lineToPoint(NSMakePoint(width - 8.5, y + height))
            line.lineWidth = 1.0
            line.stroke()
            
            line = NSBezierPath()
            line.moveToPoint(NSMakePoint(width - 0.5, y))
            line.lineToPoint(NSMakePoint(width - 0.5, y + height))
            line.lineWidth = 1.0
            line.stroke()
            
            let layoutManager = textView.layoutManager
            let container = textView.textContainer
            let nullRange = NSMakeRange(NSNotFound, 0)
            var lineRectCount: Int = 0
            
            let textVisibleRect = self.scrollView!.contentView.bounds
            let rulerBounds = bounds
            let textInset = textView.textContainerInset.height
            
            let glyphRange = layoutManager!.glyphRangeForBoundingRect(textVisibleRect, inTextContainer: container!)
            let charRange = layoutManager!.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
            
            let lineIndices = self.lineIndices!
            let startChange = lineNumberForCharacterIndex(charRange.location)
            let endChange = lineNumberForCharacterIndex(NSMaxRange(charRange))
            for var lineNumber = startChange; lineNumber <= endChange; lineNumber++ {
                let charIndex = lineIndices[lineNumber - 1]
                let lineRectsForRange = layoutManager!.rectArrayForCharacterRange(
                    NSMakeRange(charIndex, 0),
                    withinSelectedCharacterRange: nullRange,
                    inTextContainer: container!,
                    rectCount: &lineRectCount)
                if lineRectCount > 0 {
                    let ypos = textInset + NSMinY(lineRectsForRange[0]) - NSMinY(textVisibleRect)
                    let labelText = NSString(format: "%ld", lineNumber)
                    let labelSize = labelText.sizeWithAttributes(textAttributes() as? [String : AnyObject])
                    
                    let lineNumberRect = NSMakeRect( NSWidth(rulerBounds) - labelSize.width - CGFloat(RULER_MARGIN),
                                                     ypos + (NSHeight(lineRectsForRange[0]) - labelSize.height) / 2.0,
                                                     NSWidth(rulerBounds) - CGFloat(RULER_MARGIN) * 2.0,
                                                     NSHeight(lineRectsForRange[0]) )
                    
                    labelText.drawInRect(lineNumberRect, withAttributes: textAttributes() as? [String: AnyObject])
                }
                
                // we are past the visible range so exit for
                if charIndex > NSMaxRange(charRange) {
                    break
                }
            }
        }
    }
    
    
    func textAttributes() -> NSDictionary {
        return [
            NSFontAttributeName: NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.MiniControlSize)),
            NSForegroundColorAttributeName: NSColor(calibratedWhite: 0.42, alpha: 1.0)
        ]
    }
}
