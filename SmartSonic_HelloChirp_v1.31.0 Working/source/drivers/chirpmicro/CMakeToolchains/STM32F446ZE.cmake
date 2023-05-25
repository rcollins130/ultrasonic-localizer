# cmake toolchain file 

SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_VERSION 1)
# Needed to make the test compile pass
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY" CACHE STRING "" FORCE)

file(TO_CMAKE_PATH $ENV{ARM_GCC_PATH} ARM_GCC_PATH)

set(CMAKE_SYSROOT "${ARM_GCC_PATH}/arm-none-eabi" CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(ARCH_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")

add_compile_definitions(
	STM32F446xx
	USE_HAL_DRIVER
	PROTOCOL_USB
)

set(STM_HAL_ROOT "${STMCUBE_PATH}/Drivers/STM32F4xx_HAL_Driver")
set(STM_CMSIS_ROOT "${STMCUBE_PATH}/Drivers/CMSIS")

if(WIN32)
	set(CMAKE_C_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc.exe")
	set(CMAKE_CXX_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-g++.exe")
else()
	set(CMAKE_C_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc")
	set(CMAKE_CXX_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-g++")
endif()

set(CMAKE_C_FLAGS   "${ARCH_FLAGS} -fno-strict-aliasing -ffunction-sections -fdata-sections -Wall -fno-exceptions -lgcc -lc -lm -lrdimon" CACHE STRING "" FORCE)
set(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -fno-rtti" CACHE STRING "" FORCE)

# Link for code size
set(GC "-Wl,--gc-sections")
set(MAP "-Wl,-Map=output.map")
set(NOSYS "--specs=nosys.specs")
set(USE_NANO "--specs=nano.specs")

set(LFLAGS "--specs=rdimon.specs ${GC} ${MAP} -lc")

SET(CMAKE_EXE_LINKER_FLAGS "${LFLAGS}")

set(CMAKE_C_FLAGS_DEBUG "-Os -g -fno-omit-frame-pointer -funwind-tables -mno-sched-prolog" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_DEBUG "-Os -g -fno-omit-frame-pointer -funwind-tables -mno-sched-prolog" CACHE STRING "" FORCE)

set(CMAKE_C_FLAGS_RELEASE "-Os -g -DNDEBUG" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "-Os -g -DNDEBUG" CACHE STRING "" FORCE)
