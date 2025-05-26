//
//  ScanModel.swift
//  VegieScanner
//
//  Created by Shubham Raj on 23/05/25.
//

import Foundation
import SwiftUI

enum VegStatus: Int16, Codable {
    case uncertain = 0
    case veg = 1
    case notVeg = 2
}

struct ScanResult: Identifiable, Codable {
    let id: UUID
    let status: VegStatus
    let confidence: Int
    let explanation: String
    let imageData: Data

    init(id: UUID = UUID(), status: VegStatus, confidence: Int, explanation: String, imageData: Data) {
        self.id = id
        self.status = status
        self.confidence = confidence
        self.explanation = explanation
        self.imageData = imageData
    }
}

// MARK: - UI Helpers
extension ScanResult {
    var isVeg: Bool {
        return status == .veg
    }

    var statusText: String {
        switch status {
        case .veg:
            return "Veg"
        case .notVeg:
            return "Not Veg"
        case .uncertain:
            return "Uncertain"
        }
    }

    var statusColor: Color {
        switch status {
        case .veg:
            return .green
        case .notVeg:
            return .red
        case .uncertain:
            return .gray
        }
    }
}
