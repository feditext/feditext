// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Combine
import ServiceLayer
import SwiftUI
import ViewModels

@objc(ShareExtensionNavigationViewController)
class ShareExtensionNavigationViewController: UINavigationController {
    private let environment = AppEnvironment.live(
        userNotificationCenter: .current(),
        reduceMotion: { UIAccessibility.isReduceMotionEnabled },
        autoplayVideos: { UIAccessibility.isVideoAutoplayEnabled })

    override func viewDidLoad() {
        super.viewDidLoad()

        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? ImageCacheConfiguration(environment: environment).configure()

        let viewModel = ShareExtensionNavigationViewModel(environment: environment)
        let newStatusViewModel: ComposeStatusViewModel

        do {
            newStatusViewModel = try viewModel.composeStatusViewModel(extensionContext: extensionContext)
        } catch {
            setViewControllers([ShareErrorViewController(error: error)], animated: false)

            return
        }

        setViewControllers(
            [ComposeStatusViewController(viewModel: newStatusViewModel, rootViewModel: nil)],
            animated: false)
    }
}
