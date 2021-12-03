//
//  SpaceShip.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import SpriteKit
import GameplayKit

class SpaceShip: SKSpriteNode {

    private static let bulletSound: SKAction = SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false)
    private static let bulletTexture: SKTexture = SKTexture(image: #imageLiteral(resourceName: "bullet"))
    private var fireEmitter: SKEmitterNode? = nil
    
    var overheat: SpaceShipLaserOverheat = SpaceShipLaserOverheat()
    
    init() {
//        let playerShip = #imageLiteral(resourceName: "E71").zRotation(withRotation: 0.785398)
        let playerShip = #imageLiteral(resourceName: "E2")

        let texture = SKTexture(image: playerShip)
        let size = CGSize(width: 150, height: 250)
        
        super.init(texture: texture, color: UIColor.clear, size: size)
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.categoryBitMask = PhysicsCategories.Player
        self.physicsBody!.collisionBitMask = PhysicsCategories.None
        self.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        
        if let emitter = SKEmitterNode(fileNamed: "ship-fire") {
            fireEmitter = emitter
            fireEmitter?.position = CGPoint(x: 0.0, y: -(self.size.height/2) + 50.0)
            fireEmitter?.targetNode = self
            self.addChild(fireEmitter!)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fireBullet(destinationY: CGFloat) -> Bool {
        
        if !overheat.canShoot() {
            return false
        }
        
        let bullet = SKSpriteNode(texture: SpaceShip.bulletTexture)
        bullet.size = CGSize(width: 25, height: 100)
        bullet.setScale(GameScene.scale)
        bullet.position = self.position
        bullet.zPosition = self.zPosition - 0.1
        bullet.alpha = 0.0
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.scene?.addChild(bullet)
        
        // two actions
        let moveBullet = SKAction.moveTo(y: destinationY + bullet.size.height, duration: 1)
        let appearBullet = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
        let bulletAnimation = SKAction.group([moveBullet, appearBullet])
        let deleteBullet = SKAction.removeFromParent()
        
        // sequence of actions
        let bulletSequence = SKAction.sequence([SpaceShip.bulletSound, bulletAnimation, deleteBullet])
        bullet.run(bulletSequence)
        
        overheat.didShot()
        return true
        
    }
    
    func accelerate(accelerate: CGFloat) {
        if accelerate > 4.0 {
            fireEmitter?.particleSpeed = 300.0
        } else if accelerate < -4.0 {
            fireEmitter?.particleSpeed = 20.0
        } else {
            fireEmitter?.particleSpeed = 100.0
        }
    }
    
}


extension UIImage {
    func zRotation(withRotation radians: CGFloat) -> UIImage {
        
        let cgImage = self.cgImage!
        let LARGEST_SIZE = CGFloat(max(self.size.width, self.size.height))
        let context = CGContext.init(data: nil, width:Int(LARGEST_SIZE), height:Int(LARGEST_SIZE), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!
        
        var drawRect = CGRect.zero
        drawRect.size = self.size
        let drawOrigin = CGPoint(x: (LARGEST_SIZE - self.size.width) * 0.5,y: (LARGEST_SIZE - self.size.height) * 0.5)
        drawRect.origin = drawOrigin
        var tf = CGAffineTransform.identity
        tf = tf.translatedBy(x: LARGEST_SIZE * 0.5, y: LARGEST_SIZE * 0.5)
        tf = tf.rotated(by: CGFloat(radians))
        tf = tf.translatedBy(x: LARGEST_SIZE * -0.5, y: LARGEST_SIZE * -0.5)
        context.concatenate(tf)
        context.draw(cgImage, in: drawRect)
        var rotatedImage = context.makeImage()!
        
        drawRect = drawRect.applying(tf)
        
        rotatedImage = rotatedImage.cropping(to: drawRect)!
        return UIImage(cgImage: rotatedImage)
    }
}
