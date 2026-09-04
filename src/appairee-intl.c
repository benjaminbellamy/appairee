/* appairee-intl.c
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

#include "appairee-intl.h"

/* glibc caches the resolved catalogue per domain and only reconsiders it when
 * this counter changes. It is not declared in any public header, but bumping it
 * is the long-standing way to switch language without restarting, and it is
 * what makes the language menu take effect immediately. Kept in its own file so
 * that the one glibc-internal detail in the project sits in a single place.
 *
 * On a libc without this symbol the link fails loudly, which is the right
 * outcome: silently ignoring the setting would be worse. */
extern int _nl_msg_cat_cntr;

void
appairee_intl_invalidate (void)
{
  ++_nl_msg_cat_cntr;
}
