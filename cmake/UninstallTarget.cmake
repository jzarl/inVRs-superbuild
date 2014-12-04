##module
## Creates a standard uninstall target.
##
## Variables:
##  - UNINSTALL_TARGET_QUIET: Set this variable to prevent a message when the uninstall target is created.
##end
if( NOT UNINSTALL_TARGET_QUIET)
	message( STATUS "Creating uninstall target for project ${PROJECT_NAME}." )
endif()

configure_file(
	"${CMAKE_CURRENT_LIST_DIR}/cmake_uninstall.cmake.in"
	"${PROJECT_BINARY_DIR}/cmake_uninstall.cmake"
	IMMEDIATE @ONLY)

add_custom_target(uninstall
	COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
