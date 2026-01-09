import SwiftUI
import SwiftData

struct EditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State var content: String
    var originalItem: ClipboardItem

    var body: some View {
        VStack(alignment: .leading) {
            Text("Edit Clipboard Item")
                .font(.headline)
                .padding(.bottom, 8)

            TextEditor(text: $content)
                .font(.body)
                .padding(4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
                .frame(minHeight: 150)

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save Copy") {
                    saveAndCopy()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func saveAndCopy() {
        // Create new item
        let newItem = ClipboardItem(
            content: content,
            timestamp: Date(),
            sourceAppBundleID: originalItem.sourceAppBundleID,
            sourceAppName: originalItem.sourceAppName,
            isPinned: originalItem.isPinned
        )

        // Delete old one (as per requirements: "Editing will create a new clipboard entry and delete the old one")
        modelContext.delete(originalItem)
        modelContext.insert(newItem)

        dismiss()
    }
}
