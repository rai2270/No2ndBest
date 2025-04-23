//
//  CryptoCurrency.swift
//  No2ndBest
//
//  Created by TR on 4/23/25.
//

import SpriteKit

// Structure to hold cryptocurrency data
struct CryptoCurrency {
    let symbol: String
    let name: String
    let price: Double
    let priceChangePercentage24h: Double
    let marketCap: Double
    
    // Determines bubble size based on market cap
    var bubbleSize: CGFloat {
        // Normalize market cap to a reasonable size range
        let baseSize: CGFloat = 30
        let maxSize: CGFloat = 80
        let minMarketCap: Double = 1_000_000 // $1M
        let maxMarketCap: Double = 1_000_000_000_000 // $1T
        
        let normalizedSize = baseSize + CGFloat((marketCap - minMarketCap) / (maxMarketCap - minMarketCap)) * (maxSize - baseSize)
        return min(max(normalizedSize, baseSize), maxSize)
    }
    
    // Determines bubble color based on 24h price change
    var bubbleColor: SKColor {
        if priceChangePercentage24h > 5 {
            return .green // Strong positive
        } else if priceChangePercentage24h > 0 {
            return SKColor(red: 0, green: 0.8, blue: 0, alpha: 1.0) // Moderate positive
        } else if priceChangePercentage24h > -5 {
            return SKColor(red: 1.0, green: 0, blue: 0, alpha: 0.8) // Moderate negative
        } else {
            return .red // Strong negative
        }
    }
}
