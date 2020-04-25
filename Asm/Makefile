# Makefile


HexFile = ToggleLeds.hex

AsmFile = ToggleLeds.asm

Options = -BE

Device = /dev/ArduinoUno02


$(HexFile): $(AsmFile)
	gavrasm $(Options) $(AsmFile)

.PHONY: upload
upload: $(HexFile)
	avrdude -p atmega328p -c arduino -b115200 -D -V -U flash:w:$(HexFile) -P $(Device)

.PHONY: clean
clean:
	-rm -f *.lst *.hex
