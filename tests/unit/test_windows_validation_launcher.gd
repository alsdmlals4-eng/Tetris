extends GutTest

const LAUNCHER := "res://tools/local-validation/RUN_CORE_POC_VALIDATION.cmd"

func test_windows_validation_launcher_is_double_clickable_and_records_local_evidence() -> void:
    assert_true(FileAccess.file_exists(LAUNCHER), "Windows validation launcher must exist")
    if not FileAccess.file_exists(LAUNCHER):
        return

    var file := FileAccess.open(LAUNCHER, FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return
    var content := file.get_as_text()
    file.close()

    assert_true(content.contains("POC_MANUAL_VALIDATION=1"))
    assert_true(content.contains("POC_VALIDATION_REPORT_PATH"))
    assert_true(content.contains("set \"GUT_VERSION=9.7.1\""))
    assert_true(content.contains("POC_VALIDATION_GUT_VERSION=%GUT_VERSION%"))
    assert_true(content.contains("POC_VALIDATION_COMMIT"))
    assert_true(content.contains("Tetris_Core_POC_Preflight.txt"))
    assert_true(content.contains("Tetris_Core_POC_Validation.json"))
    assert_true(content.contains("IMPORT_PARSE=PASS"))
    assert_true(content.contains("GUT_SUITE=PASS"))
    assert_true(content.contains("gut_cmdln.gd"))
    assert_true(content.to_lower().contains("curl.exe"))
    assert_true(content.to_lower().contains("tar.exe"))
    assert_false(content.to_lower().contains("powershell"))
