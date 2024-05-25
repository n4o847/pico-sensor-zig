cmake_minimum_required(VERSION 3.13)

include(pico-sdk/pico_sdk_init.cmake)

project(pico-sensor-zig)

pico_sdk_init()

add_executable(pico_sensor)

target_include_directories(pico_sensor
                           PRIVATE ${CMAKE_CURRENT_LIST_DIR}/include)

target_link_libraries(
  pico_sensor pico_stdlib pico_cyw43_arch_lwip_threadsafe_background
  pico_lwip_mqtt ${CMAKE_SOURCE_DIR}/zig-out/pico_sensor.o)

pico_add_extra_outputs(pico_sensor)
