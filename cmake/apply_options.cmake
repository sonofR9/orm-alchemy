string(ASCII 27 Esc)
set(ResetColor "${Esc}[m")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(ENABLE_CLANG_FORMAT)
    include(cmake/get_all_sources.cmake)
endif()

if(ENABLE_CLANG_FORMAT)
    set(BoldYellow "${Esc}[1;33m")
    message("\n${BoldYellow}Clang format build target is added${ResetColor}")

    include(cmake/clang_format.cmake)

    clangformat_setup(${ALL_SOURCE_FILES})
endif()

# sanitizers
set(SANITIZERS_FLAGS "")
if (ENABLE_SANTIZER)
    set(ENABLE_UNDERFINED_SANITIZER true)
    set(ENABLE_ADDRESS_SANITIZER true)
    set(ENABLE_LEAK_SANITIZER true)
endif()

if(ENABLE_UNDERFINED_SANITIZER)
    set(DEBUG_MESSAGE "${DEBUG_MESSAGE} with sanitizer=undefined enabled")
    list(APPEND SANITIZERS_FLAGS "-fsanitize=undefined")
endif()

if(ENABLE_ADDRESS_SANITIZER)
    set(DEBUG_MESSAGE "${DEBUG_MESSAGE} with address sanitizer enabled")
    list(APPEND SANITIZERS_FLAGS "-fsanitize=address")
endif()

if(ENABLE_LEAK_SANITIZER)
    set(DEBUG_MESSAGE "${DEBUG_MESSAGE} with leak sanitizer enabled")
    list(APPEND SANITIZERS_FLAGS "-fsanitize=leak")
endif()

if(ENABLE_THREAD_SANITIZER)
    set(DEBUG_MESSAGE "${DEBUG_MESSAGE} with thread sanitizer enabled. Leak, address, underfined sanitizers are disabled.")
    set(SANITIZERS_FLAGS
        "-fsanitize=thread"
    )
endif()

add_compile_options(${SANITIZERS_FLAGS})
add_link_options(${SANITIZERS_FLAGS})

if(ENABLE_TEST)
    set(BoldCyan "${Esc}[1;36m")
    message("\n${BoldCyan}Build with tests is enabled${ResetColor}")

    set(GTEST_USAGE_FOUND OFF)

    file(GLOB_RECURSE cmakelists_files "${CMAKE_SOURCE_DIR}/CMakeLists.txt")
    foreach(cmakelist_file ${cmakelists_files})
        file(READ "${cmakelist_file}" cmakelist_content)
        string(FIND "${cmakelist_content}" "GTest::" index1)
        string(FIND "${cmakelist_content}" "GTEST_LIBRARY" index2)
        string(FIND "${cmakelist_content}" "gtest_discover_tests" index3)
        if(NOT ${index1} EQUAL -1 OR NOT ${index2} EQUAL -1 OR NOT ${index3} EQUAL -1)
            set(GTEST_USAGE_FOUND ON)
            message("Found GTest usage in ${cmakelist_file}")
        endif()
    endforeach()

    if (GTEST_USAGE_FOUND) 
        find_package(GTest)

        if(${GTest_FOUND})
        else()
            include(FetchContent)
            FetchContent_Declare(
                googletest
                GIT_REPOSITORY https://github.com/google/googletest.git
                GIT_TAG release-1.11.0
            )
            set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
            FetchContent_MakeAvailable(googletest)
        endif()
    endif()

    enable_testing()
endif()

# compilation flags for warnnings etc.
if("CMAKE_CXX_COMPILER_ID" STREQUAL "MSVC") 
    set(WARNINGS_FLAGS
        "-Wall"
    )
else()
    set(WARNINGS_FLAGS
        # "-Werror"
        "-Wall"
        "-Wextra"
        "-Wpedantic"
        "-Wswitch-enum"
    )
    list(APPEND WARNINGS_FLAGS "-Wno-invalid-utf8")
    
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        list(APPEND WARNINGS_FLAGS
                    "-Wno-c++20-designator"
                    "-Wno-extra-semi"
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        # no can do about designated constrcturs and extra semicolons
    endif()
endif()

add_compile_options(${WARNINGS_FLAGS})
add_compile_options("-ftemplate-backtrace-limit=0")
add_compile_definitions($<$<OR:$<CONFIG:Release>,$<CONFIG:MinSizeRel>>:QT_NO_DEBUG_OUTPUT>)
add_compile_definitions($<$<OR:$<CONFIG:Release>,$<CONFIG:MinSizeRel>>:QT_NO_DEBUG>)

if(ENABLE_CLANG_TIDY)
    set(BoldBlue "${Esc}[1;34m")
    message("\n${BoldBlue}Clang tidy is enabled${ResetColor}")

    execute_process(COMMAND clang-tidy "--version"
                    RESULT_VARIABLE RESULT_CLANG_TIDY
                    OUTPUT_VARIABLE FOUND_CLANG_TIDY_OUT
    )

    set(CLANG_TIDY_ERROR FALSE)
    if(NOT RESULT_CLANG_TIDY STREQUAL "0")
        set(RedBackgroundBold "${Esc}[1;91m")
        message("\n${RedBackgroundBold}"
        "                                   Warning!!!                                   \n"
        "Clang tidy is not found, therefore it is disabled!                              ")
        set(CLANG_TIDY_ERROR TRUE)
    else()
        string(REGEX MATCH "LLVM version [0-9]+" _version_string "${FOUND_CLANG_TIDY_OUT}")
        # Remove the "LLVM version " part to get just the version number
        string(REGEX REPLACE "LLVM version " "" LLVM_MAJOR_VERSION "${_version_string}")

        if(LLVM_MAJOR_VERSION LESS 18)
            set(YellowBackgroundBold "${Esc}[1;93m")
            message("\n${YellowBackgroundBold}"
            "                                    Warning!                                    \n"
            "Clang tidy version is less then 18!                                             \n"
            "It will be used, but there may be some errors.                                  ")
            set(CLANG_TIDY_ERROR TRUE)
        endif()

        set(CLANG_TIDY_FLAGS
            "--export-fixes=fixes.yaml"
            "--use-color"
            "-p=${CMAKE_BINARY_DIR}"
        )

        set(CMAKE_CXX_CLANG_TIDY clang-tidy ${CLANG_TIDY_FLAGS})
    endif()

    if(CLANG_TIDY_ERROR)
        message(
            "Consider running:                                                               \n"
            "sudo apt install clang-18                                                       \n"
            "And then create symlink to installed clang-tidy (you may use script located in  \n"
            "handy_scripts folder in the git repository  a_novak/teamsun-repo-config.git).   \n"
            "If there is a newer version of clang-tidy, consider installing it instead.       "
            "${ResetColor}"
        )
    endif()
else()
    set(RedBackgroundBold "${Esc}[1;91m")
    message("\n${RedBackgroundBold}"
        "                         Clang tidy is disabled!!                               \n"
        "Please, set ENABLE_CLANG_TIDY to ON, so that you'll know that your code is      \n"
        "trully perfect! (at least, that static analyzer does not find any errors)       "
        "${ResetColor}"
    )
endif()

if(ENABLE_CPPLINT)
    set(BoldBlue "${Esc}[1;34m")
    message("\n${BoldBlue}Cpplint is enabled${ResetColor}")

    set(CPPLINT_FLAGS
        "--linelength=100"
        "--filter=-build/include_subdir,-legal/copyright,-whitespace/indent,-build/namespaces,-whitespace/braces,-whitespace/newline"
    )

    set(CMAKE_CXX_CPPLINT "cpplint" ${CPPLINT_FLAGS})
endif()

if(ENABLE_CPPCHECK)
    set(BoldBlue "${Esc}[1;34m")
    message("\n${BoldBlue}Cppcheck is enabled${ResetColor}")

    set(CPPCHECK_FLAGS
        "--report-progress"
    )

    set(CMAKE_CXX_CPPCHECK "cppcheck" ${CPPCHECK_FLAGS})
endif()
