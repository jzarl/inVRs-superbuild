cmake_minimum_required( VERSION 3.0 FATAL_ERROR )
project( inVRs-SuperBuild )

############################################################
### Boilerplate code

list( APPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}" )

option( SUPERBUILD_DISABLE_VCS_UPDATES "Do not try to update repositories under VCS (Use this if you don't have a network connection)" OFF )
if ( SUPERBUILD_DISABLE_VCS_UPDATES )
	message( WARNING "Subversion and git repository updates are disabled!" )
	set( MAYBE_DISABLE_UPDATE_COMMAND UPDATE_COMMAND ${CMAKE_COMMAND} -E echo "NOT updating repository" )
endif()
set( SUPERBUILD_ "${CMAKE_CURRENT_SOURCE_DIR}/download" CACHE PATH "Cache directory for downloaded files." )
mark_as_advanced( SUPERBUILD_ )
set( SUPERBUILD_VCS_CACHE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/vcs" CACHE PATH "Cache directory for external source code under version control" )
mark_as_advanced( SUPERBUILD_VCS_CACHE_DIRECTORY )

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
include( CMakeDependentOption )
include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HelperFunctions.cmake" )
include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/UninstallTarget.cmake" )

### Repository selection
file( GLOB REPOSITORY_COLLECTIONS
	LIST_DIRECTORIES false
	RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/repositories"
	"${CMAKE_CURRENT_SOURCE_DIR}/repositories/*.repositories.cmake" )
set( SUPERBUILD_REPOSITORY_COLLECTION "minimal.repositories.cmake" CACHE STRING "Configuration file for repositories." )
set_property(CACHE SUPERBUILD_REPOSITORY_COLLECTION PROPERTY STRINGS ${REPOSITORY_COLLECTIONS} )

message( STATUS "Available repository collections:" )
foreach( coll IN LISTS REPOSITORY_COLLECTIONS )
	message( STATUS " * ${coll}" )
endforeach()
message( STATUS "Using collection: ${SUPERBUILD_REPOSITORY_COLLECTION}" )

include( "${CMAKE_CURRENT_SOURCE_DIR}/repositories/${SUPERBUILD_REPOSITORY_COLLECTION}" )
############################################################
### Boost
set( BOOST_REQUIRED_COMPONENTS system filesystem )
# try already installed version first:
conditional_find_package( Boost COMPONENTS ${BOOST_REQUIRED_COMPONENTS} )

if( Boost_BUILD )
	message( STATUS "Building Boost from source..." )
	# set BOOST_ROOT, so that find_package finds this boost, later:
	set( BOOST_ROOT "${CMAKE_INSTALL_PREFIX}" )

	# windows-builds of boost need different compilation commands:
	if( WIN32 )
		# Windows boost does apperently not support out-of-tree builds:
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.bat )
		set( BOOST_B2_COMMAND <SOURCE_DIR>/b2.exe install "--build-dir=<SOURCE_DIR>" "--prefix=<INSTALL_DIR>" )
	else()
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.sh "--prefix=<INSTALL_DIR>" )
		set( BOOST_B2_COMMAND <SOURCE_DIR>/b2 install "--build-dir=<SOURCE_DIR>" "--prefix=<INSTALL_DIR>" )
	endif()

	# assemble the complete b2 commandline:
	list( APPEND BOOST_B2_COMMAND "--layout=versioned" "--build-type=complete" )
	foreach( component IN LISTS BOOST_REQUIRED_COMPONENTS )
		list( APPEND BOOST_B2_COMMAND "--with-${component}" )
	endforeach()

	ExternalProject_Add(
		Boost
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/boost"
		DOWNLOAD_DIR "${SUPERBUILD_}"
		BUILD_IN_SOURCE 1
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

# this can be overridden in repositories/*
option( SUPERBUILD_ENABLE_QT "Build with Qt." ON)
if( SUPERBUILD_ENABLE_QT )
	if( WIN32 )
		# The Qt installer for windows uses the following scheme for the install path:
		# INSTALL_LOCATION/QT_VERSION/PLATFORM
		# e.g.:
		# INSTALL_LOCATION = C:\Qt
		# QT_VERSION = 5.4
		# PLATFORM = msvc2013_64
		# -> C:\Qt\5.4\msvc2013_64

		## get Qt install location:
		get_filename_component( QT_INSTALL_LOCATION  "[HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Qt;InstallLocation]" ABSOLUTE CACHE )
		message( STATUS "Qt install path from registry: ${QT_INSTALL_LOCATION}")

		## identify Qt installed versions
		file( GLOB QT_VERSIONS ${QT_INSTALL_LOCATION}/[4-5].[0-9] )
		list( SORT QT_VERSIONS )
		list( REVERSE QT_VERSIONS )
		message( STATUS "Identified potential Qt versions: ${QT_VERSIONS}" )

		## try to guess the correct platform identifier
		# if you are not using MSVC, you will definitely have to adjust this
		if( MSVC )
			if( CMAKE_CL_64 )
				set( _COMPILER_BITS _64 )
			else()
				set( _COMPILER_BITS )
			endif()
		endif()
		if( MSVC12 )
			# msvc2013 also identifies as MSVC12
			set( QT_POTENTIAL_PLATFORMS
				msvc2013${_COMPILER_BITS}_opengl msvc2013${_COMPILER_BITS}
				msvc2012${_COMPILER_BITS}_opengl msvc2012${_COMPILER_BITS}
				)
		elseif( MSVC14 )
			set( QT_POTENTIAL_PLATFORMS msvc2014${_COMPILER_BITS}_opengl msvc2014${_COMPILER_BITS} )
		endif()
		message( STATUS "Checking the following Qt platforms: ${QT_POTENTIAL_PLATFORMS}" )

		# pick a path from the available ones:
		find_path( QT_DIR
			NAMES bin
			PATHS ${QT_VERSIONS}
			PATH_SUFFIXES ${QT_POTENTIAL_PLATFORMS}
			DOC "Qt install directory for the current toolchain."
			NO_DEFAULT_PATH
			)
		message( STATUS "Identified potential Qt candidate directory: ${QT_DIR}" )
		list( APPEND CMAKE_PREFIX_PATH "${QT_DIR}" )
	endif()

	find_package( Qt4 )
	if ( NOT Qt4_FOUND )
		message( WARNING "Could not find Qt." )
		#message( STATUS "If you want to use Qt, get the installer from http://www.qt.io/download-open-source/" )
		#message( STATUS "If you already installed Qt, you should also set the environment variable CMAKE_PREFIX_PATH appropriately." )
	else()
		message( STATUS "Qt4 found." )
		list( APPEND OpenSG_OPTIONAL_DEPENDENCIES Qt4 )
	endif()

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
		DOWNLOAD_DIR "${SUPERBUILD_}"
		INSTALL_DIR "${FreeGLUT_DIR}"
		${FreeGLUT_DOWNLOAD}
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
			# .pdb files are not generated in MSVC 2013:
			"-DINSTALL_PDB:BOOL=OFF"
		)
	copy_install_manifest( FreeGLUT "${CMAKE_CURRENT_BINARY_DIR}/external/FreeGLUT/src/FreeGLUT-build/install_manifest.txt")
	list( APPEND OpenSG_OPTIONAL_DEPENDENCIES FreeGLUT )
else()
	message( STATUS "Using already installed GLUT." )
endif()


############################################################
### ZLIB

# this can be overridden in repositories/*
option( SUPERBUILD_ENABLE_ZLIB "Build with ZLIB (required for PCRE, PNG)." ON)
if( SUPERBUILD_ENABLE_ZLIB )
	conditional_find_package( ZLIB )
	if( ZLIB_BUILD )
		message( STATUS "Building ZLIB from source." )
		set( ZLIB_DIR "${CMAKE_INSTALL_PREFIX}" )
		ExternalProject_Add(
			ZLIB
			PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/ZLIB"
			DOWNLOAD_DIR "${SUPERBUILD_}"
			INSTALL_DIR "${ZLIB_DIR}"
			${ZLIB_DOWNLOAD}
			CMAKE_ARGS
				"${DEFAULT_CMAKE_ARGS}"
			)
		copy_install_manifest( ZLIB "${CMAKE_CURRENT_BINARY_DIR}/external/ZLIB/src/ZLIB-build/install_manifest.txt")
		list( APPEND OpenSG_OPTIONAL_DEPENDENCIES ZLIB )
	else()
		message( STATUS "Using already installed ZLIB." )
	endif()
endif()


############################################################
### PCRE
# project PCRE in OSGSupport is outdated, and PCRE now supports cmake:

# this can be overridden in repositories/*
cmake_dependent_option(
	SUPERBUILD_ENABLE_PCRE "Build with PCRE." ON
	"SUPERBUILD_ENABLE_ZLIB" OFF )
if( SUPERBUILD_ENABLE_PCRE )
	conditional_pkg_check_modules( PCRE libpcrecpp )
	if( PCRE_BUILD )
		message( STATUS "Building PCRE from source." )
		set( PCRE_DIR "${CMAKE_INSTALL_PREFIX}" )
		ExternalProject_Add(
			PCRE
			DEPENDS ZLIB
			PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/PCRE"
			DOWNLOAD_DIR "${SUPERBUILD_}"
			INSTALL_DIR "${PCRE_DIR}"
			${PCRE_DOWNLOAD}
			CMAKE_ARGS
				"${DEFAULT_CMAKE_ARGS}"
				"-DPCRE_BUILD_PCRE16:BOOL=ON"
				"-DPCRE_BUILD_PCRE32:BOOL=ON"
				"-DPCRE_SUPPORT_JIT:BOOL=ON"
				"-DPCRE_SUPPORT_UTF:BOOL=ON"
			)
		copy_install_manifest( PCRE "${CMAKE_CURRENT_BINARY_DIR}/external/PCRE/src/PCRE-build/install_manifest.txt")
	else()
		message( STATUS "Using already installed PCRE." )
	endif()
endif()

############################################################
### PNG

# this can be overridden in repositories/*
cmake_dependent_option(
	SUPERBUILD_ENABLE_PNG "Build with PNG." ON
	"SUPERBUILD_ENABLE_ZLIB" OFF )
if( SUPERBUILD_ENABLE_PNG )
	conditional_find_package( PNG )
	if( PNG_BUILD )
		message( STATUS "Building PNG from source." )
		set( PNG_DIR "${CMAKE_INSTALL_PREFIX}" )
		ExternalProject_Add(
			PNG
			DEPENDS ZLIB
			PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/PNG"
			DOWNLOAD_DIR "${SUPERBUILD_}"
			INSTALL_DIR "${PNG_DIR}"
			${PNG_DOWNLOAD}
			CMAKE_ARGS
				"${DEFAULT_CMAKE_ARGS}"
			)
		copy_install_manifest( PNG "${CMAKE_CURRENT_BINARY_DIR}/external/PNG/src/PNG-build/install_manifest.txt" )
		list( APPEND OpenSG_CMAKE_ARGS "-DPNG_NAMES_RELEASE:STRING=libpng16" "-DPNG_NAMES_DEBUG:STRING=libpng16d" )
		list( APPEND OpenSG_OPTIONAL_DEPENDENCIES PNG )
	else()
		message( STATUS "Using already installed PNG." )
	endif()
endif()


############################################################
### GLEW

conditional_find_package( GLEW )
if( GLEW_BUILD )
	message( STATUS "Building GLEW from source." )
	set( GLEW_DIR "${CMAKE_INSTALL_PREFIX}" )
	ExternalProject_Add(
		GLEW
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/GLEW"
		DOWNLOAD_DIR "${SUPERBUILD_}"
		INSTALL_DIR "${GLEW_DIR}"
		${GLEW_DOWNLOAD}
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}/cmake/glew-patch/" <SOURCE_DIR>
		CMAKE_ARGS
			"${DEFAULT_CMAKE_ARGS}"
		)
	copy_install_manifest( GLEW "${CMAKE_CURRENT_BINARY_DIR}/external/GLEW/src/GLEW-build/install_manifest.txt" )
	list( APPEND OpenSG_CMAKE_ARGS "-DGLEW_NAMES_RELEASE:STRING=glew32" "-DGLEW_NAMES_DEBUG:STRING=glew32d" )
	list( APPEND OpenSG_OPTIONAL_DEPENDENCIES GLEW )
else()
	message( STATUS "Using already installed GLEW." )
endif()


############################################################
# OpenSG dependencies:

# TODO: ( ColladaDOM OSGColladaSrcDir )
#   ColladaDOM supports CMake, but its dependency LibXML2 doesn't
#   ColladaDOM depends on LibXML2 PCRE
# OK: ( FreeGLUT OSGFreeGlutSrcDir )
# OK: ( GLEW OSGGLEWSrcDir )
# TODO: ( JPEG OSGJpegLibSrcDir )
# TODO: ( LibXML2 OSGLibXml2SrcDir )
# TODO: ( PCRE OSGPcreSrcDir )
# OK: ( PNG OSGLibPNGSrcDir )
# OK: ( ZLIB OSGZLibSrcDir )


############################################################
### OpenSG
message( STATUS "Building OpenSG from source..." )

# set OpenSG_DIR, so that find_package finds it:
set( OpenSG_DIR "${CMAKE_INSTALL_PREFIX}" )

# Build options for OpenSG:
list( APPEND OpenSG_CMAKE_ARGS
	"-DOSGCOMPAT_ENABLE:BOOL=ON" "-DOSGCOMPAT_ENABLE_DEPRECATED:BOOL=ON"
	"-DOSGBUILD_TESTS:BOOL=OFF"
	)

# XXX: STEP_TARGETS is for debugging:
ExternalProject_Add(
	OpenSG
	DEPENDS Boost ${OpenSG_OPTIONAL_DEPENDENCIES}
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/OpenSG"
	SOURCE_DIR "${SUPERBUILD_VCS_CACHE_DIRECTORY}/OpenSG"
	INSTALL_DIR "${OpenSG_DIR}"
	${OpenSG_DOWNLOAD}
	${MAYBE_DISABLE_UPDATE_COMMAND}
	PATCH_COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/cmake/opensg-patch/FindGLUT_OpenSG.cmake" <SOURCE_DIR>/CMake/FindGLUT_OpenSG.cmake
	CMAKE_ARGS
		"${DEFAULT_CMAKE_ARGS}"
		${OpenSG_CMAKE_ARGS}
	STEP_TARGETS configure
	)
copy_install_manifest( OpenSG "${CMAKE_CURRENT_BINARY_DIR}/external/OpenSG/src/OpenSG-build/install_manifest.txt")

# -> jpeg freetype

############################################################
### inVRs

# this can be overridden in repositories/*
option( SUPERBUILD_ENABLE_inVRs "Build with inVRs. Turning this off can be a nice way to get a full OpenSG stack only." ON)
if( SUPERBUILD_ENABLE_inVRs )
	ExternalProject_Add(
		inVRs
		DEPENDS OpenSG
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/inVRs"
		SOURCE_DIR "${SUPERBUILD_VCS_CACHE_DIRECTORY}/inVRs"
		${inVRs_DOWNLOAD}
		${MAYBE_DISABLE_UPDATE_COMMAND}
		INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"
		CMAKE_ARGS "${DEFAULT_CMAKE_ARGS}" "-DBOOST_ROOT:PATH=${BOOST_ROOT}" "-DOpenSG_DIR:PATH=${OpenSG_DIR}"
		)
	copy_install_manifest( inVRs "${CMAKE_CURRENT_BINARY_DIR}/inVRs-prefix/src/inVRs-build/install_manifest.txt")
endif()
