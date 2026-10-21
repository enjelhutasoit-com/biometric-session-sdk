//
// Copyright (c) 2026 Enjel Hutasoit
//


import SwiftUI

@main
struct BiometricSessionDemoApp: App {
    @StateObject private var model = DemoModel.live()

    var body: some Scene {
        WindowGroup {
            DemoView(model: model)
                .onAppear { model.start() }
        }
    }
}
