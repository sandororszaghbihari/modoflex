import SwiftUI

struct StartView: View {
    @State private var showSplash = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "bolt.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(showSplash ? 360 : 0))
                    .animation(.easeInOut(duration: 2), value: showSplash)

                Text("ModoFlex")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showSplash = true
            }
        }
        .fullScreenCover(isPresented: $showSplash) {
            SplashView()
        }
    }
}
