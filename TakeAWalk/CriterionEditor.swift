import SwiftUI

/// Popup for one attribute: an "Inactive" checkbox, an ideal range, and OK / Cancel.
struct CriterionEditor: View {
    @State private var draft: Criterion
    let onSave: (Criterion) -> Void
    @Environment(\.dismiss) private var dismiss

    init(criterion: Criterion, onSave: @escaping (Criterion) -> Void) {
        _draft = State(initialValue: criterion)
        self.onSave = onSave
    }

    private var attribute: Attribute { draft.attribute }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Active", isOn: Binding(
                        get: { draft.isActive },
                        set: { draft.isActive = $0 }
                    ))
                } footer: {
                    Text("Only active attributes count toward whether conditions are ideal.")
                }

                if attribute.isBoolean {
                    Section {
                        Text("Ideal conditions require daylight.")
                    }
                } else {
                    Section {
                        rangeBar
                    } header: {
                        Text("Ideal range (\(attribute.unit))")
                    } footer: {
                        Text("\(attribute.format(draft.lower)) to \(attribute.format(draft.upper))")
                    }
                }
            }
            .navigationTitle(attribute.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }

    /// Lower and upper bound sliders. Each keeps the other on the correct side.
    private var rangeBar: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Lower: \(attribute.format(draft.lower))").font(.caption)
                Slider(
                    value: Binding(
                        get: { draft.lower },
                        set: { draft.lower = min($0, draft.upper) }
                    ),
                    in: attribute.sliderRange
                )
            }
            VStack(alignment: .leading) {
                Text("Upper: \(attribute.format(draft.upper))").font(.caption)
                Slider(
                    value: Binding(
                        get: { draft.upper },
                        set: { draft.upper = max($0, draft.lower) }
                    ),
                    in: attribute.sliderRange
                )
            }
        }
        .disabled(!draft.isActive)
    }
}
