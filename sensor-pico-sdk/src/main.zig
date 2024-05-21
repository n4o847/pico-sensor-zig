const c = @cImport({
    @cInclude("pico/stdlib.h");
    @cInclude("pico/cyw43_arch.h");
});

export fn main() c_int {
    if (c.cyw43_arch_init() != 0) {
        return -1;
    }
    while (true) {
        c.cyw43_arch_gpio_put(c.CYW43_WL_GPIO_LED_PIN, true);
        c.sleep_ms(250);
        c.cyw43_arch_gpio_put(c.CYW43_WL_GPIO_LED_PIN, false);
        c.sleep_ms(250);
    }
    return 0;
}
