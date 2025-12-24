# Versión Avanzada - Cloud-First con Autenticación

> **Objetivo:** Transformar la app en una experiencia cloud-first con gestión de usuarios, sincronización y seguridad robusta.

---

## 📋 Requisitos según PDF

La versión avanzada debe incluir:

1. ✅ **Todo lo de versiones anteriores**
   - Ver [versionBasica.md](versionBasica.md) y [versionMedia.md](versionMedia.md)

2. ⏳ **Gestión en la nube de la colección del usuario**
   - POST `/collection/manga` - Crear/actualizar manga en colección
   - GET `/collection/manga` - Obtener colección completa
   - GET `/collection/manga/<mangaID>` - Obtener manga específico
   - DELETE `/collection/manga/<mangaID>` - Eliminar de colección

3. ⏳ **Flujo de creación y login de usuarios**
   - POST `/users` - Registro con email y password
   - POST `/users/login` - Login con autenticación básica
   - POST `/users/renew` - Renovar token

4. ⏳ **Almacenamiento seguro de credenciales**
   - Token en Keychain (NO UserDefaults)
   - Credenciales opcionales en Keychain

5. ⏳ **Persistencia local opcional**
   - Puede mantenerse para modo offline
   - Sincronización bidireccional

---

## 🔐 Arquitectura de Autenticación

### Estado de Autenticación

```swift
@Observable
final class AuthenticationManager {
    var currentUser: User?
    var isAuthenticated = false
    var authToken: String?

    private let keychain = KeychainHelper()
    private let repository = NetworkRepository()

    init() {
        // Intentar cargar token guardado
        loadSavedSession()
    }

    func loadSavedSession() {
        if let token = keychain.getToken() {
            authToken = token
            isAuthenticated = true
            // Opcional: validar token con API
        }
    }

    func register(email: String, password: String) async throws {
        // Validar formato
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.passwordTooShort
        }

        let users = Users(email: email, password: password)
        try await repository.registerUser(users)

        // Después del registro exitoso, hacer login
        try await login(email: email, password: password)
    }

    func login(email: String, password: String) async throws {
        let token = try await repository.login(email: email, password: password)

        // Guardar en Keychain
        keychain.saveToken(token)
        authToken = token
        isAuthenticated = true

        // Opcional: guardar email para auto-login
        keychain.saveEmail(email)
    }

    func renewToken() async throws {
        guard let currentToken = authToken else {
            throw AuthError.noToken
        }

        let newToken = try await repository.renewToken(currentToken)
        keychain.saveToken(newToken)
        authToken = newToken
    }

    func logout() {
        keychain.deleteToken()
        keychain.deleteEmail()
        authToken = nil
        isAuthenticated = false
        currentUser = nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case noToken
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "El email no es válido"
        case .passwordTooShort:
            return "La contraseña debe tener al menos 8 caracteres"
        case .noToken:
            return "No hay token de autenticación"
        case .tokenExpired:
            return "La sesión ha expirado. Por favor, vuelve a iniciar sesión"
        }
    }
}
```

---

## 🔑 Keychain Helper

```swift
import Security
import Foundation

final class KeychainHelper {
    private let tokenKey = "com.mismangas.authToken"
    private let emailKey = "com.mismangas.userEmail"

    // MARK: - Token Management

    func saveToken(_ token: String) {
        save(key: tokenKey, value: token)
    }

    func getToken() -> String? {
        get(key: tokenKey)
    }

    func deleteToken() {
        delete(key: tokenKey)
    }

    // MARK: - Email Management

    func saveEmail(_ email: String) {
        save(key: emailKey, value: email)
    }

    func getEmail() -> String? {
        get(key: emailKey)
    }

    func deleteEmail() {
        delete(key: emailKey)
    }

    // MARK: - Private Methods

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Eliminar cualquier valor existente
        SecItemDelete(query as CFDictionary)

        // Añadir el nuevo valor
        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

---

## 📱 Vistas de Autenticación

### LoginView

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button("Iniciar Sesión") {
                        Task {
                            await login()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)

                    NavigationLink("Crear cuenta nueva") {
                        RegisterView()
                    }
                }
            }
            .navigationTitle("Iniciar Sesión")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }

    private func login() async {
        isLoading = true

        do {
            try await authManager.login(email: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}
```

### RegisterView

```swift
struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("Contraseña", text: $password)
                    .textContentType(.newPassword)

                SecureField("Confirmar contraseña", text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                Text("La contraseña debe tener al menos 8 caracteres")
            }

            Section {
                Button("Crear Cuenta") {
                    Task {
                        await register()
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("Crear Cuenta")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private func register() async {
        isLoading = true

        do {
            try await authManager.register(email: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}
```

---

## ☁️ Cloud Collection Manager

```swift
@Observable
final class CloudCollectionManager {
    var cloudCollection: [UserMangaCollection] = []
    var isLoading = false
    var errorMessage: String?

    private let repository = NetworkRepository()
    private let authManager: AuthenticationManager

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    func loadCollection() async {
        guard let token = authManager.authToken else {
            errorMessage = "No estás autenticado"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            cloudCollection = try await repository.getUserCollection(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addToCollection(_ manga: Manga, volumes: [Int], readingVolume: Int?, complete: Bool) async {
        guard let token = authManager.authToken else { return }

        let request = UserMangaCollectionRequest(
            manga: manga.id,
            completeCollection: complete,
            volumesOwned: volumes,
            readingVolume: readingVolume
        )

        do {
            try await repository.addToCollection(request, token: token)
            await loadCollection() // Recargar
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFromCollection(_ mangaId: Int) async {
        guard let token = authManager.authToken else { return }

        do {
            try await repository.deleteFromCollection(mangaId: mangaId, token: token)
            cloudCollection.removeAll { $0.id == mangaId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isInCollection(_ mangaId: Int) -> Bool {
        cloudCollection.contains { $0.manga.id == mangaId }
    }
}
```

---

## 🔄 Sincronización Local/Cloud

### SyncManager (Opcional para modo offline)

```swift
@Observable
final class SyncManager {
    var isSyncing = false
    var lastSyncDate: Date?

    private let localStorage = LocalStorageManager()
    private let cloudManager: CloudCollectionManager

    init(cloudManager: CloudCollectionManager) {
        self.cloudManager = cloudManager
    }

    func syncCollections() async {
        isSyncing = true

        // 1. Obtener colección cloud
        await cloudManager.loadCollection()

        // 2. Comparar con local
        let localItems = localStorage.collection
        let cloudItems = cloudManager.cloudCollection

        // 3. Decidir estrategia de conflicto (cloud wins, local wins, merge, etc.)
        // Para simplificar: Cloud wins
        await syncCloudToLocal(cloudItems)

        lastSyncDate = Date()
        isSyncing = false
    }

    private func syncCloudToLocal(_ cloudItems: [UserMangaCollection]) async {
        // Convertir cloud items a local format
        // Guardar en local
    }
}
```

---

## 📦 Actualizar NetworkRepository

Añadir métodos de autenticación y colección:

```swift
// En NetworkRepository

// MARK: - Authentication

func registerUser(_ users: Users) async throws {
    try await post(.post(url: .users, body: users, headers: ["App-Token": "sLGH38NhEJ0_anlIWwhsz1-LarClEohiAHQqayF0FY"]))
}

func login(email: String, password: String) async throws -> String {
    let credentials = "\(email):\(password)"
    guard let credentialData = credentials.data(using: .utf8) else {
        throw NetworkError.invalidCredentials
    }
    let base64Credentials = credentialData.base64EncodedString()
    let headers = ["Authorization": "Basic \(base64Credentials)"]

    let response: TokenResponse = try await getJSON(.get(url: .usersLogin, headers: headers), type: TokenResponse.self)
    return response.token
}

func renewToken(_ currentToken: String) async throws -> String {
    let headers = ["Authorization": "Bearer \(currentToken)"]
    let response: TokenResponse = try await postJSON(.post(url: .usersRenew, headers: headers), type: TokenResponse.self)
    return response.token
}

// MARK: - Cloud Collection

func getUserCollection(token: String) async throws -> [UserMangaCollection] {
    try await getJSON(.get(url: .collectionManga), type: [UserMangaCollection].self, token: token)
}

func addToCollection(_ request: UserMangaCollectionRequest, token: String) async throws {
    try await post(.post(url: .collectionManga, body: request), token: token)
}

func deleteFromCollection(mangaId: Int, token: String) async throws {
    try await delete(.delete(url: .collectionManga(byId: mangaId)), token: token)
}
```

---

## 📋 Checklist de Entrega - Versión Avanzada

### Funcionalidades Core
- [ ] Todo de versión media completado
- [ ] Registro de usuarios funcional
- [ ] Login de usuarios funcional
- [ ] Logout y limpieza de sesión
- [ ] Token guardado en Keychain
- [ ] Renovación automática de token (cada 2 días)
- [ ] Colección guardada en la nube
- [ ] CRUD completo de colección cloud
- [ ] Sincronización local/cloud (opcional)
- [ ] Manejo de sesión expirada

### Seguridad
- [ ] Tokens SOLO en Keychain
- [ ] NUNCA en UserDefaults
- [ ] Headers de autenticación correctos
- [ ] Validación de email y password
- [ ] Manejo de errores 401/403

### UI/UX
- [ ] LoginView bien diseñado
- [ ] RegisterView con validaciones
- [ ] Indicador de sesión activa
- [ ] Botón de logout accesible
- [ ] Estados de loading en auth
- [ ] Mensajes de error claros

---

## 🎯 Orden de Implementación Recomendado

### Día 1 - Keychain y Auth Manager
1. Crear `KeychainHelper`
2. Crear `AuthenticationManager`
3. Testing de Keychain
4. Implementar métodos de auth en Repository

### Día 2 - UI de Autenticación
1. Crear `LoginView`
2. Crear `RegisterView`
3. Integrar en app (sheet o fullScreenCover)
4. Testing de flujo completo

### Día 3 - Cloud Collection
1. Crear `CloudCollectionManager`
2. Actualizar `MangaDetailView` con botón cloud
3. Implementar CRUD de colección
4. Testing de operaciones

### Día 4 - Integración y Sync
1. Decidir estrategia: solo cloud o local+cloud
2. Si local+cloud, implementar `SyncManager`
3. Auto-renovación de token
4. Manejo de sesión expirada

### Día 5 - Polish y Testing
1. Testing exhaustivo de auth
2. Testing de colección cloud
3. Manejo de casos edge
4. UI polish

---

## ✨ Criterios de Éxito

La versión avanzada estará completa cuando:

✅ Un usuario puede:
1. Registrarse con email y contraseña
2. Iniciar sesión y obtener token
3. Token se guarda en Keychain automáticamente
4. Cerrar sesión y limpiar datos
5. Añadir mangas a su colección en la nube
6. Ver su colección desde cualquier dispositivo
7. Editar o eliminar mangas de colección cloud
8. Token se renueva automáticamente
9. Recibir mensajes claros si sesión expira

✅ La seguridad:
1. Tokens SOLO en Keychain
2. Contraseñas nunca guardadas en plano
3. Manejo correcto de headers de auth
4. Validaciones robustas

✅ El código:
1. Mantiene Clean Architecture
2. AuthenticationManager es @Observable
3. Error handling robusto
4. Es testable y mantenible

---

**Anterior:** [← Versión Media](versionMedia.md)
**Siguiente:** [Versión Deluxe →](versionDeluxe.md)
