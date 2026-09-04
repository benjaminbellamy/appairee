/* Hand-written bindings for btd700ctl by sobalap.
 *
 * https://github.com/sobalap/btd700ctl  (LGPL-2.1)
 *
 * btd700_c.h is already a narrow, plain C API — an opaque handle, enums and
 * POD structs — so it is bound directly and needs no shim. Only what Appairée
 * actually calls is bound here; the broadcast, factory-reset and raw-command
 * entry points are deliberately absent.
 */

[CCode (cheader_filename = "btd700/btd700_c.h")]
namespace Btd700 {

    [CCode (cname = "btd700_error_t", cprefix = "BTD700_", has_type_id = false)]
    public enum Error {
        OK,
        ERR_DEVICE_NOT_FOUND,
        ERR_DEVICE_NOT_OPEN,
        ERR_HID,
        ERR_INVALID_ARG
    }

    [CCode (cname = "btd700_audio_mode_t", cprefix = "BTD700_AUDIO_MODE_", has_type_id = false)]
    public enum AudioMode {
        HIGH_QUALITY,
        GAMING,
        BROADCAST
    }

    [CCode (cname = "btd700_transport_mode_t", cprefix = "BTD700_TRANSPORT_", has_type_id = false)]
    public enum TransportMode {
        DISCONNECTED,
        CLASSIC,
        LE_AUDIO,
        MULTIPOINT
    }

    [CCode (cname = "btd700_audio_frequency_t", cprefix = "BTD700_FREQ_", has_type_id = false)]
    public enum AudioFrequency {
        [CCode (cname = "BTD700_FREQ_44100")]
        KHZ_44_1,
        [CCode (cname = "BTD700_FREQ_48000")]
        KHZ_48,
        [CCode (cname = "BTD700_FREQ_96000")]
        KHZ_96
    }

    [CCode (cname = "btd700_audio_resolution_t", cprefix = "BTD700_RES_", has_type_id = false)]
    public enum AudioResolution {
        [CCode (cname = "BTD700_RES_16BIT")]
        BITS_16,
        [CCode (cname = "BTD700_RES_24BIT")]
        BITS_24
    }

    [CCode (cname = "btd700_codec_t", cprefix = "BTD700_CODEC_", has_type_id = false)]
    public enum Codec {
        SBC,
        APTX,
        APTX_ADAPTIVE,
        APTX_LOSSLESS,
        APTX_LITE,
        LC3
    }

    [CCode (cname = "btd700_dongle_state_t", cprefix = "BTD700_STATE_", has_type_id = false)]
    public enum DongleState {
        NONE,
        DISCONNECTED,
        CONNECTED,
        STREAMING_AUDIO,
        STREAMING_VOICE
    }

    [CCode (cname = "btd700_le_audio_state_t", cprefix = "BTD700_LE_AUDIO_", has_type_id = false)]
    public enum LeAudioState {
        NONE,
        DISCONNECTED,
        CONNECTED,
        STREAMING_UNICAST,
        STREAMING_BROADCAST
    }

    [CCode (cname = "btd700_sink_mode_t", cprefix = "BTD700_SINK_", has_type_id = false)]
    public enum SinkMode {
        NOT_AVAILABLE,
        CLASSIC,
        LE_AUDIO,
        DUAL
    }

    /* manufacturer, product and serial are inline char[256] in C, so they are
     * bound unowned: reading them decays the array to a const char*, and
     * nothing here ever frees them. */
    [CCode (cname = "btd700_device_info_t", has_type_id = false)]
    public struct DeviceInfo {
        public unowned string manufacturer;
        public unowned string product;
        public unowned string serial;
    }

    [CCode (cname = "btd700_firmware_version_t", has_type_id = false)]
    public struct FirmwareVersion {
        public uint8 major;
        public uint8 minor;
        public uint16 build;
    }

    [CCode (cname = "btd700_audio_config_t", has_type_id = false)]
    public struct AudioConfig {
        public AudioMode mode;
        public TransportMode transport;
    }

    [CCode (cname = "btd700_audio_quality_t", has_type_id = false)]
    public struct AudioQuality {
        public AudioFrequency frequency;
        public AudioResolution resolution;
    }

    /* Bound as an opaque struct with no fields: its payload points into a
     * stack buffer inside the library and is invalid the moment the callback
     * returns, so Appairée uses the callback only as a "something changed"
     * ping and re-reads every value rather than parsing the report. Declaring
     * it as a struct rather than a void* is what makes valac emit the
     * `const btd700_event_t *` the C typedef actually asks for. */
    [CCode (cname = "btd700_event_t", has_type_id = false)]
    public struct Event {
    }

    [CCode (cname = "btd700_event_callback_t", has_target = false)]
    public delegate void EventCallback ([CCode (type = "const btd700_event_t*")] Event event,
                                       void* user_data);

    [Compact]
    [CCode (cname = "btd700_driver_t", free_function = "btd700_driver_destroy", has_type_id = false)]
    public class Driver {
        [CCode (cname = "btd700_driver_create")]
        public static Error create (out Driver driver);

        [CCode (cname = "btd700_driver_connect")]
        public Error connect ();

        [CCode (cname = "btd700_driver_disconnect")]
        public Error disconnect ();

        [CCode (cname = "btd700_driver_device_info")]
        public Error device_info (out DeviceInfo info);

        [CCode (cname = "btd700_driver_firmware_version")]
        public Error firmware_version (out FirmwareVersion version);

        [CCode (cname = "btd700_driver_state")]
        public Error state (out DongleState state);

        [CCode (cname = "btd700_driver_le_audio_state")]
        public Error le_audio_state (out LeAudioState state);

        [CCode (cname = "btd700_driver_audio_config")]
        public Error audio_config (out AudioConfig config);

        [CCode (cname = "btd700_driver_audio_quality")]
        public Error audio_quality (out AudioQuality quality);

        [CCode (cname = "btd700_driver_sink_transport")]
        public Error sink_transport (out SinkMode mode);

        [CCode (cname = "btd700_driver_supported_codecs")]
        public Error supported_codecs (out uint16 mask);

        [CCode (cname = "btd700_driver_active_codec")]
        public Error active_codec (out uint16 mask);

        [CCode (cname = "btd700_driver_set_audio_mode")]
        public Error set_audio_mode (AudioMode mode, TransportMode transport);

        [CCode (cname = "btd700_driver_set_codec")]
        public Error set_codec (Codec codec);

        [CCode (cname = "btd700_driver_set_event_callback")]
        public Error set_event_callback (EventCallback? callback, void* user_data);

        [CCode (cname = "btd700_driver_poll_events")]
        public Error poll_events (int timeout_ms);
    }

    [CCode (cname = "btd700_error_string")]
    public unowned string error_string (Error error);

    [CCode (cname = "btd700_audio_mode_string")]
    public unowned string audio_mode_string (AudioMode mode);

    [CCode (cname = "btd700_transport_mode_string")]
    public unowned string transport_mode_string (TransportMode mode);

    [CCode (cname = "btd700_dongle_state_string")]
    public unowned string dongle_state_string (DongleState state);

    [CCode (cname = "btd700_le_audio_state_string")]
    public unowned string le_audio_state_string (LeAudioState state);

    [CCode (cname = "btd700_sink_mode_string")]
    public unowned string sink_mode_string (SinkMode mode);

    [CCode (cname = "btd700_codec_string")]
    public unowned string codec_string (Codec codec);

    [CCode (cname = "btd700_audio_frequency_string")]
    public unowned string audio_frequency_string (AudioFrequency frequency);

    [CCode (cname = "btd700_audio_resolution_string")]
    public unowned string audio_resolution_string (AudioResolution resolution);
}
