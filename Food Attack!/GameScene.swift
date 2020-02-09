//
//  GameScene.swift
//  Food Attack!
//
//  Created by Miranda Ramirez Cospin on 2/4/20.
//  Copyright © 2020 Miranda Ramirez Cospin. All rights reserved.
//

import SpriteKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene {
  
  struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let people   : UInt32 = 0b1       // 1
    static let food: UInt32 = 0b10      // 2
  }
  
  // 1
  let player = SKSpriteNode(imageNamed: "player")
  var peopleDestroyed = 0
  
  override func didMove(to view: SKView) {
    // 2
    backgroundColor = SKColor.yellow
    // 3
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    // 4
    addChild(player)
    
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addPeople),
        SKAction.wait(forDuration: 1.5)
        ])
    ))
    
    let backgroundMusic = SKAudioNode(fileNamed: "background-music.mp3")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func addPeople() {
    // Create sprite
    let people = SKSpriteNode(imageNamed: "people")
    
    people.physicsBody = SKPhysicsBody(rectangleOf: people.size) // 1
    people.physicsBody?.isDynamic = true // 2
    people.physicsBody?.categoryBitMask = PhysicsCategory.people // 3
    people.physicsBody?.contactTestBitMask = PhysicsCategory.food // 4
    people.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
    
    // Determine where to spawn the people along the Y axis
    let actualY = random(min: people.size.height/2, max: size.height - people.size.height/2)
    
    // Position the people slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    people.position = CGPoint(x: size.width + people.size.width/2, y: actualY)
    
    // Add the people to the scene
    addChild(people)
    
    // Determine speed of the people
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: -people.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    people.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("nom-nom.mp3", waitForCompletion: false))
    
    let touchLocation = touch.location(in: self)
    
    // 2 - Set up initial location of food
    let food = SKSpriteNode(imageNamed: "food")
    food.position = player.position
    
    food.physicsBody = SKPhysicsBody(circleOfRadius: food.size.width/2)
    food.physicsBody?.isDynamic = true
    food.physicsBody?.categoryBitMask = PhysicsCategory.food
    food.physicsBody?.contactTestBitMask = PhysicsCategory.people
    food.physicsBody?.collisionBitMask = PhysicsCategory.none
    food.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to food
    let offset = touchLocation - food.position
    
    // 4 - Bail out if you are shooting down or backwards
    if offset.x < 0 { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(food)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + food.position
    
    // 9 - Create the actions
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    food.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  func foodDidCollideWithpeople(food: SKSpriteNode, people: SKSpriteNode) {
    print("Hit")
    food.removeFromParent()
    people.removeFromParent()
    
    peopleDestroyed += 1
    if peopleDestroyed > 20 {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    // 2
    if ((firstBody.categoryBitMask & PhysicsCategory.people != 0) &&
      (secondBody.categoryBitMask & PhysicsCategory.food != 0)) {
      if let people = firstBody.node as? SKSpriteNode,
        let food = secondBody.node as? SKSpriteNode {
        foodDidCollideWithpeople(food: food, people: people)
      }
    }
  }
}

