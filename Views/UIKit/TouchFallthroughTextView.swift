// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

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
        linkTextAttributes = [.foregroundColor: tintColor as Any, .underlineColor: UIColor.clear]

        layer.addSublayer(blockquotesLayer)
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

    func updateBlockquotesLayer() {
        blockquotesLayer.frame = bounds
        blockquotesLayer.sublayers = nil

        attributedText.enumerateAttribute(
            HTML.Key.quoteLevel,
            in: NSRange(location: 0, length: attributedText.length)
        ) { val, range, _ in
            // Get text range for string range.
            guard
                let quoteLevel = val as? Int,
                quoteLevel > 0,
                let start = position(
                    from: beginningOfDocument,
                    offset: range.location
                ),
                let end = position(
                    from: start,
                    offset: range.length
                ),
                let quoteRange = textRange(from: start, to: end) else {
                return
            }

            // Union all rectangles covering the quote's text.
            var quoteRect = CGRect.null
            for selectionRect in selectionRects(for: quoteRange) {
                quoteRect = quoteRect.union(selectionRect.rect)
            }
            guard quoteRect != .null else {
                return
            }

            // TODO: (Vyr) needs to be generalized for RTL (we already have a Hebrew localization)

            // Clamp to left and right margins.
            quoteRect.origin.x = 0
            quoteRect.size.width = bounds.size.width

            // Draw quote background.
            let backgroundLayer = CALayer()
            backgroundLayer.frame = quoteRect
            backgroundLayer.backgroundColor = Self.backgroundColor(for: quoteLevel).cgColor
            blockquotesLayer.addSublayer(backgroundLayer)

            // Draw quote sidebars.
            for i in 0..<quoteLevel {
                let sidebarRect = CGRect.init(
                    origin: .init(
                        x: CGFloat(i) * NSMutableAttributedString.blockquoteIndent,
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
                blockquotesLayer.addSublayer(sidebarLayer)
            }
        }
    }
}
