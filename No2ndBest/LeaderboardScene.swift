//
//  LeaderboardScene.swift
//  No2ndBest
//
//  Created by TR on 4/21/25.
//

import SpriteKit
import GameplayKit

class LeaderboardScene: SKScene {
    
    private var backButton: SKShapeNode!
    private var scoreEntries: [(name: String, score: Int)] = []
    
    override func didMove(to view: SKView) {
        setupLeaderboard()
    }
    
    private func setupLeaderboard() {
        // Set background color
        backgroundColor = .black
        
        // Add stars to background (similar to other scenes)
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
        
        // Create scene title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Leaderboard"
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.85)
        addChild(titleLabel)
        
        // Load score entries
        loadScores()
        
        // Create score table
        createScoreTable()
        
        // Back button
        backButton = createButton(text: "Back", width: size.width * 0.8, height: 60, position: CGPoint(x: size.width/2, y: size.height * 0.15))
        backButton.name = "back"
        addChild(backButton)
    }
    
    private func loadScores() {
        // In a real app, this would load from Game Center or a database
        // For now, we'll create mock data and include the actual high score
        
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        
        // Mock data (plus the actual high score)
        scoreEntries = [
            ("You", highScore),
            ("Player 1", 186),
            ("Player 2", 154),
            ("Player 3", 121),
            ("Player 4", 98),
            ("Player 5", 87),
            ("Player 6", 76),
            ("Player 7", 65),
            ("Player 8", 54),
            ("Player 9", 43)
        ]
        
        // Sort by score descending
        scoreEntries.sort { $0.score > $1.score }
    }
    
    private func createScoreTable() {
        let tableTop = size.height * 0.75
        let rowHeight: CGFloat = 40
        let tableWidth = size.width * 0.9
        
        // Create table background
        let tableBackground = SKShapeNode(rectOf: CGSize(width: tableWidth, height: rowHeight * CGFloat(scoreEntries.count + 1)), cornerRadius: 10)
        tableBackground.fillColor = UIColor.darkGray.withAlphaComponent(0.3)
        tableBackground.strokeColor = .cyan
        tableBackground.lineWidth = 2
        tableBackground.position = CGPoint(x: size.width/2, y: tableTop - (rowHeight * CGFloat(scoreEntries.count)) / 2)
        addChild(tableBackground)
        
        // Create header row
        let headerRank = SKLabelNode(fontNamed: "AvenirNext-Bold")
        headerRank.text = "RANK"
        headerRank.fontSize = 20
        headerRank.fontColor = .cyan
        headerRank.position = CGPoint(x: size.width * 0.2, y: tableTop)
        headerRank.verticalAlignmentMode = .center
        headerRank.horizontalAlignmentMode = .center
        addChild(headerRank)
        
        let headerName = SKLabelNode(fontNamed: "AvenirNext-Bold")
        headerName.text = "NAME"
        headerName.fontSize = 20
        headerName.fontColor = .cyan
        headerName.position = CGPoint(x: size.width * 0.5, y: tableTop)
        headerName.verticalAlignmentMode = .center
        headerName.horizontalAlignmentMode = .center
        addChild(headerName)
        
        let headerScore = SKLabelNode(fontNamed: "AvenirNext-Bold")
        headerScore.text = "SCORE"
        headerScore.fontSize = 20
        headerScore.fontColor = .cyan
        headerScore.position = CGPoint(x: size.width * 0.8, y: tableTop)
        headerScore.verticalAlignmentMode = .center
        headerScore.horizontalAlignmentMode = .center
        addChild(headerScore)
        
        // Add separator
        let separator = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size.width * 0.05, y: tableTop - rowHeight/2))
        path.addLine(to: CGPoint(x: size.width * 0.95, y: tableTop - rowHeight/2))
        separator.path = path
        separator.strokeColor = .white
        separator.lineWidth = 1
        addChild(separator)
        
        // Create rows for each score entry
        for (index, entry) in scoreEntries.enumerated() {
            let rowY = tableTop - rowHeight - CGFloat(index) * rowHeight
            
            // Rank
            let rankLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            rankLabel.text = "\(index + 1)"
            rankLabel.fontSize = 18
            rankLabel.fontColor = .white
            rankLabel.position = CGPoint(x: size.width * 0.2, y: rowY)
            rankLabel.verticalAlignmentMode = .center
            rankLabel.horizontalAlignmentMode = .center
            addChild(rankLabel)
            
            // Name
            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            nameLabel.text = entry.name
            nameLabel.fontSize = 18
            nameLabel.fontColor = entry.name == "You" ? .yellow : .white
            nameLabel.position = CGPoint(x: size.width * 0.5, y: rowY)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            addChild(nameLabel)
            
            // Score
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            scoreLabel.text = "\(entry.score)"
            scoreLabel.fontSize = 18
            scoreLabel.fontColor = entry.name == "You" ? .yellow : .white
            scoreLabel.position = CGPoint(x: size.width * 0.8, y: rowY)
            scoreLabel.verticalAlignmentMode = .center
            scoreLabel.horizontalAlignmentMode = .center
            addChild(scoreLabel)
            
            // Add row separator if not the last row
            if index < scoreEntries.count - 1 {
                let rowSeparator = SKShapeNode()
                let rowPath = CGMutablePath()
                rowPath.move(to: CGPoint(x: size.width * 0.05, y: rowY - rowHeight/2))
                rowPath.addLine(to: CGPoint(x: size.width * 0.95, y: rowY - rowHeight/2))
                rowSeparator.path = rowPath
                rowSeparator.strokeColor = UIColor.white.withAlphaComponent(0.3)
                rowSeparator.lineWidth = 0.5
                addChild(rowSeparator)
            }
        }
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if back button was tapped
        if backButton.contains(location) {
            // Play button sound
            SoundManager.shared.playSound(.buttonTap)
            
            // Return to main menu
            let transition = SKTransition.moveIn(with: .right, duration: 0.5)
            let menuScene = MenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            self.view?.presentScene(menuScene, transition: transition)
        }
    }
}
