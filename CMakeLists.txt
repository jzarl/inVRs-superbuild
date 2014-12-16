cmake_minimum_required( VERSION 3.1 FATAL_ERROR )
project( inVRs-SuperBuild )

############################################################
### Boilerplate code

list( APPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}" )

option( DISABLE_VCS_UPDATES "Do not try to update repositories under VCS (Use this if you don't have a network connection)" OFF )
if ( DISABLE_VCS_UPDATES )
	message( WARNING "Subversion and git repository updates are disabled!" )
	set( MAYBE_DISABLE_UPDATE_COMMAND UPDATE_COMMAND ${CMAKE_COMMAND} -E echo "NOT updating repository" )
endif()
set( DOWNLOAD_CACHE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/download" CACHE PATH "Cache directory for downloaded files." )
mark_as_advanced( DOWNLOAD_CACHE_DIRECTORY )
set( VCS_CACHE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/vcs" CACHE PATH "Cache directory for external source code under version control" )
mark_as_advanced( VCS_CACHE_DIRECTORY )

set( DEFAULT_CMAKE_ARGS
	"-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}"
	"-DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH}"
	)

if ( CMAKE_CONFIGURATION_TYPES )
	# multi-configuration generators
	#set( CMAKE_CONFIGURATION_TYPES Release Debug RelWithDebInfo )
else()
	# single-configuration generators
	set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Release Debug RelWithDebInfo )
	list( APPEND DEFAULT_CMAKE_ARGS	"-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}" )
endif()

# the default install prefix usually won't work on Linux because the external projects are installed during build time
# (and we don't want to build as root)
if( "${CMAKE_INSTALL_PREFIX}" STREQUAL "/usr/local" )
	message( WARNING "The install prefix ${CMAKE_INSTALL_PREFIX} is normally not writable." )
endif()

include( ExternalProject )
include( FindPkgConfig )
include( "${CMAKE_CURRENT_SOURCE_DIR}/repositories.cmake" )
include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HelperFunctions.cmake" )
include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/UninstallTarget.cmake" )

############################################################
### Boost
set( BOOST_REQUIRED_COMPONENTS system filesystem )
# try already installed version first:
conditional_find_package( Boost COMPONENTS ${BOOST_REQUIRED_COMPONENTS} )

list( APPEND OpenSG_DEPS Boost )

if( Boost_BUILD )
	message( STATUS "Building Boost from source..." )
	# set BOOST_ROOT, so that find_package finds this boost, later:
	set( BOOST_ROOT "${CMAKE_INSTALL_PREFIX}" )

	# windows-builds of boost need different compilation commands:
	if( WIN32 )
		# Windows boost does apperently not support out-of-tree builds:
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.bat )
		set( BOOST_B2_COMMAND <SOURCE_DIR>/b2.exe install "--build-dir=<SOURCE_DIR>" "--prefix=<INSTALL_DIR>" )
		set( BOOST_BUILD_IN_SOURCE BUILD_IN_SOURCE 1 )
	else()
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.sh "--prefix=<INSTALL_DIR>" )
		set( BOOST_B2_COMMAND <BINARY_DIR>/b2 install "--build-dir=<BINARY_DIR>" "--prefix=<INSTALL_DIR>" )
	endif()

	# assemble the complete b2 commandline:
	list( APPEND BOOST_B2_COMMAND "--layout=versioned" "--build-type=complete" )
	foreach( component IN LISTS BOOST_REQUIRED_COMPONENTS )
		list( APPEND BOOST_B2_COMMAND "--with-${component}" )
	endforeach()

	ExternalProject_Add(
		Boost
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/boost"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		${BOOST_BUILD_IN_SOURCE}
		${Boost_DOWNLOAD}
		UPDATE_COMMAND "${BOOST_BOOTSTRAP_COMMAND}"
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND "${BOOST_B2_COMMAND}"
		INSTALL_DIR "${BOOST_ROOT}"
		)
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( Boost )
	message( STATUS "Using already installed Boost." )
endif()

############################################################
### Qt - only a reminder:
find_package( Qt4 )
if ( NOT Qt4_FOUND )
	message( WARNING "Could not find Qt." )
	#message( STATUS "If you want to use Qt, get the installer from http://www.qt.io/download-open-source/" )
	#message( STATUS "If you already installed Qt, you should also set the environment variable CMAKE_PREFIX_PATH appropriately." )
else()
	message( STATUS "Qt4 found." )
endif()


############################################################
### FreeGLUT
# project FreeGLUT in OSGSupport is outdated, and FreeGLUT now supports cmake:
conditional_find_package( GLUT )
if( GLUT_BUILD )
	message( STATUS "Building GLUT from source." )
	set( FreeGLUT_DIR "${CMAKE_INSTALL_PREFIX}" )
	ExternalProject_Add(
		FreeGLUT
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/FreeGLUT"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		INSTALL_DIR "${FreeGLUT_DIR}"
		${FreeGLUT_DOWNLOAD}
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
			# .pdb files are not generated in MSVC 2013:
			"-DINSTALL_PDB:BOOL=OFF"
		)
	copy_install_manifest( FreeGLUT "${CMAKE_CURRENT_BINARY_DIR}/external/FreeGLUT/src/FreeGLUT-build/install_manifest.txt")
	list( APPEND OpenSG_DEPS FreeGLUT )
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( FreeGLUT )
	message( STATUS "Using already installed GLUT." )
endif()


############################################################
### ZLIB

conditional_find_package( ZLIB )
if( ZLIB_BUILD )
	message( STATUS "Building ZLIB from source." )
	set( ZLIB_DIR "${CMAKE_INSTALL_PREFIX}" )
	ExternalProject_Add(
		ZLIB
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/ZLIB"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		INSTALL_DIR "${ZLIB_DIR}"
		${ZLIB_DOWNLOAD}
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
		)
	list( APPEND OpenSG_DEPS ZLIB )
	copy_install_manifest( ZLIB "${CMAKE_CURRENT_BINARY_DIR}/external/ZLIB/src/ZLIB-build/install_manifest.txt")
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( ZLIB )
	message( STATUS "Using already installed ZLIB." )
endif()


############################################################
### PCRE
# project PCRE in OSGSupport is outdated, and FreeGLUT now supports cmake:

conditional_pkg_check_modules( PCRE libpcrecpp )
if( PCRE_BUILD )
	message( STATUS "Building PCRE from source." )
	set( PCRE_DIR "${CMAKE_INSTALL_PREFIX}" )
	ExternalProject_Add(
		PCRE
		DEPENDS ZLIB
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/PCRE"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		INSTALL_DIR "${PCRE_DIR}"
		${PCRE_DOWNLOAD}
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
			"-DPCRE_BUILD_PCRE16:BOOL=ON"
			"-DPCRE_BUILD_PCRE32:BOOL=ON"
			"-DPCRE_SUPPORT_JIT:BOOL=ON"
			"-DPCRE_SUPPORT_UTF:BOOL=ON"
		)
	list( APPEND OpenSG_DEPS PCRE )
	copy_install_manifest( PCRE "${CMAKE_CURRENT_BINARY_DIR}/external/PCRE/src/PCRE-build/install_manifest.txt")
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( PCRE )
	message( STATUS "Using already installed PCRE." )
endif()

############################################################
### PNG

conditional_find_package( PNG )
if( PNG_BUILD )
	message( STATUS "Building PNG from source." )
	set( PNG_DIR "${CMAKE_INSTALL_PREFIX}" )
	ExternalProject_Add(
		PNG
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/PNG"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		INSTALL_DIR "${PNG_DIR}"
		${PNG_DOWNLOAD}
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
		)
	list( APPEND OpenSG_DEPS PNG )
	copy_install_manifest( PNG "${CMAKE_CURRENT_BINARY_DIR}/external/PNG/src/PNG-build/install_manifest.txt" )
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( PNG )
	message( STATUS "Using already installed PNG." )
endif()


############################################################
### OpenSG Support libs
# Some libraries don't (yet) support CMake as build system.
# OpenSGSupport has build instructions for those libraries.
# In some cases, newer versions of a library support cmake;
# in these cases, we use the built-in build system instead.

# since these all follow the same pattern, define a function:
function( OSGSupport_Add_Download name varname )
	ExternalProject_Add( ${name}
		${${name}_DOWNLOAD}
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		UPDATE_COMMAND ""
		PATCH_COMMAND ""
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND ""
		TEST_COMMAND ""
	)

	list( APPEND OpenSGSupport_DEPS ${name} )
	list( APPEND OpenSGSupport_CMAKE_ARGS "-D${varname}:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/${name}" )
	# export variables:
	set( OpenSGSupport_DEPS "${OpenSGSupport_DEPS}" PARENT_SCOPE )
	set( OpenSGSupport_CMAKE_ARGS "${OpenSGSupport_CMAKE_ARGS}" PARENT_SCOPE )
endfunction()

# ColladaDOM supports CMake, but its dependency LibXML2 doesn't:
OSGSupport_Add_Download( ColladaDOM OSGColladaSrcDir )
#OSGSupport_Add_Download( FreeGLUT OSGFreeGlutSrcDir )
OSGSupport_Add_Download( GLEW OSGGLEWSrcDir )
OSGSupport_Add_Download( JPEG OSGJpegLibSrcDir )
OSGSupport_Add_Download( LibXML2 OSGLibXml2SrcDir )
#OSGSupport_Add_Download( PCRE OSGPcreSrcDir )
#OSGSupport_Add_Download( PNG OSGLibPNGSrcDir )
#OSGSupport_Add_Download( ZLIB OSGZLibSrcDir )

add_dependencies( ColladaDOM LibXML2 PCRE )

############################################################
### OpenSG
message( STATUS "Building OpenSG from source..." )

# set OpenSG_DIR, so that find_package finds it:
set( OpenSG_DIR "${CMAKE_INSTALL_PREFIX}" )

# Build options for OpenSG:
list( APPEND OpenSG_CMAKE_ARGS
	"-DOSG_USE_OSGSUPPORT_LIBS:BOOL=ON"
	"-DOSGCOMPAT_ENABLE:BOOL=ON" "-DOSGCOMPAT_ENABLE_DEPRECATED:BOOL=ON"
	"-DOSGBUILD_TESTS:BOOL=OFF"
	)

ExternalProject_Add(
	OpenSG
	DEPENDS ${OpenSG_DEPS}
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensg"
	SOURCE_DIR "${VCS_CACHE_DIRECTORY}/OpenSG"
	INSTALL_DIR "${OpenSG_DIR}"
	${OpenSG_DOWNLOAD}
	${MAYBE_DISABLE_UPDATE_COMMAND}
	CMAKE_ARGS
		"${DEFAULT_CMAKE_ARGS}"
		${OpenSG_CMAKE_ARGS}
	STEP_TARGETS patch configure
	)
copy_install_manifest( OpenSG "${CMAKE_CURRENT_BINARY_DIR}/external/opensg/src/OpenSG-build/install_manifest.txt")

ExternalProject_Add(
	OpenSGSupport
	DEPENDS OpenSG-patch ${OpenSGSupport_DEPS}
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport"
	DOWNLOAD_COMMAND ""
	INSTALL_DIR "${OpenSG_DIR}"
	SOURCE_DIR "${VCS_CACHE_DIRECTORY}/OpenSG/Support"
	CMAKE_ARGS
		"${DEFAULT_CMAKE_ARGS}"
		${OpenSGSupport_CMAKE_ARGS}
	)
copy_install_manifest( OpenSGSupport "${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/OpenSGSupport-build/install_manifest.txt" )

add_dependencies( OpenSG-configure OpenSGSupport )
# -> jpeg freetype

############################################################
### inVRs
ExternalProject_Add(
	inVRs
	DEPENDS OpenSG
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/inVRs"
	SOURCE_DIR "${VCS_CACHE_DIRECTORY}/inVRs"
	${inVRs_DOWNLOAD}
	${MAYBE_DISABLE_UPDATE_COMMAND}
	INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"
	CMAKE_ARGS "${DEFAULT_CMAKE_ARGS}" "-DBOOST_ROOT:PATH=${BOOST_ROOT}" "-DOpenSG_DIR:PATH=${OpenSG_DIR}"
	)
copy_install_manifest( inVRs "${CMAKE_CURRENT_BINARY_DIR}/inVRs-prefix/src/inVRs-build/install_manifest.txt")
