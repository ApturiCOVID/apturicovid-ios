import UIKit

@IBDesignable class HomeBottomView: UIView {
    
    @IBInspectable var curveOffset: CGFloat = 0
    @IBInspectable var fillColor: UIColor = .green
    
    func getPath(in rect: CGRect) -> UIBezierPath {
        
        let topLeft = CGPoint(x: rect.minX , y: rect.minY)
        let topRight = CGPoint(x: rect.maxX , y: rect.minY)
        let topMiddle = CGPoint(x: rect.midX , y: rect.minY) + CGPoint(x: 0, y: curveOffset)
        let controlPointLength = CGPoint(x: topMiddle.x/3, y: 0)
        
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRigth = CGPoint(x: rect.maxX, y: rect.maxY)
        
        let path = UIBezierPath()
        path.move(to: bottomLeft)
        path.addLine(to: topLeft)
        
        path.addCurve(to: topMiddle,
                      controlPoint1: topLeft   + controlPointLength,
                      controlPoint2: topMiddle - controlPointLength)
        
        path.addCurve(to: topRight,
                      controlPoint1: topMiddle + controlPointLength,
                      controlPoint2: topRight  - controlPointLength)

        path.addLine(to: bottomRigth)
        path.close()
        return path
    }
    
    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        fillColor.setFill()
        getPath(in: bounds).fill()
        
    }
}
