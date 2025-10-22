// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import SwiftUI
import UIKit
import ViewModels

final class TimelinesViewController: UIPageViewController {
    private let segmentedControl = UISegmentedControl()
    private let timelineViewModels: [CollectionItemsViewModel]
    private let timelineViewControllers: [TableViewController]
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NavigationViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        var timelineViewModels = [CollectionItemsViewModel]()
        var timelineViewControllers = [TableViewController]()

        for (index, timeline) in viewModel.timelines.enumerated() {
            let viewModel = viewModel.viewModel(timeline: timeline)
            timelineViewModels.append(viewModel)
            timelineViewControllers.append(
                TableViewController(
                    viewModel: viewModel,
                    rootViewModel: rootViewModel
                )
            )
            segmentedControl.insertSegment(withTitle: timeline.title, at: index, animated: false)
        }

        self.timelineViewModels = timelineViewModels
        self.timelineViewControllers = timelineViewControllers

        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [.interPageSpacing: CGFloat.defaultSpacing])

        if let timelineActionViewModel = timelineViewModels.first?.timelineActionViewModel {
            self.setupTimelineActionBarButtonItem(timelineActionViewModel)
        }
        if let firstViewController = timelineViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: false)
        }

        tabBarItem = UITabBarItem(
            title: NSLocalizedString("main-navigation.timelines", comment: ""),
            image: UIImage(systemName: "newspaper"),
            selectedImage: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        navigationItem.titleView = segmentedControl
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addAction(
            UIAction { [weak self] _ in
                guard let self = self else { return }

                self.presentedViewController?.dismiss(animated: false)

                guard let currentViewController = self.viewControllers?.first as? TableViewController,
                      let currentIndex = self.timelineViewControllers.firstIndex(of: currentViewController),
                      self.segmentedControl.selectedSegmentIndex != currentIndex
                else { return }

                let index = self.segmentedControl.selectedSegmentIndex
                let timelineViewModel = self.timelineViewModels[index]
                let timelineViewController = self.timelineViewControllers[index]

                self.setViewControllers(
                    [timelineViewController],
                    direction: self.segmentedControl.selectedSegmentIndex > currentIndex ? .forward : .reverse,
                    animated: !UIAccessibility.isReduceMotionEnabled
                )

                if let timelineActionViewModel = timelineViewModel.timelineActionViewModel {
                    self.setupTimelineActionBarButtonItem(timelineActionViewModel)
                }
            },
            for: .valueChanged)
    }

    private func setupTimelineActionBarButtonItem(_ timelineActionViewModel: TimelineActionViewModel) {
        // Other cases are handled in TableViewController.
        guard case let .displayFilter(displayFilterTimelineActionViewModel) = timelineActionViewModel else { return }

        displayFilterTimelineActionViewModel.$filtering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filtering in
                self?.navigationItem.rightBarButtonItem = .init(
                    title: NSLocalizedString(
                        "timelines.display-filter.edit",
                        comment: ""
                    ),
                    image: UIImage(
                        systemName: filtering
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                    ),
                    primaryAction: .init { [weak self, weak displayFilterTimelineActionViewModel] _ in
                        guard let self = self else { return }

                        self.presentedViewController?.dismiss(animated: true)

                        guard let displayFilterTimelineActionViewModel = displayFilterTimelineActionViewModel
                        else { return }

                        let hostingController = UIHostingController(
                            rootView: EditDisplayFilterView(viewModel: displayFilterTimelineActionViewModel)
                        )

                        hostingController.modalPresentationStyle = .pageSheet
                        if let sheet = hostingController.sheetPresentationController {
                            if #available(iOS 16.0, *) {
                                sheet.detents = [.custom(resolver: { [weak self] context in
                                    guard let self = self else { return .zero }

                                    return hostingController.sizeThatFits(in: .init(
                                        width: view.frame.width,
                                        height: .greatestFiniteMagnitude
                                    )).height
                                })]
                            } else {
                                sheet.detents = [.medium()]
                            }
                            sheet.prefersGrabberVisible = true
                            sheet.prefersEdgeAttachedInCompactHeight = true
                            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                        }
                        present(hostingController, animated: true)
                    }
                )
            }
            .store(in: &cancellables)
    }
}

extension TimelinesViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let timelineViewController = viewController as? TableViewController,
            let index = timelineViewControllers.firstIndex(of: timelineViewController),
            index + 1 < timelineViewControllers.count
        else { return nil }

        return timelineViewControllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let timelineViewController = viewController as? TableViewController,
            let index = timelineViewControllers.firstIndex(of: timelineViewController),
            index > 0
        else { return nil }

        return timelineViewControllers[index - 1]
    }
}

extension TimelinesViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        presentedViewController?.dismiss(animated: false)

        guard let viewController = viewControllers?.first as? TableViewController,
              let index = timelineViewControllers.firstIndex(of: viewController)
        else { return }

        segmentedControl.selectedSegmentIndex = index
    }
}

extension TimelinesViewController: ScrollableToTop {
    func scrollToTop(animated: Bool) {
        presentedViewController?.dismiss(animated: false)

        (viewControllers?.first as? TableViewController)?.scrollToTop(animated: animated)
    }
}

extension TimelinesViewController: NavigationHandling {
    func handle(navigation: Navigation) {
        presentedViewController?.dismiss(animated: false)

        (viewControllers?.first as? TableViewController)?.handle(navigation: navigation)
    }
}
