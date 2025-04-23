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
        circle.strokeColor = .cyan
        circle.lineWidth = 2
        circle.fillColor = .clear
        addChild(circle)
        
        let ball = SKShapeNode(circleOfRadius: 20)
        ball.fillColor = .green
        ball.strokeColor = .white
        ball.lineWidth = 1
        ball.position = CGPoint(x: size.width/2, y: size.height * 0.63 + 80) // Position at the top of the circle
        addChild(ball)
        
        // Add rotation animation to the ball
        let rotateAction = SKAction.customAction(withDuration: 3.0) { _, time in
            let angle = time * 2 * .pi
            let radius: CGFloat = 80
            let centerX = self.size.width/2
            let centerY = self.size.height * 0.63
            
            ball.position.x = centerX + cos(angle) * radius
            ball.position.y = centerY + sin(angle) * radius
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
        
        // Add copyright text
        let copyrightLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        copyrightLabel.text = "© 2025 Super Games"
        copyrightLabel.fontSize = 15
        copyrightLabel.fontColor = .darkGray
        copyrightLabel.position = CGPoint(x: size.width/2, y: 30)
        addChild(copyrightLabel)
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
