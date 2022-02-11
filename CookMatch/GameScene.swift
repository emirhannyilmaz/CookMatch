//
//  GameScene.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 16.12.2021.
//

import SpriteKit

class GameScene: SKScene {
    var swipeHandler: ((Swap) -> Void)?
    var level: Level!
    
    let tileWidth: CGFloat = 32.0
    let tileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let gameOverLayer = SKNode()
    let cookiesLayer = SKNode()
    let targetCookiesLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    
    private var selectionSprite = SKSpriteNode()
    
    private var target: [String: (SKSpriteNode, SKLabelNode)] = [:]
    
    var movesLabel: SKLabelNode?
    var scoreLabel: SKLabelNode?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        
        gameLayer.isHidden = true
        addChild(gameLayer)
        
        let informationBackground = SKSpriteNode(imageNamed: "InformationBackground")
        informationBackground.size = CGSize(width: size.width, height: 70)
        informationBackground.position.y = size.height / 2 - informationBackground.size.height / 2 - 20
        gameLayer.addChild(informationBackground)
        
        let movesBackground = SKSpriteNode(imageNamed: "MovesBackground")
        movesBackground.size = CGSize(width: 90, height: 90)
        movesBackground.position.y = size.height / 2 - movesBackground.size.height / 2 - 10
        gameLayer.addChild(movesBackground)
        
        movesLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        movesLabel!.fontSize = 22
        movesLabel!.position = CGPoint(x: informationBackground.position.x, y: informationBackground.position.y)
        movesLabel!.horizontalAlignmentMode = .center
        movesLabel!.verticalAlignmentMode = .center
        gameLayer.addChild(movesLabel!)
        
        scoreLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        scoreLabel!.fontSize = 18
        scoreLabel!.position = CGPoint(x: -size.width / 2 + 30, y: informationBackground.position.y)
        scoreLabel!.horizontalAlignmentMode = .left
        scoreLabel!.verticalAlignmentMode = .center
        gameLayer.addChild(scoreLabel!)
        
        let cookiesLayerPosition = CGPoint(x: -tileWidth * CGFloat(numColumns) / 2, y: -tileHeight * CGFloat(numRows) / 2)
        tilesLayer.position = cookiesLayerPosition
        maskLayer.position = cookiesLayerPosition
        cropLayer.maskNode = maskLayer
        cookiesLayer.position = cookiesLayerPosition
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(cropLayer)
        cropLayer.addChild(cookiesLayer)
        targetCookiesLayer.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        gameLayer.addChild(targetCookiesLayer)
        
        gameOverLayer.isHidden = true
        addChild(gameOverLayer)
    }
    
    func addSprites(for cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.size = CGSize(width: tileWidth, height: tileHeight)
            sprite.position = pointFor(column: cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.25, withRange: 0.5),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.scale(to: 1.0, duration: 0.25)
                ])
            ]))
        }
    }
    
    func addTiles() {
        for row in 0..<numRows {
            for column in 0..<numColumns {
                if level.tileAt(column: column, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    tileNode.position = pointFor(column: column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for row in 0...numRows {
            for column in 0...numColumns {
                let topLeft = (column > 0) && (row < numRows) && level.tileAt(column: column - 1, row: row) != nil
                let bottomLeft = (column > 0) && (row > 0) && level.tileAt(column: column - 1, row: row - 1) != nil
                let topRight = (column < numColumns) && (row < numRows) && level.tileAt(column: column, row: row) != nil
                let bottomRight = (column < numColumns) && (row > 0) && level.tileAt(column: column, row: row - 1) != nil
                
                let topLeftInt = topLeft ? 1 : 0
                let bottomLeftInt = bottomLeft ? 1 : 0
                let topRightInt = topRight ? 1 : 0
                let bottomRightInt = bottomRight ? 1 : 0
                
                var value = topLeftInt
                value = value | topRightInt << 1
                value = value | bottomLeftInt << 2
                value = value | bottomRightInt << 3
                
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    tileNode.size = CGSize(width: tileWidth, height: tileHeight)
                    var point = pointFor(column: column, row: row)
                    point.x -= tileWidth / 2
                    point.y -= tileHeight / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func addTargetCookiesSprites() {
        let cookiesArea: CGFloat = size.width / 2 - 45 - 30
        let cookiesSize: CGFloat = (tileWidth * CGFloat(level.target.count)) + (CGFloat(level.target.count - 1)) * 5
        let xPos: CGFloat = size.width - 30 - (cookiesArea - cookiesSize) / 2 - tileWidth / 2
        
        for (index, (cookie, count)) in level.target.enumerated() {
            let cookieSprite = SKSpriteNode(imageNamed: cookie.capitalized)
            cookieSprite.size = CGSize(width: tileWidth, height: tileHeight)
            let xOffset: CGFloat = CGFloat(index) * cookieSprite.size.width + CGFloat((index == 0 ? 0 : 5) * index)
            cookieSprite.position = CGPoint(x: xPos - xOffset, y: size.height - 50)
            targetCookiesLayer.addChild(cookieSprite)
            
            let countLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
            countLabel.fontSize = 14
            countLabel.text = String(format: "%ld", count)
            countLabel.position = CGPoint(x: cookieSprite.position.x, y: cookieSprite.position.y - cookieSprite.size.height / 2 - 10)
            targetCookiesLayer.addChild(countLabel)
            
            target[cookie] = (cookieSprite, countLabel)
        }
    }
    
    private func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(x: CGFloat(column) * tileWidth + tileWidth / 2, y: CGFloat(row) * tileHeight + tileHeight / 2)
    }
    
    private func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(numColumns) * tileWidth && point.y >= 0 && point.y < CGFloat(numRows) * tileHeight {
            return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
        } else {
            return (false, 0, 0)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: cookiesLayer)
        let (success, column, row) = convertPoint(location)
        
        if success {
            if let cookie = level.cookieAt(column: column, row: row) {
                swipeFromColumn = column
                swipeFromRow = row
                showSelectionIndicator(of: cookie)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromColumn != nil else {
            return
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: cookiesLayer)
        let (success, column, row) = convertPoint(location)
        
        if success {
            var horizontalDelta = 0
            var verticalDelta = 0
            
            if column < swipeFromColumn! {
                horizontalDelta = -1
            } else if column > swipeFromColumn! {
                horizontalDelta = 1
            } else if row < swipeFromRow! {
                verticalDelta = -1
            } else if row > swipeFromRow! {
                verticalDelta = 1
            }
            
            if horizontalDelta != 0 || verticalDelta != 0 {
                trySwap(horizontalDelta: horizontalDelta, verticalDelta: verticalDelta)
                
                hideSelectionIndicator()
                
                swipeFromColumn = nil
            }
        }
    }
    
    private func trySwap(horizontalDelta: Int, verticalDelta: Int) {
        let toColumn = swipeFromColumn! + horizontalDelta
        let toRow = swipeFromRow! + verticalDelta
        
        guard toColumn >= 0 && toColumn < numColumns else {
            return
        }
        
        guard toRow >= 0 && toRow < numRows else {
            return
        }
        
        if let toCookie = level.cookieAt(column: toColumn, row: toRow), let fromCookie = level.cookieAt(column: swipeFromColumn!, row: swipeFromRow!) {
            if let handler = swipeHandler {
                let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                handler(swap)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    func animateSwap(_ swap: Swap, completion: @escaping () -> Void) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        
        run(swapSound)
    }
    
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> Void) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        
        run(invalidSwapSound)
    }
    
    func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> Void) {
        for chain in chains {
            var lastCookieDelay: TimeInterval = -0.2
            for cookie in chain.cookies.reversed() {
                if let sprite = cookie.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        if let (targetSprite, label) = target[cookie.cookieType.description] {
                            sprite.move(toParent: targetCookiesLayer)
                            
                            let moveAction = SKAction.move(to: targetSprite.position, duration: 0.8)
                            moveAction.timingMode = .easeIn
                            let fadeOutAction = SKAction.fadeOut(withDuration: 0.8)
                            fadeOutAction.timingMode = .easeIn
                            sprite.run(SKAction.sequence([
                                SKAction.wait(forDuration: lastCookieDelay + 0.2),
                                SKAction.group([
                                    moveAction,
                                    fadeOutAction
                                ]),
                                SKAction.removeFromParent()
                            ]), withKey: "removing")
                            
                            lastCookieDelay += 0.2
                            
                            let scaleUpAction = SKAction.scale(to: 1.1, duration: 0.1)
                            scaleUpAction.timingMode = .easeIn
                            let scaleDownAction = SKAction.scale(to: 1.0, duration: 0.1)
                            scaleDownAction.timingMode = .easeOut
                            targetSprite.run(SKAction.sequence([
                                SKAction.wait(forDuration: lastCookieDelay + 0.8),
                                scaleUpAction,
                                scaleDownAction
                            ]), completion: updateNumber)
                            
                            func updateNumber() {
                                let number = Int(label.text!)! - 1
                                
                                if number > 0 {
                                    label.text = String(format: "%ld", number)
                                } else {
                                    if label.action(forKey: "removing") == nil {
                                        label.run(SKAction.sequence([
                                            SKAction.fadeOut(withDuration: 0.05),
                                            SKAction.removeFromParent()
                                        ]), withKey: "removing")
                                    }
                                }
                            }
                        } else {
                            let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                            scaleAction.timingMode = .easeOut
                            let fadeOutAction = SKAction.fadeOut(withDuration: 0.3)
                            fadeOutAction.timingMode = .easeOut
                            sprite.run(SKAction.sequence([
                                SKAction.group([
                                    scaleAction,
                                    fadeOutAction
                                ]),
                                SKAction.removeFromParent()
                            ]), withKey: "removing")
                        }
                    }
                }
            }
        }
        
        run(matchSound)
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    func animateFallingCookies(in columns: [[Cookie]], completion: @escaping () -> Void) {
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            for (index, cookie) in array.enumerated() {
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                
                let delay = 0.05 + 0.15 * TimeInterval(index)
                let sprite = cookie.sprite!
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / tileHeight) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            moveAction,
                            fallingCookieSound
                        ])
                    ])
                )
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewCookies(in columns: [[Cookie]], completion: @escaping () -> Void) {
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            let startRow = array[0].row + 1
            
            for (index, cookie) in array.enumerated() {
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.size = CGSize(width: tileWidth, height: tileHeight)
                sprite.position = pointFor(column: cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                
                let delay = 0.1 + 0.2 * TimeInterval(array.count - index - 1)
                let duration = TimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction,
                            addCookieSound
                        ])
                    ])
                )
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateScore(for chain: Chain) {
        let offset: CGPoint = CGPoint(x: (size.width / 2) - (tileWidth * CGFloat(numColumns) / 2), y: (size.height / 2) - (tileHeight * CGFloat(numRows) / 2))
        
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x) / 2 + (firstSprite.parent == targetCookiesLayer ? -offset.x : 0),
            y: (firstSprite.position.y + lastSprite.position.y) / 2 + (lastSprite.parent == targetCookiesLayer ? -offset.y : 0)
        )
        
        let scoreLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 5), duration: 0.8)
        moveAction.timingMode = .easeOut
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.8)
        fadeOutAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([
            SKAction.group([
                moveAction,
                fadeOutAction
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    func animateGameOver(_ completion: @escaping () -> Void) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func showLevelCompleted(currentLevelNumber: Int, score: Int, target: AnyObject, menuButtonAction: Selector, nextButtonAction: Selector) {
        let panelBackground = SKSpriteNode(imageNamed: "PanelBackground")
        panelBackground.size = CGSize(width: 300, height: 360)
        
        let currentLevelNumberLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        currentLevelNumberLabel.verticalAlignmentMode = .center
        currentLevelNumberLabel.fontSize = 30
        currentLevelNumberLabel.fontColor = .purple
        currentLevelNumberLabel.position = CGPoint(x: 0, y: panelBackground.size.height / 2 - 50)
        currentLevelNumberLabel.text = "Level \(currentLevelNumber)"
        
        let levelCompletedLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        levelCompletedLabel.verticalAlignmentMode = .center
        levelCompletedLabel.fontSize = 30
        levelCompletedLabel.fontColor = .white
        levelCompletedLabel.position = CGPoint(x: 0, y: 40)
        levelCompletedLabel.text = "Level Completed"
        
        let scoreLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.text = "Score: \(score)"
        
        let menuButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        menuButton.position = CGPoint(x: -menuButton.size.width / 2 - 15, y: -panelBackground.size.height / 2 + menuButton.size.height / 2 + 30)
        menuButton.label.fontSize = 26
        menuButton.label.text = "Menu"
        menuButton.setButtonAction(target: target, actionType: .TouchUpInside, action: menuButtonAction)
        
        let nextButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        nextButton.position = CGPoint(x: nextButton.size.width / 2 + 15, y: -panelBackground.size.height / 2 + nextButton.size.height / 2 + 30)
        nextButton.label.fontSize = 26
        nextButton.label.text = "Next"
        nextButton.setButtonAction(target: target, actionType: .TouchUpInside, action: nextButtonAction)
        
        gameOverLayer.addChild(panelBackground)
        gameOverLayer.addChild(currentLevelNumberLabel)
        gameOverLayer.addChild(levelCompletedLabel)
        gameOverLayer.addChild(scoreLabel)
        gameOverLayer.addChild(menuButton)
        gameOverLayer.addChild(nextButton)
        
        gameOverLayer.isHidden = false
    }
    
    func showLevelFailed(currentLevelNumber: Int, score: Int, target: AnyObject, menuButtonAction: Selector, retryButtonAction: Selector) {
        let panelBackground = SKSpriteNode(imageNamed: "PanelBackground")
        panelBackground.size = CGSize(width: 300, height: 360)
        
        let currentLevelNumberLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        currentLevelNumberLabel.verticalAlignmentMode = .center
        currentLevelNumberLabel.fontSize = 30
        currentLevelNumberLabel.fontColor = .purple
        currentLevelNumberLabel.position = CGPoint(x: 0, y: panelBackground.size.height / 2 - 50)
        currentLevelNumberLabel.text = "Level \(currentLevelNumber)"
        
        let levelFailedLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        levelFailedLabel.verticalAlignmentMode = .center
        levelFailedLabel.fontSize = 30
        levelFailedLabel.fontColor = .white
        levelFailedLabel.position = CGPoint(x: 0, y: 40)
        levelFailedLabel.text = "Level Failed"
        
        let scoreLabel = SKLabelNode(fontNamed: "LeckerliOne-Regular")
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.text = "Score: \(score)"
        
        let menuButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        menuButton.position = CGPoint(x: -menuButton.size.width / 2 - 15, y: -panelBackground.size.height / 2 + menuButton.size.height / 2 + 30)
        menuButton.label.fontSize = 26
        menuButton.label.text = "Menu"
        menuButton.setButtonAction(target: target, actionType: .TouchUpInside, action: menuButtonAction)
        
        let retryButton = CMButtonNode(textureName: "PinkButton", hasFadeAnimation: true, hasPressAnimation: true, hasInfiniteAnimation: true)
        retryButton.position = CGPoint(x: retryButton.size.width / 2 + 15, y: -panelBackground.size.height / 2 + retryButton.size.height / 2 + 30)
        retryButton.label.fontSize = 26
        retryButton.label.text = "Retry"
        retryButton.setButtonAction(target: target, actionType: .TouchUpInside, action: retryButtonAction)
        
        gameOverLayer.addChild(panelBackground)
        gameOverLayer.addChild(currentLevelNumberLabel)
        gameOverLayer.addChild(levelFailedLabel)
        gameOverLayer.addChild(scoreLabel)
        gameOverLayer.addChild(menuButton)
        gameOverLayer.addChild(retryButton)
        
        gameOverLayer.isHidden = false
    }
    
    func animateBeginGame(_ completion: @escaping () -> Void) {
        gameLayer.isHidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
    
    func showSelectionIndicator(of cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: tileWidth, height: tileHeight)
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
}
