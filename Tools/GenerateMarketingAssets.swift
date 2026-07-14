import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

private struct Palette {
    static let ink = NSColor(hex: 0x0D1020)
    static let deepTeal = NSColor(hex: 0x0F6B6A)
    static let cyan = NSColor(hex: 0x3BA7FF)
    static let coral = NSColor(hex: 0xFF6767)
    static let gold = NSColor(hex: 0xF4C96B)
    static let board = NSColor(hex: 0xEEF3F6)
    static let grid = NSColor(hex: 0x375064)
    static let text = NSColor(hex: 0xF7FBFF)
    static let muted = NSColor(hex: 0xB8C7D3)
}

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(
            srgbRed: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

private func render(width: Int, height: Int, drawing: @escaping (CGRect) -> Void) -> NSImage {
    let size = NSSize(width: width, height: height)
    guard let representation = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap representation")
    }
    representation.size = size

    NSGraphicsContext.saveGraphicsState()
    guard let bitmapContext = NSGraphicsContext(bitmapImageRep: representation) else {
        fatalError("Could not create bitmap context")
    }
    let context = NSGraphicsContext(cgContext: bitmapContext.cgContext, flipped: true)
    context.shouldAntialias = true
    context.imageInterpolation = .high
    NSGraphicsContext.current = context

    let rect = CGRect(origin: .zero, size: size)
    NSColor.white.setFill()
    rect.fill()
    drawing(rect)

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: size)
    image.addRepresentation(representation)
    return image
}

private func savePNG(_ image: NSImage, to path: String) throws {
    var proposed = CGRect(origin: .zero, size: image.size)
    guard let source = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
        throw NSError(domain: "MarketingAssets", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create CGImage"])
    }

    let width = source.width
    let height = source.height
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(domain: "MarketingAssets", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create RGB context"])
    }

    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let flattened = context.makeImage() else {
        throw NSError(domain: "MarketingAssets", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not flatten image"])
    }

    let output = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "MarketingAssets", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not create PNG destination"])
    }
    CGImageDestinationAddImage(destination, flattened, nil)
    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "MarketingAssets", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not write \(path)"])
    }
}

private func fillGradient(_ rect: CGRect, colors: [NSColor], angle: CGFloat) {
    NSGradient(colors: colors)?.draw(in: NSBezierPath(rect: rect), angle: angle)
}

private func roundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

private func strokedRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    color.setStroke()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.stroke()
}

private func circle(center: CGPoint, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

private func line(from start: CGPoint, to end: CGPoint, color: NSColor, width: CGFloat) {
    color.setStroke()
    let path = NSBezierPath()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.move(to: start)
    path.line(to: end)
    path.stroke()
}

private func text(
    _ value: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    alignment: NSTextAlignment = .left
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping

    let baseDescriptor = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor
    let descriptor = baseDescriptor.withDesign(.rounded) ?? baseDescriptor
    let font = NSFont(descriptor: descriptor, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: value, attributes: attributes).draw(in: rect)
}

private func drawBoard(in rect: CGRect, gridCount: Int = 9, winningLine: Bool = true) {
    roundedRect(rect, radius: rect.width * 0.075, color: Palette.board)
    strokedRoundedRect(rect.insetBy(dx: 6, dy: 6), radius: rect.width * 0.065, color: NSColor.white.withAlphaComponent(0.55), width: 5)

    let padding = rect.width * 0.12
    let gridRect = rect.insetBy(dx: padding, dy: padding)
    for index in 0..<gridCount {
        let step = gridRect.width / CGFloat(gridCount - 1)
        let x = gridRect.minX + CGFloat(index) * step
        let y = gridRect.minY + CGFloat(index) * step
        line(from: CGPoint(x: gridRect.minX, y: y), to: CGPoint(x: gridRect.maxX, y: y), color: Palette.grid.withAlphaComponent(0.34), width: max(2, rect.width * 0.006))
        line(from: CGPoint(x: x, y: gridRect.minY), to: CGPoint(x: x, y: gridRect.maxY), color: Palette.grid.withAlphaComponent(0.34), width: max(2, rect.width * 0.006))
    }

    let step = gridRect.width / CGFloat(gridCount - 1)
    let points = [
        CGPoint(x: gridRect.minX + step * 2, y: gridRect.minY + step * 2),
        CGPoint(x: gridRect.minX + step * 3, y: gridRect.minY + step * 3),
        CGPoint(x: gridRect.minX + step * 4, y: gridRect.minY + step * 4),
        CGPoint(x: gridRect.minX + step * 5, y: gridRect.minY + step * 5),
        CGPoint(x: gridRect.minX + step * 6, y: gridRect.minY + step * 6)
    ]

    if winningLine {
        line(from: points.first!, to: points.last!, color: Palette.gold.withAlphaComponent(0.72), width: rect.width * 0.034)
    }

    for (index, point) in points.enumerated() {
        let color = index.isMultiple(of: 2) ? Palette.cyan : Palette.coral
        circle(center: point, radius: rect.width * 0.055, color: NSColor.white.withAlphaComponent(0.92))
        circle(center: point, radius: rect.width * 0.044, color: color)
    }
}

private func makeAppIcon() -> NSImage {
    render(width: 1024, height: 1024) { rect in
        fillGradient(rect, colors: [Palette.ink, NSColor(hex: 0x102641), Palette.deepTeal], angle: -42)

        let band = NSBezierPath()
        band.move(to: CGPoint(x: 0, y: 742))
        band.curve(to: CGPoint(x: 1024, y: 520), controlPoint1: CGPoint(x: 320, y: 604), controlPoint2: CGPoint(x: 650, y: 702))
        band.line(to: CGPoint(x: 1024, y: 1024))
        band.line(to: CGPoint(x: 0, y: 1024))
        band.close()
        Palette.cyan.withAlphaComponent(0.22).setFill()
        band.fill()

        let boardRect = CGRect(x: 176, y: 168, width: 672, height: 672)
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: boardRect.midX, yBy: boardRect.midY)
        transform.rotate(byDegrees: -5)
        transform.translateX(by: -boardRect.midX, yBy: -boardRect.midY)
        transform.concat()
        drawBoard(in: boardRect, gridCount: 11)
        NSGraphicsContext.restoreGraphicsState()

        circle(center: CGPoint(x: 746, y: 256), radius: 48, color: Palette.gold)
        circle(center: CGPoint(x: 746, y: 256), radius: 24, color: NSColor.white.withAlphaComponent(0.86))
        line(from: CGPoint(x: 700, y: 256), to: CGPoint(x: 792, y: 256), color: Palette.gold.withAlphaComponent(0.95), width: 12)
        line(from: CGPoint(x: 746, y: 210), to: CGPoint(x: 746, y: 302), color: Palette.gold.withAlphaComponent(0.95), width: 12)
    }
}

private func drawPhoneMockup(in rect: CGRect) {
    roundedRect(rect, radius: rect.width * 0.11, color: NSColor(hex: 0x090B12))
    let screen = rect.insetBy(dx: rect.width * 0.055, dy: rect.width * 0.07)
    roundedRect(screen, radius: rect.width * 0.085, color: Palette.ink)

    let content = screen.insetBy(dx: 34, dy: 44)
    text("技能五子棋", in: CGRect(x: content.minX, y: content.minY, width: content.width, height: 72), size: 48, weight: .bold, color: Palette.text)
    text("经典模式", in: CGRect(x: content.minX, y: content.minY + 80, width: content.width, height: 38), size: 24, weight: .medium, color: Palette.muted)

    drawBoard(in: CGRect(x: content.minX + 18, y: content.minY + 164, width: content.width - 36, height: content.width - 36), gridCount: 9)

    let buttonY = content.minY + content.width + 198
    for (index, label) in ["开始游戏", "玩家档案", "设置"].enumerated() {
        let y = buttonY + CGFloat(index) * 92
        let color = index == 0 ? Palette.cyan : (index == 1 ? NSColor(hex: 0x7C66FF) : NSColor(hex: 0x222B3E))
        roundedRect(CGRect(x: content.minX, y: y, width: content.width, height: 66), radius: 22, color: color)
        text(label, in: CGRect(x: content.minX, y: y + 17, width: content.width, height: 32), size: 25, weight: .semibold, color: Palette.text, alignment: .center)
    }
}

private func drawIPadMockup(in rect: CGRect) {
    roundedRect(rect, radius: rect.width * 0.055, color: NSColor(hex: 0x090B12))
    let screen = rect.insetBy(dx: rect.width * 0.04, dy: rect.width * 0.045)
    roundedRect(screen, radius: rect.width * 0.038, color: Palette.ink)

    let left = CGRect(x: screen.minX + 72, y: screen.minY + 96, width: 340, height: screen.height - 192)
    let board = CGRect(x: left.maxX + 62, y: screen.minY + 188, width: 740, height: 740)
    let right = CGRect(x: board.maxX + 62, y: left.minY, width: 340, height: left.height)

    for (panel, name, color) in [(left, "玩家一", Palette.cyan), (right, "玩家二", Palette.coral)] {
        roundedRect(panel, radius: 30, color: NSColor(hex: 0x1B2433))
        circle(center: CGPoint(x: panel.minX + 92, y: panel.minY + 92), radius: 48, color: color.withAlphaComponent(0.32))
        circle(center: CGPoint(x: panel.minX + 92, y: panel.minY + 92), radius: 28, color: color)
        text(name, in: CGRect(x: panel.minX + 42, y: panel.minY + 166, width: panel.width - 84, height: 42), size: 34, weight: .bold, color: Palette.text)
        text(panel == left ? "先手 · 3 子" : "后手 · 2 子", in: CGRect(x: panel.minX + 42, y: panel.minY + 218, width: panel.width - 84, height: 34), size: 22, weight: .medium, color: Palette.muted)
    }

    text("玩家一 行动", in: CGRect(x: board.minX, y: screen.minY + 96, width: board.width, height: 48), size: 34, weight: .bold, color: Palette.text, alignment: .center)
    drawBoard(in: board, gridCount: 11)
}

private func drawIPhoneStoreImage(in rect: CGRect) {
        fillGradient(rect, colors: [Palette.ink, NSColor(hex: 0x12233B), NSColor(hex: 0x103A3B)], angle: -55)
        text("技能五子棋", in: CGRect(x: 92, y: 170, width: 1136, height: 118), size: 82, weight: .heavy, color: Palette.text, alignment: .center)
        text("本机双人对弈，经典与技能模式。", in: CGRect(x: 124, y: 292, width: 1072, height: 58), size: 34, weight: .medium, color: Palette.muted, alignment: .center)
        drawPhoneMockup(in: CGRect(x: 280, y: 468, width: 760, height: 1570))

        let chipY: CGFloat = 2200
        for (index, label) in ["技能卡牌", "自动保存", "胜负统计"].enumerated() {
            let x = 112 + CGFloat(index) * 384
            roundedRect(CGRect(x: x, y: chipY, width: 328, height: 86), radius: 28, color: NSColor.white.withAlphaComponent(0.11))
            strokedRoundedRect(CGRect(x: x, y: chipY, width: 328, height: 86), radius: 28, color: NSColor.white.withAlphaComponent(0.16), width: 2)
            text(label, in: CGRect(x: x, y: chipY + 24, width: 328, height: 36), size: 28, weight: .semibold, color: Palette.text, alignment: .center)
        }

        text("离线、本机、无账号", in: CGRect(x: 96, y: 2590, width: 1128, height: 42), size: 24, weight: .medium, color: Palette.muted, alignment: .center)
}

private func makeIPhoneStoreImage(width: Int, height: Int) -> NSImage {
    let baseSize = CGSize(width: 1320, height: 2868)
    return render(width: width, height: height) { rect in
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.scaleX(by: rect.width / baseSize.width, yBy: rect.height / baseSize.height)
        transform.concat()
        drawIPhoneStoreImage(in: CGRect(origin: .zero, size: baseSize))
        NSGraphicsContext.restoreGraphicsState()
    }
}

private func makeIPadStoreImage() -> NSImage {
    render(width: 2064, height: 2752) { rect in
        fillGradient(rect, colors: [Palette.ink, NSColor(hex: 0x152440), NSColor(hex: 0x123A34)], angle: -45)
        text("技能五子棋", in: CGRect(x: 132, y: 150, width: 1800, height: 128), size: 92, weight: .heavy, color: Palette.text, alignment: .center)
        text("iPad 三栏棋局视图，玩家、棋盘和回合状态一眼清楚。", in: CGRect(x: 190, y: 288, width: 1684, height: 58), size: 36, weight: .medium, color: Palette.muted, alignment: .center)
        drawIPadMockup(in: CGRect(x: 156, y: 500, width: 1752, height: 1314))

        for (index, label) in ["经典对局", "撤销一步", "结算统计"].enumerated() {
            let x = 222 + CGFloat(index) * 560
            roundedRect(CGRect(x: x, y: 2054, width: 496, height: 96), radius: 30, color: NSColor.white.withAlphaComponent(0.11))
            strokedRoundedRect(CGRect(x: x, y: 2054, width: 496, height: 96), radius: 30, color: NSColor.white.withAlphaComponent(0.16), width: 2)
            text(label, in: CGRect(x: x, y: 2082, width: 496, height: 40), size: 31, weight: .semibold, color: Palette.text, alignment: .center)
        }
    }
}

let outputs: [(NSImage, String)] = [
    (makeAppIcon(), "SkillGomoku/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
    (makeIPhoneStoreImage(width: 1320, height: 2868), "AppStoreAssets/iphone-6.9/01-classic-match.png"),
    (makeIPhoneStoreImage(width: 1284, height: 2778), "AppStoreAssets/iphone-6.5/01-classic-match.png"),
    (makeIPadStoreImage(), "AppStoreAssets/ipad-13/01-classic-match.png")
]

for (image, path) in outputs {
    try savePNG(image, to: path)
    print("Wrote \(path)")
}
