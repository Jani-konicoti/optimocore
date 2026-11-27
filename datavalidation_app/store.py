"""Storage and workflow for the standalone synthetic validation workspace."""

import re
import sqlite3
from contextlib import contextmanager
from pathlib import Path


DEFAULT_DATABASE = Path(__file__).resolve().parents[1] / ".local" / "standalone-validation" / "workspace.sqlite"


class WorkflowError(ValueError):
    """An operator action could not be completed."""

    def __init__(self, message, *, field_message=''):
        super().__init__(message)
        self.field_message = field_message


class Workspace:
    def __init__(self, path=DEFAULT_DATABASE):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.transaction() as db:
            db.execute("""CREATE TABLE IF NOT EXISTS batch (
                id INTEGER PRIMARY KEY, name TEXT NOT NULL,
                state TEXT NOT NULL CHECK(state IN ('READY','IN_VALIDATION','PAUSED','DONE')),
                position INTEGER NOT NULL)""")
            db.execute("""CREATE TABLE IF NOT EXISTS document (
                batch_id INTEGER NOT NULL REFERENCES batch(id), position INTEGER NOT NULL,
                scanned_reference TEXT NOT NULL, value TEXT NOT NULL,
                status INTEGER NOT NULL CHECK(status IN (0,1)),
                PRIMARY KEY(batch_id, position))""")
            if db.execute("INSERT OR IGNORE INTO batch VALUES (1001, 'Reference review', 'READY', 1)").rowcount:
                db.executemany("INSERT INTO document VALUES (1001, ?, ?, ?, 1)",
                               [(1, '1234', 'ABCD'), (2, '5678', 'WXYZ')])

    @contextmanager
    def transaction(self, *, write=True):
        db = sqlite3.connect(self.path)
        db.row_factory = sqlite3.Row
        try:
            db.execute("PRAGMA foreign_keys = ON")
            with db:
                db.execute("BEGIN IMMEDIATE" if write else "BEGIN")
                yield db
        finally:
            db.close()

    def batches(self):
        with self.transaction(write=False) as db:
            return [dict(row) for row in db.execute("""SELECT b.id, b.name, b.state, b.position,
                COUNT(d.position) AS total, SUM(CASE WHEN d.status = 0 THEN 1 ELSE 0 END) AS confirmed
                FROM batch b LEFT JOIN document d ON b.id = d.batch_id GROUP BY b.id ORDER BY b.id""")]

    def documents(self, batch_id):
        with self.transaction(write=False) as db:
            return [dict(row) for row in db.execute(
                "SELECT * FROM document WHERE batch_id = ? ORDER BY position", (batch_id,))]

    @staticmethod
    def require_active(db, batch_id):
        row = db.execute("SELECT state FROM batch WHERE id = ?", (batch_id,)).fetchone()
        if row is None or row['state'] != 'IN_VALIDATION':
            raise WorkflowError('Open the batch to make changes.')

    def open_batch(self, batch_id):
        with self.transaction() as db:
            if not db.execute("""UPDATE batch SET state = 'IN_VALIDATION'
                WHERE id = ? AND state IN ('READY', 'PAUSED', 'IN_VALIDATION')""", (batch_id,)).rowcount:
                raise WorkflowError('This batch is no longer available for validation.')

    def select_document(self, batch_id, position):
        with self.transaction() as db:
            self.require_active(db, batch_id)
            if not db.execute("""UPDATE batch SET position = ? WHERE id = ? AND EXISTS (
                SELECT 1 FROM document WHERE batch_id = ? AND position = ?)""",
                              (position, batch_id, batch_id, position)).rowcount:
                raise WorkflowError('This document does not exist in the batch.')

    def confirm(self, batch_id, position, value):
        if re.fullmatch(r'[0-9]{4}', value) is None:
            raise WorkflowError('Reference must contain exactly four digits (0–9).')
        with self.transaction() as db:
            self.require_active(db, batch_id)
            if not db.execute("UPDATE document SET value = ?, status = 0 WHERE batch_id = ? AND position = ?",
                              (value, batch_id, position)).rowcount:
                raise WorkflowError('This document does not exist in the batch.')

    def pause(self, batch_id):
        with self.transaction() as db:
            self.require_active(db, batch_id)
            db.execute("UPDATE batch SET state = 'PAUSED' WHERE id = ?", (batch_id,))

    def finish(self, batch_id):
        with self.transaction() as db:
            self.require_active(db, batch_id)
            if not db.execute("SELECT 1 FROM document WHERE batch_id = ?", (batch_id,)).fetchone():
                raise WorkflowError('This batch has no documents.')
            if db.execute("SELECT 1 FROM document WHERE batch_id = ? AND status = 1", (batch_id,)).fetchone():
                raise WorkflowError('Confirm every document before completing the batch.')
            db.execute("UPDATE batch SET state = 'DONE' WHERE id = ?", (batch_id,))
