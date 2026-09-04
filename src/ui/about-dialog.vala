/* about-dialog.vala
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

    /* Hand-built rather than an Adw.AboutDialog: that widget files the
     * application's description away behind a "Details" row, and there is no
     * property that puts it on the front page. Everything here is on one page. */
    [GtkTemplate (ui = "/fr/benjaminbellamy/Appairee/about-dialog.ui")]
    public class AboutDialog : Adw.Dialog {

        private const string PROJECT_URL = "https://github.com/sobalap/btd700ctl";
        private const string GPL3_URL = "https://www.gnu.org/licenses/gpl-3.0.html";
        private const string LGPL21_URL = "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html";

        [GtkChild] private unowned Gtk.Label version_label;
        [GtkChild] private unowned Adw.ActionRow project_row;
        [GtkChild] private unowned Adw.ActionRow app_licence_row;
        [GtkChild] private unowned Adw.ActionRow lib_licence_row;

        construct {
            version_label.label = Config.VERSION;

            project_row.activated.connect (() => {
                open (PROJECT_URL);
            });
            app_licence_row.activated.connect (() => {
                open (GPL3_URL);
            });
            lib_licence_row.activated.connect (() => {
                open (LGPL21_URL);
            });
        }

        private void open (string uri) {
            var launcher = new Gtk.UriLauncher (uri);
            launcher.launch.begin (this.get_root () as Gtk.Window, null, (obj, res) => {
                try {
                    launcher.launch.end (res);
                } catch (Error e) {
                    /* Nothing to fall back to, but a silent no-op would leave
                     * the row looking broken. */
                    warning ("could not open %s: %s", uri, e.message);
                }
            });
        }
    }
}
