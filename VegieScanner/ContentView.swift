import SwiftUI

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var useCamera = false
    @State private var selectedImage: UIImage?
    @State private var result: ScanResult?
    @State private var showResult = false
    @State private var isAnalyzing = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showNetworkAlert = false
    @AppStorage(AppConstants.UserDefaultsKeys.isStrictVeganMode) private var isStrictVeganMode = true

    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var iapManager = IAPManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {

                    // MARK: - Header Section
                    VStack(spacing: 4) {
                        Text(AppConstants.UI.appTitle)
                            .font(.system(size: 34, weight: .bold))
                        VStack(spacing: 4) {
                            Text(AppConstants.UI.appSubtitle)
                                .font(.title)
                                .foregroundColor(.white)
                            Text(AppConstants.UI.appDescription)
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }

                    // MARK: - Scan Count for Free Users
                    if !iapManager.isPremiumUser {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "camera.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Free scans remaining: \(iapManager.remainingFreeScans())/\(AppConstants.IAP.freeScansPerMonth)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Go Pro") {
                                    showPaywall = true
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                            }

                            ProgressView(value: Double(AppConstants.IAP.freeScansPerMonth - iapManager.remainingFreeScans()),
                                         total: Double(AppConstants.IAP.freeScansPerMonth))
                                .accentColor(.blue)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: 16) {
                        Button {
                            handleScanAction(useCamera: true)
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(!canPerformScan())

                        Button {
                            handleScanAction(useCamera: false)
                        } label: {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Gallery")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(!canPerformScan())
                    }
                    .padding(.horizontal)

                    Divider().padding(.vertical)

                    // MARK: - Scan History Preview
                    ScanHistoryPreview(onSelect: { selected in
                        self.result = selected
                        self.showResult = true
                    })

                    Spacer()
                }
                .padding()

                // MARK: - Loading Overlay
                if isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(1.5)
                            Text(AppConstants.UI.analyzingTitle)
                                .font(.headline)
                            Text(AppConstants.UI.analyzingSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }

                // MARK: - Navigation to Result View
                NavigationLink("", isActive: $showResult) {
                    if let result = result {
                        ScanResultView(result: result)
                    }
                }
                .hidden()
            }
            .navigationTitle("") // Optional
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if iapManager.isPremiumUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Pro")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: useCamera ? .camera : .photoLibrary) { image in
                    self.selectedImage = image
                    analyzeImage(image)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("No Internet Connection", isPresented: $showNetworkAlert) {
                Button("Retry") {}
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(AppConstants.UI.noInternetMessage)
            }
        }
    }

    // MARK: - Helper Methods

    private func canPerformScan() -> Bool {
        return iapManager.canPerformScan()
    }

    private func handleScanAction(useCamera: Bool) {
        guard networkManager.isConnected else {
            showNetworkAlert = true
            return
        }

        guard iapManager.canPerformScan() else {
            showPaywall = true
            return
        }

        self.useCamera = useCamera
        showImagePicker = true
    }

    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        iapManager.incrementScanCount()

        Task {
            do {
                if let result = try await GeminiAPI.shared.analyze(image: image) {
                    await MainActor.run {
                        self.result = result
                        CoreDataManager.shared.saveScan(result)
                        self.showResult = true
                        self.isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    print("Analysis failed: \(error)")
                }
            }
        }
    }
}
