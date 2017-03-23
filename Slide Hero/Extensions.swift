//
//  Extensions.swift
//  Slide Hero
//
//  Created by Alan Rabelo Martins on 22/03/17.
//  Copyright © 2017 Alan Rabelo Martins. All rights reserved.
//

import Foundation
import SceneKit

extension SCNAudioSource {
    convenience init(name: String, volume: Float = 1.0, positional: Bool = true, loops: Bool = true, shouldStream: Bool = false, shouldLoad: Bool = true) {
        self.init(named: "art.scnassets/sounds/\(name)")!
        self.volume = volume
        self.isPositional = positional
        self.loops = loops
        self.shouldStream = shouldStream
        if shouldLoad {
            load()
        }
    }
}

extension SCNParticleSystem {
    
    static func particle(withName name : String) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "art.scnassets/\(name).scnp", inDirectory: nil)!
        
        return trail
    }
    
}
