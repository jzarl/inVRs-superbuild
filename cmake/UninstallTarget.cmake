##module
## Automates the creation of an uninstall target.
## The following functions are provided:
##  - create_default_uninstall_target()
##    Create a default uninstall target for the current project.
##  - create_uninstall_target( <NAME> )
##    Create an uninstall target for a custom install manifest file.
##    The custom install manifest is assumed to be called "${PROJECT_BINARY_DIR}/cmake_uninstall_<NAME>.txt".
##end

if ( NOT TARGET uninstall )
	add_custom_target( uninstall )
	# make sure that we know the location of the prototype file:
	set_target_properties( uninstall PROPERTIES UT_PROTO_FILE "${CMAKE_CURRENT_LIST_DIR}/cmake_uninstall.cmake.in" )
endif()

function( create_default_uninstall_target )
	if( NOT "${ARG1}" STREQUAL "QUIET" )
		message( STATUS "Creating uninstall target for project ${PROJECT_NAME}." )
	endif()

	get_target_property( PROTO_FILE uninstall UT_PROTO_FILE )

	configure_file(
		"${PROTO_FILE}"
		"${PROJECT_BINARY_DIR}/cmake_uninstall.cmake"
		IMMEDIATE @ONLY)

	add_custom_target(uninstall_default
		COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/cmake_uninstall.cmake)
	add_dependencies( uninstall uninstall_default )
endfunction()

function( create_uninstall_target name )
	if( NOT "${ARGN}" MATCHES "QUIET" )
		message( STATUS "Creating uninstall target ${PROJECT_NAME}/${name}." )
	endif()
	
	get_target_property( PROTO_FILE uninstall UT_PROTO_FILE )
	set( MANIFEST_SUFFIX "_${name}" )

	configure_file(
		"${PROTO_FILE}"
		"${PROJECT_BINARY_DIR}/cmake_uninstall${MANIFEST_SUFFIX}.cmake"
		IMMEDIATE @ONLY)

	add_custom_target(uninstall_${name}
		COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/cmake_uninstall${MANIFEST_SUFFIX}.cmake)
	add_dependencies( uninstall uninstall_${name} )
endfunction()

