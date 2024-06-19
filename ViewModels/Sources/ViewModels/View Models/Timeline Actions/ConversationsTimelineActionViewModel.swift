import Foundation
import ServiceLayer

/// Timeline actions view model for the conversations timeline.
@MainActor
public final class ConversationsTimelineActionViewModel {
    private let conversationsService: ConversationsService

    public init(_ conversationsService: ConversationsService) {
        self.conversationsService = conversationsService
    }

    @Published private(set) public var inProgress: Bool = false
    @Published private(set) public var alertItem: AlertItem?

    public func markAllConversationsAsRead() async {
        do {
            inProgress = true
            try await conversationsService.markAllConversationsAsRead()
            inProgress = false
        } catch {
            alertItem = .init(error: error)
        }
    }
}
