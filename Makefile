BIN=Identify\ Monitor.app

all: $(BIN)

clean:
	rm $(BIN)

CC=gcc
C_FLAGS=-x objective-c
L_FLAGS=-framework Cocoa 

$(BIN): identify_monitor.m
	gcc "$<" $(C_FLAGS) $(L_FLAGS) -o "$@"

