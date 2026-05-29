import Foundation
import Combine

@MainActor
final class AllergyListViewModel: ObservableObject {

    // MARK: - Display State

    @Published var entries: [AllergyEntry] = []

    // MARK: - Sheet State

    @Published var showAddSheet: Bool = false
    @Published var editingEntry: AllergyEntry? = nil
    @Published var inputAllergen: String = ""
    @Published var inputCategory: AllergyCategory = .medication
    @Published var inputSeverity: AllergySeverity = .moderate
    @Published var inputReactionDescription: String = ""
    @Published var inputCarriesEpiPen: Bool = false
    @Published var validationError: String? = nil

    // MARK: - Undo State

    @Published var undoBannerVisible: Bool = false
    private var pendingDelete: (entry: AllergyEntry, index: Int)? = nil
    private var undoTask: Task<Void, Never>? = nil

    // MARK: - Change Tracking

    private let originalEntries: [AllergyEntry]
    var hasChanges: Bool { entries != originalEntries }

    // MARK: - Derived

    var hasAnaphylacticEntry: Bool {
        entries.contains { $0.severity == .anaphylactic }
    }

    var epiPenAvailable: Bool {
        entries.contains { $0.carriesEpiPen && $0.severity >= .severe }
    }

    var countByCategory: [AllergyCategory: Int] {
        Dictionary(grouping: entries, by: { $0.category }).mapValues { $0.count }
    }

    // MARK: - Init

    init(initialEntries: [AllergyEntry] = []) {
        let sorted = AllergyStore.sorted(initialEntries)
        self.entries = sorted
        self.originalEntries = sorted
    }

    // MARK: - Add / Edit

    func startAdd() {
        editingEntry = nil
        inputAllergen = ""
        inputCategory = .medication
        inputSeverity = .moderate
        inputReactionDescription = ""
        inputCarriesEpiPen = false
        validationError = nil
        showAddSheet = true
    }

    func startEdit(_ entry: AllergyEntry) {
        editingEntry = entry
        inputAllergen = entry.allergen
        inputCategory = entry.category
        inputSeverity = entry.severity
        inputReactionDescription = entry.reactionDescription
        inputCarriesEpiPen = entry.carriesEpiPen
        validationError = nil
        showAddSheet = true
    }

    func commitInput() {
        let trimmed = inputAllergen.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            validationError = "Allergen name cannot be empty."
            return
        }

        let trimmedDesc = inputReactionDescription.trimmingCharacters(in: .whitespaces)
        let epiPen = inputCarriesEpiPen && inputSeverity >= .severe

        if let existing = editingEntry,
           let idx = entries.firstIndex(where: { $0.id == existing.id }) {
            entries[idx].allergen = trimmed
            entries[idx].category = inputCategory
            entries[idx].severity = inputSeverity
            entries[idx].reactionDescription = trimmedDesc
            entries[idx].carriesEpiPen = epiPen
        } else {
            entries.append(AllergyEntry(
                allergen: trimmed,
                category: inputCategory,
                severity: inputSeverity,
                reactionDescription: trimmedDesc,
                carriesEpiPen: epiPen
            ))
        }

        entries = AllergyStore.sorted(entries)
        showAddSheet = false
        validationError = nil
    }

    func cancelInput() {
        showAddSheet = false
        validationError = nil
    }

    // MARK: - Delete with Undo

    func requestDelete(at offsets: IndexSet) {
        guard let idx = offsets.first else { return }
        let deleted = entries[idx]
        entries.remove(at: idx)

        commitPendingDelete()
        pendingDelete = (entry: deleted, index: idx)
        undoBannerVisible = true

        undoTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self, !Task.isCancelled else { return }
            self.commitPendingDelete()
        }
    }

    func undoDelete() {
        guard let pending = pendingDelete else { return }
        let insertIdx = min(pending.index, entries.count)
        entries.insert(pending.entry, at: insertIdx)
        entries = AllergyStore.sorted(entries)
        pendingDelete = nil
        undoBannerVisible = false
        undoTask?.cancel()
        undoTask = nil
    }

    private func commitPendingDelete() {
        pendingDelete = nil
        undoBannerVisible = false
        undoTask?.cancel()
        undoTask = nil
    }
}
