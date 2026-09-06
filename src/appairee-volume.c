/* appairee-volume.c
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

#include "appairee-volume.h"

#include <alsa/asoundlib.h>

/* The dongle's USB id, spelled the way /proc/asound/cardN/usbid spells it.
 * Matching on that rather than on the card index, which moves between boots, or
 * on the card name, which is the driver's choice rather than a contract. */
#define BTD700_USBID "3542:3001"

struct _AppaireeVolume
{
  snd_mixer_t      *mixer;

  /* Owned by the mixer, freed with it. */
  snd_mixer_elem_t *elem;
};

static gboolean
card_is_btd700 (int card)
{
  g_autofree char *path = g_strdup_printf ("/proc/asound/card%d/usbid", card);
  g_autofree char *contents = NULL;

  if (!g_file_get_contents (path, &contents, NULL, NULL))
    return FALSE;

  return g_str_equal (g_strstrip (contents), BTD700_USBID);
}

static int
find_card (void)
{
  int card = -1;

  while (snd_card_next (&card) == 0 && card >= 0)
    {
      if (card_is_btd700 (card))
        return card;
    }

  return -1;
}

AppaireeVolume *
appairee_volume_open (void)
{
  int card = find_card ();
  if (card < 0)
    return NULL;

  g_autofree char *name = g_strdup_printf ("hw:%d", card);

  snd_mixer_t *mixer = NULL;
  if (snd_mixer_open (&mixer, 0) < 0)
    return NULL;

  if (snd_mixer_attach (mixer, name) < 0 ||
      snd_mixer_selem_register (mixer, NULL, NULL) < 0 ||
      snd_mixer_load (mixer) < 0)
    {
      snd_mixer_close (mixer);
      return NULL;
    }

  /* The BTD 700 exposes one playback volume, on the feature unit between USB
   * streaming in and the headset terminal out. Taking it by capability rather
   * than by the name ALSA happens to give it. */
  snd_mixer_elem_t *elem = NULL;
  for (snd_mixer_elem_t *it = snd_mixer_first_elem (mixer);
       it != NULL;
       it = snd_mixer_elem_next (it))
    {
      if (snd_mixer_selem_has_playback_volume (it))
        {
          elem = it;
          break;
        }
    }

  if (elem == NULL)
    {
      snd_mixer_close (mixer);
      return NULL;
    }

  AppaireeVolume *self = g_new0 (AppaireeVolume, 1);
  self->mixer = mixer;
  self->elem = elem;

  return self;
}

void
appairee_volume_close (AppaireeVolume *self)
{
  if (self == NULL)
    return;

  snd_mixer_close (self->mixer);
  g_free (self);
}

gboolean
appairee_volume_read (AppaireeVolume *self,
                      glong          *value,
                      glong          *min,
                      glong          *max)
{
  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail (value != NULL && min != NULL && max != NULL, FALSE);

  /* snd_mixer caches element values and only refreshes them here. Without this
   * call a change made by anything else on the machine, the desktop volume keys
   * included, would never be seen. It also fails once the card is gone, which
   * is how an unplugged dongle is noticed. */
  if (snd_mixer_handle_events (self->mixer) < 0)
    return FALSE;

  long lo = 0;
  long hi = 0;
  if (snd_mixer_selem_get_playback_volume_range (self->elem, &lo, &hi) < 0)
    return FALSE;

  long current = 0;
  if (snd_mixer_selem_get_playback_volume (self->elem, SND_MIXER_SCHN_MONO, &current) < 0)
    return FALSE;

  *value = current;
  *min = lo;
  *max = hi;

  return TRUE;
}

gboolean
appairee_volume_write (AppaireeVolume *self,
                       glong           value)
{
  g_return_val_if_fail (self != NULL, FALSE);

  /* The dongle declares no per-channel controls on the unit, so ALSA reports
   * the volume as joined and every channel takes the same value. */
  return snd_mixer_selem_set_playback_volume_all (self->elem, value) >= 0;
}

gboolean
appairee_volume_to_db (AppaireeVolume *self,
                       glong           value,
                       glong          *millibel)
{
  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail (millibel != NULL, FALSE);

  long db = 0;
  if (snd_mixer_selem_ask_playback_vol_dB (self->elem, value, &db) < 0)
    return FALSE;

  *millibel = db;

  return TRUE;
}
