//
//  WelcomeHeader.swift
//  apturicovid
//
//  Created by Artjoms Spole on 13/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

@IBDesignable class WelcomeHeaderView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var bottomCurveInset: CGFloat = 0.0
    @IBInspectable var fillColor: UIColor = .white
    
    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        fillColor.setFill()
        getPath(in: bounds).fill()
 
    }
    
    func getPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        let topLeft = CGPoint(x: rect.minX , y: rect.minY)
        let topRight = CGPoint(x: rect.maxX , y: rect.minY)
        
        let bottomLeft1 = CGPoint(x: rect.minX, y: rect.maxY) - CGPoint(x: 0, y: cornerRadius*1.5)
        let bottomLeft2 = CGPoint(x: rect.minX, y: rect.maxY) + CGPoint(x: cornerRadius*1.5, y: 0)
        let bottomLeftControlPoint = CGPoint(x: rect.minX, y: rect.maxY)
        
        let bottomMiddle = CGPoint(x: rect.midX, y: rect.maxY) - CGPoint(x: 0, y: bottomCurveInset)
        let bottomMiddleControlPoint1 = bottomMiddle - CGPoint(x: 50, y: 0)
        let bottomMiddleControlPoint2 = bottomMiddle + CGPoint(x: 50, y: 0)
        
        let bottomRigth1 = CGPoint(x: rect.maxX, y: rect.maxY) - CGPoint(x: 0, y: cornerRadius*1.5)
        let bottomRigth2 = CGPoint(x: rect.maxX, y: rect.maxY) - CGPoint(x: cornerRadius*1.5, y: 0)
        let bottomRightControlPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        
        path.move(to: topLeft)
        path.addLine(to: bottomLeft1)
        path.addCurve(to: bottomLeft2, controlPoint1: bottomLeftControlPoint, controlPoint2: bottomLeftControlPoint)
        
        path.addCurve(to: bottomMiddle, controlPoint1: bottomMiddleControlPoint1, controlPoint2: bottomMiddleControlPoint1)
        path.addCurve(to: bottomRigth2, controlPoint1: bottomMiddleControlPoint2, controlPoint2: bottomMiddleControlPoint2)
        
        path.addCurve(to: bottomRigth1, controlPoint1: bottomRightControlPoint, controlPoint2: bottomRightControlPoint)
        
        path.addLine(to: topRight)
        path.close()

        return path
    }
}
