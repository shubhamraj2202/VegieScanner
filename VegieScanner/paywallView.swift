//
//  pauywallView.swift
//  VegieScanner
//
//  Created by Shubham Raj on 31/05/25.
//  Pro subscription paywall interface


import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var selectedProductIndex = 1 // Default to yearly
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                            
                            Text("Upgrade to Pro")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Unlock unlimited scans and premium features")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Current usage info
                        if !iapManager.isPremiumUser {
                            VStack(spacing: 8) {
                                Text("Free Plan Usage")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Scans remaining this month:")
                                    Spacer()
                                    Text("\(iapManager.remainingFreeScans())/\(AppConstants.IAP.freeScansPerMonth)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                ProgressView(value: Double(AppConstants.IAP.freeScansPerMonth - iapManager.remainingFreeScans()), total: Double(AppConstants.IAP.freeScansPerMonth))
                                    .accentColor(.green)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        // Features list
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pro Features")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited Scans",
                                description: "Scan as many foods as you want"
                            )
                            
                            FeatureRow(
                                icon: "bolt.fill",
                                title: "Priority Processing",
                                description: "Faster AI analysis results"
                            )
                            
                            FeatureRow(
                                icon: "cloud.fill",
                                title: "Cloud Sync",
                                description: "Access your scan history anywhere"
                            )
                            
                            FeatureRow(
                                icon: "heart.fill",
                                title: "Support Development",
                                description: "Help us improve the app"
                            )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        
                        // Subscription options
                        if !iapManager.products.isEmpty {
                            VStack(spacing: 12) {
                                Text("Choose Your Plan")
                                    .font(.headline)
                                
                                ForEach(Array(iapManager.products.enumerated()), id: \.element.productIdentifier) { index, product in
                                    SubscriptionOptionView(
                                        product: product,
                                        isSelected: selectedProductIndex == index,
                                        isPopular: product.productIdentifier == AppConstants.IAP.yearlyProductID
                                    ) {
                                        selectedProductIndex = index
                                    }
                                }
                            }
                        }
                        
                        // Purchase buttons
                        VStack(spacing: 12) {
                            if let selectedProduct = iapManager.products.indices.contains(selectedProductIndex) ? iapManager.products[selectedProductIndex] : nil {
                                Button(action: {
                                    purchaseProduct(selectedProduct)
                                }) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        }
                                        Text(isLoading ? "Processing..." : "Subscribe Now")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .fontWeight(.semibold)
                                }
                                .disabled(isLoading)
                            }
                            
                            Button("Restore Purchases") {
                                iapManager.restorePurchases()
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Terms and privacy
                        HStack(spacing: 20) {
                            Button("Terms of Use") {
                                if let url = URL(string: AppConstants.Support.termsURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Button("Privacy Policy") {
                                if let url = URL(string: AppConstants.Support.privacyURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private func purchaseProduct(_ product: SKProduct) {
        isLoading = true
        iapManager.purchase(product: product)
        
        // Reset loading state after a delay (in real app, this should be handled by transaction observer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isLoading = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionOptionView: View {
    let product: SKProduct
    let isSelected: Bool
    let isPopular: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.localizedTitle)
                            .fontWeight(.semibold)
                        
                        if isPopular {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(IAPManager.shared.priceString(for: product))
                        .fontWeight(.bold)
                    
                    if product.productIdentifier == AppConstants.IAP.yearlyProductID {
                        Text("Save 58%")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
