import SwiftUI

struct PrayerCountView: View {
    @Bindable var viewModel: ChallengeViewModel
    var onEditPrayer: (Int) -> Void

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let warmBrown = Color(red: 180/255, green: 120/255, blue: 80/255)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Decorative icon
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hDarkText.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "sun.min")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.hDarkText.opacity(0.25))
            }
            .padding(.bottom, 20)

            // Title
            Text("Bring the ayahs\ninto your salah.")
                .font(.custom("Georgia", size: 26))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 16)

            // Description
            descriptionText
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

            // Italic prompt
            Text("Come back after each prayer to mark it done.")
                .font(.custom("Georgia", size: 14).italic())
                .foregroundStyle(Color.hOliveGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

            // Prayer dots
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.challenge.prayerCount
                            ? warmBrown
                            : Color.hDarkText.opacity(0.08))
                        .frame(width: 16, height: 16)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.challenge.prayerCount)
                }
            }
            .padding(.bottom, 12)

            // Counter
            Text("\(viewModel.challenge.prayerCount) of 3")
                .font(.custom("Georgia", size: 20))
                .foregroundStyle(Color.hDarkText)

            // Marked prayers card
            if !viewModel.challenge.prayerEntries.isEmpty {
                markedPrayersCard
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.challenge.prayerCount)
        .onAppear {
            viewModel.syncPrayerCount()
        }
    }

    // Description with bold surah reference
    private var descriptionText: Text {
        let surah = viewModel.challenge.surahName
        let range = viewModel.challenge.verseRange
        let ref = "\(surah) \(range)"

        return Text("Recite ")
            + Text(ref).bold()
            + Text(" in three prayers. Any prayers \u{2014} Fajr, Dhuhr, Asr, Maghrib, or Isha. In any rak\u{02BB}ah after Al-F\u{0101}ti\u{1E25}ah.")
    }

    // MARK: - Marked Prayers Card

    private var markedPrayersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MARKED PRAYERS")
                .font(HFont.generalSans(11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(labelColor)

            ForEach(Array(viewModel.challenge.prayerEntries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(Color.hDarkText.opacity(0.04))
                        .frame(height: 1)
                }

                Button {
                    onEditPrayer(index)
                } label: {
                    HStack {
                        Text(entry.name)
                            .font(HFont.generalSans(14, weight: .medium))
                            .foregroundStyle(Color.hDarkText)

                        Spacer()

                        Text(viewModel.formattedPrayerTime(entry.date))
                            .font(HFont.generalSans(13))
                            .foregroundStyle(subtextColor)

                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundStyle(labelColor)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Prayer Input Sheet

struct PrayerInputSheet: View {
    @Bindable var viewModel: ChallengeViewModel
    let editingIndex: Int?
    let onDismiss: () -> Void

    @State private var selectedPrayer: String = "Fajr"
    @State private var selectedTime: Date = Date()

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    private var isEditing: Bool { editingIndex != nil }

    var body: some View {
        VStack(spacing: 24) {
            // Drag indicator
            Capsule()
                .fill(Color.hDarkText.opacity(0.08))
                .frame(width: 40, height: 4)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isEditing ? "Edit prayer." : "Mark prayer.")
                        .font(.system(size: 22, design: .serif))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-0.3)

                    Spacer()

                    Button { onDismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(Color.hDarkText.opacity(0.04))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.hDarkText)
                        }
                    }
                }

                Text("Which solah did you recite in? Any rak\u{02BB}ah counts.")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(13 * 0.3)
            }
            .padding(.top, 0)

            // Prayer picker
            VStack(alignment: .leading, spacing: 8) {
                Text("WHICH SOLAH?")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(subtextColor)

                HStack(spacing: 8) {
                    ForEach(ChallengeViewModel.prayerNames, id: \.self) { name in
                        Button {
                            selectedPrayer = name
                        } label: {
                            Text(name)
                                .font(HFont.generalSans(13, weight: selectedPrayer == name ? .medium : .regular))
                                .foregroundStyle(selectedPrayer == name ? .white : Color.hDarkText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedPrayer == name ? Color.hOliveGreen : Color.hDarkText.opacity(0.05))
                                )
                        }
                    }
                }
            }

            // Time picker
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT TIME?")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(subtextColor)

                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            Spacer()

            // Save button
            Button {
                if let index = editingIndex {
                    viewModel.updatePrayerEntry(at: index, name: selectedPrayer, date: selectedTime)
                } else {
                    viewModel.addPrayerEntry(name: selectedPrayer, date: selectedTime)
                }
                onDismiss()
            } label: {
                Text(isEditing ? "Update" : "Mark as prayed")
                    .font(HFont.generalSans(17, weight: .medium))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.hOliveGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear {
            if let index = editingIndex,
               index >= 0 && index < viewModel.challenge.prayerEntries.count {
                let entry = viewModel.challenge.prayerEntries[index]
                selectedPrayer = entry.name
                selectedTime = entry.date
            }
        }
    }
}
