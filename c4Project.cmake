if(NOT _c4_project_included)
set(_c4_project_included ON)

cmake_minimum_required(VERSION 3.11 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

include(ConfigurationTypes)
include(CreateSourceGroup)
include(c4SanitizeTarget)
include(c4StaticAnalysis)
include(PrintVar)
include(c4CatSources)
include(c4Log)
include(c4Doxygen)


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# define c4 project settings

set(C4_LOG_ENABLED OFF CACHE BOOL "default library type: either \"\"(defer to BUILD_SHARED_LIBS),INTERFACE,STATIC,SHARED,MODULE")
set(C4_LIBRARY_TYPE "" CACHE STRING "default library type: either \"\"(defer to BUILD_SHARED_LIBS),INTERFACE,STATIC,SHARED,MODULE")
set(C4_SOURCE_TRANSFORM NONE CACHE STRING "global source transform method")
set(C4_HDR_EXTS "h;hpp;hh;h++;hxx" CACHE STRING "list of header extensions for determining which files are headers")
set(C4_SRC_EXTS "c;cpp;cc;c++;cxx;cu;" CACHE STRING "list of compilation unit extensions for determining which files are sources")
set(C4_GEN_SRC_EXT "cpp" CACHE STRING "the extension of the output source files resulting from concatenation")
set(C4_GEN_HDR_EXT "hpp" CACHE STRING "the extension of the output header files resulting from concatenation")


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

function(c4_set_var_tmp var value)
    _c4_log("tmp-setting ${var} to ${value} (was ${${value}})")
    set(_c4_old_val_${var} ${${var}})
    set(${var} ${value} PARENT_SCOPE)
endfunction()

function(c4_clean_var_tmp var)
    _c4_log("cleaning ${var} to ${_c4_old_val_${var}} (tmp was ${${var}})")
    set(${var} ${_c4_old_val_${var}} PARENT_SCOPE)
endfunction()

macro(c4_override opt val)
    set(${opt} ${val} CACHE BOOL "" FORCE)
endmacro()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

macro(c4_setg var val)
    set(${var} ${val})
    set(${var} ${val} PARENT_SCOPE)
endmacro()


macro(_c4_handle_prefix prefix)
    string(TOUPPER "${prefix}" ucprefix)
    string(TOLOWER "${prefix}" lcprefix)
    set(ocprefix ${prefix})
    set(oprefix ${prefix})
    set(uprefix ${ucprefix})
    set(lprefix ${lcprefix})
    if(oprefix)
        set(oprefix "${oprefix}_")
    endif()
    if(uprefix)
        set(uprefix "${uprefix}_")
    endif()
    if(lprefix)
        set(lprefix "${lprefix}-")
    endif()
endmacro(_c4_handle_prefix)


macro(_show_pfx_vars)
    print_var(prefix)
    print_var(ucprefix)
    print_var(lcprefix)
    print_var(uprefix)
    print_var(lprefix)
endmacro()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

macro(_c4_handle_arg uprefix argname default)
     if("${_${argname}}" STREQUAL "")
         set(_${argname} "${default}")
     else()
         c4_setg(_${argname} "${_${argname}}")
     endif()
endmacro()


macro(_c4_handle_arg_or_fallback uprefix argname default)
    if("${_${argname}}" STREQUAL "")
        if("${${uprefix}${argname}}" STREQUAL "")
            if("${C4_${argname}}" STREQUAL "")
                _c4_log("${uprefix}: handle arg: _${argname}: picking default=${default}")
                c4_setg(_${argname} "${default}")
            else()
                _c4_log("${uprefix}: handle arg: _${argname}: picking C4_${argname}=${C4_${argname}}")
                c4_setg(_${argname} "${C4_${argname}}")
            endif()
        else()
            _c4_log("${uprefix}: handle arg: _${argname}: picking ${uprefix}${argname}=${${uprefix}${argname}}")
            c4_setg(_${argname} "${${uprefix}${argname}}")
        endif()
    else()
        _c4_log("${uprefix}: handle arg: _${argname}: picking explicit value _${argname}=${_${argname}}")
        #c4_setg(_${argname} "${_${argname}}")
    endif()
endmacro()



function(c4_declare_project prefix)
    _c4_handle_prefix(${prefix})
    # zero-value macro arguments
    set(opt0arg
        STANDALONE # Declare that targets from this project MAY be
                   # compiled in standalone mode. In this mode, any
                   # designated libraries on which a target depends
                   # will be incorporated into the target instead of
                   # being linked with it. The effect is to "flatten"
                   # those libraries into the requesting library, with
                   # their sources now becoming part of the requesting
                   # library; their dependencies are transitively handled.
                   # Note that requesting targets must explicitly
                   # opt-in to this behavior via the INCORPORATE
                   # argument to c4_add_library() or
                   # c4_add_executable(). Note also that this behavior
                   # is only enabled if this project's option
                   # ${prefix}_STANDALONE or C4_STANDALONE is set to ON.
    )
    # one-value macro arguments
    set(opt1arg
        DESC
        AUTHOR
        URL
        MAJOR
        MINOR
        RELEASE
        CXX_STANDARD  # if this is not provided, falls back on
                      # ${uprefix}CXX_STANDARD, then C4_CXX_STANDARD
    )
    # multi-value macro arguments
    set(optNarg
        AUTHORS
    )
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optNarg}" ${ARGN})
    #
    _c4_handle_arg(${uprefix} DESC "${lcprefix}")
    _c4_handle_arg(${uprefix} AUTHOR "${lcprefix} author <author@domain.net>")
    _c4_handle_arg(${uprefix} AUTHORS "${_AUTHOR}")
    _c4_handle_arg(${uprefix} URL "")
    _c4_handle_arg(${uprefix} MAJOR 0)
    _c4_handle_arg(${uprefix} MINOR 0)
    _c4_handle_arg(${uprefix} RELEASE 1)
    c4_setg(${uprefix}VERSION "${_MAJOR}.${_MINOR}.${_RELEASE}")
    _c4_handle_arg_or_fallback(${uprefix} CXX_STANDARD "")

    c4_set_proj_prop(${prefix} DESC         "${_DESC}")
    c4_set_proj_prop(${prefix} AUTHOR       "${_AUTHOR}")
    c4_set_proj_prop(${prefix} URL          "${_URL}")
    c4_set_proj_prop(${prefix} MAJOR        "${_MAJOR}")
    c4_set_proj_prop(${prefix} MINOR        "${_MINOR}")
    c4_set_proj_prop(${prefix} RELEASE      "${_RELEASE}")
    c4_set_proj_prop(${prefix} CXX_STANDARD "${_CXX_STANDARD}")

    if("${_c4_curr_subproject}" STREQUAL "")
        set(_c4_curr_subproject ${prefix})
        set(_c4_curr_path ${prefix})
    endif()

    if(_STANDALONE)
        option(${uprefix}STANDALONE
            "Enable compilation of opting-in targets from ${lcprefix} in standalone mode (ie, incorporate subprojects as specified in the INCORPORATE clause to c4_add_library/c4_add_target)" ${_STANDALONE})
    endif()
    option(${uprefix}DEV "enable development targets: tests, benchmarks, sanitize, static analysis, coverage" OFF)
    cmake_dependent_option(${uprefix}BUILD_TESTS "build unit tests" ON ${uprefix}DEV OFF)
    cmake_dependent_option(${uprefix}BUILD_BENCHMARKS "build benchmarks" ON ${uprefix}DEV OFF)
    c4_setup_coverage(${ucprefix})
    c4_setup_valgrind(${ucprefix} ${uprefix}DEV)
    setup_sanitize(${ucprefix} ${uprefix}DEV)
    c4_setup_static_analysis(${ucprefix} ${uprefix}DEV)

    # docs
    c4_setup_doxygen(${ucprefix} ${uprefix}DEV)

    # these are default compilation flags
    set(f "")
    set(${uprefix}CXX_FLAGS ${f} CACHE STRING "compilation flags")
    c4_setg(${uprefix}CXX_STANDARD "${_CXX_STANDARD}")
    if(${_CXX_STANDARD})
        c4_set_cxx(${_CXX_STANDARD})
    endif()

    # these are optional compilation flags
    cmake_dependent_option(${uprefix}PEDANTIC "Compile in pedantic mode" ON ${uprefix}DEV OFF)
    cmake_dependent_option(${uprefix}WERROR "Compile with warnings as errors" ON ${uprefix}DEV OFF)
    cmake_dependent_option(${uprefix}STRICT_ALIASING "Enable strict aliasing" ON ${uprefix}DEV OFF)


    if(${uprefix}STRICT_ALIASING)
        if(NOT MSVC)
            set(of "${of} -fstrict-aliasing")
        endif()
    endif()
    if(${uprefix}PEDANTIC)
        if(MSVC)
            set(of "${of} /W4")
        else()
            set(of "${of} -Wall -Wextra -Wshadow -pedantic -Wfloat-equal -fstrict-aliasing")
        endif()
    endif()
    if(${uprefix}WERROR)
        if(MSVC)
            set(of "${of} /WX")
        else()
            set(of "${of} -Werror -pedantic-errors")
        endif()
    endif()
    set(${uprefix}CXX_FLAGS "${${uprefix}CXX_FLAGS} ${of}")

    # https://stackoverflow.com/questions/24225067/how-to-define-function-inside-macro-in-cmake
    set(lcprefix_fwd_prefix_ ${lcprefix} PARENT_SCOPE)
    # c4_require_subproject
    macro(${lcprefix}_require_subproject)
        c4_require_subproject(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_library
    macro(${lcprefix}_add_library)
        c4_add_library(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_executable
    macro(${lcprefix}_add_executable)
        c4_add_executable(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_import_remote_proj
    macro(${lcprefix}_import_remote_proj)
        c4_import_remote_proj(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_download_remote_proj
    macro(${lcprefix}_download_remote_proj)
        c4_download_remote_proj(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_install_target
    macro(${lcprefix}_install_target)
        c4_install_target(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_install_exports
    macro(${lcprefix}_install_exports)
        c4_install_exports(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_install_files
    macro(${lcprefix}_install_files)
        c4_install_files("${lcprefix_fwd_prefix_}" ${ARGN})
    endmacro()
    # c4_add_doxygen
    macro(${lcprefix}_add_doxygen)
        c4_add_doxygen(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_setup_testing
    macro(${lcprefix}_setup_testing)
        c4_setup_testing(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_test
    macro(${lcprefix}_add_test)
        c4_add_test(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_test_fail_build
    macro(${lcprefix}_add_test_fail_build)
        c4_add_test_fail_build(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_install_include_test
    macro(${lcprefix}_add_install_include_test)
        c4_add_install_include_test(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_install_link_test
    macro(${lcprefix}_add_install_link_test)
        c4_add_install_link_test(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_setup_benchmarking
    macro(${lcprefix}_setup_benchmarking)
        c4_setup_benchmarking(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_benchmark
    macro(${lcprefix}_add_benchmark)
        c4_add_benchmark(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
    # c4_add_target_benchmark
    macro(${lcprefix}_add_target_benchmark)
        c4_add_target_benchmark(${lcprefix_fwd_prefix_} ${ARGN})
    endmacro()
endfunction(c4_declare_project)


function(c4_set_proj_prop prefix prop value)
    set(C4PROJ_${prefix}_${prop} ${value})
endfunction()


function(c4_get_proj_prop prefix prop var)
    set(${var} ${C4PROJ_${prefix}_${prop}} PARENT_SCOPE)
endfunction()


function(c4_set_target_prop target prop value)
    set_target_properties(${target} PROPERTIES C4_TGT_${prop} ${value})
endfunction()


function(c4_get_target_prop target prop var)
    get_target_property(val ${target} C4_TGT_${prop})
    set(${var} ${val} PARENT_SCOPE)
endfunction()


# WIP, under construction
function(c4_proj_get_version prefix dir)
    _c4_handle_prefix(${prefix})

    if("${dir}" STREQUAL "")
        set(dir ${CMAKE_CURRENT_LIST_DIR})
    endif()

    # http://xit0.org/2013/04/cmake-use-git-branch-and-commit-details-in-project/

    # Get the current working branch
    execute_process(COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${dir}
        OUTPUT_VARIABLE ${uprefix}GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Get the latest abbreviated commit hash of the working branch
    execute_process(COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${dir}
        OUTPUT_VARIABLE ${uprefix}GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # also: git diff --stat
    # also: git diff
    # also: git status --ignored

endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# examples:
# c4_set_cxx(11) # required, no extensions (eg c++11)
# c4_set_cxx(14) # required, no extensions (eg c++14)
# c4_set_cxx(11 EXTENSIONS) # opt-in to extensions (eg, gnu++11)
# c4_set_cxx(14 EXTENSIONS) # opt-in to extensions (eg, gnu++14)
# c4_set_cxx(11 OPTIONAL) # not REQUIRED. no extensions
# c4_set_cxx(11 OPTIONAL EXTENSIONS)
macro(c4_set_cxx standard)
    _c4_handle_cxx_standard_args(${ARGN})
    c4_setg(CMAKE_CXX_STANDARD ${standard})
    c4_setg(CMAKE_CXX_STANDARD_REQUIRED ${_REQUIRED})
    c4_setg(CMAKE_CXX_EXTENSIONS ${_EXTENSIONS})
endmacro()

# examples:
# c4_target_set_cxx(11) # required, no extensions (eg c++11)
# c4_target_set_cxx(14) # required, no extensions (eg c++14)
# c4_target_set_cxx(11 EXTENSIONS) # opt-in to extensions (eg, gnu++11)
# c4_target_set_cxx(14 EXTENSIONS) # opt-in to extensions (eg, gnu++14)
# c4_target_set_cxx(tgt 11 OPTIONAL) # not REQUIRED. no extensions
# c4_target_set_cxx(tgt 11 OPTIONAL EXTENSIONS)
function(c4_target_set_cxx target standard)
    _c4_handle_cxx_standard_args(${ARGN})
    set_target_properties(${_TARGET} PROPERTIES
        CXX_STANDARD ${standard}
        CXX_STANDARD_REQUIRED ${_REQUIRED}
        CXX_EXTENSIONS ${_EXTENSIONS})
endfunction()


macro(_c4_handle_cxx_standard_args)
    set(opt0arg
        OPTIONAL
        EXTENSIONS  # eg, prefer c++11 to gnu++11. defaults to OFF
    )
    set(opt1arg)
    set(optNarg)
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optNarg}" ${ARGN})
    # default values for args
    set(_REQUIRED ON)
    if(NOT "${_OPTIONAL}" STREQUAL "")
        set(_REQUIRED OFF)
    endif()
    if("${_EXTENSIONS}" STREQUAL "")
        set(_EXTENSIONS OFF)
    endif()
endmacro()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# type can be one of:
#  SUBDIRECTORY: the subproject is located in the given directory name and
#               will be added via add_subdirectory()
#  REMOTE: the subproject is located in a remote repo/url
#          and will be added via c4_import_remote_proj()
#
# examples:
#
# # c4opt requires subproject c4core, as a subdirectory. c4core will be used
# # as a separate library
# c4_require_subproject(c4opt
#     c4core
#     SUBDIRECTORY ${C4OPT_EXT_DIR}/c4core
#     )
#
# # c4opt requires subproject c4core, as a remote proj
# c4_require_subproject(c4opt
#     c4core
#     REMOTE GIT_REPOSITORY https://github.com/biojppm/c4core GIT_TAG master
#     )
function(c4_require_subproject prefix subproject_name)
    set(options0arg
        INTERFACE
        EXCLUDE_FROM_ALL
    )
    set(options1arg
        SUBDIRECTORY
    )
    set(optionsnarg
        REMOTE
    )
    cmake_parse_arguments("" "${options0arg}" "${options1arg}" "${optionsnarg}" ${ARGN})
    #
    _c4_handle_prefix(${prefix})
    list(APPEND _${uprefix}_deps ${subproject_name})
    c4_setg(_${uprefix}_deps ${_${uprefix}_deps})

    _c4_log("-----------------------------------------------")
    _c4_log("${lcprefix}: requires subproject ${subproject_name}!")

    _c4_get_subproject_property(${subproject_name} AVAILABLE _available)
    if(_available)
        _c4_log("${lcprefix}: required subproject ${subproject_name} was already imported:")
        _c4_log_subproject(${subproject_name})
    else() #elseif(NOT _${subproject_name}_available)
        _c4_log("${lcprefix}: required subproject ${subproject_name} is unknown. Importing...")
        if(_INTERFACE)
            _c4_log("${lcprefix}: ${subproject_name} is explicitly required as INTERFACE")
            c4_set_var_tmp(C4_LIBRARY_TYPE INTERFACE)
        #elseif(${uprefix}STANDALONE)
            #_c4_log("${lcprefix}: using ${uprefix}STANDALONE, so import ${subproject_name} as INTERFACE")
            #c4_set_var_tmp(C4_LIBRARY_TYPE INTERFACE)
        endif()
        set(_r ${CMAKE_CURRENT_BINARY_DIR}/subprojects/${subproject_name}) # root
        if(_REMOTE)
            _c4_mark_subproject_imported(${lcprefix} ${subproject_name} ${_r}/src ${_r}/build)
            message(STATUS "${lcprefix}: importing subproject ${subproject_name} (REMOTE)... ${ARGN}")
            c4_import_remote_proj(${prefix} ${subproject_name} ${_r} ${ARGN})
            _c4_log("${lcprefix}: finished importing subproject ${subproject_name} (REMOTE=${${uprefix}${subproject_name}_SRC_DIR}).")
        elseif(_SUBDIRECTORY)
            _c4_mark_subproject_imported(${lcprefix} ${subproject_name} ${_SUBDIRECTORY} ${_r}/build)
            message(STATUS "${lcprefix}: importing subproject ${subproject_name} (SUBDIRECTORY)... ${_SUBDIRECTORY}")
            c4_add_subproj(${lcprefix} ${subproject_name} ${_SUBDIRECTORY} ${_r}/build)
            _c4_log("${lcprefix}: finished importing subproject ${subproject_name} (SUBDIRECTORY=${${uprefix}${subproject_name}_SRC_DIR}).")
        else(_SUBDIRECTORY)
            message(FATAL_ERROR "subproject type must be either REMOTE or SUBDIRECTORY")
        endif(_REMOTE)
        if(_INTERFACE)# OR ${uprefix}STANDALONE)
            c4_clean_var_tmp(C4_LIBRARY_TYPE)
        endif()
    endif()
endfunction(c4_require_subproject)


function(c4_add_subproj prefix proj dir bindir)
    if("${_c4_curr_subproject}" STREQUAL "")
        set(_c4_curr_subproject ${prefix})
        set(_c4_curr_path ${prefix})
    endif()
    set(prev_subproject ${_c4_curr_subproject})
    set(prev_path ${_c4_curr_path})
    set(_c4_curr_subproject ${proj})
    set(_c4_curr_path ${_c4_curr_path}/${proj})
    _c4_log("adding subproj: ${prev_subproject}->${_c4_curr_subproject}. path=${_c4_curr_path}")
    add_subdirectory(${dir} ${bindir})
    set(_c4_curr_subproject ${prev_subproject})
    set(_c4_curr_path ${prev_path})
endfunction()


function(_c4_mark_subproject_imported importer_subproject subproject_name subproject_src_dir subproject_bin_dir)
    _c4_log("marking subproject imported: ${subproject_name} (imported by ${importer_subproject}). src=${subproject_src_dir}")
    #
    _c4_get_subproject_property(${importer_subproject} DEPENDENCIES deps)
    if(deps)
        list(APPEND deps ${subproject_name})
    else()
        set(deps ${subproject_name})
    endif()
    _c4_set_subproject_property(${importer_subproject} DEPENDENCIES "${deps}")
    _c4_get_folder(folder ${importer_subproject} ${subproject_name})
    #
    _c4_set_subproject_property(${subproject_name} AVAILABLE ON)
    _c4_set_subproject_property(${subproject_name} IMPORTER "${importer_subproject}")
    _c4_set_subproject_property(${subproject_name} SRC_DIR "${subproject_src_dir}")
    _c4_set_subproject_property(${subproject_name} BIN_DIR "${subproject_bin_dir}")
    _c4_set_subproject_property(${subproject_name} FOLDER "${folder}")
endfunction()


function(_c4_set_subproject_property subproject property value)
    set_property(GLOBAL PROPERTY _c4_subproject-${subproject}-${property} ${value})
endfunction()


function(_c4_get_subproject_property subproject property value)
    get_property(v GLOBAL PROPERTY _c4_subproject-${subproject}-${property})
    set(${value} ${v} PARENT_SCOPE)
endfunction()


function(_c4_log_subproject subproject)
    set(props AVAILABLE IMPORTER SRC_DIR BIN_DIR DEPENDENCIES FOLDER)
    foreach(p ${props})
        _c4_get_subproject_property(${subproject} ${p} pv)
        _c4_log("${subproject}: ${p}=${pv}")
    endforeach()
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# download external libs while running cmake:
# https://crascit.com/2015/07/25/cmake-gtest/
# (via https://stackoverflow.com/questions/15175318/cmake-how-to-build-external-projects-and-include-their-targets)
#
# to specify url, repo, tag, or branch,
# pass the needed arguments after dir.
# These arguments will be forwarded to ExternalProject_Add()
function(c4_import_remote_proj prefix name dir)
    c4_download_remote_proj(${prefix} ${name} ${dir} ${ARGN})
    c4_add_subproj(${prefix} ${name} ${dir}/src ${dir}/build)
endfunction()

function(c4_set_folder_remote_project_targets subfolder)
    foreach(target ${ARGN})
        set_target_properties(${target} PROPERTIES FOLDER ${_c4_curr_path}/${subfolder})
    endforeach()
endfunction()


function(c4_download_remote_proj prefix name dir)
    if((EXISTS ${dir}/dl) AND (EXISTS ${dir}/dl/CMakeLists.txt))
        return()
    endif()
    _c4_handle_prefix(${prefix})
    message(STATUS "${lcprefix}: downloading ${name}...")
    message(STATUS "${lcprefix}: downloading remote project ${name} to ${dir}/dl/CMakeLists.txt")
    file(WRITE ${dir}/dl/CMakeLists.txt "
cmake_minimum_required(VERSION 2.8.2)
project(${lcprefix}-download-${name} NONE)

# this project only downloads ${name}
# (ie, no configure, build or install step)
include(ExternalProject)

ExternalProject_Add(${name}-dl
    ${ARGN}
    SOURCE_DIR \"${dir}/src\"
    BINARY_DIR \"${dir}/build\"
    CONFIGURE_COMMAND \"\"
    BUILD_COMMAND \"\"
    INSTALL_COMMAND \"\"
    TEST_COMMAND \"\"
)
")
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
        WORKING_DIRECTORY ${dir}/dl)
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY ${dir}/dl)
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------



function(_c4_get_folder output importer_subproject subproject_name)
    _c4_get_subproject_property(${importer_subproject} FOLDER importer_folder)
    if("${importer_folder}" STREQUAL "")
        set(folder ${importer_subproject})
    else()
        set(folder "${importer_folder}/deps/${subproject_name}")
    endif()
    set(${output} ${folder} PARENT_SCOPE)
endfunction()


function(_c4_set_target_folder target name_to_append)
    if("${name_to_append}" STREQUAL "")
        set_target_properties(${name} PROPERTIES FOLDER "${_c4_curr_path}")
    else()
        if("${_c4_curr_path}" STREQUAL "")
            set_target_properties(${target} PROPERTIES FOLDER ${name_to_append})
        else()
            set_target_properties(${target} PROPERTIES FOLDER ${_c4_curr_path}/${name_to_append})
        endif()
    endif()
endfunction()


function(c4_set_folder_remote_project_targets subfolder)
    foreach(target ${ARGN})
        if(TARGET ${target})
            _c4_set_target_folder(${target} "${subfolder}")
        endif()
    endforeach()
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# a convenience alias to c4_add_target()
function(c4_add_executable prefix name)
    c4_add_target(${prefix} ${name} EXECUTABLE ${ARGN})
endfunction(c4_add_executable)


# a convenience alias to c4_add_target()
function(c4_add_library prefix name)
    c4_add_target(${prefix} ${name} LIBRARY ${ARGN})
endfunction(c4_add_library)


# example: c4_add_target(RYML ryml LIBRARY SOURCES ${SRC})
function(c4_add_target prefix name)
    _c4_handle_prefix(${prefix})
    _c4_log("${lcprefix}: adding target: ${name}: ${ARGN}")
    set(opt0arg
        LIBRARY     # the target is a library
        EXECUTABLE  # the target is an executable
        WIN32       # the executable is WIN32
        SANITIZE    # turn on sanitizer analysis
    )
    set(opt1arg
        LIBRARY_TYPE    # override global setting for C4_LIBRARY_TYPE
        SOURCE_ROOT     # the directory where relative source paths
                        # should be resolved. when empty,
                        # use CMAKE_CURRENT_SOURCE_DIR
        FOLDER          # IDE folder to group the target in
        SANITIZERS      # outputs the list of sanitize targets in this var
        SOURCE_TRANSFORM
    )
    set(optnarg
        INCORPORATE  # incorporate these libraries into this target,
                     # subject to ${uprefix}STANDALONE and C4_STANDALONE
        SOURCES  PUBLIC_SOURCES  INTERFACE_SOURCES  PRIVATE_SOURCES
        HEADERS  PUBLIC_HEADERS  INTERFACE_HEADERS  PRIVATE_HEADERS
        INC_DIRS PUBLIC_INC_DIRS INTERFACE_INC_DIRS PRIVATE_INC_DIRS
        LIBS     PUBLIC_LIBS     INTERFACE_LIBS     PRIVATE_LIBS
        DLLS           # DLLs required by this target
        MORE_ARGS
    )
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optnarg}" ${ARGN})

    if(${_LIBRARY})
        set(_what LIBRARY)
    elseif(${_EXECUTABLE})
        set(_what EXECUTABLE)
    else()
        message(FATAL_ERROR "must be either LIBRARY or EXECUTABLE")
    endif()

    _c4_handle_arg_or_fallback(${uprefix} SOURCE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
    function(c4_transform_to_full_path list all)
        set(l)
        foreach(f ${${list}})
            if(NOT IS_ABSOLUTE "${f}")
                set(f "${_SOURCE_ROOT}/${f}")
            endif()
            list(APPEND l "${f}")
        endforeach()
        set(${list} "${l}" PARENT_SCOPE)
        set(cp ${${all}})
        list(APPEND cp ${l})
        set(${all} ${cp} PARENT_SCOPE)
    endfunction()
    c4_transform_to_full_path(          _SOURCES allsrc)
    c4_transform_to_full_path(          _HEADERS allsrc)
    c4_transform_to_full_path(   _PUBLIC_SOURCES allsrc)
    c4_transform_to_full_path(_INTERFACE_SOURCES allsrc)
    c4_transform_to_full_path(  _PRIVATE_SOURCES allsrc)
    c4_transform_to_full_path(   _PUBLIC_HEADERS allsrc)
    c4_transform_to_full_path(_INTERFACE_HEADERS allsrc)
    c4_transform_to_full_path(  _PRIVATE_HEADERS allsrc)

    create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}" "${allsrc}")

    if(NOT ${uprefix}SANITIZE_ONLY)
        if(${_EXECUTABLE})
            _c4_log("${lcprefix}: adding executable: ${name}")
            if(WIN32)
                if(${_WIN32})
                    list(APPEND _MORE_ARGS WIN32)
                endif()
            endif()
	    add_executable(${name} ${_MORE_ARGS})
	    set(src_mode PRIVATE)
            set(tgt_type PUBLIC)
            set(compiled_target ON)
        elseif(${_LIBRARY})
            _c4_log("${lcprefix}: adding library: ${name}")
            set(_blt ${C4_LIBRARY_TYPE})
            if(NOT "${_LIBRARY_TYPE}" STREQUAL "")
                set(_blt ${_LIBRARY_TYPE})
            endif()
            #
            if("${_blt}" STREQUAL "INTERFACE")
                _c4_log("${lcprefix}: adding interface library ${name}")
                add_library(${name} INTERFACE)
                set(src_mode INTERFACE)
                set(tgt_type INTERFACE)
                set(compiled_target OFF)
            else()
                if(NOT ("${_blt}" STREQUAL ""))
                    _c4_log("${lcprefix}: adding library ${name} with type ${_blt}")
                    add_library(${name} ${_blt} ${_MORE_ARGS})
                else()
                    # obey BUILD_SHARED_LIBS (ie, either static or shared library)
                    _c4_log("${lcprefix}: adding library ${name} (defer to BUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}) --- ${_MORE_ARGS}")
                    add_library(${name} ${_MORE_ARGS})
                endif()
                # libraries
                set(src_mode PRIVATE)
                set(tgt_type PUBLIC)
                set(compiled_target ON)
            endif()
        endif(${_EXECUTABLE})

        if(src_mode STREQUAL "PUBLIC")
            c4_add_target_sources(${prefix} ${name}
                PUBLIC    "${_SOURCES};${_HEADERS};${_PUBLIC_SOURCES};${_PUBLIC_HEADERS}"
                INTERFACE "${_INTERFACE_SOURCES};${_INTERFACE_HEADERS}"
                PRIVATE   "${_PRIVATE_SOURCES};${_PRIVATE_HEADERS}")
        elseif(src_mode STREQUAL "INTERFACE")
            c4_add_target_sources(${prefix} ${name}
                PUBLIC    "${_PUBLIC_SOURCES};${_PUBLIC_HEADERS}"
                INTERFACE "${_SOURCES};${_HEADERS};${_INTERFACE_SOURCES};${_INTERFACE_HEADERS}"
                PRIVATE   "${_PRIVATE_SOURCES};${_PRIVATE_HEADERS}")
        elseif(src_mode STREQUAL "PRIVATE")
            c4_add_target_sources(${prefix} ${name}
                PUBLIC    "${_PUBLIC_SOURCES};${_PUBLIC_HEADERS}"
                INTERFACE "${_INTERFACE_SOURCES};${_INTERFACE_HEADERS}"
                PRIVATE   "${_SOURCES};${_HEADERS};${_PRIVATE_SOURCES};${_PRIVATE_HEADERS}")
        elseif()
            message(FATAL_ERROR "${lcprefix}: adding sources for target ${target} invalid source mode")
        endif()
        set_target_properties(${name} PROPERTIES C4_SOURCE_ROOT "${_SOURCE_ROOT}")

        if(_INC_DIRS)
            _c4_log("${lcprefix}: ${name}: adding include dirs ${_INC_DIRS} [from target: ${tgt_type}]")
            target_include_directories(${name} "${tgt_type}" ${_INC_DIRS})
        endif()
        if(_PUBLIC_INC_DIRS)
            _c4_log("${lcprefix}: ${name}: adding PUBLIC include dirs ${_PUBLIC_INC_DIRS}")
            target_include_directories(${name} PUBLIC ${_PUBLIC_INC_DIRS})
        endif()
        if(_INTERFACE_INC_DIRS)
            _c4_log("${lcprefix}: ${name}: adding INTERFACE include dirs ${_INTERFACE_INC_DIRS}")
            target_include_directories(${name} INTERFACE ${_INTERFACE_INC_DIRS})
        endif()
        if(_PRIVATE_INC_DIRS)
            _c4_log("${lcprefix}: ${name}: adding PRIVATE include dirs ${_PRIVATE_INC_DIRS}")
            target_include_directories(${name} PRIVATE ${_PRIVATE_INC_DIRS})
        endif()

        if(_LIBS)
            _c4_link_with_libs(${prefix} ${name} "${tgt_type}" "${_LIBS}" "${_INCORPORATE}")
        endif()
        if(_PUBLIC_LIBS)
            _c4_link_with_libs(${prefix} ${name} PUBLIC "${_PUBLIC_LIBS}" "${_INCORPORATE}")
        endif()
        if(_INTERFACE_LIBS)
            _c4_link_with_libs(${prefix} ${name} INTERFACE "${_INTERFACE_LIBS}" "${_INCORPORATE}")
        endif()
        if(_PRIVATE_LIBS)
            _c4_link_with_libs(${prefix} ${name} PRIVATE "${_PRIVATE_LIBS}" "${_INCORPORATE}")
        endif()

        if(compiled_target)
            _c4_set_target_folder(${name} "${_FOLDER}")
            if(${uprefix}CXX_FLAGS OR ${uprefix}C_FLAGS)
                #print_var(${uprefix}CXX_FLAGS)
                set_target_properties(${name} PROPERTIES
                    COMPILE_FLAGS ${${uprefix}CXX_FLAGS} ${${uprefix}C_FLAGS})
            endif()
            if(${uprefix}LINT)
                c4_static_analysis_target(${ucprefix} ${name} "${_FOLDER}" lint_targets)
            endif()
        endif(compiled_target)
    endif(NOT ${uprefix}SANITIZE_ONLY)

    if(compiled_target)
        if(_SANITIZE OR ${uprefix}SANITIZE)
            sanitize_target(${name} ${lcprefix}
                ${_what}   # LIBRARY or EXECUTABLE
                SOURCES ${allsrc}
                INC_DIRS ${_INC_DIRS} ${_PUBLIC_INC_DIRS} ${_INTERFACE_INC_DIRS} ${_PRIVATE_INC_DIRS}
                LIBS ${_LIBS} ${_PUBLIC_LIBS} ${_INTERFACE_LIBS} ${_PRIVATE_LIBS}
                OUTPUT_TARGET_NAMES san_targets
                FOLDER "${_FOLDER}"
                )
        endif()

        if(NOT ${uprefix}SANITIZE_ONLY)
            list(INSERT san_targets 0 ${name})
        endif()

        if(_SANITIZERS)
            set(${_SANITIZERS} ${san_targets} PARENT_SCOPE)
        endif()
    endif()

    # gather dlls so that they can be automatically copied to the target directory
    if(_DLLS)
        c4_set_transitive_property(${name} _C4_DLLS "${_DLLS}")
        get_target_property(vd ${name} _C4_DLLS)
    endif()

    if(${_EXECUTABLE})
        if(WIN32)
            c4_get_transitive_property(${name} _C4_DLLS transitive_dlls)
            foreach(_dll ${transitive_dlls})
                if(_dll)
                    _c4_log("enable copy of dll to target file dir: ${_dll} ---> $<TARGET_FILE_DIR:${name}>")
                    add_custom_command(TARGET ${name} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_dll}" $<TARGET_FILE_DIR:${name}>
                        COMMENT "${name}: requires dll: ${_dll} ---> $<TARGET_FILE_DIR:${name}"
                        )
                else()
                    message(WARNING "dll required by ${prefix}/${name} was not found, so cannot copy: ${_dll}")
                endif()
            endforeach()
        endif()
    endif()
endfunction() # add_target


function(_c4_link_with_libs prefix target link_type libs incorporate)
    _c4_handle_prefix(${prefix})
    foreach(lib ${libs})
        if(incorporate AND (
                    (C4_STANDALONE OR ${uprefix}STANDALONE)
                    AND
                    (NOT (${lib} IN_LIST incorporate))))
            _c4_log("${lcprefix}: -----> ${target} ${link_type} incorporating lib ${lib}")
            _c4_incorporate_lib(${prefix} ${target} ${link_type} ${lib})
        else()
            _c4_log("${lcprefix}: ${target} ${link_type} linking with lib ${lib}")
            target_link_libraries(${target} ${link_type} ${lib})
        endif()
    endforeach()
endfunction()


function(_c4_incorporate_lib prefix target link_type splib)
    _c4_handle_prefix(${prefix})
    #
    _c4_get_tgt_prop(splib_src ${splib} SOURCES)
    if(splib_src)
        create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}" "${splib_src}")
        c4_add_target_sources(${prefix} ${target} PRIVATE ${splib_src})
    endif()
    #
    _c4_get_tgt_prop(splib_isrc ${splib} INTERFACE_SOURCES)
    if(splib_isrc)
        c4_add_target_sources(${prefix} ${target} INTERFACE ${splib_isrc})
    endif()
    #
    #
    _c4_get_tgt_prop(splib_incs ${splib} INCLUDE_DIRECTORIES)
    if(splib_incs)
        target_include_directories(${target} PUBLIC ${splib_incs})
    endif()
    #
    _c4_get_tgt_prop(splib_iincs ${splib} INTERFACE_INCLUDE_DIRECTORIES)
    if(splib_iincs)
        target_include_directories(${target} INTERFACE ${splib_iincs})
    endif()
    #
    #
    _c4_get_tgt_prop(splib_lib ${splib} LINK_LIBRARIES)
    if(splib_lib)
        target_link_libraries(${target} PUBLIC ${splib_lib})
    endif()
    _c4_get_tgt_prop(splib_ilib ${splib} INTERFACE_LIBRARY)
    if(splib_ilib)
        target_link_libraries(${target} INTERFACE ${splib_ilib})
    endif()
endfunction()


function(_c4_get_tgt_prop out tgt prop)
    get_target_property(val ${tgt} ${prop})
    _c4_log("${tgt}: ${prop}=${val}")
    set(${out} ${val} PARENT_SCOPE)
endfunction()


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# WIP, under construction (still incomplete)
# see: https://github.com/pr0g/cmake-examples
# see: https://cliutils.gitlab.io/modern-cmake/


function(c4_install_target prefix target)
    _c4_handle_prefix(${prefix})
    # zero-value macro arguments
    set(opt0arg
    )
    # one-value macro arguments
    set(opt1arg
        EXPORT # the name of the export target. default: see below.
    )
    # multi-value macro arguments
    set(optNarg
    )
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optNarg}" ${ARGN})
    #
    _c4_handle_arg(${uprefix} EXPORT "${prefix}-export")
    #
    _c4_setup_install_vars(${prefix})
    # TODO: don't forget to install DLLs: _${uprefix}_${target}_DLLS
    install(TARGETS ${target}
        EXPORT ${_EXPORT}
        RUNTIME DESTINATION ${_RUNTIME_INSTALL_DIR}
        ARCHIVE DESTINATION ${_ARCHIVE_INSTALL_DIR}
        LIBRARY DESTINATION ${_LIBRARY_INSTALL_DIR}
        OBJECTS DESTINATION ${_OBJECTS_INSTALL_DIR}
        INCLUDES DESTINATION ${_INCLUDE_INSTALL_DIR}
        )
    #
    c4_install_sources(${prefix} ${target} include)
    #
    set(l ${${prefix}_TARGETS})
    list(APPEND l ${target})
    set(${prefix}_TARGETS ${l} PARENT_SCOPE)
    #
#    # pkgconfig (WIP)
#    set(pc ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig/${target}.pc)
#    file(WRITE ${pc} "# pkg-config: ${target}
#
#prefix=\"${CMAKE_INSTALL_PREFIX}\"
#exec_prefix=\"\${prefix}\"
#libdir=\"\${prefix}/${CMAKE_INSTALL_LIBDIR}\"
#includedir=\"\${prefix}/include\"
#
#Name: ${target}
#Description: A library for xyzzying frobnixes
#URL: https://github.com/me/mylibrary
#Version: 0.0.0
#Requires: @PKGCONF_REQ_PUB@
#Requires.private: @PKGCONF_REQ_PRIV@
#Cflags: -I\"${includedir}\"
#Libs: -L\"${libdir}\" -lmylibrary
#Libs.private: -L\"${libdir}\" -lmylibrary @PKGCONF_LIBS_PRIV@
#")
#    _c4_setup_install_vars(${prefix})
#    install(FILES ${pc} DESTINATION "${_ARCHIVE_INSTALL_DIR}/pkgconfig/")
endfunction()


function(c4_install_exports prefix)
    _c4_handle_prefix(${prefix})
    # zero-value macro arguments
    set(opt0arg
    )
    # one-value macro arguments
    set(opt1arg
        PREFIX     # override the c4 project-wide prefix. This will be used in the cmake
        TARGET     # the name of the exports target
        NAMESPACE  # the namespace for the targets
    )
    # multi-value macro arguments
    set(optNarg
        DEPENDENCIES
    )
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optNarg}" ${ARGN})
    #
    _c4_handle_arg(${uprefix} PREFIX    "${prefix}")
    _c4_handle_arg(${uprefix} TARGET    "${prefix}-export")
    _c4_handle_arg(${uprefix} NAMESPACE "${prefix}::")
    #
    _c4_setup_install_vars(${prefix})
    #
    list(GET ${prefix}_TARGETS 0 target)
    set(exported_target "${_NAMESPACE}${target}")
    set(targets_file "${_PREFIX}Targets.cmake")
    #
    set(deps)
    if(_DEPENDENCIES)
        set(deps "#-----------------------------
include(CMakeFindDependencyMacro)")
        foreach(d ${_DEPENDENCIES})
            set(deps "${deps}
find_dependency(${d} REQUIRED)
")
        endforeach()
        set(deps "${deps}
#-----------------------------")
    endif()
    #
    # cfg_dst is the path relative to install root where the export
    # should be installed; cfg_dst_rel is the path from there to
    # the install root
    macro(__c4_install_exports cfg_dst cfg_dst_rel)
        # make sure that different exports are staged in different directories
        set(case export_cases/${cfg_dst})
        file(MAKE_DIRECTORY ${case})
        #
        install(EXPORT "${_TARGET}"
            FILE "${targets_file}"
            NAMESPACE "${_NAMESPACE}"
            DESTINATION "${cfg_dst}")
        #
        # Config files
        # the module below has nice docs in it; do read them
        # to understand the macro calls below
        include(CMakePackageConfigHelpers)
        set(cfg ${CMAKE_CURRENT_BINARY_DIR}/${case}/${lcprefix}Config.cmake)
        set(cfg_ver ${CMAKE_CURRENT_BINARY_DIR}/${case}/${lcprefix}ConfigVersion.cmake)
        #
        file(WRITE ${cfg}.in "${deps}
set(${uprefix}VERSION ${${uprefix}VERSION})

@PACKAGE_INIT@

if(NOT TARGET ${exported_target})
    include(\${PACKAGE_PREFIX_DIR}/${targets_file})
endif()

# HACK: PACKAGE_PREFIX_DIR is obtained from the PACKAGE_INIT macro above;
# When used below in the calls to set_and_check(),
# it points at the location of this file. So point it instead
# to the CMAKE_INSTALL_PREFIX, in relative terms
get_filename_component(PACKAGE_PREFIX_DIR
    \"\${PACKAGE_PREFIX_DIR}/${cfg_dst_rel}\" ABSOLUTE)

set_and_check(${uprefix}INCLUDE_DIR \"@PACKAGE__INCLUDE_INSTALL_DIR@\")
set_and_check(${uprefix}LIB_DIR \"@PACKAGE__LIBRARY_INSTALL_DIR@\")
#set_and_check(${uprefix}SYSCONFIG_DIR \"@PACKAGE__SYSCONFIG_INSTALL_DIR@\")

check_required_components(${lcprefix})
")
        configure_package_config_file(${cfg}.in ${cfg}
            INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}"  # defaults to CMAKE_INSTALL_PREFIX
            INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}"
            PATH_VARS
                _INCLUDE_INSTALL_DIR
                _LIBRARY_INSTALL_DIR
                _SYSCONFIG_INSTALL_DIR
            #NO_SET_AND_CHECK_MACRO
            #NO_CHECK_REQUIRED_COMPONENTS_MACRO
        )
        write_basic_package_version_file(
            ${cfg_ver}
            VERSION ${${uprefix}VERSION}
            COMPATIBILITY AnyNewerVersion
        )
        install(FILES ${cfg} ${cfg_ver} DESTINATION ${cfg_dst})
    endmacro(__c4_install_exports)
    #
    # don't really know which is the right place to install the exports,
    # so for now install in all these candidates (relative to install root)...
    # YES:
    #__c4_install_exports(cmake/                                    ".."      )
    # NO:
    #__c4_install_exports(${_ARCHIVE_INSTALL_DIR}cmake/             "../.."   )
    # YES:
    __c4_install_exports(${_ARCHIVE_INSTALL_DIR}cmake/${lcprefix}/ "../../..")
    # YES:
    #__c4_install_exports(${_ARCHIVE_INSTALL_DIR}${lcprefix}/cmake/ "../../..")
endfunction()


macro(_c4_setup_install_vars prefix)
    _c4_handle_prefix(${prefix})
    set(_RUNTIME_INSTALL_DIR   bin/)
    set(_ARCHIVE_INSTALL_DIR   lib/)
    set(_LIBRARY_INSTALL_DIR   lib/) # TODO on Windows, ARCHIVE and LIBRARY dirs must be different to prevent name clashes
    set(_INCLUDE_INSTALL_DIR   include/)
    set(_OBJECTS_INSTALL_DIR   obj/)
    set(_SYSCONFIG_INSTALL_DIR etc/${lcprefix}/)
endmacro()


function(c4_install_files prefix files destination relative_to)
    _c4_log("${prefix}: adding files to install list, destination ${destination}: ${files}")
    foreach(f ${files})
        file(RELATIVE_PATH rf "${relative_to}" ${f})
        get_filename_component(rd "${rf}" DIRECTORY)
        install(FILES ${f} DESTINATION "${destination}/${rd}" ${ARGN})
    endforeach()
endfunction()


function(c4_install_directories prefix directories destination relative_to)
    _c4_log("${prefix}: adding directories to install list, destination ${destination}: ${directories}")
    foreach(d ${directories})
        file(RELATIVE_PATH rf "${relative_to}" ${d})
        get_filename_component(rd "${rf}" DIRECTORY)
        install(DIRECTORY ${d} DESTINATION "${destination}/${rd}" ${ARGN})
    endforeach()
endfunction()


function(c4_install_sources prefix target destination)
    # executables have no sources requiring install
    get_target_property(target_type ${target} TYPE)
    if(target_type STREQUAL "EXECUTABLE")
        return() # nothing to do
    endif()
    # get the sources from the target
    _c4_get_tgt_prop(src ${target} SOURCES)
    _c4_get_tgt_prop(isrc ${target} INTERFACE_SOURCES)
    _c4_get_tgt_prop(srcroot ${target} C4_SOURCE_ROOT)
    if(src)
        _c4cat_filter_hdrs("${src}" hdr)
        c4_install_files(${prefix} "${hdr}" "${destination}" "${srcroot}")
    endif()
    if(isrc)
        _c4cat_filter_srcs_hdrs("${isrc}" isrc)
        c4_install_files(${prefix} "${isrc}" "${destination}" "${srcroot}")
    endif()
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
function(c4_setup_testing prefix)
    #include(GoogleTest) # this module requires at least cmake 3.9
    _c4_handle_prefix(${prefix})
    message(STATUS "${lcprefix}: enabling tests")
    # umbrella target for building test binaries
    add_custom_target(${lprefix}test-build)
    set_target_properties(${lprefix}test-build PROPERTIES FOLDER ${_c4_curr_path}/${lprefix}test)
    _c4_set_target_folder(${lprefix}test-build ${lprefix}test)
    # umbrella target for running tests
    set(ctest_cmd env CTEST_OUTPUT_ON_FAILURE=1 ${CMAKE_CTEST_COMMAND} ${${uprefix}CTEST_OPTIONS} -C $<CONFIG>)
    add_custom_target(${lprefix}test
        ${CMAKE_COMMAND} -E echo CWD=${CMAKE_BINARY_DIR}
        COMMAND ${CMAKE_COMMAND} -E echo
        COMMAND ${CMAKE_COMMAND} -E echo ----------------------------------
        COMMAND ${CMAKE_COMMAND} -E echo ${ctest_cmd}
        COMMAND ${CMAKE_COMMAND} -E echo ----------------------------------
        COMMAND ${CMAKE_COMMAND} -E ${ctest_cmd}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        DEPENDS ${lprefix}test-build
        )
    _c4_set_target_folder(${lprefix}test ${lprefix}test)

    c4_override(BUILD_GTEST ON)
    c4_override(BUILD_GMOCK OFF)
    c4_override(gtest_force_shared_crt ON)
    c4_override(gtest_build_samples OFF)
    c4_override(gtest_build_tests OFF)
    #if(MSVC)
    #    # silence MSVC pedantic error on googletest's use of tr1: https://github.com/google/googletest/issues/1111
    #    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /D_SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING")
    #endif()
    c4_import_remote_proj(${prefix} gtest ${CMAKE_CURRENT_BINARY_DIR}/extern/gtest
        GIT_REPOSITORY https://github.com/google/googletest.git
        #GIT_TAG release-1.8.0
        )
    c4_set_folder_remote_project_targets(${lprefix}test gtest gtest_main)
endfunction(c4_setup_testing)


function(c4_add_test prefix target)
    _c4_handle_prefix(${prefix})
    #
    if(NOT ${uprefix}SANITIZE_ONLY)
        add_test(NAME ${target}-run COMMAND $<TARGET_FILE:${target}>)
    endif()
    #
    if(${CMAKE_BUILD_TYPE} STREQUAL "Coverage")
        add_dependencies(${lprefix}test-build ${target})
        return()
    endif()
    #
    set(sanitized_targets)
    foreach(s asan msan tsan ubsan)
        set(t ${target}-${s})
        if(TARGET ${t})
            list(APPEND sanitized_targets ${s})
        endif()
    endforeach()
    if(sanitized_targets)
        add_custom_target(${target}-all)
        add_dependencies(${target}-all ${target})
        add_dependencies(${lprefix}test-build ${target}-all)
        _c4_set_target_folder(${target}-all ${lprefix}test/${target})
    else()
        add_dependencies(${lprefix}test-build ${target})
    endif()
    if(sanitized_targets)
        foreach(s asan msan tsan ubsan)
            set(t ${target}-${s})
            if(TARGET ${t})
                add_dependencies(${target}-all ${t})
                sanitize_get_target_command($<TARGET_FILE:${t}> ${ucprefix} ${s} cmd)
                #message(STATUS "adding test: ${t}-run")
                add_test(NAME ${t}-run COMMAND ${cmd})
            endif()
        endforeach()
    endif()
    if(NOT ${uprefix}SANITIZE_ONLY)
        c4_add_valgrind(${prefix} ${target})
    endif()
    if(${uprefix}LINT)
        c4_static_analysis_add_tests(${ucprefix} ${target})
    endif()
endfunction(c4_add_test)


# every excess argument is passed on to set_target_properties()
function(c4_add_test_fail_build prefix name srccontent_or_srcfilename)
    #
    set(sdir ${CMAKE_CURRENT_BINARY_DIR}/test_fail_build)
    set(src ${srccontent_or_srcfilename})
    if("${src}" STREQUAL "")
        message(FATAL_ERROR "must be given an existing source file name or a non-empty string")
    endif()
    #
    if(EXISTS ${src})
        set(fn ${src})
    else()
        if(NOT EXISTS ${sdir})
            file(MAKE_DIRECTORY ${sdir})
        endif()
        set(fn ${sdir}/${name}.cpp)
        file(WRITE ${fn} "${src}")
    endif()
    #
    # https://stackoverflow.com/questions/30155619/expected-build-failure-tests-in-cmake
    add_executable(${name} ${fn})
    # don't build this target
    set_target_properties(${name} PROPERTIES
        EXCLUDE_FROM_ALL TRUE
        EXCLUDE_FROM_DEFAULT_BUILD TRUE
        # and pass on further properties given by the caller
        ${ARGN})
    add_test(NAME ${name}
        COMMAND ${CMAKE_COMMAND} --build . --target ${name} --config $<CONFIGURATION>
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    set_tests_properties(${name} PROPERTIES WILL_FAIL TRUE)
endfunction()


function(c4_add_install_link_test prefix library namespace exe_source_code)
    _c4_add_library_client_test(${prefix} ${library} "${namespace}" "${prefix}-test-${library}-install-link" "${exe_source_code}")
endfunction()


function(c4_add_install_include_test prefix library namespace)
    set(incfiles) # TODO get the list of include files
    set(incblock)
    foreach(i ${incfiles})
        set(incblock "${incblock}
#include <${i}>
")
    endforeach()
    set(src "${incblock}

int main()
{
    return 0;
}
")
    _c4_add_library_client_test(${prefix} ${library} "${namespace}" "${prefix}-test-${library}-install-include" "${src}")
endfunction()


function(_c4_add_library_client_test prefix library namespace pname source_code)
    _c4_handle_prefix(${prefix})
    set(pdir "${CMAKE_CURRENT_BINARY_DIR}/${pname}")
    set(bdir "${pdir}/build")
    if(NOT EXISTS "${pdir}")
        file(MAKE_DIRECTORY "${pdir}")
    endif()
    if(NOT EXISTS "${bdir}/build")
        file(MAKE_DIRECTORY "${bdir}/build")
    endif()
    set(psrc "${pdir}/${pname}.cpp")
    set(tsrc "${pdir}/${pname}-run.cmake")
    set(tout "${pdir}/${pname}-run-out.log")
    # generate the source file
    file(WRITE "${psrc}" "${source_code}")
    # generate the cmake project consuming this library
    file(WRITE "${pdir}/CMakeLists.txt" "
cmake_minimum_required(VERSION 3.12)
project(${pname} LANGUAGES CXX)

find_package(${library} REQUIRED)

add_executable(${pname} ${pname}.cpp)
# this must be the only required setup to link with ${library}
target_link_libraries(${pname} PUBLIC ${namespace}${library})

add_custom_target(${pname}-run
    COMMAND \$<TARGET_FILE:${pname}>
    DEPENDS ${pname}
)
")
    # The test consists in running the script generated below.
    # We force evaluation of the configuration generator expression
    # by receiving its result via the command line.
    add_test(NAME ${pname}-run
        COMMAND ${CMAKE_COMMAND} -DCFG_IN=$<CONFIG> -P "${tsrc}"
        )
    # generate the cmake script with the test content
    if(WIN32)
        set(cfg_opt "--config \${cfg}")
    endif()
    file(WRITE "${tsrc}" "
# run a command and check its return status
function(runcmd)
    message(STATUS \"Running command: \${ARGN}\")
    message(STATUS \"Running command: output goes to ${tout}\")
    execute_process(
        COMMAND \${ARGN}
        RESULT_VARIABLE retval
        OUTPUT_FILE \"${tout}\"
        ERROR_FILE \"${tout}\"
        # COMMAND_ECHO STDOUT  # only available from cmake-3.15
    )
    file(READ \"${tout}\" output)
    message(STATUS \"output:
--------------------
\${output}--------------------\")
    message(STATUS \"Exit status was \${retval}: \${ARGN}\")
    if(NOT (\${retval} EQUAL 0))
        message(FATAL_ERROR \"Command failed with exit status \${retval}: \${ARGN}\")
    endif()
endfunction()

# force evaluation of the configuration generator expression
# by receiving its result via the command line
set(cfg \${CFG_IN})

# install the library
runcmd(\"${CMAKE_COMMAND}\" --install \"${CMAKE_BINARY_DIR}\" ${cfg_opt})

# configure the client project
runcmd(\"${CMAKE_COMMAND}\" -S \"${pdir}\" -B \"${bdir}\" -DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX})

# build the client project
runcmd(\"${CMAKE_COMMAND}\" --build \"${bdir}\" ${cfg_opt})

# run the client executable
runcmd(\"${CMAKE_COMMAND}\" --build \"${bdir}\" --target \"${pname}-run\" ${cfg_opt})
")
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
function(c4_setup_valgrind prefix umbrella_option)
    if(UNIX AND (NOT ${CMAKE_BUILD_TYPE} STREQUAL "Coverage"))
        _c4_handle_prefix(${prefix})
        cmake_dependent_option(${uprefix}VALGRIND "enable valgrind tests" ON ${umbrella_option} OFF)
        cmake_dependent_option(${uprefix}VALGRIND_SGCHECK "enable valgrind tests with the exp-sgcheck tool" OFF ${umbrella_option} OFF)
        set(${uprefix}VALGRIND_OPTIONS "--gen-suppressions=all --error-exitcode=10101" CACHE STRING "options for valgrind tests")
    endif()
endfunction(c4_setup_valgrind)


function(c4_add_valgrind prefix target_name)
    _c4_handle_prefix(${prefix})
    # @todo: consider doing this for valgrind:
    # http://stackoverflow.com/questions/40325957/how-do-i-add-valgrind-tests-to-my-cmake-test-target
    # for now we explicitly run it:
    if(${uprefix}VALGRIND)
        separate_arguments(_vg_opts UNIX_COMMAND "${${uprefix}VALGRIND_OPTIONS}")
        add_test(NAME ${target_name}-valgrind COMMAND valgrind ${_vg_opts} $<TARGET_FILE:${target_name}>)
    endif()
    if(${uprefix}VALGRIND_SGCHECK)
        # stack and global array overrun detector
        # http://valgrind.org/docs/manual/sg-manual.html
        separate_arguments(_sg_opts UNIX_COMMAND "--tool=exp-sgcheck ${${uprefix}VALGRIND_OPTIONS}")
        add_test(NAME ${target_name}-sgcheck COMMAND valgrind ${_sg_opts} $<TARGET_FILE:${target_name}>)
    endif()
endfunction(c4_add_valgrind)


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
function(c4_setup_coverage prefix)
    _c4_handle_prefix(${prefix})
    set(_covok ON)
    if("${CMAKE_CXX_COMPILER_ID}" MATCHES "(Apple)?[Cc]lang")
        if("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS 3)
	    message(STATUS "${prefix} coverage: clang version must be 3.0.0 or greater. No coverage available.")
            set(_covok OFF)
        endif()
    elseif(NOT CMAKE_COMPILER_IS_GNUCXX)
        if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
            message(FATAL_ERROR "${prefix} coverage: compiler is not GNUCXX. No coverage available.")
        endif()
        set(_covok OFF)
    endif()
    if(NOT _covok)
        return()
    endif()
    set(_covon OFF)
    if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
        set(_covon ON)
    endif()
    option(${uprefix}COVERAGE "enable coverage targets" ${_covon})
    cmake_dependent_option(${uprefix}COVERAGE_CODECOV "enable coverage with codecov" ON ${uprefix}COVERAGE OFF)
    cmake_dependent_option(${uprefix}COVERAGE_COVERALLS "enable coverage with coveralls" ON ${uprefix}COVERAGE OFF)
    if(${uprefix}COVERAGE)
        #set(covflags "-g -O0 -fprofile-arcs -ftest-coverage")
        set(covflags "-g -O0 --coverage")
        if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
            set(covflags "${covflags} -fprofile-arcs -ftest-coverage -fno-inline -fno-inline-small-functions -fno-default-inline")
        endif()
        add_configuration_type(Coverage
            DEFAULT_FROM DEBUG
            C_FLAGS ${covflags}
            CXX_FLAGS ${covflags}
            )
        if(${CMAKE_BUILD_TYPE} STREQUAL "Coverage")
            if(${uprefix}COVERAGE_CODECOV)
                #include(CodeCoverage)
            endif()
            if(${uprefix}COVERAGE_COVERALLS)
                #include(Coveralls)
                #coveralls_turn_on_coverage() # NOT NEEDED, we're doing this manually.
            endif()
            find_program(GCOV gcov)
            find_program(LCOV lcov)
            find_program(GENHTML genhtml)
            find_program(CTEST ctest)
            if(NOT (GCOV AND LCOV AND GENHTML AND CTEST))
                if (HAVE_CXX_FLAG_COVERAGE)
                    set(CXX_FLAG_COVERAGE_MESSAGE supported)
                else()
                    set(CXX_FLAG_COVERAGE_MESSAGE unavailable)
                endif()
                message(WARNING
                    "Coverage not available:\n"
                    "  gcov: ${GCOV}\n"
                    "  lcov: ${LCOV}\n"
                    "  genhtml: ${GENHTML}\n"
                    "  ctest: ${CTEST}\n"
                    "  --coverage flag: ${CXX_FLAG_COVERAGE_MESSAGE}")
            endif()
            add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/lcov/index.html
                COMMAND ${LCOV} -q --zerocounters --directory .
                COMMAND ${LCOV} -q --no-external --capture --base-directory "${CMAKE_SOURCE_DIR}" --directory . --output-file before.lcov --initial
                COMMAND ${CTEST} --force-new-ctest-process
                COMMAND ${LCOV} -q --no-external --capture --base-directory "${CMAKE_SOURCE_DIR}" --directory . --output-file after.lcov
                COMMAND ${LCOV} -q --add-tracefile before.lcov --add-tracefile after.lcov --output-file final.lcov
                COMMAND ${LCOV} -q --remove final.lcov "'${CMAKE_SOURCE_DIR}/test/*'" "'/usr/*'" "'*/extern/*'" --output-file final.lcov
                COMMAND ${GENHTML} final.lcov -o lcov --demangle-cpp --sort -p "${CMAKE_BINARY_DIR}" -t ${lcprefix}
                #DEPENDS ${lprefix}test
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "${prefix} coverage: Running LCOV"
                )
            add_custom_target(${lprefix}coverage
                DEPENDS ${CMAKE_BINARY_DIR}/lcov/index.html
                COMMENT "${lcprefix} coverage: LCOV report at ${CMAKE_BINARY_DIR}/lcov/index.html"
                )
            message(STATUS "Coverage command added")
        endif()
    endif()
endfunction(c4_setup_coverage)


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
function(c4_setup_benchmarking prefix)
    _c4_handle_prefix(${prefix})
    message(STATUS "${lcprefix}: enabling benchmarks: to build, ${lprefix}bm-build")
    message(STATUS "${lcprefix}: enabling benchmarks: to run, ${lprefix}bm")
    # umbrella target for building test binaries
    add_custom_target(${lprefix}bm-build)
    # umbrella target for running benchmarks
    add_custom_target(${lprefix}bm
        ${CMAKE_COMMAND} -E echo CWD=${CMAKE_BINARY_DIR}
        DEPENDS ${lprefix}bm-build
        )
    _c4_set_target_folder(${lprefix}bm-build ${lprefix}bm)
    _c4_set_target_folder(${lprefix}bm ${lprefix}bm)
    # download google benchmark
    if(NOT TARGET benchmark)
        c4_override(BENCHMARK_ENABLE_TESTING OFF)
        c4_override(BENCHMARK_ENABLE_EXCEPTIONS OFF)
        c4_override(BENCHMARK_ENABLE_LTO OFF)
        c4_import_remote_proj(${prefix} googlebenchmark ${CMAKE_CURRENT_BINARY_DIR}/extern/googlebenchmark
            GIT_REPOSITORY https://github.com/google/benchmark.git
            )
        c4_set_folder_remote_project_targets(${lprefix}bm benchmark benchmark_main)
    endif()
    #
    option(${uprefix}BENCHMARK_CPUPOWER
        "set the cpu mode to performance before / powersave after the benchmark" OFF)
    if(${uprefix}BENCHMARK_CPUPOWER)
        find_program(C4_SUDO sudo)
        find_program(C4_CPUPOWER cpupower)
    endif()
endfunction()


function(c4_add_benchmark_cmd prefix casename)
    _c4_handle_prefix(${prefix})
    add_custom_target(${casename}
        COMMAND ${ARGN}
        VERBATIM
        COMMENT "${prefix}: running benchmark ${casename}: ${ARGN}")
    add_dependencies(${lprefix}benchmark ${casename})
    _c4_set_target_folder(${casename} ${lprefix}bm)
endfunction()


# assumes this is a googlebenchmark target, and that multiple
# benchmarks are defined from it
function(c4_add_target_benchmark prefix target casename)
    set(opt0arg
    )
    set(opt1arg
        WORKDIR # working directory
        FILTER  # benchmark patterns to filter
    )
    set(optnarg
        ARGS
    )
    cmake_parse_arguments("" "${opt0arg}" "${opt1arg}" "${optnarg}" ${ARGN})
    set(name "${target}-${casename}")
    set(rdir "${CMAKE_CURRENT_BINARY_DIR}/bm-results")
    set(rfile "${rdir}/${name}.json")
    if(NOT EXISTS "${rdir}")
        file(MAKE_DIRECTORY "${rdir}")
    endif()
    set(filter)
    if(NOT ("${_FILTER}" STREQUAL ""))
        set(filter "--benchmark_filter=${_FILTER}")
    endif()
    set(args_fwd ${filter} --benchmark_out_format=json --benchmark_out=${rfile} ${_ARGS})
    c4_add_benchmark(${prefix} ${target}
        "${name}"
        "${_WORKDIR}"
        "saving results in ${rfile}"
        ${args_fwd})
endfunction()


function(c4_add_benchmark prefix target casename work_dir comment)
    _c4_handle_prefix(${prefix})
    if(NOT TARGET ${target})
        message(FATAL_ERROR "target ${target} does not exist...")
    endif()
    if(NOT ("${work_dir}" STREQUAL ""))
        if(NOT EXISTS "${work_dir}")
            file(MAKE_DIRECTORY "${work_dir}")
        endif()
    endif()
    set(exe $<TARGET_FILE:${target}>)
    if(${uprefix}BENCHMARK_CPUPOWER)
        if(C4_BM_SUDO AND C4_BM_CPUPOWER)
            set(c ${C4_SUDO} ${C4_CPUPOWER} frequency-set --governor performance)
            set(cpupow_before
                COMMAND echo ${c}
                COMMAND ${c})
            set(c ${C4_SUDO} ${C4_CPUPOWER} frequency-set --governor powersave)
            set(cpupow_after
                COMMAND echo ${c}
                COMMAND ${c})
        endif()
    endif()
    add_custom_target(${casename}
        ${cpupow_before}
        # this is useful to show the target file (you cannot echo generator variables)
        #COMMAND ${CMAKE_COMMAND} -E echo "target file = $<TARGET_FILE:${target}>"
        COMMAND ${CMAKE_COMMAND} -E echo "${exe} ${ARGN}"
        COMMAND "${exe}" ${ARGN}
        ${cpupow_after}
        VERBATIM
        WORKING_DIRECTORY "${work_dir}"
        DEPENDS ${target}
        COMMENT "${lcprefix}: running benchmark ${target}, case ${casename}: ${comment}"
        )
    add_dependencies(${lprefix}bm-build ${target})
    add_dependencies(${lprefix}bm ${casename})
    _c4_set_target_folder(${casename} ${lprefix}bm)
endfunction()



#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#

#
# https://steveire.wordpress.com/2016/08/09/opt-in-header-only-libraries-with-cmake/
#
# Transform types:
#   * NONE
#   * UNITY
#   * UNITY_HDR
#   * SINGLE_HDR
#   * SINGLE_UNIT
function(c4_add_target_sources prefix target)
    _c4_handle_prefix(${prefix})
    set(options0arg
    )
    set(options1arg
        TRANSFORM
    )
    set(optionsnarg
        PUBLIC
        INTERFACE
        PRIVATE
    )
    cmake_parse_arguments("" "${options0arg}" "${options1arg}" "${optionsnarg}" ${ARGN})
    if(("${_TRANSFORM}" STREQUAL "GLOBAL") OR ("${_TRANSFORM}" STREQUAL ""))
        set(_TRANSFORM ${C4_SOURCE_TRANSFORM})
    endif()
    if("${_TRANSFORM}" STREQUAL "")
        set(_TRANSFORM NONE)
    endif()
    #
    # is this target an interface?
    set(_is_iface FALSE)
    get_target_property(target_type ${target} TYPE)
    if("${target_type}" STREQUAL "INTERFACE_LIBRARY")
        set(_is_iface TRUE)
    elseif("${prop_name}" STREQUAL "LINK_LIBRARIES")
        set(_is_iface FALSE)
    endif()
    #
    set(out)
    set(umbrella ${lprefix}transform-src)
    #
    if("${_TRANSFORM}" STREQUAL "NONE")
        _c4_log("${lcprefix}: target=${target} source transform: NONE!")
        #
        # do not transform the sources
        #
        if(_PUBLIC)
            _c4_log("${lcprefix}: target=${target} PUBLIC sources: ${_PUBLIC}")
            target_sources(${target} PUBLIC ${_PUBLIC})
        endif()
        if(_INTERFACE)
            _c4_log("${lcprefix}: target=${target} INTERFACE sources: ${_INTERFACE}")
            target_sources(${target} INTERFACE ${_INTERFACE})
        endif()
        if(_PRIVATE)
            _c4_log("${lcprefix}: target=${target} PRIVATE sources: ${_PRIVATE}")
            target_sources(${target} PRIVATE ${_PRIVATE})
        endif()
        #
    elseif("${_TRANSFORM}" STREQUAL "UNITY")
        _c4_log("${lcprefix}: source transform: UNITY!")
        message(FATAL_ERROR "source transformation not implemented")
        #
        # concatenate all compilation unit files (excluding interface)
        # into a single compilation unit
        #
        _c4cat_filter_srcs("${_PUBLIC}"    cpublic)
        _c4cat_filter_hdrs("${_PUBLIC}"    hpublic)
        _c4cat_filter_srcs("${_INTERFACE}" cinterface)
        _c4cat_filter_hdrs("${_INTERFACE}" hinterface)
        _c4cat_filter_srcs("${_PRIVATE}"   cprivate)
        _c4cat_filter_hdrs("${_PRIVATE}"   hprivate)
        if(cpublic OR cinterface OR cprivate)
            _c4cat_get_outname(${prefix} ${target} "src" ${C4_GEN_SRC_EXT} out)
            _c4_log("${lcprefix}: ${target}: output unit: ${out}")
            c4_cat_sources(${prefix} "${cpublic};${cinterface};${cprivate}" "${out}" ${umbrella})
            add_dependencies(${target} ${out})
        endif()
        if(_PUBLIC)
            target_sources(${target} PUBLIC
                $<BUILD_INTERFACE:${hpublic};${out}>
                $<INSTALL_INTERFACE:${hpublic};${out}>)
        endif()
        if(_INTERFACE)
            target_sources(${target} INTERFACE
                $<BUILD_INTERFACE:${hinterface}>
                $<INSTALL_INTERFACE:${hinterface}>)
        endif()
        if(_PRIVATE)
            target_sources(${target} PRIVATE
                $<BUILD_INTERFACE:${hprivate}>
                $<INSTALL_INTERFACE:${hprivate}>)
        endif()
        #
    elseif("${_TRANSFORM}" STREQUAL "UNITY_HDR")
        _c4_log("${lcprefix}: source transform: UNITY_HDR!")
        message(FATAL_ERROR "source transformation not implemented")
        #
        # like unity, but concatenate compilation units into
        # a header file, leaving other header files untouched
        #
        _c4cat_filter_srcs("${_PUBLIC}"    cpublic)
        _c4cat_filter_hdrs("${_PUBLIC}"    hpublic)
        _c4cat_filter_srcs("${_INTERFACE}" cinterface)
        _c4cat_filter_hdrs("${_INTERFACE}" hinterface)
        _c4cat_filter_srcs("${_PRIVATE}"   cprivate)
        _c4cat_filter_hdrs("${_PRIVATE}"   hprivate)
        if(c)
            _c4cat_get_outname(${prefix} ${target} "src" ${C4_GEN_HDR_EXT} out)
            _c4_log("${lcprefix}: ${target}: output hdr: ${out}")
            _c4cat_filter_srcs_hdrs("${_PUBLIC}" c_h)
            c4_cat_sources(${prefix} "${c}" "${out}" ${umbrella})
            add_dependencies(${target} ${out})
            add_dependencies(${target} ${lprefix}cat)
        endif()
        set(${src} ${out} PARENT_SCOPE)
        set(${hdr} ${h} PARENT_SCOPE)
        #
    elseif("${_TRANSFORM}" STREQUAL "SINGLE_HDR")
        _c4_log("${lcprefix}: source transform: SINGLE_HDR!")
        message(FATAL_ERROR "source transformation not implemented")
        #
        # concatenate everything into a single header file
        #
        _c4cat_get_outname(${prefix} ${target} "all" ${C4_GEN_HDR_EXT} out)
        _c4cat_filter_srcs_hdrs("${_c4al_SOURCES}" ch)
        c4_cat_sources(${prefix} "${ch}" "${out}" ${umbrella})
        #
    elseif("${_TRANSFORM}" STREQUAL "SINGLE_UNIT")
        _c4_log("${lcprefix}: source transform: SINGLE_HDR!")
        message(FATAL_ERROR "source transformation not implemented")
        #
        # concatenate:
        #  * all compilation unit into a single compilation unit
        #  * all headers into a single header
        #
        _c4cat_get_outname(${prefix} ${target} "src" ${C4_GEN_SRC_EXT} out)
        _c4cat_get_outname(${prefix} ${target} "hdr" ${C4_GEN_SRC_EXT} out)
        _c4cat_filter_srcs_hdrs("${_c4al_SOURCES}" ch)
        c4_cat_sources(${prefix} "${ch}" "${out}" ${umbrella})
    else()
        message(FATAL_ERROR "unknown transform type: ${transform_type}. Must be one of GLOBAL;NONE;UNITY;TO_HEADERS;SINGLE_HEADER")
    endif()
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

function(_c4cat_get_outname prefix target id ext out)
    _c4_handle_prefix(${prefix})
    if("${lcprefix}" STREQUAL "${target}")
        set(p "${target}")
    else()
        set(p "${lcprefix}.${target}")
    endif()
    set(${out} "${CMAKE_CURRENT_BINARY_DIR}/${p}.${id}.${ext}" PARENT_SCOPE)
endfunction()

function(_c4cat_filter_srcs in out)
    _c4cat_filter_extensions("${in}" "${C4_SRC_EXTS}" l)
    set(${out} ${l} PARENT_SCOPE)
endfunction()

function(_c4cat_filter_hdrs in out)
    _c4cat_filter_extensions("${in}" "${C4_HDR_EXTS}" l)
    set(${out} ${l} PARENT_SCOPE)
endfunction()

function(_c4cat_filter_srcs_hdrs in out)
    _c4cat_filter_extensions("${in}" "${C4_HDR_EXTS};${C4_SRC_EXTS}" l)
    set(${out} ${l} PARENT_SCOPE)
endfunction()

function(_c4cat_filter_extensions in filter out)
    set(l)
    foreach(fn ${in})  # don't quote the list here
        _c4cat_get_file_ext("${fn}" ext)
        _c4cat_one_of("${ext}" "${filter}" yes)
        if(${yes})
            list(APPEND l "${fn}")
        endif()
    endforeach()
    set(${out} "${l}" PARENT_SCOPE)
endfunction()

function(_c4cat_get_file_ext in out)
    # https://stackoverflow.com/questions/30049180/strip-filename-shortest-extension-by-cmake-get-filename-removing-the-last-ext
    string(REGEX MATCH "^.*\\.([^.]*)$" dummy ${in})
    set(${out} ${CMAKE_MATCH_1} PARENT_SCOPE)
endfunction()

function(_c4cat_one_of ext candidates out)
    foreach(e ${candidates})
        if(ext STREQUAL ${e})
            set(${out} YES PARENT_SCOPE)
            return()
        endif()
    endforeach()
    set(${out} NO PARENT_SCOPE)
endfunction()


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# given a list of source files, return a list with full paths
function(c4_to_full_path source_list source_list_with_full_paths)
    set(l)
    foreach(f ${source_list})
        if(IS_ABSOLUTE "${f}")
            list(APPEND l "${f}")
        else()
            list(APPEND l "${CMAKE_CURRENT_SOURCE_DIR}/${f}")
        endif()
    endforeach()
    set(${source_list_with_full_paths} ${l} PARENT_SCOPE)
endfunction()


# convert a list to a string separated with spaces
function(c4_separate_list input_list output_string)
    set(s)
    foreach(e ${input_list})
        set(s "${s} ${e}")
    endforeach()
    set(${output_string} ${s} PARENT_SCOPE)
endfunction()



#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
endif(NOT _c4_project_included)
