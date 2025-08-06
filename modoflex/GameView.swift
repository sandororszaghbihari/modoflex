///  GameView.swift
//  ModoFlex
//
//  Created by Mo-Do on 2025. 07. 27.
//

import SwiftUI
import AVFoundation

struct CharacterCircle: Identifiable {
    let id = UUID()
    let char: String
    var position: CGPoint
    var size: CGFloat
    var velocity: CGVector
    var isFadingOut: Bool = false
}

struct GameView: View {
    var wordPairs: [WordPair]
    @State private var currentPair: WordPair? = nil
    @State private var currentIndex = 0
    @State private var characters: [CharacterCircle] = []
    @State private var instruction: String = ""
    @State private var wordCompleted = false
    @State private var typedSpanish: String = ""
    @State private var showErrorFlash = false

    @State private var score = 0
    @State private var streak = 0
    @State private var highScore = UserDefaults.standard.integer(forKey: "highScore")

    @State private var elapsedTime = 0
    @State private var totalTime = 0
    @State private var timer: Timer? = nil
    @State private var totalTimer: Timer? = nil

    @State private var lives = 3
    @State private var lastFailedPair: WordPair? = nil
    @State private var pulse = false
    @StateObject private var dataLoader = DataLoader()
    @State private var showAnswerHint = false
    
    let movementTimer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .overlay(showErrorFlash ? Color.red.opacity(0.5) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: showErrorFlash)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Pont: \(score)")
                            Spacer()
                            Text("Széria: \(streak)")
                            Spacer()
                            Text("Rekord: \(highScore)")
                        }
                        HStack {
                            Text("Idő: \(elapsedTime)s")
                            Spacer()
                            Text("Össz: \(totalTime)s")
                        }
                    }
                    .foregroundColor(.white)
                    .font(.footnote)
                    .padding([.top, .horizontal])

                    Spacer()

                    if let pair = currentPair {
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 50)
                                HStack {
                                    if instruction == "left" {
                                        Text("🤚").font(.title)
                                    }
                                    Spacer()
                                    Text(pair.hungarian)
                                        .foregroundColor(.white)
                                        .font(.title2)
                                    Spacer()
                                    if instruction == "right" {
                                        Text("✋").font(.title)
                                    }
                                }.padding(.horizontal)
                            }
                            
                            
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.yellow.opacity(0.2))
                                        .frame(height: 40)
                                    Text(typedSpanish)
                                        .foregroundColor(.yellow)
                                        .font(.headline)
                                }

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showAnswerHint = true
                                    }
                                    
                                    // 3 másodperc múlva automatikusan eltűnik
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showAnswerHint = false
                                        }
                                    }
                                }) {
                                    Text("?")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.orange))
                                        .shadow(radius: 3)
                                }
                            }

                            if showAnswerHint, let pair = currentPair {
                                Label(pair.spanish, systemImage: "lightbulb.fill")
                                    .font(.footnote) // Kicsi, de olvashatóbb
                                    .foregroundColor(.yellow)
                                    .padding(.vertical, 2) // kis margó felül és alul
                                    .padding(.horizontal, 6) // kis margó oldalt is
                                    .background(Color.black.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.trailing, 8) // távolság a jobb szélétől
                                
                                    .animation(.easeInOut(duration: 0.2), value: showAnswerHint)
                            }
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    Image(systemName: index < lives ? "heart.fill" : "heart")
                                        .foregroundColor(index < lives ? .red : .gray)
                                }
                            }

                            //MARK: Help szöveg megjelenítő
                            if showAnswerHint && false {
                                HStack {
                                    Spacer()
                                    Label("Tipp", systemImage: "lightbulb.fill")
                                        .font(.caption2) // nagyon kicsi betűméret
                                        .foregroundColor(.yellow)
                                        .padding(.vertical, 2) // kis margó felül és alul
                                        .padding(.horizontal, 6) // kis margó oldalt is
                                        .background(Color.black.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.trailing, 8) // távolság a jobb szélétől
                                    Spacer()
                                }
                            }
                            
                            if wordCompleted {
                                Button(action: {
                                    loadNewPair(in: geometry.size)
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                        .frame(width: 60, height: 60)
                                        .background(Circle().fill(Color.green))
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)
                                        .scaleEffect(pulse ? 1.5 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                            value: pulse
                                        )
                                }
                                .padding(.top,30)
                                .onAppear { pulse = true }
                                .onChange(of: wordCompleted) { _, newValue in pulse = newValue }
                            } else {
                                ZStack {
                                    ForEach(characters) { char in
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: char.size, height: char.size)
                                            Text(char.char)
                                                .font(.system(size: char.size / 2.2, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .scaleEffect(char.isFadingOut ? 0.1 : 1.0)
                                        .opacity(char.isFadingOut ? 0.0 : 1.0)
                                        .position(char.position)
                                        .animation(.easeInOut(duration: 0.3), value: char.isFadingOut)
                                    }

                                    TouchCaptureView { location in
                                        print("📍 Precíz Tap Location: \(location)")
                                        handleTap(at: location)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onReceive(movementTimer) { _ in
                                    updateCharacterPositions(in: geometry.size)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Játék betöltése...")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Szavak száma: \(wordPairs.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
                .animation(.easeInOut, value: showAnswerHint)
            }
            .onAppear {
                if wordPairs.isEmpty {
                    print("⚠️ wordPairs üres!")
                } else {
                    loadNewPair(in: geometry.size)
                }
            }
        }
        
    }

    func handleTap(at point: CGPoint) {
        print("👆 Tap location: \(point)")

        if let tappedChar = characters.min(by: { distance($0.position, point) < distance($1.position, point) }),
           distance(tappedChar.position, point) <= tappedChar.size / 2 {
            print("✅ Tapped character: \(tappedChar.char)")
            tapAnimated(char: tappedChar.char, id: tappedChar.id)
        } else {
            print("❌ Nem talált karakter a tappolásnál.")
            triggerErrorFeedback()
        }
    }

    func tapAnimated(char: String, id: UUID) {
        guard let pair = currentPair else { return }
        guard currentIndex < pair.spanish.count else { return }
        let expected = String(pair.spanish[pair.spanish.index(pair.spanish.startIndex, offsetBy: currentIndex)])

        if char == expected {
            if let index = characters.firstIndex(where: { $0.id == id }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    characters[index].isFadingOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    characters.removeAll { $0.id == id }
                }
            }
            currentIndex += 1
            typedSpanish += char
            instruction = Bool.random() ? "left" : "right"
            score += 1

            if currentIndex >= pair.spanish.count {
                wordCompleted = true
                streak += 1
                score += 5
                if score > highScore {
                    highScore = score
                    UserDefaults.standard.set(highScore, forKey: "highScore")
                }
                timer?.invalidate()
            }
        } else {
            lives -= 1
            streak = 0
            triggerErrorFeedback()
            if lives <= 0 {
                lastFailedPair = pair
                loadSamePairAgain(in: UIScreen.main.bounds.size)
            }
        }
    }

    func triggerErrorFeedback() {
        showErrorFlash = true
        playSound(named: "error")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showErrorFlash = false
        }
    }

    func playSound(named name: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            var player: AVAudioPlayer?
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
            } catch {
                print("🎵 Hanglejátszás hiba: \(error)")
            }
        }
    }

    func loadSamePairAgain(in size: CGSize) {
        guard let pair = lastFailedPair else { return }
        currentPair = pair
        currentIndex = 0
        lives = 3
        typedSpanish = ""
        wordCompleted = false
        instruction = Bool.random() ? "left" : "right"
        characters = generateCharacters(for: pair.spanish, in: size)
        startTimer()
    }

    func loadNewPair(in size: CGSize) {
        if let newPair = wordPairs.randomElement() {
            currentPair = newPair
            currentIndex = 0
            lives = 3
            typedSpanish = ""
            wordCompleted = false
            instruction = Bool.random() ? "left" : "right"
            characters = generateCharacters(for: newPair.spanish, in: size)
            startTimer()
        }
    }

    func startTimer() {
        timer?.invalidate()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    func generateCharacters(for word: String, in size: CGSize) -> [CharacterCircle] {
        var result: [CharacterCircle] = []
        guard !word.isEmpty else { return result }

        let paddingX: CGFloat = 60
        let paddingYTop: CGFloat = 200
        let paddingYBottom: CGFloat = 250

        for (_, char) in word.map({ String($0) }).enumerated() {
            let circleSize = CGFloat.random(in: 48...64)
            let x = CGFloat.random(in: paddingX...(size.width - paddingX))
            let y = CGFloat.random(in: paddingYTop...(size.height - paddingYBottom))
            let position = CGPoint(x: x, y: y)
            let velocity = CGVector(dx: Double.random(in: -1.2...1.2), dy: Double.random(in: -1.2...1.2))
            result.append(CharacterCircle(char: char, position: position, size: circleSize, velocity: velocity))
        }
        return result
    }

    func updateCharacterPositions(in size: CGSize) {
        let bounds = CGRect(x: 30, y: 60, width: size.width - 60, height: size.height - 220)
        for i in characters.indices {
            var char = characters[i]
            var newX = char.position.x + char.velocity.dx
            var newY = char.position.y + char.velocity.dy

            if newX - char.size/2 < bounds.minX || newX + char.size/2 > bounds.maxX {
                char.velocity.dx *= -1
                newX = char.position.x + char.velocity.dx
            }
            if newY - char.size/2 < bounds.minY || newY + char.size/2 > bounds.maxY {
                char.velocity.dy *= -1
                newY = char.position.y + char.velocity.dy
            }

            char.position = CGPoint(x: newX, y: newY)
            characters[i] = char
        }

        for i in 0..<characters.count {
            for j in i+1..<characters.count {
                let a = characters[i]
                let b = characters[j]
                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let distance = sqrt(dx*dx + dy*dy)
                let minDist = (a.size + b.size) / 2
                if distance < minDist {
                    let overlap = (minDist - distance) / 2
                    let angle = atan2(dy, dx)
                    let offsetX = cos(angle) * overlap
                    let offsetY = sin(angle) * overlap
                    characters[i].position.x -= offsetX
                    characters[i].position.y -= offsetY
                    characters[j].position.x += offsetX
                    characters[j].position.y += offsetY
                }
            }
        }
        // ✅ Ütközés után is korrigáljuk a boundary-n túli pozíciókat
        for i in characters.indices {
            var char = characters[i]
            let halfSize = char.size / 2

            if char.position.x - halfSize < bounds.minX {
                char.position.x = bounds.minX + halfSize
                char.velocity.dx *= -1
            } else if char.position.x + halfSize > bounds.maxX {
                char.position.x = bounds.maxX - halfSize
                char.velocity.dx *= -1
            }

            if char.position.y - halfSize < bounds.minY {
                char.position.y = bounds.minY + halfSize
                char.velocity.dy *= -1
            } else if char.position.y + halfSize > bounds.maxY {
                char.position.y = bounds.maxY - halfSize
                char.velocity.dy *= -1
            }

            characters[i] = char
        }
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}


