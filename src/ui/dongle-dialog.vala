/* dongle-dialog.vala
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

    [GtkTemplate (ui = "/fr/benjaminbellamy/Appairee/dongle-dialog.ui")]
    public class DongleDialog : Adw.Dialog {

        [GtkChild] private unowned Gtk.Label model_label;
        [GtkChild] private unowned Gtk.Label manufacturer_label;
        [GtkChild] private unowned Gtk.Label firmware_label;
        [GtkChild] private unowned Gtk.Label serial_label;

        public void show_snapshot (Snapshot snapshot) {
            model_label.label = snapshot.product;
            manufacturer_label.label = snapshot.manufacturer;
            firmware_label.label = snapshot.firmware;
            serial_label.label = snapshot.serial;
        }
    }
}
