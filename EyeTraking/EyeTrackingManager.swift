//
//  EyeTrakingManager.swift
//  EyeTraking
//
//  Created by 山田楓也 on 2021/07/02.
//

import ARKit
import UIKit

protocol EyeTrackingManagerDelegate: AnyObject {
    func didUpdate(lookingPoint: CGPoint)
}

class EyeTrackingManager: NSObject {
    private weak var delegate: EyeTrackingManagerDelegate?
    private var sceneView: ARSCNView!
    
    // face node
    private var faceNode = SCNNode()
    
    // eye node
    private var leftEyeNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    private var rightEyeNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    // gaze node
    private var leftEyeTargetNode = SCNNode()
    private var rightEyeTargetNode = SCNNode()
    
    // array eye value
    private var lookingPositionXs: [CGFloat] = []
    private var lookingPositionYs: [CGFloat] = []
    
    // iPhone12 mini real screen size (m)
    private let phoneScreenMeterSize = CGSize(width: 0.0623908297, height: 0.135096943231532)
    
    // iPhone12 mini real screen size by point value
    private let phoneScreenPointSize = CGSize(width: 375, height: 812)
    
    // virtual iphone node
    private var virtualPhoneNode: SCNNode = SCNNode()
    
    // virtual iphone screen node
    private var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        return SCNNode(geometry: screenGeometry)
    }()
    
    private let heightCompensation: CGFloat = 106
    
    init(with sceneView: ARSCNView, delegate: EyeTrackingManagerDelegate) {
        super.init()
        
        // Set the view's delegate
        self.sceneView = sceneView
        self.delegate = delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        setupNode()
    }
    
    func setupNode() {
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(leftEyeNode)
        faceNode.addChildNode(rightEyeNode)
        leftEyeNode.addChildNode(leftEyeTargetNode)
        rightEyeNode.addChildNode(rightEyeTargetNode)
        
        leftEyeTargetNode.position.z = 0.8
        rightEyeTargetNode.position.z = 0.8
    }
    
    func startSession(_ configuration: ARFaceTrackingConfiguration) {
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopSession() {
        sceneView.session.pause()
    }
}

extension EyeTrackingManager: ARSCNViewDelegate {
    //新しいARアンカーが設置された時に呼び出される
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        leftEyeNode.simdTransform = anchor.leftEyeTransform
        rightEyeNode.simdTransform = anchor.rightEyeTransform

        var leftEyeLookingPoint = CGPoint()
        var rightEyeLookingPoint = CGPoint()
        
        DispatchQueue.main.async {
            let phoneScreenEyeRightHitTestResults = self.virtualPhoneNode.hitTestWithSegment(
                from: self.rightEyeTargetNode.worldPosition,
                to: self.rightEyeNode.worldPosition,
                options: nil
            )
            
            let phoneScreenEyeLeftHitTestResults = self.virtualPhoneNode.hitTestWithSegment(
                from: self.leftEyeTargetNode.worldPosition,
                to: self.leftEyeNode.worldPosition,
                options: nil
            )
            
            for result in phoneScreenEyeRightHitTestResults {
                rightEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.phoneScreenMeterSize.width * self.phoneScreenPointSize.width
                rightEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.phoneScreenMeterSize.height * self.phoneScreenPointSize.height + self.heightCompensation
            }
            
            for result in phoneScreenEyeLeftHitTestResults {
                leftEyeLookingPoint.x = CGFloat(result.localCoordinates.x) / self.phoneScreenMeterSize.width * self.phoneScreenPointSize.width
                leftEyeLookingPoint.y = CGFloat(result.localCoordinates.y) / self.phoneScreenMeterSize.height * self.phoneScreenPointSize.height + self.heightCompensation
            }
            
            // 直近10通りの位置を配列に保持して、平均を算出
            let suffixNumber: Int = 10
            self.lookingPositionXs.append((rightEyeLookingPoint.x + leftEyeLookingPoint.x) / 2)
            self.lookingPositionYs.append(-(rightEyeLookingPoint.y + leftEyeLookingPoint.y) / 2)
            self.lookingPositionXs = Array(self.lookingPositionXs.suffix(suffixNumber))
            self.lookingPositionYs = Array(self.lookingPositionYs.suffix(suffixNumber))
            
            let averageLookingAtPositionX = self.lookingPositionXs.average!
            let averageLookingAtPositionY = self.lookingPositionYs.average!
            
            let lookingPoint = CGPoint(x: averageLookingAtPositionX, y: averageLookingAtPositionY)
            self.delegate?.didUpdate(lookingPoint: lookingPoint)
        }
    }
}

extension EyeTrackingManager: ARSessionDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let pointOfViewTransform = sceneView.pointOfView?.transform else { return }
        virtualPhoneNode.transform = pointOfViewTransform
    }
    
    //ARアンカーが更新された時に呼び出される
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }
}
