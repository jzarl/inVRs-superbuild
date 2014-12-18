cmake_minimum_required( VERSION 3.1 FATAL_ERROR )
project( GLEW )

############################################################
set( GLEW_MAJOR_VERSION 1 )
set( GLEW_MINOR_VERSION 11 )
set( GLEW_PATCH_VERSION 0 )
set( GLEW_VERSION "${GLEW_MAJOR_VERSION}.${GLEW_MINOR_VERSION}.${GLEW_PATCH_VERSION}" )

############################################################

find_package( OpenGL REQUIRED )
# FindOpenSG.cmake does not honor "REQUIRED", yet:
if( NOT OPENGL_FOUND )
	message( ERROR "Could not find OpenGL." )
endif()
include_directories( ${OPENGL_INCLUDE_DIR} )

option( GLEW_USE_GLU "Build against GLU" OFF)
if( GLEW_USE_GLU )
	include( FindPkgConfig )
	# find GLU using pkg-config:
	pkg_check_modules( GLU REQUIRED glu )
	include_directories( ${GLU_INCLUDE_DIRS} )
else()
	add_definitions( -DGLEW_NO_GLU )
endif()

if( WIN32 )
	if( MSVC )
		set( CMAKE_DEBUG_POSTFIX "d" )
	endif()
endif()

set( GLEW_HEADERS
	include/GL/glew.h
	include/GL/wglew.h
)
if( NOT WIN32 )
	list( APPEND GLEW_HEADERS include/GL/glxew.h )
endif()

include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include )

set( GLEW_SOURCES src/glew.c ${GLEW_HEADERS} )

add_library( glew SHARED ${GLEW_SOURCES} )
if( WIN32 )
	# copied from OSGSupport:
	target_compile_definitions( glew PRIVATE _WINDLL )
endif()
target_compile_definitions( glew PRIVATE GLEW_BUILD )
target_link_libraries( glew PUBLIC ${OPENGL_gl_LIBRARY} )

add_library( glewstatic STATIC ${GLEW_SOURCES} )
target_compile_definitions( glewstatic PRIVATE GLEW_STATIC GLEW_BUILD )
target_link_libraries( glewstatic PUBLIC ${OPENGL_gl_LIBRARY} )

add_library( glewmx SHARED ${GLEW_SOURCES} )
target_compile_definitions( glewmx PUBLIC GLEW_MX PRIVATE GLEW_BUILD)
target_link_libraries( glewmx PUBLIC ${OPENGL_gl_LIBRARY} )

add_library( glewmxstatic STATIC ${GLEW_SOURCES} )
target_compile_definitions( glewmxstatic PUBLIC GLEW_MX PRIVATE GLEW_STATIC GLEW_BUILD )
target_link_libraries( glewmxstatic PUBLIC ${OPENGL_gl_LIBRARY} )

if( GLEW_USE_GLU )
	target_link_libraries( glew ${GLU_LIBRARIES} )
	target_link_libraries( glewstatic ${GLU_STATIC_LIBRARIES} )
	target_link_libraries( glewmx ${GLU_LIBRARIES} )
	target_link_libraries( glewmxstatic ${GLU_STATIC_LIBRARIES} )
endif()

set( GLEWINFO_SOURCES src/glewinfo.c )
set( VISUALINFO_SOURCES src/visualinfo.c )

add_executable( glewinfo ${GLEWINFO_SOURCES} )
target_link_libraries( glewinfo glew )

add_executable( visualinfo ${VISUALINFO_SOURCES} )
target_link_libraries( visualinfo glew )

############################################################
# install library and tools

install(
	TARGETS
		glew glewstatic glewmx glewmxstatic
	EXPORT GLEWTargets
	RUNTIME DESTINATION lib
	LIBRARY DESTINATION lib
	ARCHIVE DESTINATION lib
	INCLUDES DESTINATION include/GL
	)
if( WIN32 )
	# install the dll alongside the executables
	set( GLEW_dll glew )
endif()
install(
	TARGETS
		glewinfo visualinfo ${GLEW_dll}
	RUNTIME DESTINATION bin
	)
install(
	FILES ${GLEW_HEADERS}
	DESTINATION include/GL
	)

############################################################
# pkg-config (Unix only)
if( NOT WIN32)
	# set the variables for the .pc file:
	function( create_pkgconfig libname )
		set( infile "${CMAKE_CURRENT_SOURCE_DIR}/glew.pc.in" )
		set( outfile "${CMAKE_CURRENT_BINARY_DIR}/${libname}.pc" )
		set( prefix "${CMAKE_INSTALL_PREFIX}" )
		set( version "${GLEW_VERSION}" )

		get_target_property( cflags_defs_raw ${libname} INTERFACE_COMPILE_DEFINITIONS )
		# prepend preprocessor-symbols with "-D":
		foreach( flag IN LISTS cflags_defs)
			set( cflags "${cflags} -D${flag}" )
		endforeach()

		set( requireslib gl )
		if( GLEW_USE_GLU )
			set( requireslib "${requireslib} glu")
		endif()

		configure_file( "${infile}" "${outfile}" @ONLY )
		install( FILES "${outfile}" DESTINATION lib/pkgconfig )
	endfunction()

	create_pkgconfig( glew )
	create_pkgconfig( glewmx )
endif()

############################################################
# GLEWConfig.cmake

include( CMakePackageConfigHelpers )
write_basic_package_version_file(
	"${CMAKE_CURRENT_BINARY_DIR}/GLEWConfigVersion.cmake"
	VERSION ${GLEW_VERSION}
	COMPATIBILITY AnyNewerVersion
	)

export(
	EXPORT GLEWTargets
	FILE "${CMAKE_CURRENT_BINARY_DIR}/GLEWTargets.cmake"
	NAMESPACE GLEW::
	)

configure_file( GLEWConfig.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/GLEWConfig.cmake" COPYONLY )

install(
	EXPORT GLEWTargets
	NAMESPACE GLEW::
	DESTINATION lib/cmake/GLEW
	)
install(
	FILES
		"${CMAKE_CURRENT_BINARY_DIR}/GLEWConfig.cmake"
		"${CMAKE_CURRENT_BINARY_DIR}/GLEWConfigVersion.cmake"
	DESTINATION lib/cmake/GLEW
	)