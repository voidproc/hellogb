ROM := hellogb.gb
ROM_NAME := hellogb
ROM_TITLE := HELLOGB
INC_DIR := inc
BUILD_DIR := build

ASM := rgbasm
ASM_FLAGS := -H -i $(INC_DIR)/

LINK := rgblink
LINK_FLAGS := --sym $(BUILD_DIR)/$(ROM_NAME).sym

FIX := rgbfix
FIX_FLAGS := -t $(ROM_TITLE) -v -p 0

SRC := main.s
OBJ := $(addprefix $(BUILD_DIR)/, $(SRC:.s=.o))

all: clean $(ROM)

$(ROM): $(OBJ)
	$(LINK) $(LINK_FLAGS) -o $(BUILD_DIR)/$@ $<
	$(FIX) $(FIX_FLAGS) $(BUILD_DIR)/$@

$(OBJ): $(SRC)
	$(ASM) $(ASM_FLAGS) -o $@ $<

clean:
	rm -f $(BUILD_DIR)/*.sym
	rm -f $(BUILD_DIR)/*.gb
	rm -f $(BUILD_DIR)/*.o
