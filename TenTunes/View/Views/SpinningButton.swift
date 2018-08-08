//
//  SpinningButton.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class SpinningButton: NSButton {
    var spinning = false {
        didSet {
            guard spinning, layer?.animation(forKey: "spin") == nil else {
                return
            }
            
            layer?.transform = CATransform3DMakeTranslation(frame.size.width / 2, frame.size.height / 2, 0)
            layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)

            spinOnce()
        }
    }
    
    override func awakeFromNib() {
        wantsLayer = true
    }
    
    func spinOnce() {
        let ani = CABasicAnimation(keyPath: "transform.rotation.z")
        ani.fromValue = 0
        ani.toValue = -Double.pi * 2
        ani.duration = 1 // seconds
        ani.delegate = self
        ani.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        ani.isRemovedOnCompletion = true
        layer?.add(ani, forKey: "spin")
    }
}

extension SpinningButton : CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // May be called on other threads
        DispatchQueue.main.async {
            if self.spinning, self.layer?.animation(forKey: "spin") == nil {
                self.spinOnce()
            }
        }
    }
}
