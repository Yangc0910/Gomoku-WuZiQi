import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

private enum Story: CaseIterable {
    case gameplay
    case skills
    case profiles

    var fileName: String {
        switch self {
        case .gameplay: "01-core-gameplay.png"
        case .skills: "02-skill-mode.png"
        case .profiles: "03-player-profiles.png"
        }
    }

    var headline: String {
        switch self {
        case .gameplay: "本机双人，随时开局"
        case .skills: "九种技能，改变棋局"
        case .profiles: "档案、头像、战绩都在本机"
        }
    }

    var subheadline: String {
        switch self {
        case .gameplay: "经典五子棋与技能模式并行，15x15 棋盘清晰对弈。"
        case .skills: "飞沙走石、乾坤挪移、禁手结界等技能让每一步都有策略。"
        case .profiles: "玩家资料、头像、自动保存、撤销与结算统计完整闭环。"
        }
    }

    var chips: [String] {
        switch self {
        case .gameplay: ["经典对局", "本机双人", "离线可玩"]
        case .skills: ["标准技能", "高阶组合", "回合策略"]
        case .profiles: ["头像档案", "自动保存", "战绩统计"]
        }
    }
}

private struct Palette {
    static let obsidian = NSColor(hex: 0x060811)
    static let midnight = NSColor(hex: 0x101525)
    static let jade = NSColor(hex: 0x0D6B5E)
    static let teal = NSColor(hex: 0x22B8A8)
    static let blue = NSColor(hex: 0x4E8DFF)
    static let violet = NSColor(hex: 0x7567FF)
    static let ember = NSColor(hex: 0xFF6B58)
    static let gold = NSColor(hex: 0xF4C76A)
    static let ivory = NSColor(hex: 0xF6F0E5)
    static let board = NSColor(hex: 0xE9DED0)
    static let boardLine = NSColor(hex: 0x655747)
    static let text = NSColor(hex: 0xF8FBFF)
    static let muted = NSColor(hex: 0xB9C4D6)
    static let panel = NSColor(hex: 0x151B2B)
}

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
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

private func path(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

private func fillGradient(_ rect: CGRect, colors: [NSColor], angle: CGFloat) {
    NSGradient(colors: colors)?.draw(in: path(rect, radius: 0), angle: angle)
}

private func roundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    path(rect, radius: radius).fill()
}

private func strokedRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    color.setStroke()
    let bezier = path(rect, radius: radius)
    bezier.lineWidth = width
    bezier.stroke()
}

private func circle(center: CGPoint, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

private func line(from start: CGPoint, to end: CGPoint, color: NSColor, width: CGFloat) {
    color.setStroke()
    let bezier = NSBezierPath()
    bezier.lineWidth = width
    bezier.lineCapStyle = .round
    bezier.move(to: start)
    bezier.line(to: end)
    bezier.stroke()
}

private func shadow(color: NSColor, blur: CGFloat, offset: CGSize, drawing: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
    drawing()
    NSGraphicsContext.restoreGraphicsState()
}

private func text(
    _ value: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeightMultiple: CGFloat = 1.08
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = lineHeightMultiple

    let descriptor = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded)
    let font = descriptor.flatMap { NSFont(descriptor: $0, size: size) } ?? NSFont.systemFont(ofSize: size, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: value, attributes: attributes).draw(in: rect)
}

private func drawBackground(in rect: CGRect) {
    fillGradient(rect, colors: [Palette.obsidian, Palette.midnight, NSColor(hex: 0x0D2C31)], angle: -48)

    let topRibbon = NSBezierPath()
    topRibbon.move(to: CGPoint(x: -rect.width * 0.14, y: rect.height * 0.05))
    topRibbon.line(to: CGPoint(x: rect.width * 0.98, y: -rect.height * 0.10))
    topRibbon.line(to: CGPoint(x: rect.width * 1.12, y: rect.height * 0.18))
    topRibbon.line(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.34))
    topRibbon.close()
    Palette.teal.withAlphaComponent(0.11).setFill()
    topRibbon.fill()

    let sideRibbon = NSBezierPath()
    sideRibbon.move(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.18))
    sideRibbon.line(to: CGPoint(x: rect.width * 1.12, y: rect.height * 0.06))
    sideRibbon.line(to: CGPoint(x: rect.width * 1.18, y: rect.height * 0.54))
    sideRibbon.line(to: CGPoint(x: rect.width * 0.86, y: rect.height * 0.62))
    sideRibbon.close()
    Palette.blue.withAlphaComponent(0.10).setFill()
    sideRibbon.fill()

    for index in 0..<10 {
        let y = rect.height * 0.18 + CGFloat(index) * rect.height * 0.09
        line(
            from: CGPoint(x: -rect.width * 0.2, y: y),
            to: CGPoint(x: rect.width * 1.15, y: y - rect.height * 0.32),
            color: NSColor.white.withAlphaComponent(0.035),
            width: max(1, rect.width * 0.002)
        )
    }
}

private func drawGomokuBoard(in rect: CGRect, gridCount: Int, accent: NSColor = Palette.gold) {
    shadow(color: .black.withAlphaComponent(0.24), blur: rect.width * 0.05, offset: CGSize(width: 0, height: 16)) {
        roundedRect(rect, radius: rect.width * 0.055, color: Palette.board)
    }
    strokedRoundedRect(rect.insetBy(dx: 5, dy: 5), radius: rect.width * 0.048, color: NSColor.white.withAlphaComponent(0.52), width: max(2, rect.width * 0.008))

    let padding = rect.width * 0.105
    let gridRect = rect.insetBy(dx: padding, dy: padding)
    let step = gridRect.width / CGFloat(gridCount - 1)
    for index in 0..<gridCount {
        let x = gridRect.minX + CGFloat(index) * step
        let y = gridRect.minY + CGFloat(index) * step
        line(from: CGPoint(x: gridRect.minX, y: y), to: CGPoint(x: gridRect.maxX, y: y), color: Palette.boardLine.withAlphaComponent(0.36), width: max(1.5, rect.width * 0.0045))
        line(from: CGPoint(x: x, y: gridRect.minY), to: CGPoint(x: x, y: gridRect.maxY), color: Palette.boardLine.withAlphaComponent(0.36), width: max(1.5, rect.width * 0.0045))
    }

    let movePoints: [(CGFloat, CGFloat, NSColor)] = [
        (2, 3, NSColor(hex: 0x17202C)),
        (3, 3, Palette.ivory),
        (4, 4, NSColor(hex: 0x17202C)),
        (5, 4, Palette.ivory),
        (5, 5, NSColor(hex: 0x17202C)),
        (6, 5, Palette.ivory),
        (6, 6, NSColor(hex: 0x17202C)),
        (7, 6, Palette.ivory),
        (7, 7, NSColor(hex: 0x17202C))
    ]

    let winning = [
        CGPoint(x: gridRect.minX + step * 3, y: gridRect.minY + step * 3),
        CGPoint(x: gridRect.minX + step * 7, y: gridRect.minY + step * 7)
    ]
    line(from: winning[0], to: winning[1], color: accent.withAlphaComponent(0.75), width: rect.width * 0.026)

    for (x, y, color) in movePoints {
        let point = CGPoint(x: gridRect.minX + step * x, y: gridRect.minY + step * y)
        circle(center: CGPoint(x: point.x + rect.width * 0.011, y: point.y + rect.width * 0.014), radius: rect.width * 0.043, color: .black.withAlphaComponent(0.18))
        circle(center: point, radius: rect.width * 0.043, color: color)
        if color == Palette.ivory {
            circle(center: CGPoint(x: point.x - rect.width * 0.014, y: point.y - rect.width * 0.014), radius: rect.width * 0.010, color: .white.withAlphaComponent(0.8))
        } else {
            circle(center: CGPoint(x: point.x - rect.width * 0.012, y: point.y - rect.width * 0.012), radius: rect.width * 0.009, color: .white.withAlphaComponent(0.16))
        }
    }
}

private func drawSkillGlyph(center: CGPoint, radius: CGFloat) {
    circle(center: center, radius: radius, color: Palette.gold.withAlphaComponent(0.22))
    circle(center: center, radius: radius * 0.60, color: Palette.gold)
    circle(center: center, radius: radius * 0.31, color: Palette.obsidian.withAlphaComponent(0.88))
    line(from: CGPoint(x: center.x - radius * 0.78, y: center.y), to: CGPoint(x: center.x + radius * 0.78, y: center.y), color: Palette.gold, width: radius * 0.14)
    line(from: CGPoint(x: center.x, y: center.y - radius * 0.78), to: CGPoint(x: center.x, y: center.y + radius * 0.78), color: Palette.gold, width: radius * 0.14)
}

private func makeAppIcon() -> NSImage {
    render(width: 1024, height: 1024) { rect in
        fillGradient(rect, colors: [NSColor(hex: 0x050711), NSColor(hex: 0x10162A), NSColor(hex: 0x0E403B)], angle: -38)

        let halo = NSBezierPath(ovalIn: CGRect(x: -110, y: 610, width: 1240, height: 520))
        Palette.teal.withAlphaComponent(0.18).setFill()
        halo.fill()

        let boardRect = CGRect(x: 162, y: 170, width: 700, height: 700)
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: boardRect.midX, yBy: boardRect.midY)
        transform.rotate(byDegrees: -7)
        transform.translateX(by: -boardRect.midX, yBy: -boardRect.midY)
        transform.concat()
        drawGomokuBoard(in: boardRect, gridCount: 11)
        NSGraphicsContext.restoreGraphicsState()

        let mark = CGRect(x: 656, y: 178, width: 190, height: 190)
        shadow(color: Palette.gold.withAlphaComponent(0.42), blur: 26, offset: .zero) {
            drawSkillGlyph(center: CGPoint(x: mark.midX, y: mark.midY), radius: 78)
        }
    }
}

private func drawTopBar(in rect: CGRect, title: String, subtitle: String) {
    text(title, in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 42), size: 28, weight: .bold, color: Palette.text)
    text(subtitle, in: CGRect(x: rect.minX, y: rect.minY + 44, width: rect.width, height: 30), size: 17, weight: .medium, color: Palette.muted)
}

private func drawPill(_ value: String, in rect: CGRect, color: NSColor) {
    roundedRect(rect, radius: rect.height / 2, color: color.withAlphaComponent(0.18))
    strokedRoundedRect(rect.insetBy(dx: 1, dy: 1), radius: rect.height / 2 - 1, color: color.withAlphaComponent(0.24), width: 1.5)
    text(value, in: CGRect(x: rect.minX + 12, y: rect.minY + rect.height * 0.24, width: rect.width - 24, height: rect.height * 0.52), size: rect.height * 0.34, weight: .semibold, color: Palette.text, alignment: .center)
}

private func drawGameplayScreen(in rect: CGRect) {
    roundedRect(rect, radius: rect.width * 0.055, color: Palette.obsidian)
    let content = rect.insetBy(dx: rect.width * 0.07, dy: rect.width * 0.08)
    drawTopBar(in: content, title: "经典对局", subtitle: "玩家一行动 · 第 9 手")

    let board = CGRect(x: content.minX, y: content.minY + 112, width: content.width, height: content.width)
    drawGomokuBoard(in: board, gridCount: 13)

    let panelY = board.maxY + 34
    for (index, info) in [("黑棋", "玩家一", Palette.teal), ("白棋", "玩家二", Palette.ember)].enumerated() {
        let panel = CGRect(x: content.minX + CGFloat(index) * (content.width / 2 + 10), y: panelY, width: content.width / 2 - 10, height: 108)
        roundedRect(panel, radius: 24, color: Palette.panel)
        circle(center: CGPoint(x: panel.minX + 38, y: panel.minY + 38), radius: 18, color: info.2)
        text(info.0, in: CGRect(x: panel.minX + 68, y: panel.minY + 22, width: panel.width - 84, height: 26), size: 19, weight: .bold, color: Palette.text)
        text(info.1, in: CGRect(x: panel.minX + 68, y: panel.minY + 54, width: panel.width - 84, height: 24), size: 15, weight: .medium, color: Palette.muted)
    }

    drawPill("撤销上一步", in: CGRect(x: content.minX, y: panelY + 134, width: content.width, height: 56), color: Palette.blue)
}

private func drawSkillCard(_ title: String, subtitle: String, color: NSColor, in rect: CGRect, active: Bool) {
    roundedRect(rect, radius: 22, color: active ? color.withAlphaComponent(0.28) : Palette.panel)
    strokedRoundedRect(rect.insetBy(dx: 1, dy: 1), radius: 21, color: active ? color.withAlphaComponent(0.7) : NSColor.white.withAlphaComponent(0.08), width: 2)
    drawSkillGlyph(center: CGPoint(x: rect.minX + 42, y: rect.minY + 42), radius: 20)
    text(title, in: CGRect(x: rect.minX + 78, y: rect.minY + 22, width: rect.width - 96, height: 27), size: 20, weight: .bold, color: Palette.text)
    text(subtitle, in: CGRect(x: rect.minX + 78, y: rect.minY + 54, width: rect.width - 96, height: 24), size: 14, weight: .medium, color: Palette.muted)
}

private func drawSkillsScreen(in rect: CGRect) {
    roundedRect(rect, radius: rect.width * 0.055, color: Palette.obsidian)
    let content = rect.insetBy(dx: rect.width * 0.07, dy: rect.width * 0.08)
    drawTopBar(in: content, title: "技能五子棋", subtitle: "当前技能 · 飞沙走石")

    let board = CGRect(x: content.minX + content.width * 0.08, y: content.minY + 112, width: content.width * 0.84, height: content.width * 0.84)
    drawGomokuBoard(in: board, gridCount: 11, accent: Palette.ember)

    let marker = CGRect(x: board.maxX - 126, y: board.minY + 86, width: 94, height: 94)
    roundedRect(marker, radius: 28, color: Palette.ember.withAlphaComponent(0.22))
    strokedRoundedRect(marker, radius: 28, color: Palette.ember.withAlphaComponent(0.72), width: 3)
    text("目标", in: CGRect(x: marker.minX, y: marker.minY + 33, width: marker.width, height: 28), size: 20, weight: .heavy, color: Palette.text, alignment: .center)

    let cardY = board.maxY + 34
    drawSkillCard("飞沙走石", subtitle: "移除对方一子", color: Palette.ember, in: CGRect(x: content.minX, y: cardY, width: content.width, height: 88), active: true)
    drawSkillCard("乾坤挪移", subtitle: "移动一颗己方棋子", color: Palette.blue, in: CGRect(x: content.minX, y: cardY + 106, width: content.width, height: 88), active: false)
    drawSkillCard("禁手结界", subtitle: "封锁关键交叉点", color: Palette.violet, in: CGRect(x: content.minX, y: cardY + 212, width: content.width, height: 88), active: false)
}

private func drawProfilesScreen(in rect: CGRect) {
    roundedRect(rect, radius: rect.width * 0.055, color: Palette.obsidian)
    let content = rect.insetBy(dx: rect.width * 0.07, dy: rect.width * 0.08)
    drawTopBar(in: content, title: "玩家档案", subtitle: "头像、本地记录与战绩")

    let cards: [(String, String, NSColor, String)] = [
        ("玩家一", "12 胜 · 3 平", Palette.teal, "68%"),
        ("玩家二", "9 胜 · 3 平", Palette.ember, "55%")
    ]
    for (index, item) in cards.enumerated() {
        let card = CGRect(x: content.minX, y: content.minY + 118 + CGFloat(index) * 176, width: content.width, height: 144)
        roundedRect(card, radius: 28, color: Palette.panel)
        strokedRoundedRect(card.insetBy(dx: 1, dy: 1), radius: 27, color: NSColor.white.withAlphaComponent(0.08), width: 2)
        circle(center: CGPoint(x: card.minX + 66, y: card.minY + 72), radius: 42, color: item.2.withAlphaComponent(0.22))
        circle(center: CGPoint(x: card.minX + 66, y: card.minY + 72), radius: 28, color: item.2)
        text(item.0, in: CGRect(x: card.minX + 128, y: card.minY + 34, width: card.width - 240, height: 32), size: 23, weight: .bold, color: Palette.text)
        text(item.1, in: CGRect(x: card.minX + 128, y: card.minY + 72, width: card.width - 240, height: 28), size: 17, weight: .medium, color: Palette.muted)
        drawPill(item.3, in: CGRect(x: card.maxX - 118, y: card.minY + 48, width: 82, height: 46), color: item.2)
    }

    let summary = CGRect(x: content.minX, y: content.minY + 488, width: content.width, height: 256)
    roundedRect(summary, radius: 30, color: NSColor(hex: 0x182133))
    text("最近对局", in: CGRect(x: summary.minX + 28, y: summary.minY + 30, width: summary.width - 56, height: 32), size: 22, weight: .bold, color: Palette.text)
    for (index, row) in ["玩家一  胜  31 手", "平局  225 手", "玩家二  胜  46 手"].enumerated() {
        let y = summary.minY + 82 + CGFloat(index) * 50
        text(row, in: CGRect(x: summary.minX + 30, y: y, width: summary.width - 60, height: 28), size: 17, weight: .medium, color: index == 0 ? Palette.gold : Palette.muted)
        line(from: CGPoint(x: summary.minX + 30, y: y + 38), to: CGPoint(x: summary.maxX - 30, y: y + 38), color: NSColor.white.withAlphaComponent(0.08), width: 1)
    }

    drawPill("自动保存 · 本机隐私", in: CGRect(x: content.minX, y: summary.maxY + 34, width: content.width, height: 56), color: Palette.teal)
}

private func drawPhoneMockup(story: Story, in rect: CGRect) {
    shadow(color: .black.withAlphaComponent(0.40), blur: 58, offset: CGSize(width: 0, height: 34)) {
        roundedRect(rect, radius: rect.width * 0.13, color: NSColor(hex: 0x05060B))
    }
    strokedRoundedRect(rect.insetBy(dx: 2, dy: 2), radius: rect.width * 0.125, color: NSColor.white.withAlphaComponent(0.12), width: 3)
    let screen = rect.insetBy(dx: rect.width * 0.055, dy: rect.width * 0.075)
    NSGraphicsContext.saveGraphicsState()
    path(screen, radius: rect.width * 0.095).addClip()
    switch story {
    case .gameplay: drawGameplayScreen(in: screen)
    case .skills: drawSkillsScreen(in: screen)
    case .profiles: drawProfilesScreen(in: screen)
    }
    NSGraphicsContext.restoreGraphicsState()
}

private func drawIPadMockup(story: Story, in rect: CGRect) {
    shadow(color: .black.withAlphaComponent(0.36), blur: 66, offset: CGSize(width: 0, height: 34)) {
        roundedRect(rect, radius: rect.width * 0.055, color: NSColor(hex: 0x05060B))
    }
    strokedRoundedRect(rect.insetBy(dx: 2, dy: 2), radius: rect.width * 0.052, color: NSColor.white.withAlphaComponent(0.13), width: 3)
    let screen = rect.insetBy(dx: rect.width * 0.038, dy: rect.width * 0.045)
    roundedRect(screen, radius: rect.width * 0.038, color: Palette.obsidian)

    let sidebar = CGRect(x: screen.minX + 58, y: screen.minY + 70, width: screen.width * 0.23, height: screen.height - 140)
    let board = CGRect(x: sidebar.maxX + 64, y: screen.minY + 178, width: screen.height * 0.63, height: screen.height * 0.63)
    let right = CGRect(x: board.maxX + 64, y: sidebar.minY, width: screen.maxX - board.maxX - 122, height: sidebar.height)

    roundedRect(sidebar, radius: 34, color: Palette.panel)
    roundedRect(right, radius: 34, color: Palette.panel)
    text(story == .skills ? "技能面板" : "玩家状态", in: CGRect(x: sidebar.minX + 32, y: sidebar.minY + 38, width: sidebar.width - 64, height: 40), size: 29, weight: .bold, color: Palette.text)

    let boardTitle = story == .skills ? "高阶技能局" : "经典对局"
    text(boardTitle, in: CGRect(x: board.minX, y: screen.minY + 76, width: board.width, height: 48), size: 36, weight: .bold, color: Palette.text, alignment: .center)
    drawGomokuBoard(in: board, gridCount: 13, accent: story == .skills ? Palette.ember : Palette.gold)

    switch story {
    case .gameplay:
        drawPill("玩家一行动", in: CGRect(x: sidebar.minX + 32, y: sidebar.minY + 110, width: sidebar.width - 64, height: 58), color: Palette.teal)
        drawPill("撤销上一步", in: CGRect(x: right.minX + 34, y: right.minY + 110, width: right.width - 68, height: 58), color: Palette.blue)
        text("自动保存未完成对局，回到首页即可继续。", in: CGRect(x: right.minX + 34, y: right.minY + 206, width: right.width - 68, height: 120), size: 25, weight: .medium, color: Palette.muted)
    case .skills:
        drawSkillCard("飞沙走石", subtitle: "移除对方棋子", color: Palette.ember, in: CGRect(x: sidebar.minX + 28, y: sidebar.minY + 112, width: sidebar.width - 56, height: 96), active: true)
        drawSkillCard("乾坤挪移", subtitle: "移动己方棋子", color: Palette.blue, in: CGRect(x: sidebar.minX + 28, y: sidebar.minY + 226, width: sidebar.width - 56, height: 96), active: false)
        drawSkillCard("禁手结界", subtitle: "锁定关键点位", color: Palette.violet, in: CGRect(x: right.minX + 34, y: right.minY + 112, width: right.width - 68, height: 96), active: false)
        text("开局选择三项技能组合，形成不同攻防节奏。", in: CGRect(x: right.minX + 34, y: right.minY + 242, width: right.width - 68, height: 126), size: 25, weight: .medium, color: Palette.muted)
    case .profiles:
        for (index, name) in ["玩家一", "玩家二", "访客"].enumerated() {
            let y = sidebar.minY + 112 + CGFloat(index) * 86
            circle(center: CGPoint(x: sidebar.minX + 58, y: y + 30), radius: 26, color: index == 1 ? Palette.ember : Palette.teal)
            text(name, in: CGRect(x: sidebar.minX + 98, y: y + 16, width: sidebar.width - 132, height: 30), size: 22, weight: .bold, color: Palette.text)
        }
        text("本地胜负平统计", in: CGRect(x: right.minX + 34, y: right.minY + 108, width: right.width - 68, height: 42), size: 30, weight: .bold, color: Palette.text)
        text("头像、档案与对局记录都只保存在设备上。", in: CGRect(x: right.minX + 34, y: right.minY + 172, width: right.width - 68, height: 110), size: 25, weight: .medium, color: Palette.muted)
        drawPill("未收集数据", in: CGRect(x: right.minX + 34, y: right.minY + 328, width: right.width - 68, height: 62), color: Palette.teal)
    }
}

private func drawFeatureChips(_ chips: [String], in rect: CGRect, baseFont: CGFloat) {
    let gap = rect.width * 0.035
    let width = (rect.width - gap * 2) / 3
    for (index, chip) in chips.enumerated() {
        let chipRect = CGRect(x: rect.minX + CGFloat(index) * (width + gap), y: rect.minY, width: width, height: rect.height)
        roundedRect(chipRect, radius: rect.height * 0.33, color: NSColor.white.withAlphaComponent(0.10))
        strokedRoundedRect(chipRect.insetBy(dx: 1, dy: 1), radius: rect.height * 0.32, color: NSColor.white.withAlphaComponent(0.16), width: 2)
        text(chip, in: CGRect(x: chipRect.minX + 12, y: chipRect.minY + rect.height * 0.31, width: chipRect.width - 24, height: rect.height * 0.38), size: baseFont, weight: .semibold, color: Palette.text, alignment: .center)
    }
}

private func drawIPhoneStoreImage(story: Story, in rect: CGRect) {
    drawBackground(in: rect)
    text("技能五子棋", in: CGRect(x: 86, y: 128, width: rect.width - 172, height: 78), size: 46, weight: .heavy, color: Palette.gold, alignment: .center)
    text(story.headline, in: CGRect(x: 82, y: 220, width: rect.width - 164, height: 146), size: 76, weight: .heavy, color: Palette.text, alignment: .center, lineHeightMultiple: 0.96)
    text(story.subheadline, in: CGRect(x: 128, y: 388, width: rect.width - 256, height: 94), size: 32, weight: .medium, color: Palette.muted, alignment: .center)

    drawPhoneMockup(story: story, in: CGRect(x: rect.midX - 370, y: 566, width: 740, height: 1516))

    drawFeatureChips(story.chips, in: CGRect(x: 98, y: 2200, width: rect.width - 196, height: 88), baseFont: 27)
    text("无账号 · 不联网 · 本机保存", in: CGRect(x: 120, y: 2518, width: rect.width - 240, height: 44), size: 25, weight: .medium, color: Palette.muted, alignment: .center)
}

private func makeIPhoneStoreImage(story: Story, width: Int, height: Int) -> NSImage {
    let baseSize = CGSize(width: 1320, height: 2868)
    return render(width: width, height: height) { rect in
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.scaleX(by: rect.width / baseSize.width, yBy: rect.height / baseSize.height)
        transform.concat()
        drawIPhoneStoreImage(story: story, in: CGRect(origin: .zero, size: baseSize))
        NSGraphicsContext.restoreGraphicsState()
    }
}

private func makeIPadStoreImage(story: Story) -> NSImage {
    render(width: 2064, height: 2752) { rect in
        drawBackground(in: rect)
        text("技能五子棋", in: CGRect(x: 144, y: 126, width: rect.width - 288, height: 82), size: 54, weight: .heavy, color: Palette.gold, alignment: .center)
        text(story.headline, in: CGRect(x: 190, y: 226, width: rect.width - 380, height: 116), size: 88, weight: .heavy, color: Palette.text, alignment: .center)
        text(story.subheadline, in: CGRect(x: 260, y: 372, width: rect.width - 520, height: 62), size: 36, weight: .medium, color: Palette.muted, alignment: .center)
        drawIPadMockup(story: story, in: CGRect(x: 150, y: 554, width: 1764, height: 1278))
        drawFeatureChips(story.chips, in: CGRect(x: 220, y: 2076, width: rect.width - 440, height: 98), baseFont: 32)
        text("适配 iPhone 与 iPad，适合面对面快速开局。", in: CGRect(x: 240, y: 2384, width: rect.width - 480, height: 54), size: 31, weight: .medium, color: Palette.muted, alignment: .center)
    }
}

let outputs: [(NSImage, String)] = [
    (makeAppIcon(), "SkillGomoku/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
    (makeAppIcon(), "AppStoreAssets/app-icon/app-icon-1024.png")
] + Story.allCases.flatMap { story in
    [
        (makeIPhoneStoreImage(story: story, width: 1320, height: 2868), "AppStoreAssets/iphone-6.9/\(story.fileName)"),
        (makeIPhoneStoreImage(story: story, width: 1284, height: 2778), "AppStoreAssets/iphone-6.5/\(story.fileName)"),
        (makeIPadStoreImage(story: story), "AppStoreAssets/ipad-13/\(story.fileName)")
    ]
}

for (image, path) in outputs {
    try savePNG(image, to: path)
    print("Wrote \(path)")
}
