#!/usr/bin/ruby

require 'wiringpi'

gpio = WiringPi::GPIO.new

# Set pin modes
gpio.mode 0, OUTPUT
gpio.mode 1, OUTPUT
gpio.mode 2, OUTPUT
gpio.mode 3, OUTPUT

# Array of pins that we're using
# (and the current 'on' index — for sequential patterns)
pins = [0, 1, 4, 3]

# Turn off all the LEDs
def lights_off(gpio, pins)

  pins.each do |p|
    gpio.write p, 0
  end

end

# Turn on all the LEDs
def lights_on(gpio, pins)

  pins.each do |p|
    gpio.write p, 1
  end

end

# Blink the bulbs in succession
# repeat = number of times to run the sequence
# speed = time (in seconds) to wait before
# lighting the next bulb in sequence
def run_lights(gpio, pins, repeat = 1, speed = 0.05)

  pin_index = 0
  # This will run 'repeat' times number of pins so that we get
  # 'repeat' complete sequences
  (1..repeat * pins.length).each do

    # Loop through each of the pins we're using
    pins.each do |p|

      if pins[pin_index] == p
        gpio.write p, 1
      else
        gpio.write p, 0
      end

    end # pins.each

    if pin_index == pins.length - 1
      pin_index = 0
    else
      pin_index += 1
    end

    sleep speed

  end

  lights_off(gpio, pins)

end

# Blink the bulbs together
# repeat = number of times to run the sequence
# speed = time (in seconds) to wait before
# lighting the next bulb in sequence
def blink_lights(gpio, pins, repeat = 1, speed = 0.05)

  state = 0
  (1..repeat*2).each do

    # Loop through each of the pins we're using
    pins.each do |p|
      gpio.write p, 1 - state
    end

    state = 1 - state

    sleep speed

  end

  lights_off(gpio, pins)

end

# Complete sequence to run when a barcode lookup succeeds
def victory_dance(gpio, pins)
  run_lights(gpio, pins, 5, 0.1)
  blink_lights(gpio, pins, 5, 0.1)
end

# Sad little error light
def blink_error(gpio)
  blink_lights(gpio, Array(1), 5, 0.3)
end

#victory_dance(gpio, pins)
#run_lights(gpio, pins, 10, speed = 0.5)
#blink_error(gpio)
