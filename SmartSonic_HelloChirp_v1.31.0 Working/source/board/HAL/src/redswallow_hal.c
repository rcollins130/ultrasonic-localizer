/*
 * ________________________________________________________________________________________________________
 * Copyright (c) 2019-2019 InvenSense Inc. All rights reserved.
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

#include <stdbool.h>
#include <asf.h>
#include <delay.h>
#include <string.h>

#include "inv_uart.h"
#include "time.h"
#include "redswallow.h"
#include "redswallow_hal.h"

/* This file defines an UART backend implementation for the protocol for the Atmel MCU */

/* Private singleton */
static struct UartManager {
	uint8_t* new_bytes_buffer;
	volatile uint32_t new_bytes_buffer_idx;
	size_t new_bytes_buffer_size;

	volatile bool tx_done;
} uart_mngr = {0};

static uint8_t uart_rx_buffer;
/* Debug purpose */
static uint32_t uart_rx_cnt = 0;
static uint32_t uart_tx_cnt = 0;

/* Public functions */
void redswallow_hal_init(uint8_t* new_bytes_buffer, size_t new_bytes_buffer_size)
{
	memset(&uart_mngr, 0, sizeof(uart_mngr));

	uart_mngr.new_bytes_buffer = new_bytes_buffer;
	uart_mngr.new_bytes_buffer_size = new_bytes_buffer_size;

	uart_init(USE_RTS_CTS, &uart_rx_buffer);

	uart_mngr.tx_done = true;
}

void redswallow_hal_new_input_bytes(void)
{
	cpu_irq_enter_critical();
	redswallow_new_input_bytes(uart_mngr.new_bytes_buffer, uart_mngr.new_bytes_buffer_idx);
	uart_mngr.new_bytes_buffer_idx = 0;
	cpu_irq_leave_critical();
}

bool redswallow_hal_send(const uint8_t *data, size_t len)
{
	uint64_t t_start_send;

	t_start_send = time_get_in_us();
	do {
		/* Check send time-out */
		if ((time_get_in_us() - t_start_send) > REDSWALLOW_HAL_SEND_TIME_OUT_US) {
			uart_mngr.tx_done = false;
			return false;
		}

	} while(!uart_mngr.tx_done);
	uart_mngr.tx_done = false;
	uart_dma_puts(data, len);
	return true;
}

void redswallow_hal_delay_us(uint32_t delay_us)
{
	delay_us(delay_us);
}

/* Atmel USART IRQ Handler */
void FLEXCOM0_Handler(void)
{
	uint32_t ul_status;

	/* Read USART Status. */
	ul_status = usart_get_status(USART0);

	if((ul_status &  US_CSR_ENDRX ))
	{
		uart_rx_cnt++;
		if (uart_mngr.new_bytes_buffer_idx < uart_mngr.new_bytes_buffer_size) {
			uart_mngr.new_bytes_buffer[uart_mngr.new_bytes_buffer_idx] = uart_rx_buffer;
			uart_mngr.new_bytes_buffer_idx++;
		}
		else {
			redswallow_log_error("PROTOCOL_ERROR uart_mngr.new_bytes_buffer full");
		}

		uart_hal_new_char_callback();
		uart_dma_getc(&uart_rx_buffer, 1);
	}
	if((ul_status &  US_CSR_ENDTX ))
	{
		uart_tx_cnt++;
		uart_mngr.tx_done = true;
		usart_disable_interrupt(USART0, US_IER_ENDTX);
	}
}

void redswallow_hal_packet_lock(void)
{
}

void redswallow_hal_packet_unlock(void)
{
}
