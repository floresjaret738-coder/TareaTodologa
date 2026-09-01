import SwiftUI
import UIKit

struct SolvedSheetView: View {
    let solution: TaskSolution
    let image: UIImage
    @State private var showOriginal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Vista", selection: $showOriginal) {
                    Text("Resuelta").tag(false)
                    Text("Original").tag(true)
                }
                .pickerStyle(.segmented)

                SheetCanvas(image: image, solution: solution, showOriginal: showOriginal)
                    .frame(maxWidth: .infinity)

                if showOriginal {
                    Text("Las cajas azules muestran las zonas de texto detectadas por OCR.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if solution.annotations.isEmpty {
                    GlassCard {
                        Label("Sin anotaciones de la IA", systemImage: "rectangle.dashed")
                            .font(.headline)
                        Text("La solución no indicó posiciones concretas para las respuestas, así que no se colocan respuestas arbitrariamente sobre la hoja.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Las respuestas se muestran únicamente en las posiciones devueltas por la IA.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                StepsCard(steps: solution.steps)
            }
            .padding()
        }
        .navigationTitle("Ver resuelto")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SheetCanvas: View {
    let image: UIImage
    let solution: TaskSolution
    let showOriginal: Bool

    var body: some View {
        GeometryReader { proxy in
            let fitted = fittedRect(imageSize: image.size, containerSize: proxy.size)
            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)

                if showOriginal {
                    ForEach(solution.ocrItems) { item in
                        let box = overlay(for: item.normalizedRect.cgRect, in: fitted)
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.blue, lineWidth: 1.5)
                            .frame(width: box.width, height: box.height)
                            .position(x: box.midX, y: box.midY)
                    }
                } else {
                    ForEach(solution.annotations) { annotation in
                        annotationView(annotation, in: fitted)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.08)))
        }
        .aspectRatio(max(image.size.width, 1) / max(image.size.height, 1), contentMode: .fit)
    }

    private func annotationView(_ annotation: WorksheetAnnotation, in rect: CGRect) -> some View {
        let box = overlay(for: annotation.rect.cgRect, in: rect)
        return Text(annotation.answer)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .padding(7)
            .background(.green.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
            .position(x: box.midX, y: box.midY)
    }

    private func overlay(for normalized: CGRect, in fitted: CGRect) -> CGRect {
        let r = normalized.standardized
        let x = fitted.minX + r.minX * fitted.width
        let y = fitted.minY + (1 - r.maxY) * fitted.height
        return CGRect(
            x: x,
            y: y,
            width: max(4, r.width * fitted.width),
            height: max(4, r.height * fitted.height)
        )
    }

    private func fittedRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}
