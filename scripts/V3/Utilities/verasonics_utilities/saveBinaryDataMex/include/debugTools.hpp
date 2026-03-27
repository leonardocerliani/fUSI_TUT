#ifndef __DEBUGTOOLS_HPP__
#define __DEBUGTOOLS_HPP__

#include <iostream>

// for now have debugging on when this is included
// #define _DEBUG 1
#ifndef _DEBUG
#define _DEBUG 0
#endif
// #else
// #define _DEBUG 1

#if _DEBUG
#define _DEBUG_MSG(str)                              \
    do                                               \
    {                                                \
        std::cout << "[DEBUG] " << str << std::endl; \
    } while (false)
#else
#define _DEBUG_MSG(str) \
    do                  \
    {                   \
    } while (false)
#endif

#if _DEBUG
#define _DEBUG_EVAL(x) debug_eval(x)
#else
#define _DEBUG_EVAL(x) \
    do                 \
    {                  \
    } while (false)
#endif

#endif //!__DEBUGTOOLS_HPP__
