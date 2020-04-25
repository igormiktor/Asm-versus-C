
cmake_minimum_required( VERSION 3.5 )

set( TGT_DEVICE "ArduninoUno02" )


set( AVR_UPLOADTOOL avrdude )

if ( TGT_DEVICE STREQUAL "ArduninoUno01" )
    set( AVR_PROGRAMMER arduino )
    set( AVR_UPLOADTOOL_PORT /dev/ArduinoUno01 )
    set( AVR_MCU atmega328p )
    set( AVR_MCU_SPEED 16000000UL )
elseif( TGT_DEVICE STREQUAL "ArduninoUno02" )
    set( AVR_PROGRAMMER arduino )
    set( AVR_UPLOADTOOL_PORT /dev/ArduinoUno02 )
    set( AVR_MCU atmega328p )
    set( AVR_MCU_SPEED 16000000UL )
elseif( TGT_DEVICE STREQUAL "ArdunioMega01" )
    set( AVR_PROGRAMMER wiring )
    set( AVR_UPLOADTOOL_PORT /dev/ArduinoMega01 )
    set( AVR_MCU atmega2560 )
    set( AVR_MCU_SPEED 16000000UL )
else()
    message( FATAL_ERROR "Incorrect target device name" )
endif()


set( CMAKE_TOOLCHAIN_FILE $ENV{HOME}/.cmake/avr-gcc-toolchain.cmake )


project( ToggleLeds )

set( CMAKE_BUILD_TYPE Release )

enable_language( ASM )

set( Srcs
        ToggleLeds.cpp
        delayTenthsOfSeconds.S
    )


add_avr_executable( ToggleLeds ${Srcs} )
