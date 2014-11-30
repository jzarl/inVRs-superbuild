cmake_minimum_required( VERSION 3.0 FATAL_ERROR )
project( inVRs-SuperBuild )

############################################################
### Boilerplate code

set (CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type (Release/Debug)")
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Release Debug)
# when first generating the cache, cache-variables are not instantly available (only at subsequent runs):
if (NOT CMAKE_BUILD_TYPE)
	set (CMAKE_BUILD_TYPE Release)
endif (NOT CMAKE_BUILD_TYPE)

set( DOWNLOAD_CACHE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/download" CACHE PATH "Cache directory for downloaded files." )
mark_as_advanced( DOWNLOAD_CACHE_DIRECTORY )

set(DEFAULT_CMAKE_ARGS
	"-DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>"
	"-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
	)

# the default install prefix usually won't work because the external projects are installed
if( "${CMAKE_INSTALL_PREFIX}" STREQUAL "/usr/local" )
	message( WARNING "The install prefix ${CMAKE_INSTALL_PREFIX} is normally not writable." )
endif()

include( ExternalProject )
include( "${CMAKE_CURRENT_SOURCE_DIR}/repositories.cmake" )
include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HelperFunctions.cmake" )

############################################################
### Boost
set( BOOST_REQUIRED_COMPONENTS system filesystem )
# try already installed version first:
conditional_find_package( Boost COMPONENTS ${BOOST_REQUIRED_COMPONENTS} )

if( Boost_BUILD )
	# set BOOST_ROOT, so that find_package finds this boost, later:
	set( BOOST_ROOT "${CMAKE_INSTALL_PREFIX}" )

	# windows-builds of boost need different compilation commands:
	if( WIN32 )
		# Windows boost does apperently not support out-of-tree builds:
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.bat)
		set( BOOST_B2_COMMAND <SOURCE_DIR>/b2.exe install "--build-dir=<SOURCE_DIR>" "--prefix=<INSTALL_DIR>")
	else()
		set( BOOST_BOOTSTRAP_COMMAND <SOURCE_DIR>/bootstrap.sh "--prefix=<INSTALL_DIR>" )
		set( BOOST_B2_COMMAND <BINARY_DIR>/b2 install "--build-dir=<BINARY_DIR>" "--prefix=<INSTALL_DIR>" )
	endif()

	# assemble the complete b2 commandline:
	list( APPEND BOOST_B2_COMMAND "--layout=versioned" "--build-type=complete" )
	foreach( component IN LISTS BOOST_REQUIRED_COMPONENTS )
		list( APPEND BOOST_B2_COMMAND "--with-${component}" )
	endforeach()

	# version 1.56 is the latest version recognised by cmake 3.0.2:
	ExternalProject_Add(
		Boost
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/boost"
		DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
		${Boost_DOWNLOAD}
		UPDATE_COMMAND "${BOOST_BOOTSTRAP_COMMAND}"
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND "${BOOST_B2_COMMAND}"
		INSTALL_DIR "${BOOST_ROOT}"
		)
else()
	# create pseudo-target for ExternalProject_Add depends:
	add_custom_target( Boost COMMENT "Using system-installed Boost." )
endif()

############################################################
### OpenSG
# Build options for OpenSG:
set( OpenSG_CMAKE_ARGS
	"-DOSGCOMPAT_ENABLE:BOOL=ON" "-DOSGCOMPAT_ENABLE_DEPRECATED:BOOL=ON"
	)
# set OpenSG_DIR, so that find_package finds it:
set( OpenSG_DIR "${CMAKE_INSTALL_PREFIX}" )
ExternalProject_Add(
	OpenSG
	DEPENDS Boost
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensg"
	${OpenSG_DOWNLOAD}
	INSTALL_DIR "${OpenSG_DIR}"
	CMAKE_ARGS "${DEFAULT_CMAKE_ARGS}" "-DBOOST_ROOT:PATH=${BOOST_ROOT}" ${OpenSG_CMAKE_ARGS}
	)
# -> collada jpeg png freetype
# -> boost

############################################################
### inVRs
ExternalProject_Add(
	inVRs
	DEPENDS OpenSG
	${inVRs_DOWNLOAD}
	INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"
	CMAKE_ARGS "${DEFAULT_CMAKE_ARGS}" "-DBOOST_ROOT:PATH=${BOOST_ROOT}" "-DOpenSG_DIR:PATH=${OpenSG_DIR}"
	)
