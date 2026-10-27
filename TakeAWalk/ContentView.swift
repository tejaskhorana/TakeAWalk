import SwiftUI

/// Two tabs: live conditions, and the logs saved from the widget.
struct ContentView: View {
    var body: some View {
        TabView {
            ConditionsView()
                .tabItem { Label("Conditions", systemImage: "circle.grid.2x2") }

            LogsView()
                .tabItem { Label("Logs", systemImage: "list.bullet") }
        }
    }
}

struct ConditionsView: View {
    @State private var model = WeatherViewModel()
    @State private var editing: Criterion?

    /// Active criteria first. Each group keeps its original order.
    private var sortedCriteria: [Criterion] {
        model.criteria.enumerated()
            .sorted { a, b in
                let ra = a.element.isActive ? 0 : 1
                let rb = b.element.isActive ? 0 : 1
                return (ra, a.offset) < (rb, b.offset)
            }
            .map(\.element)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatusDoor(isIdeal: model.isIdeal, size: 143)
                    .padding(.top, 24)
                    .accessibilityLabel(model.isIdeal ? "Conditions are ideal" : "Conditions are not ideal")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 20) {
                    ForEach(sortedCriteria) { criterion in
                        Button {
                            editing = criterion
                        } label: {
                            AttributeTile(
                                title: criterion.attribute.title,
                                value: displayValue(for: criterion.attribute),
                                status: model.status(of: criterion)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(.snappy, value: model.criteria.map(\.isActive))

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .refreshable { await model.refresh() }
        .task { await model.refresh() }
        .safeAreaInset(edge: .bottom) {
            if let updated = model.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 28)
            }
        }
        .sheet(item: $editing) { criterion in
            CriterionEditor(criterion: criterion) { updated in
                model.update(updated)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func displayValue(for attribute: Attribute) -> String {
        guard let v = model.freshValues?[attribute.rawValue] else { return "—" }
        return attribute.format(v)
    }
}

/// Green in range, red out of range, grey when inactive or without data.
struct AttributeTile: View {
    let title: String
    let value: String
    let status: IdealRule.Status

    private var fill: Color {
        switch status {
        case .inRange: return .green
        case .outOfRange: return .red
        case .inactive, .unknown: return Color(.systemGray3)
        }
    }

    /// Check for in range, cross for out of range. Nothing for inactive or no data.
    private var mark: (symbol: String, color: Color)? {
        switch status {
        case .inRange: return ("checkmark.circle.fill", .green)
        case .outOfRange: return ("xmark.circle.fill", .red)
        case .inactive, .unknown: return nil
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(fill)
                    Text(value)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(8)
                }
                .frame(width: 76, height: 76)

                if let mark {
                    Image(systemName: mark.symbol)
                        .font(.system(size: 18))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, mark.color)
                        .offset(x: 4, y: -4)
                }
            }

            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}
