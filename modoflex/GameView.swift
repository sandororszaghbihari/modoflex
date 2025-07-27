//
//  WordPair.swift
//  modoflex
//
//  Created by Orszagh Bihari Sandor  on 2025. 07. 27..
//


import SwiftUI
import AVFoundation

struct WordPair {
    let hungarian: String
    let spanish: String
}

func loadWordPairs() -> [WordPair] {
    guard let url = Bundle.main.url(forResource: "data", withExtension: "txt") else {
        print("❌ Nem található a data.txt fájl")
        return []
    }

    do {
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)

        return lines.compactMap { line in
            let parts = line.components(separatedBy: ";")
            guard parts.count == 2 else { return nil }
            return WordPair(hungarian: parts[0], spanish: parts[1])
        }
    } catch {
        print("❌ Hiba a fájl beolvasásakor: \(error)")
        return []
    }
}

struct CharacterCircle: Identifiable {
    let id = UUID()
    let char: String
    var position: CGPoint
    var size: CGFloat
    var velocity: CGVector
    var isFadingOut: Bool = false
}

struct GameView: View {
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

    let wordPairs: [WordPair] = loadWordPairs()
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

                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(height: 50)
                                Text(typedSpanish)
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }

                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    Image(systemName: index < lives ? "heart.fill" : "heart")
                                        .foregroundColor(index < lives ? .red : .gray)
                                }
                            }

                            if wordCompleted {
                                Button("Új szó") {
                                    loadNewPair(in: geometry.size)
                                }
                                .font(.title)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
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
                                        .animation(.easeInOut(duration: 0.3), value: char.isFadingOut)
                                        .contentShape(Circle())
                                        .position(char.position)
                                        .onTapGesture {
                                            tapAnimated(char: char.char, id: char.id)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onReceive(movementTimer) { _ in
                                    updateCharacterPositions(in: geometry.size)
                                }
                            }
                        }
                    }

                    Spacer()
                }
            }
            .onAppear {
                loadNewPair(in: geometry.size)
                totalTime = 0
                startTotalTimer()
            }
        }
    }

    func tapAnimated(char: String, id: UUID) {
        guard let pair = currentPair else { return }
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
                if typedSpanish.count == pair.spanish.count {
                    streak += 1
                    score += 5
                }
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

    func startTotalTimer() {
        totalTimer?.invalidate()
        totalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            totalTime += 1
        }
    }

    func generateCharacters(for word: String, in size: CGSize) -> [CharacterCircle] {
        var result: [CharacterCircle] = []
        var usedRects: [CGRect] = []
        let paddingX: CGFloat = 60
        let paddingYTop: CGFloat = 200
        let paddingYBottom: CGFloat = 250
        let buffer: CGFloat = 10

        for char in word.map({ String($0) }) {
            var newPosition: CGPoint
            var rect: CGRect
            var attempt = 0
            var circleSize: CGFloat = 50
            repeat {
                circleSize = CGFloat.random(in: 48...64)
                let x = CGFloat.random(in: paddingX...(size.width - paddingX))
                let y = CGFloat.random(in: paddingYTop...(size.height - paddingYBottom))
                newPosition = CGPoint(x: x, y: y)
                rect = CGRect(x: x - circleSize/2 - buffer / 2, y: y - circleSize/2 - buffer / 2, width: circleSize + buffer, height: circleSize + buffer)
                attempt += 1
                if attempt > 100 { break }
            } while usedRects.contains(where: { $0.intersects(rect) })

            if attempt <= 100 {
                usedRects.append(rect)
                let velocity = CGVector(dx: Double.random(in: -1.2...1.2), dy: Double.random(in: -1.2...1.2))
                result.append(CharacterCircle(char: char, position: newPosition, size: circleSize, velocity: velocity))
            } else {
                print("⚠️ Elhelyezés sikertelen: \(char)")
            }
        }
        return result
    }

    func updateCharacterPositions(in size: CGSize) {
        let bounds = CGRect(x: 30, y: 120, width: size.width - 60, height: size.height - 250)
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}