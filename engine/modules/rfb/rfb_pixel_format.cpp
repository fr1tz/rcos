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

#include "rfb_pixel_format.h"

void RFBPixelFormat::_bind_methods()
{
    ObjectTypeDB::bind_method(_MD("set", "pixel_format"), &RFBPixelFormat::set);

    ObjectTypeDB::bind_method(_MD("set_bits_per_pixel", "val"), &RFBPixelFormat::set_bits_per_pixel);
    ObjectTypeDB::bind_method(_MD("set_depth", "val"), &RFBPixelFormat::set_depth);
    ObjectTypeDB::bind_method(_MD("set_big_endian_flag", "val"), &RFBPixelFormat::set_big_endian_flag);
    ObjectTypeDB::bind_method(_MD("set_true_color_flag", "val"), &RFBPixelFormat::set_true_color_flag);
    ObjectTypeDB::bind_method(_MD("set_red_max", "val"), &RFBPixelFormat::set_red_max);
    ObjectTypeDB::bind_method(_MD("set_green_max", "val"), &RFBPixelFormat::set_green_max);
    ObjectTypeDB::bind_method(_MD("set_blue_max", "val"), &RFBPixelFormat::set_blue_max);
    ObjectTypeDB::bind_method(_MD("set_red_shift", "val"), &RFBPixelFormat::set_red_shift);
    ObjectTypeDB::bind_method(_MD("set_green_shift", "val"), &RFBPixelFormat::set_green_shift);
    ObjectTypeDB::bind_method(_MD("set_blue_shift", "val"), &RFBPixelFormat::set_blue_shift);

    ObjectTypeDB::bind_method(_MD("get_bits_per_pixel"), &RFBPixelFormat::get_bits_per_pixel);
    ObjectTypeDB::bind_method(_MD("get_depth"), &RFBPixelFormat::get_depth);
    ObjectTypeDB::bind_method(_MD("get_big_endian_flag"), &RFBPixelFormat::get_big_endian_flag);
    ObjectTypeDB::bind_method(_MD("get_true_color_flag"), &RFBPixelFormat::get_true_color_flag);
    ObjectTypeDB::bind_method(_MD("get_red_max"), &RFBPixelFormat::get_red_max);
    ObjectTypeDB::bind_method(_MD("get_green_max"), &RFBPixelFormat::get_green_max);
    ObjectTypeDB::bind_method(_MD("get_blue_max"), &RFBPixelFormat::get_blue_max);
    ObjectTypeDB::bind_method(_MD("get_red_shift"), &RFBPixelFormat::get_red_shift);
    ObjectTypeDB::bind_method(_MD("get_green_shift"), &RFBPixelFormat::get_green_shift);
    ObjectTypeDB::bind_method(_MD("get_blue_shift"), &RFBPixelFormat::get_blue_shift);
}


RFBPixelFormat::RFBPixelFormat()
{
    bits_per_pixel = -1;
    depth = -1;
    big_endian_flag = -1;
    true_color_flag = -1;
    red_max = -1;
    green_max = -1;
    blue_max = -1;
    red_shift = -1;
    green_shift = -1;
    blue_shift = -1;
}

void RFBPixelFormat::set(const Ref<RFBPixelFormat>& p_pixel_format)
{
    bits_per_pixel = p_pixel_format->bits_per_pixel;
    depth = p_pixel_format->depth;
    big_endian_flag = p_pixel_format->big_endian_flag;
    true_color_flag = p_pixel_format->true_color_flag;
    red_max = p_pixel_format->red_max;
    green_max = p_pixel_format->green_max;
    blue_max = p_pixel_format->blue_max;
    red_shift = p_pixel_format->red_shift;
    green_shift = p_pixel_format->green_shift;
    blue_shift = p_pixel_format->blue_shift;
}

