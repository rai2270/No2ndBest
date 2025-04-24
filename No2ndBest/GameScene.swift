//
//  GameScene.swift
//  No2ndBest
//
//  Created by TR on 4/12/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game elements
    private var centerCircle: SKShapeNode!
    private var ball: SKShapeNode!
    private var tapTarget: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    private var pathNodes: [SKShapeNode] = []
    
    // Crypto bubbles elements
    private var cryptoBubbles: [SKNode] = []
    private var dataUpdateTimer: Timer?
    
    // Game parameters
    private var radius: CGFloat = 0
    private var ballRadius: CGFloat = 0
    private var score: Int = 0
    private var highScore: Int = 0
    private var gameRunning = false
    private var lastTapTime: TimeInterval = 0
    private var gameSpeed: CGFloat = 1.0
    private var speedIncrease: CGFloat = 0.1
    private var hitAccuracy: CGFloat = 6.0  // Increased initial hit area
    private var currentTime: TimeInterval = 0
    private var pathAngle: CGFloat = 0
    private var missedTaps: Int = 0
    private var maxMissedTaps: Int = 3  // Allow 3 missed taps before game over
    
    // Physics categories for crypto bubbles
    private let bubbleCategory: UInt32 = 0x1 << 0
    private let ballCategory: UInt32 = 0x1 << 1
    
    // Additional properties for pause functionality
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupGame()
        setupPauseButton()
        setupCryptoBubbles()
        
        // Set up physics contact delegate
        physicsWorld.contactDelegate = self
        
        // Load high score from UserDefaults
        highScore = UserDefaults.standard.integer(forKey: "highScore")
        
        // Start background music if needed
        if UserDefaults.standard.bool(forKey: "musicEnabled") {
            SoundManager.shared.startBackgroundMusic()
        }
        
        // Set up a timer to periodically fetch new cryptocurrency data
        fetchCryptoData()
        dataUpdateTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(fetchCryptoData), userInfo: nil, repeats: true)
    }
    
    deinit {
        dataUpdateTimer?.invalidate()
    }
    
    private func setupGame() {
        // Setup dimensions based on screen size
        radius = min(size.width, size.height) * 0.3
        ballRadius = radius * 0.075
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        // Add stars to background
        for _ in 0...30 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...0.8)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                   y: CGFloat.random(in: 0...size.height))
            star.zPosition = -90
            addChild(star)
            
            // Add a simple twinkle animation
            let fadeAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: CGFloat.random(in: 0.5...2.0)),
                SKAction.fadeAlpha(to: 0.8, duration: CGFloat.random(in: 0.5...2.0))
            ])
            star.run(SKAction.repeatForever(fadeAction))
        }
        
        // Create path markers
        for i in 0..<16 {
            let angle = 2 * CGFloat.pi * CGFloat(i) / 16.0
            let xPos = center.x + cos(angle) * radius
            let yPos = center.y + sin(angle) * radius
            
            let pathNode = SKShapeNode(circleOfRadius: 4)
            pathNode.position = CGPoint(x: xPos, y: yPos)
            pathNode.fillColor = i % 4 == 0 ? .yellow : .gray
            pathNode.alpha = 0.7
            addChild(pathNode)
            pathNodes.append(pathNode)
        }
        
        // Create center circle
        centerCircle = SKShapeNode(circleOfRadius: radius * 0.8)
        centerCircle.position = center
        centerCircle.strokeColor = .cyan
        centerCircle.lineWidth = 2
        centerCircle.fillColor = .clear
        addChild(centerCircle)
        
        // Create the score label
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = size.height * 0.1
        scoreLabel.position = center
        scoreLabel.text = "0"
        scoreLabel.fontColor = .white
        addChild(scoreLabel)
        
        // Create high score label
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        highScoreLabel.fontSize = size.height * 0.03
        highScoreLabel.position = CGPoint(x: center.x, y: center.y - 40)
        highScoreLabel.text = "HIGH: 0"
        highScoreLabel.fontColor = .lightGray
        highScoreLabel.name = "highScoreLabel"
        addChild(highScoreLabel)
        
        // Create message label
        messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        messageLabel.fontSize = size.height * 0.05
        messageLabel.position = CGPoint(x: center.x, y: center.y - radius * 0.9)
        messageLabel.text = "TAP TO PLAY"
        messageLabel.fontColor = .systemBlue
        addChild(messageLabel)
        
        // Create tap target position
        let tapPosition = CGPoint(x: center.x, y: center.y + radius)
        tapTarget = SKShapeNode(circleOfRadius: ballRadius * 1.5)
        tapTarget.position = tapPosition
        tapTarget.fillColor = .red
        tapTarget.alpha = 0.7
        
        // Pulse animation for the target
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5)
        ])
        tapTarget.run(SKAction.repeatForever(pulseAction))
        addChild(tapTarget)
        
        // Create ball
        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = .green
        ball.strokeColor = .white
        ball.lineWidth = 1
        ball.position = tapPosition // Start at top
        addChild(ball)
        
        // Add "TAP" text to tap target
        let tapText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapText.fontSize = ballRadius * 0.9
        tapText.position = tapPosition
        tapText.text = "TAP"
        tapText.fontColor = .white
        tapText.verticalAlignmentMode = .center
        addChild(tapText)
    }
    
    private func startGame() {
        // Initialize based on difficulty setting
        let difficulty = UserDefaults.standard.integer(forKey: "difficulty")
        
        gameRunning = true
        score = 0
        // Adjust initial game speed based on difficulty
        switch difficulty {
        case 0: // Easy
            gameSpeed = 0.8
            speedIncrease = 0.08
            hitAccuracy = 7.0
            maxMissedTaps = 5
        case 2: // Hard
            gameSpeed = 1.2
            speedIncrease = 0.12
            hitAccuracy = 5.0
            maxMissedTaps = 2
        default: // Medium (default)
            gameSpeed = 1.0
            speedIncrease = 0.1
            hitAccuracy = 6.0
            maxMissedTaps = 3
        }
        
        missedTaps = 0
        scoreLabel.text = "0"
        lastTapTime = currentTime
        messageLabel.isHidden = true
        
        // Load high score from UserDefaults
        highScore = UserDefaults.standard.integer(forKey: "highScore")
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = "HIGH: \(highScore)"
        }
        
        // Display help message
        let helpLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        helpLabel.fontSize = size.height * 0.03
        helpLabel.position = CGPoint(x: size.width/2, y: size.height * 0.9)
        helpLabel.text = "Tap when ball overlaps with TAP! (\(maxMissedTaps) misses allowed)"
        helpLabel.fontColor = .white
        helpLabel.name = "helpLabel"
        addChild(helpLabel)
        
        // Fade out help message
        helpLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
        
        // Start animation
        let scalePulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        run(scalePulse)
    }
    
    private func endGame() {
        gameRunning = false
        
        // Play game over sound
        SoundManager.shared.playSound(.gameOver)
        
        // Select a new random music track for the next game
        SoundManager.shared.selectNewTrack()
        
        // Haptic feedback for game over
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Update high score
        if score > highScore {
            highScore = score
            // Save to UserDefaults
            UserDefaults.standard.set(highScore, forKey: "highScore")
            UserDefaults.standard.synchronize()
            
            if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
                highScoreLabel.text = "HIGH: \(highScore)"
                
                // Celebrate new high score
                highScoreLabel.fontColor = .yellow
                let celebration = SKAction.sequence([
                    SKAction.scale(to: 1.5, duration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ])
                highScoreLabel.run(celebration) {
                    highScoreLabel.fontColor = .lightGray
                }
            }
        }
        
        // Create a semi-transparent overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 100
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.name = "gameOverOverlay"
        addChild(overlay)
        
        // Game over title
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 80)
        gameOverLabel.zPosition = 101
        overlay.addChild(gameOverLabel)
        
        // Final score
        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.text = "Score: \(score)"
        finalScoreLabel.fontSize = 30
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: 0, y: 20)
        finalScoreLabel.zPosition = 101
        overlay.addChild(finalScoreLabel)
        
        // Create buttons
        let buttonWidth: CGFloat = size.width * 0.6
        let buttonHeight: CGFloat = 50
        // buttonSpacing not used
        
        // Play again button
        let playAgainButton = createButton(text: "PLAY AGAIN", width: buttonWidth, height: buttonHeight, position: CGPoint(x: 0, y: -50))
        playAgainButton.name = "playAgain"
        playAgainButton.zPosition = 101
        overlay.addChild(playAgainButton)
        
        // Main menu button
        let menuButton = createButton(text: "MAIN MENU", width: buttonWidth, height: buttonHeight, position: CGPoint(x: 0, y: -110))
        menuButton.name = "mainMenu"
        menuButton.zPosition = 101
        overlay.addChild(menuButton)
        
        // Scale in animation for the overlay
        overlay.setScale(0.1)
        overlay.run(SKAction.scale(to: 1.0, duration: 0.3))
        
        // Visual feedback for game over
        let shakeAction = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -20, y: 0, duration: 0.05),
            SKAction.moveBy(x: 20, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        ])
        run(shakeAction)
    }
    
    private func addSuccessParticles(at position: CGPoint, multiplier: Int = 1) {
        // Create simple particles for successful tap
        // Number of particles scales with multiplier (more particles for multi-taps)
        let baseParticleCount = 15
        let particleCount = min(baseParticleCount * multiplier, 45) // Cap at 45 particles
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...4))
            
            // Random colors based on multiplier
            var colors: [UIColor] = [
                UIColor(red: CGFloat.random(in: 0...0.5), green: CGFloat.random(in: 0.7...1.0), blue: 1.0, alpha: 1.0)
            ]
            
            // Add more color variations for multi-taps
            if multiplier >= 2 {
                colors.append(UIColor(red: CGFloat.random(in: 0.7...1.0), green: CGFloat.random(in: 0.7...1.0), blue: 0.0, alpha: 1.0)) // Gold
            }
            if multiplier >= 3 {
                colors.append(UIColor(red: CGFloat.random(in: 0.7...1.0), green: 0.0, blue: CGFloat.random(in: 0.7...1.0), alpha: 1.0)) // Purple
            }
            
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            addChild(particle)
            
            // Random movement
            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let distance = CGFloat.random(in: 20...50) * sqrt(CGFloat(multiplier))
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            // Animate and remove - faster/more dramatic for multi-taps
            let duration = 0.5 / sqrt(CGFloat(min(multiplier, 3)))
            let moveAction = SKAction.move(to: destination, duration: duration)
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let scaleAction = SKAction.scale(to: CGFloat.random(in: 0.5...2.0) * CGFloat(multiplier), duration: duration)
            let group = SKAction.group([moveAction, fadeAction, scaleAction])
            
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
    
    // MARK: - Cryptocurrency Bubbles
    
    private func setupCryptoBubbles() {
        // Set up physics world with zero gravity for bubbles
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }
    
    @objc private func fetchCryptoData() {
        // URL for CoinGecko API - free and doesn't require API key for basic usage
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false&price_change_percentage=24h"
        
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self, let data = data, error == nil else {
                print("Error fetching crypto data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                // Parse JSON response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    var cryptos: [CryptoCurrency] = []
                    
                    for item in json {
                        if let symbol = item["symbol"] as? String,
                           let name = item["name"] as? String,
                           let price = item["current_price"] as? Double,
                           let priceChange = item["price_change_percentage_24h"] as? Double,
                           let marketCap = item["market_cap"] as? Double {
                            
                            let crypto = CryptoCurrency(
                                symbol: symbol.uppercased(),
                                name: name,
                                price: price,
                                priceChangePercentage24h: priceChange,
                                marketCap: marketCap
                            )
                            cryptos.append(crypto)
                        }
                    }
                    
                    // Update UI on main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.updateCryptoBubbles(with: cryptos)
                    }
                }
            } catch {
                print("Error parsing crypto data: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    private func updateCryptoBubbles(with cryptos: [CryptoCurrency]) {
        // Remove old bubbles
        for bubble in cryptoBubbles {
            bubble.removeFromParent()
        }
        cryptoBubbles.removeAll()
        
        // Create new bubbles (excluding Bitcoin)
        for crypto in cryptos {
            // Skip Bitcoin bubbles - only create bubbles for other cryptocurrencies
            if crypto.symbol.lowercased() != "btc" {
                createCryptoBubble(for: crypto)
            }
        }
    }
    
    private func createCryptoBubble(for crypto: CryptoCurrency) {
        let size = crypto.bubbleSize
        let bubble = SKShapeNode(circleOfRadius: size/2)
        bubble.fillColor = crypto.bubbleColor
        bubble.strokeColor = .white
        bubble.lineWidth = 1.5
        
        // Add the cryptocurrency symbol
        let symbolLabel = SKLabelNode(text: crypto.symbol)
        symbolLabel.fontName = "AvenirNext-Bold"
        symbolLabel.fontSize = min(size/3, 16)
        symbolLabel.fontColor = .white
        symbolLabel.position = CGPoint(x: 0, y: 5) // Moved up to make room for price
        symbolLabel.verticalAlignmentMode = .center
        bubble.addChild(symbolLabel)
        
        // Add price label (like in the original cryptobubbles)
        let formattedPrice = String(format: "$%.2f", crypto.price)
        let priceLabel = SKLabelNode(text: formattedPrice)
        priceLabel.fontName = "AvenirNext"
        priceLabel.fontSize = min(size/4, 12)
        priceLabel.fontColor = .white
        priceLabel.position = CGPoint(x: 0, y: -10) // Position below symbol
        priceLabel.verticalAlignmentMode = .center
        bubble.addChild(priceLabel)
        
        // Position the bubble in the upper area of the screen, above the game circle
        let safeAreaTop = self.size.height * 0.85
        let safeAreaBottom = centerCircle.position.y + radius + size/2 + 20 // Above the circle with some padding
        let xPos = CGFloat.random(in: size/2..<(self.size.width - size/2))
        let yPos = CGFloat.random(in: safeAreaBottom..<safeAreaTop)
        bubble.position = CGPoint(x: xPos, y: yPos)
        
        // Add physics body for interactions
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: size/2)
        bubble.physicsBody?.isDynamic = true
        bubble.physicsBody?.categoryBitMask = bubbleCategory
        bubble.physicsBody?.contactTestBitMask = bubbleCategory  // Make bubbles interact with each other
        bubble.physicsBody?.collisionBitMask = bubbleCategory | ballCategory  // Allow collision with other bubbles and the ball
        bubble.physicsBody?.restitution = 0.7 // Bounciness
        bubble.physicsBody?.linearDamping = 0.8 // Air resistance
        
        // Add gentle movement
        let randomDuration = TimeInterval.random(in: 8...15)
        let randomDirection = CGVector(
            dx: CGFloat.random(in: -30...30),
            dy: CGFloat.random(in: -10...10)
        )
        
        let moveAction = SKAction.move(by: randomDirection, duration: randomDuration)
        let moveReverse = SKAction.move(by: CGVector(dx: -randomDirection.dx, dy: -randomDirection.dy), duration: randomDuration)
        let sequence = SKAction.sequence([moveAction, moveReverse])
        let moveForever = SKAction.repeatForever(sequence)
        bubble.run(moveForever)
        
        // Store the crypto data for later use
        bubble.userData = NSMutableDictionary()
        bubble.userData?.setValue(crypto.symbol, forKey: "symbol")
        bubble.userData?.setValue(crypto.price, forKey: "price")
        
        // Add to scene and tracking array
        addChild(bubble)
        cryptoBubbles.append(bubble)
    }
    
    // MARK: - Physics Contact
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle physics interactions if needed
        // For now, we're just using physics for realistic movement
    }
    
    // Keep bubbles in bounds
    private func keepCryptoBubblesInBounds() {
        for bubble in cryptoBubbles {
            guard let bubbleNode = bubble as? SKShapeNode else { continue }
            
            let radius = bubbleNode.frame.width / 2
            
            // Constrain X position
            if bubbleNode.position.x < radius {
                bubbleNode.position.x = radius
                if let physicsBody = bubbleNode.physicsBody, physicsBody.velocity.dx < 0 {
                    physicsBody.velocity.dx = -physicsBody.velocity.dx * 0.8
                }
            } else if bubbleNode.position.x > size.width - radius {
                bubbleNode.position.x = size.width - radius
                if let physicsBody = bubbleNode.physicsBody, physicsBody.velocity.dx > 0 {
                    physicsBody.velocity.dx = -physicsBody.velocity.dx * 0.8
                }
            }
            
            // Constrain Y position to upper area
            let minY = centerCircle.position.y + radius + radius + 20 // Above the game circle
            let maxY = size.height - radius
            
            if bubbleNode.position.y < minY {
                bubbleNode.position.y = minY
                if let physicsBody = bubbleNode.physicsBody, physicsBody.velocity.dy < 0 {
                    physicsBody.velocity.dy = -physicsBody.velocity.dy * 0.8
                }
            } else if bubbleNode.position.y > maxY {
                bubbleNode.position.y = maxY
                if let physicsBody = bubbleNode.physicsBody, physicsBody.velocity.dy > 0 {
                    physicsBody.velocity.dy = -physicsBody.velocity.dy * 0.8
                }
            }
        }
    }
    
    private func setupPauseButton() {
        // Create pause button in the top right corner
        let pauseButton = SKShapeNode(circleOfRadius: 20)
        pauseButton.fillColor = UIColor.darkGray.withAlphaComponent(0.7)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 2
        pauseButton.position = CGPoint(x: size.width - 40, y: size.height - 40)
        pauseButton.name = "pauseButton"
        pauseButton.zPosition = 10
        addChild(pauseButton)
        
        // Add pause symbol
        let pauseSymbol = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -5, y: -7))
        path.addLine(to: CGPoint(x: -5, y: 7))
        path.move(to: CGPoint(x: 5, y: -7))
        path.addLine(to: CGPoint(x: 5, y: 7))
        pauseSymbol.path = path
        pauseSymbol.strokeColor = .white
        pauseSymbol.lineWidth = 3
        pauseButton.addChild(pauseSymbol)
    }
    
    private func showPauseMenu() {
        // Pause game state
        self.isPaused = true
        
        // Create semi-transparent overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 100
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.name = "pauseOverlay"
        addChild(overlay)
        
        // Pause title
        let pauseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 50
        pauseLabel.fontColor = .white
        pauseLabel.position = CGPoint(x: 0, y: 80)
        pauseLabel.zPosition = 101
        overlay.addChild(pauseLabel)
        
        // Create buttons
        let buttonWidth: CGFloat = size.width * 0.6
        let buttonHeight: CGFloat = 50
        
        // Resume button
        let resumeButton = createButton(text: "RESUME", width: buttonWidth, height: buttonHeight, position: CGPoint(x: 0, y: 0))
        resumeButton.name = "resume"
        resumeButton.zPosition = 101
        overlay.addChild(resumeButton)
        
        // Main menu button
        let menuButton = createButton(text: "MAIN MENU", width: buttonWidth, height: buttonHeight, position: CGPoint(x: 0, y: -60))
        menuButton.name = "mainMenu"
        menuButton.zPosition = 101
        overlay.addChild(menuButton)
        
        // Scale in animation
        overlay.setScale(0.1)
        overlay.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    private func resumeGame() {
        if let overlay = childNode(withName: "pauseOverlay") {
            overlay.run(SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.2),
                SKAction.removeFromParent()
            ]))
        }
        
        // Unpause the game after a short delay to prevent accidental taps
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.isPaused = false
            }
        ]))
    }
    
    private func returnToMainMenu() {
        // Return to main menu
        let transition = SKTransition.fade(withDuration: 0.5)
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        self.view?.presentScene(menuScene, transition: transition)
    }
    
    private func createButton(text: String, width: CGFloat, height: CGFloat, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        button.fillColor = .darkGray
        button.strokeColor = .cyan
        button.lineWidth = 2
        button.position = position
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Limit to maximum 2 touches at once
        let limitedTouches = touches.prefix(2)
        guard !limitedTouches.isEmpty else { return }
        
        // Process first touch for UI interactions
        let firstTouch = limitedTouches.first!
        let firstLocation = firstTouch.location(in: self)
        let nodes = self.nodes(at: firstLocation)
        
        // Handle button taps first (using first touch only)
        for node in nodes {
            // Pause button
            if node.name == "pauseButton" || node.parent?.name == "pauseButton" {
                SoundManager.shared.playSound(.buttonTap)
                showPauseMenu()
                return
            }
            
            // Resume button
            if node.name == "resume" || node.parent?.name == "resume" {
                SoundManager.shared.playSound(.buttonTap)
                resumeGame()
                return
            }
            
            // Main menu button
            if node.name == "mainMenu" || node.parent?.name == "mainMenu" {
                SoundManager.shared.playSound(.buttonTap)
                returnToMainMenu()
                return
            }
            
            // Play again button
            if node.name == "playAgain" || node.parent?.name == "playAgain" {
                SoundManager.shared.playSound(.buttonTap)
                // Remove overlay
                if let overlay = childNode(withName: "gameOverOverlay") {
                    overlay.removeFromParent()
                }
                startGame()
                return
            }
        }
        
        // Check if the game is paused or overlay is shown
        if self.isPaused || childNode(withName: "pauseOverlay") != nil || childNode(withName: "gameOverOverlay") != nil {
            return
        }
        
        // If game is not running, start with first touch
        if !gameRunning {
            startGame()
            return
        }
        
        // Track if we need to increase game speed (only once per multi-touch)
        var hadSuccessfulTap = false
        var totalSuccessfulTaps = 0
        
        // Create the hit area visual only once
        let hitAreaVisual = SKShapeNode(circleOfRadius: ballRadius * hitAccuracy)
        hitAreaVisual.position = ball.position
        hitAreaVisual.strokeColor = .white
        hitAreaVisual.fillColor = .clear
        hitAreaVisual.alpha = 0.3
        addChild(hitAreaVisual)
        hitAreaVisual.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Calculate distance from ball to target once (same for all touches)
        let targetDistance = hypot(ball.position.x - tapTarget.position.x, ball.position.y - tapTarget.position.y)
        let targetThreshold = ballRadius * 5   // adjust to taste
        
        // Process only up to 2 touches for gameplay
        for touch in limitedTouches {
            let location = touch.location(in: self)
            
            // Ball must be inside the top tap circle *and* the user must hit it
            if targetDistance < targetThreshold {
                // Successful tap
                score += 1
                totalSuccessfulTaps += 1
                hadSuccessfulTap = true
                
                // Fire lightning attack on successful tap
                fireLightningAttack()
                
                // Play success sound
                SoundManager.shared.playSound(.successTap)
                
                // Haptic feedback for success
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } else {
                // Failed tap
                missedTaps += 1
                
                // Play miss sound
                SoundManager.shared.playSound(.missTap)
                
                // Haptic feedback for miss
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Visual feedback for missed tap
                let missLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                missLabel.fontSize = size.height * 0.03
                missLabel.position = location
                missLabel.text = "MISS! (\(missedTaps)/\(maxMissedTaps))"
                missLabel.fontColor = .red
                addChild(missLabel)
                
                // Fade out and remove
                let fadeAction = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 0.7),
                    SKAction.removeFromParent()
                ])
                missLabel.run(fadeAction)
            }
        }
        
        // Update game state based on the processed touches
        if hadSuccessfulTap {
            // Update the score display
            scoreLabel.text = "\(score)"
            
            // Reset missed taps counter on success
            missedTaps = 0
            
            // Increase difficulty by making the game faster and reducing hit zone
            // Make speed increase more gradual at the beginning
            if score <= 5 {
                gameSpeed += speedIncrease * 0.7  // Slower speed increase for beginners
            } else {
                gameSpeed += speedIncrease
            }
            
            // Even more forgiving hit accuracy reduction
            hitAccuracy = max(4.0, 8.0 - (gameSpeed * 0.05))
            
            lastTapTime = currentTime
            
            // Visual feedback - bigger pulse for multiple successful taps
            let pulseScale = min(1.5 + (CGFloat(totalSuccessfulTaps - 1) * 0.2), 2.1) // Cap at 2.1x for 4+ taps
            let pulse = SKAction.sequence([
                SKAction.scale(to: pulseScale, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            scoreLabel.run(pulse)
            
            // Add particle effect at ball position - more particles for multi-taps
            addSuccessParticles(at: ball.position, multiplier: totalSuccessfulTaps)
            
            // Color change based on speed
            let greenComponent = max(0.0, min(1.0, 2.0 - (gameSpeed * 0.1)))
            ball.fillColor = UIColor(red: 1.0, green: greenComponent, blue: 0.0, alpha: 1.0)
            
            // Special multi-tap message for 2+ successful taps
            if totalSuccessfulTaps > 1 {
                let multiTapLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                multiTapLabel.fontSize = size.height * 0.04
                multiTapLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
                multiTapLabel.text = "\(totalSuccessfulTaps)x COMBO!"
                multiTapLabel.fontColor = .yellow
                addChild(multiTapLabel)
                
                // Fade out and remove
                multiTapLabel.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 1.0),
                    SKAction.removeFromParent()
                ]))
            }
        }
        
        // End game if too many misses
        if missedTaps >= maxMissedTaps {
            endGame()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.currentTime = currentTime
        
        // Keep crypto bubbles within the play area
        keepCryptoBubblesInBounds()
        
        // If game is not running, don't update
        if !gameRunning { return }
        
        // Check for timeout (15 seconds since last tap - more forgiving)
        if currentTime - lastTapTime > 15 {
            endGame()
            return
        }
        
        // Update ball position along circular path
        pathAngle += 0.02 * gameSpeed
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        ball.position.x = center.x + cos(pathAngle) * radius
        ball.position.y = center.y + sin(pathAngle) * radius
        
        // Highlight path nodes near the ball
        for (index, node) in pathNodes.enumerated() {
            let nodeAngle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(pathNodes.count)
            let angleDiff = abs(nodeAngle - fmod(pathAngle, 2 * CGFloat.pi))
            let normalizedDiff = min(angleDiff, 2 * CGFloat.pi - angleDiff) / (CGFloat.pi / 4)
            
            if normalizedDiff < 1.0 {
                node.alpha = 1.0
                node.setScale(1.0 + (1.0 - normalizedDiff) * 0.5)
            } else {
                node.alpha = 0.5
                node.setScale(1.0)
            }
        }
    }
    
    // MARK: - Lightning Attack Methods
    
    // Fire lightning attack at cryptocurrency bubbles
    private func fireLightningAttack() {
        // Only proceed if there are bubbles to target
        guard !cryptoBubbles.isEmpty else { return }
        
        // Find the largest bubble to target
        var targetBubble: SKNode? = nil
        var maxSize: CGFloat = 0
        
        for bubble in cryptoBubbles {
            guard let bubbleNode = bubble as? SKShapeNode else { continue }
            
            // Get the bubble size
            let bubbleSize = bubbleNode.frame.width
            
            // If this is the largest bubble so far, make it the target
            if bubbleSize > maxSize {
                maxSize = bubbleSize
                targetBubble = bubble
            }
        }
        
        // If we have a target, create lightning effect to it
        if let target = targetBubble {
            // Create the lightning bolt effect from center circle to target
            createLightningBolt(from: centerCircle.position, to: target.position) { [weak self] in
                self?.handleBubbleHit(bubble: target)
            }
        }
    }
    
    // Create a lightning bolt visual effect
    private func createLightningBolt(from startPoint: CGPoint, to endPoint: CGPoint, completion: @escaping () -> Void) {
        // Calculate distance and angle between points
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // Create a path for the lightning
        let path = CGMutablePath()
        path.move(to: startPoint)
        
        // Create zigzag pattern
        var currentPoint = startPoint
        let segments = 8
        let segmentLength = distance / CGFloat(segments)
        
        for i in 1...segments {
            let segmentEndX = startPoint.x + dx * CGFloat(i) / CGFloat(segments)
            let segmentEndY = startPoint.y + dy * CGFloat(i) / CGFloat(segments)
            let idealEnd = CGPoint(x: segmentEndX, y: segmentEndY)
            
            // Add some randomness to zigzag except for the last segment
            if i < segments {
                let randomOffsetX = CGFloat.random(in: -segmentLength/3...segmentLength/3)
                let randomOffsetY = CGFloat.random(in: -segmentLength/3...segmentLength/3)
                currentPoint = CGPoint(x: idealEnd.x + randomOffsetX, y: idealEnd.y + randomOffsetY)
            } else {
                currentPoint = endPoint // Make sure we end exactly at the target
            }
            
            path.addLine(to: currentPoint)
        }
        
        // Create the lightning shape node
        let lightning = SKShapeNode(path: path)
        lightning.strokeColor = .white
        lightning.lineWidth = 4
        lightning.glowWidth = 2
        lightning.lineCap = .round
        lightning.zPosition = 200
        addChild(lightning)
        
        // Add a glow effect
        let glow = SKShapeNode(path: path)
        glow.strokeColor = .systemBlue
        glow.lineWidth = 8
        glow.alpha = 0.5
        glow.zPosition = 199
        addChild(glow)
        
        // Animate the lightning effect
        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run {
                lightning.removeFromParent()
                glow.removeFromParent()
                completion() // Call completion after lightning effect is done
            }
        ])
        
        lightning.run(fadeAction)
        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.2)
        ]))
    }
    
    // Handle what happens when a bubble is hit by lightning
    private func handleBubbleHit(bubble: SKNode) {
        // Create explosion effect at bubble position
        let explosion = createSimpleExplosion(at: bubble.position)
        addChild(explosion)
        
        // Display Michael Saylor quote at bottom of screen
        showSaylorQuote()
        
        // Remove the bubble
        bubble.removeFromParent()
        if let index = cryptoBubbles.firstIndex(of: bubble) {
            cryptoBubbles.remove(at: index)
        }
        
        // Check if all bubbles are gone, and if so, fetch new data immediately
        if cryptoBubbles.isEmpty {
            fetchCryptoData()
            
            // If we've had issues with API, create some fallback bubbles after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.cryptoBubbles.isEmpty else { return }
                
                // Create fallback bubbles if API failed
                self.createFallbackBubbles()
            }
        }
        
        // Play sound effect
        SoundManager.shared.playSound(.successTap)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // Create fallback bubbles when API fetch fails
    private func createFallbackBubbles() {
        // Only create fallbacks if we don't have any bubbles
        guard cryptoBubbles.isEmpty else { return }
        
        // Create some dummy alt coins
        let altCoins = [
            (symbol: "ETH", name: "Ethereum", color: UIColor.green),
            (symbol: "SOL", name: "Solana", color: UIColor.purple),
            (symbol: "ADA", name: "Cardano", color: UIColor.blue),
            (symbol: "XRP", name: "Ripple", color: UIColor.cyan),
            (symbol: "DOT", name: "Polkadot", color: UIColor.magenta)
        ]
        
        // Create bubbles for each alt coin
        for (i, coin) in altCoins.enumerated() {
            // Create bubble at random position
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 25...40))
            bubble.fillColor = coin.color
            bubble.strokeColor = .white
            bubble.lineWidth = 1.5
            
            // Position randomly but ensure it's within the screen bounds
            let padding: CGFloat = 50
            let xPos = CGFloat.random(in: padding...(size.width - padding))
            let yPos = CGFloat.random(in: padding...(size.height - padding))
            bubble.position = CGPoint(x: xPos, y: yPos)
            
            // Add symbol label
            let symbolLabel = SKLabelNode(text: coin.symbol)
            symbolLabel.fontName = "AvenirNext-Bold"
            symbolLabel.fontSize = 16
            symbolLabel.fontColor = .white
            symbolLabel.position = CGPoint(x: 0, y: 0)
            symbolLabel.verticalAlignmentMode = .center
            bubble.addChild(symbolLabel)
            
            // Store the bubble
            addChild(bubble)
            cryptoBubbles.append(bubble)
        }
    }
    
    // Show Michael Saylor quote at bottom of screen
    private func showSaylorQuote() {
        // Array of Michael Saylor Bitcoin quotes
        let saylorQuotes = [
            "There is no second best.",
            "Bitcoin is digital gold in the palm of your hand.",
            "Bitcoin is a swarm of cyber hornets serving the goddess of wisdom.",
            "The winners of the 21st century are going to be the people that own high-quality scarce assets.",
            "You don't need to buy a whole Bitcoin. Stack sats.",
            "Bitcoin is hope.",
            "I have seen the future and it is Bitcoin.",
            "Bitcoin is the first engineered safe-haven asset.",
            "Bitcoin is inevitable.",
            "Bitcoin is economic security."
        ]
        
        // Pick a random quote
        let quote = saylorQuotes.randomElement() ?? "There is no second best."
        
        // Create label for the quote
        let quoteLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        quoteLabel.text = quote
        quoteLabel.fontSize = 18
        quoteLabel.fontColor = .orange
        quoteLabel.position = CGPoint(x: size.width/2, y: 50)
        quoteLabel.zPosition = 100
        addChild(quoteLabel)
        
        // Animate the quote
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        quoteLabel.alpha = 0
        quoteLabel.run(sequence)
    }
    
    // Create a simple explosion effect
    private func createSimpleExplosion(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 150
        
        // Create particles
        for _ in 1...15 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
            particle.fillColor = .orange
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.position = .zero
            container.addChild(particle)
            
            // Random direction and speed
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...60)
            let destination = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            
            // Animate
            let move = SKAction.move(to: destination, duration: 0.6)
            let fade = SKAction.fadeOut(withDuration: 0.6)
            particle.run(SKAction.group([move, fade]))
        }
        
        // Remove container after animation completes
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.removeFromParent()
        ]))
        
        return container
    }
}
