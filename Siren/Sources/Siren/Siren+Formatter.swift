// Copyright © 2023 Vyr Cossont. All rights reserved.

import CoreText
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

public extension Siren {
    /// Given an attributed string with Foundation and Siren attributes,
    /// convert them to AppKit/UIKit attributes for display,
    /// using the provided font descriptor.
    static func format(_ attributed: AttributedString, descriptor: CTFontDescriptor, baseIndent: CGFloat) -> AttributedString {
        var attributed = attributed

        var baseFontSize: CGFloat
        if let baseFontSizeNumber = CTFontDescriptorCopyAttribute(descriptor, kCTFontSizeAttribute) as? NSNumber {
            baseFontSize = .init(truncating: baseFontSizeNumber)
        } else {
            baseFontSize = 0
        }

        for run in attributed.runs {
            var fontSize = baseFontSize
            var baselineOffset: CGFloat = 0

            // Embiggen font if this run is inside a header.
            if let headerLevel = run.presentationIntent?.components.lazy.compactMap({ component in
                switch component.kind {
                case let .header(level):
                    return level
                default:
                    return nil
                }
            }).first {
                fontSize *= 1.0 + CGFloat(7 - headerLevel) / 10.0
            }

            // Handle strikethru, underline, and text size/baseline changes other than headers.
            if let styles = run.styles {
                if styles.contains(.strikethru) {
                    #if canImport(UIKit)
                    attributed[run.range].uiKit.strikethroughStyle = .single
                    #elseif canImport(AppKit)
                    attributed[run.range].appKit.strikethroughStyle = .single
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.strikethroughStyle = .single
                    #endif
                }
                if styles.contains(.underline) {
                    #if canImport(UIKit)
                    attributed[run.range].uiKit.underlineStyle = .single
                    #elseif canImport(AppKit)
                    attributed[run.range].appKit.underlineStyle = .single
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.underlineStyle = .single
                    #endif
                }
                // TODO: (Vyr) we should support several levels of nesting (say, 3),
                //  but not arbitrary nesting, because that'd allow hidden text.
                if styles.contains(.sup) {
                    baselineOffset += fontSize * 0.4
                    fontSize *= 0.8
                }
                if styles.contains(.sub) {
                    baselineOffset -= fontSize * 0.4
                    fontSize *= 0.8
                }
                if styles.contains(.small) {
                    fontSize *= 0.8
                }
            }

            if baselineOffset != 0 {
                #if canImport(UIKit)
                attributed[run.range].uiKit.baselineOffset = baselineOffset
                #elseif canImport(AppKit)
                attributed[run.range].appKit.baselineOffset = baselineOffset
                #endif
                #if canImport(SwiftUI)
                attributed[run.range].swiftUI.baselineOffset = baselineOffset
                #endif
            }

            // Handle bold, italic, and monospace.
            let runDescriptor = CTFontDescriptorCreateCopyWithAttributes(
                descriptor,
                [kCTFontSizeAttribute: fontSize as NSNumber] as CFDictionary
            )
            if let intent = run.inlinePresentationIntent {
                var traits: CTFontSymbolicTraits = []
                if intent.contains(.stronglyEmphasized) {
                    traits.insert(.traitBold)
                }
                if intent.contains(.emphasized) {
                    traits.insert(.traitItalic)
                }
                if intent.contains(.code) {
                    traits.insert(.traitMonoSpace)
                }
                if let runDescriptorWithTraits = CTFontDescriptorCreateCopyWithSymbolicTraits(
                    runDescriptor,
                    traits,
                    []
                ) {
                    let font = CTFontCreateWithFontDescriptor(runDescriptorWithTraits, 0, nil)
                    #if canImport(UIKit)
                    attributed[run.range].uiKit.font = font
                    #elseif canImport(AppKit)
                    attributed[run.range].appKit.font = font
                    #endif
                    #if canImport(SwiftUI)
                    attributed[run.range].swiftUI.font = .init(font)
                    #endif
                }
            } else {
                let font = CTFontCreateWithFontDescriptor(runDescriptor, 0, nil)
                // Ensure that every run has a font.
                #if canImport(UIKit)
                attributed[run.range].uiKit.font = font
                #elseif canImport(AppKit)
                attributed[run.range].appKit.font = font
                #endif
                #if canImport(SwiftUI)
                attributed[run.range].swiftUI.font = .init(font)
                #endif
            }
        }

        var insertions = [(AttributedString, at: AttributedString.Index)]()

        for (intent, range) in attributed.runs[\.presentationIntent] {
            if let intent = intent {
                let indent = CGFloat(intent.indentationLevel) * baseIndent

                #if canImport(AppKit) || canImport(UIKit)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.setParagraphStyle(.default)
                paragraphStyle.firstLineHeadIndent = indent
                paragraphStyle.headIndent = indent
                // Start tabs at the beginning of the indent, not the leading margin.
                paragraphStyle.tabStops = [.init(textAlignment: .natural, location: indent)]
                paragraphStyle.defaultTabInterval = baseIndent
                #endif

                var listType: ListType?
                var listDecoration: String?
                var newlines: String?
                // Order: parents to children.
                for component in intent.components.reversed() {
                    switch component.kind {
                    case .paragraph, .blockQuote, .header:
                        newlines = "\n\n"
                    case .codeBlock:
                        newlines = "\n"
                    case .orderedList:
                        listType = .ordered
                    case .unorderedList:
                        listType = .unordered
                    case let .listItem(ordinal):
                        // If we're not inside a list, just skip this.
                        // The sanitizer may or may not correct that kind of malformed HTML.
                        guard let listType = listType else { continue }

                        switch listType {
                        case .ordered:
                            listDecoration = "\(ordinal). \t"
                        case .unordered:
                            listDecoration = "• \t"
                        }
                        newlines = "\n"
                    default:
                        continue
                    }
                }

                // Used to apply paragraph style to text decorations, not the main text.
                var decorationStyleContainer = AttributeContainer()

                #if canImport(UIKit) || canImport(AppKit)
                if listDecoration != nil {
                    paragraphStyle.firstLineHeadIndent -= baseIndent
                    paragraphStyle.headIndent += baseIndent
                }

                attributed[range].paragraphStyle = paragraphStyle
                decorationStyleContainer.paragraphStyle = paragraphStyle
                #endif

                if let listDecoration = listDecoration {
                    insertions.append((
                        AttributedString(listDecoration, attributes: decorationStyleContainer),
                        at: range.lowerBound
                    ))
                }
                if let newlines = newlines {
                    insertions.append((
                        AttributedString(newlines, attributes: decorationStyleContainer),
                        at: range.upperBound
                    ))
                }
            } else {
                // Ensure that every run has a paragraph style.
                #if canImport(UIKit)
                attributed[range].uiKit.paragraphStyle = .default
                #elseif canImport(AppKit)
                attributed[range].appKit.paragraphStyle = .default
                #endif
            }
        }

        for (attrStr, index) in insertions.reversed() {
            attributed.insert(attrStr, at: index)
        }

        return attributed
    }

    private enum ListType {
        case ordered
        case unordered
    }

    #if canImport(UIKit)
    static func format(
        _ attributed: AttributedString,
        textStyle: UIFont.TextStyle, baseIndent: CGFloat) -> AttributedString {
        format(
            attributed,
            descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle),
            baseIndent: baseIndent
        )
    }

    #if canImport(SwiftUI)
    static func format(
        _ attributed: AttributedString,
        textStyle: SwiftUI.Font.TextStyle,
        baseIndent: CGFloat
    ) -> AttributedString {
        format(
            attributed,
            descriptor: textStyle.descriptor,
            baseIndent: baseIndent
        )
    }
    #endif
    #elseif canImport(AppKit)
    static func format(
        _ attributed: AttributedString,
        textStyle: NSFont.TextStyle,
        baseIndent: CGFloat
    ) -> AttributedString {
        format(
            attributed,
            descriptor: NSFontDescriptor.preferredFontDescriptor(forTextStyle: textStyle),
            baseIndent: baseIndent
        )
    }

    #if canImport(SwiftUI)
    static func format(
        _ attributed: AttributedString,
        textStyle: SwiftUI.Font.TextStyle,
        baseIndent: CGFloat
    ) -> AttributedString {
        format(
            attributed,
            descriptor: textStyle.descriptor,
            baseIndent: baseIndent
        )
    }
    #endif
    #endif
}

#if canImport(SwiftUI)
#if canImport(UIKit)
extension SwiftUI.Font.TextStyle {
    var descriptor: CTFontDescriptor {
        let textStyle: UIFont.TextStyle
        switch self {
        case .largeTitle:
            textStyle = .largeTitle
        case .title:
            textStyle = .title1
        case .title2:
            textStyle = .title2
        case .title3:
            textStyle = .title3
        case .headline:
            textStyle = .headline
        case .subheadline:
            textStyle = .subheadline
        case .body:
            textStyle = .body
        case .callout:
            textStyle = .callout
        case .footnote:
            textStyle = .footnote
        case .caption:
            textStyle = .caption1
        case .caption2:
            textStyle = .caption2
        @unknown default:
            #if DEBUG
            fatalError("Unknown SwiftUI.Font.TextStyle: \(self)")
            #else
            return UIFont.systemFont(ofSize: 0).fontDescriptor
            #endif
        }
        return UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    }
}
#endif
#elseif canImport(AppKit)
extension SwiftUI.Font.TextStyle {
    var descriptor: CTFontDescriptor {
        let textStyle: NSFont.TextStyle
        switch self {
        case .largeTitle:
            textStyle = .largeTitle
        case .title:
            textStyle = .title1
        case .title2:
            textStyle = .title2
        case .title3:
            textStyle = .title3
        case .headline:
            textStyle = .headline
        case .subheadline:
            textStyle = .subheadline
        case .body:
            textStyle = .body
        case .callout:
            textStyle = .callout
        case .footnote:
            textStyle = .footnote
        case .caption:
            textStyle = .caption1
        case .caption2:
            textStyle = .caption2
        @unknown default:
            #if DEBUG
            fatalError("Unknown SwiftUI.Font.TextStyle: \(self)")
            #else
            return NSFont.systemFont(ofSize: 0).fontDescriptor
            #endif
        }
        return NSFontDescriptor.preferredFontDescriptor(forTextStyle: textStyle)
    }
}
#endif

#if canImport(UIKit) || canImport(AppKit)
// Conform `NSParagraphStyle` to `Sendable` so we can assign it to `.paragraphStyle` without compiler warnings.
// source: trust me bro
extension NSParagraphStyle: @unchecked Sendable {}
#endif
