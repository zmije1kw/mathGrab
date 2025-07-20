//
//  GameViewController.swift
//  Math Grab 
//
//  Created by Kevin Zmijewski on 7/20/25.
//

import UIKit
import SwiftUI
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .resizeFill
                // Present the scene
                view?.presentScene(scene)
            }
            
            view?.preferredFramesPerSecond = 120
            view?.ignoresSiblingOrder = true
            view?.showsFPS = true
            view?.showsNodeCount = true
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
