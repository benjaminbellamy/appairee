/* Binding for the ALSA mixer shim in appairee-volume.c.
 *
 * Vala's alsa.vapi does bind most of the simple mixer API, but not
 * snd_mixer_handle_events, and without that call the cached element values
 * never refresh, so a level changed anywhere else on the machine stays
 * invisible. Rather than bind the one missing call and then drive alsa-lib's
 * compact classes from Vala, the shim keeps card discovery, element selection
 * and mixer ownership in C and hands back plain numbers. */

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
