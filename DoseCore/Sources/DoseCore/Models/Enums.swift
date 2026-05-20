import Foundation

public enum TrackingMode: String, Codable, Sendable, CaseIterable {
    case automatic
    case manual
}

public enum LogSource: String, Codable, Sendable, CaseIterable {
    case manual
    case correction
    case reset
    case scheduled
    case missed
}

/// Curated medication-form SF Symbol set (PRD §Iconography).
///
/// Retained for back-compat with existing `iconSymbol` strings on stored
/// medications. New code should use ``MedicationForm`` for the semantic
/// type and read the SF Symbol off `Medication.iconSymbol` directly.
public enum MedicationIcon: String, Codable, Sendable, CaseIterable {
    case inhaler        = "lungs.fill"
    case clickPen       = "pencil.tip"
    case drops          = "drop.fill"
    case pills          = "pills.fill"
    case cream          = "cross.case.fill"
    case spray          = "waterbottle.fill"
    case injection      = "syringe"
    case otherLiquid    = "cross.vial"

    public var symbolName: String { rawValue }

    public var defaultUnitLabel: String {
        switch self {
        case .inhaler:      return "puff"
        case .clickPen:     return "click"
        case .drops:        return "drop"
        case .pills:        return "tablet"
        case .cream:        return "application"
        case .spray:        return "spray"
        case .injection:    return "shot"
        case .otherLiquid:  return "dose"
        }
    }
}

/// Semantic medication form — drives unit labels ("tablets", "puffs") and
/// the default icon shown on the medication card. Decoupled from the visual
/// SF Symbol on the medication, which the user can override independently.
public enum MedicationForm: String, Codable, Sendable, CaseIterable, Identifiable {
    // Pen and inhaler lead the picker — they're the highest-effort setup
    // (pen needs the click calculator; inhaler is the dominant rescue type).
    case pen
    case inhaler
    case tablet
    case capsule
    case drops
    case spray
    case creamGel
    case injection
    case otherLiquid

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tablet:       return "Tablet"
        case .capsule:      return "Capsule"
        case .inhaler:      return "Inhaler"
        case .drops:        return "Drops"
        case .spray:        return "Spray"
        case .creamGel:     return "Cream / gel"
        case .injection:    return "Injection"
        case .pen:          return "Pen"
        case .otherLiquid:  return "Other liquid"
        }
    }

    public var defaultUnitLabel: String {
        switch self {
        case .tablet:       return "tablet"
        case .capsule:      return "capsule"
        case .inhaler:      return "puff"
        case .drops:        return "drop"
        case .spray:        return "spray"
        case .creamGel:     return "application"
        case .injection:    return "shot"
        case .pen:          return "click"
        case .otherLiquid:  return "dose"
        }
    }

    /// SF Symbol pre-selected for this form (labelled "Default" in the picker).
    public var defaultIcon: String {
        switch self {
        case .tablet:       return "pills.fill"
        case .capsule:      return "capsule.fill"
        case .inhaler:      return "lungs.fill"
        case .drops:        return "drop.fill"
        case .spray:        return "waterbottle.fill"
        case .creamGel:     return "cross.case.fill"
        case .injection:    return "syringe"
        case .pen:          return "pencil.tip"
        case .otherLiquid:  return "cross.vial"
        }
    }

    /// Icons surfaced first in the icon picker — defaults to the full catalog
    /// for now, with the form's own default appearing first.
    public var suggestedIcons: [String] {
        var list = MedicationIconCatalog.all
        if let idx = list.firstIndex(of: defaultIcon) {
            list.remove(at: idx)
        }
        return [defaultIcon] + list
    }

    /// Best-effort derivation from a legacy `iconSymbol` string. Used to
    /// hydrate the form on medications saved before the form field existed.
    public static func inferred(fromIcon symbol: String) -> MedicationForm {
        switch symbol {
        case "lungs.fill":          return .inhaler
        case "pencil.tip":          return .pen
        case "drop.fill":           return .drops
        case "pills.fill":          return .tablet
        case "capsule.fill":        return .capsule
        case "cross.case.fill":     return .creamGel
        case "waterbottle.fill":    return .spray
        case "syringe":             return .injection
        case "cross.vial":          return .otherLiquid
        default:                    return .tablet
        }
    }
}

/// Curated SF Symbol set surfaced in the icon picker grid.
public enum MedicationIconCatalog {
    public static let all: [String] = [
        "pills.fill",
        "capsule.fill",
        "lungs.fill",
        "drop.fill",
        "waterbottle.fill",
        "cross.case.fill",
        "syringe",
        "pencil.tip",
        "cross.vial"
    ]
}
