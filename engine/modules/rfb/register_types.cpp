/*
 * Copyright © 2018 Michael Goldener <mg@wasted.ch>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "register_types.h"
#include "rfb_util.h"
#include "rfb_pixel_format.h"
#include "rfb_framebuffer.h"

void register_rfb_types()
{
    ObjectTypeDB::register_type<RFBUtil>();
    ObjectTypeDB::register_type<RFBPixelFormat>();
    ObjectTypeDB::register_type<RFBFramebuffer>();
}

void unregister_rfb_types()
{
  
}
