/* language.vala
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

    public class Language {

        public const string[] CODES = { "en", "fr", "de", "es", "it", "nl" };

        /* The code currently in force. */
        public static string current = "en";

        /* A stored choice wins; otherwise follow whatever the session asks for.
         * An unrecognised stored value is ignored rather than honoured, so a
         * hand-edited setting cannot leave the app with no translations. */
        public static string resolve (string stored) {
            foreach (unowned string code in CODES) {
                if (stored == code) {
                    return stored;
                }
            }
            return from_environment ();
        }

        public static void apply (string code) {
            Environment.set_variable ("LANGUAGE", code, true);

            /* gettext has already cached the catalogue it resolved, and will go
             * on using it until told the set has changed. */
            Gettext.invalidate ();

            current = code;
        }

        private static string from_environment () {
            string? requested = Environment.get_variable ("LANGUAGE");
            if (requested == null || requested == "") {
                requested = Environment.get_variable ("LC_ALL");
            }
            if (requested == null || requested == "") {
                requested = Environment.get_variable ("LC_MESSAGES");
            }
            if (requested == null || requested == "") {
                requested = Environment.get_variable ("LANG");
            }
            if (requested == null) {
                return "en";
            }

            foreach (unowned string code in CODES) {
                if (requested.has_prefix (code)) {
                    return code;
                }
            }
            return "en";
        }
    }
}
