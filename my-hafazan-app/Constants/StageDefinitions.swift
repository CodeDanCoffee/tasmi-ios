import Foundation

enum StageDefinitions {
    static let allStages: [StageType] = StageType.allCases

    static func stages(for templateId: String) -> [StageType] {
        guard let template = MemorizationTemplate.all.first(where: { $0.id == templateId }) else {
            return StageType.allCases
        }
        return template.stages.compactMap { StageType(rawValue: $0) }
    }

    static func stageCount(for templateId: String) -> Int {
        stages(for: templateId).count
    }
}
