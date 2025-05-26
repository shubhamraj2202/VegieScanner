// ScanHistoryView.swift


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
                    ForEach(scans.prefix(10)) { scan in
                        Button {
                            onSelect(scan)
                        } label: {
                            VStack(spacing: 0.1) {
                                if let image = UIImage(data: scan.imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                Text(scan.status == .veg ? "Veg" :
                                        scan.status == .notVeg ? "Not Veg" : "Uncertain")
                                .font(.caption)
                                .foregroundColor(scan.status == .veg ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Pro Tip — always shown
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Tip")
                        .font(.headline)
                    Text("For best results, ensure ingredients lists or food are clearly visible and well-lit. AI can analyze both whole foods and ingredients, but it can make mistakes!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
        }
        .onAppear {
            scans = CoreDataManager.shared.loadRecentScans()
        }
    }
}
