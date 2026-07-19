//
//  KnitGetherApp.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import Foundation
import SwiftUI

@main
struct KnitGetherApp: App {
    init() {
        UITestLaunchReset.applyIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private enum UITestLaunchReset {
    static func applyIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        guard environment["KNITGETHER_UI_TEST_RESET_ONBOARDING"] == "1" else {
            return
        }

        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.onboardingCompleted)
    }
}
