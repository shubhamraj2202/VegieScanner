// ScanHistoryView.swift
// Refactored with centralized constants

import SwiftUI

struct ScanHistoryPreview: View {
    var onSelect: (ScanResult) -> Void
    @State private var scans: [ScanResult] = []
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !scans.isEmpty {
                // Header
                HStack {
                    Text("Recent Scans")
                        .font(.headline)
                    Spacer()
                    Button("Clear All") {
                        CoreDataManager.shared.deleteAllScans()
                        scans = []
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)

                // Grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(scans.prefix(AppConstants.Config.maxRecentScans)) { scan in
                        Button {
                            onSelect(scan)
                        } label: {
                            VStack(spacing: 4) {
                                if let image = UIImage(data: scan.imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(scan.statusColor, lineWidth: 2)
                                        )
                                }
                                
                                Text(scan.statusText)
                                    .font(.caption2)
                                    .foregroundColor(scan.statusColor)
                                    .fontWeight(.semibold)
                                
                                Text("\(scan.confidence)%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }

            // Pro Tip — always shown
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppConstants.UI.proTipTitle)
                        .font(.headline)
                    Text(AppConstants.UI.proTipText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
        }
        .onAppear {
            loadScans()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            loadScans()
        }
    }
    
    private func loadScans() {
        scans = CoreDataManager.shared.loadRecentScans(limit: AppConstants.Config.maxRecentScans)
    }
}
