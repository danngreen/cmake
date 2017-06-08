# (C) 2017 Joao Paulo Magalhaes <dev@jpmag.me>

include(CMakeDependentOption)
include(PrintVar)

#------------------------------------------------------------------------------
function(setup_sanitize prefix)
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

    # option to turn sanitize on/off
    option(${prefix}_SANITIZE "turn on clang sanitizer targets" ON)

    # options for individual sanitizers - contingent on sanitize on/off
    cmake_dependent_option(${prefix}_ASAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_TSAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_MSAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_UBSAN "" ON "${prefix}_SANITIZE" OFF)

    if(${prefix}_SANITIZE)
        string(REGEX REPLACE "([0-9]+\\.[0-9]+).*" "\\1" LLVM_VERSION "${CMAKE_CXX_COMPILER_VERSION}")
        find_program(LLVM_SYMBOLIZER llvm-symbolizer
            NAMES llvm-symbolizer-${LLVM_VERSION} llvm-symbolizer
            DOC "symbolizer to use in sanitize tools")

        if(${prefix}_ASAN)
            message(STATUS "${prefix}_SANITIZE: enabling ASAN")
            set(${prefix}_ASAN_CFLAGS "-O1 -g -fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls" CACHE STRING "compile flags for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
            set(${prefix}_ASAN_LFLAGS "-g -fsanitize=address" CACHE STRING "linker flags for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
            set(${prefix}_ASAN_RENV  "env ASAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} ASAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
            # the flags are strings; we need to separate them into a list
            # to prevent cmake from quoting them when passing to the targets
            separate_arguments(${prefix}_ASAN_CFLAGS_SEP UNIX_COMMAND ${${prefix}_ASAN_CFLAGS})
            separate_arguments(${prefix}_ASAN_LFLAGS_SEP UNIX_COMMAND ${${prefix}_ASAN_LFLAGS})
        endif()

        if(${prefix}_TSAN)
            message(STATUS "${prefix}_SANITIZE: enabling TSAN")
            set(${prefix}_TSAN_CFLAGS "-O1 -g -fsanitize=thread -fno-omit-frame-pointer" CACHE STRING "compile flags for clang thread sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
            set(${prefix}_TSAN_LFLAGS "-g -fsanitize=thread" CACHE STRING "linker flags for clang thread sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
            set(${prefix}_TSAN_RENV  "env TSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} TSAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang thread sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
            separate_arguments(${prefix}_TSAN_CFLAGS_SEP UNIX_COMMAND ${${prefix}_TSAN_CFLAGS})
            separate_arguments(${prefix}_TSAN_LFLAGS_SEP UNIX_COMMAND ${${prefix}_TSAN_LFLAGS})
        endif()

        if(${prefix}_MSAN)
            message(STATUS "${prefix}_SANITIZE: enabling MSAN")
            set(${prefix}_MSAN_CFLAGS "-O1 -g -fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer -fno-optimize-sibling-calls" CACHE STRING "compile flags for clang memory sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
            set(${prefix}_MSAN_LFLAGS "-g -fsanitize=memory" CACHE STRING "linker flags for clang memory sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
            set(${prefix}_MSAN_RENV  "env MSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} MSAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang memory sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
            separate_arguments(${prefix}_MSAN_CFLAGS_SEP UNIX_COMMAND ${${prefix}_MSAN_CFLAGS})
            separate_arguments(${prefix}_MSAN_LFLAGS_SEP UNIX_COMMAND ${${prefix}_MSAN_LFLAGS})
        endif()

        if(${prefix}_UBSAN)
            message(STATUS "${prefix}_SANITIZE: enabling UBSAN")
            set(${prefix}_UBSAN_CFLAGS "-g -fsanitize=undefined" CACHE STRING "compile flags for clang undefined behaviour sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
            set(${prefix}_UBSAN_LFLAGS "-g -fsanitize=undefined" CACHE STRING "linker flags for clang undefined behaviour sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
            set(${prefix}_UBSAN_RENV "env UBSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} UBSAN_OPTIONS='symbolize=1 print_stacktrace=1'" CACHE STRING "run environment for clang undefined behaviour sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
            separate_arguments(${prefix}_UBSAN_CFLAGS_SEP UNIX_COMMAND ${${prefix}_UBSAN_CFLAGS})
            separate_arguments(${prefix}_UBSAN_LFLAGS_SEP UNIX_COMMAND ${${prefix}_UBSAN_LFLAGS})
        endif()

    endif() # ${prefix}_SANITIZE

endif() # clang
endfunction()

#------------------------------------------------------------------------------
function(sanitize_get_target_command name prefix which_sanitizer_ output)
    string(TOUPPER ${which_sanitizer_} which_sanitizer)
    if("${which_sanitizer}" STREQUAL ASAN)
    elseif("${which_sanitizer}" STREQUAL TSAN)
    elseif("${which_sanitizer}" STREQUAL MSAN)
    elseif("${which_sanitizer}" STREQUAL UBSAN)
    else()
        message(FATAL_ERROR "the sanitizer must be one of: ASAN, TSAN, MSAN, UBSAN")
    endif()
    separate_arguments(cmd UNIX_COMMAND "${${prefix}_${which_sanitizer}_RENV} ${name}")
    set(${output} ${cmd} PARENT_SCOPE)
endfunction()

function(_sanitize_set_target_folder tgt folder)
    if(folder)
        set_target_properties(${tgt} PROPERTIES FOLDER "${folder}")
    endif()
endfunction()

#------------------------------------------------------------------------------
function(sanitize_target name prefix)

    set(options0arg
        LIBRARY
        EXECUTABLE
    )
    set(options1arg
        OUTPUT_TARGET_NAMES
        FOLDER
    )
    set(optionsnarg
        SOURCES
        INC_DIRS
        LIBS
        LIB_DIRS
    )

    cmake_parse_arguments(_c4st "${options0arg}" "${options1arg}" "${optionsnarg}" ${ARGN})

    if((NOT _c4st_LIBRARY) AND (NOT _c4st_EXECUTABLE))
        message(FATAL_ERROR "either LIBRARY or EXECUTABLE must be specified")
    endif()

    if(prefix)
        string(TOUPPER ${prefix} oprefix)
        set(oprefix ${oprefix}_)
        string(TOLOWER ${prefix} prefix)
        set(prefix ${prefix}-)
    endif()

    if(${oprefix}SANITIZE AND NOT TARGET ${prefix}sanitize)
        add_custom_target(${prefix}sanitize)
        _sanitize_set_target_folder(${prefix}sanitize "${_c4st_FOLDER}")
    endif()
    if(${oprefix}ASAN AND NOT TARGET ${prefix}asan-all)
        add_custom_target(${prefix}asan-all)
        add_dependencies(${prefix}sanitize ${prefix}asan-all)
        _sanitize_set_target_folder(${prefix}asan-all "${_c4st_FOLDER}")
    endif()
    if(${oprefix}MSAN AND NOT TARGET ${prefix}msan-all)
        add_custom_target(${prefix}msan-all)
        add_dependencies(${prefix}sanitize ${prefix}msan-all)
        _sanitize_set_target_folder(${prefix}msan-all "${_c4st_FOLDER}")
    endif()
    if(${oprefix}TSAN AND NOT TARGET ${prefix}tsan-all)
        add_custom_target(${prefix}tsan-all)
        add_dependencies(${prefix}sanitize ${prefix}tsan-all)
        _sanitize_set_target_folder(${prefix}tsan-all "${_c4st_FOLDER}")
    endif()
    if(${oprefix}UBSAN AND NOT TARGET ${prefix}ubsan-all)
        add_custom_target(${prefix}ubsan-all)
        add_dependencies(${prefix}sanitize ${prefix}ubsan-all)
        _sanitize_set_target_folder(${prefix}ubsan-all "${_c4st_FOLDER}")
    endif()

    if(${oprefix}ASAN OR ${oprefix}MSAN OR ${oprefix}TSAN OR ${oprefix}UBSAN)
        add_custom_target(${name}-sanitize-all)
        _sanitize_set_target_folder(${name}-sanitize-all "${_c4st_FOLDER}")
    endif()

    set(targets)

    # https://clang.llvm.org/docs/AddressSanitizer.html
    if(${oprefix}ASAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-asan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-asan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        _sanitize_set_target_folder(${name}-asan "${_c4st_FOLDER}")
        list(APPEND targets ${name}-asan)
        target_include_directories(${name}-asan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-asan)
                list(APPEND _real_libs ${_l}-asan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-asan PUBLIC ${_real_libs})
        target_compile_options(${name}-asan PUBLIC ${${prefix}ASAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-asan PUBLIC ${${prefix}ASAN_LFLAGS_SEP})
        add_dependencies(${prefix}asan-all ${name}-asan)
        add_dependencies(${name}-sanitize-all ${name}-asan)
    endif()

    # https://clang.llvm.org/docs/ThreadSanitizer.html
    if(${oprefix}TSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-tsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-tsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        _sanitize_set_target_folder(${name}-tsan "${_c4st_FOLDER}")
        list(APPEND targets ${name}-tsan)
        target_include_directories(${name}-tsan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-tsan)
                list(APPEND _real_libs ${_l}-tsan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-tsan PUBLIC ${_real_libs})
        target_compile_options(${name}-tsan PUBLIC ${${prefix}TSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-tsan PUBLIC ${${prefix}TSAN_LFLAGS_SEP})
        add_dependencies(${prefix}tsan-all ${name}-tsan)
        add_dependencies(${name}-sanitize-all ${name}-tsan)
    endif()

    # https://clang.llvm.org/docs/MemorySanitizer.html
    if(${oprefix}MSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-msan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-msan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        _sanitize_set_target_folder(${name}-msan "${_c4st_FOLDER}")
        list(APPEND targets ${name}-msan)
        target_include_directories(${name}-msan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-msan)
                list(APPEND _real_libs ${_l}-msan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-msan PUBLIC ${_real_libs})
        target_compile_options(${name}-msan PUBLIC ${${prefix}MSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-msan PUBLIC ${${prefix}MSAN_LFLAGS_SEP})
        add_dependencies(${prefix}msan-all ${name}-msan)
        add_dependencies(${name}-sanitize-all ${name}-msan)
    endif()

    # https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
    if(${oprefix}UBSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-ubsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-ubsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        _sanitize_set_target_folder(${name}-ubsan "${_c4st_FOLDER}")
        list(APPEND targets ${name}-ubsan)
        target_include_directories(${name}-ubsan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-ubsan)
                list(APPEND _real_libs ${_l}-ubsan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-ubsan PUBLIC ${_real_libs})
        target_compile_options(${name}-ubsan PUBLIC ${${prefix}UBSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-ubsan PUBLIC ${${prefix}UBSAN_LFLAGS_SEP})
        add_dependencies(${prefix}ubsan-all ${name}-ubsan)
        add_dependencies(${name}-sanitize-all ${name}-ubsan)
    endif()

    if(_c4st_OUTPUT_TARGET_NAMES)
        set(${_c4st_OUTPUT_TARGET_NAMES} ${targets} PARENT_SCOPE)
    endif()
endfunction()
