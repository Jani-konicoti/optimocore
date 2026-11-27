"""SQL Server and 32-bit Jet adapter for the marked local document fixture."""

import json
import os
import secrets
import subprocess
from pathlib import Path

from datavalidation_app.store import WorkflowError

BRIDGE = Path(__file__).resolve().parents[1] / 'scripts' / 'Invoke-LegacyBatch.ps1'


class LegacyWorkspace:
    def __init__(self, batch_id):
        self.batch_id = batch_id
        self.snapshot = None

    @classmethod
    def create(cls, *, scripted=False, hooks=False):
        workspace = cls(10_000_000 + secrets.randbelow(90_000_000))
        action = 'create-hooks' if hooks else 'create-scripted' if scripted else 'create'
        workspace.request(action)
        return workspace

    def request(self, action, **arguments):
        powershell = Path(os.environ.get('WINDIR', r'C:\Windows')) / 'SysWOW64/WindowsPowerShell/v1.0/powershell.exe'
        try:
            completed = subprocess.run(
                [str(powershell), '-NoProfile', '-NonInteractive', '-ExecutionPolicy',
                 'RemoteSigned', '-File', str(BRIDGE)],
                input=json.dumps(dict(action=action, id=self.batch_id, **arguments)),
                encoding='utf-8', capture_output=True, check=True, timeout=35,
                creationflags=subprocess.CREATE_NO_WINDOW,
            )
            payload = json.loads(completed.stdout)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            raise WorkflowError('The 32-bit legacy fixture bridge could not complete the request.') from error
        if 'error' in payload:
            raise WorkflowError(payload['error'])
        return payload['result']

    def batches(self):
        self.snapshot = self.request('read')
        return [self.snapshot['batch']]

    def require_batch(self, batch_id):
        if batch_id != self.batch_id:
            raise WorkflowError('This workspace only supports its selected isolated batch.')

    def documents(self, batch_id):
        self.require_batch(batch_id)
        return (self.snapshot or self.request('read'))['documents']

    def select_document(self, batch_id, position):
        if position not in {document['position'] for document in self.documents(batch_id)}:
            raise WorkflowError('This document does not exist in the batch.')

    def open_batch(self, batch_id):
        self.require_batch(batch_id)
        self.request('open')

    def confirm(self, batch_id, position, value):
        self.require_batch(batch_id)
        result = self.request('confirm', position=position, value=value)
        message = result['field_message']
        if 'error' in result:
            raise WorkflowError(result['error'], field_message=message)
        return message

    def pause(self, batch_id):
        self.require_batch(batch_id)
        self.request('pause')

    def finish(self, batch_id):
        self.require_batch(batch_id)
        self.request('finish')
