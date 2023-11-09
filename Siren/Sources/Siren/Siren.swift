// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import SwiftSoup

/// HTML parser and formatter using SwiftSoup.
/// Intended to replace Feditext's use of WebKit for handling the limited subset of HTML used on Fedi.
public enum Siren {
    static let cleaner = Cleaner(
        headWhitelist: nil,
        // swiftlint:disable:next force_try
        bodyWhitelist: try! .basic()
            .addTags("h1", "h2", "h3", "h4", "h5", "h6")
            .addTags("kbd", "samp", "tt")
            .addTags("s", "ins", "del")
            .addTags("hr")
            .addAttributes("ol", "start", "reversed")
            .addAttributes("li", "value")
            .removeProtocols("a", "href", "ftp", "mailto")
            .addProtocols(
                "a",
                "href",
                "web+ap",
                // From here on down: see https://docs.joinmastodon.org/spec/activitypub/#sanitization
                "dat",
                "dweb",
                "ipfs",
                "ipns",
                "ssb",
                "gopher",
                "xmpp",
                "magnet",
                "gemini"
            )
            .addAttributes("a", "class", "rel", "type")
            .removeEnforcedAttribute("a", "rel")
            .addAttributes("span", "class")
    )

    /// Parse HTML and return an attributed string with Siren attributes.
    public static func parse(_ raw: String) throws -> AttributedString {
        let doc = try Self.cleaner.clean(SwiftSoup.parseBodyFragment(raw))

        guard let body = doc.body() else {
            throw SirenError.missingBody
        }

        let visitor = Visitor()
        try body.traverse(visitor)

        return visitor.attributed
    }
}

public enum SirenError: Error {
    case missingBody
    case nodeType(_ name: String)
    case tag(_ name: String)
    case escapedListItem

    public var localizedDescription: String {
        switch self {
        case .missingBody:
            return "No body element in SwiftSoup output"
        case let .nodeType(name):
            return "Node type not supported: \(name)"
        case let .tag(name):
            return "Tag not supported: \(name)"
        case .escapedListItem:
            return "Requested ordinal for list item outside of list"
        }
    }
}

public extension AttributeScopes {
    var siren: AttributeScopes.SirenAttributes.Type {
        AttributeScopes.SirenAttributes.self
    }
}

public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.SirenAttributes, T>) -> T {
        return self[T.self]
    }
}

public extension AttributeScopes {
    struct SirenAttributes: AttributeScope {
        public let classes: SirenClassesAttribute
        public let styles: SirenStylesAttribute
    }
}

public enum SirenClassesAttribute: CodableAttributedStringKey {
    public static let name = "SirenClasses"
    public typealias Value = SirenClass
}

/// The semantic classes commonly supported by Mastodon and other Fedi servers.
public struct SirenClass: OptionSet, Codable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let mention = SirenClass(rawValue: 1 << 0)
    public static let hashtag = SirenClass(rawValue: 1 << 1)
    public static let ellipsis = SirenClass(rawValue: 1 << 2)
    public static let invisible = SirenClass(rawValue: 1 << 3)

    init?(_ name: String) {
        switch name {
        case "mention":
            self = .mention
        case "hashtag":
            self = .hashtag
        case "ellipsis":
            self = .ellipsis
        case "invisible":
            self = .invisible
        default:
            return nil
        }
    }
}

public enum SirenStylesAttribute: CodableAttributedStringKey {
    public static let name = "SirenStyles"
    public typealias Value = SirenStyle
}

/// Text style with no equivalent among Apple presentation intents.
public struct SirenStyle: OptionSet, Codable, Hashable, CaseIterable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let strikethru = SirenStyle(rawValue: 1 << 0)
    public static let underline = SirenStyle(rawValue: 1 << 1)
    // TODO: (Vyr) small, sub, and sup can be nested
    public static let small = SirenStyle(rawValue: 1 << 2)
    public static let sup = SirenStyle(rawValue: 1 << 3)
    public static let sub = SirenStyle(rawValue: 1 << 4)

    public static var allCases: [SirenStyle] = [
        .strikethru,
        .underline,
        .small,
        .sup,
        .sub
    ]

    init?(_ element: SwiftSoup.Element) {
        switch element.tagNameNormal() {
        case "strike", "s", "del":
            self = .strikethru
        case "u", "ins":
            self = .underline
        case "small":
            self = .small
        case "sup":
            self = .sup
        case "sub":
            self = .sub
        default:
            return nil
        }
    }
}

class Visitor: NodeVisitor {
    var attributed = AttributedString()

    var inlineIntentStack = [InlinePresentationIntent]()
    var stylesStack = [SirenStyle]()
    var linkStack = [URL]()
    var blockID: Int = 1
    var blockIntentStack = [PresentationIntent]()
    var listOrdinalStack = [Int]()
    var classesStack = [SirenClass]()
    var preNestLevel = 0

    func nextBlockID() -> Int {
        let id = blockID
        blockID += 1
        return id
    }

    func beginList() {
        listOrdinalStack.append(1)
    }

    func endList() {
        _ = listOrdinalStack.popLast()
    }

    func nextListOrdinal() throws -> Int {
        if listOrdinalStack.isEmpty {
            throw SirenError.escapedListItem
        }
        let lastIndex = listOrdinalStack.index(before: listOrdinalStack.endIndex)
        let ordinal = listOrdinalStack[lastIndex]
        listOrdinalStack[lastIndex] += 1
        return ordinal
    }

    func insertText(_ string: String) {
        var text = AttributedString(string)

        if let intent = inlineIntentStack.last {
            text.inlinePresentationIntent = intent
        }

        if let styles = stylesStack.last {
            text.styles = styles
        }

        if let link = linkStack.last {
            text.link = link
        }

        if let intent = blockIntentStack.last {
            text.presentationIntent = intent
        }

        if let classes = classesStack.last {
            text.classes = classes
        }

        attributed.append(text)
    }

    func head(_ node: Node, _ depth: Int) throws {
        switch node {
        case let element as Element:
            let name = element.tagNameNormal()
            if name == "body" || name == "span" {
                // Container node, doesn't matter, but may have classes.

            } else if let tag = InlineIntentTag(element) {
                var intent = inlineIntentStack.last ?? []
                intent.insert(tag.intent)
                inlineIntentStack.append(intent)
                if let text = tag.text {
                    insertText(text)
                }

            } else if let style = SirenStyle(element) {
                var styles = stylesStack.last ?? []
                styles.insert(style)
                stylesStack.append(styles)

            } else if name == "a", let href = element.attrUrl("href") {
                linkStack.append(href)

            } else if let tag = BlockIntentTag(element) {
                let kind: PresentationIntent.Kind
                switch tag {
                case .blockQuote:
                    kind = .blockQuote
                case .codeBlock:
                    kind = .codeBlock(languageHint: nil)
                    preNestLevel += 1
                case let .header(level):
                    kind = .header(level: level)
                case .listItem:
                    let ordinal = try nextListOrdinal()
                    kind = .listItem(ordinal: ordinal)
                case .orderedList:
                    kind = .orderedList
                    beginList()
                case .paragraph:
                    kind = .paragraph
                case .thematicBreak:
                    kind = .thematicBreak
                case .unorderedList:
                    kind = .unorderedList
                    beginList()
                }
                let intent = PresentationIntent(kind, identity: nextBlockID(), parent: blockIntentStack.last)
                blockIntentStack.append(intent)

            } else {
                #if DEBUG
                // TODO: (Vyr) which tags are we missing?
                throw SirenError.tag(name)
                #endif
            }

            if let elementClasses = element.sirenClasses() {
                var classes = classesStack.last ?? []
                classes.formUnion(elementClasses)
                classesStack.append(classes)
            }

        case let textNode as TextNode:
            if preNestLevel > 0 {
                insertText(textNode.getWholeText())
            } else {
                insertText(textNode.text())
            }

        default:
            throw SirenError.nodeType(String(describing: type(of: node)))
        }
    }

    func tail(_ node: Node, _ depth: Int) throws {
        switch node {
        case let element as Element:
            let name = element.tagNameNormal()
            if InlineIntentTag(element) != nil {
                _ = inlineIntentStack.popLast()

            } else if SirenStyle(element) != nil {
                _ = stylesStack.popLast()

            } else if name == "a", element.attrUrl("href") != nil {
                _ = linkStack.popLast()

            } else if let tag = BlockIntentTag(element) {
                _ = blockIntentStack.popLast()
                switch tag {
                case .codeBlock:
                    preNestLevel -= 1
                case .orderedList, .unorderedList:
                    endList()
                default:
                    break
                }
            }

            if element.sirenClasses() != nil {
                _ = classesStack.popLast()
            }
        default:
            break
        }
    }
}

/// Tag that maps directly to one of Apple's inline presentation intents.
enum InlineIntentTag {
    case bold
    case italic
    case code
    case lineBreak
    case softBreak

    init?(_ element: Element) {
        switch element.tagNameNormal() {
        case "b", "strong":
            self = .bold
        case "i", "em":
            self = .italic
        case "code", "kbd", "samp", "tt":
            self = .code
        default:
            return nil
        }
    }

    var intent: InlinePresentationIntent {
        switch self {
        case .bold:
            return .stronglyEmphasized
        case .italic:
            return .emphasized
        case .code:
            return .code
        case .lineBreak:
            return .lineBreak
        case .softBreak:
            return .softBreak
        }
    }

    /// Text for self-closing tags, which don't have their own.
    var text: String? {
        switch self {
        case .lineBreak:
            return "\n"
        case .softBreak:
            // ZERO WIDTH SPACE
            return "\u{200b}"
        default:
            return nil
        }
    }
}

// TODO: (Vyr) support list numbering attributes
/// Tag that maps directly to one of Apple's block presentation intents.
enum BlockIntentTag {
    case blockQuote
    case codeBlock
    case header(_ level: Int)
    case listItem
    case orderedList
    case paragraph
    case thematicBreak
    case unorderedList

    init?(_ element: Element) {
        switch element.tagNameNormal() {
        case "blockquote":
            self = .blockQuote
        case "pre":
            self = .codeBlock
        case "h1":
            self = .header(1)
        case "h2":
            self = .header(2)
        case "h3":
            self = .header(3)
        case "h4":
            self = .header(4)
        case "h5":
            self = .header(5)
        case "h6":
            self = .header(6)
        case "li":
            self = .listItem
        case "ol":
            self = .orderedList
        case "p":
            self = .paragraph
        case "hr":
            self = .thematicBreak
        case "ul":
            self = .unorderedList
        default:
            return nil
        }
    }
}

extension Element {
    func attrUrl(_ key: String) -> URL? {
        if let value = try? attr(key),
           let parsed = URL(string: value) {
            return parsed
        }
        return nil
    }

    func attrInt(_ key: String) -> Int? {
        if let value = try? attr(key),
           let parsed = Int(value) {
            return parsed
        }
        return nil
    }

    func sirenClasses() -> SirenClass? {
        if let value = try? attr("class") {
            let classes = SirenClass(
                value
                    .split(whereSeparator: { $0.isWhitespace })
                    .map(String.init)
                    .compactMap(SirenClass.init)
            )
            if classes.isEmpty {
                return nil
            }
            return classes
        }
        return nil
    }
}
