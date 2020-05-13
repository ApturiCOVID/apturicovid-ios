import UIKit

class HomeBottomView: UIView {
    func createPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint.zero)
        path.addCurve(
            to: CGPoint(x: frame.maxX / 2, y: 20),
            controlPoint1: CGPoint(x: 60, y: 0),
            controlPoint2: CGPoint(x: frame.maxX / 2 - 20, y: 25)
        )
        path.addCurve(
            to: CGPoint(x: frame.maxX, y: frame.minY),
            controlPoint1: CGPoint(x: frame.maxX / 2 + 20, y: 25),
            controlPoint2: CGPoint(x: frame.maxX - 60, y: 0)
        )
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.minY))
        path.close()
        return path
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = createPath()
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = Colors.mintGreen.cgColor
        
        layer.addSublayer(shape)
    }
}
