//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import SpriteKit

enum SpaceSpriteNodeType {
    case Unkown
    case Planet
}

class SpaceSpriteNode: SKSpriteNode {
    var speedMultiplier: TimeInterval = 0.75
    var removeOnSceneExit: Bool = true
    var type: SpaceSpriteNodeType = SpaceSpriteNodeType.Unkown
}
