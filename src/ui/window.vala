/* window.vala
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

    [GtkTemplate (ui = "/fr/benjaminbellamy/Appairee/window.ui")]
    public class Window : Adw.ApplicationWindow {

        [GtkChild] private unowned Gtk.Stack device_stack;
        [GtkChild] private unowned Adw.StatusPage absent_page;
        [GtkChild] private unowned Gtk.Box permission_box;
        [GtkChild] private unowned Gtk.Label udev_command;
        [GtkChild] private unowned Gtk.Button copy_button;
        [GtkChild] private unowned Adw.Banner rejected_banner;
        [GtkChild] private unowned Adw.ActionRow led_row;
        [GtkChild] private unowned Adw.ComboRow mode_row;
        [GtkChild] private unowned Adw.ComboRow codec_row;
        [GtkChild] private unowned Adw.ActionRow volume_row;
        [GtkChild] private unowned Gtk.Scale volume_scale;
        [GtkChild] private unowned Gtk.Label state_label;
        [GtkChild] private unowned Gtk.Label le_audio_label;
        [GtkChild] private unowned Gtk.Label transport_label;
        [GtkChild] private unowned Gtk.Label sink_label;
        [GtkChild] private unowned Gtk.Label quality_label;

        private Settings settings;
        private Device device = new Device ();

        private LedEntry[] led_entries;
        private LedSwatch led_swatch = new LedSwatch (36);

        private Btd700.Codec[] codec_ids = {};
        private Snapshot? latest = null;
        private ManualDialog? manual = null;

        /* Raised while the rows are being filled in from a snapshot, so that
         * writing a value back into the widgets is not mistaken for the user
         * choosing it. */
        private bool syncing = false;

        /* The same guard for the volume slider, which arrives on its own signal
         * rather than with a snapshot. Without it, showing the level the dongle
         * reports would immediately be sent back to the dongle as a change. */
        private bool syncing_volume = false;

        /* The decibel figure for each step, as the dongle reports it, indexed
         * from volume_floor. Kept so the row can be labelled while dragging. */
        private long[] volume_millibels = {};
        private long volume_floor = 0;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            settings = new Settings (Config.APP_ID);
            settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
            settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
            settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

            udev_command.label = udev_rule_command ();
            copy_button.clicked.connect (on_copy_command);

            led_entries = Led.all ();
            led_row.add_prefix (led_swatch);
            add_dialog_actions ();

            mode_row.notify["selected"].connect (on_mode_selected);
            codec_row.notify["selected"].connect (on_codec_selected);

            volume_scale.value_changed.connect (on_volume_changed);

            device.updated.connect (on_device_updated);
            device.volume_updated.connect (on_volume_updated);
            device.mode_rejected.connect (() => {
                rejected_banner.revealed = true;
            });
            device.start ();

            close_request.connect (() => {
                shutdown ();
                return false;
            });

            update_light ();
        }

        /* Stops the worker before the window goes away. Destroying a window does
         * not emit close-request, so switching language would otherwise leave a
         * second driver running against the same dongle. */
        public void shutdown () {
            device.stop ();
        }

        private void add_dialog_actions () {
            var about_dongle = new SimpleAction ("about-dongle", null);
            about_dongle.activate.connect (() => {
                var dialog = new DongleDialog ();
                if (latest != null && latest.present) {
                    dialog.show_snapshot (latest);
                }
                dialog.present (this);
            });
            add_action (about_dongle);

            var open_manual = new SimpleAction ("manual", null);
            open_manual.activate.connect (() => {
                manual = new ManualDialog ();
                manual.set_current (latest != null ? Led.current (latest) : -1);
                manual.closed.connect (() => {
                    manual = null;
                });
                manual.present (this);
            });
            add_action (open_manual);
        }

        private void on_device_updated (Snapshot snapshot) {
            latest = snapshot;

            if (!snapshot.present) {
                absent_page.description = describe_absence (snapshot.error);
                device_stack.visible_child_name = "absent";
            } else {
                device_stack.visible_child_name = "present";

                syncing = true;

                /* "None" is what the library calls state 0, which is what the
                 * dongle reports while it is in pairing mode. That word means
                 * nothing to anyone reading it. */
                state_label.label = snapshot.state == Btd700.DongleState.NONE
                    ? _("Pairing")
                    : Btd700.dongle_state_string (snapshot.state);
                le_audio_label.label = Btd700.le_audio_state_string (snapshot.le_audio);
                transport_label.label = Btd700.transport_mode_string (snapshot.transport);
                sink_label.label = Btd700.sink_mode_string (snapshot.sink);
                quality_label.label = "%s · %s".printf (
                    Btd700.audio_frequency_string (snapshot.frequency),
                    Btd700.audio_resolution_string (snapshot.resolution));

                mode_row.selected = (uint) snapshot.mode;
                sync_codecs (snapshot);

                syncing = false;
            }

            update_light ();

            if (manual != null) {
                manual.set_current (Led.current (snapshot));
            }
        }

        private void update_light () {
            int current = latest != null ? Led.current (latest) : -1;

            if (current >= 0) {
                led_swatch.show_entry (led_entries[current]);
                led_row.title = led_entries[current].meaning;
                /* How the light behaves is already visible in the swatch, so the
                 * wording only needs to be there for whoever looks for it. */
                led_row.tooltip_text = led_entries[current].description;
                return;
            }

            led_swatch.show_entry (null);
            led_row.title = (latest == null || !latest.present)
                ? _("No dongle connected")
                : _("The light cannot be read in this state");
            led_row.tooltip_text = null;
        }

        private void sync_codecs (Snapshot snapshot) {
            var names = new Gtk.StringList (null);
            Btd700.Codec[] ids = {};
            uint selected = Gtk.INVALID_LIST_POSITION;

            for (int i = 0; i <= (int) Btd700.Codec.LC3; i++) {
                if ((snapshot.supported_codecs & (1 << i)) == 0) {
                    continue;
                }

                if ((snapshot.active_codecs & (1 << i)) != 0) {
                    selected = (uint) ids.length;
                }

                names.append (Btd700.codec_string ((Btd700.Codec) i));
                ids += (Btd700.Codec) i;
            }

            codec_ids = ids;
            codec_row.model = names;
            codec_row.selected = selected;
            codec_row.sensitive = ids.length > 0;
        }

        private void on_mode_selected () {
            if (syncing) {
                return;
            }
            rejected_banner.revealed = false;
            device.request_audio_mode ((Btd700.AudioMode) mode_row.selected);
        }

        private void on_volume_updated (VolumeState state) {
            volume_row.visible = state.available;
            if (!state.available) {
                return;
            }

            volume_millibels = state.millibels;
            volume_floor = state.min;

            syncing_volume = true;
            volume_scale.set_range ((double) state.min, (double) state.max);
            volume_scale.set_increments (1, 1);
            volume_scale.set_value ((double) state.value);
            syncing_volume = false;
        }

        private void on_volume_changed () {
            long step = (long) Math.round (volume_scale.get_value ());

            /* Updated even while syncing, so the row follows the slider as it
             * is dragged rather than waiting for the dongle to be read back. */
            volume_row.subtitle = describe_level (step);

            if (syncing_volume) {
                return;
            }
            device.request_volume (step);
        }

        /* The dongle reports hundredths of a decibel and its own step is the
         * unit the slider moves in, so neither number is scaled on the way in
         * or on the way out. */
        private string describe_level (long step) {
            var index = (int) (step - volume_floor);
            if (index < 0 || index >= volume_millibels.length) {
                return "";
            }
            return _("%.2f dB").printf (volume_millibels[index] / 100.0);
        }

        private void on_codec_selected () {
            if (syncing || codec_row.selected >= (uint) codec_ids.length) {
                return;
            }
            device.request_codec (codec_ids[codec_row.selected]);
        }

        private string describe_absence (Btd700.Error error) {
            /* The library cannot tell "not plugged in" apart from "not allowed
             * to open it", so both are covered: the sentence above the fold, and
             * the fix below it. */
            /* Only worth showing when there is no rule to be found. A native
             * package installs one at install time, and inside a Flatpak this
             * looks at the sandbox's own directories, which never contain one —
             * which is the right answer there, since the user does have to
             * install it by hand. */
            permission_box.visible = (error == Btd700.Error.ERR_DEVICE_NOT_FOUND)
                && !udev_rule_installed ();

            if (error == Btd700.Error.ERR_DEVICE_NOT_FOUND) {
                return _("Plug in a Sennheiser BTD 700 and it will appear here.");
            }

            return _("The dongle could not be opened: %s").printf (Btd700.error_string (error));
        }

        private static bool udev_rule_installed () {
            foreach (unowned string directory in
                     new string[] { "/etc/udev/rules.d", "/usr/lib/udev/rules.d", "/lib/udev/rules.d" }) {
                try {
                    var entries = Dir.open (directory);
                    string? name;
                    while ((name = entries.read_name ()) != null) {
                        if (name.has_suffix (".rules") &&
                            (name.contains ("btd700") || name.contains ("appairee"))) {
                            return true;
                        }
                    }
                } catch (FileError e) {
                    /* The directory simply may not exist; that is not an error. */
                }
            }
            return false;
        }

        /* Telling someone to "copy the file that ships with the app" is useless
         * when the app is a Flatpak: the rule then sits under a path with a hash
         * in it that nobody could guess. Flatpak records that path in
         * /.flatpak-info, so the exact command can be shown instead. */
        private string udev_rule_command () {
            var directory = Config.PKGDATADIR;

            if (FileUtils.test ("/.flatpak-info", FileTest.EXISTS)) {
                try {
                    var info = new KeyFile ();
                    info.load_from_file ("/.flatpak-info", KeyFileFlags.NONE);
                    directory = info.get_string ("Instance", "app-path") + "/share/appairee";
                } catch (Error e) {
                    warning ("could not read /.flatpak-info: %s", e.message);
                }
            }

            return "sudo cp %s/99-btd700.rules /etc/udev/rules.d/ && sudo udevadm control --reload-rules && sudo udevadm trigger".printf (directory);
        }

        private void on_copy_command () {
            get_clipboard ().set_text (udev_command.label);

            copy_button.label = _("Copied");
            Timeout.add_seconds (2, () => {
                copy_button.label = _("Copy Command");
                return Source.REMOVE;
            });
        }
    }
}
