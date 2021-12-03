//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import SpriteKit

extension Bundle {
    
    func emitterNode(_ name: String) -> SKEmitterNode? {
        guard let path = self.path(forResource: name, ofType: "sks") else {
            return nil
        }
        if let emitter = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? SKEmitterNode {
            return emitter
        }
        return nil
    }
}
