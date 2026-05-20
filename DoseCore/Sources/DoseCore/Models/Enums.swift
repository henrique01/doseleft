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
public enum MedicationIcon: String, Codable, Sendable, CaseIterable {
    case inhaler        = "lungs.fill"
    // Click-dialed pens (compounded tirzepatide / semaglutide). Each "dose" the
    // user logs corresponds to N clicks, configured via the in-app calculator.
    case clickPen       = "pencil.tip"
    case drops          = "drop.fill"
    case pills          = "pills.fill"
    // PRD listed "tube" but no such SF Symbol exists; cross.case.fill is the
    // closest stock medical-kit glyph and reads as a tube/ointment container.
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
