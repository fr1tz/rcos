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


#ifndef RFB_UTIL_H
#define RFB_UTIL_H

#include "reference.h"

class RFBUtil : public Reference
{
    OBJ_TYPE(RFBUtil, Reference);
    OBJ_CATEGORY("References");

    ByteArray des_xcrypt(const ByteArray& p_data, const ByteArray& p_key, int p_mode);

protected:
	static void _bind_methods();

public:
    ByteArray des_encrypt(const ByteArray& p_data, const ByteArray& p_key);
    ByteArray des_decrypt(const ByteArray& p_data, const ByteArray& p_key);
};

#endif // RFB_UTIL_H
