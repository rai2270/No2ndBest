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
        
        // Create a container node for all settings elements for better organization
        let settingsContainer = SKNode()
        settingsContainer.position = CGPoint(x: size.width/2, y: size.height/2)
        settingsContainer.zPosition = 10
        addChild(settingsContainer)
        
        // Calculate header width based on screen size for consistency
        let headerWidth = min(size.width * 0.9, 400) // Cap width for very large screens
        
        // Create Bitcoin-styled header
        let headerBackground = SKShapeNode(rectOf: CGSize(width: headerWidth, height: 70), cornerRadius: 15)
        headerBackground.fillColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.9) // Bitcoin orange
        headerBackground.strokeColor = .white
        headerBackground.lineWidth = 1.5
        headerBackground.position = CGPoint(x: 0, y: size.height * 0.35)
        headerBackground.zPosition = 1
        settingsContainer.addChild(headerBackground)
        
        // Create scene title with Bitcoin symbol
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Settings"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -30, y: size.height * 0.35) // Shift left slightly to make room for symbol
        titleLabel.zPosition = 2
        settingsContainer.addChild(titleLabel)
        
        // Add Bitcoin symbol next to title - with responsive positioning
        let bitcoinSymbol = SKLabelNode(text: "₿")
        bitcoinSymbol.fontName = "AvenirNext-Bold"
        bitcoinSymbol.fontSize = 24
        bitcoinSymbol.fontColor = .white
        bitcoinSymbol.verticalAlignmentMode = .center
        // Position relative to title, not exact points which can vary by device
        bitcoinSymbol.position = CGPoint(x: titleLabel.position.x + titleLabel.frame.width/2 + 40, y: titleLabel.position.y)
        bitcoinSymbol.zPosition = 2
        settingsContainer.addChild(bitcoinSymbol)
        
        // Create settings panel background
        let panelBackground = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: size.height * 0.5), cornerRadius: 20)
        panelBackground.fillColor = UIColor(white: 0.15, alpha: 0.7)  // Dark semi-transparent background
        panelBackground.strokeColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.5) // Bitcoin orange border
        panelBackground.lineWidth = 2
        panelBackground.position = CGPoint(x: 0, y: 0)
        panelBackground.zPosition = 0
        settingsContainer.addChild(panelBackground)
        
        // Adjusted vertical spacing
        let rowHeight: CGFloat = 70
        let startY = panelBackground.frame.height / 2 - rowHeight
        
        // Music toggle - well separated from other controls
        let musicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        addSettingRow(title: "Music", y: startY, enabled: musicEnabled, parent: settingsContainer) { toggle in
            self.musicToggle = toggle
        }
        
        // Sound effects toggle - with proper spacing
        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        addSettingRow(title: "Sound Effects", y: startY - rowHeight, enabled: soundEnabled, parent: settingsContainer) { toggle in
            self.soundToggle = toggle
        }
        
        // Difficulty control - with ample space from other elements
        addDifficultyControl(y: startY - rowHeight * 2, parent: settingsContainer)
        
        // Reset high score button - well separated
        let resetButton = createTextButton(
            text: "Reset High Score", 
            width: size.width * 0.8, 
            height: 50, 
            position: CGPoint(x: 0, y: startY - rowHeight * 3.2),
            bitcoinOrange: true
        )
        resetButton.name = "reset"
        settingsContainer.addChild(resetButton)
        
        // Back button with good spacing
        backButton = createTextButton(
            text: "Back", 
            width: size.width * 0.7, 
            height: 60, 
            position: CGPoint(x: 0, y: -panelBackground.frame.height / 2 - 40),
            bitcoinOrange: false
        )
        backButton.name = "back"
        settingsContainer.addChild(backButton)
    }
    
    private func addSettingRow(title: String, y: CGFloat, enabled: Bool, parent: SKNode, completion: @escaping (SKShapeNode) -> Void) {
        // Create row background for better visual separation
        let rowBackground = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 50), cornerRadius: 10)
        rowBackground.fillColor = UIColor(white: 0.2, alpha: 0.5)
        rowBackground.strokeColor = .clear
        rowBackground.position = CGPoint(x: 0, y: y)
        rowBackground.zPosition = 2
        parent.addChild(rowBackground)
        
        // Create label with improved positioning - left aligned for consistency
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = title
        label.fontSize = 22
        label.fontColor = .white
        // Position on left side with fixed margin for consistency
        label.position = CGPoint(x: -size.width * 0.3, y: y) 
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 3
        parent.addChild(label)
        
        // Create toggle switch with improved positioning - consistently placed at right side
        let toggle = createToggleSwitch(position: CGPoint(x: size.width * 0.22, y: y), isOn: enabled)
        toggle.zPosition = 3
        parent.addChild(toggle)
        completion(toggle)
    }
    
    private func createToggleSwitch(position: CGPoint, isOn: Bool) -> SKShapeNode {
        let width: CGFloat = 60
        let height: CGFloat = 30
        
        let toggle = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height/2)
        toggle.position = position
        toggle.fillColor = isOn ? UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) : .darkGray // Bitcoin orange when on
        toggle.strokeColor = .white
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
    
    private func addDifficultyControl(y: CGFloat, parent: SKNode) {
        // Create row background for the difficulty section with more height for large elements
        let rowBackground = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 60), cornerRadius: 10)
        rowBackground.fillColor = UIColor(white: 0.2, alpha: 0.5)
        rowBackground.strokeColor = .clear
        rowBackground.position = CGPoint(x: 0, y: y)
        rowBackground.zPosition = 2
        parent.addChild(rowBackground)
        
        // Create label with improved position
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "Difficulty"
        label.fontSize = 22
        label.fontColor = .white
        // More leftward position to avoid overlap with the control
        label.position = CGPoint(x: -size.width * 0.3, y: y)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 3
        parent.addChild(label)
        
        // Get current difficulty
        let difficulty = UserDefaults.standard.integer(forKey: "difficulty")
        
        // Create difficulty selector with consistent sizing across devices
        let difficultyOptions = ["Easy", "Medium", "Hard"]
        
        // Calculate sizes relative to screen width for consistency
        let segmentWidth: CGFloat = min(60, size.width / 8)
        let totalWidth: CGFloat = segmentWidth * CGFloat(difficultyOptions.count)
        
        // Create a background with a subtle gradient
        difficultyControl = SKShapeNode(rectOf: CGSize(width: totalWidth, height: 35), cornerRadius: 5)
        // Fixed position relative to the row's center rather than screen width percentage
        difficultyControl.position = CGPoint(x: rowBackground.frame.width * 0.25, y: y)
        difficultyControl.fillColor = UIColor(red: 40/255, green: 40/255, blue: 45/255, alpha: 1.0) // Slightly lighter than darkGray
        difficultyControl.strokeColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.6) // Bitcoin orange border
        difficultyControl.lineWidth = 1.5
        difficultyControl.name = "difficultyControl"
        difficultyControl.zPosition = 3
        
        // Add subtle inner shadow
        let innerShadow = SKShapeNode(rectOf: CGSize(width: totalWidth - 2, height: 33), cornerRadius: 4)
        innerShadow.fillColor = UIColor(red: 30/255, green: 30/255, blue: 35/255, alpha: 0.5)
        innerShadow.strokeColor = .clear
        innerShadow.position = CGPoint(x: 0, y: -1)
        innerShadow.zPosition = 0.5
        difficultyControl.addChild(innerShadow)
        
        parent.addChild(difficultyControl)
        
        // Add selector indicator with Bitcoin orange color and glow effect - sized proportionally
        let selectedSegment = SKShapeNode(rectOf: CGSize(width: segmentWidth - 4, height: 31), cornerRadius: 3)
        selectedSegment.fillColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) // Bitcoin orange
        selectedSegment.strokeColor = .clear
        // Position exactly at the segment location
        let segmentPosition = -totalWidth/2 + segmentWidth/2 + CGFloat(difficulty) * segmentWidth
        selectedSegment.position = CGPoint(x: segmentPosition, y: 0)
        selectedSegment.name = "selectedSegment"
        selectedSegment.zPosition = 1
        
        // Add glow effect to selected segment
        let glow = SKEffectNode()
        glow.shouldEnableEffects = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
        let glowShape = SKShapeNode(rectOf: CGSize(width: segmentWidth - 4, height: 31), cornerRadius: 3)
        glowShape.fillColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 0.5)
        glowShape.strokeColor = .clear
        glow.addChild(glowShape)
        glow.zPosition = 0.5
        selectedSegment.addChild(glow)
        
        difficultyControl.addChild(selectedSegment)
        
        // Add text labels for options with improved contrast - adjusted sizing for consistency
        for (index, option) in difficultyOptions.enumerated() {
            let optionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            optionLabel.text = option
            // Adjust font size based on segment width for proper fit
            let fontSize = min(16, segmentWidth * 0.25) // Scale font size with segment width up to max of 16
            optionLabel.fontSize = fontSize
            
            // Enhanced contrast for the text
            if index == difficulty {
                optionLabel.fontColor = .black // Black text on orange background
                
                // Add a small Bitcoin symbol for the selected option, positioned relative to segment width
                if index == 1 { // Medium difficulty, add Bitcoin symbol
                    let btcSymbol = SKLabelNode(fontNamed: "AvenirNext-Bold")
                    btcSymbol.text = "₿"
                    btcSymbol.fontSize = 12
                    btcSymbol.fontColor = .black
                    // Position symbol relative to segment width rather than fixed pixel values
                    btcSymbol.position = CGPoint(x: optionLabel.position.x + segmentWidth/2, y: -segmentWidth/5)
                    btcSymbol.verticalAlignmentMode = .center
                    btcSymbol.alpha = 0.7
                    btcSymbol.zPosition = 2
                    difficultyControl.addChild(btcSymbol)
                }
            } else {
                optionLabel.fontColor = UIColor(white: 1.0, alpha: 0.9) // Slightly off-white for better contrast
            }
            
            // Ensure labels are perfectly centered within their segments
            let segmentPosition = -totalWidth/2 + segmentWidth/2 + CGFloat(index) * segmentWidth
            optionLabel.position = CGPoint(x: segmentPosition, y: 0)
            optionLabel.verticalAlignmentMode = .center
            optionLabel.horizontalAlignmentMode = .center // Ensure center alignment
            optionLabel.name = "option\(index)"
            optionLabel.zPosition = 2
            difficultyControl.addChild(optionLabel)
        }
        
        // Store the current difficulty
        difficultyControl.userData = NSMutableDictionary()
        difficultyControl.userData?.setValue(difficulty, forKey: "difficulty")
    }
    
    private func createTextButton(text: String, width: CGFloat, height: CGFloat, position: CGPoint, bitcoinOrange: Bool = false) -> SKShapeNode {
        // Create button with improved styling
        let button = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        button.fillColor = UIColor(white: 0.2, alpha: 0.9)
        button.strokeColor = bitcoinOrange ? 
                            UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) : // Bitcoin orange
                            UIColor(red: 0, green: 0.7, blue: 0.9, alpha: 1.0) // Cyan alternative
        button.lineWidth = 2
        button.position = position
        button.zPosition = 3
        
        // Add subtle gradient effect
        let gradient = SKShapeNode(rectOf: CGSize(width: width - 4, height: height - 4), cornerRadius: 10)
        gradient.fillColor = UIColor(white: 0.25, alpha: 0.7)
        gradient.strokeColor = .clear
        gradient.position = CGPoint(x: 0, y: -1) // Slight offset for 3D effect
        gradient.zPosition = -0.1
        button.addChild(gradient)
        
        // Improved label styling
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 0.1
        button.addChild(label)
        
        // Add Bitcoin symbol to reset button if it's the reset high score button
        if text == "Reset High Score" {
            let bitcoinSymbol = SKLabelNode(text: "₿")
            bitcoinSymbol.fontName = "AvenirNext-Bold"
            bitcoinSymbol.fontSize = 18
            bitcoinSymbol.fontColor = UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) // Bitcoin orange
            bitcoinSymbol.position = CGPoint(x: label.position.x - 110, y: 0)
            bitcoinSymbol.verticalAlignmentMode = .center
            bitcoinSymbol.horizontalAlignmentMode = .center
            button.addChild(bitcoinSymbol)
        }
        
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
        
        // Update the toggle appearance with Bitcoin orange
        toggle.fillColor = newState ? UIColor(red: 247/255, green: 147/255, blue: 26/255, alpha: 1.0) : .darkGray
        
        // Move the knob
        if let knob = toggle.childNode(withName: "knob") {
            // Use the actual toggle width from the createToggleSwitch function
            let width: CGFloat = 60
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
        // Calculate which segment was tapped using the actual control size
        let totalWidth: CGFloat = difficultyControl.frame.width
        let segmentWidth: CGFloat = totalWidth / 3 // Three difficulty options
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
