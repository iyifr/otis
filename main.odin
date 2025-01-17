package otis

import "core:bytes"
import "core:fmt"
import "core:net"
import "core:os"
import "core:strings"

PORT :: 6379

main :: proc() {

	endpoint := net.Endpoint {
		address = net.IP4_Loopback,
		port    = PORT,
	}

	listen_socket, listen_err := net.listen_tcp(endpoint)

	if listen_err != nil {
		fmt.printf("Error occured binding to an address: %s\n", listen_err)
		if (listen_err == net.Bind_Error.Address_In_Use) {
			os.exit(1)
		}
	}

	fmt.printf("Server listening on port: %d\n", endpoint.address)


	for {
		client_socket, client_addr, client_accept_error := net.accept_tcp(listen_socket)

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

			received_str := string(data_in_bytes[:bytes_received])

			str := "+OK\r\n"

			// Echo back to client
			_, send_err := net.send_tcp(client_socket, transmute([]byte)str)

			if send_err != nil {
				fmt.printf("Error sending response: %s\n", send_err)
				break
			}
		}
	}
}
