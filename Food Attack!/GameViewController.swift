//
//  GameViewController.swift
//  Food Attack!
//
//  Created by Miranda Ramirez Cospin on 2/4/20.
//  Copyright © 2020 Miranda Ramirez Cospin. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let scene = GameScene(size: view.bounds.size)
    let skView = view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .resizeFill
    skView.presentScene(scene)
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}
