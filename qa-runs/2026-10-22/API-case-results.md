# 기존 API 테스트 개별 실행 결과

| 실행 항목 | 결과 |
| --- | --- |
| test_update_without_base_updated_at_is_rejected | PASS |
| test_second_update_from_same_baseline_is_rejected_and_first_survives | PASS |
| test_update_with_refreshed_baseline_succeeds | PASS |
| test_duplicate_create_is_rejected_and_row_stays_single | PASS |
| test_resend_reaches_server_through_update_path | PASS |
| test_api_18_partial_payload_does_not_delete_existing_sessions | PASS |
| test_api_18_resend_does_not_duplicate_or_drop | PASS |
| test_api_19_rejected_request_preserves_server_state | PASS |
| test_api_20_rejected_update_does_not_discard_previous_value | PASS |
| test_api_20_rejected_update_keeps_children_intact | PASS |
| test_api_26_exact_millisecond_timestamp_allows_save | PASS |
| test_api_26_truncated_timestamp_is_rejected_without_mutation | PASS |
| test_api_28_dictionary_patch_rejects_partial_body | PASS |
| test_api_28_project_patch_rejects_partial_body | PASS |
| test_api_28_project_patch_accepts_full_body | PASS |
| test_api_28_library_patch_rejects_partial_body[yarn] | PASS |
| test_api_28_library_patch_rejects_partial_body[needle] | PASS |
| test_api_28_library_patch_rejects_partial_body[tool] | PASS |
