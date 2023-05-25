/*
 Copyright © 2016-2019, Chirp Microsystems.  All rights reserved.

 Chirp Microsystems CONFIDENTIAL

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL CHIRP MICROSYSTEMS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 You can contact the authors of this program by email at support@chirpmicro.com
 or by mail at 2560 Ninth Street, Suite 220, Berkeley, CA 94710.
 */

#include "soniclib.h"				// Chirp SonicLib API definitions
#include "chirp_bsp.h"

/*!
 * \brief Initialize board hardware
 *
 * \note This function performs all necessary initialization on the board.
 */
void chbsp_board_init(ch_group_t *grp_ptr) {
}

/*!
 * \brief Assert the reset pin
 *
 * This function drives the sensor reset pin low.
 */
void chbsp_reset_assert(void) {
}

/*!
 * \brief Deassert the reset pin
 *
 * This function drives the sensor reset pin high.
 */
void chbsp_reset_release(void) {
}

/*!
 * \brief Assert the PROG pin
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function drives the sensor PROG pin high on the specified port.
 */
void chbsp_program_enable(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Deassert the PROG pin
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function drives the sensor PROG pin low on the specified port.
 */
void chbsp_program_disable(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Configure the Chirp sensor INT pin as an output for a group of sensors
 * 
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 *
 * This function should configure each Chirp sensor's INT pin as an output (from the perspective 
 * of the host system).
 */
void chbsp_group_set_io_dir_out(ch_group_t *grp_ptr) {
}

/*!
 * \brief Configure the Chirp sensor INT pin as an output for one sensor.
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function configures the Chirp sensor INT pin as an output (from the perspective 
 * of the host system).
 */
void chbsp_set_io_dir_out(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Configure the Chirp sensor INT pins as inputs for a group of sensors
 * 
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 * 
 * This function should configure each Chirp sensor's INT pin as an input (from the perspective 
 * of the host system).
 */
void chbsp_group_set_io_dir_in(ch_group_t *grp_ptr) {
}

/*!
 * \brief Configure the Chirp sensor INT pin as an input for one sensor.
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function configures the Chirp sensor INT pin as an input (from the perspective of 
 * the host system).
 */
void chbsp_set_io_dir_in(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Initialize the I/O pins.
 *
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 * 
 * Configure reset and program pins as outputs. Assert reset and program. Configure 
 * sensor INT pin as input.
 */
void chbsp_group_pin_init(ch_group_t *grp_ptr) {
}

/*!
 * \brief Set the INT pins low for a group of sensors.
 *
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 * 
 * This function drives the INT line low for each sensor in the group.
 */
void chbsp_group_io_clear(ch_group_t *grp_ptr) {
}

 /*!
 * \brief Set the INT pins high for a group of sensors.
 * 
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 *
 * This function drives the INT line high for each sensor in the group.
 */
void chbsp_group_io_set(ch_group_t *grp_ptr) {
}

/*!
 * \brief Disable interrupts for a group of sensors
 * 
 * \param grp_ptr 	pointer to the ch_group_t config structure for a group of sensors
 *
 * For each sensor in the group, this function disables the host interrupt associated 
 * with the Chirp sensor device's INT line.
 */
void chbsp_group_io_interrupt_enable(ch_group_t *grp_ptr) {
}

/*!
 * \brief Enable the interrupt for one sensor
 *
 * \param dev_ptr	pointer to the ch_dev_t config structure for a sensor
 *
 * This function enables the host interrupt associated with the Chirp sensor device's 
 * INT line.
 */
void chbsp_io_interrupt_enable(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Disable interrupts for a group of sensors
 * 
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 *
 * For each sensor in the group, this function disables the host interrupt associated 
 * with the Chirp sensor device's INT line.
 */
void chbsp_group_io_interrupt_disable(ch_group_t *grp_ptr) {
}

/*!
 * \brief Disable the interrupt for one sensor
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function disables the host interrupt associated with the Chirp sensor device's 
 * INT line.
 */
void chbsp_io_interrupt_disable(ch_dev_t *dev_ptr) {
}

/*!
 * \brief Set callback routine for Chirp sensor I/O interrupt
 *
 * \param callback_func_ptr 	pointer to application function to be called when interrupt occurs
 *
 * This function sets up the specified callback routine to be called whenever the interrupt 
 * associated with the sensor's INT line occurs.  The callback routine address in stored in
 * a pointer variable that will later be accessed from within the interrupt handler to call 
 * the function.
 *
 * The callback function will be called at interrupt level from the interrupt 
 * service routine.
 */
void chbsp_io_callback_set(ch_io_int_callback_t callback_func_ptr) {
}


/*!
 * \brief Delay for specified number of microseconds
 * 
 * \param us  	number of microseconds to delay before returning
 *
 * This function waits for the specified number of microseconds before returning to 
 * the caller.
 */
void chbsp_delay_us(uint32_t us) {
}

/*!
 * \brief Delay for specified number of milliseconds.
 *
 * \param ms 	number of milliseconds to delay before returning
 *
 * This function waits for the specified number of milliseconds before returning to 
 * the caller.
 */
void chbsp_delay_ms(uint32_t ms) {
}

/*!
 * \brief Initialize the host's I2C hardware.
 *
 * \return 0 if successful, 1 on error
 *
 * This function performs general I2C initialization on the host system.
 */
int chbsp_i2c_init(void) { 
	return 0;
}

/*!
 * \brief Return I2C information for a sensor port on the board.
 *
 * \param grp_ptr 		pointer to the ch_group_t config structure for a group of sensors
 * \param dev_num		device number within sensor group
 * \param info_ptr		pointer to structure to be filled with I2C config values
 *
 * \return 0 if successful, 1 if error
 *
 * This function returns I2C values in the ch_i2c_info_t structure specified by \a info_ptr.
 * The structure includes three fields.  
 *  - The \a address field contains the I2C address for the sensor.  
 *  - The \a bus_num field contains the I2C bus number (index).  
 *  - The \a drv_flags field contains various bit flags through which the BSP can inform 
 *  SonicLib driver functions to perform specific actions during I2C I/O operations.
 */
uint8_t chbsp_i2c_get_info(ch_group_t __attribute__((unused)) *grp_ptr, uint8_t io_index, ch_i2c_info_t *info_ptr) {
	return 0;
}

/*!
 * \brief Write bytes to an I2C slave.
 * 
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 * \param data 			data to be transmitted
 * \param num_bytes 	length of data to be transmitted
 *
 * \return 0 if successful, 1 on error or NACK
 *
 * This function writes one or more bytes of data to an I2C slave device.
 * The I2C interface must have already been initialized using \a chbsp_i2c_init().
 */
int chbsp_i2c_write(ch_dev_t *dev_ptr, uint8_t *data, uint16_t num_bytes) {
	return 1;
}

/*!
 * \brief Write bytes to an I2C slave using memory addressing.
 * 
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 * \param mem_addr		internal memory or register address within device
 * \param data 			data to be transmitted
 * \param num_bytes 	length of data to be transmitted
 *
 * \return 0 if successful, 1 on error or NACK
 *
 * This function writes one or more bytes of data to an I2C slave device using an internal 
 * memory or register address.  The remote device will write \a num_bytes bytes of
 * data starting at internal memory/register address \a mem_addr.
 * The I2C interface must have already been initialized using \a chbsp_i2c_init().
 */
int chbsp_i2c_mem_write(ch_dev_t *dev_ptr, uint16_t mem_addr, uint8_t *data, uint16_t num_bytes) {
	return 1;
}

/*!
 * \brief Read bytes from an I2C slave.
 * 
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 * \param data 			pointer to receive data buffer
 * \param num_bytes 	number of bytes to read
 *
 * \return 0 if successful, 1 on error or NACK
 *
 * This function reads the specified number of bytes from an I2C slave device.
 * The I2C interface must have already been initialized using \a chbsp_i2c_init().
 */
int chbsp_i2c_read(ch_dev_t *dev_ptr, uint8_t *data, uint16_t num_bytes) {
	return 1;
}

/*!
 * \brief Read bytes from an I2C slave using memory addressing.
 * 
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 * \param mem_addr		internal memory or register address within device
 * \param data 			pointer to receive data buffer
 * \param num_bytes 	number of bytes to read
 *
 * \return 0 if successful, 1 on error or NACK
 *
 * This function reads the specified number of bytes from an I2C slave device, using
 * an internal memory or register address.  The remote device will return \a num_bytes bytes
 * starting at internal memory/register address \a mem_addr.
 *
 * The I2C interface must have already been initialized using \a chbsp_i2c_init().
 */
int chbsp_i2c_mem_read(ch_dev_t *dev_ptr, uint16_t mem_addr, uint8_t *data, uint16_t num_bytes) {
	return 1;
}

/*!
 * \brief Reset I2C bus associated with device.
 *
 * \param dev_ptr 		pointer to the ch_dev_t config structure for a sensor
 *
 * This function performs a reset of the I2C interface for the specified device.
 */
void chbsp_i2c_reset(ch_dev_t * dev_ptr) {
}

/*!
 * \brief Initialize periodic timer.
 *
 * \param interval_ms		timer interval, in milliseconds
 * \param callback_func_ptr	address of routine to be called every time the timer expires
 *
 * \return 0 if successful, 1 if error
 *
 * This function initializes a periodic timer on the board.  The timer is programmed 
 * to generate an interrupt after every \a interval_ms milliseconds.  
 *
 * The \a callback_func_ptr parameter specifies a callback routine that will be called when the 
 * timer expires (and interrupt occurs).  The \a chbsp_periodic_timer_handler function 
 * will call this function.
 */
uint8_t chbsp_periodic_timer_init(uint16_t interval_ms, ch_timer_callback_t callback_func_ptr) {
	return 0;
}

/*!
 * \brief Enable periodic timer interrupt.
 *
 * This function enables the interrupt associated with the periodic timer initialized by 
 * \a chbsp_periodic_timer_init().
 */
void chbsp_periodic_timer_irq_enable(void) {
}

/*!
 * \brief Disable periodic timer interrupt.
 *
 * This function enables the interrupt associated with the periodic timer initialized by 
 * \a chbsp_periodic_timer_init().
 */
void chbsp_periodic_timer_irq_disable(void) {
}

/*!
 * \brief Start periodic timer.
 *
 * \return 0 if successful, 1 if error
 *
 * This function starts the periodic timer initialized by \a chbsp_periodic_timer_init().
 */
uint8_t chbsp_periodic_timer_start(void) {
	return 0;
}

/*!
 * \brief Stop periodic timer.
 *
 * \return 0 if successful, 1 if error
 *
 * This function stops the periodic timer initialized by \a chbsp_periodic_timer_init().
 */
uint8_t chbsp_periodic_timer_stop(void) {
	return 0;
}

/*!
 * \brief Periodic timer handler.
 *
 * \return 0 if successful, 1 if error
 *
 * This function handles the expiration of the periodic timer, re-arms it and any associated 
 * interrupts for the next interval, and calls the callback routine that was registered using 
 * \a chbsp_periodic_timer_init().
 */
void chbsp_periodic_timer_handler(void) {
}

/*!
 * \brief Change the period for interrupts
 *
 * \param new_period_us		the new timer interval, in microseconds
 * 
 * This function manipulates the timer interval programmed for sensor interrupts. 
 */
void chbsp_periodic_timer_change_period(uint32_t new_period_us) {
}

/*!
 * \brief Put the processor into low-power sleep state.
 *
 * This function puts the host processor (MCU) into a low-power sleep mode, to conserve energy. 
 * The sleep state should be selected such that interrupts associated with the I2C, external 
 * GPIO pins, and the periodic timer (if used) are able to wake up the device.
 */
void chbsp_proc_sleep(void) {
}

/*!
 * \brief Turn on an LED on the board.
 *
 * This function turns on an LED on the board. 
 *
 * The \a dev_num parameter contains the device number of a specific sensor.  This routine
 * will turn on the LED on the Chirp sensor daughterboard that is next to the specified
 * sensor.
 */
void chbsp_led_on(uint8_t led_num) {
}

/*!
 * \brief Turn off an LED on the board.
 *
 * This function turns off an LED on the board. 
 *
 * The \a dev_num parameter contains the device number of a specific sensor.  This routine
 * will turn off the LED on the Chirp sensor daughterboard that is next to the specified
 * sensor.
 */
void chbsp_led_off(uint8_t led_num) {
}

/*!
 * \brief Toggle an LED on the board.
 *
 * This function toggles an LED on the board. It changes the on/off state from whatever it currently is. 
 * The implementation of this function is flexible to allow for different arrangements of LEDs.
 *
 * The \a dev_num parameter contains the device number of a specific sensor.  The device number 
 * may be used to select which LED should be toggled (e.g. if it is located next to an 
 * individual sensor).  If the board does not have LEDs associated with individual sensors, the 
 * BSP may implement this routine to combine all device numbers to control a single LED, or any 
 * other organization that makes sense for the board.
 */
void chbsp_led_toggle(uint8_t dev_num) {
}

/*!
 * \brief Output a text string via serial interface
 *
 * \param str	pointer to a string of characters to be output
 * 
 * This function prints debug information to the console.
 */
void chbsp_print_str(char *str) {
}



/************* End of file chbsp_chirp_smartsonic.c  --   Copyright 2016-2019 Chirp Microsystems **********/
