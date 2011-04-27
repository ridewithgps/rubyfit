////////////////////////////////////////////////////////////////////////////////
// The following .FIT software provided may be used with .FIT devices only and
// remains the copyrighted property of Dynastream Innovations Inc.
// The software is being provided on an "as-is" basis and as an accommodation,
// and therefore all warranties, representations, or guarantees of any kind
// (whether express, implied or statutory) including, without limitation,
// warranties of merchantability, non-infringement, or fitness for a particular
// purpose, are specifically disclaimed.
//
// Copyright 2008 Dynastream Innovations Inc.
// All rights reserved. This software may not be reproduced by any means
// without express written approval of Dynastream Innovations Inc.
////////////////////////////////////////////////////////////////////////////////

#include "string.h"
#include "fit_product.h"


///////////////////////////////////////////////////////////////////////
// Public Constants
///////////////////////////////////////////////////////////////////////

const FIT_UINT8 fit_base_type_sizes[FIT_BASE_TYPES] =
{
   sizeof(FIT_ENUM),
   sizeof(FIT_SINT8),
   sizeof(FIT_UINT8),
   sizeof(FIT_SINT16),
   sizeof(FIT_UINT16),
   sizeof(FIT_SINT32),
   sizeof(FIT_UINT32),
   sizeof(FIT_STRING),
   sizeof(FIT_FLOAT32),
   sizeof(FIT_FLOAT64),
   sizeof(FIT_UINT8Z),
   sizeof(FIT_UINT16Z),
   sizeof(FIT_UINT32Z),
   sizeof(FIT_BYTE),
};

const FIT_ENUM fit_enum_invalid = FIT_ENUM_INVALID;
const FIT_SINT8 fit_sint8_invalid = FIT_SINT8_INVALID;
const FIT_UINT8 fit_uint8_invalid = FIT_UINT8_INVALID;
const FIT_SINT16 fit_sint16_invalid = FIT_SINT16_INVALID;
const FIT_UINT16 fit_uint16_invalid = FIT_UINT16_INVALID;
const FIT_SINT32 fit_sint32_invalid = FIT_SINT32_INVALID;
const FIT_UINT32 fit_uint32_invalid = FIT_UINT32_INVALID;
const FIT_STRING fit_string_invalid = FIT_STRING_INVALID;
const FIT_FLOAT32 fit_float32_invalid = FIT_FLOAT32_INVALID;
const FIT_FLOAT64 fit_float64_invalid = FIT_FLOAT64_INVALID;
const FIT_UINT8Z fit_uint8z_invalid = FIT_UINT8Z_INVALID;
const FIT_UINT16Z fit_uint16z_invalid = FIT_UINT16Z_INVALID;
const FIT_UINT32Z fit_uint32z_invalid = FIT_UINT32Z_INVALID;
const FIT_BYTE fit_byte_invalid = FIT_BYTE_INVALID;

const FIT_UINT8 *fit_base_type_invalids[FIT_BASE_TYPES] =
{
   (FIT_UINT8 *)&fit_enum_invalid,
   (FIT_UINT8 *)&fit_sint8_invalid,
   (FIT_UINT8 *)&fit_uint8_invalid,
   (FIT_UINT8 *)&fit_sint16_invalid,
   (FIT_UINT8 *)&fit_uint16_invalid,
   (FIT_UINT8 *)&fit_sint32_invalid,
   (FIT_UINT8 *)&fit_uint32_invalid,
   (FIT_UINT8 *)&fit_string_invalid,
   (FIT_UINT8 *)&fit_float32_invalid,
   (FIT_UINT8 *)&fit_float64_invalid,
   (FIT_UINT8 *)&fit_uint8z_invalid,
   (FIT_UINT8 *)&fit_uint16z_invalid,
   (FIT_UINT8 *)&fit_uint32z_invalid,
   (FIT_UINT8 *)&fit_byte_invalid,
};


///////////////////////////////////////////////////////////////////////
// Public Functions
///////////////////////////////////////////////////////////////////////

FIT_UINT8 Fit_GetArch(void)
{
   const FIT_UINT16 arch = 0x0100;
   return (*(FIT_UINT8 *)&arch);
}

const FIT_MESG_DEF *Fit_GetMesgDef(FIT_MESG_NUM global_mesg_num)
{
   FIT_UINT8 index;

   for (index = 0; index < FIT_MESGS; index++)
   {
      if (fit_mesg_defs[index]->global_mesg_num == global_mesg_num)
         return (FIT_MESG_DEF *) fit_mesg_defs[index];
   }

   return (FIT_MESG_DEF *) FIT_NULL;
}

FIT_UINT16 Fit_GetMesgDefSize(const FIT_MESG_DEF *mesg_def)
{
   if (mesg_def == FIT_NULL)
      return 0;

   return FIT_STRUCT_OFFSET(fields, FIT_MESG_DEF) + (FIT_UINT16)mesg_def->num_fields * FIT_FIELD_DEF_SIZE;
}

FIT_UINT8 Fit_GetMesgSize(FIT_MESG_NUM global_mesg_num)
{
   const FIT_MESG_DEF *mesg_def;
   FIT_UINT8 field;
   FIT_UINT8 size = 0;

   mesg_def = Fit_GetMesgDef(global_mesg_num);

   if (mesg_def == FIT_NULL)
      return 0;

   for (field = 0; field < mesg_def->num_fields; field++)
   {
      size += mesg_def->fields[FIT_MESG_DEF_FIELD_OFFSET(size, field)];
   }

   return size;
}

FIT_BOOL Fit_InitMesg(const FIT_MESG_DEF *mesg_def, void *mesg)
{
   FIT_UINT8 *mesg_buf = (FIT_UINT8 *) mesg;
   FIT_UINT8 field;

   if (mesg_def == FIT_NULL)
      return FIT_FALSE;

   for (field = 0; field < mesg_def->num_fields; field++)
   {
      FIT_UINT8 base_type_num = mesg_def->fields[FIT_MESG_DEF_FIELD_OFFSET(base_type, field)] & FIT_BASE_TYPE_NUM_MASK;
      FIT_UINT8 base_type_size;
      FIT_UINT8 field_size;

      if (base_type_num >= FIT_BASE_TYPES)
         return FIT_FALSE;

      base_type_size = fit_base_type_sizes[base_type_num];

      for (field_size = 0; field_size < mesg_def->fields[FIT_MESG_DEF_FIELD_OFFSET(size, field)]; field_size += base_type_size)
      {
         memcpy(mesg_buf, fit_base_type_invalids[base_type_num], base_type_size);
         mesg_buf += base_type_size;
      }
   }

   return FIT_TRUE;
}

FIT_UINT8 Fit_GetFieldOffset(const FIT_MESG_DEF *mesg_def, FIT_UINT8 field_def_num)
{
   FIT_UINT8 offset = 0;
   FIT_UINT8 field;

   if (mesg_def == FIT_NULL)
      return FIT_UINT8_INVALID;

   for (field = 0; field < mesg_def->num_fields; field++)
   {
      if (mesg_def->fields[FIT_MESG_DEF_FIELD_OFFSET(field_def_num, field)] == field_def_num)
         return offset;

      offset += mesg_def->fields[FIT_MESG_DEF_FIELD_OFFSET(size, field)];
   }

   return FIT_UINT8_INVALID;
}

FIT_UINT8 Fit_LookupMessage(FIT_UINT16 global_mesg_num, FIT_UINT16 message_index, FIT_UINT32 *offset, FIT_READ_BYTES_FUNC read_bytes_func)
{
   FIT_UINT16 global_mesg_nums[FIT_MAX_LOCAL_MESGS];
   FIT_UINT8 sizes[FIT_MAX_LOCAL_MESGS];
   FIT_UINT16 current_message_index = FIT_UINT16_INVALID;
   #if defined(FIT_MESSAGE_INDEX)
      FIT_UINT16 message_index_offset = FIT_UINT16_INVALID;
   #endif
   FIT_UINT8 i;

   *offset = 0;

   for (i = 0; i < FIT_MAX_LOCAL_MESGS; i++)
      global_mesg_nums[i] = FIT_UINT16_INVALID;

   while (1)
   {
      FIT_UINT8 header;
      FIT_UINT8 local_mesg_num;

      if (read_bytes_func(&header, *offset, sizeof(header)) != sizeof(header))
         return FIT_UINT8_INVALID;
         
      *offset += sizeof(header);

      if ((header & (FIT_HDR_TIME_REC_BIT | FIT_HDR_TYPE_DEF_BIT)) == FIT_HDR_TYPE_DEF_BIT)
      {
         FIT_MESG_DEF mesg_def_header;
         FIT_FIELD_DEF field_def;
         #if defined(FIT_MESSAGE_INDEX)
            FIT_UINT16 current_message_index_offset = FIT_UINT16_INVALID;  // Initialize to invalid.  If not found, it will remain invalid.
         #endif
         FIT_UINT8 current_size;
         FIT_UINT8 current_field_def;

         local_mesg_num = header & FIT_HDR_TYPE_MASK;

         if (read_bytes_func(&mesg_def_header, *offset, FIT_MESG_DEF_HEADER_SIZE) != FIT_MESG_DEF_HEADER_SIZE)
            return FIT_UINT8_INVALID;

         *offset += FIT_MESG_DEF_HEADER_SIZE;
         global_mesg_nums[local_mesg_num] = mesg_def_header.global_mesg_num;
         current_size = 0;

         for (current_field_def = 0; current_field_def < mesg_def_header.num_fields; current_field_def++)
         {
            if (read_bytes_func(&field_def, *offset, FIT_FIELD_DEF_SIZE) != FIT_FIELD_DEF_SIZE)
               return FIT_UINT8_INVALID;

            #if defined(FIT_MESSAGE_INDEX)
               if (field_def.field_def_num == FIT_MESSAGE_INDEX_FIELD_NUM)
                  current_message_index_offset = current_size;
            #endif

            current_size += field_def.size;
            *offset += FIT_FIELD_DEF_SIZE;
         }

         sizes[local_mesg_num] = current_size;

         #if defined(FIT_MESSAGE_INDEX)
            if (global_mesg_nums[local_mesg_num] == global_mesg_num)
               message_index_offset = current_message_index_offset;
         #endif
      }
      else
      {
         if (header & FIT_HDR_TIME_REC_BIT)
            local_mesg_num = (header & FIT_HDR_TIME_TYPE_MASK) >> FIT_HDR_TIME_TYPE_SHIFT;
         else
            local_mesg_num = header & FIT_HDR_TYPE_MASK;

         if (global_mesg_nums[local_mesg_num] == global_mesg_num)
         {
            // If the requested message index is invalid, we've found a match.
            if (message_index == FIT_UINT16_INVALID)
               return local_mesg_num;

            #if defined(FIT_MESSAGE_INDEX)
               if (message_index_offset != FIT_UINT16_INVALID)
               {
                  // Read the message index.
                  if (read_bytes_func(&current_message_index, *offset + message_index_offset, sizeof(current_message_index)) != sizeof(current_message_index))
                     return FIT_UINT8_INVALID;
               }
               else
            #endif
            {
               current_message_index++;
            }
            
            #if defined(FIT_MESSAGE_INDEX)
               if ((message_index & FIT_MESSAGE_INDEX_MASK) == (current_message_index & FIT_MESSAGE_INDEX_MASK))
            #else
               if (message_index == current_message_index)
            #endif
            {
               return local_mesg_num;
            }
         }
         else if (global_mesg_nums[local_mesg_num] == FIT_UINT16_INVALID)
         {
            return FIT_UINT8_INVALID;
         }

         *offset += sizes[local_mesg_num];
      }
   }
}
