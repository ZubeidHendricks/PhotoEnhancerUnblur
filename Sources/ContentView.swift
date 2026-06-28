import SwiftUI
import PhotosUI
import AppFactoryKit

// Photo Enhancer & Unblur — pick a soft/low-res photo and sharpen + upscale it
// on-device. Press and hold to compare. Pro unlocks 4× upscale and saving.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    private let service: PhotoEnhancing = OnDeviceEnhancer()

    @State private var pickerItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var strength = 0.6
    @State private var showingOriginal = false
    @State private var isProcessing = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    preview
                    if inputImage != nil {
                        HStack { Image(systemName: "dial.low"); Slider(value: $strength, in: 0...1); Image(systemName: "dial.high") }
                        actions
                    } else { picker }
                    if let errorText { Text(errorText).font(.footnote).foregroundStyle(.red) }
                }
                .padding(20)
            }
            .navigationTitle("Enhance")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(.quaternary)
            if let shown = (showingOriginal ? inputImage : (outputImage ?? inputImage)) {
                Image(uiImage: shown).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 18))
                    .gesture(LongPressGesture(minimumDuration: 0.01).sequenced(before: DragGesture(minimumDistance: 0))
                        .onChanged { _ in if outputImage != nil { showingOriginal = true } }
                        .onEnded { _ in showingOriginal = false })
            } else {
                VStack(spacing: 10) { Image(systemName: "sparkle.magnifyingglass").font(.system(size: 52)).foregroundStyle(.purple); Text("Pick a photo to enhance").foregroundStyle(.secondary) }
            }
            if isProcessing { ProgressView().controlSize(.large) }
        }
        .frame(height: 360)
    }

    private var picker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Choose Photo", systemImage: "photo").frame(maxWidth: .infinity, minHeight: 52)
        }.buttonStyle(.borderedProminent).tint(.purple)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button { Task { await enhance(upscale: 2) } } label: {
                Label("Enhance", systemImage: "wand.and.stars").frame(maxWidth: .infinity, minHeight: 50)
            }.buttonStyle(.borderedProminent).tint(.purple).disabled(isProcessing)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose Another", systemImage: "photo").frame(maxWidth: .infinity, minHeight: 46)
            }.buttonStyle(.bordered)

            if outputImage != nil {
                Button { factory.requirePremium(feature: "save_4x") { Task { await enhance(upscale: 4); save() } } } label: {
                    Label("Save 4× (Pro)", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 46)
                }.buttonStyle(.bordered)
            }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        errorText = nil
        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
            inputImage = img; outputImage = nil
            await enhance(upscale: 2)
        } else { errorText = "Couldn't load that photo." }
    }

    private func enhance(upscale: Int) async {
        guard let inputImage else { return }
        isProcessing = true; errorText = nil
        defer { isProcessing = false }
        do { outputImage = try await service.enhance(inputImage, strength: strength, upscale: upscale) }
        catch { errorText = "Enhance failed." }
    }

    private func save() {
        guard let outputImage else { return }
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
    }
}
