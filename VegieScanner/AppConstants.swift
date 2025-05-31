//
//  AppConstants.swift
//  VegieScanner
//
//  Created by Shubham Raj on 31/05/25.
//  Centralized constants management

import Foundation

struct AppConstants {
    
    // MARK: - App Configuration
    struct Config {
        static let geminiAPIKey: String = {
            guard let key = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String,
                  !key.isEmpty else {
                fatalError("Gemini API key is missing from Info.plist")
            }
            return key
        }()
        
        static let geminiModel = Bundle.main.infoDictionary?["GeminiModel"] as? String ?? "gemini-1.5-flash"
        static let imageCompressionQuality = Bundle.main.infoDictionary?["ImageCompressionQuality"] as? Double ?? 0.8
        static let maxRecentScans = Bundle.main.infoDictionary?["MaxRecentScans"] as? Int ?? 10
    }
    
    // MARK: - UI Text
    struct UI {
        static let appTitle = Bundle.main.infoDictionary?["AppTitle"] as? String ?? "Is It Vegie?"
        static let appSubtitle = Bundle.main.infoDictionary?["AppSubtitle"] as? String ?? "Scan Your Food"
        static let appDescription = Bundle.main.infoDictionary?["AppDescription"] as? String ?? "Instantly check if it's veg-friendly"
        static let analyzingTitle = Bundle.main.infoDictionary?["AnalyzingTitle"] as? String ?? "Analyzing Your Food"
        static let analyzingSubtitle = Bundle.main.infoDictionary?["AnalyzingSubtitle"] as? String ?? "Our AI is checking if it's veg..."
        static let proTipTitle = Bundle.main.infoDictionary?["ProTipTitle"] as? String ?? "Pro Tip"
        static let proTipText = Bundle.main.infoDictionary?["ProTipText"] as? String ?? "For best results, ensure ingredients lists or food are clearly visible and well-lit. AI can analyze both whole foods and ingredients, but it can make mistakes!"
        static let noInternetTitle = Bundle.main.infoDictionary?["NoInternetTitle"] as? String ?? "No Internet Connection"
        static let noInternetMessage = Bundle.main.infoDictionary?["NoInternetMessage"] as? String ?? "Please check your internet connection and try again."
    }
    
    // MARK: - AI Prompts
    struct Prompts {
        static let veganPrompt = Bundle.main.infoDictionary?["VeganPrompt"] as? String ?? """
        Is the food in this image vegan? Strictly flag any dairy, eggs, or animal-derived ingredients as not vegan. Identify the food name as precisely as possible. Answer with one of these exact keywords only: "Vegan", "Not Vegan", or "Uncertain". Then give a detailed explanation and a confidence percentage.

        Format your response exactly like this:

        Food Name: <name or description of food>
        Status: <Vegan / Not Vegan / Uncertain>
        Confidence: <number>%
        Explanation: <detailed explanation here>
        """
        
        static let vegetarianPrompt = Bundle.main.infoDictionary?["VegetarianPrompt"] as? String ?? """
        Is the food in this image vegetarian? Dairy products like milk, butter, paneer, or cheese are allowed. Avoid meat, fish, and eggs. Identify the food name as precisely as possible. Answer with one of these exact keywords only: "Vegetarian", "Not Vegetarian", or "Uncertain". Then give a detailed explanation and a confidence percentage.

        Format your response exactly like this:

        Food Name: <name or description of food>
        Status: <Vegetarian / Not Vegetarian / Uncertain>
        Confidence: <number>%
        Explanation: <detailed explanation here>
        """
    }
    
    // MARK: - Support
    struct Support {
        static let supportEmail = Bundle.main.infoDictionary?["SupportEmail"] as? String ?? "aurax.ai108@gmail.com"
        static let termsURL = Bundle.main.infoDictionary?["TermsURL"] as? String ?? "https://docs.google.com/document/d/e/2PACX-1vSwBtdgx33nAUofbKZyBG38cQMAdlmTBKRFua7otwGeuIpEeiM_McZ8qQ1Lw6HSQZn447JgC3cEHX6W/pub"
        static let privacyURL = Bundle.main.infoDictionary?["PrivacyURL"] as? String ?? "https://docs.google.com/document/d/e/2PACX-1vTRiRqZMBUw9SFSAoe9AgXIg6uoEPMggC0_nN-gfIV9L4PDkKU4rb92nFKTBz6wN9Z_9PnwU87esFqP/pub"
    }
    
    // MARK: - In-App Purchase
    struct IAP {
        static let monthlyProductID = "com.vegiscanner.pro.monthly"
        static let yearlyProductID = "com.vegiscanner.pro.yearly"
        static let freeScansPerMonth = 10
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let isStrictVeganMode = "isStrictVeganMode"
        static let isPremiumUser = "isPremiumUser"
        static let monthlyScansUsed = "monthlyScansUsed"
        static let lastResetDate = "lastResetDate"
    }
}
