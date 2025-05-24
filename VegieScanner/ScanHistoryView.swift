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
            // Header with Clear All
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
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(scans.prefix(10)) { scan in
                    Button {
                        onSelect(scan)
                    } label: {
                        VStack {
                            if let image = UIImage(data: scan.imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Text(scan.status == .vegan ? "Vegan" :
                                 scan.status == .notVegan ? "Not Vegan" : "Uncertain")
                                .font(.caption2)
                                .foregroundColor(scan.status == .vegan ? .green : .red)
                        }
                    }
                }
            }

            // Pro Tip
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Tip")
                        .font(.headline)
                    Text("For best results, ensure ingredients lists or food are clearly visible and well-lit. Our AI can analyze both whole foods and ingredient labels, but it can make mistakes!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .onAppear {
            scans = CoreDataManager.shared.loadRecentScans()
        }
    }
}
