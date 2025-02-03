package resp_parser

import "core:testing"
@(test)
test_parser :: proc(t: ^testing.T) {
	n := 2 + 2

	testing.expect(t, ok = n == 4, msg = "")
}
