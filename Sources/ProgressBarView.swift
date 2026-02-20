import SwiftUI

struct ProgressBarView: View {
    let percentage: Int
    var daysLeft: Int? = nil
    let height: CGFloat = 8

    private var barColor: Color {
        if daysLeft != nil {
            return Config.weeklyUsageColor(pct: percentage, daysLeft: daysLeft)
        }
        return Config.usageColor(for: percentage)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(min(percentage, 100)) / 100)
            }
        }
        .frame(height: height)
    }
}
