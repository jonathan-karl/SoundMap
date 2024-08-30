import SwiftUI

struct AnimatedLaunchScreen: View {
    @State private var isAnimating = false
    @State private var loadingProgress = 0.0

    let icons = ["music.note", "waveform", "speaker.wave.3", "ear", "mic", "headphones"]
    var onFinishedLoading: () -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                VStack(spacing: 10) {
                    Text("Soundmap")
                        .font(.system(size: 34, weight: .bold, design: .default))

                    Text("Mapping noise levels across cafés, restaurants and bars")
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeIn(duration: 0.8), value: isAnimating)

                Spacer()

                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(0..<icons.count, id: \.self) { index in
                        Image(systemName: icons[index])
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: isAnimating
                            )
                            .offset(y: isAnimating ? -5 : 5)
                    }
                }
                .frame(width: 200, height: 200)

                Spacer()

                ProgressView(value: loadingProgress, total: 1.0)
                    .frame(width: 200)
                    .animation(.linear(duration: 0.1), value: loadingProgress)

                Text("Loading...")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .padding(.top, 8)

                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            startLoading()
        }
    }

    func startLoading() {
        // Simulate app initialization tasks
        DispatchQueue.global(qos: .userInitiated).async {
            // Perform any necessary initialization tasks here
            // For example, loading data, setting up services, etc.

            // Simulate progress
            for _ in 1...20 {
                DispatchQueue.main.async {
                    withAnimation {
                        loadingProgress += 0.05
                    }
                }
                Thread.sleep(forTimeInterval: 0.05) // Simulating work being done
            }

            // Ensure we reach 100% progress
            DispatchQueue.main.async {
                withAnimation {
                    loadingProgress = 1.0
                }
                // Small delay to ensure animations complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onFinishedLoading()
                }
            }
        }
    }
}

struct AnimatedLaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedLaunchScreen(onFinishedLoading: {})
    }
}
