//
//  WKWebViewExtension.swift
//  EyeTraking
//
//  Created by 山田楓也 on 2021/07/02.
//

import WebKit

extension WKWebView {
    func loadPage(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        self.load(request)
    }
    
    func scrollByLookingAt(at position: CGFloat) {
        if position >= self.bounds.maxY {
            self.scrollView.scrollDown()
        } else if position < self.bounds.minY {
            self.scrollView.scrollUp()
        }
    }
}
