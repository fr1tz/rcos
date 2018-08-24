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

#include "rfb_util.h"
#include "d3des.h"

ByteArray RFBUtil::des_xcrypt(const ByteArray& p_data, const ByteArray& p_key, int mode)
{
    ByteArray ret;
    if(p_data.size() % 8 != 0)
    {
        ERR_EXPLAIN("data size not multiple of 8");
        ERR_FAIL_COND_V(p_data.size() % 8 != 0, ret);
    }
    if(p_key.size() != 8)
    {
        ERR_EXPLAIN("unsupported key length");
        ERR_FAIL_COND_V(p_key.size() != 8, ret);
    }
    unsigned char key[8];
    for(int i = 0; i < 8; i++)
        key[i] = p_key[i];
    rfbDesKey(key, mode);
    int num_blocks = p_data.size() / 8;
    for(int current_block = 0; current_block < num_blocks; current_block++)
    {
        unsigned char block[8];
        for(int i = 0; i < 8; i++)
            block[i] = p_data[current_block*8+i];
        rfbDes(block, block);
        for(int i = 0; i < 8; i++)
            ret.append(block[i]);
    }
    return ret;
}

void RFBUtil::_bind_methods()
{
    ObjectTypeDB::bind_method(_MD("des_encrypt", "data", "key"), &RFBUtil::des_encrypt);
    ObjectTypeDB::bind_method(_MD("des_decrypt", "data", "key"), &RFBUtil::des_decrypt);
}

ByteArray RFBUtil::des_encrypt(const ByteArray& p_data, const ByteArray& p_key)
{
    return des_xcrypt(p_data, p_key, EN0);
}

ByteArray RFBUtil::des_decrypt(const ByteArray& p_data, const ByteArray& p_key)
{
    return des_xcrypt(p_data, p_key, DE1);
}


