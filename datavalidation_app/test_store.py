import tempfile
import unittest
from pathlib import Path

from datavalidation_app.store import WorkflowError, Workspace


class WorkspaceTest(unittest.TestCase):
    def test_two_document_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'workspace.sqlite'
            workspace = Workspace(path)
            self.assertEqual(workspace.batches()[0]['state'], 'READY')
            workspace.open_batch(1001)
            with self.assertRaises(WorkflowError):
                workspace.finish(1001)
            with self.assertRaises(WorkflowError):
                workspace.confirm(1001, 1, 'ABCD')
            self.assertEqual(workspace.documents(1001)[0]['status'], 1)
            workspace.confirm(1001, 1, '1234')
            workspace.select_document(1001, 2)
            workspace.pause(1001)

            workspace = Workspace(path)
            batch = workspace.batches()[0]
            self.assertEqual((batch['state'], batch['position'], batch['confirmed']), ('PAUSED', 2, 1))
            self.assertEqual(workspace.documents(1001)[0]['value'], '1234')
            with self.assertRaises(WorkflowError):
                workspace.confirm(1001, 2, '5678')
            workspace.open_batch(1001)
            workspace.select_document(1001, 1)
            workspace.select_document(1001, 2)
            with self.assertRaises(WorkflowError):
                workspace.confirm(1001, 2, 'WXYZ')
            workspace.confirm(1001, 2, '5678')
            workspace.finish(1001)

            workspace = Workspace(path)
            self.assertEqual(workspace.batches()[0]['state'], 'DONE')
            self.assertEqual([(d['value'], d['status']) for d in workspace.documents(1001)],
                             [('1234', 0), ('5678', 0)])
            with self.assertRaises(WorkflowError):
                workspace.open_batch(1001)
