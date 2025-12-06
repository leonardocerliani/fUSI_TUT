#include "Timer.hpp"

Timer::Timer() : beg_(clock_::now()) {}

void Timer::reset() { beg_ = clock_::now(); }

double Timer::printElapsed() const
{
    double telap = std::chrono::duration_cast<second_>(clock_::now() - beg_).count();
    std::cout << "Elapsed time: " << telap << " s" << std::endl;
    return telap;
}

double Timer::printElapsed(const char *msg) const
{
    double telap = std::chrono::duration_cast<second_>(clock_::now() - beg_).count();
    std::cout << std::fixed << std::setprecision(4);
    std::cout << "Elapsed time: " << telap << " s"
              << "\t[" << msg << "]" << std::endl;
    return telap;
}

double Timer::elapsed() const
{
    return std::chrono::duration_cast<second_>(clock_::now() - beg_).count();
}
