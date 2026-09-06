/* device.vala
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

    /* Everything the window displays, assembled on the worker thread and handed
     * to the main thread as one immutable batch. */
    public class Snapshot : Object {
        public bool present;
        public Btd700.Error error;

        public string manufacturer = "";
        public string product = "";
        public string serial = "";
        public string firmware = "";

        public Btd700.DongleState state;
        public Btd700.LeAudioState le_audio;
        public Btd700.AudioMode mode;
        public Btd700.TransportMode transport;
        public Btd700.SinkMode sink;
        public Btd700.AudioFrequency frequency;
        public Btd700.AudioResolution resolution;

        public uint16 supported_codecs;
        public uint16 active_codecs;

        public bool same_as (Snapshot other) {
            return present == other.present
                && error == other.error
                && state == other.state
                && le_audio == other.le_audio
                && mode == other.mode
                && transport == other.transport
                && sink == other.sink
                && frequency == other.frequency
                && resolution == other.resolution
                && supported_codecs == other.supported_codecs
                && active_codecs == other.active_codecs
                && manufacturer == other.manufacturer
                && product == other.product
                && serial == other.serial
                && firmware == other.firmware;
        }
    }

    /* The dongle's playback volume, which is not part of the HID protocol.
     * It is a USB audio control on the dongle's own feature unit, reached
     * through ALSA, so it is read on its own schedule rather than folded into
     * a Snapshot: a mixer read is a cheap ioctl where every value in a Snapshot
     * costs a HID command that can block for a second. */
    public class VolumeState : Object {
        public bool available;

        /* The device's own step and its own bounds. Nothing here is a
         * percentage; the window shows these numbers as they arrive. */
        public long value;
        public long min;
        public long max;

        /* What each step from min to max is worth in hundredths of a decibel,
         * asked of the device once. Carried with the state so that the window
         * can label the slider without touching ALSA off the worker thread. */
        public long[] millibels;

        public bool same_as (VolumeState other) {
            return available == other.available
                && value == other.value
                && min == other.min
                && max == other.max;
        }
    }

    private enum RequestKind {
        WAKE,
        SET_MODE,
        SET_CODEC,
        SET_VOLUME
    }

    private class Request : Object {
        public RequestKind kind;
        public Btd700.AudioMode mode;
        public Btd700.Codec codec;
        public long volume;
    }

    /* btd700ctl blocks for up to a second per command, is not thread safe, and
     * exposes no pollable file descriptor, so every call to it happens on this
     * one worker thread. The UI only ever sees Snapshot objects arriving on the
     * main loop. */
    public class Device : Object {

        public signal void updated (Snapshot snapshot);

        /* The dongle reports success for an audio mode it then ignores, so a
         * rejected change has to be detected by reading it back. */
        public signal void mode_rejected ();

        public signal void volume_updated (VolumeState state);

        private const int POLL_TIMEOUT_MS = 200;

        /* The dongle reports connection changes on its own but says nothing when
         * the audio mode or codec is changed by the physical button or by
         * another program, so everything is re-read on a slow tick too. At the
         * 200 ms poll quantum this is every two seconds. */
        private const int REFRESH_TICKS = 10;

        private Thread<bool>? worker = null;

        /* Only ever touched on the worker thread. Identical snapshots are
         * dropped so that the slow tick does not churn the UI. */
        private Snapshot? last_published = null;

        private AsyncQueue<Request> requests = new AsyncQueue<Request> ();
        private int stopping = 0;

        /* Worker thread only. snd_mixer is not thread safe, and the decibel
         * table is built here so that nothing else has to ask ALSA. */
        private VolumeControl? volume = null;
        private VolumeState? last_volume = null;
        private long[] millibels = {};

        /* Raised by the library's event callback, which fires both from
         * poll_events and from inside ordinary commands. Destroying a driver
         * calls hid_exit(), which is process-global, so exactly one driver
         * exists per process and one static flag is enough. */
        private static int event_flag = 0;

        public void start () {
            if (worker != null) {
                return;
            }
            worker = new Thread<bool> ("appairee-device", run);
        }

        public void stop () {
            if (worker == null) {
                return;
            }
            AtomicInt.set (ref stopping, 1);

            var wake = new Request ();
            wake.kind = RequestKind.WAKE;
            requests.push (wake);

            worker.join ();
            worker = null;
        }

        public void request_audio_mode (Btd700.AudioMode mode) {
            var req = new Request ();
            req.kind = RequestKind.SET_MODE;
            req.mode = mode;
            requests.push (req);
        }

        public void request_codec (Btd700.Codec codec) {
            var req = new Request ();
            req.kind = RequestKind.SET_CODEC;
            req.codec = codec;
            requests.push (req);
        }

        public void request_volume (long value) {
            var req = new Request ();
            req.kind = RequestKind.SET_VOLUME;
            req.volume = value;
            requests.push (req);
        }

        private static void on_device_event (Btd700.Event event, void* user_data) {
            /* The payload points into a stack buffer that dies with this call,
             * so it is ignored on purpose: the worker re-reads every value. */
            AtomicInt.set (ref event_flag, 1);
        }

        private bool run () {
            Btd700.Driver? driver = null;

            if (Btd700.Driver.create (out driver) != Btd700.Error.OK || driver == null) {
                emit_absent (Btd700.Error.ERR_INVALID_ARG);
                return true;
            }

            bool open = false;
            int ticks = 0;

            while (AtomicInt.get (ref stopping) == 0) {
                if (!open) {
                    /* connect() returns OK without reopening anything when the
                     * handle is stale, so the disconnect is what actually makes
                     * a reconnect happen. */
                    driver.disconnect ();

                    var err = driver.connect ();
                    if (err != Btd700.Error.OK) {
                        emit_absent (err);
                        /* Wakes early if stop() pushes; any setting queued while
                         * no dongle is present is dropped, which is what the
                         * status page in the UI already implies. */
                        requests.timeout_pop (1000000);
                        continue;
                    }

                    open = true;
                    ticks = 0;
                    driver.set_event_callback (on_device_event, null);

                    /* The dongle sends no event describing its current state, so
                     * the first read has to be asked for. */
                    AtomicInt.set (ref event_flag, 1);
                }

                for (Request? req = requests.try_pop (); req != null; req = requests.try_pop ()) {
                    if (!apply (driver, req)) {
                        open = false;
                        break;
                    }
                }
                if (!open) {
                    continue;
                }

                if (AtomicInt.compare_and_exchange (ref event_flag, 1, 0)) {
                    if (!publish (driver)) {
                        open = false;
                        continue;
                    }
                }

                poll_volume ();

                var err = driver.poll_events (POLL_TIMEOUT_MS);
                if (err == Btd700.Error.ERR_HID || err == Btd700.Error.ERR_DEVICE_NOT_OPEN) {
                    open = false;
                    continue;
                }

                if (++ticks >= REFRESH_TICKS) {
                    ticks = 0;
                    AtomicInt.set (ref event_flag, 1);
                }
            }

            driver.disconnect ();
            volume = null;
            return true;
        }

        private bool apply (Btd700.Driver driver, Request req) {
            /* Volume lives on the sound card, not in the HID protocol, so this
             * one neither touches the driver nor invalidates a Snapshot. */
            if (req.kind == RequestKind.SET_VOLUME) {
                if (volume != null) {
                    volume.write (req.volume);
                }
                return true;
            }

            var err = Btd700.Error.OK;

            if (req.kind == RequestKind.SET_MODE) {
                /* set_audio_mode writes the transport as well as the mode, so
                 * the current transport is read and written back untouched:
                 * changing the mode must never drop the dongle out of
                 * multipoint. */
                Btd700.AudioConfig config;
                err = driver.audio_config (out config);
                if (err == Btd700.Error.OK) {
                    err = driver.set_audio_mode (req.mode, config.transport);
                }

                /* Writing the mode only takes effect while the dongle is
                 * streaming audio. Otherwise it answers "success" and changes
                 * nothing, so the only way to know is to read it back. */
                if (err == Btd700.Error.OK) {
                    Btd700.AudioConfig applied;
                    if (driver.audio_config (out applied) == Btd700.Error.OK &&
                        applied.mode != req.mode) {
                        Idle.add (() => {
                            mode_rejected ();
                            return Source.REMOVE;
                        });
                    }
                }
            } else if (req.kind == RequestKind.SET_CODEC) {
                err = driver.set_codec (req.codec);
            }

            if (err == Btd700.Error.ERR_HID || err == Btd700.Error.ERR_DEVICE_NOT_OPEN) {
                return false;
            }

            /* Read back whatever the dongle actually settled on rather than
             * assuming the write took. */
            AtomicInt.set (ref event_flag, 1);
            return true;
        }

        private bool publish (Btd700.Driver driver) {
            var snapshot = new Snapshot ();
            snapshot.present = true;
            snapshot.error = Btd700.Error.OK;

            /* Read one at a time and give up at the first failure: a command
             * that has to time out costs a full second, and a dongle that was
             * unplugged mid-read would otherwise be asked nine times. */
            Btd700.DeviceInfo info;
            if (driver.device_info (out info) != Btd700.Error.OK) {
                return false;
            }

            Btd700.FirmwareVersion firmware;
            if (driver.firmware_version (out firmware) != Btd700.Error.OK) {
                return false;
            }

            Btd700.AudioConfig config;
            if (driver.audio_config (out config) != Btd700.Error.OK) {
                return false;
            }

            Btd700.AudioQuality quality;
            if (driver.audio_quality (out quality) != Btd700.Error.OK) {
                return false;
            }

            if (driver.state (out snapshot.state) != Btd700.Error.OK ||
                driver.le_audio_state (out snapshot.le_audio) != Btd700.Error.OK ||
                driver.sink_transport (out snapshot.sink) != Btd700.Error.OK ||
                driver.supported_codecs (out snapshot.supported_codecs) != Btd700.Error.OK ||
                driver.active_codec (out snapshot.active_codecs) != Btd700.Error.OK) {
                return false;
            }

            snapshot.manufacturer = info.manufacturer;
            snapshot.product = info.product;
            snapshot.serial = info.serial;
            snapshot.firmware = "%u.%u.%u".printf (firmware.major, firmware.minor, firmware.build);

            snapshot.mode = config.mode;
            snapshot.transport = config.transport;
            snapshot.frequency = quality.frequency;
            snapshot.resolution = quality.resolution;

            emit (snapshot);
            return true;
        }

        private void poll_volume () {
            if (volume == null) {
                volume = VolumeControl.open ();
                if (volume == null) {
                    emit_volume (new VolumeState ());
                    return;
                }
                millibels = {};
            }

            long value, min, max;
            if (!volume.read (out value, out min, out max)) {
                /* The card goes away with the dongle. Dropping the handle is
                 * what makes the next pass open a fresh one. */
                volume = null;
                millibels = {};
                emit_volume (new VolumeState ());
                return;
            }

            var state = new VolumeState ();
            state.available = true;
            state.value = value;
            state.min = min;
            state.max = max;
            state.millibels = decibel_table (min, max);

            emit_volume (state);
        }

        /* Asked of the device once per handle rather than derived from the
         * range: the step-to-decibel mapping is the device's to state, not
         * ours to assume is linear. */
        private long[] decibel_table (long min, long max) {
            if (millibels.length == (int) (max - min + 1)) {
                return millibels;
            }

            var table = new long[max - min + 1];
            for (int i = 0; i < table.length; i++) {
                if (!volume.to_db (min + i, out table[i])) {
                    return {};
                }
            }

            millibels = table;
            return millibels;
        }

        private void emit_volume (VolumeState state) {
            if (last_volume != null && state.same_as (last_volume)) {
                return;
            }
            last_volume = state;

            Idle.add (() => {
                volume_updated (state);
                return Source.REMOVE;
            });
        }

        private void emit_absent (Btd700.Error error) {
            var snapshot = new Snapshot ();
            snapshot.present = false;
            snapshot.error = error;
            emit (snapshot);
        }

        private void emit (Snapshot snapshot) {
            if (last_published != null && snapshot.same_as (last_published)) {
                return;
            }
            last_published = snapshot;

            Idle.add (() => {
                updated (snapshot);
                return Source.REMOVE;
            });
        }
    }
}
