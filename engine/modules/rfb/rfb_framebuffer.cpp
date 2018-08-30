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
#include "rfb_pixel_format.h"

void RFBFramebuffer::_bind_methods()
{
    ObjectTypeDB::bind_method(_MD("set_pixel_format", "pixel_format"), &RFBFramebuffer::set_pixel_format);
    ObjectTypeDB::bind_method(_MD("set_size", "size"), &RFBFramebuffer::set_size);
    ObjectTypeDB::bind_method(_MD("put_rect_raw", "rect", "data", "data_offset"), &RFBFramebuffer::put_rect_raw);
    ObjectTypeDB::bind_method(_MD("put_rect_cursor", "rect", "data", "data_offset"), &RFBFramebuffer::put_rect_cursor);
    ObjectTypeDB::bind_method(_MD("copy_rect", "src_rect", "dst_pos"), &RFBFramebuffer::copy_rect);
    ObjectTypeDB::bind_method(_MD("get_image"), &RFBFramebuffer::get_image);
}

void RFBFramebuffer::set_pixel_format(const Ref<RFBPixelFormat>& p_pixel_format)
{
    mPixelFormat.bits_per_pixel = p_pixel_format->get_bits_per_pixel();
    mPixelFormat.bytes_per_pixel = mPixelFormat.bits_per_pixel/8;
    mPixelFormat.depth = p_pixel_format->get_depth();
    mPixelFormat.big_endian_flag = p_pixel_format->get_big_endian_flag();
    mPixelFormat.true_color_flag = p_pixel_format->get_true_color_flag();
    mPixelFormat.red_max = p_pixel_format->get_red_max();
    mPixelFormat.green_max = p_pixel_format->get_green_max();
    mPixelFormat.blue_max = p_pixel_format->get_blue_max();
    mPixelFormat.red_shift = p_pixel_format->get_red_shift();
    mPixelFormat.green_shift = p_pixel_format->get_green_shift();
    mPixelFormat.blue_shift = p_pixel_format->get_blue_shift();
}

void RFBFramebuffer::set_size(const Vector2& p_size)
{
    mSize = p_size;
    mData.resize(mSize.x*mSize.y*4);
}

void RFBFramebuffer::put_rect_raw(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset)
{
    int rect_x = p_rect.pos.x;
    int rect_y = p_rect.pos.y;
    int rect_width = p_rect.size.x;
    int rect_height = p_rect.size.y;
    int bytes_per_pixel = mPixelFormat.bytes_per_pixel;
    DVector<uint8_t>::Read r = p_data.read();
    DVector<uint8_t>::Write w = mData.write();
    const uint8_t* rect_data_ptr = r.ptr() + p_data_offset;
    uint8_t* fb_data_ptr = w.ptr();
    uint8_t rgba[4];
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
                rgba[0] = rect_pixel_ptr[2];
                rgba[1] = rect_pixel_ptr[1];
                rgba[2] = rect_pixel_ptr[0];
                rgba[3] = 255;
                int fb_pixel_idx = ((rect_y+y)*mSize.x) + (rect_x+x);
                int fb_data_idx = fb_pixel_idx*4;
                for(int i = 0; i < 4; i++)
                    fb_data_ptr[fb_data_idx+i] = rgba[i];
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
                rgba[0] = r*255;
                rgba[1] = g*255;
                rgba[2] = b*255;
                rgba[3] = 255;
                int fb_pixel_idx = ((rect_y+y)*mSize.x) + (rect_x+x);
                int fb_data_idx = fb_pixel_idx*4;
                for(int i = 0; i < 4; i++)
                    fb_data_ptr[fb_data_idx+i] = rgba[i];
            }
        }
    }
    else // Use ColorMap
    {
       // TODO
    }
}

void RFBFramebuffer::put_rect_cursor(const Rect2& p_rect, const ByteArray& p_data, int p_data_offset)
{
    put_rect_raw(p_rect, p_data, p_data_offset);
    int rect_x = p_rect.pos.x;
    int rect_y = p_rect.pos.y;
    int rect_width = p_rect.size.x;
    int rect_height = p_rect.size.y;
    DVector<uint8_t>::Read r = p_data.read();
    DVector<uint8_t>::Write w = mData.write();
    uint8_t* fb_data_ptr = w.ptr();
    int bitmask_data_offset = p_rect.size.x*p_rect.size.y*mPixelFormat.bytes_per_pixel;
    const uint8_t* bitmask_data_ptr = r.ptr() + p_data_offset + bitmask_data_offset;
    for(int y = 0; y < rect_height; y++)
    {
        for(int x = 0; x < rect_width; x++)
        {
            int bit_idx = x % 8;
            if(x > 0 && bit_idx == 0)
                bitmask_data_ptr++;
            if((bitmask_data_ptr[0] & (128 >> bit_idx)) == 0)
            {
                int fb_pixel_idx = ((rect_y+y)*mSize.x) + (rect_x+x);
                int fb_data_idx = fb_pixel_idx*4;
                fb_data_ptr[fb_data_idx+3] = 0;
            }

        }
        bitmask_data_ptr++;
    }
}

void RFBFramebuffer::copy_rect(const Rect2& p_src_rect, const Vector2& p_dst_pos)
{
    int rect_width = p_src_rect.size.x;
    int rect_height = p_src_rect.size.y;
    int src_rect_x = p_src_rect.pos.x;
    int src_rect_y = p_src_rect.pos.y;
    int dst_rect_x = p_dst_pos.x;
    int dst_rect_y = p_dst_pos.y;

    DVector<uint8_t> rect_copy;
    rect_copy.resize(rect_width*rect_height*4);

    DVector<uint8_t>::Write w1 = mData.write();
    DVector<uint8_t>::Write w2 = rect_copy.write();

    uint8_t* fb_data_ptr = w1.ptr();
    uint8_t* rect_copy_data_ptr = w2.ptr();

    for(int y = 0; y < rect_height; y++)
    {
        for(int x = 0; x < rect_width; x++)
        {
            int fb_pixel_idx = ((src_rect_y+y)*mSize.x) + (src_rect_x+x);
            int rect_copy_pixel_idx = (y*rect_width) + x;
            for(int i = 0; i < 4; i++)
                rect_copy_data_ptr[rect_copy_pixel_idx*4+i] = fb_data_ptr[fb_pixel_idx*4+i];
        }
    }

    for(int y = 0; y < rect_height; y++)
    {
        for(int x = 0; x < rect_width; x++)
        {
            int fb_pixel_idx = ((dst_rect_y+y)*mSize.x) + (dst_rect_x+x);
            int rect_copy_pixel_idx = (y*rect_width) + x;
            for(int i = 0; i < 4; i++)
                fb_data_ptr[fb_pixel_idx*4+i] = rect_copy_data_ptr[rect_copy_pixel_idx*4+i];
        }
    }
}

Image RFBFramebuffer::get_image() const
{
    Image image;
    image.create(mSize.x, mSize.y, 0, Image::FORMAT_RGBA, mData);
    return image;
}
