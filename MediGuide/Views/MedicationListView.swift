import SwiftUI

struct MedicationListView: View {
    @ObservedObject var vm: MedicationListViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if vm.entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }

            if vm.undoBannerVisible {
                undoBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.undoBannerVisible)
        .sheet(isPresented: $vm.showAddSheet) {
            MedicationEntrySheet(vm: vm)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.startAdd()
                } label: {
                    Label("Add Medication", systemImage: "plus")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No medications added")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add any medications you take regularly so they can be shared in an emergency.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Medication") {
                vm.startAdd()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
            Spacer()
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(vm.entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.name)
                            .font(.body.bold())
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        vm.startEdit(entry)
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        if let idx = vm.entries.firstIndex(where: { $0.id == entry.id }) {
                            vm.requestDelete(at: IndexSet(integer: idx))
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Undo Banner

    private var undoBanner: some View {
        HStack {
            Text("Medication removed")
                .font(.subheadline)
            Spacer()
            Button("Undo") {
                vm.undoDelete()
            }
            .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

// MARK: - Entry Sheet

struct MedicationEntrySheet: View {
    @ObservedObject var vm: MedicationListViewModel
    @FocusState private var nameFieldFocused: Bool

    var isEditing: Bool { vm.editingEntry != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Medication name", text: $vm.inputName)
                        .focused($nameFieldFocused)
                    TextField("Notes (optional)", text: $vm.inputNote, axis: .vertical)
                        .lineLimit(3, reservesSpace: false)
                }

                if let error = vm.validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.cancelInput() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { vm.commitInput() }
                        .bold()
                }
            }
            .onAppear { nameFieldFocused = true }
        }
        .presentationDetents([.medium])
    }
}
