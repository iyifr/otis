package resp_parser

import "core:bufio"
import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:strconv"
import "core:strings"

SIMPLE_STRING :: '+'
ERROR :: '-'
BULKSTRING :: '$'
ARRAY :: '*'
INTEGER :: ':'

RESP_Error_Codes :: enum u32 {
	NONE,
	INVALID_INPUT,
	UNEXPECTED_EOF,
	PROTOCOL_ERROR,
}

CRLF: []byte : transmute([]byte){'\r', '\n'}

Parser :: struct {
	data: []byte,
	pos:  int,
}

OtisCmdGrp :: struct {
	type:  string,
	str:   string,
	num:   int,
	bulk:  string,
	array: []OtisCmdGrp,
}

OtisDBCmd :: struct {
	// Cmd represents the command to execute (e.g., "SET", "GET", "DEL").
	// This is the main command keyword that specifies the action to perform
	// in OtisDB. For example:
	// - "SET": To store a value.
	// - "GET": To retrieve a value.
	// - "DEL": To delete a value.
	// - "EXPIRE": To set a time-to-live for a key.
	Cmd:  string,

	// Args holds any additional parameters required by the command.
	// For example:
	// - If Cmd is "SET", Args might contain ["key", "value"].
	// - If Cmd is "EXPIRE", Args might contain ["key", "seconds"].
	// This slice allows flexible support for commands with variable arguments.
	Args: []string,
}

init_parser_state :: proc(p: ^Parser, data: []byte) {
	p.data = data
	p.pos = 0
}


readLine :: proc(p: ^Parser) -> ([]byte, RESP_Error_Codes) {
	if p.pos >= len(p.data) {
		return nil, RESP_Error_Codes.UNEXPECTED_EOF
	}

	end := bytes.index(p.data[p.pos:], CRLF)

	if end == -1 {
		return nil, RESP_Error_Codes.UNEXPECTED_EOF
	}

	line := p.data[p.pos:p.pos + end]
	p.pos += end + 2
	return line, nil
}

readLineAsString :: proc(p: ^Parser) -> (val: string, error: RESP_Error_Codes) {
	line, err := readLine(p)

	if err != nil {
		return "", err
	}

	return string(line), err
}


demo :: proc() {
	string_reader := strings.Reader {
		s = "$9\r\nIyimideiyi\r\n",
	}

	b, _ := strings.reader_read_byte(&string_reader)


	if b != '$' {
		fmt.println("Invalid type, expecting bulk strings only")
		os.exit(1)
	}

	size, _ := strings.reader_read_byte(&string_reader)

	strSize, ok := strconv.parse_int(string([]byte{size}), 10)

	if (ok) {
		fmt.println("Ok!")
	}
	fmt.printfln("size is - %i", strSize)

	strings.reader_read_byte(&string_reader)
	strings.reader_read_byte(&string_reader)

	name := make([]byte, strSize)
	defer delete(name)

	strings.reader_read(&string_reader, name)
	fmt.printfln("byte val:%s", transmute(string)name)
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	s := new(string, context.temp_allocator)

	// Read into the pointer returned by new()
	s^ = "$9\r\nIyimideiyi\r\n"

	byteArray := transmute([]byte)s^

	resp_instance := Parser {
		data = byteArray,
		pos  = 0,
	}

	line1, error := readLineAsString(&resp_instance)

	fmt.println(line1)

}
