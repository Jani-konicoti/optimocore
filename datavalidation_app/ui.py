import sqlite3
import tkinter as tk
from pathlib import Path
from tkinter import ttk

from datavalidation_app.store import WorkflowError

try:
    from PIL import Image, ImageTk
except ImportError:
    Image = ImageTk = None

FIXTURE_IMAGES = Path(__file__).resolve().parents[1] / '.local' / 'documents' / '1001'


class ValidationApp:
    def __init__(self, root, workspace, *, legacy=False):
        self.root = root
        self.workspace = workspace
        self.legacy = legacy
        self.batch_id = None
        self.position = None
        self.records = []
        self.scan = None
        self.scan_preview = None
        self.value = tk.StringVar()
        root.title('Optimo Data Validation')
        root.geometry('1120x720')
        root.minsize(900, 620)

        ttk.Style().configure('Title.TLabel', font=('Segoe UI', 21, 'bold'))
        ttk.Style().configure('Section.TLabel', font=('Segoe UI', 13, 'bold'))
        frame = ttk.Frame(root, padding=(24, 18))
        frame.pack(fill='both', expand=True)
        ttk.Label(frame, text='Data Validation', style='Title.TLabel').pack(anchor='w')
        description = 'Isolated SQL Server and Jet fixture' if legacy else 'Local workspace · Synthetic documents'
        ttk.Label(frame, text=description).pack(anchor='w', pady=(3, 16))
        ttk.Separator(frame).pack(fill='x')

        content = ttk.Panedwindow(frame, orient='horizontal')
        content.pack(fill='both', expand=True, pady=14)
        queue = ttk.Frame(content, padding=(0, 4, 16, 0))
        content.add(queue, weight=1)
        ttk.Label(queue, text='Batch queue', style='Section.TLabel').pack(anchor='w', pady=(0, 8))
        self.queue = ttk.Treeview(queue, columns=('state',), show='tree headings', height=6, selectmode='browse')
        self.queue.heading('#0', text='Batch')
        self.queue.heading('state', text='State')
        self.queue.column('#0', width=144, minwidth=130)
        self.queue.column('state', width=92, minwidth=86)
        self.queue.pack(fill='x')
        self.queue.bind('<<TreeviewSelect>>', self.update_open_button)
        self.queue.bind('<Double-1>', lambda _: self.run(self.open_batch))
        self.queue.bind('<Return>', lambda _: self.run(self.open_batch))
        self.open_button = ttk.Button(queue, text='Open batch', command=lambda: self.run(self.open_batch))
        self.open_button.pack(anchor='w', pady=(10, 18))
        ttk.Label(queue, text='Documents', style='Section.TLabel').pack(anchor='w', pady=(0, 8))
        self.documents = ttk.Treeview(queue, columns=('state',), show='tree headings', height=7, selectmode='browse')
        self.documents.heading('#0', text='Document')
        self.documents.heading('state', text='Review')
        self.documents.column('#0', width=144, minwidth=130)
        self.documents.column('state', width=92, minwidth=86)
        self.documents.pack(fill='x')
        self.documents.bind('<<TreeviewSelect>>', self.pick_document)

        review = ttk.Frame(content, padding=(16, 4, 2, 0))
        content.add(review, weight=3)
        toolbar = ttk.Frame(review)
        toolbar.pack(fill='x', pady=(0, 8))
        self.title = ttk.Label(toolbar, text='Document review', style='Section.TLabel')
        self.title.pack(side='left')
        self.next = ttk.Button(toolbar, text='Next', command=lambda: self.run(lambda: self.move(1)))
        self.next.pack(side='right')
        self.previous = ttk.Button(toolbar, text='Previous', command=lambda: self.run(lambda: self.move(-1)))
        self.previous.pack(side='right', padx=(0, 6))
        self.preview = tk.Canvas(review, height=270, background='#e5ebea', highlightthickness=0)
        self.preview.pack(fill='both', expand=True)
        self.preview.bind('<Configure>', lambda _: self.draw_document())

        editor = ttk.Frame(review, padding=(0, 14, 0, 0))
        editor.pack(fill='x')
        ttk.Label(editor, text='Reference number', style='Section.TLabel').pack(anchor='w')
        ttk.Label(editor, text='Enter the four digits shown on the document.').pack(anchor='w', pady=(2, 7))
        field = ttk.Frame(editor)
        field.pack(fill='x')
        self.entry = ttk.Entry(field, width=18, textvariable=self.value, font=('Segoe UI', 12))
        self.entry.pack(side='left', ipady=3)
        self.entry.bind('<Return>', lambda _: self.run(self.confirm))
        self.confirm_button = ttk.Button(field, text='Confirm reference', command=lambda: self.run(self.confirm))
        self.confirm_button.pack(side='left', padx=(8, 0))
        self.note = ttk.Label(editor, wraplength=430)
        self.note.pack(anchor='w', pady=(8, 0))
        self.field_message = ttk.Label(editor, wraplength=430)

        ttk.Separator(frame).pack(fill='x', pady=(0, 12))
        footer = ttk.Frame(frame)
        footer.pack(fill='x')
        self.summary = ttk.Label(footer)
        self.summary.pack(side='left')
        self.finish_button = ttk.Button(footer, text='Complete batch', command=lambda: self.run(self.finish))
        self.finish_button.pack(side='right')
        self.pause_button = ttk.Button(footer, text='Pause batch', command=lambda: self.run(self.pause))
        self.pause_button.pack(side='right', padx=(0, 6))
        self.refresh()

    def run(self, action):
        try:
            action()
        except WorkflowError as error:
            self.note.configure(text=str(error), foreground='#94252f')
            self.show_field_message(error.field_message)
        except sqlite3.Error:
            self.note.configure(text='Could not access local storage. Try the action again.', foreground='#94252f')

    def update_open_button(self, _=None):
        selection = self.queue.selection()
        state = self.queue.set(selection[0], 'state') if selection else ''
        self.open_button.configure(text={'Paused': 'Resume batch', 'Done': 'Review batch'}.get(state, 'Open batch'),
                                   state='normal' if selection else 'disabled')

    def refresh(self, message=''):
        batches = self.workspace.batches()
        names = {'READY': 'Ready', 'IN_VALIDATION': 'In review', 'PAUSED': 'Paused', 'DONE': 'Done'}
        wanted = self.queue.selection() or tuple(str(b['id']) for b in batches[:1])
        for batch in batches:
            key = str(batch['id'])
            values = (names[batch['state']],)
            if self.queue.exists(key):
                self.queue.item(key, values=values)
            else:
                self.queue.insert('', 'end', iid=key, text=f"{key}  {batch['name']}", values=values)
        if wanted:
            self.queue.selection_set(wanted)
        self.update_open_button()
        batch = next((b for b in batches if b['id'] == self.batch_id), None)
        self.records = self.workspace.documents(self.batch_id) if batch else []
        self.active = bool(batch and batch['state'] == 'IN_VALIDATION' and batch.get('editable', True))
        self.position = self.position or (batch['position'] if batch else None)
        self.documents.delete(*self.documents.get_children())
        for document in self.records:
            key = str(document['position'])
            self.documents.insert('', 'end', iid=key, text=f'Document {key}',
                                  values=('Confirmed' if document['status'] == 0 else 'Pending',))
        if self.position:
            self.documents.selection_set(str(self.position))
        self.summary.configure(text=(f"Batch {self.batch_id}  ·  {names[batch['state']]}  ·  "
                                     f"{batch['confirmed']} of {batch['total']} confirmed" if batch else 'Select a batch to begin.'))
        self.pause_button.configure(state='normal' if self.active else 'disabled')
        self.finish_button.configure(state='normal' if self.active and batch['total'] == batch['confirmed'] else 'disabled')
        self.render_record(message)

    def render_record(self, message=''):
        record = next((d for d in self.records if d['position'] == self.position), None)
        self.scan = None
        preview_error = ''
        if record and record.get('image'):
            try:
                if Image is None:
                    raise OSError
                with Image.open(record['image']) as image:
                    self.scan = image.convert('RGB')
            except OSError:
                preview_error = 'Cannot display this TIFF. Check that Pillow and the fixture image are available.'
        elif record and Image is not None and self.batch_id == 1001 and self.position in (1, 2):
            name = 'reference.tif' if self.position == 1 else 'reference-2.tif'
            try:
                with Image.open(FIXTURE_IMAGES / name) as image:
                    self.scan = image.convert('RGB')
            except OSError:
                pass  # The built-in synthetic sheet also runs on a clean checkout.
        self.title.configure(text=f'Document {self.position} of {len(self.records)}' if record else 'Document review')
        self.value.set(record['value'] if record else '')
        editable = record and self.active and not preview_error
        self.entry.configure(state='normal' if editable else 'readonly')
        self.confirm_button.configure(state='normal' if editable else 'disabled')
        self.previous.configure(state='normal' if record and self.position > 1 else 'disabled')
        self.next.configure(state='normal' if record and self.position < len(self.records) else 'disabled')
        self.note.configure(text=preview_error or message, foreground='#94252f' if preview_error else '#245946')
        self.show_field_message('')
        self.draw_document()

    def show_field_message(self, message):
        self.field_message.configure(text=message)
        if message:
            self.field_message.pack(anchor='w', pady=(4, 0))
        else:
            self.field_message.pack_forget()

    def draw_document(self):
        self.preview.delete('all')
        self.scan_preview = None
        w, h = self.preview.winfo_width(), self.preview.winfo_height()
        if not self.records or self.position is None:
            self.preview.create_text(w / 2, h / 2, text='Open a batch to see its documents.', fill='#36504a', font=('Segoe UI', 12))
            return
        if self.scan is not None and w > 32 and h > 24:
            fitted = self.scan.copy()
            fitted.thumbnail((w - 32, h - 24))
            self.scan_preview = ImageTk.PhotoImage(fitted, master=self.root)
            self.preview.create_image(w / 2, h / 2, image=self.scan_preview)
            return
        record = next(d for d in self.records if d['position'] == self.position)
        if record.get('image'):
            self.preview.create_text(w / 2, h / 2, text='TIFF preview unavailable.', fill='#36504a', font=('Segoe UI', 12))
            return
        paper_w, paper_h = min(w - 32, 428), min(h - 24, 410)
        if paper_w < 220 or paper_h < 110:
            return
        x, y = (w - paper_w) / 2, (h - paper_h) / 2
        self.preview.create_rectangle(x, y, x + paper_w, y + paper_h, fill='#fcfbf5', outline='#b8c4bd')
        self.preview.create_text(x + 22, y + 19, anchor='nw', text='Reference sheet', fill='#182f2a', font=('Segoe UI', 16, 'bold'))
        self.preview.create_text(x + 22, y + 52, anchor='nw', text=f'Synthetic document {record["position"]}', fill='#465650', font=('Segoe UI', 10))
        self.preview.create_line(x + 22, y + 79, x + paper_w - 22, y + 79, fill='#bac5bf')
        if paper_h > 165:
            self.preview.create_text(x + 22, y + 103, anchor='nw', text='Reference number', fill='#465650', font=('Segoe UI', 10))
        self.preview.create_text(x + 22, y + (131 if paper_h > 165 else 85), anchor='nw',
                                 text=record['scanned_reference'], fill='#182f2a', font=('Consolas', 24, 'bold'))

    def open_batch(self):
        selection = self.queue.selection()
        if not selection:
            return
        batch_id = int(selection[0])
        if self.queue.set(selection[0], 'state') != 'Done':
            self.workspace.open_batch(batch_id)
        self.batch_id, self.position = batch_id, None
        self.refresh()
        if self.active:
            self.entry.focus_set()
            self.entry.selection_range(0, 'end')

    def pick_document(self, _):
        selection = self.documents.selection()
        if selection and int(selection[0]) != self.position:
            self.run(lambda: self.show_document(int(selection[0])))

    def show_document(self, position):
        if self.active:
            self.workspace.select_document(self.batch_id, position)
        self.position = position
        self.documents.selection_set(str(position))
        self.render_record()

    def move(self, delta):
        self.show_document(self.position + delta)

    def confirm(self):
        if self.confirm_button.instate(('!disabled',)):
            field_message = self.workspace.confirm(self.batch_id, self.position, self.value.get())
            message = ('Reference saved to the working copy. Pause or complete to publish.'
                       if self.legacy else 'Reference confirmed and saved.')
            self.refresh(message)
            self.show_field_message(field_message or '')

    def pause(self):
        self.workspace.pause(self.batch_id)
        self.refresh('Batch paused. Confirmed references are saved.')

    def finish(self):
        self.workspace.finish(self.batch_id)
        self.refresh('Batch complete. All references are saved.')
