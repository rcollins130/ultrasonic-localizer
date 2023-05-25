/*
 * ________________________________________________________________________________________________________
 * Copyright (c) 2020 InvenSense Inc. All rights reserved.
 *
 * This software, related documentation and any modifications thereto (collectively “Software”) is subject
 * to InvenSense and its licensors' intellectual property rights under U.S. and international copyright
 * and other intellectual property rights laws.
 *
 * InvenSense and its licensors retain all intellectual property and proprietary rights in and to the Software
 * and any use, reproduction, disclosure or distribution of the Software without an express license agreement
 * from InvenSense is strictly prohibited.
 *
 * EXCEPT AS OTHERWISE PROVIDED IN A LICENSE AGREEMENT BETWEEN THE PARTIES, THE SOFTWARE IS
 * PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 * EXCEPT AS OTHERWISE PROVIDED IN A LICENSE AGREEMENT BETWEEN THE PARTIES, IN NO EVENT SHALL
 * INVENSENSE BE LIABLE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, OR ANY
 * DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THE SOFTWARE.
 * ________________________________________________________________________________________________________
 */
#include <asf.h>

#include "inv_spi.h"
#include "time.h"
#include "imu_hal.h"

#include "Invn\Drivers\Icm426xx\Icm426xxDefs.h"
#include "Invn\Drivers\Icm426xx\Icm426xxDriver_HL.h"
#include "Invn\Drivers\Icm426xx\Icm426xxTransport.h"
#include "Invn\Drivers\Icm426xx\Icm426xxExtFunc.h"

/* FIFO timestamp resolution is 16us (register value << 4) */
#define IMU_TMST_RESOL_16US    4
/* Define output data in us rate for ICM */
#define IMU_SAMPLE_RATE_TYP_200HZ_IN_US (5000) /* 5 ms <=> 200Hz */
#define IMU_SAMPLE_RATE_MAX_200HZ_IN_US (5250) /* +- 5% margin */
#define IMU_SAMPLE_RATE_MIN_200HZ_IN_US (4750) /* +- 5% margin */

extern uint64_t imu_isr_timestamp;

/* Icm426xx driver object */
static struct inv_icm426xx inv_icm426xx_dev;
/* Timestamp of previous IMU data sampling */
static uint64_t prev_timestamp = 0;
static uint32_t imu_sampling_time = IMU_SAMPLE_RATE_TYP_200HZ_IN_US;

extern void imu_raw_ag_received_callback(uint64_t data_timestamp, int16_t *acc_data, int16_t *gyro_data);

/****************************************************************************/
/*! Low-level serial interface function implementation for SPI
 */
/****************************************************************************/
static int imu_io_hal_read_reg(struct inv_icm426xx_serif * serif, uint8_t reg, uint8_t * buf, uint32_t len)
{
	(void)serif;
	spi_master_read_register(INV_SPI_CS0, reg, len, buf);

	return 0;
}

static int imu_io_hal_write_reg(struct inv_icm426xx_serif * serif, uint8_t reg, const uint8_t * buf, uint32_t len)
{
	(void)serif;

	uint8_t i;
	for (i = 0; i < len ; i++)
		spi_master_write_register(INV_SPI_CS0, reg+i, 1, &buf[i]);
	return 0;
}

/****************************************************************************/
/*! IMU Data callback
 */
/****************************************************************************/

static void imu_raw_data_received_callback(inv_icm426xx_sensor_event_t * event)
{
	uint64_t estimated_timestamp;
	uint32_t delta;

	if ((event->sensor_mask & (1 << INV_ICM426XX_SENSOR_ACCEL))
			&& (event->sensor_mask & (1 << INV_ICM426XX_SENSOR_GYRO))) {
		/* Reconstruct the timestamp if we have multiple elements in the FIFO */
		if ((imu_isr_timestamp - prev_timestamp) > IMU_SAMPLE_RATE_MAX_200HZ_IN_US) {
			estimated_timestamp = prev_timestamp + imu_sampling_time;
		} else {
			estimated_timestamp = imu_isr_timestamp;
			delta = imu_isr_timestamp - prev_timestamp;
			if ((delta > IMU_SAMPLE_RATE_MIN_200HZ_IN_US) && (delta < IMU_SAMPLE_RATE_MAX_200HZ_IN_US))
				imu_sampling_time = delta;
		}
		prev_timestamp = estimated_timestamp;

		/* notify gyr, acc, timestamp_fsync and fsync_event to upper layer */
		imu_raw_ag_received_callback(estimated_timestamp, &event->accel[0], &event->gyro[0]);
	}
}

/****************************************************************************/
/*! Public API
 */
/****************************************************************************/

int8_t imu_hal_init(void)
{
	struct inv_icm426xx_serif icm426xx_serif;
	uint8_t who_am_i = 0;
	int8_t rc;

	printf("Booting up ICM426xx...\r\n");

	spi_master_init(INV_SPI_CS0);

	/* Initialize serial interface between MCU and Icm426xx */
	icm426xx_serif.serif_type = ICM426XX_UI_SPI4;
	icm426xx_serif.max_read = 32768; /* 1024*32 */
	icm426xx_serif.max_write = 32768; /* 1024*32 */
	icm426xx_serif.context = 0; /*no need */
	icm426xx_serif.read_reg = imu_io_hal_read_reg;
	icm426xx_serif.write_reg = imu_io_hal_write_reg;

	rc = inv_icm426xx_init(&inv_icm426xx_dev, &icm426xx_serif, imu_raw_data_received_callback);
	if(rc != INV_ERROR_SUCCESS)
	{
		printf("inv_icm426xx_init() failed\r\n");
		return rc;
	}

	/* Check WHOAMI */
	printf("Reading ICM426xx WHOAMI...\r\n");
	rc = inv_icm426xx_get_who_am_i(&inv_icm426xx_dev, &who_am_i);
	if(rc != INV_ERROR_SUCCESS) {
		printf("inv_icm426xx_get_who_am_i() failed\r\n");
		return rc;
	}

	if (who_am_i != ICM42688_WHOAMI) {
		printf("Unexpected WHOAMI value %d. Aborting setup\r\n", who_am_i);
		return INV_ERROR;
	} else {
		printf("ICM426xx WHOAMI value: 0x%x\r\n", who_am_i);
	}

	/* Configure sensors */
	rc |= inv_icm426xx_set_accel_fsr(&inv_icm426xx_dev, ICM426XX_ACCEL_CONFIG0_FS_SEL_16g);
	rc |= inv_icm426xx_set_gyro_fsr(&inv_icm426xx_dev, ICM426XX_GYRO_CONFIG0_FS_SEL_2000dps);

	rc |= inv_icm426xx_set_accel_frequency(&inv_icm426xx_dev, ICM426XX_ACCEL_CONFIG0_ODR_200_HZ);
	rc |= inv_icm426xx_set_gyro_frequency(&inv_icm426xx_dev, ICM426XX_GYRO_CONFIG0_ODR_200_HZ);

	return rc;
}

int8_t imu_hal_enable(void)
{
	int8_t rc = inv_icm426xx_enable_accel_low_noise_mode(&inv_icm426xx_dev);
	rc |= inv_icm426xx_enable_gyro_low_noise_mode(&inv_icm426xx_dev);

	prev_timestamp = time_get_in_us();

	return rc;
}

int8_t imu_hal_disable(void)
{
	int8_t rc = inv_icm426xx_disable_accel(&inv_icm426xx_dev);
	rc |= inv_icm426xx_disable_gyro(&inv_icm426xx_dev);

	return rc;
}

void imu_hal_start_data_read(void)
{
	/*
	 * Extract packets from FIFO. Callback defined at init time (i.e. imu_raw_data_received_callback)
	 * will be called for each valid packet extracted from FIFO.
	 */
	inv_icm426xx_get_data_from_fifo(&inv_icm426xx_dev);
}


/****************************************************************************/
/*! Sleep & Get time implementation for ICM426xx
 */
/****************************************************************************/
extern void inv_icm426xx_sleep_us(uint32_t us)
{
	delay_us(us);
}

uint64_t inv_icm426xx_get_time_us(void)
{
	return time_get_in_us();
}