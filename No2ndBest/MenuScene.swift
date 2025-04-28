//
//  MenuScene.swift
//  No2ndBest
//
//  Created by TR on 4/21/25.
//

import SpriteKit
import GameplayKit

class MenuScene: SKScene {
    
    // Menu buttons
    private var playButton: SKShapeNode!
    private var settingsButton: SKShapeNode!
    private var leaderboardButton: SKShapeNode!
    
    override func didMove(to view: SKView) {
        setupMenu()
    }
    
    private func setupMenu() {
        // Set background color
        backgroundColor = .black
        
        // Add stars to background (similar to GameScene)
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
        
        // Create game title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "No2ndBest"
        titleLabel.fontSize = 60
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.8)
        addChild(titleLabel)
        
        // Create decorative ball and circle
        let circle = SKShapeNode(circleOfRadius: 80)
        circle.position = CGPoint(x: size.width/2, y: size.height * 0.63)
        circle.strokeColor = UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1.0) // Brighter cyan that matches game style
        circle.lineWidth = 2
        circle.fillColor = .clear
        addChild(circle)
        
        // Create Bitcoin-styled ball (matching the gameplay style)
        let ball = SKShapeNode(circleOfRadius: 20)
        let bitcoinColor = UIColor(red: 0.95, green: 0.7, blue: 0.2, alpha: 1.0) // Bitcoin gold color
        ball.fillColor = bitcoinColor
        ball.strokeColor = .orange
        ball.lineWidth = 1.5
        ball.position = CGPoint(x: size.width/2, y: size.height * 0.63 + 80) // Position at the top of the circle
        
        // Add Bitcoin "₿" symbol to the ball
        let bitcoinSymbol = SKLabelNode(text: "₿")
        bitcoinSymbol.fontSize = 24
        bitcoinSymbol.fontName = "AvenirNext-Bold"
        bitcoinSymbol.verticalAlignmentMode = .center
        bitcoinSymbol.horizontalAlignmentMode = .center
        bitcoinSymbol.fontColor = .white
        bitcoinSymbol.name = "bitcoinSymbol"
        ball.addChild(bitcoinSymbol)
        
        // Add glow effect
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = bitcoinColor.withAlphaComponent(0.3)
        glow.strokeColor = .clear
        glow.position = .zero
        glow.zPosition = -1
        ball.addChild(glow)
        
        // Add pulsing glow animation
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 0.8, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(pulseAction))
        
        // Add continuous rotation animation to the Bitcoin symbol
        let rotateSymbolAction = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        bitcoinSymbol.run(SKAction.repeatForever(rotateSymbolAction))
        
        addChild(ball)
        
        // Add rotation animation to the ball around the circular path
        let rotateAction = SKAction.customAction(withDuration: 3.0) { [weak self] node, time in
            guard let self = self else { return }
            let angle = time * 2 * .pi
            let radius: CGFloat = 80
            let centerX = self.size.width/2
            let centerY = self.size.height * 0.63
            
            node.position.x = centerX + cos(angle) * radius
            node.position.y = centerY + sin(angle) * radius
        }
        ball.run(SKAction.repeatForever(rotateAction))
        
        // Create buttons
        let buttonWidth: CGFloat = size.width * 0.7
        let buttonHeight: CGFloat = 60
        let buttonSpacing: CGFloat = 20
        let startY = size.height * 0.4
        
        // Play button
        playButton = createButton(text: "PLAY", width: buttonWidth, height: buttonHeight, position: CGPoint(x: size.width/2, y: startY))
        addChild(playButton)
        
        // Settings button
        settingsButton = createButton(text: "SETTINGS", width: buttonWidth, height: buttonHeight, position: CGPoint(x: size.width/2, y: startY - buttonHeight - buttonSpacing))
        addChild(settingsButton)
        
        // Leaderboard button
        leaderboardButton = createButton(text: "LEADERBOARD", width: buttonWidth, height: buttonHeight, position: CGPoint(x: size.width/2, y: startY - 2 * (buttonHeight + buttonSpacing)))
        addChild(leaderboardButton)
        
        // Add high score display
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        highScoreLabel.text = "HIGH SCORE: \(highScore)"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = .lightGray
        highScoreLabel.position = CGPoint(x: size.width/2, y: startY - 3 * (buttonHeight + buttonSpacing))
        addChild(highScoreLabel)
        
        // 2025 BTC Conference Hackathon label
        let hackathonLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        hackathonLabel.text = "BTC Conference Hackathon 2025"
        hackathonLabel.fontSize = 15
        hackathonLabel.fontColor = .darkGray
        hackathonLabel.position = CGPoint(x: size.width/2, y: 30)
        addChild(hackathonLabel)
    }
    
    private func createButton(text: String, width: CGFloat, height: CGFloat, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        button.fillColor = .darkGray
        button.strokeColor = .cyan
        button.lineWidth = 2
        button.position = position
        button.name = text.lowercased()
        
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if a button was tapped
        if playButton.contains(location) {
            pulseButton(playButton)
            startGame()
        } else if settingsButton.contains(location) {
            pulseButton(settingsButton)
            showSettings()
        } else if leaderboardButton.contains(location) {
            pulseButton(leaderboardButton)
            showLeaderboard()
        }
    }
    
    private func pulseButton(_ button: SKShapeNode) {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        button.run(pulse)
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func startGame() {
        // Load GameScene
        let transition = SKTransition.fade(withDuration: 0.5)
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        self.view?.presentScene(gameScene, transition: transition)
        
        // Play sound
        SoundManager.shared.playSound(.buttonTap)
    }
    
    private func showSettings() {
        // Load SettingsScene
        let transition = SKTransition.moveIn(with: .right, duration: 0.5)
        let settingsScene = SettingsScene(size: self.size)
        settingsScene.scaleMode = .aspectFill
        self.view?.presentScene(settingsScene, transition: transition)
        
        // Play sound
        SoundManager.shared.playSound(.buttonTap)
    }
    
    private func showLeaderboard() {
        // Load LeaderboardScene
        let transition = SKTransition.moveIn(with: .left, duration: 0.5)
        let leaderboardScene = LeaderboardScene(size: self.size)
        leaderboardScene.scaleMode = .aspectFill
        self.view?.presentScene(leaderboardScene, transition: transition)
        
        // Play sound
        SoundManager.shared.playSound(.buttonTap)
    }
}
