package otis

import "core:bufio"
import "core:bytes"
import "core:fmt"
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

CRLF: []byte : {'\r', '\n'}

Parser :: struct {
	data: []byte,
	pos:  int,
}

OtisCmd :: struct {
	type:  string,
	str:   string,
	num:   int,
	bulk:  string,
	array: []OtisCmd,
}

load_up_parser_state :: proc(p: ^Parser, data: []byte) {
	{
		p.data = data
		p.pos = 0
	}
}

parse_resp_v2 :: proc(p: ^Parser, data: []byte) {
	load_up_parser_state(p, data)
}

main :: proc() {
	string_reader := strings.Reader {
		s = "$5\r\nAhmed\r\n",
	}

	buffer := bytes.Buffer{}
	

	b, err := strings.reader_read_byte(&string_reader)

	if (err != nil) {
		fmt.panicf("Failed to read buffer")
	}

	bytes.buffer_write_byte(&buffer, b)

	if b != '$' {
		fmt.println("Invalid type, expecting bulk strings only")
		os.exit(1)
	}


	fmt.printfln("byte val:%s", bytes.buffer_to_bytes(&buffer))
}
