cmake_minimum_required(VERSION 3.17)
set(PROJ_NAME soniclib)
project(${PROJ_NAME} C ASM)

set(CMAKE_C_STANDARD 99)

set(SRC_PATH ${CMAKE_CURRENT_SOURCE_DIR}/src/)
#set(FREERTOS_SRC_PATH ${CMAKE_SOURCE_DIR}/../Middlewares/Third_Party/FreeRTOS/Source/)

#set(HAL_SRC_PATH ${CMAKE_SOURCE_DIR}/../Drivers/STM32F4xx_HAL_Driver/Src)
#set(LINKER_SCRIPT ${CMAKE_SOURCE_DIR}/CMakeToolchains/STM32F446ZETx_FLASH.ld)

add_library(${PROJ_NAME}
		${SRC_PATH}/ch101_finaltest.c
		${SRC_PATH}/ch101_finaltest_fw.c
		${SRC_PATH}/ch101_floor.c
		${SRC_PATH}/ch101_floor_fw.c
		${SRC_PATH}/ch101_gppc.c
		${SRC_PATH}/ch101_gppc_fw.c
		${SRC_PATH}/ch101_gpr.c
		${SRC_PATH}/ch101_gpr_fw.c
		${SRC_PATH}/ch101_gpr_narrow.c
		${SRC_PATH}/ch101_gpr_narrow_fw.c
		${SRC_PATH}/ch101_gpr_narrow_wd.c
		${SRC_PATH}/ch101_gpr_narrow_wd_fw.c
		${SRC_PATH}/ch101_gpr_open.c
		${SRC_PATH}/ch101_gpr_open_fw.c
		${SRC_PATH}/ch101_gpr_rxopt.c
		${SRC_PATH}/ch101_gpr_rxopt_fw.c
		${SRC_PATH}/ch101_gpr_rxopt_narrow.c
		${SRC_PATH}/ch101_gpr_rxopt_narrow_fw.c
		${SRC_PATH}/ch101_gpr_rxopt_narrow_wd.c
		${SRC_PATH}/ch101_gpr_rxopt_narrow_wd_fw.c
		${SRC_PATH}/ch101_gpr_rxopt_wd.c
		${SRC_PATH}/ch101_gpr_rxopt_wd_fw.c
		${SRC_PATH}/ch101_gpr_sr.c
		${SRC_PATH}/ch101_gpr_sr_fw.c
		${SRC_PATH}/ch101_gpr_sr_narrow.c
		${SRC_PATH}/ch101_gpr_sr_narrow_fw.c
		${SRC_PATH}/ch101_gpr_sr_narrow_wd.c
		${SRC_PATH}/ch101_gpr_sr_narrow_wd_fw.c
		${SRC_PATH}/ch101_gpr_sr_open.c
		${SRC_PATH}/ch101_gpr_sr_open_fw.c
		${SRC_PATH}/ch101_gpr_sr_wd.c
		${SRC_PATH}/ch101_gpr_sr_wd_fw.c
		${SRC_PATH}/ch101_gpr_wd.c
		${SRC_PATH}/ch101_gpr_wd_fw.c
		${SRC_PATH}/ch101_sonicsync.c
		${SRC_PATH}/ch101_sonicsync_master_fw.c
		${SRC_PATH}/ch101_sonicsync_slave_fw.c
		${SRC_PATH}/ch201_finaltest.c
		${SRC_PATH}/ch201_finaltest_fw.c
		${SRC_PATH}/ch201_gprmt.c
		${SRC_PATH}/ch201_gprmt_fw.c
		${SRC_PATH}/ch201_gprmt_wd.c
		${SRC_PATH}/ch201_gprmt_wd_fw.c
		${SRC_PATH}/ch201_gprstr.c
		${SRC_PATH}/ch201_gprstr_fw.c
		${SRC_PATH}/ch201_gprstr_wd.c
		${SRC_PATH}/ch201_gprstr_wd_fw.c
		${SRC_PATH}/ch201_presence.c
		${SRC_PATH}/ch201_presence_fw.c
		${SRC_PATH}/chbsp_dummy.c
		${SRC_PATH}/ch_api.c
		${SRC_PATH}/ch_common.c
		${SRC_PATH}/ch_driver.c
		${SRC_PATH}/ch_math_utils.c
)

if (NOT DEFINED CHIRP_BOARD_CONFIG_DIR)
	set(CHIRP_BOARD_CONFIG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test/codesize)
	message(WARNING "CHIRP_BOARD_CONFIG_DIR not set, defaulting to ${CHIRP_BOARD_CONFIG_DIR}")
	target_compile_definitions(${PROJ_NAME} PUBLIC -DIQ_DATA_MAX_NUM_SAMPLES=240)
	message(WARNING "CHIRP_BOARD_CONFIG_DIR not set, defining IQ_DATA_MAX_NUM_SAMPLES=240")
endif()

target_include_directories(${PROJ_NAME} PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}/inc/
		${CHIRP_BOARD_CONFIG_DIR}
)

#target_link_options(${PROJ_NAME} PRIVATE "-T${LINKER_SCRIPT}")
