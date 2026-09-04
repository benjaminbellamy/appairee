/* manual-dialog.vala
 *
 * Copyright 2026 Benjamin Bellamy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Appairee {

    [GtkTemplate (ui = "/fr/benjaminbellamy/Appairee/manual-dialog.ui")]
    public class ManualDialog : Adw.Dialog {

        [GtkChild] private unowned Adw.PreferencesGroup led_group;

        private Gtk.Image[] marks;

        construct {
            var entries = Led.all ();
            marks = new Gtk.Image[entries.length];

            for (int i = 0; i < entries.length; i++) {
                unowned LedEntry entry = entries[i];

                var row = new Adw.ActionRow () {
                    title = entry.description,
                    subtitle = entry.meaning,
                    subtitle_lines = 0
                };

                var swatch = new LedSwatch (36);
                swatch.show_entry (entry);
                row.add_prefix (swatch);

                var mark = new Gtk.Image.from_icon_name ("object-select-symbolic") {
                    valign = Gtk.Align.CENTER,
                    visible = false,
                    tooltip_text = _("The dongle is showing this right now")
                };
                mark.add_css_class ("accent");
                row.add_suffix (mark);
                marks[i] = mark;

                led_group.add (row);
            }
        }

        public void set_current (int current) {
            for (int i = 0; i < marks.length; i++) {
                marks[i].visible = (i == current);
            }
        }
    }
}
