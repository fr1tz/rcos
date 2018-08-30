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

class RFBPixelFormat;

class RFBFramebuffer : public Reference
{
    OBJ_TYPE(RFBFramebuffer, Reference)
    OBJ_CATEGORY("References")

    struct PixelFormat
    {
        int bits_per_pixel;
        int bytes_per_pixel;
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

    PixelFormat mPixelFormat;
    Vector2 mSize;
    DVector<uint8_t> mData;

protected:
	static void _bind_methods();

public:
    void set_pixel_format(const Ref<RFBPixelFormat>& p_pixel_format);
    void set_size(const Vector2& p_size);
    void put_rect_raw(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset);
    void put_rect_cursor(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset);
    void copy_rect(const Rect2& p_src_rect, const Vector2& p_dst_pos);
    Image get_image() const;
};

#endif // RFB_FRAMEBUFFER_H
