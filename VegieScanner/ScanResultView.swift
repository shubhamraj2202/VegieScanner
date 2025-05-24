//
//  ScanResultView.swift
//  VegieScanner
//
//  Created by Shubham Raj on 23/05/25.
//

import SwiftUI

struct ScanResultView: View {
    let result: ScanResult

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let uiImage = UIImage(data: result.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .frame(height: 300)
                }

                Text(icon(for: result.status) + " " + result.statusText)
                    .font(.largeTitle)
                    .foregroundColor(result.statusColor)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Confidence")
                        .font(.headline)

                    ProgressView(value: Float(result.confidence) / 100.0)
                        .accentColor(.blue)

                    Text("\(result.confidence)%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                Text("Analysis")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(result.explanation)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(for status: VeganStatus) -> String {
        switch status {
        case .vegan:
            return "✅"
        case .notVegan:
            return "❌"
        case .uncertain:
            return "❓"
        }
    }
}
