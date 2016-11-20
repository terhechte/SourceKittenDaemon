import Foundation

infix operator =~
func =~(string:String, regex:String) -> Bool {
    return string.range(of: regex, options: .regularExpression) != nil
}
