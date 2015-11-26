import Foundation

infix operator =~ {}
func =~(string:String, regex:String) -> Bool {
    return string.rangeOfString(regex, options: .RegularExpressionSearch) != nil
}
