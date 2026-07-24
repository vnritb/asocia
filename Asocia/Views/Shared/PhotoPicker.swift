import SwiftUI
import PhotosUI

/// Selector de fotografia del soci: mostra un avatar circular i, en tocar-lo,
/// deixa triar entre fer una foto amb la càmera o triar-la de la galeria.
///
/// La galeria s'implementa amb `PhotosPicker` (framework PhotosUI, iOS 16+),
/// que s'executa fora de procés i per tant NO requereix
/// `NSPhotoLibraryUsageDescription`. La càmera necessita `UIImagePickerController`
/// (encara no hi ha equivalent nadiu en SwiftUI) i sí que requereix
/// `NSCameraUsageDescription` (ja afegit a `project.yml`).
struct MemberPhotoPicker: View {
    @Binding var photoData: Data?

    @Environment(LocalizationManager.self) private var loc

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        let addPhotoText = loc.t("photoPicker.add")
        let changePhotoText = loc.t("photoPicker.change")
        let dialogTitle = loc.t("photoPicker.dialogTitle")
        let takePhotoText = loc.t("photoPicker.takePhoto")
        let chooseGalleryText = loc.t("photoPicker.chooseGallery")
        let removeText = loc.t("photoPicker.remove")
        let cancelText = loc.t("common.cancel")
        
        VStack(spacing: 10) {
            Button {
                showSourceDialog = true
            } label: {
                avatar
            }
            .buttonStyle(.plain)

            Button(photoData == nil ? addPhotoText : changePhotoText) {
                showSourceDialog = true
            }
            .font(.footnote)
        }
        .confirmationDialog(dialogTitle, isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button(takePhotoText) { showCamera = true }

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Text(chooseGalleryText)
            }

            if photoData != nil {
                Button(removeText, role: .destructive) { photoData = nil }
            }
            Button(cancelText, role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                if let image {
                    photoData = ImageCompression.jpegData(from: image)
                }
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .task(id: photosPickerItem) {
            guard let item = photosPickerItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            photoData = ImageCompression.jpegData(from: uiImage)
            photosPickerItem = nil
        }
    }

    @ViewBuilder
    private var avatar: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color(.systemGray5))
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 1))
    }
}

/// Wrapper de `UIImagePickerController` per capturar una foto amb la
/// càmera (no hi ha alternativa nativa en SwiftUI a data d'avui).
private struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onCapture(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
        }
    }
}

enum ImageCompression {
    /// Redimensiona i comprimeix a JPEG per no inflar la base de dades ni
    /// el payload de xarxa (la foto es guarda amb `.externalStorage` a
    /// SwiftData, però igualment val la pena no pujar imatges de 12 MP).
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 800, quality: CGFloat = 0.7) -> Data? {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

#Preview {
    MemberPhotoPicker(photoData: .constant(nil))
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}
