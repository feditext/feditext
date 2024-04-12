// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import Siren
import UIKit

// TODO: (Vyr) rename this class
/// This badly-misnamed class also handles tapped-link highlights and blockquote rendering.
final class TouchFallthroughTextView: UITextView, EmojiInsertable {
    var shouldFallthrough: Bool = true

    private var linkHighlightView: UIView?
    private let blockquotesLayer = CALayer()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        let textStorage = NSTextStorage()
        let layoutManager = AnimatingLayoutManager()
        let presentTextContainer = textContainer ?? NSTextContainer(size: .zero)

        layoutManager.addTextContainer(presentTextContainer)
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: presentTextContainer)

        layoutManager.view = self
        clipsToBounds = false
        textDragInteraction?.isEnabled = false
        isEditable = false
        isScrollEnabled = false
        delaysContentTouches = false
        textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        linkTextAttributes = [.foregroundColor: UIColor.tintColor as Any, .underlineColor: UIColor.clear]

        layer.addSublayer(blockquotesLayer)
        // Don't draw text decorations outside of bounds.
        // Fixes blank areas when posts are folded.
        blockquotesLayer.masksToBounds = true
        // Draw the decorations behind the text.
        blockquotesLayer.zPosition = -1
        updateBlockquotesLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else { return super.point(inside: point, with: event) }

        return shouldFallthrough ? urlAndRect(at: point) != nil : super.point(inside: point, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first,
              let (_, rect) = urlAndRect(at: touch.location(in: self)) else {
            return
        }

        let linkHighlightView = UIView(frame: rect)

        self.linkHighlightView = linkHighlightView
        linkHighlightView.transform = Self.linkHighlightViewTransform
        linkHighlightView.layer.cornerRadius = .defaultCornerRadius
        linkHighlightView.backgroundColor = .secondarySystemBackground
        insertSubview(linkHighlightView, at: 0)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        removeLinkHighlightView()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        removeLinkHighlightView()
    }

    override var selectedTextRange: UITextRange? {
        get { shouldFallthrough ? nil : super.selectedTextRange }
        set {
            if !shouldFallthrough {
                super.selectedTextRange = newValue
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return text.isEmpty ? .zero : super.intrinsicContentSize
    }

    func urlAndRect(at point: CGPoint) -> (URL, CGRect)? {
        guard
            let pos = closestPosition(to: point),
            let range = tokenizer.rangeEnclosingPosition(
                pos, with: .character,
                inDirection: UITextDirection.layout(.left))
            else { return nil }

        let urlAtPointIndex = offset(from: beginningOfDocument, to: range.start)

        guard let url = attributedText.attribute(
                .link, at: offset(from: beginningOfDocument, to: range.start),
                effectiveRange: nil) as? URL
        else { return nil }

        let maxLength = attributedText.length
        var min = urlAtPointIndex
        var max = urlAtPointIndex

        attributedText.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: urlAtPointIndex),
            options: .reverse) { attribute, range, stop in
                if let attributeURL = attribute as? URL, attributeURL == url, min > 0 {
                    min = range.location
                } else {
                    stop.pointee = true
                }
        }

        attributedText.enumerateAttribute(
            .link,
            in: NSRange(location: urlAtPointIndex, length: maxLength - urlAtPointIndex),
            options: []) { attribute, range, stop in
                if let attributeURL = attribute as? URL, attributeURL == url, max < maxLength {
                    max = range.location + range.length
                } else {
                    stop.pointee = true
                }
        }

        var urlRect = CGRect.zero

        layoutManager.enumerateEnclosingRects(
            forGlyphRange: NSRange(location: min, length: max - min),
            withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
            in: textContainer) { rect, _ in
                if urlRect.origin == .zero {
                    urlRect.origin = rect.origin
                }

                urlRect = urlRect.union(rect)
        }

        return (url, urlRect)
    }

    override var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }

        set {
            super.attributedText = newValue
            updateBlockquotesLayer()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBlockquotesLayer()
    }
}

private extension TouchFallthroughTextView {
    static let linkHighlightViewTransform = CGAffineTransform(scaleX: 1.1, y: 1.1)

    func removeLinkHighlightView() {
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.linkHighlightView?.alpha = 0
        } completion: { _ in
            self.linkHighlightView?.removeFromSuperview()
            self.linkHighlightView = nil
        }
    }

    /// Returns a dynamic color that darkens the system background color in light mode and brightens it in dark mode.
    static func backgroundColor(for quoteLevel: Int) -> UIColor {
        return .init { traitCollection in
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            UIColor.systemBackground.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            b += (traitCollection.userInterfaceStyle == .light ? -1.0 : 1.0)
                * CGFloat(quoteLevel) * 0.05
            return .init(hue: h, saturation: s, brightness: b, alpha: a)
        }
    }

    /// Collection of text bounding rectangles for a blockquote.
    struct Blockquote {
        var rects: [CGRect]
    }

    func updateBlockquotesLayer() {
        blockquotesLayer.frame = bounds
        blockquotesLayer.sublayers = nil

        // Indexed by `(level - 1)` since there is no level 0.
        var levelMaps = [[Int: Blockquote]]()

        attributedText.enumerateAttribute(
            .presentationIntentAttributeName,
            in: NSRange(location: 0, length: attributedText.length)
        ) { val, range, _ in
            guard let intent = val as? PresentationIntent else { return }

            // Reversed so we get it in parents to children order.
            let blockquoteComponents = intent.components.filter({ $0.kind == .blockQuote}).reversed()
            guard !blockquoteComponents.isEmpty else { return }

            // Shrink to exclude leading and trailing whitespace.
            guard let stringRange = Range(range, in: attributedText.string) else { return }
            var lower = stringRange.lowerBound
            var upperInclusive = attributedText.string.index(before: stringRange.upperBound)
            while lower <= upperInclusive && attributedText.string[lower].isWhitespace {
                lower = attributedText.string.index(after: lower)
            }
            while lower <= upperInclusive && attributedText.string[upperInclusive].isWhitespace {
                upperInclusive = attributedText.string.index(before: upperInclusive)
            }
            if !(lower <= upperInclusive) { return }
            let range = NSRange(lower...upperInclusive, in: attributedText.string)
            guard
                let start = position(
                    from: beginningOfDocument,
                    offset: range.location
                ),
                let end = position(
                    from: start,
                    offset: range.length
                ),
                let quoteRange = textRange(from: start, to: end)
            else {
                return
            }

            // Create any level maps that are missing.
            while levelMaps.count < blockquoteComponents.count {
                levelMaps.append([Int: Blockquote]())
            }

            // Add blockquote text bounding rectangles to all nested blockquotes containing that text.
            let textRects = selectionRects(for: quoteRange).map(\.rect).filter({ !$0.isEmpty })
            for (levelMapsIndex, component) in blockquoteComponents.enumerated() {
                let id = component.identity
                var blockquote = levelMaps[levelMapsIndex][id] ?? Blockquote(rects: [])
                blockquote.rects.append(contentsOf: textRects)
                levelMaps[levelMapsIndex][id] = blockquote
            }
        }

        // Arrange decorations for higher-level quotes in front.
        for (levelMapsIndex, levelMap) in levelMaps.enumerated() {
            let level = levelMapsIndex + 1

            for (_, blockquote) in levelMap {
                var quoteRect = CGRect.null
                for rect in blockquote.rects {
                    quoteRect = quoteRect.union(rect)
                }
                if quoteRect.isEmpty { continue }

                // Clamp to left and right margins.
                let indentedLeftMargin = CGFloat(level - 1) * NSMutableAttributedString.blockquoteIndent
                quoteRect.origin.x = indentedLeftMargin
                quoteRect.size.width = bounds.size.width - indentedLeftMargin

                // Draw quote background.
                let backgroundLayer = CALayer()
                backgroundLayer.frame = quoteRect
                backgroundLayer.backgroundColor = Self.backgroundColor(for: level).cgColor
                backgroundLayer.zPosition = CGFloat(level)
                blockquotesLayer.addSublayer(backgroundLayer)

                // Draw quote sidebar.
                let sidebarRect = CGRect.init(
                    origin: .init(
                        x: indentedLeftMargin,
                        y: quoteRect.origin.y
                    ),
                    size: .init(
                        width: NSMutableAttributedString.blockquoteIndent / 3,
                        height: quoteRect.height
                    )
                )
                let sidebarLayer = CALayer()
                sidebarLayer.frame = sidebarRect
                sidebarLayer.backgroundColor = UIColor.opaqueSeparator.cgColor
                sidebarLayer.zPosition = CGFloat(level) + 0.1
                blockquotesLayer.addSublayer(sidebarLayer)
            }
        }

        updateHorizontalRuleLayerSiren(.init(levelMaps.count + 1))
    }

    /// Draw horizontal rules in front of blockquotes.
    func updateHorizontalRuleLayerSiren(_ zPosition: CGFloat) {
        attributedText.enumerateAttribute(
            .init(SirenSpecialAttribute.name),
            in: NSRange(location: 0, length: attributedText.length)
        ) { val, range, _ in
            guard
                let special = val as? SirenSpecial,
                special == .thematicBreak,
                let start = position(
                    from: beginningOfDocument,
                    offset: range.location
                ),
                let end = position(
                    from: start,
                    offset: range.length
                ),
                let hrRange = textRange(from: start, to: end)
            else { return }

            let textRects = selectionRects(for: hrRange).map(\.rect)
            var textRect = CGRect.null
            for rect in textRects {
                textRect = textRect.union(rect)
            }

            // Indent if inside an indented block.
            let indentedLeftMargin = attributedText
                .attribute(.presentationIntentAttributeName, at: range.location, effectiveRange: nil)
                .flatMap { $0 as? PresentationIntent }
                .map { CGFloat($0.indentationLevel) * NSMutableAttributedString.blockquoteIndent }
                ?? 0.0
            let availableWidth = bounds.size.width - indentedLeftMargin

            // Mostly arbitrary but looks okay.
            let hrLayer = CALayer()
            hrLayer.frame = .init(
                origin: .init(
                    x: indentedLeftMargin + availableWidth * 0.1,
                    y: textRect.origin.y - NSMutableAttributedString.blockquoteIndent
                ),
                size: .init(
                    width: availableWidth * 0.8,
                    height: NSMutableAttributedString.blockquoteIndent / 6
                )
            )
            hrLayer.backgroundColor = UIColor.opaqueSeparator.cgColor
            hrLayer.zPosition = zPosition
            blockquotesLayer.addSublayer(hrLayer)
        }
    }
}
