//
//  GeminiAPI.swift
//  VegieScanner
//
//  Refactored with centralized constants and better error handling
//

import Foundation
import UIKit
import SwiftUI

enum APIError: Error, LocalizedError {
    case noInternet
    case invalidImage
    case invalidResponse
    case rateLimitExceeded
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection available"
        case .invalidImage:
            return "Unable to process the selected image"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

class GeminiAPI {
    static let shared = GeminiAPI()
    private init() {}

    func analyze(image: UIImage) async throws -> ScanResult? {
        // Check network connectivity
        guard NetworkManager.shared.isConnected else {
            throw APIError.noInternet
        }
        
        guard let imageData = image.jpegData(compressionQuality: AppConstants.Config.imageCompressionQuality) else {
            throw APIError.invalidImage
        }
        
        let apiKey = AppConstants.Config.geminiAPIKey
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(AppConstants.Config.geminiModel):generateContent?key=\(apiKey)") else {
            throw APIError.serverError("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let base64Image = imageData.base64EncodedString()
        let isStrictVeganMode = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isStrictVeganMode)
        let prompt = isStrictVeganMode ? AppConstants.Prompts.veganPrompt : AppConstants.Prompts.vegetarianPrompt

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        ["inlineData": [
                            "mimeType": "image/jpeg",
                            "data": base64Image
                        ]]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topK": 1,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw APIError.serverError("Failed to encode request")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 429:
                throw APIError.rateLimitExceeded
            default:
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }

        guard let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw APIError.invalidResponse
        }

        // Parse the structured response
        let (_, status, confidence, explanation) = parseStructuredResponse(text)
        
        return ScanResult(
            status: status,
            confidence: confidence,
            explanation: explanation.isEmpty ? "Analysis completed" : explanation,
            imageData: imageData
        )
    }
}

func parseStructuredResponse(_ text: String) -> (foodName: String, status: VegStatus, confidence: Int, explanation: String) {
    var foodName = ""
    var status: VegStatus = .uncertain
    var confidence: Int = 50 // Default confidence
    var explanation = ""
    var collectingExplanation = false

    let lines = text.components(separatedBy: "\n")
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercaseLine = trimmedLine.lowercased()
        
        if lowercaseLine.hasPrefix("food name:") {
            foodName = String(trimmedLine.dropFirst("food name:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            collectingExplanation = false
        } else if lowercaseLine.hasPrefix("status:") {
            let value = String(trimmedLine.dropFirst("status:".count)).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch value {
            case "vegan", "vegetarian":
                status = .veg
            case "not vegan", "not vegetarian":
                status = .notVeg
            case "uncertain":
                status = .uncertain
            default:
                status = .uncertain
            }
            collectingExplanation = false
        } else if lowercaseLine.hasPrefix("confidence:") {
            let value = String(trimmedLine.dropFirst("confidence:".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "%", with: "")
            confidence = Int(value) ?? 50
            collectingExplanation = false
        } else if lowercaseLine.hasPrefix("explanation:") {
            explanation = String(trimmedLine.dropFirst("explanation:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            collectingExplanation = true
        } else if collectingExplanation && !trimmedLine.isEmpty {
            // Continue collecting explanation text
            explanation += " " + trimmedLine
        }
    }
    
    // Ensure confidence is within valid range
    confidence = max(0, min(100, confidence))

    return (foodName, status, confidence, explanation)
}

// MARK: - Gemini API Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
}
