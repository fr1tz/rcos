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


#ifndef RFB_FRAMEBUFFER_H
#define RFB_FRAMEBUFFER_H

#include "reference.h"

#include "rfb_pixel_format.h"

struct RFBPixelFormat
{
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
};

class RFBFramebuffer : public Reference
{
    OBJ_TYPE(RFBFramebuffer, Reference);
    OBJ_CATEGORY("References");

    Vector2 mSize;
    RFBPixelFormat mPixelFormat;
    DVector<uint8_t> mData;

protected:
	static void _bind_methods();

public:
    void set_size(const Vector2& p_size);
    void set_pixel_format_bits_per_pixel(int p_val) { mPixelFormat.bits_per_pixel = p_val; }
    void set_pixel_format_depth(int p_val) { mPixelFormat.depth = p_val; }
    void set_pixel_format_big_endian_flag(int p_val) { mPixelFormat.big_endian_flag = p_val; }
    void set_pixel_format_true_color_flag(int p_val) { mPixelFormat.true_color_flag = p_val; }
    void set_pixel_format_red_max(int p_val) { mPixelFormat.red_max = p_val; }
    void set_pixel_format_green_max(int p_val) { mPixelFormat.green_max = p_val; }
    void set_pixel_format_blue_max(int p_val) { mPixelFormat.blue_max = p_val; }
    void set_pixel_format_red_shift(int p_val) { mPixelFormat.red_shift = p_val; }
    void set_pixel_format_green_shift(int p_val) { mPixelFormat.green_shift = p_val; }
    void set_pixel_format_blue_shift(int p_val) { mPixelFormat.blue_shift = p_val; }
    void put_rect_raw(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset);
    Image get_image() const;
};

#endif // RFB_FRAMEBUFFER_H
