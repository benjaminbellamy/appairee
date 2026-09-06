/* appairee-volume.h
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

#pragma once

#include <glib.h>

G_BEGIN_DECLS

/* The dongle's playback volume, which is not part of the vendor HID protocol
 * btd700ctl speaks. The BTD 700 declares Volume on Feature Unit 8 of its USB
 * audio interface, the unit that feeds the headset output terminal, so the
 * level travels to the dongle as a USB control transfer and ALSA is what
 * addresses it.
 *
 * Values here are the device's own steps and the decibels are the device's own
 * decibels, read back through ALSA. Nothing in this file scales, rounds or
 * converts them. */
typedef struct _AppaireeVolume AppaireeVolume;

/* NULL when no BTD 700 sound card is present, which is the ordinary state with
 * the dongle unplugged. */
AppaireeVolume *appairee_volume_open (void);

void appairee_volume_close (AppaireeVolume *self);

/* FALSE once the card has gone, so that the caller closes and tries again. */
gboolean appairee_volume_read (AppaireeVolume *self,
                               glong          *value,
                               glong          *min,
                               glong          *max);

gboolean appairee_volume_write (AppaireeVolume *self,
                                glong           value);

/* What the device says a step is worth in hundredths of a decibel, asked about
 * a step it is not currently set to, so a slider can be labelled without being
 * moved to read it. */
gboolean appairee_volume_to_db (AppaireeVolume *self,
                                glong           value,
                                glong          *millibel);

G_END_DECLS
