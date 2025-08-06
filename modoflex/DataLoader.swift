//
//  DataLoader.swift
//  modoflex
//
//  Created by Orszagh Bihari Sandor  on 2025. 07. 27..
//


import Foundation

class DataLoader: ObservableObject {
    @Published var wordPairs: [WordPair] = []
    @Published var availableFiles: [GitHubFile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDataLoaded = false
    
    private let baseURL = "https://raw.githubusercontent.com/sandororszaghbihari/modoflex/main/modoflex/DATA/"
    
    func loadAvailableFiles() {
        isLoading = true
        errorMessage = nil
        
        // Először próbáljuk betölteni a files.txt fájlt
        guard let url = URL(string: "\(baseURL)files.txt") else {
            loadFallbackFiles()
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let content = String(data: data, encoding: .utf8) {
                    let lines = content.split(separator: "\n")
                    var files: [GitHubFile] = []
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedLine.isEmpty {
                            files.append(GitHubFile(name: trimmedLine, url: "\(self.baseURL)\(trimmedLine)"))
                        }
                    }
                    
                    if !files.isEmpty {
                        self.availableFiles = files
                        print("✅ \(files.count) fájl betöltve a files.txt-ből")
                    } else {
                        print("⚠️ A files.txt üres, fallback listát használunk")
                        self.loadFallbackFiles()
                    }
                } else {
                    print("❌ Nem sikerült betölteni a files.txt-t, fallback listát használunk")
                    self.loadFallbackFiles()
                }
                self.isLoading = false
            }
        }.resume()
    }
    
    private func loadFallbackFiles() {
        // Fallback fájlok listája ha a files.txt nem elérhető
        let fallbackFiles = [
            GitHubFile(name: "data.txt", url: "\(baseURL)data.txt"),
            GitHubFile(name: "alap.txt", url: "\(baseURL)alap.txt"),
            GitHubFile(name: "haladó.txt", url: "\(baseURL)halado.txt"),
            GitHubFile(name: "szavak.txt", url: "\(baseURL)szavak.txt"),
            GitHubFile(name: "gyakorlás.txt", url: "\(baseURL)gyakorlas.txt")
        ]
        
        DispatchQueue.main.async {
            self.availableFiles = fallbackFiles
            self.isLoading = false
        }
    }
    
    func loadFromGitHub(fileName: String, completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        isDataLoaded = false
        
        guard let url = URL(string: "\(baseURL)\(fileName)") else {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Hibás URL"
                self.isLoading = false
                completion?()
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                // Ellenőrizzük a HTTP válasz státuszát
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 {
                        self.errorMessage = "❌ A fájl nem található: \(fileName)"
                        print("❌ 404 - A fájl nem található: \(fileName)")
                        self.isLoading = false
                        completion?()
                        return
                    }
                }
                
                if let data = data, let content = String(data: data, encoding: .utf8) {
                    let lines = content.split(separator: "\n")
                    var tempPairs: [WordPair] = []

                    for line in lines {
                        let components = line.split(separator: ";").map { String($0) }
                        print("🔍 Sor feldolgozása: '\(line)' -> \(components.count) komponens")
                        
                        if components.count >= 2 {
                            // Ha csak 2 komponens van, akkor magyar;spanyol formátum
                            let hungarian = components[0]
                            let spanish = components[1]
                            
                            let pair = WordPair(
                                id: tempPairs.count + 1, // Automatikus ID generálás
                                hungarian: hungarian,
                                spanish: spanish,
                                questionNote: components.count > 2 ? components[2] : "",
                                answerNote: components.count > 3 ? components[3] : "",
                                score: components.count > 4 ? components[4] : "0"
                            )
                            print("✅ Pár létrehozva: \(hungarian) - \(spanish)")
                            tempPairs.append(pair)
                        } else {
                            print("⚠️ Hiányos sor: '\(line)'")
                        }
                    }

                    if tempPairs.isEmpty {
                        self.errorMessage = "❌ A fájl üres vagy nem megfelelő formátumú: \(fileName)"
                        print("❌ A fájl üres vagy nem megfelelő formátumú: \(fileName)")
                    } else {
                        self.wordPairs = tempPairs
                        self.isDataLoaded = true
                        print("✅ \(tempPairs.count) szó betöltve a \(fileName) fájlból")
                    }
                } else {
                    self.errorMessage = "❌ Nem sikerült letölteni: \(error?.localizedDescription ?? "Ismeretlen hiba")"
                    print("❌ Nem sikerült letölteni: \(error?.localizedDescription ?? "Ismeretlen hiba")")
                }
                self.isLoading = false
                completion?()
            }
        }.resume()
    }
    
    // Régi metódus kompatibilitás miatt
    func loadFromGitHub() {
        loadFromGitHub(fileName: "data.txt")
    }
}
