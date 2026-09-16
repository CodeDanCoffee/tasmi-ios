import SwiftUI

struct SelectVersesView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    // Design tokens from CSS
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255) // rgb(168,160,152)
    private let stepperPillBg = Color(red: 242/255, green: 238/255, blue: 231/255) // rgb(242,238,231)
    private let previewCardBg = Color(red: 255/255, green: 253/255, blue: 248/255) // rgb(255,253,248)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let cardShadow = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.03)

    private var maxVerse: Int {
        viewModel.selectedChapter?.versesCount ?? 1
    }

    private var selectedCount: Int {
        viewModel.verseEnd - viewModel.verseStart + 1
    }

    private var canDecrementStart: Bool {
        viewModel.verseStart > 1
    }

    private var canIncrementStart: Bool {
        viewModel.verseStart < viewModel.verseEnd
    }

    private var canDecrementEnd: Bool {
        viewModel.verseEnd > viewModel.verseStart
    }

    private var canIncrementEnd: Bool {
        viewModel.verseEnd < maxVerse
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick a range")
                    .font(HFont.sourceSerif(26, weight: .regular))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.4)

                if let chapter = viewModel.selectedChapter {
                    HStack(alignment: .firstTextBaseline, spacing: HSpacing.xs) {
                        Text(ChapterNames.arabicName(for: chapter.id) ?? chapter.nameArabic)
                            .font(HFont.amiriQuran(18))
                            .foregroundStyle(Color.hDarkText)
                        Text("\(chapter.nameSimple) · \(chapter.versesCount) ayat")
                            .font(HFont.generalSans(14))
                            .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 6)

            if viewModel.isLoadingVerses {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                // Range picker card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // FROM stepper
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From")
                                .font(HFont.generalSans(11))
                                .foregroundStyle(labelColor)
                                .tracking(0.6)
                                .textCase(.uppercase)

                            stepperGroup(
                                value: viewModel.verseStart,
                                canDecrement: canDecrementStart,
                                canIncrement: canIncrementStart,
                                onDecrement: {
                                    if canDecrementStart { viewModel.verseStart -= 1 }
                                },
                                onIncrement: {
                                    if canIncrementStart { viewModel.verseStart += 1 }
                                }
                            )
                        }

                        // UNTIL stepper
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Until")
                                .font(HFont.generalSans(11))
                                .foregroundStyle(labelColor)
                                .tracking(0.6)
                                .textCase(.uppercase)

                            stepperGroup(
                                value: viewModel.verseEnd,
                                canDecrement: canDecrementEnd,
                                canIncrement: canIncrementEnd,
                                onDecrement: {
                                    if canDecrementEnd { viewModel.verseEnd -= 1 }
                                },
                                onIncrement: {
                                    if canIncrementEnd { viewModel.verseEnd += 1 }
                                }
                            )
                        }
                    }

                    Text("\(selectedCount) ayahs selected")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(labelColor)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .shadow(color: cardShadow, radius: 0, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // Preview label
                Text("Preview")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(labelColor)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                // Preview card. Card fills remaining space, content scrolls inside
                ScrollView {
                    let selectedVerses = viewModel.verses.filter { v in
                        v.verseNumber >= viewModel.verseStart && v.verseNumber <= viewModel.verseEnd
                    }

                    VStack(spacing: 12) {
                        // Bismillah (centered, olive green)
                        if viewModel.verseStart == 1,
                           let chapter = viewModel.selectedChapter,
                           chapter.id != 9, chapter.id != 1 {
                            Text(bismillahText())
                                .font(HFont.amiriQuran(22))
                                .foregroundStyle(Color.hOliveGreen)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Text(buildQuranText(from: selectedVerses))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .environment(\.layoutDirection, .rightToLeft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tracking(0.5)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                .background(previewCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .shadow(color: cardShadow, radius: 0, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .task {
            await viewModel.loadVerses()
        }
    }

    // MARK: - Stepper Group

    private func stepperGroup(
        value: Int,
        canDecrement: Bool,
        canIncrement: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            // Minus button
            Button(action: onDecrement) {
                Text("−")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.hDarkText)
                    .frame(width: 36, height: 36)
                    .background(canDecrement ? .white : stepperPillBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hDarkText.opacity(0.08), lineWidth: canDecrement ? 1 : 0)
                    )
            }
            .opacity(canDecrement ? 1.0 : 0.4)
            .disabled(!canDecrement)

            // Number
            Text("\(value)")
                .font(.custom("Georgia", size: 26))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.5)
                .frame(maxWidth: .infinity)

            // Plus button
            Button(action: onIncrement) {
                Text("+")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.hDarkText)
                    .frame(width: 36, height: 36)
                    .background(canIncrement ? .white : stepperPillBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.hDarkText.opacity(0.08), lineWidth: canIncrement ? 1 : 0)
                    )
            }
            .opacity(canIncrement ? 1.0 : 0.4)
            .disabled(!canIncrement)
        }
        .padding(6)
        .background(stepperPillBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quran Text

    private func bismillahText() -> AttributedString {
        var attr = AttributedString("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
        attr.font = HFont.amiriQuran(22)
        attr.foregroundColor = Color.hOliveGreen
        return attr
    }

    private func buildQuranText(from verses: [Verse]) -> AttributedString {
        var result = AttributedString()

        let verseFont = UIFont(name: "AmiriQuran-Regular", size: 32)
            ?? UIFont.systemFont(ofSize: 32)
        let markerFont = UIFont(name: "AmiriQuran-Regular", size: 24)
            ?? UIFont.systemFont(ofSize: 24)

        for verse in verses {
            // Verse text
            var verseAttr = AttributedString((verse.textUthmani ?? "").cleanArabic)
            verseAttr.font = Font(verseFont)
            verseAttr.foregroundColor = Color.hDarkText
            result.append(verseAttr)

            // Verse end marker with number
            let num = toArabicNumerals(verse.verseNumber)
            var markerAttr = AttributedString(" \u{06DD}\(num) ")
            markerAttr.font = Font(markerFont)
            markerAttr.foregroundColor = Color.hOliveGreen
            result.append(markerAttr)
        }

        return result
    }

    private func toArabicNumerals(_ number: Int) -> String {
        let arabicDigits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(String(number).map { arabicDigits[Int(String($0))!] })
    }
}
