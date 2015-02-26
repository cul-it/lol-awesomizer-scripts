#!/usr/bin/env ruby
#
# Main code block running on the Pi. This should be added to one of the
# init.d scripts so that it launches automatically when the Pi is booted.
# It handles two functions: controlling the LEDs through the GPIO pins
# and handling barcodes that are scanned with the external reader.
#
#
# This code based on a post at
# http://unix.stackexchange.com/questions/77756/can-i-stop-linux-from-listening-to-a-usb-input-device-as-a-keyboard-but-still-c

BARCODE_SCANNER = "/dev/input/event0"

require 'dotenv'
Dotenv.load

require 'open-uri'
require 'rubygems'
require 'libdevinput'
require 'ffi'
require 'ffi/tools/const_generator'
require_relative 'lol_blink'

# Set up Pi GPIO
gpio = WiringPi::GPIO.new

# Set pin modes
gpio.mode 0, OUTPUT
gpio.mode 1, OUTPUT
gpio.mode 2, OUTPUT
gpio.mode 3, OUTPUT

# Array of pins that we're using
pins = [0, 1, 4, 3]

# Start a default "waiting for input" lights sequence
led_thread = Thread.new { while(true) do  run_lights(gpio, pins, 10, speed = 0.8)  end }

# We need access to the file
DevInput.class_eval { attr_reader :dev }

# Look up value of EVIOCGRAB constant
cg = FFI::ConstGenerator.new('input') do |gen|
  gen.include('linux/input.h')
  gen.const(:EVIOCGRAB, '%u', '(unsigned)')
end
EVIOCGRAB = cg['EVIOCGRAB'].to_i

scanner = DevInput.new(BARCODE_SCANNER)
# Send EVIOCGRAB to scanner, which grabs it for exclusive use by our process
scanner.dev.ioctl(EVIOCGRAB, 1)


puts "Waiting for events..."

code = []
scanner.each do |event|
  # Ignore everything except key press events
  next unless event.type == 1 && event.value == 1
  #puts "Key: #{event.code_str}"
  if event.code_str == 'Enter'
    open("#{ENV['WEBSERVICE_URL']}/inc/#{code.join}")
    code = []

    # Pause the 'waiting for input' LED sequence, run the 'success' sequence,
    # then go back to waiting.
    led_thread.kill
    victory_dance(gpio, pins)
    led_thread = Thread.new { while(true) do  run_lights(gpio, pins, 10, speed = 0.8)  end }

  else
    code.push event.code_str
  end
end
