//
//  GameScene.swift
//  Math Grab 
//
//  Created by Kevin Zmijewski on 7/20/25.
//

import SpriteKit
import SwiftUI

@objcMembers
class GameScene: SKScene {
    
    //MARK: - Class variables
    
    @AppStorage("highScore") var highScore: Int = 0
    
    private var readySetGoLabel = SKLabelNode(fontNamed: "Chalkboard")
    private let pauseButton = SKSpriteNode(imageNamed: "pauseButtonImage")
    private var scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var questionLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var answerLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var timerLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var timerTextLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var highScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    private var endScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    private var timeInSeconds: Int = 60
    private var pauseTimer: Bool = false
    private var countDownComplete: Bool = false
    private var questionList: [Int] = []
    private var answerList: [Int] = [0]
    
    private var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
            readySetGoLabel.text = "GET READY"
            endScoreLabel.text = "YOUR SCORE: \(score)"
            highScoreLabel.text = "HIGH SCORE: \(highScore)"
        }
    }
    
    //MARK: - Override Methods
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -3)
        score = 0
        
        let background = SKSpriteNode(imageNamed: "backgroundChalkboard")
        background.name = "background"
        background.size.width = view.bounds.width
        background.size.height = view.bounds.height
        background.zPosition = -1
        self.addChild(background)
        
        pauseButton.name = "pauseButton"
        pauseButton.size = CGSize(width: 80, height: 80)
        pauseButton.position = CGPoint(x: frame.width / 3, y: -frame.height / 3)
        pauseButton.zPosition = 100
        self.addChild(pauseButton)
        
        timerLabel.fontColor = UIColor.white
        timerLabel.position.y = 100
        timerLabel.zPosition = 100
        timerLabel.name = "timerLabel"
        timerLabel.text = String(timeInSeconds)
        timerLabel.fontSize = 20
        timerLabel.isUserInteractionEnabled = false
        self.addChild(timerLabel)
        
        highScoreLabel.isHidden = true
        highScoreLabel.fontColor = UIColor.white
        highScoreLabel.zPosition = 100
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.fontSize = 32
        highScoreLabel.isUserInteractionEnabled = false
        self.addChild(highScoreLabel)
        
        endScoreLabel.isHidden = true
        endScoreLabel.fontColor = UIColor.white
        endScoreLabel.position.y = 50
        endScoreLabel.zPosition = 100
        endScoreLabel.name = "endScoreLabel"
        endScoreLabel.fontSize = 32
        endScoreLabel.isUserInteractionEnabled = false
        self.addChild(endScoreLabel)
        
        scoreLabel.fontColor = UIColor.white
        scoreLabel.position.y = 145
        scoreLabel.zPosition = 99
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 50
        scoreLabel.isUserInteractionEnabled = false
        self.addChild(scoreLabel)
        
        answerLabel.fontColor = UIColor.white
        answerLabel.position.y = 90
        answerLabel.position.x = frame.width / 3
        answerLabel.zPosition = 99
        answerLabel.name = "answerBlockLabel"
        answerLabel.text = "YOUR COUNT"
        answerLabel.fontSize = 20
        answerLabel.isUserInteractionEnabled = false
        self.addChild(answerLabel)
        
        questionLabel.fontColor = UIColor.white
        questionLabel.position.y = 90
        questionLabel.position.x = -frame.width / 3
        questionLabel.zPosition = 99
        questionLabel.name = "questionLabel"
        questionLabel.text = "FIND THE SUM"
        questionLabel.fontSize = 20
        questionLabel.isUserInteractionEnabled = false
        self.addChild(questionLabel)
        
        generateQuestion(numOfElements: 2)
        generateAnswerTotalBlock()
        playOpeningSound()
        generateReadyGetGoMessages()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let music = await SKAudioNode(fileNamed: "PixelAdventures")
                await self.addChild(music)
            }
            
            Task {
                for _ in 1...7 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    await self.generateCollectable()
                }
            }
            timer.invalidate()
        }

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else { return }
        
        if tapped.name != "background" && tapped.name != "pauseButton" && tapped.name != "blankBlockImage" && tapped.name != "blockLabel" && tapped.name != "scoreLabel" && tapped.name != "answerLabel" && tapped.name != "questionLabel" && tapped.name != "answerTotalBlock" && tapped.name != "answerBlockLabel" && tapped.name != "symbolBlock" &&  tapped.name != "readySetGoLabel" && tapped.name != "timerLabel" && tapped.name != "highScoreLabel" && tapped.name != "endScoreLabel" && self.countDownComplete == true && self.view?.isPaused == false && self.timeInSeconds > 0 {
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.destroyAnswerBlocks()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.generateCollectable()
                
                self.addBlockToAnswerQueue(tappedNode: tapped.name ?? "")
                self.compareCurrentAnswerQueueToQuestionQueue()
            }
            
            playItemCollectedSound()
            tapped.removeFromParent()
        }

        if pauseButton.contains(location) && self.timeInSeconds > 0 && self.countDownComplete == true{
            if (!self.view!.isPaused) {
                self.view?.isPaused = true
                self.pauseTimer = true
            } else {
                self.view?.isPaused = false
                self.pauseTimer = false
                startGameTimer()
            }
        }
        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func update(_ currentTime: TimeInterval) {
        
        for node in children {
            if node.position.y < -400 {
                node.removeFromParent()
                generateCollectable()
            }
        }
        
        if timeInSeconds <= 0 {
            endofRound()
        }
        
    }
    
    //MARK: - Game Timer
    
    func startGameTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            self.timeInSeconds -= 1
            if self.timeInSeconds <= 0 {
                timer.invalidate()
            } else if self.pauseTimer {
                timer.invalidate()
            }
            self.timerLabel.text = "\(self.timeInSeconds)"
        }
    }
    
    //MARK: - Sound Effects
    
    func playItemCollectedSound() {
        let sound = SKAction.playSoundFileNamed("bonus.wav", waitForCompletion: false)
        run(sound)
    }
    
    func playNewHighScoreSound() {
        let sound = SKAction.playSoundFileNamed("newHighScore.mp3", waitForCompletion: false)
        run(sound)
    }
    
    func playScoreUpSound() {
        Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) { timer in
            Task {
                try await Task.sleep(nanoseconds: 0_200_000_000)
                let sound = SKAction.playSoundFileNamed("coinBonus.mp3", waitForCompletion: false)
                await self.run(sound)
            }
            timer.invalidate()
        }
    }
    
    func playScoreDownSound() {
        Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) { timer in
            Task {
                try await Task.sleep(nanoseconds: 0_150_000_000)
                let sound = SKAction.playSoundFileNamed("blip.mp3", waitForCompletion: false)
                await self.run(sound)
            }
            timer.invalidate()
        }
    }
    
    func playOpeningSound() {
        let sound = SKAction.playSoundFileNamed("beep.mp3", waitForCompletion: false)
        Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) { timer in
            Task {
                try await Task.sleep(nanoseconds: 0_000_000_000)
                await self.run(sound)
            }
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await self.run(sound)
            }
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await self.run(sound)
                await self.startGameTimer()
            }
            timer.invalidate()
        }
    }
    
    //MARK: - Question And Answer Handling
    
    func compareCurrentAnswerQueueToQuestionQueue() {
        if answerList.reduce(0,+) == questionList.reduce(0,+) {
            playScoreUpSound()
            score += 1
            questionList.removeAll()
            answerList.removeAll()
            destroyQuestionBlocks()
            generateQuestion(numOfElements: 2)
        } else if answerList.reduce(0,+) > questionList.reduce(0,+) {
            score -= 1
            playScoreDownSound()
            answerList.removeAll()
        }
    } 
    
    func addBlockToAnswerQueue(tappedNode: String) {
        if let lastChar = tappedNode.last {
            if let convertToInt = Int(String(lastChar)) {
                if convertToInt == 0 {
                    answerList.append(questionList.reduce(0,+)-answerList.reduce(0,+))
                } else {
                    answerList.append(convertToInt)
                }
            }
        }
        generateAnswerTotalBlock()
    }
    
    func generateAnswerTotalBlock() {
        let sprite = SKSpriteNode(imageNamed: "blankBlockImage")
        sprite.name = "answerTotalBlock"
        
        sprite.size = CGSize(width: 50, height: 50)
        sprite.zPosition = 100
        sprite.isUserInteractionEnabled = false
        
        sprite.position = CGPoint(x: frame.width / 3, y: frame.height / 3)
        
        let blockLabel = SKLabelNode(fontNamed: "Arial")
        blockLabel.name = "answerLabel"
        blockLabel.text = String(answerList.reduce(0,+) < questionList.reduce(0,+) ? answerList.reduce(0,+) : 0)
        blockLabel.fontSize = 28
        blockLabel.blendMode = .add
        blockLabel.horizontalAlignmentMode = .center
        blockLabel.verticalAlignmentMode = .center
        blockLabel.fontColor = .black
        blockLabel.zPosition = 105
        blockLabel.isUserInteractionEnabled = false
        
        sprite.addChild(blockLabel)
        addChild(sprite)
    }
    
    func generateQuestion(numOfElements: Int) {
        if numOfElements < 2 { return }
        generateMathSymbolCollectable()
        for _ in 0..<numOfElements {
            questionList.append(Int.random(in: 1...10))
        }
        for i in 0..<questionList.count {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.generateQuestionCollectable(elementNumber: self.questionList[i],elementPosition: i)
            }
        }
    }
    
    func generateMathSymbolCollectable() {
        let sprite = SKSpriteNode(imageNamed: "blankBlockImage")
        sprite.name = "symbolBlock"
        
        sprite.size = CGSize(width: 50, height: 50)
        sprite.zPosition = 100
        sprite.isUserInteractionEnabled = false
        
        sprite.position = CGPoint(x: (-frame.width / 3) - 0, y: frame.height / 3)
        
        let blockLabel = SKLabelNode(fontNamed: "Arial")
        blockLabel.name = "blockLabel"
        blockLabel.text = String("+")
        blockLabel.fontSize = 30
        blockLabel.blendMode = .add
        blockLabel.horizontalAlignmentMode = .center
        blockLabel.verticalAlignmentMode = .center
        blockLabel.fontColor = .black
        blockLabel.zPosition = 105
        blockLabel.isUserInteractionEnabled = false
        
        sprite.addChild(blockLabel)
        addChild(sprite)
    }
    
    func generateQuestionCollectable(elementNumber: Int, elementPosition: Int) {
        let sprite = SKSpriteNode(imageNamed: "blankBlockImage")
        sprite.name = "blankBlockImage"
        
        sprite.size = CGSize(width: 50, height: 50)
        sprite.zPosition = 100
        sprite.isUserInteractionEnabled = false
        
        if elementPosition == 0 {
            sprite.position = CGPoint(x: (-frame.width / 3) - 50, y: frame.height / 3)
        } else {
            sprite.position = CGPoint(x: (-frame.width / 3) + 50, y: frame.height / 3)
        }
        
        let blockLabel = SKLabelNode(fontNamed: "Arial")
        blockLabel.name = "blockLabel"
        blockLabel.text = String(elementNumber)
        blockLabel.fontSize = 28
        blockLabel.blendMode = .add
        blockLabel.horizontalAlignmentMode = .center
        blockLabel.verticalAlignmentMode = .center
        blockLabel.fontColor = .black
        blockLabel.zPosition = 105
        blockLabel.isUserInteractionEnabled = false
        
        sprite.addChild(blockLabel)
        addChild(sprite)
    }
    
    func destroyQuestionBlocks() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            for node in self.children {
                if node.name == "blockLabel" || node.name == "blankBlockImage" {
                    node.removeFromParent()
                }
            }
        }
    }
    
    func destroyAnswerBlocks() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            for node in self.children {
                if node.name == "answerLabel" || node.name == "answerTotalBlock" {
                    node.removeFromParent()
                }
            }
        }
    }
    
    func generateCollectable() {
        let sprites = [ "blockNumber0", "blockNumber1", "blockNumber2", "blockNumber3", "blockNumber4", "blockNumber5", "blockNumber6", "blockNumber7", "blockNumber8", "blockNumber9" ]
        
        let spriteName = sprites.randomElement()!
        let directionalChange = [ 1.0, -1.0 ]
        let directionChange: Double = directionalChange.randomElement()!
        let collectable = SKSpriteNode(imageNamed: spriteName)
        
        collectable.name = spriteName
        collectable.size = CGSize(width: 70, height: 70)
        collectable.physicsBody = SKPhysicsBody(texture: collectable.texture!, size: collectable.size)
        collectable.physicsBody?.isDynamic = true
        collectable.physicsBody?.affectedByGravity = true
        collectable.texture!.filteringMode = .nearest
        collectable.zPosition = 0
        collectable.position = CGPoint(x: Double.random(in: -300..<300), y: -400)
        collectable.physicsBody?.velocity = CGVector(dx: directionChange * 50, dy: 700)
        
        addChild(collectable)
    }
    
    //MARK: - Ready, Set, Go
    
    func generateReadyGetGoMessages() {
        readySetGoLabel.fontColor = UIColor.white
        readySetGoLabel.position.y = -20
        readySetGoLabel.position.x = 0
        readySetGoLabel.zPosition = 99
        readySetGoLabel.name = "readySetGoLabel"
        readySetGoLabel.fontSize = 62
        readySetGoLabel.isUserInteractionEnabled = false
        self.addChild(readySetGoLabel)
        Timer.scheduledTimer(withTimeInterval: 1.1, repeats: false) { timer in
            self.readySetGoLabel.text = "GET SET!"
            timer.invalidate()
        }
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { timer in
            self.readySetGoLabel.text = "GO!"
            timer.invalidate()
        }
        Timer.scheduledTimer(withTimeInterval: 3.2, repeats: false) { timer in
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                for node in self.children {
                    if node.name == "readySetGoLabel" {
                        node.removeFromParent()
                    }
                }
            }
            timer.invalidate()
            self.countDownComplete = true
        }
    }
    
    //MARK: - End of Round
    
    func endofRound() {
        if self.highScore < self.score {
            self.highScore = self.score
            playNewHighScoreSound()
        }
        gameOver()
        highScoreLabel.isHidden = false
        endScoreLabel.isHidden = false
    }
    
    //MARK: - Game Over
    
    func gameOver() {
        isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for node in self.children {
                if node.name == "scoreLabel" || node.name == "background" || node.name == "highScoreLabel" || node.name == "endScoreLabel" { continue }
                node.removeFromParent()
            }
        }
        scoreLabel.removeFromParent()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .resizeFill
                self.view?.presentScene(scene)
            }
        }
    }
    
}

