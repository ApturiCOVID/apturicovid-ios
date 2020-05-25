//
//  KeychainValue.swift
//  apturicovid
//
//  Created by Artjoms Spole on 25/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation

@propertyWrapper
public struct KeychainValue<T> where T: Codable {
    
    let codingKey: CodingKey
    private let defaultValue: T

    public init(_ codingKey: CodingKey, defaultValue: T) {
        self.codingKey = codingKey
        self.defaultValue = defaultValue
    }
    
    public init(_ globalKey: KeychainGlobalKey, defaultValue: T) {
        self.codingKey = globalKey
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get { KeychainService.loadData(key: codingKey.stringValue, type: T.self) ?? defaultValue }
        set { KeychainService.saveData(key: codingKey.stringValue, data: newValue) }
    }

}

public enum KeychainGlobalKey: CodingKey, CaseIterable {
    case phoneNumber
}
