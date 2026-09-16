import SwiftUI

struct SelectTemplateView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick a template")
                    .font(HFont.sourceSerif(26, weight: .regular))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.4)
                Text("How you'll work through the range.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 20)

            // Template cards
            VStack(spacing: 12) {
                ForEach(MemorizationTemplate.all) { template in
                    TemplateCardView(
                        template: template,
                        isSelected: viewModel.selectedTemplate.id == template.id
                    ) {
                        viewModel.selectedTemplate = template
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

struct TemplateCardView: View {
    let template: MemorizationTemplate
    let isSelected: Bool
    let onTap: () -> Void

    // rgb(233, 236, 227) - selected card background
    private let selectedBg = Color(red: 233/255, green: 236/255, blue: 227/255)
    // rgb(61, 56, 52) - description text
    private let descColor = Color(red: 61/255, green: 56/255, blue: 52/255)
    // rgb(122, 114, 106) - stages text
    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Top row: title + badge + stages
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Text(template.name)
                            .font(.custom("Georgia", size: 20))
                            .foregroundStyle(Color.hDarkText)

                        if template.isRecommended {
                            Text("RECOMMENDED")
                                .font(HFont.generalSans(11, weight: .medium))
                                .foregroundStyle(Color.hOliveGreen)
                                .tracking(0.3)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.hOliveGreen, lineWidth: 1)
                                )
                        }
                    }

                    Spacer()

                    Text("\(template.stages.count) stages")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(subtextColor)
                }
                .padding(.bottom, 6)

                // Description
                Text(template.description)
                    .font(HFont.generalSans(14))
                    .foregroundStyle(descColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? selectedBg : .white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color.hOliveGreen : Color.hDarkText.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
