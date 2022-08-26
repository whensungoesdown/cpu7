////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	uartsim.h
// {{{
// Project:	wbuart32, a full featured UART with simulator
//
// Purpose:	To forward a Verilator simulated UART link over a TCP/IP pipe.
//
//	This file provides the description of the interface between the UARTSIM
//	and the rest of the world.  See below for more detailed descriptions.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2021, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
// }}}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <poll.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <signal.h>
#include <ctype.h>

#define	TXIDLE	0
#define	TXDATA	1
#define	RXIDLE	0
#define	RXDATA	1

class	UARTSIM	{
	// Member declarations
	// {{{
	// The file descriptors:
	//	m_skt   is the socket/port we are listening on
	//	m_conrd is the file descriptor to read from
	//	m_conwr is the file descriptor to write to
	int	m_skt, m_conrd, m_conwr;
	//
	// The m_setup register is the 29'bit control register used within
	// the core.
	unsigned m_setup;
	// And the pieces of the setup register broken out.
	int	m_nparity, m_fixdp, m_evenp, m_nbits, m_nstop, m_baud_counts;

	// UART state
	int	m_rx_baudcounter, m_rx_state, m_rx_busy,
		m_rx_changectr, m_last_tx;
	int	m_tx_baudcounter, m_tx_state, m_tx_busy;
	unsigned	m_rx_data, m_tx_data;
	// }}}

	// Private methods
	// {{{
	// setup_listener is an attempt to encapsulate all of the network
	// related setup stuff.
	void	setup_listener(const int port);

	// Call check_for_new_connections() to see if we can accept a new
	// network socket connection to our device
	void	check_for_new_connections(void);

	// nettick() gets called if we are connected to a network, and
	int	nettick(const int i_tx);
	int	fdtick(const int i_tx);
	int	rawtick(const int i_tx, const bool network);

	// We'll use the file descriptor for the listener socket to determine
	// whether we are connected to the network or not.  If not connected
	// to the network, then we assume m_conrd and m_conwr refer to 
	// your more traditional file descriptors, and use them as such.
	int	tick(const int i_tx) {
		return rawtick(i_tx, (m_skt >= 0));
	}
	// }}} 
    FILE *uart_out;
public:
	// Public member functions
	// {{{

	// UARTSIM(port)
	// {{{
	// The UARTSIM constructor takes one argument: the port on the
	// localhost to listen in on.  Once started, connections may be made
	// to this port to get the output from the port.
	UARTSIM(const int port, const char* uart_output_file);
	// }}}
    ~UARTSIM() {
        kill();
    }

	// kill(void)
	// {{{
	// kill() closes any active connection and the socket.  Once killed,
	// no further output will be sent to the port.
	void	kill(void);
	// }}}

	// setup(isetup)
	// {{{
	// setup() busts out the bits from isetup to the various internal
	// parameters.  It is ideally only called between bits at appropriate
	// transition intervals. 
	void	setup(unsigned isetup);
	// }}}

	// operator()(i_tx)
	// {{{
	// The operator() function is called on every tick.  The input is the
	// the output txuart transmit wire from the device.  The output is to
	// be connected to the the rxuart receive wire into the device.  This
	// makes hookup and operation very simple.
	//
	// This is the most appropriate simulation entry function if the 
	// setup register will never change.
	//
	int	operator()(int i_tx) {
		return tick(i_tx); }
	// }}}

	// operator()(i_tx, isetup)
	// {{{
	// If there is a possibility that the core might change the UART setup,
	// then it makes sense to include that current setup when calling the
	// tick operator.
	int	operator()(int i_tx, unsigned isetup) {
		setup(isetup); return tick(i_tx); }
	// }}}
	// }}}
};

void	UARTSIM::setup_listener(const int port) {
	struct	sockaddr_in	my_addr;

	signal(SIGPIPE, SIG_IGN);

	printf("Listening on port %d\n", port);

	m_skt = socket(AF_INET, SOCK_STREAM, 0);
	if (m_skt < 0) {
		perror("ERR: Could not allocate socket: ");
		exit(EXIT_FAILURE);
	}

	// Set the reuse address option
	{
		int optv = 1, er;
		er = setsockopt(m_skt, SOL_SOCKET, SO_REUSEADDR, &optv, sizeof(optv));
		if (er != 0) {
			perror("ERR: SockOpt Err:");
			exit(EXIT_FAILURE);
		}
	}

	memset(&my_addr, 0, sizeof(struct sockaddr_in)); // clear structure
	my_addr.sin_family = AF_INET;
	// Use *all* internet ports to this computer, allowing connections from
	// any/every one of them.
	my_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	my_addr.sin_port = htons(port);

	if (bind(m_skt, (struct sockaddr *)&my_addr, sizeof(my_addr))!=0) {
		perror("ERR: BIND FAILED:");
		exit(EXIT_FAILURE);
	}

	if (listen(m_skt, 1) != 0) {
		perror("ERR: Listen failed:");
		exit(EXIT_FAILURE);
	}
}
// }}}

// UARTSIM::UARTSIM(const int port)
// {{{
UARTSIM::UARTSIM(const int port, const char* uart_output_file) {
	m_conrd = m_conwr = m_skt = -1;
	if (port == 0) {
		m_conrd = STDIN_FILENO;
		m_conwr = STDOUT_FILENO;
	} else
		setup_listener(port);
	setup(25);	// Set us up for (default) 8N1 w/ a baud rate of CLK/25
	m_rx_baudcounter = 0;
	m_tx_baudcounter = 0;
	m_rx_state = RXIDLE;
	m_tx_state = TXIDLE;
    char uart_file_name[80];
    sprintf(uart_file_name, "%s.real", uart_output_file);
    //printf("file path is %s\n", uart_file_name);
    if((uart_out = fopen(uart_file_name, "w")) == NULL) {
        printf("Error: can not open uart log file!\n");
        exit(0);
    }
}
// }}}

// UARTSIM::kill
// {{{
void	UARTSIM::kill(void) {
	fflush(stdout);

	// Quickly double check that we aren't about to close stdin/stdout
	if (m_conrd == STDIN_FILENO)
		m_conrd = -1;
	if (m_conwr == STDOUT_FILENO)
		m_conwr = -1;
	// Close any active connection
	if (m_conrd >= 0)				close(m_conrd);
	if ((m_conwr >= 0)&&(m_conwr != m_conrd))	close(m_conwr);
	if (m_skt >= 0) close(m_skt);

	m_conrd = m_conwr = m_skt = -1;
    fflush(uart_out);
    fclose(uart_out);
}
// }}}

// UARTSIM::setup(isetup)
// {{{
void	UARTSIM::setup(unsigned isetup) {
	if (isetup != m_setup) {
		m_setup = isetup;
		m_baud_counts = (isetup & 0x0ffffff);
		m_nbits   = 8-((isetup >> 28)&0x03);
		m_nstop   =((isetup >> 27)&1)+1;
		m_nparity = (isetup >> 26)&1;
		m_fixdp   = (isetup >> 25)&1;
		m_evenp   = (isetup >> 24)&1;
	}
}
// }}}

// UARTSIM::check_for_new_connections
// {{{
void	UARTSIM::check_for_new_connections(void) {
	if ((m_conrd < 0)&&(m_conwr<0)&&(m_skt>=0)) {
		// Can we accept a connection?
		struct	pollfd	pb;

		pb.fd = m_skt;
		pb.events = POLLIN;
		poll(&pb, 1, 0);

		if (pb.revents & POLLIN) {
			m_conrd = accept(m_skt, 0, 0);
			m_conwr = m_conrd;

			if (m_conrd < 0)
				perror("Accept failed:");
			// else printf("New connection accepted!\n");
		}
	}

}
// }}}

// UARTSIM::rawtick(i_tx, network)
// {{{
int	UARTSIM::rawtick(const int i_tx, const bool network) {
	int	o_rx = 1, nr = 0;

	if (network)
		check_for_new_connections();

	if ((!i_tx)&&(m_last_tx))
		m_rx_changectr = 0;
	else	m_rx_changectr++;
	m_last_tx = i_tx;

	if (m_rx_state == RXIDLE) {
		if (!i_tx) {
            //printf("run here!\n");
			m_rx_state = RXDATA;
			m_rx_baudcounter =m_baud_counts+m_baud_counts/2-1;
			m_rx_baudcounter -= m_rx_changectr;
			m_rx_busy    = 0;
			m_rx_data    = 0;
		}
	} else if (m_rx_baudcounter <= 0) {
		if (m_rx_busy >= (1<<(m_nbits+m_nparity+m_nstop-1))) {
			m_rx_state = RXIDLE;
			if (m_conwr >= 0) {
				char	buf[1];
				buf[0] = (m_rx_data >> (32-m_nbits-m_nstop-m_nparity))&0x0ff; 
                //printf("uart output: %c\n", buf[0]);
                fprintf(uart_out, "%c", buf[0]);
				if ((network)&&(1 != send(m_conwr, buf, 1, 0))) {
					close(m_conwr);
					m_conrd = m_conwr = -1;
					fprintf(stderr, "Failed write, connection closed\n");
				} else if ((!network)
                           #ifdef OUTPUT_UART_INFO
                           && (1 != write(m_conwr, buf, 1))
                           #endif
                           ) {
					fprintf(stderr, "ERR while attempting to write out--closing output port\n");
					perror("UARTSIM::write() ");
					m_conrd = m_conwr = -1;
				}
			}
		} else {
			m_rx_busy = (m_rx_busy << 1)|1;
			// Low order bit is transmitted first, in this
			// order:
			//	Start bit (1'b1)
			//	bit 0
			//	bit 1
			//	bit 2
			//	...
			//	bit N-1
			//	(possible parity bit)
			//	stop bit
			//	(possible secondary stop bit)
			m_rx_data = ((i_tx&1)<<31) | (m_rx_data>>1);
            //printf("m_rx_data val is %x\n", m_rx_data);
		} m_rx_baudcounter = m_baud_counts-1;
	} else {
		m_rx_baudcounter--;
        //printf("m_rx_data val is %x\n", m_rx_data);
        //printf("m_rx_baudcounter is %d\n", m_rx_baudcounter);
    }

	if ((m_tx_state == TXIDLE)&&((network)||(m_conrd >= 0))) {
		struct	pollfd	pb;
		pb.fd = m_conrd;
		pb.events = POLLIN;
		if (poll(&pb, 1, 0) < 0)
			perror("Polling error:");

		if (pb.revents & POLLIN) {
			char	buf[1];

			if (network)
				nr = recv(m_conrd, buf, 1, MSG_DONTWAIT);
			else {
				nr = read(m_conrd, buf, 1);
                //printf("get char: %c\n", buf[0]);
            }
			if (1 == nr) {
				m_tx_data = (-1<<(m_nbits+m_nparity+1))
					// << nstart_bits
					|((buf[0]<<1)&0x01fe);
				if (m_nparity) {
					int	p;

					// If m_nparity is set, we need to then
					// create the parity bit.
					if (m_fixdp)
						p = m_evenp;
					else {
						p = (m_tx_data >> 1)&0x0ff;
						p = p ^ (p>>4);
						p = p ^ (p>>2);
						p = p ^ (p>>1);
						p &= 1;
						p ^= m_evenp;
					}
					m_tx_data |= (p<<(m_nbits+m_nparity));
				}
				m_tx_busy = (1<<(m_nbits+m_nparity+m_nstop+1))-1;
				m_tx_state = TXDATA;
				o_rx = 0;
				m_tx_baudcounter = m_baud_counts-1;
			} else if ((network)&&(nr == 0)) {
				close(m_conrd);
				m_conrd = m_conwr = -1;
				// printf("Closing network connection\n");
			} else if (nr < 0) {
				if (!network) {
					fprintf(stderr, "ERR while attempting to read in--closing input port\n");
					perror("UARTSIM::read() ");
					m_conrd = -1;
				} else {
					perror("O/S Read err:");
					close(m_conrd);
					m_conrd = m_conwr = -1;
				}
			}
		}
	} else if (m_tx_baudcounter <= 0) {
		m_tx_data >>= 1;
		m_tx_busy >>= 1;
		if (!m_tx_busy)
			m_tx_state = TXIDLE;
		else
			m_tx_baudcounter = m_baud_counts-1;
		o_rx = m_tx_data&1;
	} else {
		m_tx_baudcounter--;
		o_rx = m_tx_data&1;
	}

	return o_rx;
}
// }}}

// UARTSIM::nettick
// {{{
int	UARTSIM::nettick(const int i_tx) {
	return rawtick(i_tx, true);
}
// }}}

// UARTSIM::fdtick
// {{{
int	UARTSIM::fdtick(const int i_tx) {
	return rawtick(i_tx, false);
}
// }}}

