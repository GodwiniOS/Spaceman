//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//
import SpriteKit
import GameplayKit

enum GameState {
    case none
    case waiting
    case inGame
    case gameOver
}

extension SKAction {
    
    class func setSpaceSpeed(to speed: TimeInterval, duration: TimeInterval) -> SKAction {
        
        var initialSpeed: TimeInterval? = nil
        var deltaSpeed: TimeInterval? = nil
        
        return SKAction.customAction(withDuration: duration) {
            node, elapsedTime in
            
            // if this is applied to a GameScene
            if let space = node as? GameScene {
                
                // only on the very first loop, since after starsSpeed is
                // modified
                if initialSpeed == nil {
                    initialSpeed = space.starsSpeed
                    deltaSpeed = speed - initialSpeed!
                }
                
                // apply the fraction
                let fraction = (duration != 0.0 ? Float(elapsedTime / CGFloat(duration)) : 1.0)
                space.starsSpeed = initialSpeed! + (deltaSpeed! * TimeInterval(fraction))
                
            }
            
        }
    }
    
    class func hudLabelFadeAction(duration d: TimeInterval = 0.9, fadeDuration fd: TimeInterval = 0.3) -> SKAction {
        let waitDuration = d - 2 * fd;
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: fd)
        let wait = SKAction.wait(forDuration: waitDuration)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: fd)
        return SKAction.sequence([fadeIn, wait, fadeOut])
    }
    
    class func hudLabelMoveAction(movingLabel: SKLabelNode!, destinationNode: SKNode!, duration: TimeInterval = 0.9) -> SKAction {
        var pos = movingLabel.position
        pos.y = destinationNode.position.y -
            destinationNode.frame.size.height * 0.5 -
            movingLabel.frame.size.height * 0.5
        return SKAction.moveTo(y: pos.y, duration: duration)
    }
    
    class func hudLabelBumpAction(duration: TimeInterval = 0.3) -> SKAction {
        let scale = SKAction.scale(to: 1.4, duration: duration / 2)
        let unscale = SKAction.scale(to: 1.0, duration: duration / 2)
        return SKAction.sequence([scale, unscale])
    }
    
}

class GameScene: SKScene, GameLogicDelegate {
    
    static let scale: CGFloat = 1.0 - (1.0 / UIScreen.main.scale)
    static let backgroundNodeNameObject = "background-node-0"
    static let normalStarsSpeed: TimeInterval = 120.0
    static let gameStarsSpeed: TimeInterval = 550.0
    
    // handles the stars and the background
    
    private let spaceTexture: SKTexture = SKTexture(image: #imageLiteral(resourceName: "background"))
    var starsSpeed: TimeInterval = GameScene.normalStarsSpeed // px per seconds
    private let limitY: CGFloat
    private var tilesCount: Int = 0
    private var gameOverTransitoning = false
    private var lastUpdate: TimeInterval = 0.0
    
    // player
    
    private let player: SpaceShip = SpaceShip()
    private let allowVerticalMove: Bool = true
    private let playerBaseY: CGFloat = 0.2
    private let playerMaxY: CGFloat = 0.25
    private let playerMinY: CGFloat = 0.15
    private let playerOverheatNode: SpaceShipLaserOverheatNode = SpaceShipLaserOverheatNode()
    
    // planets
    private var planetsNodes: [SpaceSpriteNode] = {
        var nodes = [SpaceSpriteNode]()
        for textureIndex in 0...14 {
            let texture = SKTexture(image: UIImage.Asset.bgObject[textureIndex])
            let planet = SpaceSpriteNode(texture: texture)
            planet.name = GameScene.backgroundNodeNameObject
            planet.type = SpaceSpriteNodeType.Planet
            nodes.append(planet)
        }
        return nodes
    }()
    
    // ui nodes
    
    private var startPanel: StartPanelNode? = nil
    private let scoreLabel: SKLabelNode?
    private let livesLabel: SKLabelNode?
    
    // game data
    
    private let gameLogic: GameLogic = GameLogic()
    private var gameState: GameState = .none {
        didSet {
            switch gameState {
            case .waiting:
                self.setWaitingGameState()
                break
            case .inGame:
                self.setInGameState()
                break
            case .gameOver:
                self.setGameOverState()
                break
            default: break
            }
        }
        
    }
    
    // MARK: - private
    
    private func backgroundZPosition(zPosition: CGFloat) -> CGFloat {
        return zPosition + CGFloat(tilesCount)
    }
    
    private func gameZPosition(zPosition: CGFloat) -> CGFloat {
        return zPosition + 30.0
    }
    
    private func scoreBoardZPosition(zPosition: CGFloat) -> CGFloat {
        return zPosition + 100.0
    }
    
    private func livesText(_ lives: Int) -> String! {
        return "LIVES : \(max(lives, 0))"
    }
    
    // MARK: - game state
    
    private func setWaitingGameState() {
        
        player.position = CGPoint(x: self.size.width/2, y: -player.size.height)
        gameOverTransitoning = false
        
        startPanel?.removeFromParent()
        startPanel = StartPanelNode(size: self.size)
        startPanel?.zPosition = self.scoreBoardZPosition(zPosition: 2)
        self.addChild(startPanel!)
        startPanel?.fadeIn()
        
        self.setStarsSpeed(GameScene.normalStarsSpeed, duration: 0.5)
        
    }
    
    private func setInGameState() {
        
        gameLogic.gameDidStart()
        
        self.setStarsSpeed(GameScene.gameStarsSpeed, duration: 0.5)
        
        startPanel?.fadeOut() {
            self.startPanel?.removeFromParent()
            self.startPanel = nil
        }
        
        // player appear
        player.position = CGPoint(x: self.size.width/2, y: -player.size.height)
        self.player.isHidden = false
        let playerAppear = SKAction.moveTo(y: self.size.height * self.playerBaseY, duration: 0.3)
        self.player.run(playerAppear)
        
    }
    
    private func setGameOverState() {
        gameLogic.gameDidStop()
        self.setWaitingGameState()
    }
    
    // MARK: - implementation
    
    override init(size: CGSize) {
        
        // scroll indexes
        let centerY = (size.height - spaceTexture.size().height) / 2
        limitY = 0.0 - centerY - spaceTexture.size().height
        
        // label
        scoreLabel = SKLabelNode()
        scoreLabel?.fontSize = 65.0
        scoreLabel?.fontName = FontName
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel?.verticalAlignmentMode = .top
        
        livesLabel = SKLabelNode()
        livesLabel?.fontSize = 65.0
        livesLabel?.fontName = FontName
        livesLabel?.horizontalAlignmentMode = .right
        livesLabel?.verticalAlignmentMode = .top
        
        // super
        super.init(size: size)
        
        // prepare player
        player.setScale(GameScene.scale)
        player.zPosition = self.gameZPosition(zPosition: 4)
        
        gameLogic.delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = gameLogic
        
        // create the space
        
        var y = -((size.height - spaceTexture.size().height) / 2)
        let loopCount = Int(ceil((self.size.height / spaceTexture.size().height)))
        for i in 0...loopCount {
            
            tilesCount += 1
            
            let tile = SpaceSpriteNode(imageNamed: "background")
            tile.position = CGPoint(x: self.size.width / 2.0, y: y)
            tile.name = GameScene.backgroundNodeNameObject
            tile.zPosition = CGFloat(i)
            tile.removeOnSceneExit = false
            self.addChild(tile)
            
            let tile1 = SpaceSpriteNode(imageNamed: "background1")
            tile1.position = CGPoint(x: self.size.width / 2.0, y: y)
            tile1.name = GameScene.backgroundNodeNameObject
            tile1.zPosition = CGFloat(i) + 0.1
            tile1.speedMultiplier = 0.96
            tile1.removeOnSceneExit = false
            self.addChild(tile1)
            
            y += self.spaceTexture.size().height
        }
        
        // score and lives label prep work
        
        scoreLabel?.zPosition = self.scoreBoardZPosition(zPosition: 1)
        scoreLabel?.position = CGPoint(x: 22.0, y: self.size.height - 22.0)
        scoreLabel?.text = gameLogic.scoreText()
        self.addChild(scoreLabel!)
        
        livesLabel?.zPosition = self.scoreBoardZPosition(zPosition: 1.1)
        livesLabel?.position = CGPoint(x: self.size.width - 22.0, y: self.size.height - 22.0)
        livesLabel?.text = self.livesText(self.gameLogic.lives)
        self.addChild(livesLabel!)
        
        self.gameState = .waiting
        self.addChild(player)
        
        self.startSpawningPlanets()
        
        playerOverheatNode.position.x = 40.0
        playerOverheatNode.position.y = 40.0
        playerOverheatNode.zPosition = self.scoreBoardZPosition(zPosition: 1.2)
        self.addChild(playerOverheatNode)
        
        player.overheat.startsToCoolOff = { time in
            self.playerOverheatNode.setOverheatPercentage(percentage: 0.0, time: time)
        }
        
        if GodMode {
            player.physicsBody?.categoryBitMask = PhysicsCategories.None
        }
        
    }
    
    override var isPaused: Bool {
        didSet {
            if gameState == .inGame {
                if self.isPaused {
                    gameLogic.gameDidStop()
                } else {
                    gameLogic.gameDidRestart()
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdate != 0 {
            
            let deltaT = currentTime - lastUpdate
            var distance = deltaT * starsSpeed
            
            // move background 0
            self.enumerateChildNodes(withName: GameScene.backgroundNodeNameObject) { background, stop in
                
                var removeObject = false
                var isPlanet = false
                if let spaceObject = background as? SpaceSpriteNode {
                    distance = deltaT * self.starsSpeed * spaceObject.speedMultiplier
                    removeObject = spaceObject.removeOnSceneExit
                    isPlanet = spaceObject.type == SpaceSpriteNodeType.Planet
                }
                
                background.position.y -= CGFloat(distance)
                if background.position.y < self.limitY {
                    if removeObject {
                        background.removeFromParent()
                        if isPlanet {
                            self.planetsNodes.append(background as! SpaceSpriteNode)
                        }
                    } else {
                        background.position.y += CGFloat(self.tilesCount) * self.spaceTexture.size().height
                    }
                    
                }
                
            }
            
        }
        lastUpdate = currentTime
    }
    
    func setStarsSpeed(_ speed: TimeInterval, duration: TimeInterval) {
        let action = SKAction.setSpaceSpeed(to: speed, duration: duration)
        action.timingMode = SKActionTimingMode.easeInEaseOut
        self.run(action)
    }
    
    // MARK: - game logic delegate
    
    func scoreDidChange(_ newScore: Int, text: String!) {
        
        if newScore == 0 {
            scoreLabel?.text = text
            return
        }
        
        guard let score: SKLabelNode = scoreLabel else {
            return
        }
        
        let hitLabel = SKLabelNode()
        hitLabel.fontSize = score.fontSize
        hitLabel.fontName = FontName
        hitLabel.horizontalAlignmentMode = .left
        hitLabel.verticalAlignmentMode = .top
        hitLabel.text = "Enemy destroyed: +100"
        hitLabel.alpha = 0.0
        hitLabel.zPosition = score.zPosition + 0.1
        
        var pos = score.position
        pos.y -= score.frame.size.height * 2.0
        hitLabel.position = pos
        
        let fade = SKAction.hudLabelFadeAction()
        let move = SKAction.hudLabelMoveAction(movingLabel: hitLabel, destinationNode: score)
        
        self.addChild(hitLabel)
        hitLabel.run(SKAction.group([fade, move])) {
            
            hitLabel.removeFromParent()
            
            score.text = text
            score.run(SKAction.hudLabelBumpAction())
        }
        
    }
    
    func livesDidChange(oldLives: Int, newLives: Int) {
        
        if oldLives == newLives {
            livesLabel?.text = self.livesText(newLives)
            return
        }
        
        guard let lives: SKLabelNode = livesLabel else {
            return;
        }
        
        let failLabel = SKLabelNode()
        failLabel.fontSize = lives.fontSize
        failLabel.fontName = FontName
        failLabel.horizontalAlignmentMode = .right
        failLabel.verticalAlignmentMode = .top
        failLabel.text = newLives < oldLives ? "Enemy escaped: -1" : "Extra life: +1"
        failLabel.alpha = 0.0
        failLabel.zPosition = lives.zPosition + 0.1
        
        var pos = lives.position
        pos.y -= lives.frame.size.height * 2.0
        failLabel.position = pos
        
        let fade = SKAction.hudLabelFadeAction()
        let move = SKAction.hudLabelMoveAction(movingLabel: failLabel, destinationNode: lives)
        
        self.addChild(failLabel)
        failLabel.run(SKAction.group([fade, move])) {
            
            failLabel.removeFromParent()
            
            lives.text = self.livesText(newLives)
            lives.run(SKAction.hudLabelBumpAction())
        }
        
    }
    
    func playerDidLose(destroyed: Bool) {
        
        // we will have a transition
        gameOverTransitoning = true
        
        // reset game some data
        playerOverheatNode.setOverheatPercentage(percentage: 0.0)
        player.overheat.coolOff()
        
        // the block to call once the transition is done
        let gameOverTransitionDone = {
            self.gameOverTransitoning = false
            self.gameState = .gameOver
        }
        
        // the transition depends on why the player did lose
        if destroyed {
            // - lost because destroyed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                // dispatched only to have the sound played with a small delay
                // because there is also the sound of the enemy ship hitting us
                self.player.explode(removeFromParent: false, completion: gameOverTransitionDone)
            })
        } else {
            // - lost because lives == 0
            let hidePlayer = SKAction.moveTo(y: -player.size.height, duration: 0.5)
            player.run(hidePlayer, completion: gameOverTransitionDone)
        }
        
    }
    
    func shouldSpawnEnemy(enemySpeedMultiplier: CGFloat) {
        
        DispatchQueue.global().async {
            
            let enemy = EnemyNode()
            enemy.setScale(GameScene.scale)
            var moveType = EnemyShipMove.Straight
            if self.gameLogic.score > 4000 {
                moveType = (arc4random() % 2 == 0 ? .Straight : .Curvy)
            }
            enemy.move = moveType
            enemy.zPosition = self.gameZPosition(zPosition: 5)
            enemy.speed = enemy.speed * enemySpeedMultiplier
            
            let randomXStart = random(min: 10.0, max: self.size.width - 10.0)
            let yStart = self.size.height + 200.0
            
            let randomXEnd = random(min: 10.0, max: self.size.width - 10.0)
            let yEnd: CGFloat = -enemy.size.height
            
            DispatchQueue.main.async(execute: {
                self.addChild(enemy)
                enemy.move(from: CGPoint(x: randomXStart, y: yStart), to: CGPoint(x: randomXEnd, y: yEnd)) {
                    self.gameLogic.enemyEscaped()
                }
            })
            
        }
        
    }
    
    func shouldSpawnBonus() {
        
        DispatchQueue.global().async {
            
            let cat = NyanCat()
            cat.setScale(GameScene.scale)
            let nyanY = random(min: self.size.height * 0.33, max: self.size.height * 0.8)
            let from = CGPoint(x: -cat.size.width, y: nyanY)
            let to = CGPoint(x: self.size.width + cat.size.width, y: nyanY)
            cat.position = from
            cat.zPosition = self.gameZPosition(zPosition: 2)
            
            DispatchQueue.main.async(execute: {
                self.addChild(cat)
                cat.nyanNyanNyan(from: from, to: to) {
                    print("cat did nyan")
                }
            })
            
        }
        
    }
    
    func shouldExplodeNode(_ node: SKNode) -> Bool {
        // if this is an enemy and it's out of bounds, do nothing
        if node is EnemyNode && node.position.y >= self.size.height {
            return false
        }
        // otherwise, explode it!!
        node.explode()
        return true
    }
    
    func shouldIncreaseSpeed() {
        self.setStarsSpeed(self.starsSpeed + 100.0, duration: 0.5)
    }
    
    // MARK: - spawn planets
    
    static let spawnPlanetsAction = "spawn-planets"
    
    func spawnPlanet() {
        
        DispatchQueue.global().async {
            
            if (self.planetsNodes.count <= 0) {
                self.startSpawningPlanets()
                return
            }
            
            let planetIndex = Int(arc4random()) % self.planetsNodes.count
            let planet = self.planetsNodes[planetIndex]
            self.planetsNodes.remove(at: planetIndex)
            planet.setScale(random(min: 0.3, max: 1.0))
            planet.speedMultiplier = 1.1
            
            let randomY = random(min: 600.0, max: 2500.0)
            planet.position.y = self.size.height + randomY
            planet.position.x = random(min: 10.0, max: self.size.width - 10.0)
            
            planet.zPosition = self.backgroundZPosition(zPosition: 1)
            
            DispatchQueue.main.async(execute: {
                self.addChild(planet)
                self.startSpawningPlanets()
            })
            
        }
        
    }
    
    func startSpawningPlanets() {
        DispatchQueue.global().async {
            // the random wait time to pop a planet, between 3.0 and 22.0, has
            // been chosen based on the initial game speed, so we make a ratio
            // with the actual speed
            let min: CGFloat = 3.0 * (CGFloat(GameScene.gameStarsSpeed / self.starsSpeed))
            let max: CGFloat = 22.0 * (CGFloat(GameScene.gameStarsSpeed / self.starsSpeed))
            let waitTime = random(min: min,max: max)
            let waitAction = SKAction.wait(forDuration: TimeInterval(waitTime))
            let spawnAction = SKAction.run {
                self.spawnPlanet()
            }
            let sequence = SKAction.sequence([waitAction, spawnAction])
            DispatchQueue.main.async(execute: {
                self.run(sequence, withKey: GameScene.spawnPlanetsAction)
            })
        }
    }
    
    func stopSpawningPlanets() {
        self.removeAction(forKey: GameScene.spawnPlanetsAction)
    }
    
    // MARK: - handle touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOverTransitoning {
            return
        }
        
        if gameState == .waiting || gameState == .gameOver {
            self.gameState = .inGame
            return
        }
        
        if gameState == .inGame {
            // bullet could not be fired because of overheat
            if (player.fireBullet(destinationY: self.size.height)) {
                playerOverheatNode.setOverheatPercentage(percentage: player.overheat.overheatRatio)
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOverTransitoning {
            return
        }
        
        if gameState == .waiting || gameState == .gameOver {
            return
        }
        
        var i = 0
        for touch: AnyObject in touches {
            
            // allow 2 touches to move, can make the ship move faster
            if i >= 2 {
                break
            }
            
            let pointOfTouch = touch.location(in: self)
            let previous = touch.previousLocation(in: self)
            let amountDraggedX = pointOfTouch.x - previous.x
            let amountDraggedY = pointOfTouch.y - previous.y
            
            var x = player.position.x + amountDraggedX
            x = max(player.size.width / 2, x)
            x = min(self.size.width - player.size.width / 2, x)
            
            var y = player.position.y
            if allowVerticalMove {
                y += amountDraggedY
                y = max(self.size.height * playerMinY, y)
                y = min(self.size.height * playerMaxY, y)
                if i == 0 {
                    let deltaY = y - player.position.y
                    player.accelerate(accelerate: deltaY)
                }
            }
            
            player.position = CGPoint(x: x, y: y)
            
            i += 1
            
        }
        
    }
    
}
