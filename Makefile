demo.wasm: demo.c3
	c3c compile -D PLATFORM_WEB --reloc=none --target wasm32 -O3 -g0 --link-libc=no --use-stdlib=no --no-entry -o demo -z --export-table demo.c3 raylib.c3

demo.wat: demo.wasm
	wasm2wat demo.wasm > demo.wat
