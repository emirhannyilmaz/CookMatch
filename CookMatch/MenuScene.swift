//
//  MenuScene.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 19.01.2022.
//

import SpriteKit

class MenuScene: SKScene {
    var currentLevelNumber = 0
    var levelMaps: [LevelMap] = []
    var levelPanelLevelNumber: Int?
    var levelPanelPlayButtonHandler: ((Int) -> Void)?
    
    let panelLayer = SKNode()
    
    var lifeCountLabel: SKLabelNode?
    var newLifeCountdownLabel: SKLabelNode?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        panelLayer.isHidden = true
        panelLayer.alpha = 0
        panelLayer.zPosition = 100
        addChild(panelLayer)
    }
    
    func addLifeBar() {
        let lifeBackground = CMButtonNode(textureName: "LifeBackground", hasFadeAnimation: true, hasPressAnimation: false, hasInfiniteAnimation: false)
        lifeBackground.position = CGPoint(x: 0, y: size.height / 2 - lifeBackground.size.height / 2 - 20)
        lifeBackground.zPosition = 200
        lifeBackground.label.fontSize = 24
        lifeBackground.label.fontColor = .black
        addChild(lifeBackground)
        
        newLifeCountdownLabel = lifeBackground.label
        
        let heartButton = CMButtonNode(textureName: "HeartButton", hasFadeAnimation: false, hasPressAnimation: false, hasInfiniteAnimation: true)
        heartButton.position = CGPoint(x: -lifeBackground.size.width / 2, y: size.height / 2 - lifeBackground.size.height / 2 - 20)
        heartButton.zPosition = 300
        heartButton.label.fontSize = 28
        addChild(heartButton)
        
        lifeCountLabel = heartButton.label
    }
    
    func addLevelMap(page: Int, multiplier: CGFloat, yPos: CGFloat) -> LevelMap {
        let levelMap = LevelMap(page: page, multiplier: multiplier)
        levelMap.sprite = SKSpriteNode(texture: SKTexture(imageNamed: "LevelMapBackground"), color: .black, size: size)
        levelMap.sprite!.position = CGPoint(x: 0, y: yPos)
        
        var buttonYPos: CGFloat = -size.height / 2 + 59 / 2 + ((size.height - (10 * 59)) / 2)
        for index in 1...10 {
            let level = index + 10 * levelMap.page
            
            let button = CMButtonNode(textureName: "LevelButton", hasFadeAnimation: false, hasPressAnimation: true, hasInfiniteAnimation: false)
            button.isEnabled = level <= currentLevelNumber
            button.setButtonAction(target: self, actionType: .TouchUpInside, action: #selector(levelButtonTouched))
            button.position = CGPoint(x: (index % 2 == 0 ? 0 : (levelMap.multiplier * (size.width / 2)) + (-levelMap.multiplier * (27 + 54))), y: buttonYPos)
            button.label.text = String(level)
            button.label.fontSize = 26
            button.label.position = CGPoint(x: 0, y: 2)
            
            levelMap.buttons.append(button)
            levelMap.sprite!.addChild(levelMap.buttons.last!)
            
            buttonYPos += 59
            if index % 2 != 0 {
                levelMap.multiplier *= -1
            }
        }
        
        return levelMap
    }
    
    func handleLevelMaps(dy: CGFloat, duration: TimeInterval, timingMode: SKActionTimingMode) {
        if levelMaps.first!.page == 0 && levelMaps.first!.sprite!.position.y + dy - levelMaps.first!.sprite!.size.height / 2 > -size.height / 2 {
            return
        }
        
        for (index, levelMap) in levelMaps.enumerated() {
            if levelMap.sprite!.position.y + dy - levelMap.sprite!.size.height / 2 < -size.height / 2 && levelMap == levelMaps.last! {
                let newLevelMap = addLevelMap(page: levelMap.page + 1, multiplier: levelMap.multiplier, yPos: levelMap.sprite!.position.y + size.height)
                
                levelMaps.append(newLevelMap)
                addChild(levelMaps.last!.sprite!)
                
                if index != 0 {
                    levelMaps[index - 1].sprite!.removeFromParent()
                    levelMaps.remove(at: index - 1)
                }
            }
            
            if levelMap.sprite!.position.y + dy - levelMap.sprite!.size.height / 2 > -size.height / 2 && index == 0 {
                let newLevelMap = addLevelMap(page: levelMap.page - 1, multiplier: levelMap.multiplier, yPos: levelMap.sprite!.position.y - size.height)
                
                levelMaps.insert(newLevelMap, at: 0)
                addChild(levelMaps.first!.sprite!)
                    
                if levelMaps.indices.contains(index + 2) {
                    levelMaps[index + 2].sprite!.removeFromParent()
                    levelMaps.remove(at: index + 2)
                }
            }
        }
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: dy), duration: duration)
        moveAction.timingMode = timingMode
        
        for levelMap in levelMaps {
            levelMap.sprite!.run(moveAction)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard panelLayer.isHidden else {
            return
        }
        
        if let touch = touches.first {
            let dy: CGFloat = touch.location(in: self).y - touch.previousLocation(in: self).y
            
            handleLevelMaps(dy: dy, duration: 0, timingMode: .linear)
        }
    }
    
    @objc func levelButtonTouched(sender: CMButtonNode) {
        showLevelPanel(levelNumber: Int(sender.label.text!)!)
    }
    
    func showLevelPanel(levelNumber: Int) {
        for levelMap in levelMaps {
            for levelButton in levelMap.buttons {
                if levelButton.isEnabled {
                    levelButton.run(SKAction.colorize(withColorBlendFactor: 0.4, duration: 0.2))
                }
                
                levelButton.isUserInteractionEnabled = false
            }
            
            levelMap.sprite!.run(SKAction.colorize(withColorBlendFactor: 0.4, duration: 0.2))
        }
        
        levelPanelLevelNumber = levelNumber
        
        let panelBackground = SKSpriteNode(imageNamed: "PanelBackground")
        panelBackground.size = CGSize(width: 300, height: 360)
        panelLayer.addChild(panelBackground)
        
        let cancelButton = CMButtonNode(textureName: "CircleRedButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        cancelButton.position = CGPoint(x: panelBackground.size.width / 2 - 15, y: panelBackground.size.height / 2 - 75)
        cancelButton.label.fontSize = 26
        cancelButton.label.text = "X"
        cancelButton.setButtonAction(target: self, actionType: .TouchUpInside, action: #selector(panelCancelButtonTouched))
        panelLayer.addChild(cancelButton)
        
        let levelData = LevelData.loadFrom(filename: "Level_\(levelPanelLevelNumber!)")!
        
        let tileWidth: CGFloat = 32.0
        let tileHeight: CGFloat = 36.0
        let cookiesArea: CGFloat = panelBackground.size.width
        let cookiesSize: CGFloat = ((tileWidth * 2) * CGFloat(levelData.target.count)) + (CGFloat(levelData.target.count - 1)) * 10
        let xPos: CGFloat = -panelBackground.size.width / 2 + tileWidth + (cookiesArea - cookiesSize) / 2
        
        for (index, (cookie, count)) in levelData.target.enumerated() {
            let cookieSprite = SKSpriteNode(imageNamed: cookie.capitalized)
            cookieSprite.size = CGSize(width: tileWidth * 2, height: tileHeight * 2)
            let xOffset: CGFloat = CGFloat(index) * cookieSprite.size.width + CGFloat((index == 0 ? 0 : 10) * index)
            cookieSprite.position = CGPoint(x: xPos + xOffset, y: 0)
            panelLayer.addChild(cookieSprite)
            
            let countLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
            countLabel.fontSize = 28
            countLabel.text = String(format: "%ld", count)
            countLabel.position = CGPoint(x: cookieSprite.position.x, y: cookieSprite.position.y - cookieSprite.size.height / 2 - 20)
            panelLayer.addChild(countLabel)
        }
        
        let levelNumberLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        levelNumberLabel.verticalAlignmentMode = .center
        levelNumberLabel.fontSize = 30
        levelNumberLabel.fontColor = .purple
        levelNumberLabel.position = CGPoint(x: 0, y: panelBackground.size.height / 2 - 50)
        levelNumberLabel.text = "Level \(levelNumber)"
        panelLayer.addChild(levelNumberLabel)
        
        let playButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        playButton.position = CGPoint(x: 0, y: -panelBackground.size.height / 2 + playButton.size.height / 2 + 30)
        playButton.label.fontSize = 26
        playButton.label.text = "Play"
        playButton.setButtonAction(target: self, actionType: .TouchUpInside, action: #selector(levelPanelPlayButtonTouched))
        panelLayer.addChild(playButton)
        
        panelLayer.run(SKAction.sequence([
            SKAction.unhide(),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
    }
    
    func showKeepPlayingPanel() {
        for levelMap in levelMaps {
            for levelButton in levelMap.buttons {
                if levelButton.isEnabled {
                    levelButton.run(SKAction.colorize(withColorBlendFactor: 0.4, duration: 0.2))
                }
                
                levelButton.isUserInteractionEnabled = false
            }
            
            levelMap.sprite!.run(SKAction.colorize(withColorBlendFactor: 0.4, duration: 0.2))
        }
        
        let panelBackground = SKSpriteNode(imageNamed: "PanelBackground")
        panelBackground.size = CGSize(width: 300, height: 360)
        panelLayer.addChild(panelBackground)
        
        let cancelButton = CMButtonNode(textureName: "CircleRedButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        cancelButton.position = CGPoint(x: panelBackground.size.width / 2 - 15, y: panelBackground.size.height / 2 - 75)
        cancelButton.label.fontSize = 26
        cancelButton.label.text = "X"
        cancelButton.setButtonAction(target: self, actionType: .TouchUpInside, action: #selector(panelCancelButtonTouched))
        panelLayer.addChild(cancelButton)
        
        let heartButton = CMButtonNode(textureName: "HeartButton", hasFadeAnimation: false, hasPressAnimation: false, hasInfiniteAnimation: true)
        heartButton.size = CGSize(width: 100, height: 86)
        heartButton.zPosition = 300
        heartButton.label.fontSize = 56
        heartButton.label.text = lifeCountLabel!.text
        panelLayer.addChild(heartButton)
        
        let keepPlayingLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        keepPlayingLabel.verticalAlignmentMode = .center
        keepPlayingLabel.fontSize = 30
        keepPlayingLabel.fontColor = .purple
        keepPlayingLabel.position = CGPoint(x: 0, y: panelBackground.size.height / 2 - 50)
        keepPlayingLabel.text = "Keep Playing!"
        panelLayer.addChild(keepPlayingLabel)
        
        let watchAdButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        watchAdButton.position = CGPoint(x: 0, y: -panelBackground.size.height / 2 + watchAdButton.size.height / 2 + 30)
        watchAdButton.label.fontSize = 26
        watchAdButton.label.text = "Watch Ad"
        panelLayer.addChild(watchAdButton)
        
        panelLayer.run(SKAction.sequence([
            SKAction.unhide(),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
    }
    
    @objc func panelCancelButtonTouched() {
        for levelMap in levelMaps {
            for levelButton in levelMap.buttons {
                if levelButton.isEnabled {
                    levelButton.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.2))
                }
                
                levelButton.isUserInteractionEnabled = true
            }
            
            levelMap.sprite!.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.2))
        }
        
        panelLayer.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.hide(),
        ]))
        panelLayer.removeAllChildren()
    }
    
    func replacePanels(newPanelShowFunction: @escaping () -> Void) {
        panelLayer.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.hide(),
        ]), completion: newPanelShowFunction)
        panelLayer.removeAllChildren()
    }
    
    @objc func levelPanelPlayButtonTouched() {
        if Int(lifeCountLabel!.text!)! > 0 {
            levelPanelPlayButtonHandler!(levelPanelLevelNumber!)
        } else {
            replacePanels(newPanelShowFunction: showKeepPlayingPanel)
        }
    }
}
