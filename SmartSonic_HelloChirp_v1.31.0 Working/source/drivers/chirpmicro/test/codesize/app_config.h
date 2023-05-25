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

#ifndef __APP_CONFIG_H_
#define __APP_CONFIG_H_

#include "soniclib.h"

 /*========================= Sensor Firmware Selection ===========================*/

/* Select sensor firmware to use 
 *   The sensor firmware type is specified during the call to ch_init(), by
 *   giving the name (address) of the firmware initialization function that will
 *   be called.  The CHIRP_SENSOR_FW_INIT_FUNC symbol is used to specify the 
 *   init routine for the sensor firmware to be used.
 *
 *   Uncomment ONE of the following lines to use that sensor firmware type.
 *   You must choose a firmware type that is appropriate for the sensor model 
 *   you are using (CH101 or CH201).  
 *
 *   To use a different sensor firmware type than those listed here (for 
 *   example, a new distribution from Chirp), simply define 
 *   CHIRP_SENSOR_FW_INIT_FUNC to equal the name of the init routine for 
 *   the new firmware.
 *
 * 	 Short Range Firmware:
 *   CH101 sensor firmware with "sr" in the name, e.g. ch101_gpr_sr_open, is 
 *   optimized for short range. The short range firmware has 4 times the 
 *   resolution, but only 1/4 the maximum range.  If you use this option, you 
 *   should redefine the CHIRP_SENSOR_MAX_RANGE_MM symbol, below, to 250mm or 
 *   less.
 */

	/* CH101 GPR OPEN - general purpose rangefinding, standard range */
#define	 CHIRP_SENSOR_FW_INIT_FUNC	ch101_gpr_open_init

	/* CH101 GPR SR OPEN - general purpose rangefinding, short range */
// #define	 CHIRP_SENSOR_FW_INIT_FUNC	ch101_gpr_sr_open_init

	/* CH201 GPRMT - general purpose rangefinding / multi threshold */
// #define	 CHIRP_SENSOR_FW_INIT_FUNC	ch201_gprmt_init	

/*============================ Sensor Configuration =============================*/

/* Operating mode for the sensor(s)
 *	 These two values define the mode in which the sensor(s) will operate.  
 *
 *	 The CHIRP_FIRST_SENSOR_MODE value specifies the mode for the first sensor
 *	 (lowest numbered) that is present.  If only one sensor is attached, this
 *	 value must be either CH_MODE_TRIGGERED_TX_RX or CH_MODE_FREERUN.
 *
 *	 The CHIRP_OTHER_SENSOR_MODE value specifies the mode for all other sensors
 *	 that are present.
 *
 * 	 For typical Pitch-Catch operation using two or more sensors, set 
 * 	 CHIRP_FIRST_SENSOR_MODE to CH_MODE_TRIGGERED_TX_RX and set 
 * 	 CHIRP_OTHER_SENSOR_MODE to CH_MODE_TRIGGERED_RX_ONLY.
 */
#define CHIRP_FIRST_SENSOR_MODE		CH_MODE_TRIGGERED_TX_RX
#define CHIRP_OTHER_SENSOR_MODE		CH_MODE_TRIGGERED_RX_ONLY

/* Maximum detection range for the sensor
 * This value will determine how long the sensor "listens" for an ultrasound 
 * signal.  Note that the maximum possible range will vary depending on sensor 
 * model (CH101 vs. CH201) and sensor firmware type.  If the value specified 
 * here is greater than the maximum possible range, the maximum possible range 
 * will be used.
 */
#define	CHIRP_SENSOR_MAX_RANGE_MM		(750)	/* maximum range, in mm */

/* Static target rejection range
 * This value specifies if static target rejection (STR) will be used.  If
 * CHIRP_SENSOR_STATIC_RANGE is non-zero, STR will be enabled and will apply
 * to the specified number of samples at the beginning of a measurement.
 */
#define	CHIRP_SENSOR_STATIC_RANGE		(0)	/* static target rejection sample 
											   range, in samples (0=disabled) */
/* Receive sensor pre-triggering
 * This value specifieds if receive (rx) sensor pre-triggering will be used.  
 * This setting only applies if more than one sensor is used, and one or more 
 * sensor is operating in CH_MODE_TRIGGERED_RX_ONLY.  
 *
 * Receive pre-triggering improves performance in pitch-catch operation at 
 * short distances, by triggering the receive-only sensor(s) slightly before 
 * the transmitting sensor.  However, this setting will reduce maximum range of 
 * rx-only sensors approximately 200mm, relative to the 
 * CHIRP_SENSOR_MAX_RANGE_MM setting, above.
 *
 * Set RX_PRETRIGGER_ENABLE to non-zero to enable rx pretriggering, or zero 
 * to disable.
 */

#define RX_PRETRIGGER_ENABLE	 1
											   
/*============================= Application Timing ==============================*/

/* Define how often the application will get a new sample from the sensor(s) 
 *   This macro defines the sensor measurement interval, in milliseconds.  
 *
 *   For sensors in triggered mode (CH_MODE_TRIGGERED_TX_RX or 
 *   CH_MODE_TRIGGERED_RX_ONLY), the application will use a periodic timer to 
 *   trigger a sensor measurement each time this period elapses.
 *
 *   For sensors in free-running mode (CH_MODE_FREERUN), the application will
 *   set this period as the sensor's internal sample interval.
 */
#define	MEASUREMENT_INTERVAL_MS		(100)

/*===================  Application Storage for Sensor Data ======================*/

/* Define how many samples per measurement are expected by this application
 *   The following macro is used to allocate array storage in the "chirp_data_t"
 *   structure, defined in main.c.  That structure contains arrays for 
 *   individual data values (I/Q or amplitude) that describe the raw samples 
 *   within an ultrasound measurement.  
 *
 *   Because a Chirp CH201 sensor has more samples in each measurement than a 
 *   CH101 device, the CH201 sample count is used here by default.  If you are 
 *   ONLY using CH101 devices with this application, you may redefine the 
 *   following symbol to CH101_MAX_NUM_SAMPLES to use less memory.
 */
#define DATA_MAX_NUM_SAMPLES  CH201_MAX_NUM_SAMPLES		// use CH201 max

/*===================  Build Options for I/Q Data Handling ======================*/

/* The following build options control if and how the raw I/Q data is read 
 * from the device after each measurement cycle, in addition to the standard 
 * range and amplitude.  
 *
 * Note that reading the I/Q data is not required for most basic sensing 
 * applications - the reported range value is typically all that is required. 
 * However, the full data set may be read and analyzed for more advanced 
 * sensing or data capture needs.
 *
 * Comment or un-comment the various definitions, as appropriate.
 *
 * By default, this application will read the I/Q data in blocking mode.
 * The data will be read from the device and placed in the I/Q data array field 
 * in the application's chirp_data structure.  Because the I/Q data is read in 
 * blocking mode, the call to ch_get_iq_data() will not return until the data 
 * has actually been copied from the device.  
 *
 * If, however, READ_IQ_NONBLOCKING is defined instead, the I/Q data will be 
 * read in non-blocking mode. The ch_get_iq_data() call will return immediately,
 * and a separate callback function will be called to notify the application 
 * when the read operation is complete.
 */
#define READ_IQ_DATA_BLOCKING		/* define for blocking I/Q data read */
// #define READ_IQ_DATA_NONBLOCK	/* define for non-blocking I/Q data read */

#endif /* __APP_CONFIG_H_ */