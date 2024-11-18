package otis

import "core:bytes"
import "core:fmt"
import "core:net"
import "core:strings"

PORT :: 6379

main :: proc() {
	listen_socket, listen_err := net.listen_tcp(
		net.Endpoint{address = net.IP4_Loopback, port = PORT},
	)

	if listen_err != nil {
		fmt.printf("Listen error: %s\n", listen_err)
	}

	client_socket, _, client_accept_error := net.accept_tcp(listen_socket)

	if client_accept_error != nil {
		fmt.printf("Accept error: %s", client_accept_error)
	}

	fmt.printfln("Server live on port: %v", PORT)
	handleClient(client_socket)
}

handleClient :: proc(client_socket: net.TCP_Socket) {
	// This loops till our client wants to disconnect
	for {
		// allocating memory for our data
		data_in_bytes := make([]byte, 1024)
		defer delete(data_in_bytes)

		bytes_received, err := net.recv_tcp(client_socket, data_in_bytes[:])

		if err != nil {
			fmt.printf("error while receiving data: %s", err)
			break
		}

		if bytes_received == 0 {
			fmt.println("Connection closed by client")
			break
		}

		// Check for exit command
		exit_code := "exit\r\n"
		received_str := strings.clone_from_bytes(data_in_bytes[:bytes_received], context.allocator)

		if strings.has_prefix(received_str, exit_code) {
			fmt.println("Connection ended")
			break
		}

		// Clone only the received bytes, not the entire buffer
		if data, err := strings.clone_from_bytes(
			data_in_bytes[:bytes_received],
			context.allocator,
		); err == nil {
			net.send_tcp(client_socket, transmute([]u8)data)
			fmt.println("client said:", data)
			defer delete(data)
		} else {
			fmt.eprintln("Error converting bytes to string:", err)
		}

	}
}
