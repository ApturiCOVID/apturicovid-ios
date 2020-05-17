//
//  CGPointEx.swift
//  apturicovid
//
//  Created by Artjoms Spole on 17/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }

    static func /(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
    
    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs , y: lhs.y / rhs)
    }
    
    static func += (lhs:inout CGPoint, rhs:CGPoint) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs:inout CGPoint, rhs:CGPoint) {
        lhs = lhs + rhs
    }
}

