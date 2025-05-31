//
//  IAPManager.swift
//  VegieScanner
//
//  Created by Shubham Raj on 31/05/25.
//  In-App Purchase management for Pro subscriptions

import Foundation
import StoreKit
import SwiftUI

class IAPManager: NSObject, ObservableObject {
    static let shared = IAPManager()
    
    @Published var products: [SKProduct] = []
    @Published var isPremiumUser: Bool {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: AppConstants.UserDefaultsKeys.isPremiumUser)
        }
    }
    @Published var monthlyScansUsed: Int {
        didSet {
            UserDefaults.standard.set(monthlyScansUsed, forKey: AppConstants.UserDefaultsKeys.monthlyScansUsed)
        }
    }
    
    private override init() {
        self.isPremiumUser = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isPremiumUser)
        self.monthlyScansUsed = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.monthlyScansUsed)
        super.init()
        
        SKPaymentQueue.default().add(self)
        fetchProducts()
        checkAndResetMonthlyScans()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Product Fetching
    func fetchProducts() {
        let productIDs: Set<String> = [
            AppConstants.IAP.monthlyProductID,
            AppConstants.IAP.yearlyProductID
        ]
        
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    // MARK: - Purchase Methods
    func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            print("Purchases are disabled")
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Scan Limits
    func canPerformScan() -> Bool {
        if isPremiumUser {
            return true
        }
        
        checkAndResetMonthlyScans()
        return monthlyScansUsed < AppConstants.IAP.freeScansPerMonth
    }
    
    func incrementScanCount() {
        if !isPremiumUser {
            monthlyScansUsed += 1
        }
    }
    
    func remainingFreeScans() -> Int {
        if isPremiumUser {
            return -1 // Unlimited
        }
        
        checkAndResetMonthlyScans()
        return max(0, AppConstants.IAP.freeScansPerMonth - monthlyScansUsed)
    }
    
    private func checkAndResetMonthlyScans() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastResetDate = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.lastResetDate) as? Date {
            if !calendar.isDate(lastResetDate, equalTo: now, toGranularity: .month) {
                // New month, reset scans
                monthlyScansUsed = 0
                UserDefaults.standard.set(now, forKey: AppConstants.UserDefaultsKeys.lastResetDate)
            }
        } else {
            // First time, set the reset date
            UserDefaults.standard.set(now, forKey: AppConstants.UserDefaultsKeys.lastResetDate)
        }
    }
    
    // MARK: - Helper Methods
    func getProduct(for identifier: String) -> SKProduct? {
        return products.first { $0.productIdentifier == identifier }
    }
    
    func priceString(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? ""
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
        }
        
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid product identifiers: \(response.invalidProductIdentifiers)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Product request failed: \(error.localizedDescription)")
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchaseSuccess(transaction)
            case .restored:
                handlePurchaseSuccess(transaction)
            case .failed:
                handlePurchaseFailure(transaction)
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchaseSuccess(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.isPremiumUser = true
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handlePurchaseFailure(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            if error.code != .paymentCancelled {
                print("Purchase failed: \(error.localizedDescription)")
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
