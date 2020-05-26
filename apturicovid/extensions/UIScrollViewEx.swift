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
        setContentOffset(CGPoint(x: contentInset.left, y: -contentInset.top), animated: animated)
    }
}
