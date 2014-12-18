## Define a tri-state cache variable USE_<PKG> and search the package.
## <PKG>_BUILD is set depending on the combination of USE_<PKG> and <PKG>_FOUND.
##
## You can use it as follows:
## <pre>
## conditional_find_package( MyPackage COMPONENTS My_Component )
## if ( MyPackage_BUILD )
##   ExternalProject_Add( MyPackage ... )
## endif()
function( conditional_find_package PKG )
	# ignore the package, if it's installed in the install prefix
	# this allows for recompilation using another build type:
	list( REMOVE_ITEM CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}" )

	set( USE_${PKG} auto CACHE STRING
	"Which ${PKG} should be used? 'system' to require an already installed version, 'internal' to force building it, 'auto' to try a system-wide installation and fall back to the internal version if none is found." )
	set_property( CACHE USE_${PKG} PROPERTY STRINGS "auto" "system" "internal" )

	if( "${USE_${PKG}}" STREQUAL "internal")
		message( STATUS "Package ${PKG} will be built (Not searching for an already installed version)." )
		set( ${PKG}_BUILD true PARENT_SCOPE)
		return()
	endif()

	if( "${USE_${PKG}}" STREQUAL "system" )
		set( _REQUIRED "REQUIRED" )
	endif()

	find_package( ${PKG} ${ARGN} ${_REQUIRED} QUIET NO_CMAKE_PACKAGE_REGISTRY )
	if( ${PKG}_FOUND )
		message( STATUS "Package ${PKG} is already installed. Not building it..." )
		set( ${PKG}_BUILD false PARENT_SCOPE)
	else()
		message( STATUS "Package ${PKG} is not installed. Building it..." )
		set( ${PKG}_BUILD true PARENT_SCOPE)
	endif()
endfunction()

## Just like conditional_find_package, but using pkg-config.
## Usage is just like pkg_check_modules
function( conditional_pkg_check_modules PKG )
	# ignore the package, if it's installed in the install prefix
	# this allows for recompilation using another build type:
	list( REMOVE_ITEM CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}" )

	set( USE_${PKG} auto CACHE STRING
	"Which ${PKG} should be used? 'system' to require an already installed version, 'internal' to force building it, 'auto' to try a system-wide installation and fall back to the internal version if none is found." )
	set_property( CACHE USE_${PKG} PROPERTY STRINGS "auto" "system" "internal" )

	if( "${USE_${PKG}}" STREQUAL "internal")
		set( ${PKG}_BUILD true PARENT_SCOPE)
		return()
	endif()

	if( "${USE_${PKG}}" STREQUAL "system" )
		set( _REQUIRED "REQUIRED" )
	endif()

	pkg_check_modules( ${PKG} ${ARGN} ${_REQUIRED} )
	if( ${PKG}_FOUND )
		set( ${PKG}_BUILD false PARENT_SCOPE)
	else()
		set( ${PKG}_BUILD true PARENT_SCOPE)
	endif()
endfunction()

function( copy_install_manifest name manifest_file)
	ExternalProject_Add_Step(
		${name} copy_install_manifest
		DEPENDEES install
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${manifest_file} ${inVRs-SuperBuild_BINARY_DIR}/install_manifest_${name}.txt
		)
	create_uninstall_target( ${name} )
endfunction()
