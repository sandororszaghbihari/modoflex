//
//  SplashView.swift
//  modoflex
//
//  Created by Orszagh Bihari Sandor  on 2025. 07. 27..
//


// SplashView.swift
import SwiftUI

struct SplashView: View {
    @StateObject private var dataLoader = DataLoader()
    @State private var isLoaded = false
    @State private var selectedFile: GitHubFile?
    @State private var showingFileSelector = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sötét háttér mint a GameView-ban
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                if isLoaded && !dataLoader.wordPairs.isEmpty {
                    GameView(wordPairs: dataLoader.wordPairs)
                        .transition(.opacity)
                } else if showingFileSelector {
                    FileSelectionView(
                        dataLoader: dataLoader,
                        selectedFile: $selectedFile,
                        showingFileSelector: $showingFileSelector,
                        isLoaded: $isLoaded
                    )
                    .transition(.opacity)
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Szavak betöltése...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if dataLoader.wordPairs.isEmpty && !dataLoader.isLoading {
                            Text("Betöltött szavak: \(dataLoader.wordPairs.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let errorMessage = dataLoader.errorMessage {
                            VStack(spacing: 15) {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                
                                Button(action: {
                                    showingFileSelector = true
                                    dataLoader.errorMessage = nil
                                }) {
                                    Text("Vissza a fájl választóhoz")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            dataLoader.loadAvailableFiles()
        }
    }
}

struct FileSelectionView: View {
    @ObservedObject var dataLoader: DataLoader
    @Binding var selectedFile: GitHubFile?
    @Binding var showingFileSelector: Bool
    @Binding var isLoaded: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Válassz fájlt")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if dataLoader.isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Fájlok betöltése...")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("files.txt keresése...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(dataLoader.availableFiles) { file in
                            FileSelectionCard(
                                file: file,
                                isSelected: selectedFile?.id == file.id
                            ) {
                                selectedFile = file
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = dataLoader.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Button(action: {
                    if let file = selectedFile {
                        showingFileSelector = false
                        dataLoader.loadFromGitHub(fileName: file.name) {
                            // Callback hívódik meg, amikor a betöltés befejeződött
                            if dataLoader.errorMessage == nil && !dataLoader.wordPairs.isEmpty {
                                withAnimation {
                                    isLoaded = true
                                }
                            } else {
                                // Ha van hiba vagy nincsenek szavak, térjünk vissza a fájl választóhoz
                                showingFileSelector = true
                            }
                        }
                    }
                }) {
                    Text("Kezdés")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedFile != nil ? Color.blue : Color.gray
                        )
                        .cornerRadius(12)
                }
                .disabled(selectedFile == nil)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct FileSelectionCard: View {
    let file: GitHubFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(file.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Kattints a kiválasztáshoz")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TouchCaptureView: UIViewRepresentable {
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator: NSObject {
        var onTap: (CGPoint) -> Void

        init(onTap: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: sender.view)
            onTap(location)
        }
    }
}
