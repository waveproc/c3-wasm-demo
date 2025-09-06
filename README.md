# C3 wasm demo

Examples of C3 apps running in the web browser with WebAssembly.

The web version uses [zozlib.js](https://github.com/tsoding/zozlib.js) which is a simple reimplementation of a Subset of Raylib API in JavaScript for WebAssembly.

## Building the web version

- Install c3c and add it to your PATH environment variable.
- Install npm and enable pnpm.
- ```
    c3c compile ...
    pnpx live-server
    ```

- Open <http://127.0.0.1:8080>
