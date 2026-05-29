import Foundation
import Combine

@MainActor
final class MedicationListViewModel: ObservableObject {

    // MARK: - Display State

    @Published var entries: [MedicationEntry] = []

    // MARK: - Sheet State

    @Published var showAddSheet: Bool = false
    @Published var editingEntry: MedicationEntry? = nil
    @Published var inputName: String = ""
    @Published var inputNote: String = ""
    @Published var validationError: String? = nil

    // MARK: - Undo State

    @Published var undoBannerVisible: Bool = false
    private var pendingDelete: (entry: MedicationEntry, index: Int)? = nil
    private var undoTask: Task<Void, Never>? = nil

    // MARK: - Change Tracking

    private let originalEntries: [MedicationEntry]
    var hasChanges: Bool { entries != originalEntries }

    // MARK: - Init

    init(initialEntries: [MedicationEntry] = []) {
        self.entries = initialEntries
        self.originalEntries = initialEntries
    }

    // MARK: - Add / Edit

    func startAdd() {
        editingEntry = nil
        inputName = ""
        inputNote = ""
        validationError = nil
        showAddSheet = true
    }

    func startEdit(_ entry: MedicationEntry) {
        editingEntry = entry
        inputName = entry.name
        inputNote = entry.note
        validationError = nil
        showAddSheet = true
    }

    func commitInput() {
        let trimmedName = inputName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Medication name cannot be empty."
            return
        }

        let trimmedNote = inputNote.trimmingCharacters(in: .whitespaces)

        if let existing = editingEntry,
           let idx = entries.firstIndex(where: { $0.id == existing.id }) {
            entries[idx].name = trimmedName
            entries[idx].note = trimmedNote
        } else {
            entries.append(MedicationEntry(name: trimmedName, note: trimmedNote))
        }

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

        // Cancel any in-flight undo before starting a new one
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
        pendingDelete = nil
        undoBannerVisible = false
        undoTask?.cancel()
        undoTask = nil
    }

    private func commitPendingDelete() {
        // The entry is already removed from `entries`; this just clears the undo buffer
        pendingDelete = nil
        undoBannerVisible = false
        undoTask?.cancel()
        undoTask = nil
    }
}
