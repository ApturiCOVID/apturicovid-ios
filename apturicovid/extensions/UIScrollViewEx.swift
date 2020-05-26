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
    func resetScrollToInsts(animated: Bool) {
        
        let offset = CGPoint(x: contentInset.left, y: -contentInset.top)
        
        UIView.animate(withDuration: animated ? 0.5 : 0) {
            self.contentOffset = offset
        }

    }
}
