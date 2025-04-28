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
    private var currentTime: TimeInterval = 0
    private var lastShownQuote: String = ""  // Track last shown quote to avoid repetition
    private var gameSpeed: CGFloat = 1.0
    private var speedIncrease: CGFloat = 0.1
    private var hitAccuracy: CGFloat = 6.0  // Increased initial hit area
    private var pathAngle: CGFloat = 0
    private var missedTaps: Int = 0
    private var maxMissedTaps: Int = 3  // Allow 3 missed taps before game over
    
    // Bitcoin hash power visualization
    private var hashMeter: SKNode!
    private var hashChips = [SKShapeNode]()
    private var hashRateLabel: SKLabelNode!
    private var currentHashRate: Double = 500.0 // Default starting rate in MH/s
    private var baseHashRate: Double = 500.0 // Base rate that grows over time in MH/s
    
    // Physics categories for crypto bubbles
    private let bubbleCategory: UInt32 = 0x1 << 0
    private let ballCategory: UInt32 = 0x1 << 1
    
    // Additional properties for pause functionality
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupGame()
        setupPauseButton()
        setupCryptoBubbles()
        setupHashMeter()
        
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
        radius = min(size.width, size.height) * 0.4  // Increased from 0.3 to 0.4 for a larger game circle
        ballRadius = radius * 0.15  // Doubled from 0.075 to 0.15 for a more prominent ball
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
        
        // Create Bitcoin circuit-styled path
        
        // First, create the main circular path
        let mainPath = SKShapeNode(circleOfRadius: radius)
        mainPath.strokeColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.9) // Bitcoin orange, more vibrant
        
        // Add physics body to the center circle to make bubbles bounce off it
        centerCircle = SKShapeNode(circleOfRadius: radius)
        centerCircle.fillColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.1) // Bitcoin orange with transparency
        centerCircle.strokeColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.4) // Bitcoin orange border
        centerCircle.position = center
        centerCircle.zPosition = 10
        
        // Create a physics body for the center circle
        centerCircle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        centerCircle.physicsBody?.isDynamic = false // Static body
        centerCircle.physicsBody?.categoryBitMask = ballCategory
        centerCircle.physicsBody?.collisionBitMask = bubbleCategory
        centerCircle.physicsBody?.contactTestBitMask = bubbleCategory
        centerCircle.physicsBody?.restitution = 0.9 // High bounce
        addChild(centerCircle)
        mainPath.lineWidth = 3 // Thicker, more visible line
        mainPath.position = center
        mainPath.zPosition = -1
        addChild(mainPath)
        
        // Add node markers along the path
        for i in 0..<16 {
            let angle = 2 * CGFloat.pi * CGFloat(i) / 16.0
            let xPos = center.x + cos(angle) * radius
            let yPos = center.y + sin(angle) * radius
            
            // Create larger node points at key positions (every 4th node)
            if i % 4 == 0 {
                // Major node - hexagonal shape to resemble Bitcoin network nodes
                let majorNode = SKShapeNode(circleOfRadius: 7)
                majorNode.position = CGPoint(x: xPos, y: yPos)
                majorNode.fillColor = .orange
                majorNode.strokeColor = .white
                majorNode.lineWidth = 1
                majorNode.alpha = 0.8
                
                // Add subtle pulsing animation to major nodes
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 1.5),
                    SKAction.scale(to: 1.0, duration: 1.5)
                ])
                majorNode.run(SKAction.repeatForever(pulse))
                
                addChild(majorNode)
                pathNodes.append(majorNode)
            } else {
                // Minor node - simple dot
                let minorNode = SKShapeNode(circleOfRadius: 3)
                minorNode.position = CGPoint(x: xPos, y: yPos)
                minorNode.fillColor = .white
                minorNode.alpha = 0.5
                addChild(minorNode)
                pathNodes.append(minorNode)
            }
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
        
        // Create tap target position (Lightning Node)
        let tapPosition = CGPoint(x: center.x, y: center.y + radius)
        
        // Create lightning node container
        tapTarget = SKShapeNode(circleOfRadius: ballRadius * 1.6)
        tapTarget.position = tapPosition
        tapTarget.fillColor = UIColor(red: 0.95, green: 0.7, blue: 0.2, alpha: 0.2) // Bitcoin gold with transparency
        tapTarget.strokeColor = .orange
        tapTarget.lineWidth = 2
        
        // Add lightning bolt icon in center
        let lightningNode = SKShapeNode()
        let lightningPath = CGMutablePath()
        let boltSize = ballRadius * 0.8
        
        // Draw simple lightning bolt zigzag
        lightningPath.move(to: CGPoint(x: 0, y: boltSize))
        lightningPath.addLine(to: CGPoint(x: -boltSize/2, y: boltSize/4))
        lightningPath.addLine(to: CGPoint(x: 0, y: 0))
        lightningPath.addLine(to: CGPoint(x: boltSize/2, y: -boltSize/4))
        lightningPath.addLine(to: CGPoint(x: 0, y: -boltSize))
        
        lightningNode.path = lightningPath
        lightningNode.strokeColor = .white
        lightningNode.lineWidth = 3
        lightningNode.lineCap = .round
        lightningNode.lineJoin = .round
        tapTarget.addChild(lightningNode)
        
        // Enhanced pulse animation
        let pulseAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.fadeAlpha(to: 0.9, duration: 0.5)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.9, duration: 0.5),
                SKAction.fadeAlpha(to: 0.6, duration: 0.5)
            ])
        ])
        tapTarget.run(SKAction.repeatForever(pulseAction))
        
        // Add "TAP HERE" text with arrow for new users
        let tapHereLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapHereLabel.text = "TAP HERE!"
        tapHereLabel.fontSize = 20
        tapHereLabel.fontColor = .white
        tapHereLabel.position = CGPoint(x: 0, y: ballRadius * 3)
        tapHereLabel.name = "tapHereLabel"
        
        // Add arrow pointing to target
        let arrowNode = SKShapeNode()
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 0, y: ballRadius * 2.3))
        arrowPath.addLine(to: CGPoint(x: 0, y: ballRadius * 1.8))
        arrowNode.path = arrowPath
        arrowNode.strokeColor = .white
        arrowNode.lineWidth = 2
        arrowNode.name = "tapArrow"
        
        // Add animations for better visibility
        let fadeSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        tapHereLabel.run(SKAction.repeatForever(fadeSequence))
        arrowNode.run(SKAction.repeatForever(fadeSequence))
        
        tapTarget.addChild(tapHereLabel)
        tapTarget.addChild(arrowNode)
        addChild(tapTarget)
        
        // Create Bitcoin-styled ball
        ball = SKShapeNode(circleOfRadius: ballRadius)
        
        // We'll use a simple color instead of a gradient texture since the texture initializer is causing issues
        let bitcoinColor = UIColor(red: 0.95, green: 0.7, blue: 0.2, alpha: 1.0) // Bitcoin gold color
        
        ball.fillColor = bitcoinColor
        ball.strokeColor = .orange
        ball.lineWidth = 1.5
        ball.position = tapPosition // Start at top
        
        // Add Bitcoin "₿" symbol to the ball
        let bitcoinSymbol = SKLabelNode(text: "₿")
        bitcoinSymbol.fontSize = ballRadius * 2.0 // Increased from 1.2 to 2.0 for a much larger symbol
        bitcoinSymbol.fontName = "AvenirNext-Bold"
        bitcoinSymbol.verticalAlignmentMode = .center
        bitcoinSymbol.horizontalAlignmentMode = .center
        bitcoinSymbol.fontColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) // Bitcoin orange color
        bitcoinSymbol.name = "bitcoinSymbol"
        ball.addChild(bitcoinSymbol)
        
        // Add glow effect
        let glowEffect = SKEffectNode()
        glowEffect.shouldEnableEffects = true
        glowEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
        
        // Create the glow shape
        let glowShape = SKShapeNode(circleOfRadius: ballRadius*0.9)
        glowShape.fillColor = .orange
        glowShape.alpha = 0.4
        glowEffect.addChild(glowShape)
        
        glowEffect.alpha = 0.6
        glowEffect.name = "glow"
        ball.addChild(glowEffect)
        
        // Add subtle rotation animation
        ball.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 6.0)))
        
        addChild(ball)
        
        // "TAP HERE!" text above is sufficient, no additional tap text needed
        
        // Add the 'No Second Best' motto at the top with better visibility
        // Create a dark background rect for better visibility
        let backgroundRect = SKShapeNode(rect: CGRect(x: 0, y: size.height - 90, width: size.width, height: 40), cornerRadius: 0)
        backgroundRect.fillColor = UIColor.black.withAlphaComponent(0.6)
        backgroundRect.strokeColor = .clear
        backgroundRect.zPosition = 9
        backgroundRect.name = "mottoBackground"
        addChild(backgroundRect)
        
        // Add the motto text
        let mottoLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mottoLabel.text = "There is no second best."
        mottoLabel.fontSize = 24
        mottoLabel.fontColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) // Bitcoin orange
        mottoLabel.position = CGPoint(x: size.width/2, y: size.height - 70) // Better position
        mottoLabel.horizontalAlignmentMode = .center
        mottoLabel.name = "mottoLabel"
        mottoLabel.zPosition = 10
        addChild(mottoLabel)
    }
    
    private func startGame() {
        // Initialize based on difficulty setting
        let difficulty = UserDefaults.standard.integer(forKey: "difficulty")
        
        // Check if this is the first time playing the game
        let hasPlayedBefore = UserDefaults.standard.bool(forKey: "hasPlayedBefore")
        
        gameRunning = true
        score = 0
        
        // Adjust initial game speed based on difficulty and whether they've played before
        switch difficulty {
        case 0: // Easy
            // First-time players get faster ball (current speed)
            // Returning players get slower ball (previous speed)
            gameSpeed = hasPlayedBefore ? 0.7 : 0.8
            speedIncrease = hasPlayedBefore ? 0.07 : 0.08
            hitAccuracy = 7.0
            maxMissedTaps = 5
        case 2: // Hard
            gameSpeed = hasPlayedBefore ? 1.1 : 1.2
            speedIncrease = hasPlayedBefore ? 0.11 : 0.12
            hitAccuracy = 5.0
            maxMissedTaps = 2
        default: // Medium (default)
            gameSpeed = hasPlayedBefore ? 0.9 : 1.0
            speedIncrease = hasPlayedBefore ? 0.09 : 0.1
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
        // Visual "TAP HERE!" guidance is sufficient - no additional instructions needed
        
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
        
        // Save the highest hash rate achieved
        let existingHighest = UserDefaults.standard.double(forKey: "highestHashRate")
        if currentHashRate > existingHighest {
            UserDefaults.standard.set(currentHashRate, forKey: "highestHashRate")
        }
        
        // Mark that the user has played before - this will enable slower ball speed on next play
        UserDefaults.standard.set(true, forKey: "hasPlayedBefore")
        UserDefaults.standard.synchronize()
        
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
        // Create cryptocurrency bubbles using our hardcoded data
        // This is more reliable than using an API and avoids rate limits
        createFallbackBubbles(minCount: 25)
    }
    
    private func updateCryptoBubbles(with cryptos: [CryptoCurrency]) {
        // Remove old bubbles
        for bubble in cryptoBubbles {
            bubble.removeFromParent()
        }
        cryptoBubbles.removeAll()
        
        // Filter out Bitcoin (BTC) and create a shuffled array for more variety
        let filteredCryptos = cryptos.filter { $0.symbol.lowercased() != "btc" }
        
        // If we didn't get enough cryptocurrencies from the API, create some fallbacks
        if filteredCryptos.count < 5 {
            // Fill with fallbacks immediately rather than waiting
            createFallbackBubbles(minCount: 5)
            return
        }
        
        // Shuffle the array to ensure we get variety each time
        let shuffledCryptos = filteredCryptos.shuffled()
        
        // Create many more bubbles like cryptobubbles.net
        var usedSymbols = Set<String>() // Track which symbols we've already used
        
        // First pass - use unique cryptocurrencies
        for crypto in shuffledCryptos {
            // Skip duplicates
            if usedSymbols.contains(crypto.symbol.lowercased()) {
                continue
            }
            
            createCryptoBubble(for: crypto)
            usedSymbols.insert(crypto.symbol.lowercased())
            
            // Create many more bubbles to fill the screen (like cryptobubbles.net)
            if cryptoBubbles.count >= 25 { // Reduced by 50% from 50 to 25
                break
            }
        }
        
        // If we don't have enough bubbles, create fallback ones with different symbols
        if cryptoBubbles.count < 20 {
            createFallbackBubbles(minCount: 20, usedSymbols: usedSymbols)
        }
        
        // Ensure bubbles are well distributed
        distributeBubblesEvenly()
    }
    
    private func createCryptoBubble(for crypto: CryptoCurrency) {
        let size = crypto.bubbleSize
        let bubble = SKShapeNode(circleOfRadius: size/2)
        
        // Create distinctive colors based on the crypto symbol
        let uniqueColor = getUniqueColorForSymbol(crypto.symbol)
        bubble.fillColor = uniqueColor
        
        // Add glowing stroke based on price change direction
        bubble.strokeColor = crypto.priceChangePercentage24h >= 0 ? .green : .red
        bubble.lineWidth = 2.0
        
        // Add shimmer effect to make bubbles more visually appealing
        let shimmerAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ])
        bubble.run(SKAction.repeatForever(shimmerAction))
        
        // Add the cryptocurrency symbol with enhanced styling (no price display needed)
        let symbolLabel = SKLabelNode(text: crypto.symbol)
        symbolLabel.fontName = "AvenirNext-Bold"
        symbolLabel.fontSize = min(size/2.5, 18) // Larger font size for better visibility
        symbolLabel.fontColor = .white
        symbolLabel.position = CGPoint(x: 0, y: 0) // Centered in bubble
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.horizontalAlignmentMode = .center
        
        // Add subtle glow effect to make symbols pop
        symbolLabel.alpha = 0.95
        bubble.addChild(symbolLabel)
        
        // Position the bubble in the upper area of the screen, above the game circle
        let safeAreaTop = self.size.height * 0.85
        let safeAreaBottom = centerCircle.position.y + radius + size/2 + 20 // Above the circle with some padding
        let xPos = CGFloat.random(in: size/2..<(self.size.width - size/2))
        let yPos = CGFloat.random(in: safeAreaBottom..<safeAreaTop)
        bubble.position = CGPoint(x: xPos, y: yPos)
        
        // Add enhanced physics body for more dynamic interactions
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: size/2)
        bubble.physicsBody?.isDynamic = true
        bubble.physicsBody?.mass = size / 40  // Larger bubbles are heavier
        bubble.physicsBody?.categoryBitMask = bubbleCategory
        bubble.physicsBody?.contactTestBitMask = bubbleCategory  // Make bubbles interact with each other
        bubble.physicsBody?.collisionBitMask = bubbleCategory | ballCategory  // Allow collision with other bubbles and the ball
        bubble.physicsBody?.restitution = 0.9 // Increased bounciness
        bubble.physicsBody?.linearDamping = 0.5 // Reduced air resistance for more movement
        bubble.physicsBody?.angularDamping = 0.5 // Allow spinning
        bubble.physicsBody?.allowsRotation = true // Enable rotation
        
        // Add gentle continuous movement 
        let randomDirection = CGVector(
            dx: CGFloat.random(in: -50...50),
            dy: CGFloat.random(in: -30...30)
        )
        
        // Apply a small ongoing force for gentle continuous movement
        bubble.physicsBody?.applyForce(CGVector(dx: randomDirection.dx/10, dy: randomDirection.dy/10))
        
        // Name the bubble with the crypto symbol for identification
        bubble.name = "bubble_" + crypto.symbol
        
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
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Check if a bubble has collided with the center circle
        if (bodyA.categoryBitMask == bubbleCategory && bodyB.categoryBitMask == ballCategory) ||
           (bodyA.categoryBitMask == ballCategory && bodyB.categoryBitMask == bubbleCategory) {
            
            // Get the bubble node - it's either bodyA or bodyB
            let bubbleNode = (bodyA.categoryBitMask == bubbleCategory) ? bodyA.node : bodyB.node
            // We don't need to track the center node explicitly
            _ = (bodyA.categoryBitMask == ballCategory) ? bodyA.node : bodyB.node
            
            // Instead of popping bubbles, let them bounce off the center circle
            // We'll just give them a slight pulse animation for visual feedback
            if let bubble = bubbleNode as? SKShapeNode {
                // Apply a subtle pulse animation
                let pulseAction = SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])
                bubble.run(pulseAction)
                
                // Apply a little extra bounce restitution to make the collision feel more dynamic
                // but only for a brief moment
                let originalRestitution = bubble.physicsBody?.restitution ?? 0.9
                bubble.physicsBody?.restitution = 1.2
                
                // Reset the restitution after a short time
                bubble.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.2),
                    SKAction.run { bubble.physicsBody?.restitution = originalRestitution }
                ]))
            }
        }
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
        // Pause button - temporarily hidden due to functionality issues
        // let pauseButton = SKShapeNode(circleOfRadius: 20)
        // pauseButton.fillColor = UIColor.darkGray.withAlphaComponent(0.7)
        // pauseButton.strokeColor = .white
        // pauseButton.lineWidth = 2
        // pauseButton.position = CGPoint(x: size.width - 40, y: size.height - 40)
        // pauseButton.name = "pauseButton"
        // pauseButton.zPosition = 10
        // addChild(pauseButton)
        // 
        // // Pause icon
        // let pauseSymbol = SKNode()
        // let bar1 = SKShapeNode(rectOf: CGSize(width: 4, height: 16))
        // bar1.fillColor = .white
        // bar1.strokeColor = .clear
        // bar1.position = CGPoint(x: -4, y: 0)
        // pauseSymbol.addChild(bar1)
        // 
        // let bar2 = SKShapeNode(rectOf: CGSize(width: 4, height: 16))
        // bar2.fillColor = .white
        // bar2.strokeColor = .clear
        // bar2.position = CGPoint(x: 4, y: 0)
        // pauseSymbol.addChild(bar2)
        // 
        // pauseButton.addChild(pauseSymbol)
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
            // Pause button - temporarily disabled
            // if node.name == "pauseButton" || node.parent?.name == "pauseButton" {
            //     SoundManager.shared.playSound(.buttonTap)
            //     showPauseMenu()
            //     return
            // }
            
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
            
            // Update Bitcoin network hash rate visualization
            updateHashRate()
            
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
        pathAngle += 0.04 * gameSpeed  // Doubled from 0.02 to 0.04 for faster initial movement
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
        
        // Randomly select how many simultaneous lightning strikes (2-4)
        let numberOfStrikes = Int.random(in: 2...4)
        
        // Ensure we don't try to hit more bubbles than exist
        let strikes = min(numberOfStrikes, cryptoBubbles.count)
        
        // Shuffle bubbles to get random targets
        let shuffledBubbles = cryptoBubbles.shuffled()
        
        // Create lightning effects with staggered timing for visual appeal
        for i in 0..<strikes {
            let targetBubble = shuffledBubbles[i]
            
            // Introduce slight delay between lightning bolts for visual effect
            let delay = Double(i) * 0.05 // 50ms delay between each bolt
            
            // Slightly randomize start positions around the center circle edge
            let angle = Double.random(in: 0...(2 * Double.pi))
            let offsetX = cos(angle) * Double(radius) * 0.8
            let offsetY = sin(angle) * Double(radius) * 0.8
            
            let startPoint = CGPoint(
                x: centerCircle.position.x + CGFloat(offsetX),
                y: centerCircle.position.y + CGFloat(offsetY)
            )
            
            // Delayed strike
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                // Create visual lightning effect
                self.createLightningBolt(from: startPoint, to: targetBubble.position) { [weak self] in
                    // Only handle bubble hit if it's still in the scene
                    if targetBubble.parent != nil {
                        self?.handleBubbleHit(bubble: targetBubble)
                    }
                }
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
        
        // Replace the popped bubble with a new one immediately
        let minBubbleCount = 10  // Maintain at least this many bubbles
        
        if cryptoBubbles.count < minBubbleCount {
            // If we still have some bubbles, add a replacement with animation
            if !cryptoBubbles.isEmpty {
                addReplacementBubble()
            } else {
                // If all bubbles are gone, fetch new data immediately
                fetchCryptoData()
                
                // If API fails, create fallback bubbles after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self, self.cryptoBubbles.isEmpty else { return }
                    self.createFallbackBubbles(minCount: minBubbleCount)
                }
            }
        }
        
        // Play sound effect
        SoundManager.shared.playSound(.successTap)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Bitcoin Hash Power Visualization
    
    private func setupHashMeter() {
        // Load the persistent hash rate from UserDefaults
        baseHashRate = UserDefaults.standard.double(forKey: "highestHashRate")
        if baseHashRate < 500.0 {
            // If no previous hash rate stored, start at 500 EH/s (2023-2024 levels)
            baseHashRate = 500.0
        }
        
        // Set current hash rate to at least the base rate
        currentHashRate = baseHashRate
        
        // Bitcoin hash power visualization - resembles a mining chip array
        hashMeter = SKNode()
        
        // Position below the main circle instead of inside it
        // Note: Main circle radius is determined in setupGame() with radius variable
        let circleBottom = centerCircle.position.y - radius
        hashMeter.position = CGPoint(x: centerCircle.position.x, y: circleBottom - 40) // 40 points below the circle
        hashMeter.zPosition = 5
        addChild(hashMeter)
        
        // Create hash rate label with Bitcoin font styling - make it larger and more visible
        let bitcoinOrange = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) // Bitcoin orange
        hashRateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hashRateLabel.fontSize = 16
        hashRateLabel.fontColor = bitcoinOrange
        hashRateLabel.position = CGPoint(x: -25, y: 0)
        hashRateLabel.horizontalAlignmentMode = .center
        hashRateLabel.verticalAlignmentMode = .center
        hashRateLabel.text = String(format: "%.1f EH/s", currentHashRate)
        hashMeter.addChild(hashRateLabel)
        
        // Create a container node for the chip grid - position closer to the hash rate text
        let chipsContainer = SKNode()
        chipsContainer.position = CGPoint(x: 30, y: 0) // Position closer to the hash rate text
        hashMeter.addChild(chipsContainer)
        
        // Create small "chip" elements arranged in a grid pattern
        let chipSize: CGFloat = 4
        let chipSpacing: CGFloat = 2
        let rows = 3
        let cols = 5
        
        for row in 0..<rows {
            for col in 0..<cols {
                let chip = SKShapeNode(rectOf: CGSize(width: chipSize, height: chipSize), cornerRadius: 1)
                chip.fillColor = bitcoinOrange
                chip.strokeColor = UIColor.orange.withAlphaComponent(0.5)
                chip.position = CGPoint(
                    x: CGFloat(col) * (chipSize + chipSpacing),
                    y: CGFloat(row) * (chipSize + chipSpacing) - 4 // Slight vertical adjustment
                )
                chipsContainer.addChild(chip)
                hashChips.append(chip)
            }
        }
        
        // Add label explaining what this represents - make it clearer and positioned below hash rate
        let descriptionLabel = SKLabelNode(fontNamed: "AvenirNext")
        descriptionLabel.fontSize = 12
        descriptionLabel.fontColor = .white
        descriptionLabel.position = CGPoint(x: -25, y: -20) // Position directly below the hash rate
        descriptionLabel.horizontalAlignmentMode = .center
        descriptionLabel.text = "HASHRATE"
        hashMeter.addChild(descriptionLabel)
        
        // Start with initial visualization
        updateHashRate()
    }
    
    private func updateHashRate() {
        // Calculate a new potential hash rate based on current score
        // Use the base hash rate as a starting point with slower growth
        let scoreHashRate = baseHashRate * pow(1.05, Double(score) / 10)
        
        // Always use whichever is higher - this ensures hash rate never decreases
        // Cap the maximum hash rate to prevent display issues
        currentHashRate = min(5000.0, max(scoreHashRate, currentHashRate))
        
        // Format the hash rate with appropriate units that scale automatically through the Bitcoin mining units
        // Start with MH/s and progress through: MH/s → GH/s → TH/s → PH/s → EH/s → ZH/s
        var displayRate = currentHashRate
        var unit = "MH/s" // Start with Megahashes
        
        // Scale through the units as the hash rate grows
        if displayRate >= 1000 {
            displayRate /= 1000
            unit = "GH/s" // Gigahashes
        }
        
        if displayRate >= 1000 {
            displayRate /= 1000
            unit = "TH/s" // Terahashes
        }
        
        if displayRate >= 1000 {
            displayRate /= 1000
            unit = "PH/s" // Petahashes
        }
        
        if displayRate >= 1000 {
            displayRate /= 1000
            unit = "EH/s" // Exahashes
        }
        
        if displayRate >= 1000 {
            displayRate /= 1000
            unit = "ZH/s" // Zettahashes
        }
        
        // Cap at 999.9 ZH/s to prevent layout issues
        displayRate = min(999.9, displayRate)
        
        // Format with the number and unit
        let formattedRate = String(format: "%.1f %@", displayRate, unit)
        
        hashRateLabel.text = formattedRate
        
        // Visual effect: pulse the chips at different rates based on hash power
        for (index, chip) in hashChips.enumerated() {
            // Remove existing actions
            chip.removeAllActions()
            
            // Calculate pulse speed based on hash rate and chip position
            let pulseSpeed = 0.5 / min(5.0, max(0.2, Double(score) / 20.0))
            let delay = Double(index) * pulseSpeed / Double(hashChips.count)
            
            // Create pulse animation
            let pulse = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 0.3, duration: pulseSpeed * 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: pulseSpeed * 0.6)
            ])
            
            // Run continuous pulse animation
            chip.run(SKAction.repeatForever(pulse))
        }
    }
    
    // MARK: - Visual Effects
    
    // Track recent explosions to throttle when too many happen at once
    private var recentExplosions = 0
    private var lastExplosionTime: TimeInterval = 0
    
    private func createExplosion(at position: CGPoint, color: UIColor) {
        // Performance optimization: limit explosions when multiple happen in quick succession
        let currentTime = CACurrentMediaTime()
        
        // Reset counter if enough time has passed
        if currentTime - lastExplosionTime > 0.5 {
            recentExplosions = 0
        }
        
        // Update explosion tracking
        recentExplosions += 1
        lastExplosionTime = currentTime
        
        // When many explosions happen at once, use a simplified effect
        let isHighLoad = recentExplosions > 2
        
        // Extremely simplified version under high load
        if isHighLoad {
            // Just show a single sprite that scales and fades out
            let flash = SKShapeNode(circleOfRadius: 20)
            flash.fillColor = color
            flash.alpha = 0.7
            flash.position = position
            flash.zPosition = 2
            addChild(flash)
            
            // Simple scale and fade
            let scaleAction = SKAction.scale(to: 1.5, duration: 0.2)
            let fadeAction = SKAction.fadeOut(withDuration: 0.2)
            flash.run(SKAction.group([scaleAction, fadeAction])) { [weak flash] in
                flash?.removeFromParent()
            }
            return
        }
        
        // Regular load - use a more efficient but still visually appealing effect
        // Use just 3-4 particles instead of 5-8
        let particleCount = Int.random(in: 3...4)
        let burstRadius = CGFloat.random(in: 20...30)
        
        // Create a particle container to batch operations
        let container = SKNode()
        container.position = position
        container.zPosition = 2
        addChild(container)
        
        for _ in 0..<particleCount {
            let particleSize = CGFloat.random(in: 3...5)
            let particle = SKShapeNode(circleOfRadius: particleSize)
            particle.fillColor = color
            particle.strokeColor = .clear
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: burstRadius/2...burstRadius)
            particle.position = .zero
            container.addChild(particle)
            
            // Combine move and fade into a single group action
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            let fadeAction = SKAction.fadeOut(withDuration: 0.3)
            
            // Group actions for better performance
            particle.run(SKAction.group([moveAction, fadeAction]))
        }
        
        // Remove container quickly
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    // Helper method to create unique crypto list
    private func createUniqueCryptoList(excluding usedSymbols: Set<String>) -> [CryptoCurrency] {
        return [
            CryptoCurrency(symbol: "ETH", name: "Ethereum", price: 3500.00, priceChangePercentage24h: 2.5, marketCap: 420_000_000_000),
            CryptoCurrency(symbol: "SOL", name: "Solana", price: 120.00, priceChangePercentage24h: 5.0, marketCap: 51_000_000_000),
            CryptoCurrency(symbol: "ADA", name: "Cardano", price: 0.45, priceChangePercentage24h: -1.2, marketCap: 16_000_000_000),
            CryptoCurrency(symbol: "XRP", name: "Ripple", price: 0.60, priceChangePercentage24h: 0.8, marketCap: 33_000_000_000),
            CryptoCurrency(symbol: "DOT", name: "Polkadot", price: 6.50, priceChangePercentage24h: -0.5, marketCap: 8_500_000_000),
            CryptoCurrency(symbol: "DOGE", name: "Dogecoin", price: 0.08, priceChangePercentage24h: -3.0, marketCap: 11_000_000_000),
            CryptoCurrency(symbol: "AVAX", name: "Avalanche", price: 35.00, priceChangePercentage24h: 4.2, marketCap: 13_000_000_000),
            CryptoCurrency(symbol: "MATIC", name: "Polygon", price: 0.70, priceChangePercentage24h: 1.5, marketCap: 7_000_000_000),
            CryptoCurrency(symbol: "LINK", name: "Chainlink", price: 14.20, priceChangePercentage24h: 3.1, marketCap: 8_000_000_000),
            CryptoCurrency(symbol: "UNI", name: "Uniswap", price: 8.90, priceChangePercentage24h: 1.7, marketCap: 5_000_000_000),
            CryptoCurrency(symbol: "ATOM", name: "Cosmos", price: 9.40, priceChangePercentage24h: 2.3, marketCap: 3_500_000_000),
            CryptoCurrency(symbol: "ALGO", name: "Algorand", price: 0.19, priceChangePercentage24h: 0.5, marketCap: 1_500_000_000),
            CryptoCurrency(symbol: "FIL", name: "Filecoin", price: 5.30, priceChangePercentage24h: 4.8, marketCap: 2_500_000_000),
            CryptoCurrency(symbol: "NEAR", name: "NEAR Protocol", price: 6.10, priceChangePercentage24h: 3.2, marketCap: 6_000_000_000),
            CryptoCurrency(symbol: "ICP", name: "Internet Computer", price: 12.50, priceChangePercentage24h: -1.8, marketCap: 6_500_000_000),
            CryptoCurrency(symbol: "VET", name: "VeChain", price: 0.03, priceChangePercentage24h: 1.1, marketCap: 2_100_000_000),
            CryptoCurrency(symbol: "HBAR", name: "Hedera", price: 0.08, priceChangePercentage24h: 0.9, marketCap: 2_700_000_000),
            CryptoCurrency(symbol: "ONE", name: "Harmony", price: 0.02, priceChangePercentage24h: -0.8, marketCap: 250_000_000),
            CryptoCurrency(symbol: "THETA", name: "Theta Network", price: 0.95, priceChangePercentage24h: 2.7, marketCap: 950_000_000),
            CryptoCurrency(symbol: "ZIL", name: "Zilliqa", price: 0.03, priceChangePercentage24h: 3.5, marketCap: 450_000_000),
            CryptoCurrency(symbol: "XTZ", name: "Tezos", price: 0.85, priceChangePercentage24h: 1.3, marketCap: 800_000_000),
            CryptoCurrency(symbol: "EOS", name: "EOS", price: 0.70, priceChangePercentage24h: -0.2, marketCap: 800_000_000),
            CryptoCurrency(symbol: "XLM", name: "Stellar", price: 0.11, priceChangePercentage24h: 0.4, marketCap: 3_100_000_000),
            CryptoCurrency(symbol: "TRX", name: "TRON", price: 0.12, priceChangePercentage24h: 1.6, marketCap: 12_000_000_000),
            CryptoCurrency(symbol: "CHZ", name: "Chiliz", price: 0.11, priceChangePercentage24h: 5.2, marketCap: 850_000_000),
            CryptoCurrency(symbol: "LTC", name: "Litecoin", price: 82.50, priceChangePercentage24h: 1.1, marketCap: 6_100_000_000),
            CryptoCurrency(symbol: "CAKE", name: "PancakeSwap", price: 2.40, priceChangePercentage24h: 3.7, marketCap: 520_000_000),
            CryptoCurrency(symbol: "EGLD", name: "MultiversX", price: 43.20, priceChangePercentage24h: 4.9, marketCap: 1_100_000_000),
            CryptoCurrency(symbol: "FLOW", name: "Flow", price: 0.75, priceChangePercentage24h: 2.1, marketCap: 850_000_000),
            CryptoCurrency(symbol: "QNT", name: "Quant", price: 105.00, priceChangePercentage24h: 0.6, marketCap: 1_350_000_000),
            CryptoCurrency(symbol: "APE", name: "ApeCoin", price: 1.40, priceChangePercentage24h: -1.3, marketCap: 600_000_000),
            CryptoCurrency(symbol: "KSM", name: "Kusama", price: 30.20, priceChangePercentage24h: 3.8, marketCap: 280_000_000),
            CryptoCurrency(symbol: "ENJ", name: "Enjin Coin", price: 0.32, priceChangePercentage24h: 1.9, marketCap: 350_000_000),
            CryptoCurrency(symbol: "YFI", name: "Yearn Finance", price: 7900.00, priceChangePercentage24h: 2.3, marketCap: 265_000_000),
            CryptoCurrency(symbol: "BAT", name: "Basic Attention", price: 0.25, priceChangePercentage24h: 1.2, marketCap: 375_000_000)
        ]
    }
    
    // Add a new bubble to replace one that was popped
    private func addReplacementBubble() {
        // Get all existing bubble symbols to avoid duplicates
        var existingSymbols = Set<String>()
        for bubble in cryptoBubbles {
            if let symbol = bubble.name?.replacingOccurrences(of: "bubble_", with: "") {
                existingSymbols.insert(symbol.lowercased())
            }
        }
        
        // Create our own cryptocurrencies with unique symbols
        let altCoins = createUniqueCryptoList(excluding: existingSymbols)
        
        // Filter coins to only those not already in use
        let availableCoins = altCoins.filter { !existingSymbols.contains($0.symbol.lowercased()) }
        
        // Pick a random available coin, or any coin if we run out of unique ones
        let randomCoin = availableCoins.isEmpty ? altCoins.randomElement()! : availableCoins.randomElement()!
        
        // Get color from our unique color generator
        let coinColor = getUniqueColorForSymbol(randomCoin.symbol)
        
        // Use the coin's bubble size based on market cap (or random size for variety)
        let size = randomCoin.bubbleSize * CGFloat.random(in: 0.8...1.2) // Add some randomness
        let bubble = SKShapeNode(circleOfRadius: size/2)
        bubble.fillColor = coinColor
        bubble.strokeColor = randomCoin.priceChangePercentage24h >= 0 ? UIColor.green : UIColor.red
        bubble.lineWidth = 2.0
        bubble.name = "bubble_" + randomCoin.symbol
        
        // Add symbol label
        let symbolLabel = SKLabelNode(text: randomCoin.symbol)
        symbolLabel.fontName = "AvenirNext-Bold"
        symbolLabel.fontSize = min(size/3, 16)
        symbolLabel.fontColor = UIColor.white
        symbolLabel.position = CGPoint(x: 0, y: 0)
        symbolLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        bubble.addChild(symbolLabel)
        
        // Add shimmer effect
        let shimmerAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ])
        bubble.run(SKAction.repeatForever(shimmerAction))
        
        // Position at the edge of the screen with a bit of randomness
        let entryPoint = Int.random(in: 0...3) // 0: top, 1: right, 2: bottom, 3: left
        var xPos: CGFloat = 0
        var yPos: CGFloat = 0
        
        // Get scene dimensions
        let sceneWidth = self.size.width
        let sceneHeight = self.size.height
        
        // Get center circle position and dimensions for checking
        let centerX = sceneWidth / 2
        let centerY = sceneHeight / 2
        let circleRadius = radius + 20 // Same padding as in distributeBubblesEvenly
        
        switch entryPoint {
        case 0: // Top
            xPos = CGFloat.random(in: size...sceneWidth-size)
            yPos = sceneHeight + size
        case 1: // Right
            xPos = sceneWidth + size
            yPos = CGFloat.random(in: size...sceneHeight-size)
        case 2: // Bottom
            xPos = CGFloat.random(in: size...sceneWidth-size)
            yPos = -size
        default: // Left
            xPos = -size
            yPos = CGFloat.random(in: size...sceneHeight-size)
        }
        
        // Calculate entry angle to avoid direct path through center circle
        let dx = centerX - xPos
        let dy = centerY - yPos
        let angleToCenter = atan2(dy, dx)
        
        // Adjust entry angle by a random offset to avoid center
        let offsetAngle = CGFloat.random(in: -0.6...0.6) // About ±30 degrees
        
        bubble.position = CGPoint(x: xPos, y: yPos)
        
        // Add physics body
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: size/2)
        bubble.physicsBody?.isDynamic = true
        bubble.physicsBody?.mass = CGFloat(Double(size) / 40.0)
        bubble.physicsBody?.categoryBitMask = bubbleCategory
        bubble.physicsBody?.contactTestBitMask = bubbleCategory
        bubble.physicsBody?.collisionBitMask = bubbleCategory | ballCategory
        bubble.physicsBody?.restitution = 0.9
        bubble.physicsBody?.linearDamping = 0.5
        bubble.physicsBody?.angularDamping = 0.5
        bubble.physicsBody?.allowsRotation = true
        
        addChild(bubble)
        cryptoBubbles.append(bubble)
        
        // Apply impulse toward playfield but avoiding center circle
        
        // Use the offset angle to calculate a new target point that avoids the center
        let adjustedAngle = Double(angleToCenter + offsetAngle)
        
        // Calculate a target point that's on the opposite side of the screen but avoiding center
        let targetX = centerX + CGFloat(cos(adjustedAngle)) * circleRadius * 1.5 // Target outside the circle
        let targetY = centerY + CGFloat(sin(adjustedAngle)) * circleRadius * 1.5
        
        // Direction vector to the adjusted target
        let targetDx = targetX - bubble.position.x
        let targetDy = targetY - bubble.position.y
        
        // Calculate distance for impulse strength
        let targetDistance = CGFloat(sqrt(Double(targetDx*targetDx + targetDy*targetDy)))
        let normalizedDirection = CGVector(
            dx: targetDx / targetDistance * CGFloat.random(in: 70...140),
            dy: targetDy / targetDistance * CGFloat.random(in: 70...140)
        )
        
        bubble.physicsBody?.applyImpulse(normalizedDirection)
    }
    
    // Helper method to generate a unique color based on cryptocurrency symbol
    private func getUniqueColorForSymbol(_ symbol: String) -> UIColor {
        // Convert symbol to lowercase to ensure consistent coloring
        let symbolLower = symbol.lowercased()
        
        // Use the symbol's letters to create a unique but consistent color
        var hue: CGFloat = 0
        let saturation: CGFloat = 0.85  // High saturation for vibrant colors
        var brightness: CGFloat = 0.9   // Good brightness for visibility
        
        // Calculate hue based on the ASCII values of the symbol's letters
        if let firstChar = symbolLower.unicodeScalars.first?.value {
            // Use the first character to get the primary hue (0-1 range)
            hue = CGFloat(firstChar % 26) / 26.0
            
            // Adjust hue slightly based on the entire string to ensure uniqueness
            if symbolLower.count > 1 {
                let secondCharValue = symbolLower.unicodeScalars[symbolLower.index(symbolLower.startIndex, offsetBy: 1)].value
                hue = (hue + CGFloat(secondCharValue % 10) / 100.0).truncatingRemainder(dividingBy: 1.0)
            }
            
            // Adjust brightness slightly based on string length
            brightness = min(0.95, 0.8 + CGFloat(symbolLower.count) / 50.0)
        }
        
        // Create color from HSB values
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    // Distribute bubbles around the screen like cryptobubbles.net - avoiding center circle
    private func distributeBubblesEvenly() {
        guard cryptoBubbles.count > 1 else { return }
        
        // Get center circle position and dimensions
        let centerX = size.width / 2
        let centerY = size.height / 2
        let circleRadius = radius + 20 // Add padding to ensure bubbles start outside circle
        
        // Configure physics world for better bubble interactions
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.05) // Very slight gravity
        
        // Place bubbles with full screen coverage but avoiding center circle
        for bubble in cryptoBubbles {
            var validPosition = false
            var xPos: CGFloat = 0
            var yPos: CGFloat = 0
            
            // Keep trying positions until we find one outside the center circle
            while !validPosition {
                // Generate a random position across entire screen with padding
                xPos = CGFloat.random(in: 40...size.width-40)
                yPos = CGFloat.random(in: 40...size.height-40)
                
                // Calculate distance from center
                let dx = xPos - centerX
                let dy = yPos - centerY
                let distanceFromCenter = sqrt(dx*dx + dy*dy)
                
                // Position is valid if it's outside the center circle
                if distanceFromCenter > circleRadius {
                    validPosition = true
                }
            }
            
            bubble.position = CGPoint(x: xPos, y: yPos)
            
            // Apply initial random impulse for more dynamic movement
            // Calculate direction - slightly biased away from center for initial dispersion
            let dx = bubble.position.x - centerX
            let dy = bubble.position.y - centerY
            let magnitude = sqrt(dx*dx + dy*dy)
            
            // Normalized direction vector with random magnitude
            let directionX = dx / magnitude
            let directionY = dy / magnitude
            
            let randomImpulse = CGVector(
                dx: directionX * CGFloat.random(in: 5...15) + CGFloat.random(in: -15...15),
                dy: directionY * CGFloat.random(in: 5...15) + CGFloat.random(in: -15...15)
            )
            
            bubble.physicsBody?.applyImpulse(randomImpulse)
        }
    }
    
    // Show Michael Saylor quote at bottom of screen
    // Create fallback bubbles with unique symbols when needed
    private func createFallbackBubbles(minCount: Int = 5, usedSymbols: Set<String> = []) {
        // Extended fallback crypto data with many options
        let fallbackCryptos = [
            CryptoCurrency(symbol: "ETH", name: "Ethereum", price: 3500.00, priceChangePercentage24h: 2.5, marketCap: 420_000_000_000),
            CryptoCurrency(symbol: "SOL", name: "Solana", price: 120.00, priceChangePercentage24h: 5.0, marketCap: 51_000_000_000),
            CryptoCurrency(symbol: "ADA", name: "Cardano", price: 0.45, priceChangePercentage24h: -1.2, marketCap: 16_000_000_000),
            CryptoCurrency(symbol: "XRP", name: "Ripple", price: 0.60, priceChangePercentage24h: 0.8, marketCap: 33_000_000_000),
            CryptoCurrency(symbol: "DOT", name: "Polkadot", price: 6.50, priceChangePercentage24h: -0.5, marketCap: 8_500_000_000),
            CryptoCurrency(symbol: "DOGE", name: "Dogecoin", price: 0.08, priceChangePercentage24h: -3.0, marketCap: 11_000_000_000),
            CryptoCurrency(symbol: "AVAX", name: "Avalanche", price: 35.00, priceChangePercentage24h: 4.2, marketCap: 13_000_000_000),
            CryptoCurrency(symbol: "MATIC", name: "Polygon", price: 0.70, priceChangePercentage24h: 1.5, marketCap: 7_000_000_000),
            CryptoCurrency(symbol: "LINK", name: "Chainlink", price: 14.20, priceChangePercentage24h: 3.1, marketCap: 8_000_000_000),
            CryptoCurrency(symbol: "UNI", name: "Uniswap", price: 8.90, priceChangePercentage24h: 1.7, marketCap: 5_000_000_000),
            CryptoCurrency(symbol: "ATOM", name: "Cosmos", price: 9.40, priceChangePercentage24h: 2.3, marketCap: 3_500_000_000),
            CryptoCurrency(symbol: "ALGO", name: "Algorand", price: 0.19, priceChangePercentage24h: 0.5, marketCap: 1_500_000_000),
            CryptoCurrency(symbol: "FIL", name: "Filecoin", price: 5.30, priceChangePercentage24h: 4.8, marketCap: 2_500_000_000),
            CryptoCurrency(symbol: "NEAR", name: "NEAR Protocol", price: 6.10, priceChangePercentage24h: 3.2, marketCap: 6_000_000_000),
            CryptoCurrency(symbol: "ICP", name: "Internet Computer", price: 12.50, priceChangePercentage24h: -1.8, marketCap: 6_500_000_000),
            CryptoCurrency(symbol: "VET", name: "VeChain", price: 0.03, priceChangePercentage24h: 1.1, marketCap: 2_100_000_000),
            CryptoCurrency(symbol: "HBAR", name: "Hedera", price: 0.08, priceChangePercentage24h: 0.9, marketCap: 2_700_000_000),
            CryptoCurrency(symbol: "ONE", name: "Harmony", price: 0.02, priceChangePercentage24h: -0.8, marketCap: 250_000_000),
            CryptoCurrency(symbol: "THETA", name: "Theta Network", price: 0.95, priceChangePercentage24h: 2.7, marketCap: 950_000_000),
            CryptoCurrency(symbol: "ZIL", name: "Zilliqa", price: 0.03, priceChangePercentage24h: 3.5, marketCap: 450_000_000),
            CryptoCurrency(symbol: "XTZ", name: "Tezos", price: 0.85, priceChangePercentage24h: 1.3, marketCap: 800_000_000),
            CryptoCurrency(symbol: "EOS", name: "EOS", price: 0.70, priceChangePercentage24h: -0.2, marketCap: 800_000_000),
            CryptoCurrency(symbol: "XLM", name: "Stellar", price: 0.11, priceChangePercentage24h: 0.4, marketCap: 3_100_000_000),
            CryptoCurrency(symbol: "TRX", name: "TRON", price: 0.12, priceChangePercentage24h: 1.6, marketCap: 12_000_000_000),
            CryptoCurrency(symbol: "CHZ", name: "Chiliz", price: 0.11, priceChangePercentage24h: 5.2, marketCap: 850_000_000),
            CryptoCurrency(symbol: "LTC", name: "Litecoin", price: 82.50, priceChangePercentage24h: 1.1, marketCap: 6_100_000_000),
            CryptoCurrency(symbol: "CAKE", name: "PancakeSwap", price: 2.40, priceChangePercentage24h: 3.7, marketCap: 520_000_000),
            CryptoCurrency(symbol: "EGLD", name: "MultiversX", price: 43.20, priceChangePercentage24h: 4.9, marketCap: 1_100_000_000),
            CryptoCurrency(symbol: "FLOW", name: "Flow", price: 0.75, priceChangePercentage24h: 2.1, marketCap: 850_000_000),
            CryptoCurrency(symbol: "QNT", name: "Quant", price: 105.00, priceChangePercentage24h: 0.6, marketCap: 1_350_000_000),
            CryptoCurrency(symbol: "APE", name: "ApeCoin", price: 1.40, priceChangePercentage24h: -1.3, marketCap: 600_000_000),
            CryptoCurrency(symbol: "KSM", name: "Kusama", price: 30.20, priceChangePercentage24h: 3.8, marketCap: 280_000_000),
            CryptoCurrency(symbol: "ENJ", name: "Enjin Coin", price: 0.32, priceChangePercentage24h: 1.9, marketCap: 350_000_000),
            CryptoCurrency(symbol: "YFI", name: "Yearn Finance", price: 7900.00, priceChangePercentage24h: 2.3, marketCap: 265_000_000),
            CryptoCurrency(symbol: "BAT", name: "Basic Attention", price: 0.25, priceChangePercentage24h: 1.2, marketCap: 375_000_000)
        ]
        
        // Convert usedSymbols to mutable copy
        var trackUsedSymbols = usedSymbols
        
        // Create bubbles from fallback data, only using unique symbols
        for crypto in fallbackCryptos.shuffled() {
            // Skip symbols we've already used
            if trackUsedSymbols.contains(crypto.symbol.lowercased()) {
                continue
            }
            
            createCryptoBubble(for: crypto)
            trackUsedSymbols.insert(crypto.symbol.lowercased())
            
            // Check if we have enough bubbles
            if cryptoBubbles.count >= minCount {
                break
            }
        }
        
        // Distribute the bubbles evenly
        distributeBubblesEvenly()
    }
    
    private func showSaylorQuote() {
        // First, remove any existing quote labels to prevent overlapping
        self.enumerateChildNodes(withName: "saylorQuoteLabel") { node, _ in
            node.removeFromParent()
        }
        
        // Array of Michael Saylor Bitcoin quotes (shortened for better display)
        let saylorQuotes = [
            "Bitcoin is digital gold.",
            "Bitcoin is hope.",
            "Bitcoin is inevitable.",
            "Stack sats.",
            "Bitcoin is economic security."
        ]
        
        // Pick a random quote, ensuring we don't repeat the last shown quote
        var quote = ""
        repeat {
            quote = saylorQuotes.randomElement() ?? "Bitcoin is inevitable."
        } while quote == lastShownQuote && saylorQuotes.count > 1
        
        // Update the last shown quote
        lastShownQuote = quote
        
        // Create label for the quote
        let quoteLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        quoteLabel.text = quote
        quoteLabel.fontSize = 24  // Increased from 18 to 24 for better readability
        quoteLabel.fontColor = .orange
        quoteLabel.position = CGPoint(x: size.width/2, y: 70)  // Raised position to avoid bottom cutoff
        quoteLabel.zPosition = 100
        quoteLabel.name = "saylorQuoteLabel" // Add a name to identify quote labels
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
