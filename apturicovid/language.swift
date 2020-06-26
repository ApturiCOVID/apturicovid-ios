import Foundation

let languageChangeNotification = NSNotification.Name(rawValue: "LanguageDidChange")

var language = "lv" {
    didSet {
        NotificationCenter.default.post(name: languageChangeNotification, object: language)
    }
}
