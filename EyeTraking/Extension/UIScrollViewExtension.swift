//
//  UIScrollViewExtension.swift
//  EyeTraking
//
//  Created by 山田楓也 on 2021/07/02.
//

import UIKit

extension UIScrollView {
    func scrollUp() {
        DispatchQueue.main.async {
            for _ in 1...10 {
                if self.topInsetY >= self.contentOffset.y {
                    return
                }
                self.contentOffset.y = self.contentOffset.y - 1
            }
        }
    }
    
    func scrollDown() {
        DispatchQueue.main.async {
            for _ in 1...10 {
                if self.bottomInsetY <= self.contentOffset.y {
                    return
                }
                self.contentOffset.y = self.contentOffset.y + 1
            }
        }
    }
    
    // MARK: - Egde Inset Properties
    
    private var bottomInsetY: CGFloat {
        return self.contentSize.height - self.bounds.height + self.contentInset.bottom
    }
    
    private var topInsetY: CGFloat {
        return -self.contentInset.top
    }
}
