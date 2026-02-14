import SwiftUI

struct ToastView: View {
    let message: String
    let symbolName: String

    init(message: String = "Copied", symbolName: String = "checkmark.circle.fill") {
        self.message = message
        self.symbolName = symbolName
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 16))
                .foregroundStyle(Color.green)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ToastView()
        .padding()
        .background(Color.gray)
}
