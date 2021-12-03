//
//  GameLogic.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//



import SpriteKit

protocol GameLogicDelegate: AnyObject {
    func scoreDidChange(_ newScore: Int, text: String!)
    func livesDidChange(oldLives: Int, newLives: Int)
    func playerDidLose(destroyed: Bool)
    func shouldSpawnEnemy(enemySpeedMultiplier: CGFloat)
    func shouldSpawnBonus()
    func shouldExplodeNode(_ node: SKNode) -> Bool
    func shouldIncreaseSpeed()
}

class GameLogic: NSObject, SKPhysicsContactDelegate {

    private static let DefaultNumberOfLives: Int = 3
    private static let DefaultScore: Int = 0
    private static let DefaultEnemiesSpawnInterval: TimeInterval = 3.3
    private static let DefaultEnemiesSpeedMultiplier: CGFloat = 1.0
    
    // MARK: - delegate
    
    weak var delegate: GameLogicDelegate? = nil
    
    // MARK: - private
    
    private func gameOver(playerDestroyed destroyed: Bool) {
        if score > UserDefaults.standard.integer(forKey: HighScoreKey) {
            UserDefaults.standard.set(score, forKey: HighScoreKey)
        }
        delegate?.playerDidLose(destroyed: destroyed)
    }
    
    // MARK: - score
    
    private(set) var score: Int = GameLogic.DefaultScore {
        didSet {
            if oldValue != score {
                delegate?.scoreDidChange(score, text: scoreText())
                if score % 3000 == 0 {
                    enemiesSpeedMultiplier += 0.1
                } else if score % 1000 == 0 {
                    spawnEnemiesInterval = max(0.5, spawnEnemiesInterval - 0.5)
                    stopSpawningEnemies()
                    startSpawningEnemies()
                    delegate?.shouldIncreaseSpeed()
                }
            }
        }
    }
    
    func scoreText() -> String! {
        return "SCORE : \(score)"
    }
    
    // MARK: - lives
    
    private(set) var lives: Int = GameLogic.DefaultNumberOfLives {
        willSet (newLives) {
            delegate?.livesDidChange(oldLives: lives, newLives: newLives)
            if lives == 0 && !GodMode {
                gameOver(playerDestroyed: false)
            }
        }
    }
    
    // MARK: - enemies
    
    private var spawnEnemiesInterval: TimeInterval = GameLogic.DefaultEnemiesSpawnInterval
    private var enemiesSpeedMultiplier: CGFloat = GameLogic.DefaultEnemiesSpeedMultiplier
    private var enemiesSpawner: Timer? = nil
    
    @objc private func spawnEnemy(_ timer: Timer) {
        delegate?.shouldSpawnEnemy(enemySpeedMultiplier: enemiesSpeedMultiplier)
    }
    
    private func startSpawningEnemies() {
        enemiesSpawner = Timer.scheduledTimer(timeInterval: spawnEnemiesInterval,
                                              target: self,
                                              selector: #selector(GameLogic.spawnEnemy(_:)),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    private func stopSpawningEnemies() {
        enemiesSpawner?.invalidate()
        enemiesSpawner = nil
    }
    
    // MARK: - bonus
    
    private var bonusSpawner: Timer? = nil
    
    @objc private func spawBonus(_ timer: Timer) {
        delegate?.shouldSpawnBonus()
        startSpawningBonus()
    }
    
    private func startSpawningBonus() {
        let waitTime = random(min: 50.0, max: 120.0)
        bonusSpawner = Timer.scheduledTimer(timeInterval: TimeInterval(waitTime),
                                              target: self,
                                              selector: #selector(GameLogic.spawBonus(_:)),
                                              userInfo: nil,
                                              repeats: false)
    }
    
    private func stopSpawningBonus() {
        bonusSpawner?.invalidate()
        bonusSpawner = nil
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // organise bodies by category bitmask order
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        // player hits enemy
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy {
            if let node = body2.node { // enemy ship
                // explode it
                let _ = delegate?.shouldExplodeNode(node)
            }
            // player did lose
            enemyTouchesPlayer()
        }
        
        // bullet hits enemy
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy {
            if let node = body2.node {
                if ((delegate?.shouldExplodeNode(node)) != nil) {
                    enemyKilled()
                }
            }
            // ... and bullet disappear
            body1.node?.removeFromParent()
        }
        
        // bullet hits nyan cat
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.NyanCat {
            if let node = body2.node {
                // otherwise enemy explodes ...
                let _ = delegate?.shouldExplodeNode(node)
                bonusKilled()
            }
            // ... and bullet disappear
            body1.node?.removeFromParent()
        }
        
    }
    
    // MARK: - implementation
    
    func gameDidStart() {
        
        score = GameLogic.DefaultScore
        lives = GameLogic.DefaultNumberOfLives
        spawnEnemiesInterval = GameLogic.DefaultEnemiesSpawnInterval
        enemiesSpeedMultiplier = GameLogic.DefaultEnemiesSpeedMultiplier
        
        stopSpawningEnemies()
        startSpawningEnemies()
        
        stopSpawningBonus()
        startSpawningBonus()
        
    }
    
    func gameDidStop() {
        stopSpawningEnemies()
        stopSpawningBonus()
    }
    
    func gameDidRestart() {
        stopSpawningEnemies()
        startSpawningEnemies()
        stopSpawningBonus()
        startSpawningBonus()
    }
    
    func enemyKilled() { score += 579 }
    
    func enemyEscaped() { lives -= 1 }
    
    func bonusKilled() { lives += 1 }
    
    func enemyTouchesPlayer() {
        if !GodMode {
            gameOver(playerDestroyed: true)
        }
    }
}
