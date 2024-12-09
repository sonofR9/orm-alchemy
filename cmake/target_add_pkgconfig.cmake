find_package(PkgConfig REQUIRED)

function(target_pkgconfig_modules)
	if(${ARGC} LESS 1)
		message(FATAL_ERROR "target_pkgconfig_modules: no target given")
	elseif(${ARGC} LESS 2)
		message(FATAL_ERROR "target_pkgconfig_modules: no pkgconfig module given")
	endif()

	set(targetName ${ARGV0})

	set(noValues "")
	set(singleValues "")
	set(multiValues PRIVATE PUBLIC INTERFACE)

	cmake_parse_arguments(
		PARSE_ARGV 1
		ARG
		"${noValues}" "${singleValues}" "${multiValues}"
	)

	foreach(arg IN LISTS ARG_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "target_pkgconfig_modules: ${arg} doesn't have a visibility specifier")
	endforeach()

	foreach(arg IN LISTS multiValues)
		if(NOT ARG_${arg})
			continue()
		endif()

		pkg_check_modules(${targetName}_PKG_CONFIG REQUIRED ${ARG_${arg}})

		target_include_directories(${targetName} ${arg} ${${targetName}_PKG_CONFIG_INCLUDE_DIRS})
    	target_link_directories   (${targetName} ${arg} ${${targetName}_PKG_CONFIG_LIBRARY_DIRS})
    	target_compile_options    (${targetName} ${arg} ${${targetName}_PKG_CONFIG_CFLAGS})
    	target_link_options       (${targetName} ${arg} ${${targetName}_PKG_CONFIG_LDFLAGS})
		message("${${targetName}_PKG_CONFIG_LDFLAGS}")
    	target_link_libraries     (${targetName} ${arg} ${${targetName}_PKG_CONFIG_LIBRARIES})
	endforeach()
endfunction()
