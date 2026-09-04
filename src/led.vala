/* led.vala
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

    /* How the light behaves. */
    public enum LedPattern {
        STEADY,
        DIM,
        FLASH,      // on and off continuously
        FLASH3,     // three flashes, then a pause, then again
        ALTERNATE   // primary, then secondary, back and forth
    }

    public class LedEntry : Object {
        public string primary;              // CSS class carrying the colour
        public string? secondary;           // second colour, ALTERNATE only
        public LedPattern pattern;
        public string description;          // how the light behaves
        public string meaning;              // what it tells you

        public LedEntry (string primary, string? secondary, LedPattern pattern,
                         string description, string meaning) {
            this.primary = primary;
            this.secondary = secondary;
            this.pattern = pattern;
            this.description = description;
            this.meaning = meaning;
        }

        /* Everything about the appearance that never changes. The colour is not
         * here: it is applied per frame, because it alternates for one entry. */
        public string[] modifier_classes () {
            return pattern == LedPattern.DIM ? new string[] { "led-dim" } : new string[0];
        }

        /* Whether the light is lit at t seconds since the clock started. */
        public bool lit_at (double t) {
            switch (pattern) {
                case LedPattern.FLASH:
                    return Math.fmod (t, 1.0) < 0.5;

                case LedPattern.FLASH3:
                    /* Three 250 ms pulses 250 ms apart, then a pause, so that
                     * the "3×" in the manual is actually countable. */
                    double phase = Math.fmod (t, 2.5);
                    return phase < 1.25 && ((int) (phase / 0.25)) % 2 == 0;

                default:
                    return true;
            }
        }

        public string colour_at (double t) {
            if (pattern == LedPattern.ALTERNATE && secondary != null) {
                return Math.fmod (t, 1.4) < 0.7 ? primary : secondary;
            }
            return primary;
        }
    }

    /* One clock for every light on screen, so they blink in step and the app
     * does not carry a timer per row. */
    public class LedAnimator {

        private const uint INTERVAL_MS = 50;

        private static uint source = 0;
        private static int64 started = 0;

        /* Created on first use, not in a field initialiser: nothing ever
         * instantiates this class, so its static initialiser would never run
         * and the array would stay null. */
        private static GenericArray<unowned LedSwatch>? swatches = null;

        public static void register (LedSwatch swatch) {
            if (swatches == null) {
                swatches = new GenericArray<unowned LedSwatch> ();
            }
            swatches.add (swatch);

            if (source == 0) {
                started = GLib.get_monotonic_time ();
                source = Timeout.add (INTERVAL_MS, tick);
            }
        }

        public static void unregister (LedSwatch swatch) {
            if (swatches == null) {
                return;
            }
            swatches.remove (swatch);

            if (swatches.length == 0 && source != 0) {
                Source.remove (source);
                source = 0;
            }
        }

        public static double now () {
            return started == 0 ? 0.0 : (GLib.get_monotonic_time () - started) / 1000000.0;
        }

        private static bool tick () {
            double t = now ();

            for (uint i = 0; swatches != null && i < swatches.length; i++) {
                swatches[i].animate (t);
            }

            return Source.CONTINUE;
        }
    }

    /* The dongle itself, drawn from the artwork the app icon uses: the body in
     * one colour with the light window overlaid in another, so the light can be
     * coloured and blinked on its own.
     *
     * The blinking is driven from LedAnimator rather than CSS: GTK does not
     * re-render a GtkImage for a CSS animation, so an animated colour or
     * opacity simply sits at one value. */
    public class LedSwatch : Gtk.Box {

        private Gtk.Image light;
        private LedEntry? entry = null;
        private string colour = "";
        private string[] modifiers = {};

        /* GtkOverlay is final in GTK 4 and cannot be derived from, so the
         * overlay is held rather than inherited. */
        public LedSwatch (int size = 28) {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);

            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;

            var body = new Gtk.Image.from_icon_name ("appairee-dongle-symbolic") {
                pixel_size = size
            };
            body.add_css_class ("led-body");

            light = new Gtk.Image.from_icon_name ("appairee-dongle-led-symbolic") {
                pixel_size = size
            };
            light.add_css_class ("led-light");

            var overlay = new Gtk.Overlay ();
            overlay.child = body;
            overlay.add_overlay (light);
            append (overlay);
        }

        public void show_entry (LedEntry? shown) {
            foreach (unowned string css_class in modifiers) {
                light.remove_css_class (css_class);
            }
            if (colour != "") {
                light.remove_css_class (colour);
                colour = "";
            }

            entry = shown;
            modifiers = shown != null ? shown.modifier_classes () : new string[0];

            foreach (unowned string css_class in modifiers) {
                light.add_css_class (css_class);
            }

            /* Set the starting frame now rather than waiting for the next tick,
             * so a swatch is never briefly unlit when it first appears. */
            animate (LedAnimator.now ());
        }

        public void animate (double t) {
            if (entry == null) {
                light.opacity = 0;
                return;
            }

            var wanted = entry.colour_at (t);
            if (wanted != colour) {
                if (colour != "") {
                    light.remove_css_class (colour);
                }
                light.add_css_class (wanted);
                colour = wanted;
            }

            light.opacity = entry.lit_at (t) ? 1.0 : 0.06;
        }

        public override void map () {
            base.map ();
            LedAnimator.register (this);
        }

        public override void unmap () {
            LedAnimator.unregister (this);
            base.unmap ();
        }
    }

    /* The status LED table, reproduced from page 6 of the BTD 700 instruction
     * manual. Order and wording follow the printed table. */
    public class Led {

        public const int PAIRING = 0;
        public const int OFF = 13;

        public static LedEntry[] all () {
            const string RED = "led-red";
            const string WHITE = "led-white";
            const string BLUE = "led-blue";
            const string PINK = "led-pink";
            const string PURPLE = "led-purple";
            const string AMBER = "led-amber";
            const string GREEN = "led-green";

            return {
                new LedEntry (RED, WHITE, LedPattern.ALTERNATE,
                    _("Red, then white, alternately"),
                    _("Pairing with headphones is being performed")),
                new LedEntry (WHITE, null, LedPattern.FLASH3,
                    _("Flashes white 3×"),
                    _("Pairing with headphones was successful")),
                new LedEntry (WHITE, null, LedPattern.FLASH3,
                    _("Repeatedly flashes white 3× for 20 seconds"),
                    _("Searches for paired headphones for up to 20 seconds")),
                new LedEntry (WHITE, null, LedPattern.FLASH3,
                    _("Lights up white and flashes white 3×"),
                    _("Reconnects with paired headphones")),
                new LedEntry (RED, null, LedPattern.FLASH3,
                    _("Flashes red 3×"),
                    _("Pairing with headphones was not successful")),
                new LedEntry (WHITE, null, LedPattern.DIM,
                    _("Lights up dimly white"),
                    _("Connected via Bluetooth Classic mode")),
                new LedEntry (BLUE, null, LedPattern.DIM,
                    _("Lights up dimly blue"),
                    _("Connected via Bluetooth Low Energy mode")),
                new LedEntry (BLUE, null, LedPattern.STEADY,
                    _("Lights up blue"),
                    _("Audio coding via LC3 codec")),
                new LedEntry (PINK, null, LedPattern.STEADY,
                    _("Lights up pink"),
                    _("Audio coding via aptX Adaptive or aptX Classic codec")),
                new LedEntry (PURPLE, null, LedPattern.STEADY,
                    _("Lights up purple"),
                    _("Audio coding via aptX Lossless codec")),
                new LedEntry (WHITE, null, LedPattern.STEADY,
                    _("Lights up white"),
                    _("Audio coding via SBC codec")),
                new LedEntry (WHITE, null, LedPattern.FLASH,
                    _("Flashes white"),
                    _("Incoming call")),
                new LedEntry (PINK, null, LedPattern.FLASH3,
                    _("Flashes pink 3×"),
                    _("Reset to factory default settings")),
                new LedEntry ("led-off", null, LedPattern.STEADY,
                    _("Off"),
                    _("Disconnected from headphones or device")),
                new LedEntry (RED, null, LedPattern.STEADY,
                    _("Lights up red"),
                    _("Mute function is active")),
                new LedEntry (AMBER, null, LedPattern.STEADY,
                    _("Lights up amber"),
                    _("Auracast broadcasting mode")),
                new LedEntry (GREEN, null, LedPattern.STEADY,
                    _("Lights up green"),
                    _("Gaming mode"))
            };
        }

        /* Which row the dongle is showing right now, or -1 when it cannot be
         * told. Gaming and broadcasting override the codec colour, and the
         * codec colours only apply while audio is actually streaming. Mute and
         * incoming calls are invisible to the control protocol, so those rows
         * are never highlighted. */
        public static int current (Snapshot snapshot) {
            if (!snapshot.present) {
                return -1;
            }

            /* The protocol has no pairing command, and upstream never named
             * state 0 beyond "NONE". Observed on the hardware: it reports 0
             * while the pairing button has put it into pairing mode, and 1 when
             * it is merely disconnected. */
            if (snapshot.state == Btd700.DongleState.NONE) {
                return PAIRING;
            }

            if (snapshot.state == Btd700.DongleState.DISCONNECTED) {
                return OFF;
            }

            if (snapshot.mode == Btd700.AudioMode.GAMING) {
                return 16;
            }

            if (snapshot.mode == Btd700.AudioMode.BROADCAST) {
                return 15;
            }

            if (snapshot.state == Btd700.DongleState.STREAMING_AUDIO) {
                if (active (snapshot, Btd700.Codec.LC3)) {
                    return 7;
                }
                if (active (snapshot, Btd700.Codec.APTX_LOSSLESS)) {
                    return 9;
                }
                if (active (snapshot, Btd700.Codec.APTX_ADAPTIVE) ||
                    active (snapshot, Btd700.Codec.APTX)) {
                    return 8;
                }
                if (active (snapshot, Btd700.Codec.SBC)) {
                    return 10;
                }
            }

            if (snapshot.transport == Btd700.TransportMode.LE_AUDIO) {
                return 6;
            }

            if (snapshot.transport == Btd700.TransportMode.CLASSIC ||
                snapshot.transport == Btd700.TransportMode.MULTIPOINT) {
                return 5;
            }

            return -1;
        }

        private static bool active (Snapshot snapshot, Btd700.Codec codec) {
            return (snapshot.active_codecs & (1 << (int) codec)) != 0;
        }
    }
}
