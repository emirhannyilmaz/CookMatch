//
//  GameViewController.swift
//  CookMatch
//
//  Created by Emirhan Yılmaz on 16.12.2021.
//

import UIKit
import SpriteKit
import AVFoundation

extension UserDefaults {
    static func resetDefaults() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
    }
}

class GameViewController: UIViewController {
    var menuScene: MenuScene!
    var gameScene: GameScene!
    var movesLeft = 0
    var score = 0
    var collectedCookies: [String:Int] = [:]
    var currentLevelNumber = 0
    var life = 0
    var level: Level!
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    var newLifeCountdownTimer: Timer?
    
    let timeRequiredForNewLife = 1800
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UserDefaults.resetDefaults()
        
        if UserDefaults.standard.integer(forKey: "level") == 0 {
            UserDefaults.standard.set(1, forKey: "level")
            UserDefaults.standard.set(5, forKey: "life")
            currentLevelNumber = 1
            life = 5
        } else {
            currentLevelNumber = UserDefaults.standard.integer(forKey: "level")
            life = UserDefaults.standard.integer(forKey: "life")
        }
        
        showMenuScene()
        
        backgroundMusic?.play()
        
         if life != 5 {
            newLifeCountdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(newLifeCountdown), userInfo: nil, repeats: true)
        }
    }
    
    func showMenuScene() {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        menuScene = MenuScene(size: skView.bounds.size)
        menuScene.scaleMode = .aspectFill
        menuScene.currentLevelNumber = currentLevelNumber
        menuScene.addLifeBar()
        
        menuScene.lifeCountLabel!.text = String(life)
        if life == 5 {
            menuScene.newLifeCountdownLabel!.text = "Full"
        }
        
        let firstLevelMap = menuScene.addLevelMap(page: (currentLevelNumber - 1) / 10, multiplier: 1, yPos: 0)
        menuScene.levelMaps.append(firstLevelMap)
        menuScene.addChild(menuScene.levelMaps[0].sprite!)
        menuScene.levelPanelPlayButtonHandler = showGameScene
        
        skView.presentScene(menuScene)
    }
    
    func showGameScene(levelNumber: Int) {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        gameScene = GameScene(size: skView.bounds.size)
        gameScene.scaleMode = .aspectFill
        
        level = Level(filename: "Level_\(levelNumber)")
        gameScene.level = level
        gameScene.addTiles()
        gameScene.addTargetCookiesSprites()
        gameScene.swipeHandler = handleSwipe
        
        skView.presentScene(gameScene)
        
        beginGame()
    }
    
    func beginGame() {
        movesLeft = level.moves
        score = 0
        collectedCookies = [:]
        updateLabels()
        level.resetComboMultiplier()
        gameScene.animateBeginGame {
            
        }
        shuffle()
    }
    
    func shuffle() {
        gameScene.removeAllCookieSprites()
        let newCookies = level.shuffle()
        gameScene.addSprites(for: newCookies)
    }
    
    func handleSwipe(_ swap: Swap) {
        view.isUserInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            gameScene.animateSwap(swap, completion: handleMatches)
        } else {
            gameScene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        
        gameScene.animateMatchedCookies(for: chains) {
            for chain in chains {
                for cookie in chain.cookies {
                    if self.collectedCookies[cookie.cookieType.description] != nil {
                        self.collectedCookies[cookie.cookieType.description]! += 1
                    } else {
                        self.collectedCookies[cookie.cookieType.description] = 1
                    }
                }
                self.score += chain.score
                self.gameScene.animateScore(for: chain)
            }
            self.updateLabels()
            
            let columns = self.level.fillHoles()
            self.gameScene.animateFallingCookies(in: columns) {
                let columns = self.level.topUpCookies()
                self.gameScene.animateNewCookies(in: columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        decreaseMoves()
        if level.getPossibleSwapsCount() == 0 {
            shuffle()
        }
        view.isUserInteractionEnabled = true
    }
    
    func updateLabels() {
        gameScene.movesLabel!.text = String(format: "%ld", movesLeft)
        gameScene.scoreLabel!.text = String(score)
    }
    
    func decreaseMoves() {
        movesLeft -= 1
        updateLabels()
        
        var victory = false
        for (index, (name, count)) in level.target.enumerated() {
            if collectedCookies[name] != nil {
                if collectedCookies[name]! >= count {
                    if index == level.target.count - 1 {
                        victory = true
                    }
                    continue
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        if victory {
            showGameOver(victory: true, currentLevelNumber: currentLevelNumber)
            currentLevelNumber = currentLevelNumber < numLevels ? currentLevelNumber + 1 : 1
            UserDefaults.standard.set(currentLevelNumber, forKey: "level")
        } else if movesLeft == 0 {
            showGameOver(victory: false, currentLevelNumber: currentLevelNumber)
            life -= 1
            UserDefaults.standard.set(life, forKey: "life")
            if UserDefaults.standard.object(forKey: "newLifeCountdownStartTime") == nil {
                UserDefaults.standard.set(Date(), forKey: "newLifeCountdownStartTime")
                newLifeCountdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(newLifeCountdown), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func newLifeCountdown() {
        let timeDifference = Calendar.current.dateComponents([.second], from: UserDefaults.standard.object(forKey: "newLifeCountdownStartTime")! as! Date, to: Date())
        let countdownTime = timeRequiredForNewLife - timeDifference.second!
        
        // If game opens with minus countdown time give life(s) to player.
        if countdownTime < 0 {
            life += 1
            life += -countdownTime / timeRequiredForNewLife
            
            if life > 5 {
                life = 5
            }
            
            if life != 5 {
                UserDefaults.standard.set(life, forKey: "life")
                let timeInterval = TimeInterval(Int(-countdownTime % timeRequiredForNewLife) * -1)
                UserDefaults.standard.set(Date().addingTimeInterval(timeInterval), forKey: "newLifeCountdownStartTime")
                menuScene.lifeCountLabel!.text = String(life)
                return
            } else {
                UserDefaults.standard.set(life, forKey: "life")
                menuScene.lifeCountLabel!.text = String(life)
                menuScene.newLifeCountdownLabel!.text = "Full"
                UserDefaults.standard.removeObject(forKey: "newLifeCountdownStartTime")
                newLifeCountdownTimer!.invalidate()
                return
            }
        }
        
        menuScene.newLifeCountdownLabel!.text = String(format: "%02d", countdownTime / 60) + ":" + String(format: "%02d", countdownTime % 60)
        
        if countdownTime == 0 {
            life += 1
            UserDefaults.standard.set(life, forKey: "life")
            UserDefaults.standard.set(Date(), forKey: "newLifeCountdownStartTime")
            menuScene.lifeCountLabel!.text = String(life)
        }
        
        if life == 5 {
            menuScene.newLifeCountdownLabel!.text = "Full"
            UserDefaults.standard.removeObject(forKey: "newLifeCountdownStartTime")
            newLifeCountdownTimer!.invalidate()
        }
    }
    
    func showGameOver(victory: Bool, currentLevelNumber: Int) {
        gameScene.animateGameOver {
            if victory {
                self.gameScene.showLevelCompleted(currentLevelNumber: currentLevelNumber, score: self.score, target: self, menuButtonAction: #selector(self.menuButtonTouched), nextButtonAction: #selector(self.nextButtonTouched))
            } else {
                self.gameScene.showLevelFailed(currentLevelNumber: currentLevelNumber, score: self.score, target: self, menuButtonAction: #selector(self.menuButtonTouched), retryButtonAction: #selector(self.retryButtonTouched))
            }
        }
    }
    
    @objc func menuButtonTouched() {
        showMenuScene()
    }
    
    @objc func nextButtonTouched() {
        showGameScene(levelNumber: currentLevelNumber)
    }
    
    @objc func retryButtonTouched() {
        showGameScene(levelNumber: currentLevelNumber)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
