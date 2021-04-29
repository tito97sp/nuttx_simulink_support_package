/* Copyright 2018-2019 The MathWorks, Inc. */
#ifndef MW_uORB_INIT_H
#define MW_uORB_INIT_H

#include <poll.h>
#include <uORB/uORB.h>
#include "rtwtypes.h"
#include "MW_uORB_busstruct_conversion.h"

//#if defined(MW_PX4_NUTTX_BUILD)
typedef struct pollfd pollfd_t;
//#elif defined(MW_PX4_POSIX_BUILD)
//typedef px4_pollfd_struct_t pollfd_t;
//#endif

typedef const struct orb_metadata orb_metadata_t;

#endif //MW_uORB_INIT_H
