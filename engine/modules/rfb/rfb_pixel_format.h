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


#ifndef RFB_PIXEL_FORMAT_H
#define RFB_PIXEL_FORMAT_H

#include "reference.h"

class RFBPixelFormat : public Reference
{
    OBJ_TYPE(RFBPixelFormat, Reference)
    OBJ_CATEGORY("References")

    int bits_per_pixel;
    int depth;
    int big_endian_flag;
    int true_color_flag;
    int red_max;
    int green_max;
    int blue_max;
    int red_shift;
    int green_shift;
    int blue_shift;

protected:
	static void _bind_methods();

public:
    RFBPixelFormat();

    void set(const Ref<RFBPixelFormat>& p_pixel_format);

    void set_bits_per_pixel(int p_val) { bits_per_pixel = p_val; }
    void set_depth(int p_val) { depth = p_val; }
    void set_big_endian_flag(int p_val) { big_endian_flag = p_val; }
    void set_true_color_flag(int p_val) { true_color_flag = p_val; }
    void set_red_max(int p_val) { red_max = p_val; }
    void set_green_max(int p_val) { green_max = p_val; }
    void set_blue_max(int p_val) { blue_max = p_val; }
    void set_red_shift(int p_val) { red_shift = p_val; }
    void set_green_shift(int p_val) { green_shift = p_val; }
    void set_blue_shift(int p_val) { blue_shift = p_val; }

    int get_bits_per_pixel() const { return bits_per_pixel; }
    int get_depth() const { return depth; }
    int get_big_endian_flag() const { return big_endian_flag; }
    int get_true_color_flag() const { return true_color_flag; }
    int get_red_max() const { return red_max; }
    int get_green_max() const { return green_max; }
    int get_blue_max() const { return blue_max; }
    int get_red_shift() const { return red_shift; }
    int get_green_shift() const { return green_shift; }
    int get_blue_shift() const { return blue_shift; }
};

#endif // RFB_PIXEL_FORMAT_H
