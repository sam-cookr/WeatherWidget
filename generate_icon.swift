import AppKit
import CoreGraphics

let size = NSSize(width: 512, height: 512)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)

// Background: Rounded rect with gradient
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 40, dy: 40), xRadius: 100, yRadius: 100)
let gradient = NSGradient(starting: NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
                         ending: NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0))
gradient?.draw(in: path, angle: -45)

// Draw a sun
let sunPath = NSBezierPath(ovalIn: NSRect(x: 160, y: 160, width: 192, height: 192))
NSColor.yellow.set()
sunPath.fill()

// Draw a cloud
let cloudPath = NSBezierPath()
cloudPath.move(to: NSPoint(x: 200, y: 180))
cloudPath.appendArc(withCenter: NSPoint(x: 240, y: 180), radius: 60, startAngle: 0, endAngle: 180)
cloudPath.appendArc(withCenter: NSPoint(x: 320, y: 180), radius: 80, startAngle: 0, endAngle: 180)
cloudPath.appendArc(withCenter: NSPoint(x: 380, y: 180), radius: 60, startAngle: 0, endAngle: 180)
cloudPath.close()
NSColor.white.withAlphaComponent(0.9).set()
cloudPath.fill()

image.unlockFocus()

if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) {
    let data = bitmap.representation(using: .png, properties: [:])
    try? data?.write(to: URL(fileURLWithPath: "icon.png"))
}
