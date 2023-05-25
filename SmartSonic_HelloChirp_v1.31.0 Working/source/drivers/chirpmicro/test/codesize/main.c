/*
 * ________________________________________________________________________________________________________
 * Copyright (c) 2020 InvenSense Inc. All rights reserved.
 *
 * This software, related documentation and any modifications thereto (collectively �Software�) is subject
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

#include "app_config.h"
#include "chirp_bsp.h"

#define DATA_READY_FLAG		(1 << 0)
#define IQ_READY_FLAG		(1 << 1)

typedef struct {
	uint32_t		range;							// from ch_get_range()
	uint16_t		amplitude;						// from ch_get_amplitude()
	uint16_t		num_samples;					// from ch_get_num_samples()
	ch_iq_sample_t	iq_data[DATA_MAX_NUM_SAMPLES];	// from ch_get_iq_data()
} chirp_data_t;

chirp_data_t	chirp_data[CHIRP_MAX_NUM_SENSORS];
ch_dev_t	chirp_devices[CHIRP_MAX_NUM_SENSORS];
ch_group_t 	chirp_group;
ch_thresholds_t chirp_ch201_thresholds = {
	.threshold = {
		{0, 	5000},		/* threshold 0 */
		{26,	2000},		/* threshold 1 */
		{39,	800},		/* threshold 2 */
		{56,	400},		/* threshold 3 */
		{79,	250},		/* threshold 4 */
		{89,	175}		/* threshold 5 */
	}
};
volatile uint32_t taskflags = 0;
static uint32_t active_devices;
static uint8_t	num_connected_sensors = 0;
static uint8_t	num_triggered_devices = 0;
static uint8_t	num_io_queued = 0;

/* Forward declarations */
static void    sensor_int_callback_dummy(ch_group_t *grp_ptr, uint8_t dev_num);
static void    io_complete_callback_dummy(ch_group_t *grp_ptr);
static void    periodic_timer_callback_dummy(void);
static uint8_t handle_data_ready(ch_group_t *grp_ptr);
static uint8_t display_iq_data(ch_dev_t *dev_ptr) ;
static uint8_t handle_iq_data_done(ch_group_t *grp_ptr);


/* main() - entry point and main loop
 *
 * This function contains the initialization sequence for a simple application, based on hello chirp example.
 * After the initialization sequence completes, this routine enters an infinite 
 * loop that will run for the remainder of the application execution.
 */
int main(void)
{
	uint8_t ret = 0;
	uint8_t num_ports;
	uint8_t dev_num;
	ch_group_t *grp_ptr = &chirp_group;

	chbsp_board_init(grp_ptr);
	num_ports = ch_get_num_ports(grp_ptr);

	for (dev_num = 0; dev_num < num_ports; dev_num++) {
		ch_dev_t *dev_ptr = &(chirp_devices[dev_num]);
		ret |= ch_init(dev_ptr, grp_ptr, dev_num, CHIRP_SENSOR_FW_INIT_FUNC);
	}
	
	ret = ch_group_start(grp_ptr);

	ch_dev_t *dev_ptr = ch_get_dev_ptr(grp_ptr, 0);
	for (dev_num = 0; dev_num < num_ports; dev_num++) {
		if (ch_sensor_is_connected(dev_ptr)) {
			uint16_t part_num = ch_get_part_number(dev_ptr);
			uint32_t freq = ch_get_frequency(dev_ptr);
			uint16_t rtc_cal = ch_get_rtc_cal_result(dev_ptr);
			uint16_t rtc_pulselength = ch_get_rtc_cal_pulselength(dev_ptr);
                        const char * p_fw_version = ch_get_fw_version_string(dev_ptr);
		}
	}

	ch_io_int_callback_set(grp_ptr, sensor_int_callback_dummy);
	ch_io_complete_callback_set(grp_ptr, io_complete_callback_dummy);

	for (dev_num = 0; dev_num < num_ports; dev_num++) {
		ch_config_t dev_config;
		if (ch_sensor_is_connected(dev_ptr)) {
			num_connected_sensors++;
                        active_devices |= (1 << dev_num);
			if (num_connected_sensors == 1) {
				dev_config.mode = CHIRP_FIRST_SENSOR_MODE;
			} else {
				dev_config.mode = CHIRP_OTHER_SENSOR_MODE;
			}
                        if (dev_config.mode != CH_MODE_FREERUN) {
				num_triggered_devices++;
			}
			dev_config.max_range       = CHIRP_SENSOR_MAX_RANGE_MM;
			dev_config.static_range    = CHIRP_SENSOR_STATIC_RANGE;
			if (dev_config.mode == CH_MODE_FREERUN) {
				dev_config.sample_interval = MEASUREMENT_INTERVAL_MS;
			} else {
				dev_config.sample_interval = 0;
			}
			if (ch_get_part_number(dev_ptr) == CH201_PART_NUMBER) {
				dev_config.thresh_ptr = &chirp_ch201_thresholds;
			} else {
				dev_config.thresh_ptr = 0;
			}
			ret = ch_set_config(dev_ptr, &dev_config);
			if ((!ret) && (dev_config.mode == CH_MODE_FREERUN)) {
				chbsp_set_io_dir_in(dev_ptr);
				chbsp_io_interrupt_enable(dev_ptr);
			}
			if (!ret) {
				chbsp_led_on(dev_num);
			}
		}
	}

	ch_set_rx_pretrigger(grp_ptr, RX_PRETRIGGER_ENABLE);
        
        if (num_triggered_devices > 0) {
		chbsp_periodic_timer_init(MEASUREMENT_INTERVAL_MS, periodic_timer_callback_dummy);
		chbsp_periodic_timer_irq_enable();
		chbsp_periodic_timer_start();
        }

	while(1) {
		if (taskflags == 0)
			chbsp_proc_sleep();

		if (taskflags & DATA_READY_FLAG) {
			taskflags &= ~DATA_READY_FLAG;
			handle_data_ready(grp_ptr);
		}

                if (num_io_queued != 0) {
			ch_io_start_nb(grp_ptr);
			num_io_queued = 0;
		}
		if (taskflags & IQ_READY_FLAG) {
			taskflags &= ~IQ_READY_FLAG;
			handle_iq_data_done(grp_ptr);
		}
	}
}

static void periodic_timer_callback_dummy(void) {
	if (num_triggered_devices > 0) {
		ch_group_trigger(&chirp_group);
        }
}

static void sensor_int_callback_dummy(ch_group_t *grp_ptr, uint8_t dev_num) {
	ch_dev_t *dev_ptr = ch_get_dev_ptr(grp_ptr, dev_num);
        if ((1 << dev_num) == active_devices) {
		taskflags |= DATA_READY_FLAG;
                if (ch_get_mode(dev_ptr) == CH_MODE_FREERUN) {
			chbsp_set_io_dir_in(dev_ptr);
			chbsp_group_io_interrupt_enable(grp_ptr);
		} else {
			chbsp_group_io_interrupt_disable(grp_ptr);
		}
        }
}

static void io_complete_callback_dummy(ch_group_t __attribute__((unused)) *grp_ptr) {
	taskflags |= IQ_READY_FLAG;
}

static uint8_t handle_data_ready(ch_group_t *grp_ptr) {
	uint8_t 	dev_num;
	int 		num_samples = 0;
        uint8_t 	ret_val = 0;

	for (dev_num = 0; dev_num < ch_get_num_ports(grp_ptr); dev_num++) {
		ch_dev_t *dev_ptr = ch_get_dev_ptr(grp_ptr, dev_num);

		if (ch_sensor_is_connected(dev_ptr)) {

			if (ch_get_mode(dev_ptr) == CH_MODE_TRIGGERED_RX_ONLY) {
				chirp_data[dev_num].range = ch_get_range(dev_ptr, CH_RANGE_DIRECT);
			} else {
				chirp_data[dev_num].range = ch_get_range(dev_ptr, CH_RANGE_ECHO_ONE_WAY);
			}

			if (chirp_data[dev_num].range == CH_NO_TARGET) {
				chirp_data[dev_num].amplitude = 0;
			} else {
				chirp_data[dev_num].amplitude = ch_get_amplitude(dev_ptr);
			}

			num_samples = ch_get_num_samples(dev_ptr);
			chirp_data[dev_num].num_samples = num_samples;

			display_iq_data(dev_ptr);
		}
	}
	return ret_val;
}

uint8_t display_iq_data(ch_dev_t *dev_ptr) {
	uint8_t 	error = 0;
	uint16_t 	num_samples = ch_get_num_samples(dev_ptr);
	uint8_t		dev_num = ch_get_dev_num(dev_ptr);

#if defined(READ_IQ_BLOCKING)
	error = ch_get_iq_data(dev_ptr, chirp_data[dev_num].iq_data, 
								start_sample, num_samples, CH_IO_MODE_BLOCK);
#elif defined(READ_IQ_NONBLOCKING)
	error = ch_get_iq_data(dev_ptr, chirp_data[dev_num].iq_data, 
								start_sample, num_samples, CH_IO_MODE_NONBLOCK);
#endif  // defined(READ_IQ_BLOCKING)
	return error;
}

static uint8_t handle_iq_data_done(ch_group_t *grp_ptr) {
	int				dev_num;
	uint16_t 		num_samples;

	for (dev_num = 0; dev_num < ch_get_num_ports(grp_ptr); dev_num++) {
		ch_dev_t *dev_ptr = ch_get_dev_ptr(grp_ptr, dev_num);
		if (ch_sensor_is_connected(dev_ptr)) {
			num_samples = ch_get_num_samples(dev_ptr);
			(void)num_samples;
		}
	}
	return 0;
}