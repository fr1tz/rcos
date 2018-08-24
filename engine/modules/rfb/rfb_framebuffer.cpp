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

#include "rfb_framebuffer.h"
#include "d3des.h"

void RFBFramebuffer::_bind_methods()
{
    ObjectTypeDB::bind_method(_MD("set_size", "size"), &RFBFramebuffer::set_size);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_bits_per_pixel"), &RFBFramebuffer::set_pixel_format_bits_per_pixel);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_depth"), &RFBFramebuffer::set_pixel_format_depth);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_big_endian_flag"), &RFBFramebuffer::set_pixel_format_big_endian_flag);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_true_color_flag"), &RFBFramebuffer::set_pixel_format_true_color_flag);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_red_max"), &RFBFramebuffer::set_pixel_format_red_max);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_green_max"), &RFBFramebuffer::set_pixel_format_green_max);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_blue_max"), &RFBFramebuffer::set_pixel_format_blue_max);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_red_shift"), &RFBFramebuffer::set_pixel_format_red_shift);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_green_shift"), &RFBFramebuffer::set_pixel_format_green_shift);
    ObjectTypeDB::bind_method(_MD("set_pixel_format_blue_shift"), &RFBFramebuffer::set_pixel_format_blue_shift);
    ObjectTypeDB::bind_method(_MD("put_rect_raw", "rect", "data", "data_offset"), &RFBFramebuffer::put_rect_raw);
    ObjectTypeDB::bind_method(_MD("get_image"), &RFBFramebuffer::get_image);
}

void RFBFramebuffer::set_size(const Vector2& p_size)
{
    mSize = p_size;
    mData.resize(mSize.x*mSize.y*3);
}

void RFBFramebuffer::put_rect_raw(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset)
{
    int rect_x = p_rect.pos.x;
    int rect_y = p_rect.pos.y;
    int rect_width = p_rect.size.x;
    int rect_height = p_rect.size.y;
    int bytes_per_pixel = mPixelFormat.bits_per_pixel/8;
    DVector<uint8_t>::Read r = p_data.read();
    const uint8_t* rect_data_ptr = r.ptr() + p_data_offset;
    DVector<uint8_t>::Write w = mData.write();
    uint8_t* fb_data_ptr = w.ptr();
    uint8_t rgb[3];
    if(mPixelFormat.big_endian_flag == 0
    && mPixelFormat.true_color_flag != 0
    && mPixelFormat.bits_per_pixel == 32
    && mPixelFormat.red_shift == 16
    && mPixelFormat.green_shift == 8
    && mPixelFormat.blue_shift == 0
    && mPixelFormat.red_max == 0xFF
    && mPixelFormat.green_max == 0xFF
    && mPixelFormat.blue_max == 0xFF)
    {
        for(int y = 0; y < rect_height; y++)
        {
            for(int x = 0; x < rect_width; x++)
            {
                int rect_pixel_idx = (y*rect_width) + x;
                const uint8_t* rect_pixel_ptr = (rect_data_ptr + rect_pixel_idx*bytes_per_pixel);
                rgb[0] = rect_pixel_ptr[2];
                rgb[1] = rect_pixel_ptr[1];
                rgb[2] = rect_pixel_ptr[0];
                int fb_pixel_idx = ((rect_y+y)*mSize.x) + (rect_x+x);
                int fb_data_idx = fb_pixel_idx*3;
                for(int i = 0; i < 3; i++)
                    fb_data_ptr[fb_data_idx+i] = rgb[i];
            }
        }
    }
    else if(mPixelFormat.true_color_flag != 0)
    {
        for(int y = 0; y < rect_height; y++)
        {
            for(int x = 0; x < rect_width; x++)
            {
                int rect_pixel_idx = (y*rect_width) + x;
                const uint8_t* rect_pixel_ptr = (rect_data_ptr + rect_pixel_idx*bytes_per_pixel);
                uint32_t pixel;
                if(mPixelFormat.bits_per_pixel == 32)
                {
                    pixel = *(uint32_t*)rect_pixel_ptr;
                }
                else if(mPixelFormat.bits_per_pixel == 16)
                {
                    pixel = *(uint16_t*)rect_pixel_ptr;
                }
                else
                {
                    pixel = *rect_pixel_ptr;
                }
                float r = float((pixel >> mPixelFormat.red_shift) & mPixelFormat.red_max) / mPixelFormat.red_max;
                float g = float((pixel >> mPixelFormat.green_shift) & mPixelFormat.green_max) / mPixelFormat.green_max;
                float b = float((pixel >> mPixelFormat.blue_shift) & mPixelFormat.blue_max) / mPixelFormat.blue_max;
                rgb[0] = r*255;
                rgb[1] = g*255;
                rgb[2] = b*255;
                int fb_pixel_idx = ((rect_y+y)*mSize.x) + (rect_x+x);
                int fb_data_idx = fb_pixel_idx*3;
                for(int i = 0; i < 3; i++)
                    fb_data_ptr[fb_data_idx+i] = rgb[i];
            }
        }
    }
    else // Use ColorMap
    {
       // TODO
    }
}

Image RFBFramebuffer::get_image() const
{
    Image image;
    image.create(mSize.x, mSize.y, 0, Image::FORMAT_RGB, mData);
    return image;
}
