//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import SwiftUI

struct DemoView: View {
    @ObservedObject var model: DemoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("State: \(String(describing: model.state))")
                .font(.headline)
            HStack {
                button("Sign in") { await model.signIn() }
                button("Lock") { await model.lock() }
                button("Unlock") { await model.unlock() }
            }
            HStack {
                button("Sensitive action") { await model.sensitiveAction() }
                button("Sign out") { await model.signOut() }
            }
            Text("Demo only. Sign in here is not a real login.")
                .font(.footnote)
                .foregroundColor(.secondary)
            List(Array(model.log.enumerated()), id: \.offset) { entry in
                Text(entry.element).font(.footnote)
            }
        }
        .padding()
    }

    private func button(
        _ title: String,
        action: @escaping () async -> Void
    ) -> some View {
        Button(title) {
            model.interact()
            Task { await action() }
        }
    }
}
