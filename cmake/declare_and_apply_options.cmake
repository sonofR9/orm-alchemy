set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)

option(ENABLE_TEST "Set to \"ON\" for test build" ON)

# option(ENABLE_CLANG_FORMAT "Set to \"ON\" to add clang-format build target" OFF)

option(ENABLE_CLANG_TIDY "Set to \"ON\" to enable clang-tidy" ON)
# option(ENABLE_CPPLINT "Set to \"ON\" to enable cpplint" OFF)
# option(ENABLE_CPPCHECK "Set to \"ON\" to enable cppcheck" OFF)

# TODO(novak) memory sanitizer?
option(ENABLE_UNDERFINED_SANITIZER "Set to \"ON\" to enable sanitizer=underfined" OFF)
option(ENABLE_ADDRESS_SANITIZER "Set to \"ON\" to enable address sanitizer" OFF)
option(ENABLE_LEAK_SANITIZER "Set to \"ON\" to enable leak sanitizer" OFF)
option(ENABLE_SANITIZER "Set to \"ON\" to enable adress, leak, underfined sanitizer" OFF)
option(ENABLE_THREAD_SANITIZER "Set to \"ON\" to enable thread sanitizer" OFF)

include(cmake/apply_options.cmake)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
