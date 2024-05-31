const c = @cImport({
    @cInclude("pico/stdlib.h");
    @cInclude("hardware/uart.h");
});

pub const UART: *c.uart_inst_t = @ptrCast(c.uart1_hw); // workaround

pub const UART_TX_PIN = 4;
pub const UART_RX_PIN = 5;

pub fn init() void {
    const actual_baudrate = c.uart_init(UART, 9600);
    _ = actual_baudrate;
    c.uart_set_format(UART, 8, 1, c.UART_PARITY_NONE);

    c.gpio_set_function(UART_TX_PIN, c.GPIO_FUNC_UART);
    c.gpio_set_function(UART_RX_PIN, c.GPIO_FUNC_UART);

    // workaround from here
    drain();
    c.sleep_ms(100);
    enable_self_calibration();
    c.sleep_ms(100);
    _ = read_co2_concentration();
    c.sleep_ms(100);
    // workaround to here
}

pub fn deinit() void {
    c.uart_deinit(UART);
}

pub fn drain() void {
    while (c.uart_is_readable(UART)) {
        var data: u8 = undefined;
        c.uart_read_blocking(UART, &data, 1);
    }
}

fn send(packet: *const [8]u8) void {
    const checksum = calculate_checksum(packet);
    c.uart_write_blocking(UART, packet, packet.len);
    c.uart_write_blocking(UART, &checksum, 1);
}

fn receive() [8]u8 {
    var packet: [8]u8 = undefined;
    var checksum: u8 = undefined;
    c.uart_read_blocking(UART, &packet, packet.len);
    c.uart_read_blocking(UART, &checksum, 1);
    // calculate_checksum(&packet) == checksum;
    return packet;
}

fn read_co2_concentration_send() void {
    const command: [8]u8 = .{ 0xff, 0x01, 0x86, 0x00, 0x00, 0x00, 0x00, 0x00 };
    send(&command);
}

fn read_co2_concentration_receive() u16 {
    const response = receive();
    const high = response[2];
    const low = response[3];
    return @as(u16, high) * 256 + @as(u16, low);
}

pub fn read_co2_concentration() u16 {
    read_co2_concentration_send();
    return read_co2_concentration_receive();
}

pub fn enable_self_calibration() void {
    const command: [8]u8 = .{ 0xff, 0x01, 0x79, 0xa0, 0x00, 0x00, 0x00, 0x00 };
    send(&command);
}

pub fn disable_self_calibration() void {
    const command: [8]u8 = .{ 0xff, 0x01, 0x79, 0x00, 0x00, 0x00, 0x00, 0x00 };
    send(&command);
}

fn calculate_checksum(packet: []const u8) u8 {
    var sum: u8 = 0;
    for (1..8) |i| {
        sum +%= packet[i];
    }
    sum = 0xff -% sum;
    return sum +% 0x01;
}

test {
    const std = @import("std");
    const bytes: []const u8 = &.{ 0xff, 0x01, 0x86, 0x00, 0x00, 0x00, 0x00, 0x00 };
    try std.testing.expectEqual(0x79, calculate_checksum(bytes));
}
