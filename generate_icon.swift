#!/usr/bin/env swift

import Foundation
import AppKit

func createGradient(size: CGSize, color1: NSColor, color2: NSColor) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    
    let gradient = NSGradient(starting: color1, ending: color2)
    gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 90)
    
    image.unlockFocus()
    return image
}

func drawWaveform(in context: CGContext, center: CGPoint, size: CGFloat, color: NSColor) {
    let barWidth = size / 10
    let spacing = size / 12
    
    // 5 vertical bars of varying heights
    let bars: [(CGFloat, CGFloat)] = [
        (center.x - 2 * (barWidth + spacing), 0.5),  // Left
        (center.x - (barWidth + spacing), 0.7),
        (center.x, 1.0),  // Center (tallest)
        (center.x + (barWidth + spacing), 0.7),
        (center.x + 2 * (barWidth + spacing), 0.5),  // Right
    ]
    
    context.setFillColor(color.cgColor)
    
    for (x, heightRatio) in bars {
        let barHeight = size * heightRatio
        let top = center.y - barHeight / 2
        let rect = CGRect(x: x - barWidth / 2, y: top, width: barWidth, height: barHeight)
        let path = NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2)
        context.addPath(path.cgPath)
        context.fillPath()
    }
}

func createAppIcon(size: CGFloat) -> NSImage? {
    // Purple gradient colors
    let color1 = NSColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)
    let color2 = NSColor(red: 167/255, green: 85/255, blue: 255/255, alpha: 1.0)
    
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize)
    
    image.lockFocus()
    
    // Draw gradient background
    let gradient = NSGradient(starting: color1, ending: color2)
    let cornerRadius = size / 5
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: imageSize), 
                           xRadius: cornerRadius, 
                           yRadius: cornerRadius)
    path.addClip()
    gradient?.draw(in: NSRect(origin: .zero, size: imageSize), angle: 90)
    
    // Draw waveform
    if let context = NSGraphicsContext.current?.cgContext {
        let center = CGPoint(x: size / 2, y: size / 2)
        let waveformSize = size / 2
        drawWaveform(in: context, center: center, size: waveformSize, color: .white)
    }
    
    image.unlockFocus()
    return image
}

// Generate the icon
let size: CGFloat = 1024
if let icon = createAppIcon(size: size) {
    if let tiffData = icon.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let outputPath = "VoiceIt/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
        let url = URL(fileURLWithPath: outputPath)
        
        do {
            try pngData.write(to: url)
            print("✅ Created app icon: \(outputPath)")
            print("🎉 App icon generated successfully!")
            print("📱 The icon will appear when you build the app.")
        } catch {
            print("❌ Error writing file: \(error)")
        }
    }
} else {
    print("❌ Failed to create icon")
}

