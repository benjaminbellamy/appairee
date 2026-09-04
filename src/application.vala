/* application.vala
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

    public class Application : Adw.Application {

        private Settings settings;
        private SimpleAction language_action;

        public Application () {
            Object (
                application_id: Config.APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
        }

        construct {
            settings = new Settings (Config.APP_ID);

            ActionEntry[] action_entries = {
                { "about", on_about_action },
                { "quit", on_quit_action },
            };
            add_action_entries (action_entries, this);
            // gtk4.vapi declares accels as `string[]`, but GTK takes
            // `const char * const *`, so valac emits a const-dropping call. This
            // warns at build time and cannot be silenced with -Wno- flags; it is
            // harmless because GTK does not write to the array.
            set_accels_for_action ("app.quit", { "<primary>q" });

            language_action = new SimpleAction.stateful (
                "language",
                VariantType.STRING,
                new Variant.string (Language.current)
            );
            language_action.activate.connect (on_language_action);
            add_action (language_action);
        }

        public override void startup () {
            base.startup ();

            // GTK 4.10 deprecated GtkStyleContext as a whole, but
            // add_provider_for_display is still the only way to install a
            // display-wide provider, so the warning it emits is unavoidable.
            /* The dongle artwork is carried in the resource bundle rather than
             * installed as themed icons: it belongs to this application and
             * nothing else should be looking it up by name. */
            Gtk.IconTheme.get_for_display (Gdk.Display.get_default ())
                .add_resource_path ("/fr/benjaminbellamy/Appairee/icons");

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/fr/benjaminbellamy/Appairee/style.css");
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        public override void activate () {
            var window = active_window as Window;
            if (window == null) {
                window = new Window (this);
            }
            window.present ();
        }

        private void on_language_action (Variant? parameter) {
            if (parameter == null) {
                return;
            }

            var code = parameter.get_string ();
            if (code == Language.current) {
                return;
            }

            settings.set_string ("language", code);
            Language.apply (code);
            language_action.set_state (parameter);

            /* Every visible string was translated when its widget was built, so
             * the window is rebuilt rather than walked and re-labelled. */
            hold ();

            var previous = active_window as Window;
            if (previous != null) {
                previous.shutdown ();
                previous.destroy ();
            }
            new Window (this).present ();

            release ();
        }

        private void on_about_action () {
            new AboutDialog ().present (active_window);
        }

        private void on_quit_action () {
            quit ();
        }
    }
}
