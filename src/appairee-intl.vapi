/* Binding for the gettext cache shim in appairee-intl.c.
 *
 * Named Gettext rather than Intl so that it cannot be confused with GLib.Intl,
 * which is what the rest of the code calls for setlocale and textdomain. */

[CCode (cheader_filename = "appairee-intl.h")]
namespace Appairee.Gettext {

    [CCode (cname = "appairee_intl_invalidate")]
    public void invalidate ();
}
