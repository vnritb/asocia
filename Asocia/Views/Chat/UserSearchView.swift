import SwiftUI

/// Buscador de socios para abrir (o crear) una conversación individual.
///
/// Regla de negocio: solo puede existir una conversación individual por
/// pareja de usuarios. `chatService.openOrCreateIndividualConversation` se
/// encarga de devolver la ya existente si ya la había, en vez de duplicarla.
/// 
/// Implementa scroll infinito con paginación para manejar grandes cantidades de usuarios.
struct UserSearchView: View {
    var onOpenConversation: (Conversation) -> Void

    @Environment(\.chatService) private var chatService
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var query = ""
    @State private var results: [ChatUser] = []
    @State private var currentPage = 0
    @State private var hasMore = true
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var isOpening = false
    @State private var errorMessage: String?
    
    private let pageSize = 10

    var body: some View {
        NavigationStack {
            List {
                ForEach(results) { user in
                    Button {
                        Task { await open(user) }
                    } label: {
                        HStack(spacing: 12) {
                            avatar(for: user)
                            Text(user.fullName)
                            Spacer()
                            if isOpening {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isOpening)
                    .onAppear {
                        // Cargar más cuando lleguemos a los últimos 3 elementos
                        if results.last?.id == user.id && hasMore && !isLoadingMore {
                            Task { await loadMore() }
                        }
                    }
                }
                
                // Indicador de carga al final
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .overlay {
                if results.isEmpty && !isLoading {
                    ContentUnavailableView.search(text: query)
                } else if isLoading {
                    ProgressView()
                }
            }
            .searchable(text: $query, prompt: loc.t("userSearch.prompt"))
            .navigationTitle(loc.t("userSearch.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.close")) { dismiss() }
                }
            }
            .task(id: query) { 
                await resetAndSearch() 
            }
            .alert(loc.t("userSearch.errorTitle"), isPresented: .constant(errorMessage != nil), actions: {
                Button(loc.t("common.ok")) { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }
    
    /// Resetea la búsqueda y carga la primera página
    private func resetAndSearch() async {
        isLoading = true
        currentPage = 0
        results = []
        hasMore = true
        
        let response = await chatService.searchDirectory(query: query, page: 0, pageSize: pageSize)
        results = response.users
        hasMore = response.hasMore
        isLoading = false
        
        #if DEBUG
        print("🔍 Búsqueda: '\(query)' - \(results.count) resultados, hasMore: \(hasMore)")
        #endif
    }
    
    /// Carga la siguiente página
    private func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        let response = await chatService.searchDirectory(query: query, page: currentPage, pageSize: pageSize)
        results.append(contentsOf: response.users)
        hasMore = response.hasMore
        isLoadingMore = false
        
        #if DEBUG
        print("📄 Página \(currentPage) cargada: +\(response.users.count) usuarios, total: \(results.count), hasMore: \(hasMore)")
        #endif
    }

    private func open(_ user: ChatUser) async {
        isOpening = true
        defer { isOpening = false }
        do {
            let conversation = try await chatService.openOrCreateIndividualConversation(with: user.id)
            onOpenConversation(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func avatar(for user: ChatUser) -> some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.2))
            if let data = user.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Text(String(user.fullName.prefix(1)))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}

#Preview {
    UserSearchView { _ in }
        .environment(LocalizationManager())
}
