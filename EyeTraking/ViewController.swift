//
//  ViewController.swift
//  EyeTraking
//
//  Created by 山田楓也 on 2021/06/27.
//

import UIKit
import ARKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var pointerView: UIImageView!
    
    private var eyeTrackingManager: EyeTrackingManager!
    private let urlString = "https://www.apple.com/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eyeTrackingManager = EyeTrackingManager(with: sceneView, delegate: self)
        webView.loadPage(with: urlString)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        eyeTrackingManager.startSession(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        eyeTrackingManager.stopSession()
    }
}

extension ViewController: EyeTrackingManagerDelegate {
    func didUpdate(lookingPoint: CGPoint) {
        pointerView.transform = CGAffineTransform(translationX: lookingPoint.x, y: lookingPoint.y)
        webView.scrollByLookingAt(at: pointerView.frame.minY)
    }
}
