# pico-sensor-zig

## server

1. Install Docker

2. Set environment variables
   1. Copy server/.env.example to server/.env
   2. Set variables
      | key | value |
      |---|---|
      | `GRAFANA_PORT` | port for Grafana |
      | `DOCKER_INFLUXDB_INIT_MODE` | `setup` |
      | `DOCKER_INFLUXDB_INIT_USERNAME` | username for InfluxDB |
      | `DOCKER_INFLUXDB_INIT_PASSWORD` | password for InfluxDB |
      | `DOCKER_INFLUXDB_INIT_ORG` | organization name for InfluxDB |
      | `DOCKER_INFLUXDB_INIT_BUCKET` | bucket name for InfluxDB |
      | `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` | (described later) |

3. Run the InfluxDB container
   ```bash
   cd server
   docker compose up influxdb
   ```

3. Set the token and restart
   1. Open server/influxdb/config/influx-configs and copy the token
   2. Set `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` in server/.env
   3. Press Ctrl+C to stop the InfluxDB container
   4. Run all containers
      ```bash
      docker compose up -d
      ```

4. Configure Grafana
   1. Log in
      1. If `GRAFANA_PORT` is set to `3000` for example, open http://localhost:3000/
      2. Enter `admin` for username and password, and log in
      3. Change your password (recommended)
   2. Connect InfluxDB
      1. Open "Connections" > "Data sources"
      2. Click "Add new data source" and select "InfluxDB"
      3. Fill in the form
         - HTTP
           - URL: `http://influxdb:8086`
         - Auth
           - Custom HTTP Headers
             - Header: `Authorization`, Value: `Token <INFLUXDB_TOKEN>` (replace `<INFLUXDB_TOKEN>` with the token for InfluxDB)
         - InfluxDB Details
           - Database: bucket name for InfluxDB
           - User: username for InfluxDB
           - Password: password for InfluxDB

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
