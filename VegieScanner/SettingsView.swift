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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scan Settings")) {
                    Toggle("Strict Vegan Mode", isOn: $isStrictVeganMode)
                    Text(isStrictVeganMode ?
                        "When enabled, dairy, eggs, and other animal products are flagged as non-vegan." :
                        "When disabled, dairy is allowed. This is suitable for vegetarian users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                Section {
                    Button("Contact Us") {
                        // Add your support email action later
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
}
