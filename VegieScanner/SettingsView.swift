//
//  SettingsView.swift
//  VegieScanner
//
//  Refactored settings with subscription management
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppConstants.UserDefaultsKeys.isStrictVeganMode) private var isStrictVeganMode = true
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            Form {
                // Subscription Status Section
                Section(header: Text("Subscription")) {
                    HStack {
                        Image(systemName: iapManager.isPremiumUser ? "crown.fill" : "crown")
                            .foregroundColor(iapManager.isPremiumUser ? .yellow : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(iapManager.isPremiumUser ? "Pro User" : "Free User")
                                .fontWeight(.semibold)
                            
                            if iapManager.isPremiumUser {
                                Text("Unlimited scans available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(iapManager.remainingFreeScans()) scans remaining this month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                
                // Data Management Section
                Section(header: Text("Data")) {
                    Button("Clear All Scan History") {
                        CoreDataManager.shared.deleteAllScans()
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

                    Button("Terms of Use") {
                        openURL(URL(string: AppConstants.Support.termsURL)!)
                    }

                    Button("Privacy Policy") {
                        openURL(URL(string: AppConstants.Support.privacyURL)!)
                    }
                }
                
                // App Info Section
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func contactSupport() {
        let email = AppConstants.Support.supportEmail
        let subject = "VegieScanner Support Request"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let body = """
        Hi AuraX Team,\n

        I'm experiencing an issue with the VegieScanner app.\n\n

        App Version: \(appVersion) (\(buildVersion))\n
        Device Model: \( UIDevice.current.model)\n
        iOS Version: \(UIDevice.current.systemVersion)\n
        Subscription Status: \(iapManager.isPremiumUser ? "Pro" : "Free")\n
        Issue Description: _______\n\n

        Please assist me with the above.\n
        \n
        Regards,\n
        [Your Name]\n
        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let emailURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(emailURL)
        }
    }
}
