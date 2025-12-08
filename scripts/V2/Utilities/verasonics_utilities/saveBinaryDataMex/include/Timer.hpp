#ifndef __TIMER_HPP__
#define __TIMER_HPP__

#include <iostream>
#include <chrono>
#include <iomanip>

/** How to use:
 *
 *    int main()
 *    {
 *        Timer tmr;
 *        double t = tmr.elapsed();
 *        std::cout << t << std::endl;
 *
 *        tmr.reset();
 *        t = tmr.elapsed();
 *        std::cout << t << std::endl;
 *
 *        return 0;
 *    }
 *
 */

/**
 * @brief Timer class
 * Example usage:
 *     int main()
 *     {
 *         Timer tmr;
 *         double t = tmr.elapsed();
 *         std::cout << t << std::endl;
 *         tmr.reset();
 *         t = tmr.elapsed();
 *         std::cout << t << std::endl;
 *         return 0;
 *     }
 */
class Timer
{
public:
    /**
     * @brief Construct a new Timer object
     *
     */
    Timer();
    /**
     * @brief Reset the timer to time something else
     *
     */
    void reset();
    /**
     * @brief Get elapsed time since creation or last reset and print to
     * std::cout.
     */
    double printElapsed() const;
    /**
     * @brief Get elapsed time since creation or last reset and print to
     * std::cout.
     *
     * @param msg message to display in front of time elapsed.
     * End result will be
     *  [<msg>] Elapsed time: xx s
     */
    double printElapsed(const char *msg) const;
    /**
     * @brief Get elapsed time since creation or last reset
     *
     * @return double, the time elapsed
     */

    double elapsed() const;

private:
    typedef std::chrono::high_resolution_clock clock_;
    typedef std::chrono::duration<double, std::ratio<1>> second_;
    std::chrono::time_point<clock_> beg_;
};

#endif