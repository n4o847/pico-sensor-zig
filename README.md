# pico-sensor-zig

## server

1. Install Docker

2. Run containers
   ```bash
   cd server
   docker compose up -d
   ```

## sensor-pico-sdk

1. Install [Zig](https://ziglang.org/) (at least version 0.12)

2. Install CMake (at least version 3.13), and GCC cross compiler
    ```bash
    sudo apt install cmake gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib
    ```

3. Initialize submodules
   ```bash
   cd sensor-pico-sdk
   git submodule update --init
   cd pico-sdk
   git submodule update --init
   cd ..
   ```

4. Build the project
   ```bash
   zig build --release=small
   ```

5. Run the program on your Raspberry Pi Pico W in either way
   - Load build/pico_sensor.elf on your Pico via a debugger
   - Press and hold the BOOTSEL button, and plug your Pico into your computer. Then drag and drop build/pico_sensor.uf2 onto the RPI-RP2 drive

## sensor-microzig

Work in progress because [MicroZig](https://github.com/ZigEmbeddedGroup/microzig) does not currently support Pico W.
