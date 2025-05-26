//
//  SettingsView.swift
//  VegieScanner
//
//  Created by Shubham Raj on 25/05/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isStrictVeganMode") private var isStrictVeganMode = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scan Settings")) {
                    Toggle("Strict Vegan Mode", isOn: $isStrictVeganMode)

                    Text(isStrictVeganMode ?
                         "🌱 Vegan Mode: Flags dairy, eggs, and other animal products as non-vegan." :
                         "🧀 Vegetarian Mode: Dairy is allowed, suitable for vegetarian users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                Section(header: Text("Support")) {
                    Button("Contact Us") {
                        contactSupport()
                    }
                    .foregroundColor(.blue)

                    Button("Terms of Use") {
                        openURL(URL(string: "https://docs.google.com/document/d/e/2PACX-1vSwBtdgx33nAUofbKZyBG38cQMAdlmTBKRFua7otwGeuIpEeiM_McZ8qQ1Lw6HSQZn447JgC3cEHX6W/pub")!)
                    }

                    Button("Privacy Policy") {
                        openURL(URL(string: "https://docs.google.com/document/d/e/2PACX-1vTRiRqZMBUw9SFSAoe9AgXIg6uoEPMggC0_nN-gfIV9L4PDkKU4rb92nFKTBz6wN9Z_9PnwU87esFqP/pub")!)
                    }

                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func contactSupport() {
        let email = "aurax.ai108@gmail.com"
        let subject = "VegieScanner Support Request"

        let body = """
        Hi AuraX Team,\r\n
        \r\n
        I’m experiencing an issue with the VegieScanner app.\r\n
        \r\n
        Device Model: _______\r\n
        iOS Version: _______\r\n
        Issue Description: _______\r\n
        Screenshots (if any): _______\r\n
        \r\n
        Please assist me with the above.\r\n
        \r\n
        Regards,\r\n
        [Your Name]
        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let emailURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(emailURL)
        }
    }
}
