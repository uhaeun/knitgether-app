"""No app, API, database or git mutation: regression checks for QA tooling itself."""
import importlib.util
from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import Mock
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'qa/appium'))
sys.path.insert(0, str(ROOT / 'qa/mutation'))
from pages.pattern_panel_page import PatternPanelPage
import run_mutation as mutation


def viewer(labels):
    page = object.__new__(PatternPanelPage)
    elements = [SimpleNamespace(is_displayed=lambda visible=visible: visible,
                                 get_attribute=lambda key, text=text: text)
                for text, visible in labels]
    page._scroll_view = lambda: SimpleNamespace(find_elements=lambda *args: elements)
    return page


@pytest.mark.parametrize('labels', [[], [('  ', True)], [('hidden', False)]])
def test_unreadable_viewer_cannot_pass(labels):
    with pytest.raises(AssertionError, match='판정할 수 없음'):
        viewer(labels).viewer_signature()


def test_signature_preserves_visible_text_beyond_first_40_characters():
    prefix = 'x' * 40
    assert viewer([(prefix + 'A', True)]).viewer_signature() != viewer([(prefix + 'B', True)]).viewer_signature()


def injection(edits):
    return {'편집': edits}


def test_mismatch_does_not_leave_a_partial_patch(tmp_path, monkeypatch):
    monkeypatch.setattr(mutation, 'ROOT', str(tmp_path))
    (tmp_path / 'a').write_text('original')
    (tmp_path / 'b').write_text('other')
    with pytest.raises(SystemExit, match='매칭 실패'):
        mutation.patch(injection([('a', 'original', 'changed'), ('b', 'missing', 'changed')]))
    assert (tmp_path / 'a').read_text() == 'original'
    assert not mutation._BACKUPS


def test_restore_does_not_touch_files_it_did_not_patch(tmp_path, monkeypatch):
    monkeypatch.setattr(mutation, 'ROOT', str(tmp_path))
    p = tmp_path / 'a'
    p.write_text('user edit')
    mutation.restore(injection([('a', 'original', 'changed')]))
    assert p.read_text() == 'user edit'


def test_restore_preserves_exact_original_bytes(tmp_path, monkeypatch):
    monkeypatch.setattr(mutation, 'ROOT', str(tmp_path))
    p = tmp_path / 'a'
    original = b'original\r\n'
    p.write_bytes(original)
    inj = injection([('a', 'original', 'changed')])
    mutation.patch(inj)
    assert b'changed' in p.read_bytes()
    mutation.restore(inj)
    assert p.read_bytes() == original
    assert not mutation._BACKUPS


def test_junit_error_skip_and_mixed_results_are_not_detection_success(tmp_path):
    report = tmp_path / 'results.xml'
    report.write_text('''<testsuite>
    <testcase name="failure"><failure/></testcase>
    <testcase name="setup_error"><error/></testcase>
    <testcase name="skip"><skipped/></testcase>
    <testcase name="success"/>
    <testcase name="parameters[a]"><failure/></testcase>
    <testcase name="parameters[b]"/>
    </testsuite>''')
    assert mutation.parse_results(report) == {
        'failure': 'FAILED', 'setup_error': 'ERROR', 'skip': 'SKIPPED',
        'success': 'PASSED', 'parameters': 'MIXED'}


def test_collection_failure_cannot_read_a_stale_report(monkeypatch):
    monkeypatch.setattr(mutation.subprocess, 'run', lambda *args, **kw: SimpleNamespace(returncode=2))
    with pytest.raises(RuntimeError, match='완료되지 않아'):
        mutation.pytest_run(['anything'])


def test_existing_server_is_never_killed_or_replaced(monkeypatch):
    monkeypatch.setattr(mutation, 'run', lambda *args, **kw: SimpleNamespace(returncode=0, stdout='1234'))
    popen = Mock()
    monkeypatch.setattr(mutation.subprocess, 'Popen', popen)
    with pytest.raises(SystemExit, match='포트를 비운'):
        mutation.restart_server()
    popen.assert_not_called()


def test_dirty_target_does_not_trigger_restore_or_rebuild(monkeypatch):
    monkeypatch.setattr(mutation, 'INJECTIONS', {'example': {'FAIL 기대': [], '설명': 'test'}})
    def dirty(inj):
        raise SystemExit('dirty target')
    monkeypatch.setattr(mutation, 'ensure_clean', dirty)
    restore, build = Mock(), Mock()
    monkeypatch.setattr(mutation, 'restore', restore)
    monkeypatch.setattr(mutation, 'build_app', build)
    with pytest.raises(SystemExit, match='dirty target'):
        mutation.check('example')
    restore.assert_not_called()
    build.assert_not_called()
