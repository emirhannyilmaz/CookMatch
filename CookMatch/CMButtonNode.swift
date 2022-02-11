//
//  CMButtonNode.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 14.01.2022.
//

import SpriteKit

class CMButtonNode: SKSpriteNode {
    let hasFadeAnimation: Bool
    let hasPressAnimation: Bool
    let hasInfiniteAnimation: Bool
    var label: SKLabelNode
    var actionTouchUpInside: Selector?
    var actionTouchDown: Selector?
    var actionTouchUp: Selector?
    weak var targetTouchUpInside: AnyObject?
    weak var targetTouchDown: AnyObject?
    weak var targetTouchUp: AnyObject?
    
    enum CMButtonActionType: Int {
        case TouchUpInside = 1, TouchDown, TouchUp
    }
    
    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                color = .black
                colorBlendFactor = 0
            } else {
                color = .clear
                colorBlendFactor = 0.4
            }
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            removeAllActions()
            
            if isSelected {
                var wait = false
                var actions: [SKAction] = []
                
                if hasPressAnimation {
                    actions.append(SKAction.scale(to: 0.8, duration: 0.1))
                    wait = true
                }
                
                if hasFadeAnimation {
                    actions.append(SKAction.colorize(withColorBlendFactor: 0.2, duration: 0.1))
                }
                
                run(SKAction.group(actions))
                
                actions = []
                
                if hasPressAnimation {
                    actions.append(SKAction.group([
                        SKAction.scaleX(to: 0.85, duration: 0.4),
                        SKAction.scaleY(to: 0.75, duration: 0.4)
                    ]))
                    
                    actions.append(SKAction.group([
                        SKAction.scaleX(to: 0.8, duration: 0.4),
                        SKAction.scaleY(to: 0.8, duration: 0.4)
                    ]))
                } else {
                    actions.append(SKAction.group([
                        SKAction.scaleX(to: 1.05, duration: 0.4),
                        SKAction.scaleY(to: 0.95, duration: 0.4)
                    ]))
                    
                    actions.append(SKAction.group([
                        SKAction.scaleX(to: 1, duration: 0.4),
                        SKAction.scaleY(to: 1, duration: 0.4)
                    ]))
                }
                
                if hasInfiniteAnimation {
                    run(SKAction.sequence([
                        SKAction.wait(forDuration: wait ? 0.1 : 0),
                        SKAction.repeatForever(SKAction.sequence(actions))
                    ]))
                }
            } else {
                var wait = false
                var actions: [SKAction] = []
                
                if hasPressAnimation {
                    actions.append(SKAction.scale(to: 1, duration: 0.1))
                    wait = true
                }
                
                if hasFadeAnimation {
                    actions.append(SKAction.colorize(withColorBlendFactor: 0, duration: 0.1))
                }
                
                run(SKAction.group(actions))
                
                actions = []
                
                actions.append(SKAction.group([
                    SKAction.scaleX(to: 1.05, duration: 0.4),
                    SKAction.scaleY(to: 0.95, duration: 0.4)
                ]))
                
                actions.append(SKAction.group([
                    SKAction.scaleX(to: 1, duration: 0.4),
                    SKAction.scaleY(to: 1, duration: 0.4)
                ]))
                
                if hasInfiniteAnimation {
                    run(SKAction.sequence([
                        SKAction.wait(forDuration: wait ? 0.1 : 0),
                        SKAction.repeatForever(SKAction.sequence(actions))
                    ]))
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(textureName: String, hasFadeAnimation: Bool, hasPressAnimation: Bool, hasInfiniteAnimation: Bool) {
        self.hasFadeAnimation = hasFadeAnimation
        self.hasPressAnimation = hasPressAnimation
        self.hasInfiniteAnimation = hasInfiniteAnimation
        label = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        label.verticalAlignmentMode = .center
        
        let tex = SKTexture(imageNamed: textureName)
        
        super.init(texture: tex, color: .black, size: tex.size())
        
        if hasInfiniteAnimation {
            run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.scaleX(to: 1.05, duration: 0.4),
                        SKAction.scaleY(to: 0.95, duration: 0.4)
                    ]),
                    SKAction.group([
                        SKAction.scaleX(to: 1, duration: 0.4),
                        SKAction.scaleY(to: 1, duration: 0.4)
                    ])
                ])
            ))
        }
        
        isUserInteractionEnabled = true
        
        addChild(label)
    }
    
    func setButtonAction(target: AnyObject, actionType: CMButtonActionType, action: Selector) {
        switch actionType {
        case .TouchUpInside:
            targetTouchUpInside = target
            actionTouchUpInside = action
        case .TouchDown:
            targetTouchDown = target
            actionTouchDown = action
        case .TouchUp:
            targetTouchUp = target
            actionTouchUp = action
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else {
            return
        }
        
        isSelected = true
        
        if targetTouchDown != nil && targetTouchDown!.responds(to: actionTouchDown) {
            UIApplication.shared.sendAction(actionTouchDown!, to: targetTouchDown, from: self, for: nil)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else {
            return
        }
        
        let touch: AnyObject! = touches.first
        let touchLocation = touch.location(in: parent!)
        
        if frame.contains(touchLocation) {
            isSelected = true
        } else {
            isSelected = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else {
            return
        }
        
        isSelected = false
        
        if targetTouchUpInside != nil && targetTouchUpInside!.responds(to: actionTouchUpInside) {
            let touch: AnyObject! = touches.first
            let touchLocation = touch.location(in: parent!)
            
            if frame.contains(touchLocation) {
                UIApplication.shared.sendAction(actionTouchUpInside!, to: targetTouchUpInside, from: self, for: nil)
            }
        }
        
        if targetTouchUp != nil && targetTouchUp!.responds(to: actionTouchUp) {
            UIApplication.shared.sendAction(actionTouchUp!, to: targetTouchUp, from: self, for: nil)
        }
    }
}
