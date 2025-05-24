//
//  ScanModel.swift
//  VegieScanner
//
//  Created by Shubham Raj on 23/05/25.
//

import Foundation
import SwiftUI

enum VeganStatus: Int16, Codable {
    case uncertain = 0
    case vegan = 1
    case notVegan = 2
}

struct ScanResult: Identifiable, Codable {
    let id: UUID
    let status: VeganStatus
    let confidence: Int
    let explanation: String
    let imageData: Data

    init(id: UUID = UUID(), status: VeganStatus, confidence: Int, explanation: String, imageData: Data) {
        self.id = id
        self.status = status
        self.confidence = confidence
        self.explanation = explanation
        self.imageData = imageData
    }
}

// MARK: - UI Helpers
extension ScanResult {
    var isVegan: Bool {
        return status == .vegan
    }

    var statusText: String {
        switch status {
        case .vegan:
            return "Vegan"
        case .notVegan:
            return "Not Vegan"
        case .uncertain:
            return "Uncertain"
        }
    }

    var statusColor: Color {
        switch status {
        case .vegan:
            return .green
        case .notVegan:
            return .red
        case .uncertain:
            return .gray
        }
    }
}
