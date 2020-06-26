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
    
    func distance(to: CGPoint) -> CGFloat {
        
        let deltaX = self.x - to.x
        let deltaY = self.y - to.y
        
        let touchHypo = sqrt( pow(abs(deltaX), 2) + pow(abs(deltaY), 2))
        
        return touchHypo
    }
}

