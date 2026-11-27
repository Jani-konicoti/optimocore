"""Opt-in Windows integration test for a disposable SQL Server and Jet batch."""

import argparse
import hashlib
from pathlib import Path
from tkinter import Tk

from datavalidation_app.legacy import LegacyWorkspace
from datavalidation_app.ui import ValidationApp


def check_published(workspace, state, locked, expected):
    published = workspace.request('published')
    batch = published['batch']
    assert (batch['state'], batch['locked']) == (state, locked), batch
    assert [(row['value'], row['status']) for row in published['documents']] == expected


def exercise(workspace):
    source = Path('.local/documents/1001/Data.mdb')
    with source.open('rb') as stream:
        before = hashlib.file_digest(stream, 'sha256').hexdigest()
    root = Tk()
    root.withdraw()
    try:
        app = ValidationApp(root, workspace, legacy=True)
        scripted = workspace.snapshot['batch']['scripted']
        hooks = workspace.snapshot['batch']['hooks']
        check_published(workspace, 'READY', False, [('ABCD', 1), ('WXYZ', 1)])
        app.open_button.invoke()
        assert app.active and app.value.get() == 'ABCD' and app.scan is not None
        app.confirm_button.invoke()
        assert 'exactly four digits' in app.note.cget('text')
        if hooks:
            assert app.field_message.cget('text') == 'REVIEW THE OCR REFERENCE.'
            app.value.set('abcd')
            app.confirm_button.invoke()
            assert 'exactly four digits' in app.note.cget('text')
            assert app.field_message.cget('text') == 'REVIEW THE OCR REFERENCE.'
        if scripted:
            app.value.set('0000')
            app.confirm_button.invoke()
            assert 'blocked by the SQL lookup rule' in app.note.cget('text')
            if hooks:
                assert app.field_message.cget('text') == 'CHECKING REFERENCE.'
            unchanged = workspace.request('read')['documents'][0]
            assert (unchanged['value'], unchanged['status']) == ('ABCD', 1)
        app.value.set('1234')
        app.confirm_button.invoke()
        assert 'saved' in app.note.cget('text'), app.note.cget('text')
        if hooks:
            assert app.field_message.cget('text') == 'REFERENCE CHECK PASSED.'
        check_published(workspace, 'IN_VALIDATION', True, [('ABCD', 1), ('WXYZ', 1)])
        app.next.invoke()
        assert app.position == 2 and app.scan is not None and app.value.get() == 'WXYZ'
        app.pause_button.invoke()
        check_published(workspace, 'PAUSED', False, [('1234', 0), ('WXYZ', 1)])
    finally:
        root.destroy()

    # A new app and bridge instance reread SQL status and the server-side Jet file.
    workspace = LegacyWorkspace(workspace.batch_id)
    root = Tk()
    root.withdraw()
    try:
        app = ValidationApp(root, workspace, legacy=True)
        app.open_button.invoke()
        assert app.active and app.position == 2
        app.previous.invoke()
        assert app.value.get() == '1234'
        app.next.invoke()
        app.confirm_button.invoke()
        assert 'exactly four digits' in app.note.cget('text')
        if hooks:
            assert app.field_message.cget('text') == 'CHECKING REFERENCE.'
        app.value.set('5678')
        app.confirm_button.invoke()
        if hooks:
            assert app.field_message.cget('text') == 'REFERENCE CHECK PASSED.'
        app.finish_button.invoke()
        check_published(workspace, 'DONE', False, [('1234', 0), ('5678', 0)])
    finally:
        root.destroy()
    with source.open('rb') as stream:
        assert hashlib.file_digest(stream, 'sha256').hexdigest() == before
    mode = 'PreProc/PostProc' if hooks else 'scripted' if scripted else 'script-free'
    print(f'PASS: {mode} legacy batch {workspace.batch_id} reached unlocked DONE with both Jet values persisted.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('batch_id', type=int, nargs='?', help='An unused clone ID. Omit to create a clone.')
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--scripted', action='store_true', help='Create a new scripted lookup fixture batch.')
    modes.add_argument('--hooks', action='store_true', help='Create a fixture batch with PreProc and PostProc messages.')
    args = parser.parse_args()
    if args.batch_id and (args.scripted or args.hooks):
        parser.error('Omit creation options when testing a specific existing batch.')
    workspace = LegacyWorkspace(args.batch_id) if args.batch_id else LegacyWorkspace.create(scripted=args.scripted, hooks=args.hooks)
    print(f'Testing isolated legacy batch {workspace.batch_id}.', flush=True)
    exercise(workspace)
