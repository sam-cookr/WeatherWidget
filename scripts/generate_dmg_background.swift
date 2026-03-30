#!/usr/bin/env swift
// Generates dmg_background.png — 1200×800 @2x image for a 600×400 DMG window.
// DMG icon positions: WeatherWidget.app at (175,175), Applications at (425,175)
import AppKit

let pw: CGFloat = 1120
let ph: CGFloat = 620

let image = NSImage(size: NSSize(width: pw, height: ph))
image.lockFocus()

// ── Background ────────────────────────────────────────────────────────────
NSGradient(
    colors: [
        NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1),
        NSColor(red: 0.14, green: 0.14, blue: 0.17, alpha: 1),
    ],
    atLocations: [0, 1],
    colorSpace: .sRGB
)!.draw(in: NSRect(x: 0, y: 0, width: pw, height: ph), angle: 90)

// ── Arrow between icons ───────────────────────────────────────────────────
// Icons at Finder coords (140,155) and (420,155) in a 560×310 window
// Physical @2x image coords: x=280, x=840 — arrow centred at x=560, y≈460 from bottom
let arrowStyle = NSMutableParagraphStyle()
arrowStyle.alignment = .center

NSAttributedString(string: "→", attributes: [
    .font: NSFont.systemFont(ofSize: 72, weight: .thin),
    .foregroundColor: NSColor.white.withAlphaComponent(0.20),
    .paragraphStyle: arrowStyle,
]).draw(in: NSRect(x: 0, y: 250, width: pw, height: 100))

image.unlockFocus()

let tiff = image.tiffRepresentation!
let bmp  = NSBitmapImageRep(data: tiff)!
try! bmp.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "dmg_background.png"))
print("Generated dmg_background.png")
