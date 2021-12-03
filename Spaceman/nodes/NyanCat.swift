//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//
import SpriteKit
import GameplayKit

class NyanCat: SKSpriteNode {

    var textures: [SKTexture]
    let playNyan: SKAction = SKAction.playSoundFileNamed("nyan-short.wav", waitForCompletion: false)
    
    init() {
        
        let nyan = SKTexture(image: #imageLiteral(resourceName: "F11"))
        textures = [SKTexture]()
        for i in 0...11 {
            let texture = SKTexture(imageNamed: "nyan\(i)")
            textures.append(texture)
        }
        
        super.init(texture: nyan, color: UIColor.clear, size: nyan.size())
        
        if let rainbow = SKEmitterNode(fileNamed: "MyParticle") {
            rainbow.position = CGPoint(x: -((self.size.width / 2) - 10), y: 0.0)
            rainbow.targetNode = self
            self.addChild(rainbow)
        }
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.categoryBitMask = PhysicsCategories.NyanCat
        self.physicsBody!.collisionBitMask = PhysicsCategories.None
        self.physicsBody!.contactTestBitMask = PhysicsCategories.Bullet
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func nyanNyanNyan(from: CGPoint, to: CGPoint, completion: @escaping ()->() = {}) {
        
        let realTo = CGPoint(x: to.x + 300, y: to.y)
        self.position = from;
        
        let duration: TimeInterval = 3.0
        
        let moveYDuration = 0.32
        let moveYLoopCount = Int(ceil(duration / moveYDuration)) + 1
        let moveY0 = SKAction.moveTo(y: realTo.y + 12.0, duration: moveYDuration / 2.0)
        let moveY1 = SKAction.moveTo(y: realTo.y - 12.0, duration: moveYDuration / 2.0)
        let moveYLoop = SKAction.repeat(SKAction.sequence([moveY0, moveY1]), count: moveYLoopCount)
        let moveX = SKAction.moveTo(x: realTo.x, duration: duration)
        let move = SKAction.group([moveX, moveYLoop])
        
        let timePerFrame: TimeInterval = 0.05
        let loopTime = timePerFrame * TimeInterval(textures.count)
        let loopCount = duration / loopTime
        
        let nyan = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: false, restore: false)
        let nyanLoop = SKAction.repeat(nyan, count: Int(loopCount + 2))
        let group = SKAction.group([move, nyanLoop])
        
        let delete = SKAction.removeFromParent()
        let finally = SKAction.run(completion)
        
        self.run(SKAction.sequence([playNyan, group, delete, finally]))
        
    }
    
}
