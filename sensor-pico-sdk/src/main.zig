const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("stdio.h");

    @cInclude("pico/stdlib.h");
    @cInclude("pico/cyw43_arch.h");

    @cInclude("lwip/apps/mqtt.h");
});

const config = @cImport({
    @cInclude("config.h");
});

fn show_pico_error_code(err: c_int) []const u8 {
    return switch (err) {
        c.PICO_OK => "PICO_OK",
        c.PICO_ERROR_TIMEOUT => "PICO_ERROR_TIMEOUT",
        c.PICO_ERROR_GENERIC => "PICO_ERROR_GENERIC",
        c.PICO_ERROR_NO_DATA => "PICO_ERROR_NO_DATA",
        c.PICO_ERROR_NOT_PERMITTED => "PICO_ERROR_NOT_PERMITTED",
        c.PICO_ERROR_INVALID_ARG => "PICO_ERROR_INVALID_ARG",
        c.PICO_ERROR_IO => "PICO_ERROR_IO",
        c.PICO_ERROR_BADAUTH => "PICO_ERROR_BADAUTH",
        c.PICO_ERROR_CONNECT_FAILED => "PICO_ERROR_CONNECT_FAILED",
        c.PICO_ERROR_INSUFFICIENT_RESOURCES => "PICO_ERROR_INSUFFICIENT_RESOURCES",
        else => "???",
    };
}

fn show_mqtt_connection_status(err: c.mqtt_connection_status_t) []const u8 {
    return switch (err) {
        c.MQTT_CONNECT_ACCEPTED => "MQTT_CONNECT_ACCEPTED",
        c.MQTT_CONNECT_REFUSED_PROTOCOL_VERSION => "MQTT_CONNECT_REFUSED_PROTOCOL_VERSION",
        c.MQTT_CONNECT_REFUSED_IDENTIFIER => "MQTT_CONNECT_REFUSED_IDENTIFIER",
        c.MQTT_CONNECT_REFUSED_SERVER => "MQTT_CONNECT_REFUSED_SERVER",
        c.MQTT_CONNECT_REFUSED_NOT_AUTHORIZED_ => "MQTT_CONNECT_REFUSED_NOT_AUTHORIZED_",
        c.MQTT_CONNECT_REFUSED_USERNAME_PASS => "MQTT_CONNECT_REFUSED_USERNAME_PASS",
        c.MQTT_CONNECT_DISCONNECTED => "MQTT_CONNECT_DISCONNECTED",
        c.MQTT_CONNECT_TIMEOUT => "MQTT_CONNECT_TIMEOUT",
        else => "???",
    };
}

const mqtt_client_info = c.mqtt_connect_client_info_t{
    .client_id = "pico_w",
    .client_user = null,
    .client_pass = null,
    .keep_alive = 100,
    .will_topic = null,
    .will_msg = null,
    .will_qos = 0,
    .will_retain = 0,
};

fn make_ip4_addr(a0: u8, a1: u8, a2: u8, a3: u8) u32 {
    return @as(u32, a0) | (@as(u32, a1) << 8) | (@as(u32, a2) << 16) | (@as(u32, a3) << 24);
}

fn mqtt_incoming_publish_cb(arg: ?*anyopaque, topic: [*c]const u8, tot_len: u32) callconv(.C) void {
    const client_info: *c.mqtt_connect_client_info_t = @ptrCast(@alignCast(arg));

    _ = c.printf("MQTT client \"%s\" publish cb: topic %s, len %d\n", client_info.client_id, topic, tot_len);
}

fn mqtt_incoming_data_cb(arg: ?*anyopaque, data: [*c]const u8, len: u16, flags: u8) callconv(.C) void {
    const client_info: *c.mqtt_connect_client_info_t = @ptrCast(@alignCast(arg));
    _ = data;

    _ = c.printf("MQTT client \"%s\" data cb: len %d, flags %d\n", client_info.client_id, len, flags);
}

fn mqtt_connection_cb(client: ?*c.mqtt_client_t, arg: ?*anyopaque, status: c.mqtt_connection_status_t) callconv(.C) void {
    const client_info: *c.mqtt_connect_client_info_t = @ptrCast(@alignCast(arg));
    _ = client;

    _ = c.printf("MQTT client \"%s\" connection cb: status %s\n", client_info.client_id, show_mqtt_connection_status(status).ptr);

    // if (status == c.MQTT_CONNECT_ACCEPTED) {}
}

export fn main() c_int {
    _ = c.stdio_init_all();

    if (c.cyw43_arch_init() != 0) {
        _ = c.printf("Failed to initialize\n");
        return c.EXIT_FAILURE;
    }

    c.cyw43_arch_enable_sta_mode();

    _ = c.printf("Connecting to Wi-Fi...\n");
    {
        const err = c.cyw43_arch_wifi_connect_timeout_ms(config.WIFI_SSID, config.WIFI_PASSWORD, c.CYW43_AUTH_WPA2_AES_PSK, 30000);
        if (err != c.PICO_OK) {
            _ = c.printf("Failed to connect (%s)\n", show_pico_error_code(err).ptr);
            return c.EXIT_FAILURE;
        } else {
            _ = c.printf("Connected\n");
        }
    }

    const mqtt_client = c.mqtt_client_new() orelse {
        _ = c.printf("Failed to create client\n");
        return c.EXIT_FAILURE;
    };

    c.mqtt_set_inpub_callback(mqtt_client, mqtt_incoming_publish_cb, mqtt_incoming_data_cb, @constCast(&mqtt_client_info));

    const ip_addr = c.ip4_addr_t{ .addr = config.BROKER_IP_ADDR };
    const port = 1883;
    {
        const err = c.mqtt_client_connect(mqtt_client, &ip_addr, port, mqtt_connection_cb, @constCast(&mqtt_client_info), &mqtt_client_info);
        if (err != c.ERR_OK) {
            _ = c.printf("Failed to connect to broker (%d)\n", err);
        }
    }

    while (true) {
        c.cyw43_arch_gpio_put(c.CYW43_WL_GPIO_LED_PIN, true);
        c.sleep_ms(250);
        c.cyw43_arch_gpio_put(c.CYW43_WL_GPIO_LED_PIN, false);
        c.sleep_ms(250);
    }

    c.cyw43_arch_deinit();

    return c.EXIT_SUCCESS;
}
