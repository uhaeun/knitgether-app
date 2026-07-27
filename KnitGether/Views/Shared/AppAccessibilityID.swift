import Foundation

enum AppAccessibilityID {
    enum Tab {
        static let home = "tab.home"
        static let myKnitting = "tab.my_knitting"
        static let tool = "tab.tool"
        static let library = "tab.library"
        static let settings = "tab.settings"
    }

    enum Project {
        static let addButton = "project.add"
        static let editButton = "project.edit"
        static let saveButton = "project.save"
        static let deleteButton = "project.delete"
        static let nameField = "project.form.name"
        static let statusPicker = "project.form.status"
        static let yarnPicker = "project.form.yarn"
        static let needlePicker = "project.form.needle"
        static let patternPicker = "project.form.pattern"
        static let memoField = "project.form.memo"
        static let showInfoButton = "project.show_info"

        static func row(_ id: UUID) -> String {
            "project.row.\(id.uuidString.lowercased())"
        }
    }

    enum Workspace {
        static let editProjectButton = "workspace.project.edit"
        static let displayModePicker = "workspace.display_mode"
        static let patternDirectImportButton = "workspace.pattern.direct_import"
        static let patternScanButton = "workspace.pattern.scan"
        static let patternLibraryButton = "workspace.pattern.library"
        static let patternManualButton = "workspace.pattern.manual"
        static let patternManualTitleField = "workspace.pattern.manual.title"
        static let patternManualSaveButton = "workspace.pattern.manual.save"
        static let patternOpenPDFButton = "workspace.pattern.open_pdf"
        static let patternLookupButton = "workspace.pattern.lookup"
        static let patternUnlinkButton = "workspace.pattern.unlink"
        static let counterModePicker = "workspace.counter.mode"
        static let counterPreviousButton = "workspace.counter.previous"
        static let counterNextButton = "workspace.counter.next"
        static let counterEditCurrentButton = "workspace.counter.edit_current"
        static let counterEditTargetButton = "workspace.counter.edit_target"
        static let counterNumberField = "workspace.counter.number_field"
        static let counterNumberSaveButton = "workspace.counter.number_save"
        static let counterSectionField = "workspace.counter.section"
        static let counterSectionSaveButton = "workspace.counter.section_save"
        static let counterMemoButton = "workspace.counter.memo"
        static let counterMemoField = "workspace.counter.memo_field"
        static let counterMemoSaveButton = "workspace.counter.memo_save"
        static let rowInstructionAddButton = "workspace.row_instruction.add"
        static let rowInstructionBulkButton = "workspace.row_instruction.bulk"
        static let rowInstructionRenumberButton = "workspace.row_instruction.renumber"
        static let rowInstructionNumberField = "workspace.row_instruction.form.number"
        static let rowInstructionTextField = "workspace.row_instruction.form.text"
        static let rowInstructionSkillTagsField = "workspace.row_instruction.form.skill_tags"
        static let rowInstructionSaveButton = "workspace.row_instruction.form.save"
        static let bulkRowInstructionStartField = "workspace.row_instruction.bulk.start"
        static let bulkRowInstructionLinesField = "workspace.row_instruction.bulk.lines"
        static let bulkRowInstructionSaveButton = "workspace.row_instruction.bulk.save"
        static let yarnUsageRecordButton = "workspace.yarn_usage.record"
        static let yarnUsageQuantityStepper = "workspace.yarn_usage.quantity"
        static let yarnUsageMemoField = "workspace.yarn_usage.memo"
        static let yarnUsageSaveButton = "workspace.yarn_usage.save"
        static let needleLinkButton = "workspace.needle.link"
        static let toolLinkButton = "workspace.tool.link"
        static let gaugeRecordLinkButton = "workspace.gauge_record.link"
        static let workStartButton = "workspace.work_time.start"
        static let workFinishButton = "workspace.work_time.finish"
        static let workSessionsButton = "workspace.work_time.sessions"
        static let workSessionMemoField = "workspace.work_session.memo"
        static let workSessionMemoSaveButton = "workspace.work_session.memo_save"
        static let progressPhotoAddButton = "workspace.progress_photo.add"
        static let progressPhotoTakenAtPicker = "workspace.progress_photo.taken_at"
        static let progressPhotoCaptionField = "workspace.progress_photo.caption"
        static let progressPhotoSaveButton = "workspace.progress_photo.save"
        static let progressPhotoDeleteButton = "workspace.progress_photo.delete"
        static let projectMemoField = "workspace.memo.field"
        static let projectMemoSaveButton = "workspace.memo.save"

        static func rowInstruction(_ id: UUID) -> String {
            "workspace.row_instruction.row.\(id.uuidString.lowercased())"
        }

        static func rowInstructionSuggestionAddButton(_ rowNumber: Int) -> String {
            "workspace.row_instruction.suggestion.add.\(rowNumber)"
        }

        static func yarnUsageRow(_ id: UUID) -> String {
            "workspace.yarn_usage.row.\(id.uuidString.lowercased())"
        }

        static func workSessionRow(_ id: UUID) -> String {
            "workspace.work_session.row.\(id.uuidString.lowercased())"
        }

        static func progressPhotoRow(_ id: UUID) -> String {
            "workspace.progress_photo.row.\(id.uuidString.lowercased())"
        }

        static func needlePickerRow(_ id: UUID) -> String {
            "workspace.needle.picker.row.\(id.uuidString.lowercased())"
        }

        static func toolPickerRow(_ id: UUID) -> String {
            "workspace.tool.picker.row.\(id.uuidString.lowercased())"
        }

        static func linkedToolRow(_ id: UUID) -> String {
            "workspace.tool.linked.row.\(id.uuidString.lowercased())"
        }
    }

    enum Library {
        static let patternAddButton = "library.pattern.add"
        static let patternEditButton = "library.pattern.edit"
        static let patternSaveButton = "library.pattern.save"
        static let patternTitleField = "library.pattern.form.title"
        static let patternDesignerField = "library.pattern.form.designer"
        static let patternPageCountField = "library.pattern.form.page_count"
        static let patternNotesField = "library.pattern.form.notes"
        static let yarnAddButton = "library.yarn.add"
        static let yarnEditButton = "library.yarn.edit"
        static let yarnDeleteButton = "library.yarn.delete"
        static let yarnSaveButton = "library.yarn.save"
        static let yarnNameField = "library.yarn.form.name"
        static let yarnBrandField = "library.yarn.form.brand"
        static let yarnColorwayField = "library.yarn.form.colorway"
        static let yarnWeightField = "library.yarn.form.weight"
        static let yarnQuantityStepper = "library.yarn.form.quantity"
        static let yarnNotesField = "library.yarn.form.notes"
        static let needleAddButton = "library.needle.add"
        static let needleEditButton = "library.needle.edit"
        static let needleDeleteButton = "library.needle.delete"
        static let needleSaveButton = "library.needle.save"
        static let needleNameField = "library.needle.form.name"
        static let needleTypeField = "library.needle.form.type"
        static let needleSizeField = "library.needle.form.size"
        static let needleLengthField = "library.needle.form.length"
        static let needleNotesField = "library.needle.form.notes"
        static let toolAddButton = "library.tool.add"
        static let toolEditButton = "library.tool.edit"
        static let toolDeleteButton = "library.tool.delete"
        static let toolSaveButton = "library.tool.save"
        static let toolNameField = "library.tool.form.name"
        static let toolTypeField = "library.tool.form.type"
        static let toolLinkField = "library.tool.form.link"
        static let toolMemoField = "library.tool.form.memo"
        static let skillAddButton = "library.skill.add"
        static let skillSaveButton = "library.skill.save"
        static let skillNameField = "library.skill.form.name"
        static let skillAbbreviationField = "library.skill.form.abbreviation"
        static let skillCategoryField = "library.skill.form.category"
        static let skillDifficultyField = "library.skill.form.difficulty"
        static let skillDescriptionField = "library.skill.form.description"
        static let skillStepsField = "library.skill.form.steps"
        static let skillAnimationNameField = "library.skill.form.animation_name"
        static let skillAnimationTypeField = "library.skill.form.animation_type"

        static func patternRow(_ id: UUID) -> String {
            "library.pattern.row.\(id.uuidString.lowercased())"
        }

        static func yarnRow(_ id: UUID) -> String {
            "library.yarn.row.\(id.uuidString.lowercased())"
        }

        static func needleRow(_ id: UUID) -> String {
            "library.needle.row.\(id.uuidString.lowercased())"
        }

        static func toolRow(_ id: UUID) -> String {
            "library.tool.row.\(id.uuidString.lowercased())"
        }

        static func skillRow(_ id: UUID) -> String {
            "library.skill.row.\(id.uuidString.lowercased())"
        }
    }

    enum Tool {
        static let gaugeCalculatorCard = "tool.gauge_calculator"
        static let skillTestCard = "tool.skill_test"
        static let navigationCard = "tool.navigation"
        static let dictionaryCard = "tool.dictionary"
        static let dictionaryCountLabel = "tool.dictionary.count"
        static func dictionaryTermRow(_ term: String) -> String {
            "tool.dictionary.term.\(term)"
        }
        static let animationCard = "tool.animation"
        static let gaugeProjectPicker = "tool.gauge.project"
        static let gaugePatternPicker = "tool.gauge.pattern"
        static let gaugeManualPatternField = "tool.gauge.manual_pattern"
        static let gaugeSampleWidthField = "tool.gauge.sample_width"
        static let gaugeSampleHeightField = "tool.gauge.sample_height"
        static let gaugeSampleStitchesField = "tool.gauge.sample_stitches"
        static let gaugeSampleRowsField = "tool.gauge.sample_rows"
        static let gaugeTargetWidthField = "tool.gauge.target_width"
        static let gaugeTargetHeightField = "tool.gauge.target_height"
        static let gaugeNeedleField = "tool.gauge.needle"
        static let gaugeMemoField = "tool.gauge.memo"
        static let gaugeSaveBeforeButton = "tool.gauge.save_before"
        static let gaugeSaveAfterButton = "tool.gauge.save_after"
        static let gaugeMeasureHubLink = "tool.gauge.measure_hub"
        static let gaugeQuickMeasureButton = "tool.gauge.measure.quick"
        static let gaugeTargetListLink = "tool.gauge.target.list"
        static let gaugeTargetAddButton = "tool.gauge.target.add"
        static let gaugeTargetEditButton = "tool.gauge.target.edit"
        static let gaugeTargetSaveButton = "tool.gauge.target.save"
        static let gaugeTargetNameField = "tool.gauge.target.form.name"
        static let gaugeTargetNeedleField = "tool.gauge.target.form.needle"
        static let gaugeTargetAfterWashToggle = "tool.gauge.target.form.after_wash"
        static let gaugeTargetFormWidthField = "tool.gauge.target.form.width"
        static let gaugeTargetFormHeightField = "tool.gauge.target.form.height"
        static let gaugeTargetFormStitchesField = "tool.gauge.target.form.stitches"
        static let gaugeTargetFormRowsField = "tool.gauge.target.form.rows"
        static let gaugeSwatchAddButton = "tool.gauge.swatch.add"
        static let gaugeSwatchEditButton = "tool.gauge.swatch.edit"
        static let gaugeSwatchSaveButton = "tool.gauge.swatch.save"
        static let gaugeSwatchNeedleSizeField = "tool.gauge.swatch.form.needle_size"
        static let gaugeSwatchNeedleTypeField = "tool.gauge.swatch.form.needle_type"
        static let gaugeSwatchNeedleMaterialField = "tool.gauge.swatch.form.needle_material"
        static let gaugeSwatchYarnNameField = "tool.gauge.swatch.form.yarn_name"
        static let gaugeSwatchYarnBrandField = "tool.gauge.swatch.form.yarn_brand"
        static let gaugeSwatchYarnColorField = "tool.gauge.swatch.form.yarn_color"
        static let gaugeSwatchYarnLotField = "tool.gauge.swatch.form.yarn_lot"
        static let gaugeSwatchPatternField = "tool.gauge.swatch.form.pattern"
        static let gaugeSwatchNotesField = "tool.gauge.swatch.form.notes"
        static let gaugeManualMethodLink = "tool.gauge.measure.manual_method"
        static let gaugePhotoMethodLink = "tool.gauge.measure.photo_method"
        static let gaugeMeasurementSaveButton = "tool.gauge.measure.save"
        static let gaugeMeasurementWidthField = "tool.gauge.measure.width"
        static let gaugeMeasurementHeightField = "tool.gauge.measure.height"
        static let gaugeMeasurementStitchesField = "tool.gauge.measure.stitches"
        static let gaugeMeasurementRowsField = "tool.gauge.measure.rows"
        static let gaugePhotoPicker = "tool.gauge.measure.photo_picker"
        static let gaugePhotoAutoButton = "tool.gauge.measure.photo_auto"
        static let gaugePhotoResultSaveButton = "tool.gauge.measure.photo_result_save"
        static let gaugeQuickTargetNameField = "tool.gauge.quick.target_name"
        static let gaugeQuickNeedleField = "tool.gauge.quick.needle"
        static let gaugeQuickSaveButton = "tool.gauge.quick.save"

        static func gaugeTargetRow(_ id: UUID) -> String {
            "tool.gauge.target.row.\(id.uuidString.lowercased())"
        }

        static func gaugeSwatchRow(_ id: UUID) -> String {
            "tool.gauge.swatch.row.\(id.uuidString.lowercased())"
        }

        static func gaugeMeasurementRow(_ id: UUID) -> String {
            "tool.gauge.measure.row.\(id.uuidString.lowercased())"
        }
    }

    enum Settings {
        static let accountCard = "settings.account"
        static let profileCard = "settings.profile"
        static let profileNameField = "settings.profile.name"
        static let profileSaveButton = "settings.profile.save"
        static let backupCard = "settings.backup"
        static let dataManagementCard = "settings.data_management"
        static let statisticsCard = "settings.statistics"
        static let workSessionsCard = "settings.work_sessions"
    }

    enum Onboarding {
        static let startButton = "onboarding.start"
        static let registerButton = "onboarding.register"
        static let loginButton = "onboarding.login"
        static let completeButton = "onboarding.complete"
    }

    enum Auth {
        static let submitButton = "auth.submit"
        static let modePicker = "auth.mode"
        static let emailField = "auth.email"
        static let passwordField = "auth.password"
        static let displayNameField = "auth.display_name"
        static let logoutButton = "auth.logout"
    }
}
