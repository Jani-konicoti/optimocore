using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Windows.Forms;

public static class MonitorSessionsCsv
{
    public static void Export(DataGridView grid)
    {
        var selected = new List<string[]>();
        foreach (DataGridViewRow row in grid.Rows)
        {
            if (!row.Selected || row.IsNewRow) continue;
            var fields = new string[6];
            for (int index = 0; index < fields.Length; index++)
                fields[index] = Convert.ToString(row.Cells[index].Value, CultureInfo.InvariantCulture);
            selected.Add(fields);
        }
        if (selected.Count == 0) return;

        using (var dialog = new SaveFileDialog { Filter = "Csv File (*.csv)|*.csv", Title = "Nome file CSV da creare", RestoreDirectory = true })
        {
            if (dialog.ShowDialog(grid.FindForm()) != DialogResult.OK) return;
            try
            {
                using (var file = new FileStream(dialog.FileName, FileMode.CreateNew, FileAccess.Write))
                using (var writer = new StreamWriter(file, new UTF8Encoding(false)))
                    Write(writer, selected);
            }
            catch (IOException error)
            {
                MessageBox.Show(grid.FindForm(), "Errore in esportazione CSV - " + error.Message, "Monitor");
            }
        }
    }

    public static void Write(TextWriter writer, IEnumerable<string[]> selected)
    {
        writer.WriteLine("Processo;Utente;Inizio;Fine;Linea;Durata;");
        int count = 0;
        long seconds = 0;
        foreach (string[] fields in selected)
        {
            int duration;
            if (String.IsNullOrEmpty(fields[1]) ||
                !Int32.TryParse(fields[5], NumberStyles.Integer, CultureInfo.InvariantCulture, out duration))
                continue; // The grid's summary row has no user and an HH:mm:ss duration.
            foreach (string field in fields)
            {
                string value = field ?? "";
                if (value.IndexOfAny(new[] { ';', '"', '\r', '\n' }) >= 0)
                    value = "\"" + value.Replace("\"", "\"\"") + "\"";
                writer.Write(value);
                writer.Write(';');
            }
            writer.WriteLine();
            seconds += duration;
            count++;
        }
        writer.WriteLine(String.Format(CultureInfo.InvariantCulture, ";;;;{0} Sessioni;{1:00}:{2:00}:{3:00};",
            count, seconds / 3600, (seconds / 60) % 60, seconds % 60));
    }
}
