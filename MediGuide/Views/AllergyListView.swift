import SwiftUI

struct AllergyListView: View {
    @ObservedObject var vm: AllergyListViewModel

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
            AllergyEntrySheet(vm: vm)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.startAdd()
                } label: {
                    Label("Add Allergy", systemImage: "plus")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No allergies added")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add known allergies so emergency responders are alerted before treatment.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Allergy") {
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
                allergyRow(entry)
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

    private func allergyRow(_ entry: AllergyEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if entry.severity == .anaphylactic {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    Text(entry.allergen)
                        .font(.body.bold())
                        .foregroundStyle(entry.severity == .anaphylactic ? .red : .primary)
                }

                HStack(spacing: 6) {
                    categoryBadge(entry.category)
                    severityBadge(entry.severity)
                    if entry.carriesEpiPen {
                        epiPenBadge
                    }
                }

                if !entry.reactionDescription.isEmpty {
                    Text(entry.reactionDescription)
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
        .padding(.vertical, 2)
        .listRowBackground(entry.severity == .anaphylactic ? Color.red.opacity(0.06) : nil)
    }

    // MARK: - Badges

    private func categoryBadge(_ category: AllergyCategory) -> some View {
        Label(category.displayName, systemImage: category.icon)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
    }

    private func severityBadge(_ severity: AllergySeverity) -> some View {
        Text(severity.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor(severity).opacity(0.15), in: Capsule())
            .foregroundStyle(severityColor(severity))
    }

    private var epiPenBadge: some View {
        Label("EpiPen", systemImage: "syringe.fill")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(.orange)
    }

    private func severityColor(_ severity: AllergySeverity) -> Color {
        switch severity {
        case .mild:         return .green
        case .moderate:     return .yellow
        case .severe:       return .orange
        case .anaphylactic: return .red
        }
    }

    // MARK: - Undo Banner

    private var undoBanner: some View {
        HStack {
            Text("Allergy removed")
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

struct AllergyEntrySheet: View {
    @ObservedObject var vm: AllergyListViewModel
    @FocusState private var allergenFieldFocused: Bool

    var isEditing: Bool { vm.editingEntry != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Allergen") {
                    TextField("e.g. Penicillin, Peanuts, Bee stings", text: $vm.inputAllergen)
                        .focused($allergenFieldFocused)
                }

                Section("Category") {
                    Picker("Category", selection: $vm.inputCategory) {
                        ForEach(AllergyCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Reaction severity") {
                    Picker("Severity", selection: $vm.inputSeverity) {
                        ForEach(AllergySeverity.allCases, id: \.self) { sev in
                            Text(sev.displayName).tag(sev)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Reaction description (optional)") {
                    TextField("e.g. Hives and throat swelling", text: $vm.inputReactionDescription, axis: .vertical)
                        .lineLimit(3, reservesSpace: false)
                }

                if vm.inputSeverity >= .severe {
                    Section {
                        Toggle("Carries EpiPen / epinephrine auto-injector", isOn: $vm.inputCarriesEpiPen)
                    }
                }

                if let error = vm.validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Allergy" : "Add Allergy")
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
            .onAppear { allergenFieldFocused = true }
        }
        .presentationDetents([.large])
    }
}
