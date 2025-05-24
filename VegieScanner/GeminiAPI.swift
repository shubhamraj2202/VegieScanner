//
//  GeminiAPI.swift
//  VegieScanner
//
//  Created by Shubham Raj on 23/05/25.
//
import Foundation
import UIKit

//struct ScanResult: Identifiable, Codable {
//    let id = UUID()
//    let isVegan: Bool
//    let confidence: Int
//    let explanation: String
//    let imageData: Data
//}

class GeminiAPI {
    static let shared = GeminiAPI()
    private init() {}

    func analyze(image: UIImage) async throws -> ScanResult? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String ?? ""
        assert(!apiKey.isEmpty, "Gemini API key is missing from Info.plist")
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        // let prompt = "Is the food in this image vegan? Be detailed and explain why or why not. Provide a confidence percentage."
//        let prompt = """
//        Is the food in this image vegan? Answer with one of these exact keywords only: "Vegan", "Not Vegan", or "Uncertain". Then give a detailed explanation and a confidence percentage.
//
//        Format your response exactly like this:
//
//        Status: <Vegan / Not Vegan / Uncertain>
//        Confidence: <number>%
//        Explanation: <detailed explanation here>
//        """
        let prompt = """
        Is the food in this image vegan? Identify the food name as precisely as possible. Answer with one of these exact keywords only: "Vegan", "Not Vegan", or "Uncertain". Then give a detailed explanation and a confidence percentage.

        Format your response exactly like this:

        Food Name: <name or description of food>
        Status: <Vegan / Not Vegan / Uncertain>
        Confidence: <number>%
        Explanation: <detailed explanation here>
        """

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
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let response = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let text = response.candidates.first?.content.parts.first?.text else {
            return nil
        }

        // Parse vegan status + confidence from response
        let (_, status, confidence, explanation) = parseStructuredResponse(text)
        return ScanResult(status: status, confidence: confidence, explanation: explanation, imageData: imageData)
        // analyzeImagereturn ScanResult(status: status, confidence: confidence, explanation: explanation, imageData: imageData, foodName: foodName)
    }

    private func extractConfidence(from text: String) -> Int {
        let pattern = #"(\d{1,3})\s*%"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            let percentStr = text[match].replacingOccurrences(of: "%", with: "")
            return Int(percentStr.trimmingCharacters(in: .whitespaces)) ?? 0
        }
        return 0
    }
}

func parseStructuredResponse(_ text: String) -> (foodName: String, status: VeganStatus, confidence: Int, explanation: String) {
    var foodName = ""
    var status: VeganStatus = .uncertain
    var confidence: Int = 0
    var explanation = ""

    let lines = text.components(separatedBy: "\n")
    for line in lines {
        if line.lowercased().starts(with: "food name:") {
            foodName = line.dropFirst("food name:".count).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if line.lowercased().starts(with: "status:") {
            let value = line.dropFirst("status:".count).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch value {
                case "vegan": status = .vegan
                case "not vegan": status = .notVegan
                case "uncertain": status = .uncertain
                default: status = .uncertain
            }
        } else if line.lowercased().starts(with: "confidence:") {
            let value = line.dropFirst("confidence:".count).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")
            confidence = Int(value) ?? 0
        } else if line.lowercased().starts(with: "explanation:") {
            explanation = line.dropFirst("explanation:".count).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Append multiline explanation
            if !explanation.isEmpty {
                explanation += "\n" + line
            }
        }
    }

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
