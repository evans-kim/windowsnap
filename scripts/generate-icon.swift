import AppKit

// Geometric artwork stays editable and renders identically at every icon size.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let folder = root.appendingPathComponent(".build/WindowSnap.iconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: radius, yRadius: radius).fill()
}
func render(_ size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = AffineTransform(scale: CGFloat(size) / 1024)
    (transform as NSAffineTransform).concat()
    let bg = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 202, yRadius: 202)
    NSGradient(starting: color(43, 192, 180), ending: color(10, 95, 102))!.draw(in: bg, angle: -65)
    rect(183, 231, 658, 548, 72, color(2, 53, 64, 0.25))
    rect(183, 253, 658, 548, 72, color(238, 255, 250))
    rect(213, 283, 598, 428, 42, color(13, 82, 91))
    rect(237, 307, 268, 380, 25, color(126, 232, 200))
    rect(529, 307, 258, 380, 25, color(29, 109, 117))
    for x: CGFloat in [238, 274, 310] {
        color(35, 125, 129, 0.45).setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: 747, width: 18, height: 18)).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 2 ? "@2x" : ""
        try render(points * scale).write(to: folder.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
try render(1024).write(to: root.appendingPathComponent("Resources/AppIcon.png"))
