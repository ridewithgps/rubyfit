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


#if !defined(FIT_CONFIG_H)
#define FIT_CONFIG_H


#if defined(__cplusplus)
   extern "C" {
#endif

#define FIT_LOCAL_MESGS     16 // Adjust to suit RAM requirements.
#define FIT_ARCH_ENDIAN     FIT_ARCH_ENDIAN_LITTLE   // Set to correct endian for build architecture.

#define FIT_CONVERT_CHECK_CRC // Define to check file crc.
#define FIT_CONVERT_TIME_RECORD // Define to support time records (compressed timestamp).
//#define FIT_CONVERT_MULTI_THREAD // Define to support multiple conversion threads.
//#define FIT_CONVERT_CHECK_FILE_HDR_DATA_TYPE // Define to check file header for .FIT data type.  Verifies file is .FIT format before starting decode.

#if defined(__cplusplus)
   }
#endif

#endif // !defined(FIT_CONFIG_H)
