//
//  Language.swift
//  apturicovid
//
//  Created by Artjoms Spole on 13/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation

enum Language: String, Codable, CaseIterable {
    case LV, EN, RU
    
    @UserDefault(.applicationLanguage, defaultValue: .LV)
    static var primary: Language {
        didSet { NotificationCenter.default.post(name: .languageDidChange, object: primary) }
    }
    
    var isPrimary: Bool { self == Language.primary }
    var localization: String { self.rawValue.lowercased() }
}
