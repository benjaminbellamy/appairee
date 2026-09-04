# btd700ctl (vendored)

These files are copied **unmodified** from btd700ctl by **sobalap**:

  https://github.com/sobalap/btd700ctl
  commit 747f3d6bcac91bdb36872038225e06eebc93f07a

They implement the BTD 700's vendor HID protocol — all of the work of talking to
the dongle. Appairée contains no protocol code of its own.

They are vendored so that building Appairée needs nothing but hidapi: no separate
clone, configure, build and `sudo make install` of btd700ctl first.

## Licence

btd700ctl is **LGPL-2.1**, and these files remain available under those terms; a
copy is in `LICENSE` beside them. Appairée as a whole is GPL-3.0-or-later, which
LGPL-2.1 permits (section 3 allows a copy to be taken under the GNU GPL version 2
or later, and section 6 permits the combination regardless).

## Updating

Re-copy the three files from upstream and update the commit above. Do not edit
them locally: keeping them byte-identical is what makes them easy to re-sync, and
any fix belongs upstream.
