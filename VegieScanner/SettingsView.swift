//
//  SettingsView.swift
//  VegieScanner
//
//  Refactored settings with subscription management and improved UX
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppConstants.UserDefaultsKeys.isStrictVeganMode) private var isStrictVeganMode = true
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @State private var showPaywall = false
    @State private var showRestoreSuccess = false
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                // Subscription Section
                Section(header: Text("Subscription")) {
                    HStack {
                        Image(systemName: iapManager.isPremiumUser ? "crown.fill" : "crown")
                            .foregroundColor(iapManager.isPremiumUser ? .yellow : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(iapManager.isPremiumUser ? "Pro User" : "Free User")
                                .fontWeight(.semibold)
                            
                            Text(iapManager.isPremiumUser ? "Unlimited scans available" :
                                 "\(iapManager.remainingFreeScans()) scans remaining this month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !iapManager.isPremiumUser {
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    if iapManager.isPremiumUser {
                        Button("Restore Purchases") {
                            iapManager.restorePurchases()
                            showRestoreSuccess = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Scan Settings Section
                Section(header: Text("Scan Settings")) {
                    Toggle("Strict Vegan Mode", isOn: $isStrictVeganMode)

                    Text(isStrictVeganMode ?
                         "🌱 Vegan Mode: Flags dairy, eggs, and other animal products as non-vegan." :
                         "🧀 Vegetarian Mode: Dairy is allowed, suitable for vegetarian users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                // Data Section
                Section(header: Text("Data")) {
                    Button("Clear All Scan History") {
                        showClearConfirmation = true
                    }
                    .foregroundColor(.red)

                    HStack {
                        Text("Network Status")
                        Spacer()
                        HStack {
                            Circle()
                                .fill(NetworkManager.shared.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(NetworkManager.shared.isConnected ? "Connected" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Support Section
                Section(header: Text("Support & Legal")) {
                    Button("Contact Support") {
                        contactSupport()
                    }
                    .foregroundColor(.blue)

                    Link("Terms of Use", destination: URL(string: AppConstants.Support.termsURL)!)
                    Link("Privacy Policy", destination: URL(string: AppConstants.Support.privacyURL)!)
                }

                // App Info Section
                Section(header: Text("App Info")) {
                    LabeledContent("Version", value: getAppInfo("CFBundleShortVersionString"))
                    LabeledContent("Build", value: getAppInfo("CFBundleVersion"))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restore Successful", isPresented: $showRestoreSuccess) {
                Button("OK", role: .cancel) { }
            }
            .alert("Confirm", isPresented: $showClearConfirmation) {
                Button("Delete", role: .destructive) {
                    CoreDataManager.shared.deleteAllScans()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all scan history?")
            }
        }
    }

    private func contactSupport() {
        let email = AppConstants.Support.supportEmail
        let subject = "VegieScanner Support Request"
        let appVersion = getAppInfo("CFBundleShortVersionString")
        let buildVersion = getAppInfo("CFBundleVersion")

        let body = """
        Hi AuraX Team,\r\n
        \r\n
        I'm experiencing an issue with the VegieScanner app.\r\n\r\n
        App Version: \(appVersion) (\(buildVersion))\r\n
        Device Model: \(UIDevice.current.model)\r\n
        iOS Version: \(UIDevice.current.systemVersion)\r\n
        Subscription Status: \(iapManager.isPremiumUser ? "Pro" : "Free")\r\n
        Issue Description: _______\r\n\r\n
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

    private func getAppInfo(_ key: String) -> String {
        return Bundle.main.infoDictionary?[key] as? String ?? "Unknown"
    }
}
