//
//  SpaceShipLaserOverheat.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import Foundation

class SpaceShipLaserOverheat {
    
    // MARK: variables for overheat
    
    // - heat limit, the max number of shot the laser can shot
    private(set) var heatLimit: Int = 20
    
    // - the current heat, when set calls a block
    private(set) var heat: Int = 0
    
    // - an accessor to the overheat ratio
    var overheatRatio: Float {
        get {
            return Float(heat)/Float(heatLimit)
        }
    }
    
    // - can set an infinite shoot 
    var infiniteShoot: Bool = false {
        didSet {
            if infiniteShoot {
                self.coolOff()
            }
        }
    }
    
    // - a timer to decrease heat
    private var coolOffTimer: Timer?
    private let coolOffTimerStepInterval: TimeInterval = 0.5
    private var isFirstCoolOffCallback: Bool = false
    
    // - block called when cool of starts
    var startsToCoolOff:((TimeInterval) -> Void)?
    
    // MARK: private
    
    // cool of timer callback
    @objc private func coolOffCallback(_ timer: Timer) {
        
        // if it is the first time in the loop the callback is called, we set
        // we call the startsToCoolOff(TimeInterval) block and create a repeating
        // timer with a normal delay
        if isFirstCoolOffCallback {
            
            isFirstCoolOffCallback = false
            
            if startsToCoolOff != nil {
                let time: TimeInterval = coolOffTimerStepInterval * TimeInterval(heat)
                startsToCoolOff!(time)
            }
            
            coolOffTimer = Timer.scheduledTimer(timeInterval: coolOffTimerStepInterval,
                                                target: self,
                                                selector: #selector(SpaceShipLaserOverheat.coolOffCallback(_:)),
                                                userInfo: nil,
                                                repeats: true)
            
        }
        
        // decrease the heat
        self.heat = max(heat - 1, 0)
        
        // if heat reaches 0 stop decreasing
        if self.heat == 0 {
            timer.invalidate()
        }
        
    }
    
    // MARK: public
    
    func canShoot() -> Bool {
        return heat < heatLimit || infiniteShoot
    }
    
    func didShot() {
        
        if infiniteShoot {
            return
        }

        // increase heat
        self.heat = min(heat + 1, heatLimit)
        
        // handles timer
        coolOffTimer?.invalidate()
        isFirstCoolOffCallback = true
        
        // the first timer has a bigger time interval and does not repeat, and
        // in the callback another repeating timer with the standard interval
        // is created
        coolOffTimer = Timer.scheduledTimer(timeInterval: coolOffTimerStepInterval * 2,
                                       target: self,
                                       selector: #selector(SpaceShipLaserOverheat.coolOffCallback(_:)),
                                       userInfo: nil,
                                       repeats: false)
        
    }
    
    func coolOff() {
        self.heat = 0
        coolOffTimer?.invalidate()
        coolOffTimer = nil
    }
    
    func upgrade(heatLimitIncrease i: Int) {
        heatLimit += i
    }
    
}
