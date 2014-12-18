cmake_minimum_required( VERSION 3.0 FATAL_ERROR )
project( GLEW )

############################################################
set( GLEW_MAJOR_VERSION 1 )
set( GLEW_MINOR_VERSION 11 )
set( GLEW_PATCH_VERSION 0 )
set( GLEW_VERSION "${GLEW_MAJOR_VERSION}.${GLEW_MINOR_VERSION}.${GLEW_PATCH_VERSION}" )

set( GLEW_HEADERS
	include/GL/glew.h
	include/GL/wglew.h
)
set( GLEW_SOURCES src/glew.c ${GLEW_HEADERS} )

set( GLEWINFO_SOURCES src/glewinfo.c )
set( VISUALINFO_SOURCES src/visualinfo.c )

############################################################
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include )

if( WIN32 )
	if( MSVC )
		set( CMAKE_DEBUG_POSTFIX "d" )
	endif()
	function(fix_archive_name target name)
	endfunction()
else()
	# used to have "libGLEW.a" instead of "libGLEWstatic.a" on Unix:
	function(fix_archive_name target name)
		set_property( TARGET ${target} PROPERTY ARCHIVE_OUTPUT_NAME ${name} )
	endfunction()
endif()

############################################################
### Find dependencies and make interface libraries for them

find_package( OpenGL REQUIRED )
# FindOpenGL.cmake does not honor "REQUIRED", yet:
if( NOT OPENGL_FOUND )
	message( ERROR "Could not find OpenGL." )
endif()
# if you make changes on the imported target, make sure to also change it in GlewConfig.cmake.in:
add_library( GLEW-gl INTERFACE IMPORTED)
set_property( TARGET GLEW-gl PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${OPENGL_INCLUDE_DIR} )
set_property( TARGET GLEW-gl PROPERTY INTERFACE_LINK_LIBRARIES ${OPENGL_gl_LIBRARY} )
# pkg-config:
set( GLEW_REQUIRES "${GLEW_REQUIRES} gl" )

option( GLEW_USE_GLU "Build against GLU" ON)
add_library( GLEW-glu INTERFACE IMPORTED)
add_library( GLEW-glustatic INTERFACE IMPORTED)
if( GLEW_USE_GLU )
	message( STATUS "Building with support for GLU." )
	include( FindPkgConfig )

	# find GLU using pkg-config:
	pkg_check_modules( GLU REQUIRED glu )

	# if you make changes on the imported target, make sure to also change it in GlewConfig.cmake.in:
	set_property( TARGET GLEW-glu GLEW-glustatic PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${GLU_INCLUDE_DIRS} )
	set_property( TARGET GLEW-glu PROPERTY INTERFACE_LINK_LIBRARIES ${GLU_LIBRARIES} )
	set_property( TARGET GLEW-glustatic PROPERTY INTERFACE_LINK_LIBRARIES ${GLU_LIBRARIES_STATIC} )

	# pkg-config:
	set( GLEW_REQUIRES "${GLEW_REQUIRES} glu" )
else()
	set_property( TARGET GLEW-glu GLEW-glustatic PROPERTY INTERFACE_COMPILE_DEFINITIONS GLEW_NO_GLU)
endif()

if( NOT WIN32 )
	message( STATUS "Building with support for X11." )
	# if you make changes on the imported target, make sure to also change it in GlewConfig.cmake.in:
	find_package( X11 REQUIRED )
	add_library( GLEW-x11 INTERFACE IMPORTED)
	set_property( TARGET GLEW-x11 PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${X11_INCLUDE_DIR} )
	set_property( TARGET GLEW-x11 PROPERTY INTERFACE_LINK_LIBRARIES ${X11_LIBRARIES} )
	set( X11-target GLEW-x11 )

	# pkg-config:
	set( GLEW_REQUIRES "${GLEW_REQUIRES} x11" )

	list( APPEND GLEW_HEADERS include/GL/glxew.h )
endif()


############################################################
### Define GLEW targets

add_library( GLEW SHARED ${GLEW_SOURCES} )
if( WIN32 )
	# copied from OSGSupport:
	target_compile_definitions( GLEW PRIVATE _WINDLL )
endif()
target_compile_definitions( GLEW PRIVATE GLEW_BUILD )
target_link_libraries( GLEW PUBLIC GLEW-gl GLEW-glu ${X11-target} )

add_library( GLEWstatic STATIC ${GLEW_SOURCES} )
fix_archive_name( GLEWstatic GLEW )
target_compile_definitions( GLEWstatic PRIVATE GLEW_STATIC GLEW_BUILD )
target_link_libraries( GLEWstatic PUBLIC GLEW-gl GLEW-glustatic ${X11-target} )

add_library( GLEWmx SHARED ${GLEW_SOURCES} )
target_compile_definitions( GLEWmx PUBLIC GLEW_MX PRIVATE GLEW_BUILD)
target_link_libraries( GLEWmx PUBLIC GLEW-gl GLEW-glu ${X11-target} )

add_library( GLEWmxstatic STATIC ${GLEW_SOURCES} )
fix_archive_name( GLEWmxstatic GLEWmx )
target_compile_definitions( GLEWmxstatic PUBLIC GLEW_MX PRIVATE GLEW_STATIC GLEW_BUILD )
target_link_libraries( GLEWmxstatic PUBLIC GLEW-gl GLEW-glustatic ${X11-target} )

add_executable( glewinfo ${GLEWINFO_SOURCES} )
target_link_libraries( glewinfo GLEW )

add_executable( visualinfo ${VISUALINFO_SOURCES} )
target_link_libraries( visualinfo GLEW )


############################################################
# Install library and tools

install(
	TARGETS
		GLEW GLEWstatic GLEWmx GLEWmxstatic
	EXPORT GLEWTargets
	RUNTIME DESTINATION lib
	LIBRARY DESTINATION lib
	ARCHIVE DESTINATION lib
	INCLUDES DESTINATION include/GL
	)
if( WIN32 )
	# install the dll alongside the executables
	set( GLEW_dll GLEW )
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

		set( requireslib ${GLEW_REQUIRES} )

		configure_file( "${infile}" "${outfile}" @ONLY )
		install( FILES "${outfile}" DESTINATION lib/pkgconfig )
	endfunction()

	create_pkgconfig( GLEW )
	create_pkgconfig( GLEWmx )
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

configure_file( GLEWConfig.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/GLEWConfig.cmake" @ONLY )

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
