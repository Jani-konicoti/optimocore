from argparse import ArgumentParser
from tkinter import Tk

from datavalidation_app.legacy import LegacyWorkspace
from datavalidation_app.store import WorkflowError, Workspace
from datavalidation_app.ui import ValidationApp


if __name__ == '__main__':
    parser = ArgumentParser(description='Standalone Optimo Data Validation')
    parser.add_argument('--legacy-fixture', metavar='MODE_OR_BATCH_ID',
                        help='Create or reopen a disposable SQL Server and Jet fixture batch.')
    args = parser.parse_args()
    try:
        if args.legacy_fixture in ('new', 'new-scripted', 'new-hooks'):
            workspace = LegacyWorkspace.create(scripted=args.legacy_fixture == 'new-scripted',
                                               hooks=args.legacy_fixture == 'new-hooks')
            print(f'Created isolated legacy batch {workspace.batch_id}.')
        elif args.legacy_fixture:
            workspace = LegacyWorkspace(int(args.legacy_fixture))
        else:
            workspace = Workspace()
    except (ValueError, WorkflowError) as error:
        parser.exit(1, f'{error}\n')
    root = Tk()
    try:
        ValidationApp(root, workspace, legacy=bool(args.legacy_fixture))
    except WorkflowError as error:
        root.destroy()
        parser.exit(1, f'{error}\n')
    root.mainloop()
