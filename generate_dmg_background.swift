#!/usr/bin/env swift
// Generates dmg_background.png — 1200×800 @2x image for a 600×400 DMG window.
// DMG icon positions: WeatherWidget.app at (175,195), Applications at (425,195)
// which maps to physical image coords: x=350,850  y=410 from bottom.
import AppKit

let pw: CGFloat = 1200
let ph: CGFloat = 800

let image = NSImage(size: NSSize(width: pw, height: ph))
image.lockFocus()

// ── Background ────────────────────────────────────────────────────────────
NSGradient(
    colors: [
        NSColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1),
        NSColor(red: 0.11, green: 0.12, blue: 0.18, alpha: 1),
    ],
    atLocations: [0, 1],
    colorSpace: .sRGB
)!.draw(in: NSRect(x: 0, y: 0, width: pw, height: ph), angle: 125)

// ── Dot grid ──────────────────────────────────────────────────────────────
NSColor.white.withAlphaComponent(0.035).setFill()
stride(from: CGFloat(0), through: pw, by: 36).forEach { x in
    stride(from: CGFloat(0), through: ph, by: 36).forEach { y in
        NSRect(x: x, y: y, width: 1.5, height: 1.5).fill()
    }
}

// ── Glass card (title area) ───────────────────────────────────────────────
let cardW: CGFloat = 480
let cardH: CGFloat = 110
let cardX: CGFloat = (pw - cardW) / 2
let cardY: CGFloat = 570

let cardPath = NSBezierPath(
    roundedRect: NSRect(x: cardX, y: cardY, width: cardW, height: cardH),
    xRadius: 30, yRadius: 30
)

// Fill
NSColor.white.withAlphaComponent(0.055).setFill()
cardPath.fill()

// Top specular
let clip = NSBezierPath(
    roundedRect: NSRect(x: cardX, y: cardY + cardH * 0.5, width: cardW, height: cardH * 0.5),
    xRadius: 30, yRadius: 30
)
clip.addClip()
NSGradient(
    colors: [NSColor.white.withAlphaComponent(0.13), NSColor.white.withAlphaComponent(0)],
    atLocations: [0, 1],
    colorSpace: .sRGB
)!.draw(in: NSRect(x: cardX, y: cardY, width: cardW, height: cardH), angle: 90)
NSGraphicsContext.current?.cgContext.resetClip()

// Border
NSColor.white.withAlphaComponent(0.18).setStroke()
cardPath.lineWidth = 1.5
cardPath.stroke()

// ── App name ──────────────────────────────────────────────────────────────
let center = { () -> NSMutableParagraphStyle in
    let p = NSMutableParagraphStyle(); p.alignment = .center; return p
}()

NSAttributedString(string: "WeatherWidget", attributes: [
    .font: NSFont.systemFont(ofSize: 54, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.92),
    .paragraphStyle: center,
    .kern: -1.0,
]).draw(in: NSRect(x: cardX, y: cardY + 24, width: cardW, height: 72))

// ── Subtitle ──────────────────────────────────────────────────────────────
NSAttributedString(string: "Lock-Screen Weather for macOS", attributes: [
    .font: NSFont.systemFont(ofSize: 20, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.28),
    .paragraphStyle: center,
]).draw(in: NSRect(x: 0, y: 526, width: pw, height: 36))

// ── Separator ─────────────────────────────────────────────────────────────
NSColor.white.withAlphaComponent(0.07).setFill()
NSRect(x: 120, y: 505, width: pw - 240, height: 1).fill()

// ── Arrow between icons ───────────────────────────────────────────────────
// Icons at physical x=350 (app) and x=850 (Applications), y≈410 from bottom
NSAttributedString(string: "→", attributes: [
    .font: NSFont.systemFont(ofSize: 64, weight: .ultraLight),
    .foregroundColor: NSColor.white.withAlphaComponent(0.15),
    .paragraphStyle: center,
]).draw(in: NSRect(x: 0, y: 365, width: pw, height: 100))

// ── Labels under each icon ────────────────────────────────────────────────
let labelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .medium),
    .foregroundColor: NSColor.white.withAlphaComponent(0.18),
    .paragraphStyle: center,
]
// App icon centre at physical x=350 → span 50..650
NSAttributedString(string: "Drag to install", attributes: labelAttrs)
    .draw(in: NSRect(x: 50, y: 270, width: 600, height: 36))

// Applications centre at physical x=850 → span 550..1150
NSAttributedString(string: "Applications", attributes: labelAttrs)
    .draw(in: NSRect(x: 550, y: 270, width: 600, height: 36))

image.unlockFocus()

let tiff = image.tiffRepresentation!
let bmp  = NSBitmapImageRep(data: tiff)!
try! bmp.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "dmg_background.png"))
print("Generated dmg_background.png")
