//
//  SettingsScene.swift
//  No2ndBest
//
//  Created by TR on 4/21/25.
//

import SpriteKit
import GameplayKit

class SettingsScene: SKScene {
    
    private var musicToggle: SKShapeNode!
    private var soundToggle: SKShapeNode!
    private var backButton: SKShapeNode!
    private var difficultyControl: SKShapeNode!
    
    override func didMove(to view: SKView) {
        setupSettings()
    }
    
    private func setupSettings() {
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
        titleLabel.text = "Settings"
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.85)
        addChild(titleLabel)
        
        // Create settings controls
        let startY = size.height * 0.7
        let spacing: CGFloat = 80
        
        // Music toggle
        let musicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        addSettingRow(title: "Music", y: startY, enabled: musicEnabled) { toggle in
            self.musicToggle = toggle
        }
        
        // Sound effects toggle
        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        addSettingRow(title: "Sound Effects", y: startY - spacing, enabled: soundEnabled) { toggle in
            self.soundToggle = toggle
        }
        
        // Difficulty slider
        addDifficultyControl(y: startY - 2 * spacing)
        
        // Reset high score button
        let resetButton = createTextButton(text: "Reset High Score", width: size.width * 0.8, height: 50, position: CGPoint(x: size.width/2, y: startY - 3 * spacing))
        resetButton.name = "reset"
        addChild(resetButton)
        
        // Back button
        backButton = createTextButton(text: "Back", width: size.width * 0.8, height: 60, position: CGPoint(x: size.width/2, y: size.height * 0.15))
        backButton.name = "back"
        addChild(backButton)
    }
    
    private func addSettingRow(title: String, y: CGFloat, enabled: Bool, completion: @escaping (SKShapeNode) -> Void) {
        // Create label
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = title
        label.fontSize = 24
        label.fontColor = .white
        label.position = CGPoint(x: size.width * 0.3, y: y)
        label.horizontalAlignmentMode = .left
        addChild(label)
        
        // Create toggle switch
        let toggle = createToggleSwitch(position: CGPoint(x: size.width * 0.75, y: y), isOn: enabled)
        addChild(toggle)
        completion(toggle)
    }
    
    private func createToggleSwitch(position: CGPoint, isOn: Bool) -> SKShapeNode {
        let width: CGFloat = 70
        let height: CGFloat = 35
        
        let toggle = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height/2)
        toggle.position = position
        toggle.fillColor = isOn ? .systemGreen : .darkGray
        toggle.strokeColor = .lightGray
        toggle.lineWidth = 1
        toggle.name = "toggle"
        
        // Create the toggle knob
        let knobSize: CGFloat = height - 8
        let knob = SKShapeNode(circleOfRadius: knobSize/2)
        knob.fillColor = .white
        knob.strokeColor = .clear
        
        // Position the knob based on state
        let knobX: CGFloat = isOn ? width/2 - 6 : -width/2 + 6
        knob.position = CGPoint(x: knobX, y: 0)
        knob.name = "knob"
        
        toggle.addChild(knob)
        
        // Store the current state
        toggle.userData = NSMutableDictionary()
        toggle.userData?.setValue(isOn, forKey: "isOn")
        
        return toggle
    }
    
    private func addDifficultyControl(y: CGFloat) {
        // Create label
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "Difficulty"
        label.fontSize = 24
        label.fontColor = .white
        label.position = CGPoint(x: size.width * 0.3, y: y + 35) // Move label above the control
        label.horizontalAlignmentMode = .left
        addChild(label)
        
        // Get current difficulty
        let difficulty = UserDefaults.standard.integer(forKey: "difficulty")
        
        // Create difficulty selector
        let difficultyOptions = ["Easy", "Medium", "Hard"]
        
        let segmentWidth: CGFloat = 60
        let totalWidth: CGFloat = segmentWidth * CGFloat(difficultyOptions.count)
        
        difficultyControl = SKShapeNode(rectOf: CGSize(width: totalWidth, height: 35), cornerRadius: 5)
        difficultyControl.position = CGPoint(x: size.width * 0.7, y: y)
        difficultyControl.fillColor = .darkGray
        difficultyControl.strokeColor = .lightGray
        difficultyControl.lineWidth = 1
        difficultyControl.name = "difficultyControl"
        addChild(difficultyControl)
        
        // Add selector indicator
        let selectedSegment = SKShapeNode(rectOf: CGSize(width: segmentWidth - 4, height: 31), cornerRadius: 3)
        selectedSegment.fillColor = .cyan
        selectedSegment.strokeColor = .clear
        selectedSegment.position = CGPoint(x: -totalWidth/2 + segmentWidth/2 + CGFloat(difficulty) * segmentWidth, y: 0)
        selectedSegment.name = "selectedSegment"
        selectedSegment.zPosition = 1
        difficultyControl.addChild(selectedSegment)
        
        // Add text labels for options
        for (index, option) in difficultyOptions.enumerated() {
            let optionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            optionLabel.text = option
            optionLabel.fontSize = 16
            optionLabel.fontColor = index == difficulty ? .black : .white
            optionLabel.position = CGPoint(x: -totalWidth/2 + segmentWidth/2 + CGFloat(index) * segmentWidth, y: 0)
            optionLabel.verticalAlignmentMode = .center
            optionLabel.name = "option\(index)"
            optionLabel.zPosition = 2
            difficultyControl.addChild(optionLabel)
        }
        
        // Store the current difficulty
        difficultyControl.userData = NSMutableDictionary()
        difficultyControl.userData?.setValue(difficulty, forKey: "difficulty")
    }
    
    private func createTextButton(text: String, width: CGFloat, height: CGFloat, position: CGPoint) -> SKShapeNode {
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
        let nodes = self.nodes(at: location)
        
        // Play button sound
        SoundManager.shared.playSound(.buttonTap)
        
        for node in nodes {
            // Handle toggle switches
            if node.name == "toggle" || node.parent?.name == "toggle" {
                let toggle = node.name == "toggle" ? node as! SKShapeNode : node.parent as! SKShapeNode
                toggleSwitch(toggle)
                return
            }
            
            // Handle difficulty selector
            if node.name == "difficultyControl" || node.parent?.name == "difficultyControl" {
                // Convert touch to control's coordinate space
                let difficultyLocation = difficultyControl.convert(location, from: self)
                handleDifficultySelection(at: difficultyLocation)
                return
            }
            
            // Handle reset button
            if node.name == "reset" || node.parent?.name == "reset" {
                resetHighScore()
                return
            }
            
            // Handle back button
            if node.name == "back" || node.parent?.name == "back" {
                returnToMainMenu()
                return
            }
        }
    }
    
    private func toggleSwitch(_ toggle: SKShapeNode) {
        // Get the current state and toggle it
        let isOn = toggle.userData?.value(forKey: "isOn") as? Bool ?? false
        let newState = !isOn
        
        // Update the toggle appearance
        toggle.fillColor = newState ? .systemGreen : .darkGray
        
        // Move the knob
        if let knob = toggle.childNode(withName: "knob") {
            let width: CGFloat = 70
            let knobX: CGFloat = newState ? width/2 - 6 : -width/2 + 6
            let moveAction = SKAction.moveTo(x: knobX, duration: 0.2)
            knob.run(moveAction)
        }
        
        // Store the new state
        toggle.userData?.setValue(newState, forKey: "isOn")
        
        // Update user defaults based on which toggle was changed
        if toggle === musicToggle {
            UserDefaults.standard.set(newState, forKey: "musicEnabled")
            if newState {
                SoundManager.shared.startBackgroundMusic()
            } else {
                SoundManager.shared.stopBackgroundMusic()
            }
        } else if toggle === soundToggle {
            UserDefaults.standard.set(newState, forKey: "soundEnabled")
        }
        
        // Save the changes
        UserDefaults.standard.synchronize()
    }
    
    private func handleDifficultySelection(at location: CGPoint) {
        // Calculate which segment was tapped
        let segmentWidth: CGFloat = 60
        let totalWidth: CGFloat = segmentWidth * 3
        let offsetX = location.x + totalWidth/2
        
        if offsetX < 0 || offsetX > totalWidth {
            return
        }
        
        let segment = Int(offsetX / segmentWidth)
        if segment < 0 || segment > 2 {
            return
        }
        
        // Update the selected segment position
        if let selectedSegment = difficultyControl.childNode(withName: "selectedSegment") as? SKShapeNode {
            let moveAction = SKAction.moveTo(x: -totalWidth/2 + segmentWidth/2 + CGFloat(segment) * segmentWidth, duration: 0.2)
            selectedSegment.run(moveAction)
        }
        
        // Update text colors
        for i in 0...2 {
            if let label = difficultyControl.childNode(withName: "option\(i)") as? SKLabelNode {
                label.fontColor = i == segment ? .black : .white
            }
        }
        
        // Store the new difficulty
        difficultyControl.userData?.setValue(segment, forKey: "difficulty")
        UserDefaults.standard.set(segment, forKey: "difficulty")
        UserDefaults.standard.synchronize()
    }
    
    private func resetHighScore() {
        // Show confirmation
        let confirmation = SKLabelNode(fontNamed: "AvenirNext-Bold")
        confirmation.text = "High Score Reset!"
        confirmation.fontSize = 30
        confirmation.fontColor = .red
        confirmation.position = CGPoint(x: size.width/2, y: size.height/2)
        confirmation.setScale(0)
        addChild(confirmation)
        
        // Animate the confirmation
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        confirmation.run(SKAction.sequence([scaleUp, wait, fadeOut, remove]))
        
        // Reset the high score
        UserDefaults.standard.set(0, forKey: "highScore")
        UserDefaults.standard.synchronize()
    }
    
    private func returnToMainMenu() {
        let transition = SKTransition.moveIn(with: .left, duration: 0.5)
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        self.view?.presentScene(menuScene, transition: transition)
    }
}
