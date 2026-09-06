/* Binding for the ALSA mixer shim in appairee-volume.c.
 *
 * Vala ships an alsa.vapi, but it cannot express this: ElemId has no setters,
 * so a control cannot be addressed by name or numid, ElemInfo exposes no range,
 * and snd_mixer_handle_events is absent, which leaves the cached mixer values
 * frozen. The shim does the ALSA work in C and hands back plain numbers. */

[CCode (cheader_filename = "appairee-volume.h")]
namespace Appairee {

    [Compact]
    [CCode (cname = "AppaireeVolume", free_function = "appairee_volume_close",
            has_type_id = false)]
    public class VolumeControl {

        [CCode (cname = "appairee_volume_open")]
        public static VolumeControl? open ();

        [CCode (cname = "appairee_volume_read")]
        public bool read (out long value, out long min, out long max);

        [CCode (cname = "appairee_volume_write")]
        public bool write (long value);

        [CCode (cname = "appairee_volume_to_db")]
        public bool to_db (long value, out long millibel);
    }
}
