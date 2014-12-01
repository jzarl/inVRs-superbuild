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

set( DEFAULT_CMAKE_ARGS
	"-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}"
	"-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
	)
set( EP_DOWNLOAD_ONLY
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport"
	DOWNLOAD_DIR "${DOWNLOAD_CACHE_DIRECTORY}"
	UPDATE_COMMAND ""
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ""
	INSTALL_COMMAND ""
	)

# the default install prefix usually won't work because the external projects are installed during build time
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

list( APPEND OpenSG_DEPS Boost )
list( APPEND OpenSG_DEPS_ARGS "-DBOOST_ROOT:PATH=${BOOST_ROOT}" )

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
	add_custom_target( Boost COMMENT "Using system-installed Boost." )
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
### OpenSG Support libs
ExternalProject_Add(ColladaDOM ${ColladaDOM_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGColladaSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/ColladaDOM" )

ExternalProject_Add(FreeGLUT ${FreeGLUT_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGFreeGlutSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/FreeGLUT" )

ExternalProject_Add(GLEW ${GLEW_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGGLEWSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/GLEW" )

ExternalProject_Add(JPEG ${JPEG_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGJpegLibSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/JPEG" )

ExternalProject_Add(LibXML2 ${LibXML2_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGLibXml2SrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/LibXML2" )

ExternalProject_Add(PCRE ${PCRE_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGPcreSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/PCRE" )

ExternalProject_Add(PNG ${PNG_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGLibPNGSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/PNG" )

ExternalProject_Add(ZLIB ${ZLIB_DOWNLOAD} ${EP_DOWNLOAD_ONLY} )
list( APPEND OpenSG_CMAKE_ARGS "-DOSGZLibSrcDir:PATH=${CMAKE_CURRENT_BINARY_DIR}/external/opensgsupport/src/ZLIB" )



############################################################
### OpenSG
message( STATUS "Building OpenSG from source..." )

# set OpenSG_DIR, so that find_package finds it:
set( OpenSG_DIR "${CMAKE_INSTALL_PREFIX}" )

# Build options for OpenSG:
list( APPEND OpenSG_CMAKE_ARGS
	"-DOSG_USE_OSGSUPPORT_LIBS:BOOL=ON"
	"-DOSGCOMPAT_ENABLE:BOOL=ON" "-DOSGCOMPAT_ENABLE_DEPRECATED:BOOL=ON"
	)

ExternalProject_Add(
	OpenSG
	DEPENDS ${OpenSG_DEPS}
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensg"
	INSTALL_DIR "${OpenSG_DIR}"
	${OpenSG_DOWNLOAD}
	CMAKE_ARGS
		"${DEFAULT_CMAKE_ARGS}"
		${OpenSG_CMAKE_ARGS}
		${OpenSG_DEPS_ARGS}
	)

# -> jpeg freetype

############################################################
### inVRs
ExternalProject_Add(
	inVRs
	DEPENDS OpenSG
	${inVRs_DOWNLOAD}
	INSTALL_DIR "${CMAKE_INSTALL_PREFIX}"
	CMAKE_ARGS "${DEFAULT_CMAKE_ARGS}" "-DBOOST_ROOT:PATH=${BOOST_ROOT}" "-DOpenSG_DIR:PATH=${OpenSG_DIR}"
	)
