//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import SpriteKit

class StartPanelNode: SKSpriteNode {

    private static let FadeInTranslationY: CGFloat = 80.0
    
    let label: SKLabelNode = SKLabelNode()
    let scoreLabel: SKLabelNode = SKLabelNode()
    
    init(size: CGSize) {
        
        let highScore = UserDefaults.standard.integer(forKey: HighScoreKey)
        
        scoreLabel.fontSize = 52.0
        scoreLabel.fontName = FontName
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.text = "HIGH SCORE : \(highScore)"
        
        label.fontSize = 80.0
        label.fontName = FontName
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.text = "TAP TO START"
        
        var pos = CGPoint(x: size.width / 2, y: size.height * 0.66)
        scoreLabel.position = pos
        pos.y -= scoreLabel.frame.size.height + 16.0
        label.position = pos
        
        super.init(texture: nil, color: UIColor.clear, size: size)
        
        self.addChild(scoreLabel)
        self.addChild(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func animate(alpha: CGFloat, yTranslation: CGFloat, completion: @escaping ()->() = {}) {
    
        let fadeIn = SKAction.fadeAlpha(to: alpha, duration: 0.2)
        let moveUpScore = SKAction.moveTo(y: scoreLabel.position.y + yTranslation, duration: 0.2)
        let groupScore = SKAction.group([fadeIn, moveUpScore])
        
        scoreLabel.run(groupScore)
        
        let moveUpLabel = SKAction.moveTo(y: label.position.y + yTranslation, duration: 0.2)
        let groupLabel = SKAction.group([fadeIn, moveUpLabel])
        let waitLabel = SKAction.wait(forDuration: 0.1)
        
        label.run(SKAction.sequence([waitLabel, groupLabel])) {
            completion()
        }
        
    }
    
    func fadeIn(completion: @escaping ()->() = {}) {
        
        scoreLabel.alpha = 0.0
        scoreLabel.position.y -= StartPanelNode.FadeInTranslationY
        
        label.alpha = 0.0
        label.position.y -= StartPanelNode.FadeInTranslationY
        
        self.animate(alpha: 1.0, yTranslation: StartPanelNode.FadeInTranslationY, completion: completion)
        
    }
    
    func fadeOut(completion: @escaping ()->() = {}) {
        
        self.animate(alpha: 0.0, yTranslation: StartPanelNode.FadeInTranslationY) {
            self.label.position.y -= StartPanelNode.FadeInTranslationY
            completion()
        }
        
    }
    
}
