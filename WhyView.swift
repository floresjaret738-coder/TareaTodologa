import SwiftUI

struct WhyView: View {
    let solution: TaskSolution
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Te explico la idea detrás de la solución, sin complicarla.")
                    .foregroundStyle(.secondary)
                WhyCard(why: solution.why)
                StepsCard(steps: solution.steps)
            }
            .padding()
        }
        .navigationTitle("¿Por qué?")
    }
}
