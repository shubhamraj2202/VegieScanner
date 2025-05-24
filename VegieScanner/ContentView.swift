import SwiftUI

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var useCamera = false
    @State private var selectedImage: UIImage?
    @State private var result: ScanResult?
    @State private var showResult = false
    @State private var isAnalyzing = false
    @State private var showSettings = false
    @AppStorage("isStrictVeganMode") private var isStrictVeganMode = true

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Is It Vegie?")
                            .font(.system(size: 34, weight: .bold))
                        VStack(spacing: 4) {
                            Text("Scan Your Food")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Instantly check if it's vegan-friendly")
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

                    VStack(spacing: 16) {
                        Button {
                            useCamera = true
                            showImagePicker = true
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

                        Button {
                            useCamera = false
                            showImagePicker = true
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
                    }
                    .padding(.horizontal)

                    Divider().padding(.vertical)

//                    Text("Recent Scans")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScanHistoryPreview(onSelect: { selected in
                        self.result = selected
                        self.showResult = true
                    })

                    Spacer()
                }
                .padding()

                if isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(1.5)
                            Text("Analyzing Your Food")
                                .font(.headline)
                            Text("Our AI is checking if it's vegan...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }

                NavigationLink(
                    destination: Group {
                        if let result = result {
                            ScanResultView(result: result)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $showResult
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .imageScale(.large)
            })
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: useCamera ? .camera : .photoLibrary) { image in
                    self.selectedImage = image
                    analyzeImage(image)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        Task {
            if let result = try? await GeminiAPI.shared.analyze(image: image) {
                self.result = result
                CoreDataManager.shared.saveScan(result)
                self.showResult = true
            }
            isAnalyzing = false
        }
    }
}

struct SettingsView: View {
    @AppStorage("isStrictVeganMode") private var isStrictVeganMode = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scan Settings")) {
                    Toggle("Strict Vegan Mode", isOn: $isStrictVeganMode)
                    Text(isStrictVeganMode ?
                        "When enabled, dairy, eggs, and other animal products are flagged as non-vegan." :
                        "When disabled, dairy is allowed. This is suitable for vegetarian users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                Section {
                    Button("Contact Us") {
                        // placeholder
                    }
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
