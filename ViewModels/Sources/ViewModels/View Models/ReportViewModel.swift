// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public final class ReportViewModel: CollectionItemsViewModel {
    @Published public var elements: ReportElements
    @Published public private(set) var reportingState = ReportingState.composing
    @Published public private(set) var rules: [Rule] = []
    @Published public private(set) var categories: [Report.Category] = []
    @Published public private(set) var canSubmit = false

    private let accountService: AccountService
    private var cancellables = Set<AnyCancellable>()

    public init(accountService: AccountService, statusId: Status.Id? = nil, identityContext: IdentityContext) {
        self.accountService = accountService
        self.elements = ReportElements(accountId: accountService.account.id)

        super.init(
            collectionService: identityContext.service.navigationService.timelineService(
                timeline: .profile(
                    accountId: accountService.account.id,
                    profileCollection: .statusesAndBoosts
                )
            ),
            identityContext: identityContext
        )

        identityContext.service
            .rulesPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$rules)

        $rules
            .map { rules in
                Report.Category
                    .allCasesExceptUnknown
                    // Show only categories that the instance supports.
                    .filter(self.canUseCategory)
                    // Hide the rules violation category if the instance doesn't have any rules.
                    .filter { $0 != .violation || !rules.isEmpty }
            }
            .assign(to: &$categories)

        $categories
            .sink(receiveValue: { [weak self] categories in
                guard let self = self else { return }
                if categories.count == 1, let singleCategory = categories.first {
                    // If there's only one category, it should be pre-selected.
                    self.elements.category = singleCategory
                } else {
                    // Otherwise, changing the categories should de-select any current selection.
                    self.elements.category = nil
                }
            })
            .store(in: &cancellables)

        $elements.combineLatest($categories)
            .map { elements, categories in
                if elements.category == .violation {
                    // If reporting a rule violation, the user must pick at least one rule.
                    return !elements.ruleIDs.isEmpty
                }
                // The user must have picked a category unless the instance doesn't support them.
                return elements.category != nil || categories.isEmpty
            }
            .assign(to: &$canSubmit)

        identityContext.service
            .refreshRules()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)

        if let statusId = statusId {
            elements.statusIds.insert(statusId)
        }
    }

    public override func viewModel(indexPath: IndexPath) -> Any {
        let viewModel = super.viewModel(indexPath: indexPath)

        if let statusViewModel = viewModel as? StatusViewModel {
            statusViewModel.showReportSelectionToggle = true
            statusViewModel.selectedForReport = elements.statusIds.contains(statusViewModel.id)
        }

        return viewModel as Any
    }

    private func canUseCategory(_ category: Report.Category) -> Bool {
        var elements = ReportElements(accountId: "")
        elements.category = category
        return ReportEndpoint.create(elements).canCallWith(identityContext.apiCapabilities)
    }
}

public extension ReportViewModel {
    enum ReportingState {
        case composing
        case reporting
        case done
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var accountHost: String {
        URL(string: accountService.account.url)?.host ?? ""
    }

    var isLocalAccount: Bool { accountService.isLocal }

    func report() {
        accountService.report(elements)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.reportingState = .reporting })
            .sink { [weak self] in
                guard let self = self else { return }

                switch $0 {
                case .finished:
                    self.reportingState = .done
                case let .failure(error):
                    self.alertItem = AlertItem(error: error)
                    self.reportingState = .composing
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
