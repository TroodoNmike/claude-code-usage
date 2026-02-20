import SwiftUI

struct ProgressBarView: View {
    let percentage: Int
    let height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Config.usageColor(for: percentage))
                    .frame(width: geo.size.width * CGFloat(min(percentage, 100)) / 100)
            }
        }
        .frame(height: height)
    }
}
