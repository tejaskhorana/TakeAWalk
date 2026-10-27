import SwiftUI

struct AttributeCircle: Identifiable {
    let name: String
    let color: Color
    var id: String { name }
}

// Placeholder: one solid color per attribute. The meaning of color is deferred (see PRODUCT.md).
// Green is avoided so attribute circles never read as the "ideal" signal.
let attributeCircles: [AttributeCircle] = [
    AttributeCircle(name: "Actual temp", color: .red),
    AttributeCircle(name: "Perceived temp", color: .orange),
    AttributeCircle(name: "Cloud cover", color: .gray),
    AttributeCircle(name: "Humidity", color: .blue),
    AttributeCircle(name: "Precip intensity", color: .indigo),
    AttributeCircle(name: "Precip chance", color: .cyan),
    AttributeCircle(name: "Wind speed", color: .teal),
    AttributeCircle(name: "Wind gust", color: .purple),
    AttributeCircle(name: "UV index", color: .yellow),
    AttributeCircle(name: "Visibility", color: .brown),
    AttributeCircle(name: "Pressure", color: .pink),
    AttributeCircle(name: "Dew point", color: Color(.systemGray3)),
]

struct ContentView: View {
    @State private var model = WeatherViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Circle()
                    .fill(model.isIdeal ? Color.green : Color.clear)
                    .overlay(Circle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 2))
                    .frame(width: 220, height: 220)
                    .padding(.top, 24)
                    .accessibilityLabel(model.isIdeal ? "Conditions are ideal" : "Conditions are not ideal")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
                    ForEach(attributeCircles) { attribute in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(attribute.color)
                                .frame(width: 48, height: 48)
                            Text(attribute.name)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let updated = model.lastUpdated {
                    Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .refreshable { await model.refresh() }
        .task { await model.refresh() }
    }
}
