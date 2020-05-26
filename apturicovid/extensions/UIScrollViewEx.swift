//
//  UIScrollViewEx.swift
//  apturicovid
//
//  Created by Artjoms Spole on 26/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit.UIScrollView

extension UIScrollView {
    /// Sets content offset to the top.
    func resetScrollToInsts(animated: Bool, aditinalOffset: CGPoint = .zero) {
        
        let offset = CGPoint(x: contentInset.left + aditinalOffset.x, y: -(contentInset.top+aditinalOffset.y))
        
        guard contentOffset != offset else { return }
        
        UIView.animate(withDuration: animated ? 0.5 : 0) {
            self.contentOffset = offset
        }

    }
}
