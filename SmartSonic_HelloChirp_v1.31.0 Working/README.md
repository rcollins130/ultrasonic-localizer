# SmartSonic HelloChirp Example v1.31.0
Copyright 2021 Chirp Microsystems. All rights reserved.

### Overview
- This release contains a revised version of the CH101 HelloChirp Example project for the Chirp SmartSonic board, 
including changes to the example application, an updated version of the SonicLib sensor library, and updated CH101 GPR sensor 
firmware which enables new features.

### Change log
- The new CH101 GPR firmwares add support for getting/setting the calibration results. The *ch_get_cal_result()*
function in SonicLib API is used to get the calibration result from the sensor. The *ch_set_cal_result()* is used to set the calibration result to the sensor.

### Instructions

- Open **source\application\smartsonic-hellochirp-example\inc\app_config.h**
- In **Sensor Firmware Selection Selection** section, uncomment ONE of the following lines to use that sensor firmware type.
For example, uncomment line#69 to use **ch101_gpr_sr_narrow_init** for **CH101 GPR Short range narrow FoV** firmware.
			#define	 CHIRP_SENSOR_FW_INIT_FUNC	ch101_gpr_sr_narrow_init

- To get the calibration result from a sensor, use *uint8_t ch_get_cal_result(ch_dev_t *dev_ptr, ch_cal_result_t *cal_ptr);*
For example,
			ch_cal_result_t cal_result;
			int err = 0;
			err = ch_get_cal_result(dev_ptr, &cal_result);

- To set a saved calibration result to a sensor, use *uint8_t ch_set_cal_result(ch_dev_t *dev_ptr, ch_cal_result_t *cal_ptr);*
For example,
			ch_cal_result_t cal_result;			
			cal_result.dco_period = 184;
			cal_result.rev_cycles = 263;
			ch_set_cal_result(dev_ptr, &cal_result);

**dev_ptr is a pointer that points to Chirp sensor device structure*

### WARNING
The *ch_set_cal_result()* function should not be used to set the calibration result to a fixed value, 
even one individually calculated for each sensor, as this could change over the lifetime 
of the sensor; rather, this function could be used to update the calibration result if the 
calibration result calculated by CHx01 at startup (i.e. returned by *ch_get_cal_result()*) 
is sufficiently different than expected or sensor performance is not good.

For more information about the API, please check **source\drivers\chirpmicro\inc\soniclib.h**	