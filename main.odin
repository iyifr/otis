package otis

import "core:bytes"
import "core:fmt"
import "core:net"
import "core:os"
import "core:strings"
import "core:time"

PORT :: 6379

SERVER_TIMEOUT :: 500 * time.Second

main :: proc() {

	endpoint := net.Endpoint {
		address = net.IP4_Loopback,
		port    = PORT,
	}

	listen_socket, listen_err := net.listen_tcp(endpoint)

rao
	if listen_err != nil {
		fmt.printf("Error occured binding to an address: %s\n", listen_err)
		if (listen_err == net.Bind_Error.Address_In_Use) {
			os.exit(1)
		}
	}

	fmt.printf("Server listening on port: %d\n", endpoint.address)


	for {
		client_socket, client_addr, client_accept_error := net.accept_tcp(listen_socket)
		net.set_option(client_socket, net.Socket_Option.Receive_Timeout, SERVER_TIMEOUT)
		net.set_option(client_socket, net.Socket_Option.Send_Timeout, SERVER_TIMEOUT)

		if client_accept_error != nil {
			fmt.printf("Accept error: %s\n", client_accept_error)
			break
		}

		fmt.printf("New client connected from: %v\n", client_addr)
		handleClient(client_socket, client_addr)
	}
}

handleClient :: proc(client_socket: net.TCP_Socket, client_addr: net.Endpoint) {
	defer net.close(client_socket)

	for {
		data_in_bytes := make([]byte, 1024)
		defer delete(data_in_bytes)

		bytes_received, err := net.recv_tcp(client_socket, data_in_bytes[:])

		if err != nil {
			fmt.printf("Error while receiving data: %s\n", err)
			break
		}

		if bytes_received == 0 {
			fmt.printf("Client at port %d disconnected.\n", client_addr.port)
			break
		} else {
			fmt.printfln("Number of bytes recieved: %d", bytes_received)

			bytes_written, send_err := write_message_with_delimiter(
				client_socket,
				data_in_bytes[:bytes_received],
				200,
			)

			fmt.printfln("Total bytes written: %d", bytes_written)

			if send_err != nil {
				fmt.printf("Error sending response: %s\n", send_err)
				break
			}
		}
	}
}

write_all :: proc(
	socket: net.TCP_Socket,
	message: []u8,
) -> (
	bytes_written: int,
	err: net.TCP_Send_Error,
) {
	return net.send_tcp(socket, message[:])
}

write_message_with_delimiter :: proc(
	socket: net.TCP_Socket,
	message: []u8,
	delimiter: u8,
) -> (
	bytes_written: int,
	message_send_err: net.TCP_Send_Error,
) {
	no_of_bytes_written, err := write_all(socket, message)
	fmt.printfln("No of bytes to echo back: %d", no_of_bytes_written)
	fmt.printfln("Bytes echoed back: %d", message)

	if (err != nil) {
		return no_of_bytes_written, err
	}

	delim: u8 = 0102
	delim_bytes_no, delim_send_err := net.send_tcp(socket, []byte{delim})

	fmt.printfln("Delim bytes no: %d", delim_bytes_no)
	fmt.printfln("Bytes echoed back: %d", []byte{delim})

	if (delim_send_err != nil) {
		fmt.printfln("ERROR")
		return no_of_bytes_written + delim_bytes_no, delim_send_err
	}

	return no_of_bytes_written + delim_bytes_no, nil
}
